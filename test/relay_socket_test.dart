// Sichert die Invariante, auf der RelaySocket aufbaut: connect() muss bei
// einem Verbindungsfehler WERFEN. Ohne das `await channel.ready` im Adapter
// würde WebSocketChannel verzögert verbinden, connect() erfolgreich
// zurückkehren und der Fehler erst später an unerwarteter Stelle auftauchen —
// die Aufrufstellen erwarten aber das Wurfverhalten von dart:io.
import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/relay_socket.dart';

void main() {
  test('connect wirft bei nicht erreichbarem Relay', () async {
    await expectLater(
      RelaySocket.connect('ws://127.0.0.1:1'),
      throwsA(isA<Object>()),
    );
  }, timeout: const Timeout(Duration(seconds: 30)));
}
