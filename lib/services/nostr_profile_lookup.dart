import 'dart:async';
import 'dart:convert';

import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'relay_config.dart';
import 'profile_relay_connection_io.dart'
    if (dart.library.js_interop) 'profile_relay_connection_web.dart';

typedef ProfileRelayQuery =
    Future<List<Map<String, dynamic>>> Function(String relay, String pubkey);

/// Begrenzte Profil-Discovery mit Leseanfragen, ohne privaten Schlüssel/Signer.
///
/// Fragt App-Relays und einen Profil-Index ab, danach die NIP-65-Write-Relays
/// des Autors. Es gilt die Ersetzungsreihenfolge nach NIP-01, auch bei einer
/// Bildentfernung. Bei Ausfall bleibt das zuletzt bekannte Profil erhalten.
class NostrProfileLookup {
  NostrProfileLookup({
    Future<List<String>> Function()? relays,
    ProfileRelayQuery? query,
    DateTime Function()? now,
  }) : _relays = relays ?? RelayConfig.getActiveRelays,
       _query = query ?? const ProfileRelayClient().query,
       _now = now ?? DateTime.now;

  static const cacheDuration = Duration(hours: 12);
  static const indexRelay = 'wss://purplepag.es';
  static const maxInitialRelays = 8;
  static const maxAuthorRelays = 4;
  static final _hex = RegExp(r'^[0-9a-f]{64}$');

  final Future<List<String>> Function() _relays;
  final ProfileRelayQuery _query;
  final DateTime Function() _now;
  final _pending = <String, Future<String?>>{};
  int _generation = 0;

  Future<String?> fetchPicture(String pubkey) {
    if (!_hex.hasMatch(pubkey)) return Future.value(null);
    return _pending.putIfAbsent(pubkey, () {
      final generation = _generation;
      return _fetch(pubkey, generation).whenComplete(() {
        if (generation == _generation) _pending.remove(pubkey);
      });
    });
  }

  /// Verhindert, dass eine laufende alte Abfrage einen geleerten Cache befüllt.
  void invalidate() {
    _generation++;
    _pending.clear();
  }

  Future<String?> _fetch(String pubkey, int generation) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'nostr_profile_metadata_v2_$pubkey';
    Event? cached;
    var fetchedAt = 0;
    try {
      final value = jsonDecode(prefs.getString(key) ?? '') as Map;
      cached = _validEvent(value['event'], pubkey, _now());
      if (cached?.kind != 0) cached = null;
      fetchedAt = value['fetchedAt'] as int;
    } catch (_) {
      // Ungültiger Cache oder Altbestand: alte URL als Fallback nutzen.
    }
    final now = _now();
    if (cached != null && _isFresh(fetchedAt, now)) return _picture(cached);

    final legacy = pictureUrl(prefs.getString('nostr_profile_picture_$pubkey'));
    final legacyAt = prefs.getInt('nostr_profile_picture_time_$pubkey') ?? 0;
    if (cached == null && legacy != null && _isFresh(legacyAt, now)) {
      return legacy;
    }

    List<String> configured;
    try {
      configured = await _relays();
    } catch (_) {
      configured = RelayConfig.defaultRelays;
    }
    // Auch bei vielen eigenen App-Relays einen Discovery-Platz reservieren.
    final initial = <String>{
      ...configured
          .map((r) => relayUrl(r))
          .whereType<String>()
          .where((r) => r != indexRelay)
          .toSet()
          .take(maxInitialRelays - 1),
      indexRelay,
    };
    Event? cachedRelays;
    final relayKey = 'nostr_profile_relays_v2_$pubkey';
    try {
      cachedRelays = _validEvent(
        jsonDecode(prefs.getString(relayKey) ?? ''),
        pubkey,
        now,
      );
      if (cachedRelays?.kind != 10002) cachedRelays = null;
    } catch (_) {}
    final events = await _queryAll(initial, pubkey, now);
    final relayList = _newest([
      ?cachedRelays,
      ...events.where((e) => e.kind == 10002),
    ]);
    if (relayList != null) {
      final authorRelays = <String>{};
      for (final tag in relayList.tags) {
        if (tag.length < 2 || tag[0] != 'r') continue;
        if (tag.length > 2 && tag[2] != 'write') continue;
        final relay = relayUrl(tag[1], discovered: true);
        if (relay != null && !initial.contains(relay)) authorRelays.add(relay);
        if (authorRelays.length == maxAuthorRelays) break;
      }
      events.addAll(await _queryAll(authorRelays, pubkey, now));
    }
    // Neuere Hinweise aus Autor-Relays für den nächsten Abruf speichern.
    // Die zweite Stufe wird hier nicht rekursiv erweitert.
    final latestRelays = _newest([
      ?cachedRelays,
      ...events.where((e) => e.kind == 10002),
    ]);
    if (latestRelays != null && generation == _generation) {
      await prefs.setString(relayKey, jsonEncode(latestRelays.toJson()));
    }

    final latest = _newest([?cached, ...events.where((e) => e.kind == 0)]);
    final receivedProfile = events.any((e) => e.kind == 0);
    if (latest != null && receivedProfile && generation == _generation) {
      await prefs.setString(
        key,
        jsonEncode({
          'event': latest.toJson(),
          'fetchedAt': _now().millisecondsSinceEpoch,
        }),
      );
      // Ein bekanntes signiertes Profil darf keine alte URL wiederbeleben.
      await prefs.remove('nostr_profile_picture_$pubkey');
      await prefs.remove('nostr_profile_picture_time_$pubkey');
    }
    return latest != null ? _picture(latest) : legacy;
  }

  bool _isFresh(int at, DateTime now) {
    final age = now.millisecondsSinceEpoch - at;
    return at > 0 && age >= 0 && age < cacheDuration.inMilliseconds;
  }

  Future<List<Event>> _queryAll(
    Iterable<String> relays,
    String pubkey,
    DateTime now,
  ) async {
    final results = await Future.wait(
      relays.map((relay) async {
        try {
          final raw = await _query(relay, pubkey);
          return raw
              .take(ProfileRelayClient.maxEvents)
              .map((e) => _validEvent(e, pubkey, now))
              .whereType<Event>()
              .toList();
        } catch (_) {
          return <Event>[];
        }
      }),
    );
    return results.expand((r) => r).toList();
  }

  static Event? _validEvent(dynamic raw, String pubkey, DateTime now) {
    try {
      if (raw is! Map<String, dynamic> ||
          raw['pubkey'] != pubkey ||
          (raw['kind'] != 0 && raw['kind'] != 10002)) {
        return null;
      }
      final at = raw['created_at'];
      if (at is! int || at < 0 || at > now.millisecondsSinceEpoch ~/ 1000) {
        return null;
      }
      // Prüft Event-ID und BIP-340-Signatur.
      final event = Event.fromJson(raw);
      if (event.kind == 0 &&
          jsonDecode(event.content) is! Map<String, dynamic>) {
        return null;
      }
      return event;
    } catch (_) {
      return null;
    }
  }

  static Event? _newest(Iterable<Event> events) {
    Event? best;
    for (final event in events) {
      if (best == null ||
          event.createdAt > best.createdAt ||
          (event.createdAt == best.createdAt &&
              event.id.compareTo(best.id) < 0)) {
        best = event;
      }
    }
    return best;
  }

  static String? _picture(Event event) {
    return pictureUrl((jsonDecode(event.content) as Map)['picture']);
  }

  static String? pictureUrl(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri.toString();
  }

  /// Auch signierte Relay-Hinweise können auf unsichere Netzwerkziele zeigen.
  /// TLS verlangen, lokale/private Literale ablehnen; kein DNS-Rebinding-Schutz.
  static String? relayUrl(String value, {bool discovered = false}) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'wss' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      return null;
    }
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
    if (discovered) {
      if (!host.contains('.') ||
          host == 'localhost' ||
          host.endsWith('.local') ||
          host.endsWith('.localdomain') ||
          host.endsWith('.localhost') ||
          host.contains(':') ||
          host.contains('[')) {
        return null;
      }
      final parts = host.split('.').map(int.tryParse).toList();
      if (parts.every((p) => p != null)) {
        // Auch verkürzte IPv4-Adressen wie 127.1 ablehnen.
        if (parts.length != 4 || parts.any((p) => p! < 0 || p > 255)) {
          return null;
        }
        final a = parts[0]!;
        final b = parts[1]!;
        if (a == 0 ||
            a == 10 ||
            a == 127 ||
            a >= 224 ||
            (a == 169 && b == 254) ||
            (a == 172 && b >= 16 && b <= 31) ||
            (a == 192 && b == 168) ||
            (a == 100 && b >= 64 && b <= 127)) {
          return null;
        }
      }
    }
    // Ein Root-Slash benennt denselben Endpunkt; andere Pfade bleiben erhalten.
    return uri.path == '/' && !uri.hasQuery
        ? uri.replace(path: '').toString()
        : uri.toString();
  }
}

/// Eine Verbindung/Subscription pro Relay für beide Metadaten-Typen.
/// Das Zeitlimit umfasst Handshake und Antwort. Jeder Ausgang schließt den Kanal.
class ProfileRelayClient {
  const ProfileRelayClient({this.timeout = const Duration(seconds: 6)});

  static const maxMessages = 64;
  static const maxEvents = 8;
  static const maxMessageLength = 64 * 1024;
  final Duration timeout;

  Future<List<Map<String, dynamic>>> query(String relay, String pubkey) async {
    WebSocketChannel? channel;
    void Function()? abort;
    StreamSubscription<dynamic>? subscription;
    final events = <Map<String, dynamic>>[];
    final done = Completer<void>();
    final deadline = Stopwatch()..start();
    const subId = 'profile'; // Auf dieser eigenen Verbindung eindeutig.
    try {
      final connection = openProfileRelay(Uri.parse(relay));
      channel = connection.channel;
      abort = connection.abort;
      // Vor ready zuhören: Manche Transporte melden Handshake-Fehler im Stream.
      var messages = 0;
      subscription = channel.stream.listen(
        (data) {
          if (done.isCompleted) return;
          if (++messages > maxMessages ||
              data is! String ||
              data.length > maxMessageLength) {
            done.complete();
            return;
          }
          try {
            final message = jsonDecode(data);
            if (message is! List || message.length < 2 || message[1] != subId) {
              return;
            }
            if (message[0] == 'EVENT' &&
                message.length == 3 &&
                message[2] is Map) {
              events.add(Map<String, dynamic>.from(message[2] as Map));
              if (events.length >= maxEvents) done.complete();
            } else if (message[0] == 'EOSE' || message[0] == 'CLOSED') {
              done.complete();
            }
          } catch (_) {
            // Ungültige Frames dürfen spätere gültige Antworten nicht stören.
          }
        },
        onError: (Object _) {
          if (!done.isCompleted) done.complete();
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );
      await channel.ready.timeout(timeout);
      channel.sink.add(
        jsonEncode([
          'REQ',
          subId,
          {
            'kinds': [0, 10002],
            'authors': [pubkey],
            'limit': 2,
          },
        ]),
      );
      final remaining = timeout - deadline.elapsed;
      if (remaining > Duration.zero) await done.future.timeout(remaining);
    } catch (_) {
      // Teilantworten sind auch nützlich, wenn ein Relay kein EOSE sendet.
    } finally {
      // Den Close-Handshake nicht abwarten: Ein unantwortendes Relay kann ihn
      // blockieren. Listener beenden und Fehler beim Aufräumen abfangen.
      unawaited(subscription?.cancel().catchError((Object _) {}));
      unawaited(channel?.sink.close().catchError((Object _) {}));
      abort?.call();
    }
    return events;
  }
}
