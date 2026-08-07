// Sichert die zwei Eigenschaften, an denen der Log bisher gescheitert ist:
// die Fehlermeldung darf nicht auf den Klassennamen eingekocht werden, und
// der Stack-Kopf muss auch ohne Ausfuehrlich-Modus erhalten bleiben.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/app_logger.dart';

void main() {
  test('warn haengt die Fehlermeldung an, nicht nur den Typ', () {
    AppLogger.warn('T', 'Plattformdaten nicht lesbar',
        UnsupportedError('Platform._version'));
    final e = AppLogger.entries.last;
    expect(e.level, 'WARN');
    expect(e.message, contains('Platform._version'),
        reason: 'nur "UnsupportedError" ist zur Fehlersuche wertlos');
    expect(e.message, contains('UnsupportedError'));
  });

  test('error schreibt den Stack-Kopf auch ohne Ausfuehrlich-Modus', () {
    expect(AppLogger.isVerbose, isFalse, reason: 'Standard ist aus');
    try {
      throw StateError('kaputt');
    } catch (err, st) {
      AppLogger.error('T', 'Ablauf gescheitert', err, st);
    }
    final e = AppLogger.entries.last;
    // Level ERROR, damit der "nur Probleme"-Filter im Log-Screen den
    // Eintrag nicht ausblendet.
    expect(e.level, 'ERROR');
    expect(e.message, contains('kaputt'));
    expect(e.message, contains('bei '), reason: 'Stack-Kopf im selben Eintrag');
    expect(e.message.contains('\n'), isFalse,
        reason: 'eine Zeile pro Eintrag, sonst wird exportText() unlesbar');
  });

  test('FlutterErrorDetails landen vollstaendig im Log', () {
    // Ruft die Logik aus _installErrorHandlers direkt auf. Der Weg ueber
    // FlutterError.reportError ist hier nicht moeglich: flutter_test wertet
    // jeden so gemeldeten Fehler als Fehlschlag des Tests selbst. Die
    // Zuweisung von FlutterError.onError in main.dart ist eine Zeile und
    // durch Lesen pruefbar — hier geht es um den Inhalt des Eintrags.
    final details = FlutterErrorDetails(
      exception: ArgumentError('Testfehler aus dem Widget-Baum'),
      stack: StackTrace.current,
      library: 'testlib',
    );
    AppLogger.error(
        'Flutter', details.library ?? 'widget', details.exception, details.stack);

    final e = AppLogger.entries.last;
    expect(e.tag, 'Flutter');
    expect(e.level, 'ERROR');
    expect(e.message, contains('Testfehler aus dem Widget-Baum'));
    expect(e.message, contains('testlib'));
  });
}
