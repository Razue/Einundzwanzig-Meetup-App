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

  test('report() ist idempotent — zweiter Aufruf verdoppelt nicht', () {
    final t = RelayParseTally('T', 'X');
    t.message();
    t.failed(FormatException('kaputt'));
    final before = AppLogger.entries.length;
    t.report();
    t.report();
    expect(AppLogger.entries.length, before + 1,
        reason: 'finish()+finally oder doppeltes report() darf nicht fluten');
  });

  test('erster Parse-Fehler landet im Ausfuehrlich-Modus als debug', () async {
    await AppLogger.setVerbose(true);
    final before = AppLogger.entries.length;
    final t = RelayParseTally('T', 'Admin-Liste');
    t.message();
    t.failed(FormatException('ungueltiges EVENT'));
    t.report();
    expect(AppLogger.entries.length, before + 2,
        reason: 'warn-Zusammenfassung + debug-Stichprobe');
    expect(AppLogger.entries[before].level, 'WARN');
    expect(AppLogger.entries[before + 1].level, 'DEBUG');
    expect(AppLogger.entries[before + 1].message, contains('ungueltiges EVENT'));
    await AppLogger.setVerbose(false);
  });
}
