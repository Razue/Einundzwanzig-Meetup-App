// Prueft die PBKDF2-Rechnung gegen Werte einer UNABHAENGIGEN Implementierung.
//
// Warum das der wichtigste Test dieser Aenderung ist: der abgeleitete
// Schluessel entschluesselt bestehende Backups. Weicht er um ein Bit ab, ist
// jede vorhandene .21bkp-Datei unlesbar — ohne Fehlermeldung, die auf die
// Ursache zeigt. Die Beschleunigung ueber WebCrypto darf am Ergebnis nichts
// aendern, und dafuer muss zuerst die Dart-Rechnung selbst belegt sein.
//
// HERKUNFT DER ERWARTUNGSWERTE: erzeugt mit PBKDF2KeyDerivator aus
// pointycastle 3.9.1 (HMac(SHA256Digest(), 64), Pbkdf2Parameters(salt,
// iterations, keyBytes)), Passwort und Salt jeweils als UTF-8. Fremder Code,
// andere Struktur, dieselbe Spezifikation — das ist mehr wert als ein aus dem
// Gedaechtnis eingetippter Vektor.
//
// Die Werte stehen hier fest, statt pointycastle im Test aufzurufen: dieses
// Paket ist auf diesem Zweig keine deklarierte Abhaengigkeit, und dieser Zweig
// soll unabhaengig bleiben. Nachrechnen laesst sich jeder Wert mit den obigen
// Angaben in drei Zeilen.

import 'dart:convert';

import 'package:einundzwanzig_meetup_app/services/pbkdf2/pbkdf2_dart.dart';
import 'package:flutter_test/flutter_test.dart';

const _salt = 'einundzwanzig-salt-32-bytes-lang!';
const _passwordA = 'korrekt pferd batterie klammer';

/// iterations → erwarteter 32-Byte-Schluessel fuer _passwordA
const _expectedA = <int, String>{
  1: '070375026d4efd90f55f8c596f9804c9d59e8b261c226982aea5b2076a95bb8a',
  2: 'f92df020004a77d443c83df50dd1899ad67b97d28b7d21b9481a78e5cb86885a',
  4096: '730ecb5f9ff2ce548af5ef16149284b4b0e96be1a1c57f1192bafe12bae7b0c9',
  100000: '22772726dbae2cda50c4f036ecce698ad1def22782eaab08d439742d531e0166',
};

const _expectedAt600k =
    'c32f5c29f83c8c3a2250ecd4ca726a7766d74edfd8cb74d2cf95e7d4654ce58e';
const _expectedUmlaut =
    '090f088c774831b951cdff271be383fe5c34b45a5e925f5cf465eda21affa3a1';
const _expected64Byte =
    '546f47b1fbba44eb9b8f88a78a65a017911b0f1d744ad7aff4742981e7af99d8'
    'ca31938c361ececdd17b1f0eeefadfec9df608589f378a985dc1424b6b1481ba';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('PBKDF2-HMAC-SHA256 stimmt mit der Referenz ueberein', () {
    _expectedA.forEach((iterations, expected) {
      test('$iterations Runden', () {
        expect(
          _hex(pbkdf2DartFromPassword(
            password: _passwordA,
            salt: utf8.encode(_salt),
            iterations: iterations,
            keyBytes: 32,
          )),
          expected,
        );
      });
    });

    test('600000 Runden — der Wert, den die App wirklich benutzt', () {
      expect(
        _hex(pbkdf2DartFromPassword(
          password: 'passwort',
          salt: utf8.encode(_salt),
          iterations: 600000,
          keyBytes: 32,
        )),
        _expectedAt600k,
      );
    });

    test('Sonderzeichen im Passwort werden als UTF-8 behandelt', () {
      // Ein Passwort mit Umlauten oder Emoji darf nicht je nach Weg anders
      // kodiert werden — sonst oeffnet das Backup auf einem Geraet und auf
      // dem anderen nicht.
      expect(
        _hex(pbkdf2DartFromPassword(
          password: 'Gruß-Ähre-müde-😀',
          salt: utf8.encode(_salt),
          iterations: 1000,
          keyBytes: 32,
        )),
        _expectedUmlaut,
      );
    });

    test('mehr als ein Block: 64 Byte Schluessel', () {
      // Die App braucht 32 Byte, also genau einen Block. Die Schleife ueber
      // die Bloecke soll trotzdem stimmen, falls jemand die Laenge aendert.
      expect(
        _hex(pbkdf2DartFromPassword(
          password: 'passwort',
          salt: utf8.encode(_salt),
          iterations: 1000,
          keyBytes: 64,
        )),
        _expected64Byte,
      );
    });
  });

  group('Grenzen', () {
    test('0 Runden werden abgewiesen statt still 1 zu rechnen', () {
      expect(
        () => pbkdf2DartFromPassword(
            password: 'x', salt: const [1], iterations: 0, keyBytes: 32),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Schluessellaenge 0 wird abgewiesen', () {
      expect(
        () => pbkdf2DartFromPassword(
            password: 'x', salt: const [1], iterations: 1, keyBytes: 0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
