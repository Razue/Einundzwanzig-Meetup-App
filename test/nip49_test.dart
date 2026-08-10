// Prueft den NIP-49-Export gegen den OFFIZIELLEN Testvektor des NIPs.
//
// Warum das der entscheidende Test ist: der Zweck von `ncryptsec` ist, dass
// ANDERE Apps den Schluessel lesen koennen — Amber, Clave, Signet, nsec.app.
// Ein Export, den nur diese App selbst wieder aufmacht, waere wertlos, und in
// einem reinen Hin-und-Rueckweg-Test faellt das nicht auf.
//
// Der Vektor stammt aus https://github.com/nostr-protocol/nips/blob/master/49.md
//
// Laeuft absichtlich auch im Browser:
//   flutter test --platform chrome test/nip49_test.dart
// Dort ist es der Beweis, dass die Krypto unter dart2js rechnet — pointycastles
// Poly1305 tat das NICHT ("full width integer not supported").

import 'package:einundzwanzig_meetup_app/services/nip49.dart';
import 'package:flutter_test/flutter_test.dart';

/// Offizieller Vektor: Passwort "nostr", log_n 16.
const _vectorNcryptsec =
    'ncryptsec1qgg9947rlpvqu76pj5ecreduf9jxhselq2nae2kghhvd5g7dgjtcxfqtd67p9m0w5'
    '7lspw8gsq6yphnm8623nsl8xn9j4jdzz84zm3frztj3z7s35vpzmqf6ksu8r89qk5z2zxfmu5gv'
    '8th8wclt0h4p';
const _vectorPassword = 'nostr';
const _vectorPrivkeyHex =
    '3501454135014541350145413501453fefb02227e449e57cf4d3a3ce05378683';

/// log_n 8 statt 16 fuer die eigenen Runden: scrypt mit 2^16 braucht 64 MB.
/// Fuer die Formatpruefung ist die Rundenzahl gleichgueltig — sie steht im Kopf
/// des Datensatzes und wird beim Entschluesseln von dort gelesen. Der echte
/// Wert 16 ist ueber den offiziellen Vektor oben abgedeckt.
const _logN = 8;
const _privkey =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('offizieller Testvektor', () {
    test('entschluesselt zum erwarteten privaten Schluessel', () async {
      expect(await Nip49.decrypt(_vectorNcryptsec, _vectorPassword),
          _vectorPrivkeyHex);
    });

    test('falsches Passwort wird abgewiesen', () async {
      await expectLater(Nip49.decrypt(_vectorNcryptsec, 'falsch'),
          throwsA(isA<Nip49Exception>()));
    });
  });

  group('eigener Export laesst sich wieder lesen', () {
    test('Hin und Rueckweg', () async {
      final enc = await Nip49.encrypt(_privkey, 'geheim', logN: _logN);
      expect(enc, startsWith('ncryptsec1'));
      expect(await Nip49.decrypt(enc, 'geheim'), _privkey);
    });

    test('zwei Exporte unterscheiden sich (Salt und Nonce sind zufaellig)',
        () async {
      final a = await Nip49.encrypt(_privkey, 'geheim', logN: _logN);
      final b = await Nip49.encrypt(_privkey, 'geheim', logN: _logN);
      expect(a, isNot(b));
      // …und ergeben trotzdem denselben Schluessel.
      expect(await Nip49.decrypt(a, 'geheim'),
          await Nip49.decrypt(b, 'geheim'));
    });

    test('Sicherheitsstufe wird mitgefuehrt und ist ohne Passwort lesbar',
        () async {
      final insecure = await Nip49.encrypt(_privkey, 'geheim',
          logN: _logN, keySecurity: KeySecurity.insecure);
      expect(Nip49.keySecurityOf(insecure), KeySecurity.insecure);

      final secure = await Nip49.encrypt(_privkey, 'geheim',
          logN: _logN, keySecurity: KeySecurity.secure);
      expect(Nip49.keySecurityOf(secure), KeySecurity.secure);
    });

    test('die Sicherheitsstufe ist als AAD GEBUNDEN, nicht nur angehaengt',
        () async {
      // Wird das Byte im Datensatz verdreht, ohne neu zu verschluesseln, muss
      // die Pruefsumme anschlagen — sonst koennte jemand die Angabe „war nie
      // unsicher unterwegs" hineinluegen.
      final enc = await Nip49.encrypt(_privkey, 'geheim',
          logN: _logN, keySecurity: KeySecurity.insecure);
      final tampered = _flipKeySecurityByte(enc);
      expect(tampered, isNot(enc));
      await expectLater(Nip49.decrypt(tampered, 'geheim'),
          throwsA(isA<Nip49Exception>()));
    });

    test('Passwort mit Umlauten und Emoji ueberlebt den Rueckweg', () async {
      const pw = 'Grüß-Ähre-😀';
      final enc = await Nip49.encrypt(_privkey, pw, logN: _logN);
      expect(await Nip49.decrypt(enc, pw), _privkey);
    });
  });

  group('Eingaben werden geprueft', () {
    test('leeres Passwort', () async {
      await expectLater(Nip49.encrypt(_privkey, '', logN: _logN),
          throwsA(isA<Nip49Exception>()));
    });

    test('privater Schluessel falscher Laenge', () async {
      await expectLater(Nip49.encrypt('ab' * 16, 'geheim', logN: _logN),
          throwsA(isA<Nip49Exception>()));
    });

    test('kein Hex', () async {
      await expectLater(Nip49.encrypt('zz' * 32, 'geheim', logN: _logN),
          throwsA(isA<Nip49Exception>()));
    });

    test('falsches Praefix', () async {
      await expectLater(Nip49.decrypt('nsec1abcdef', 'geheim'),
          throwsA(isA<Nip49Exception>()));
    });

    test('abgeschnittener ncryptsec', () async {
      await expectLater(
          Nip49.decrypt(_vectorNcryptsec.substring(0, 60), _vectorPassword),
          throwsA(isA<Nip49Exception>()));
    });
  });
}

/// Dreht das Sicherheits-Byte im Datensatz um und laesst das Chiffrat
/// UNVERAENDERT.
///
/// Neu zu verschluesseln wuerde einen gueltigen Datensatz erzeugen und nichts
/// beweisen. Nur wenn das Byte als AAD in die Pruefsumme eingeht, schlaegt das
/// Entschluesseln danach fehl.
String _flipKeySecurityByte(String ncryptsec) {
  final payload = Nip49.debugDecodePayload(ncryptsec);
  payload[42] = payload[42] == 0x00 ? 0x01 : 0x00;
  return Nip49.debugEncodePayload(payload);
}
