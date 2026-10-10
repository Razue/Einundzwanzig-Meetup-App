// ============================================
// RELAY SOCKET — plattformübergreifende WebSocket-Verbindung zu Nostr-Relays
// ============================================
// Ersetzt `dart:io` WebSocket, das im Browser NICHT funktioniert: dort wirft
// WebSocket.connect() intern `Unsupported operation: Platform._version`.
// Folge war, dass in der Web-Version JEDE Relay-Verbindung fehlschlug —
// Bürgschaften, Organisator-Registry, Profilbilder, Reputations-Publishing,
// Nostr-Kalender und Zap-Prüfung waren damit ohne Funktion.
//
// web_socket_channel (Dart-Team, tools.dart.dev) bringt Implementierungen für
// dart:io UND Browser mit und wählt sie automatisch passend zur Plattform.
//
// Die API ist absichtlich deckungsgleich mit der bisher genutzten Teilmenge
// von dart:io WebSocket (connect / listen / add / close), damit die
// Aufrufstellen unverändert bleiben und der Umbau nachvollziehbar ist.
// ============================================

import 'dart:async';

import 'package:nostr/nostr.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'app_logger.dart';

class RelaySocket {
  final WebSocketChannel _channel;

  /// Obergrenze für eine Relay-Nachricht. Darüber wird der Frame verworfen,
  /// statt ihn zu parsen (Security Audit M4).
  static const int maxMessageChars = 512 * 1024;

  RelaySocket._(this._channel);

  static bool _withinLimit(dynamic data) {
    final tooBig = (data is String && data.length > maxMessageChars) ||
        (data is List<int> && data.length > maxMessageChars);
    if (!tooBig) return true;
    AppLogger.debug('RelaySocket', 'Frame über $maxMessageChars verworfen');
    return false;
  }

  /// Baut die Verbindung auf und wartet, bis sie steht.
  ///
  /// Wichtig für die Gleichwertigkeit zu dart:io: Dort wirft
  /// `WebSocket.connect()` bei einem Verbindungsfehler. WebSocketChannel
  /// verbindet dagegen verzögert, weshalb hier auf `ready` gewartet wird —
  /// nur so schlagen Fehler wie bisher an der Aufrufstelle auf, und ein
  /// `.timeout(...)` der Aufrufer greift weiterhin auf den Verbindungsaufbau.
  ///
  /// Scheitert `ready`, wird der Channel geschlossen — sonst bliebe bei
  /// WebSocketChannel eine halb offene Verbindung liegen (besser als die
  /// reine dart:io-Parität, wo Aufrufer-`.timeout()` den Socket ebenfalls
  /// nicht freigibt).
  static Future<RelaySocket> connect(String url) async {
    final channel = WebSocketChannel.connect(Uri.parse(url));
    try {
      await channel.ready;
      return RelaySocket._(channel);
    } catch (_) {
      // close() bewusst NICHT awaiten: nach fehlgeschlagenem Handshake kann
      // sink.close() auf manchen Plattformen haengen und connect() blockieren.
      try {
        channel.sink.close();
      } catch (_) {}
      rethrow;
    }
  }

  /// Eingehende Nachrichten. Entspricht `ws.listen(...)`.
  StreamSubscription listen(
    void Function(dynamic data) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _channel.stream.listen(
          (data) {
            if (_withinLimit(data)) onData(data);
          },
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  /// Für Aufrufstellen, die den Socket direkt als Stream verwenden
  /// (`await for (final data in ws.stream.timeout(...))`).
  Stream get stream => _channel.stream.where(_withinLimit);

  /// Nachricht senden. Entspricht `ws.add(...)`.
  void add(String data) => _channel.sink.add(data);

  /// Verbindung schließen. Entspricht `ws.close()`.
  Future<void> close() => _channel.sink.close();

  // ===========================================================
  // ZENTRALE SIGNATURPRÜFUNG (Security Audit H2/M1)
  // ===========================================================
  //
  // Jedes Event, das aus einer ["EVENT", subId, {...}]-Nachricht in die
  // App gelangt, läuft hier durch: ID nachrechnen, Schnorr-Signatur
  // prüfen. Ein Relay (oder wer sich dazwischenschaltet) kann damit keine
  // Kalender-Termine, Profile, Chats, Zusagen oder Follow-Listen unter
  // fremdem Pubkey unterschieben.
  //
  // Verworfene Events werden gezählt und sparsam protokolliert — nie
  // geworfen, damit ein kaputtes Relay die Verarbeitung nicht abbricht.

  static int _rejectedCount = 0;

  /// Anzahl der seit App-Start wegen ungültiger Signatur verworfenen Events.
  static int get rejectedEventCount => _rejectedCount;

  /// Liefert das Event-Objekt zurück, wenn ID und Signatur stimmen —
  /// sonst null. [raw] ist typischerweise `msg[2]` einer EVENT-Nachricht.
  static Map<String, dynamic>? verifiedEvent(dynamic raw, {String tag = 'RelaySocket'}) {
    if (raw is! Map<String, dynamic>) return null;
    bool ok = false;
    try {
      // verify: false — der Konstruktor würde sonst schon werfen und
      // isValid() unten prüfte dieselbe Signatur ein zweites Mal (bip340
      // auf pointycastle ist teuer; bei hunderten Chat-Events pro Fetch
      // fällt die doppelte Prüfung merklich ins Gewicht).
      final event = Event(
        raw['id'] ?? '',
        raw['pubkey'] ?? '',
        raw['created_at'] ?? 0,
        raw['kind'] ?? 0,
        (raw['tags'] as List<dynamic>?)
                ?.map((t) => (t as List<dynamic>).map((e) => e.toString()).toList())
                .toList() ??
            [],
        raw['content'] ?? '',
        raw['sig'] ?? '',
        verify: false,
      );
      ok = event.isValid();
    } catch (_) {
      ok = false;
    }
    if (ok) return raw;
    _rejectedCount++;
    // Nur jedes 1., 10., 100., … verworfene Event loggen — kein Log-Sturm.
    if (_rejectedCount == 1 || _rejectedCount % 10 == 0) {
      AppLogger.debug(tag,
          'Event mit ungültiger Signatur verworfen (kind ${raw['kind']}, gesamt: $_rejectedCount)');
    }
    return null;
  }
}
