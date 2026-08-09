// Sichert das schmale Fenster ab, in dem die gesamte gespeicherte
// Log-Historie verloren gehen konnte.
//
// Der Zone-Handler in main() ist ab der ersten Zeile aktiv und kann loggen,
// bevor AppLogger.init() den persistenten Puffer geladen hat. Ohne Wache
// bewaffnet so ein frueher Eintrag den 2-Sekunden-Persist-Timer. Braucht
// init() laenger — kalter Start, traege SharedPreferences —, schreibt der
// Timer einen Puffer, der NUR den frueh gemeldeten Fehler enthaelt, und
// init() laedt anschliessend genau diesen einen Eintrag.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/services/app_logger.dart';

const _prefsKey = 'diagnostic_log';

Future<List<String>> storedMessages() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_prefsKey);
  if (raw == null) return const [];
  return (jsonDecode(raw) as List)
      .map((e) => (e as Map<String, dynamic>)['m'] as String)
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('frueher Eintrag zerstoert die gespeicherte Historie nicht', () async {
    // Eine bereits gespeicherte Historie vortaeuschen.
    SharedPreferences.setMockInitialValues({
      _prefsKey: jsonEncode([
        {'t': 1000, 'l': 'INFO', 'g': 'alt', 'm': 'Eintrag von gestern'},
      ]),
    });

    // Der Zone-Handler meldet, BEVOR init() gelaufen ist.
    AppLogger.warn('Zone', 'frueher Fehler vor init');

    // Laenger warten als das Persist-Intervall (2 s). Ohne die Wache in
    // _schedulePersist wuerde hier geschrieben und "Eintrag von gestern"
    // waere weg.
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    expect(await storedMessages(), ['Eintrag von gestern'],
        reason: 'vor init() darf nicht geschrieben werden');

    // Jetzt laden.
    await AppLogger.init();

    final inMemory = AppLogger.entries.map((e) => e.message).toList();
    expect(inMemory, contains('Eintrag von gestern'),
        reason: 'gespeicherte Historie muss erhalten bleiben');
    expect(inMemory, contains('frueher Fehler vor init'),
        reason: 'der frueh gemeldete Fehler darf nicht verworfen werden');

    // init() holt das Speichern nach, damit der fruehe Eintrag einen
    // Start-Absturz ueberlebt.
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    final persisted = await storedMessages();
    expect(persisted, contains('Eintrag von gestern'));
    expect(persisted, contains('frueher Fehler vor init'));
  }, timeout: const Timeout(Duration(seconds: 30)));
}
