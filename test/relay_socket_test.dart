// Sichert die Invariante, auf der RelaySocket aufbaut: connect() muss bei
// einem Verbindungsfehler WERFEN. Ohne das `await channel.ready` im Adapter
// würde WebSocketChannel verzögert verbinden, connect() erfolgreich
// zurückkehren und der Fehler erst später an unerwarteter Stelle auftauchen —
// die Aufrufstellen erwarten aber das Wurfverhalten von dart:io.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:einundzwanzig_meetup_app/services/relay_socket.dart';

void main() {
  test('connect wirft bei nicht erreichbarem Relay', () async {
    // Eigenes Timeout enger als der Test-Timeout: auf manchen Hosts dauert
    // Connection-Refused laenger. Ob WebSocketChannelException oder unser
    // Timeout — beides belegt, dass connect() nicht erfolgreich zurueckkehrt.
    await expectLater(
      RelaySocket.connect('ws://127.0.0.1:1')
          .timeout(const Duration(seconds: 5)),
      throwsA(anyOf(
        isA<WebSocketChannelException>(),
        isA<TimeoutException>(),
      )),
    );
  }, timeout: const Timeout(Duration(seconds: 10)));
}
