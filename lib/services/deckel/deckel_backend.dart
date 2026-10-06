// Womit der Deckel signiert und worüber er seine Ereignisse austauscht.
//
// Beides ist austauschbar: Die App signiert mit der eingerichteten Identität
// und spricht mit Relays. Tests und der Demo-Tisch nehmen frische Schlüssel
// und einen Tisch, der nur im Speicher steht.

import 'dart:async';
import 'dart:convert';

import 'package:nostr/nostr.dart';

import '../app_logger.dart';
import '../relay_config.dart';
import '../relay_socket.dart';
import '../signing_service.dart';
import 'deckel_events.dart';

const String _tag = 'Deckel';

abstract class DeckelSigner {
  Future<String?> pubkey();

  /// Signiert den Entwurf und gibt das fertige Ereignis zurück.
  Future<Map<String, dynamic>> sign(DeckelDraft draft);
}

/// Die Identität der App, gleich in welchem Modus sie signiert.
class AppDeckelSigner implements DeckelSigner {
  const AppDeckelSigner();

  @override
  Future<String?> pubkey() => SigningService.pubkeyHex();

  @override
  Future<Map<String, dynamic>> sign(DeckelDraft draft) async {
    final signed = await SigningService.signEvent(
      kind: draft.kind,
      tags: draft.tags,
      content: draft.content,
    );
    return signed.toJson();
  }
}

/// Ein Schlüssel, der nur für diesen Tisch da ist.
class KeyDeckelSigner implements DeckelSigner {
  KeyDeckelSigner([String? privateKey])
      : _keys = privateKey == null ? Keychain.generate() : Keychain(privateKey);

  final Keychain _keys;

  /// Zeit der nächsten Signatur. Tests stellen sie, damit die Reihenfolge feststeht.
  int Function()? clock;

  String get public => _keys.public;

  @override
  Future<String?> pubkey() async => _keys.public;

  @override
  Future<Map<String, dynamic>> sign(DeckelDraft draft) async {
    return Event.from(
      createdAt: clock?.call() ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: draft.kind,
      tags: draft.tags,
      content: draft.content,
      privkey: _keys.private,
    ).toJson();
  }
}

abstract class DeckelBackend {
  /// Alle Ereignisse des Deckels: was schon da ist und was neu kommt.
  /// Jedes ist bereits auf Kennung und Signatur geprüft.
  Stream<Map<String, dynamic>> watch(String deckelId);

  /// Wahr, wenn das Ereignis irgendwo angenommen wurde.
  Future<bool> publish(Map<String, dynamic> event);

  Future<void> close();
}

/// Wahr nur für ein Ereignis, dessen Kennung zum Inhalt passt und dessen
/// Signatur zur Kennung.
bool deckelEventValid(Map<String, dynamic> raw) {
  try {
    Event.fromJson(raw, verify: true);
    return true;
  } catch (_) {
    return false;
  }
}

/// Ein Tisch im Speicher. Mehrere Teilnehmer teilen sich dieselbe Instanz.
class MemoryDeckelBackend implements DeckelBackend {
  final List<Map<String, dynamic>> _events = [];
  final StreamController<Map<String, dynamic>> _live = StreamController.broadcast(sync: true);

  List<Map<String, dynamic>> get events => List.unmodifiable(_events);

  // Bestand nachreichen und auf Neues hören geschieht in einem Zug. Läge
  // dazwischen auch nur ein Moment, ginge ein Ereignis verloren, das genau
  // dann veröffentlicht wird.
  @override
  Stream<Map<String, dynamic>> watch(String deckelId) {
    late final StreamController<Map<String, dynamic>> out;
    StreamSubscription<Map<String, dynamic>>? live;
    out = StreamController(
      onListen: () {
        List.of(_events).forEach(out.add);
        live = _live.stream.listen(out.add, onDone: out.close);
      },
      onCancel: () => live?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<bool> publish(Map<String, dynamic> event) async {
    if (!deckelEventValid(event)) return false;
    _events.add(event);
    _live.add(event);
    return true;
  }

  @override
  Future<void> close() => _live.close();
}

/// Der Tisch auf Nostr-Relays.
///
/// Zu jedem Relay bleibt eine Verbindung offen, solange der Deckel auf dem
/// Bildschirm ist: Ein Strich soll bei allen am Tisch erscheinen, ohne dass
/// jemand neu lädt. Reißt eine Verbindung ab, wird sie neu aufgebaut.
class RelayDeckelBackend implements DeckelBackend {
  RelayDeckelBackend({List<String>? relays}) : _fixed = relays;

  final List<String>? _fixed;
  final StreamController<Map<String, dynamic>> _out = StreamController.broadcast();
  final Set<RelaySocket> _sockets = {};
  bool _closed = false;

  static const Duration _connect = Duration(seconds: 5);
  static const Duration _retry = Duration(seconds: 4);

  /// Relays, die der Deckel zusätzlich zu denen des Nutzers nimmt.
  ///
  /// Am Tisch müssen alle Handys mindestens ein Relay gemeinsam haben, das
  /// auch von einem unbekannten Schlüssel schreiben lässt. Von den
  /// Standard-Relays der App tat das bei der Prüfung nur eines; das
  /// Vereins-Relay verlangt eine NIP-05-Adresse. Diese beiden nahmen alle
  /// vier Ereignisarten an und gaben sie nach dem d-Tag wieder heraus
  /// (tool/deckel/relay_check.dart).
  static const List<String> extraRelays = ['wss://relay.primal.net', 'wss://nostr.mom'];

  Future<List<String>> _relays() async =>
      _fixed ?? <String>{...await RelayConfig.getActiveRelays(), ...extraRelays}.toList();

  @override
  Stream<Map<String, dynamic>> watch(String deckelId) {
    _relays().then((relays) {
      for (final url in relays) {
        _follow(url, deckelId);
      }
    });
    return _out.stream;
  }

  Future<void> _follow(String url, String deckelId) async {
    while (!_closed) {
      RelaySocket? ws;
      try {
        ws = await RelaySocket.connect(url).timeout(_connect);
        if (_closed) break;
        _sockets.add(ws);
        final gone = Completer<void>();
        ws.listen(
          (data) {
            final event = _eventIn(data);
            if (event != null && !_closed) _out.add(event);
          },
          onError: (_) {
            if (!gone.isCompleted) gone.complete();
          },
          onDone: () {
            if (!gone.isCompleted) gone.complete();
          },
        );
        ws.add(jsonEncode([
          'REQ',
          'deckel',
          {
            'kinds': kDeckelKinds,
            '#d': [deckelId],
          },
        ]));
        await gone.future;
      } catch (e) {
        AppLogger.debug(_tag, 'Relay $url nicht erreichbar: $e');
      } finally {
        if (ws != null) {
          _sockets.remove(ws);
          try {
            ws.close();
          } catch (_) {}
        }
      }
      if (_closed) break;
      await Future<void>.delayed(_retry);
    }
  }

  Map<String, dynamic>? _eventIn(dynamic data) {
    try {
      final msg = jsonDecode(data as String);
      if (msg is! List || msg.length < 3 || msg[0] != 'EVENT') return null;
      final event = Map<String, dynamic>.from(msg[2] as Map);
      return deckelEventValid(event) ? event : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> publish(Map<String, dynamic> event) async {
    final relays = await _relays();
    final frame = jsonEncode(['EVENT', event]);
    final id = event['id'] as String;
    final results = await Future.wait(relays.map((url) => _send(url, frame, id)));
    final accepted = results.where((ok) => ok).length;
    AppLogger.debug(_tag, 'Ereignis $id: $accepted von ${relays.length} Relays');
    return accepted > 0;
  }

  Future<bool> _send(String url, String frame, String id) async {
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(url).timeout(_connect);
      final done = Completer<bool>();
      ws.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String);
            if (msg is List && msg.length >= 3 && msg[0] == 'OK' && msg[1] == id) {
              if (!done.isCompleted) done.complete(msg[2] == true);
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!done.isCompleted) done.complete(false);
        },
        onDone: () {
          if (!done.isCompleted) done.complete(false);
        },
      );
      ws.add(frame);
      return await done.future.timeout(RelayConfig.publishTimeout, onTimeout: () => false);
    } catch (_) {
      return false;
    } finally {
      try {
        ws?.close();
      } catch (_) {}
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
    for (final ws in _sockets.toList()) {
      try {
        ws.close();
      } catch (_) {}
    }
    await _out.close();
  }
}
