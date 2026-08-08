// Sichert die Eigenschaft, von der die Umstellung der stillen catch-Bloecke
// abhaengt: Meldungen auf debug-Ebene duerfen den persistenten Puffer im
// Normalbetrieb NICHT fuellen.
//
// Ohne diese Grenze waere das Ergebnis der Umstellung eine Log-Flut — pro
// nicht erreichbarem Relay eine Zeile, mal Relay-Anzahl, mal Abfrage. Der
// 800er-Ringpuffer haette dann Minuten statt Stunden abgedeckt und die
// wenigen echten Fehler waeren herausgerollt.
import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/app_logger.dart';

void main() {
  test('debug landet im Normalbetrieb NICHT im Puffer, warn schon', () async {
    expect(AppLogger.isVerbose, isFalse, reason: 'Standard ist aus');

    final before = AppLogger.entries.length;

    // So loggen die umgestellten Relay-Schleifen: pro Relay eine Zeile.
    for (var i = 0; i < 25; i++) {
      AppLogger.debug('T', 'Relay $i fehlgeschlagen: SocketException');
    }
    expect(AppLogger.entries.length, before,
        reason: '25 debug-Zeilen duerfen den Puffer nicht vergroessern');

    // Ein echter Fehlschlag muss dagegen ankommen.
    AppLogger.warn('T', 'Eigener npub nicht dekodierbar: FormatException');
    expect(AppLogger.entries.length, before + 1);
    expect(AppLogger.entries.last.level, 'WARN');
  });

  test('im Ausfuehrlich-Modus sind die Detailzeilen da', () async {
    await AppLogger.setVerbose(true);
    final before = AppLogger.entries.length;
    AppLogger.debug('T', 'Relay-Kette Schritt 1');
    AppLogger.debug('T', 'Relay-Kette Schritt 2');
    expect(AppLogger.entries.length, before + 2,
        reason: 'genau dafuer ist der Modus da: die Kette nachvollziehen');
    await AppLogger.setVerbose(false);
  });
}
