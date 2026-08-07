// Sichert die beiden Eigenschaften, um die es beim Zaehler geht: er schweigt
// wenn alles in Ordnung ist, und er meldet EINMAL statt pro Nachricht.
import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/app_logger.dart';

void main() {
  test('ohne Fehlschlaege schweigt der Zaehler vollstaendig', () {
    final before = AppLogger.entries.length;
    final t = RelayParseTally('T', 'Admin-Liste von wss://relay');
    for (var i = 0; i < 47; i++) {
      t.message();
    }
    t.report();
    expect(AppLogger.entries.length, before,
        reason: '47 einwandfreie Nachrichten duerfen keine Zeile erzeugen');
  });

  test('meldet EINE Zeile mit Verhaeltnis, nicht eine pro Nachricht', () {
    final before = AppLogger.entries.length;
    final t = RelayParseTally('T', 'Admin-Liste von wss://relay');
    for (var i = 0; i < 47; i++) {
      t.message();
      if (i % 16 == 0) t.failed(); // 3 Fehlschlaege: i = 0, 16, 32
    }
    t.report();

    expect(AppLogger.entries.length, before + 1,
        reason: 'genau eine Zeile — das war der Zweck der Umstellung');
    final e = AppLogger.entries.last;
    expect(e.level, 'WARN');
    expect(e.message, contains('3 von 47'),
        reason: 'das Verhaeltnis ist die eigentliche Information');
    expect(e.message, contains('Admin-Liste von wss://relay'));
    expect(t.seen, 47);
    expect(t.failures, 3);
  });

  test('report() ist mehrfach aufrufbar, ohne zu verdoppeln — aber meldet erneut', () {
    // Dokumentiert das tatsaechliche Verhalten: report() ist im finally
    // platziert und wird pro Subscription genau einmal erreicht. Wer es
    // zweimal aufruft, bekommt zwei Zeilen — deshalb gehoert es NICHT
    // zusaetzlich an die EOSE-Stelle.
    final t = RelayParseTally('T', 'X');
    t.message();
    t.failed();
    final before = AppLogger.entries.length;
    t.report();
    t.report();
    expect(AppLogger.entries.length, before + 2);
  });
}
