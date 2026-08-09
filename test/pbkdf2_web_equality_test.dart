// Beweist, dass die WebCrypto-Abkuerzung im BROWSER denselben Schluessel
// erzeugt wie die Dart-Rechnung.
//
// Warum das kein Formalismus ist: die Beschleunigung existiert nur, weil die
// Dart-Rechnung im Browser rund 100 Sekunden brauchte. Liefert WebCrypto einen
// anderen Schluessel, laesst sich kein bestehendes Backup mehr oeffnen — und
// zwar ohne Fehlermeldung, die auf die Ursache zeigt. Das waere ein
// Datenverlust-Fehler, den man erst beim Wiederherstellen bemerkt.
//
// Ausfuehren:
//   flutter test --platform chrome test/pbkdf2_web_equality_test.dart
//
// In der VM laeuft die Datei ebenfalls, prueft dort aber nur, dass die
// Abkuerzung korrekt als "nicht verfuegbar" meldet.

import 'dart:convert';

import 'package:einundzwanzig_meetup_app/services/pbkdf2/pbkdf2_dart.dart';
import 'package:einundzwanzig_meetup_app/services/pbkdf2/pbkdf2_fast.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';

const _password = 'einundzwanzig-test-passwort';
const _salt = 'einundzwanzig-salt-32-bytes-lang!';

/// Mit pointycastle in der VM erzeugt (test/pbkdf2_equality_test.dart belegt,
/// dass die eigene Rechnung damit uebereinstimmt) — fuer genau die Parameter,
/// die die App im Backup benutzt: 600.000 Runden, 32 Byte.
const _expectedAt600k =
    'e69c19ea83dcda0b6f2e010dfaa087359d3d4b5ad4ba925b012cbfa9b80e271c';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('ausserhalb des Browsers meldet die Abkuerzung "nicht verfuegbar"', () async {
    if (kIsWeb) return;
    expect(
      await pbkdf2Fast(
          password: utf8.encode(_password),
          salt: utf8.encode(_salt),
          iterations: 1000,
          keyBytes: 32),
      isNull,
      reason: 'nativ muss der Aufrufer selbst rechnen',
    );
  });

  test('WebCrypto liefert bei 600.000 Runden genau den erwarteten Schluessel',
      () async {
    if (!kIsWeb) return;
    final fast = await pbkdf2Fast(
      password: utf8.encode(_password),
      salt: utf8.encode(_salt),
      iterations: 600000,
      keyBytes: 32,
    );
    expect(fast, isNotNull,
        reason: 'im Browser muss crypto.subtle da sein (sicherer Kontext)');
    expect(_hex(fast!), _expectedAt600k);
  });

  test('WebCrypto == Dart-Rechnung, bei mehreren Rundenzahlen', () async {
    if (!kIsWeb) return;
    // Niedrige Rundenzahlen, damit die Dart-Rechnung im Browser in
    // vertretbarer Zeit durchlaeuft. Der Vergleich prueft die Konstruktion;
    // die Rundenzahl selbst ist oben mit 600.000 abgedeckt.
    for (final iterations in [1, 2, 1000, 20000]) {
      final fast = await pbkdf2Fast(
        password: utf8.encode(_password),
        salt: utf8.encode(_salt),
        iterations: iterations,
        keyBytes: 32,
      );
      final slow = pbkdf2DartFromPassword(
        password: _password,
        salt: utf8.encode(_salt),
        iterations: iterations,
        keyBytes: 32,
      );
      expect(_hex(fast!), _hex(slow),
          reason: 'Abweichung bei $iterations Runden');
    }
  });

  test('WebCrypto ist deutlich schneller — sonst waere die Aenderung sinnlos',
      () async {
    if (!kIsWeb) return;
    final sw = Stopwatch()..start();
    await pbkdf2Fast(
      password: utf8.encode(_password),
      salt: utf8.encode(_salt),
      iterations: 600000,
      keyBytes: 32,
    );
    sw.stop();
    // Die Dart-Rechnung brauchte hier gemessen rund 100 Sekunden. Fuenf
    // Sekunden sind grosszuegig und trennen "nativ gerechnet" trotzdem
    // zweifelsfrei von "durch JavaScript gelaufen".
    expect(sw.elapsed, lessThan(const Duration(seconds: 5)),
        reason: 'lief die Ableitung doch durch die Dart-Rechnung?');
  });
}
