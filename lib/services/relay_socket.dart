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

import 'package:web_socket_channel/web_socket_channel.dart';

class RelaySocket {
  final WebSocketChannel _channel;

  RelaySocket._(this._channel);

  /// Baut die Verbindung auf und wartet, bis sie steht.
  ///
  /// Wichtig für die Gleichwertigkeit zu dart:io: Dort wirft
  /// `WebSocket.connect()` bei einem Verbindungsfehler. WebSocketChannel
  /// verbindet dagegen verzögert, weshalb hier auf `ready` gewartet wird —
  /// nur so schlagen Fehler wie bisher an der Aufrufstelle auf, und ein
  /// `.timeout(...)` der Aufrufer greift weiterhin auf den Verbindungsaufbau.
  static Future<RelaySocket> connect(String url) async {
    final channel = WebSocketChannel.connect(Uri.parse(url));
    await channel.ready;
    return RelaySocket._(channel);
  }

  /// Eingehende Nachrichten. Entspricht `ws.listen(...)`.
  StreamSubscription listen(
    void Function(dynamic data) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _channel.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  /// Für Aufrufstellen, die den Socket direkt als Stream verwenden
  /// (`await for (final data in ws.stream.timeout(...))`).
  Stream get stream => _channel.stream;

  /// Nachricht senden. Entspricht `ws.add(...)`.
  void add(String data) => _channel.sink.add(data);

  /// Verbindung schließen. Entspricht `ws.close()`.
  Future<void> close() => _channel.sink.close();
}
