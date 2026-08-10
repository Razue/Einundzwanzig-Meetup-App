// Prueft die NIP-44-v2-Umsetzung gegen die offiziellen Testvektoren des NIPs
// (test/fixtures/nip44.vectors.json, unveraendert von github.com/paulmillr/nip44).
//
// Warum das der entscheidende Test ist: NIP-44 wird gebraucht, um mit FREMDEN
// Signern zu reden (nsec.app, Amber, Alby als Bunker). Eine Umsetzung, die nur
// ihre eigene Verschluesselung wieder entschluesselt, ist in sich stimmig und
// trotzdem unbrauchbar — jeder Fehler in Schluesselableitung, Padding oder
// MAC-Reihenfolge bleibt dabei unsichtbar.
//
// Die Negativfaelle sind ebenso wichtig wie die positiven: falscher MAC,
// gefaelschte Padding-Laenge und Kurvenpunkte auf dem Twist muessen ABGELEHNT
// werden. Ohne diese Faelle wuerde eine Umsetzung, die einfach nie prueft,
// alle positiven Vektoren bestehen.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:einundzwanzig_meetup_app/services/nip44.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart';

void main() {
  final root = jsonDecode(
    File('test/fixtures/nip44.vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final v2 = root['v2'] as Map<String, dynamic>;
  final valid = v2['valid'] as Map<String, dynamic>;
  final invalid = v2['invalid'] as Map<String, dynamic>;

  List<Map<String, dynamic>> cases(Map<String, dynamic> from, String key) =>
      (from[key] as List).cast<Map<String, dynamic>>();

  Uint8List unhex(String s) => Uint8List.fromList(hex.decode(s));
  String sha256Hex(String s) =>
      hex.encode(sha256.convert(utf8.encode(s)).bytes);

  group('NIP-44 v2 — gueltige Vektoren', () {
    test('get_conversation_key', () {
      final list = cases(valid, 'get_conversation_key');
      expect(list, hasLength(35));
      for (final c in list) {
        expect(
          hex.encode(Nip44.conversationKey(
            privkeyHex: c['sec1'] as String,
            pubkeyHex: c['pub2'] as String,
          )),
          c['conversation_key'],
          reason: 'sec1=${c['sec1']} pub2=${c['pub2']}',
        );
      }
    });

    test('get_message_keys', () {
      final block = valid['get_message_keys'] as Map<String, dynamic>;
      final ck = unhex(block['conversation_key'] as String);
      final list = (block['keys'] as List).cast<Map<String, dynamic>>();
      expect(list, hasLength(32));
      for (final c in list) {
        final keys = Nip44.messageKeys(ck, unhex(c['nonce'] as String));
        expect(hex.encode(keys.chachaKey), c['chacha_key'],
            reason: 'nonce=${c['nonce']}');
        expect(hex.encode(keys.chachaNonce), c['chacha_nonce'],
            reason: 'nonce=${c['nonce']}');
        expect(hex.encode(keys.hmacKey), c['hmac_key'],
            reason: 'nonce=${c['nonce']}');
      }
    });

    test('calc_padded_len', () {
      final list = (valid['calc_padded_len'] as List).cast<List>();
      expect(list, hasLength(24));
      for (final pair in list) {
        expect(Nip44.calcPaddedLen(pair[0] as int), pair[1],
            reason: 'unpadded=${pair[0]}');
      }
    });

    test('encrypt_decrypt (inkl. Gegenrichtung des Sitzungsschluessels)', () {
      final list = cases(valid, 'encrypt_decrypt');
      expect(list, hasLength(10));
      for (final c in list) {
        final sec1 = c['sec1'] as String;
        final sec2 = c['sec2'] as String;
        final plaintext = c['plaintext'] as String;

        // Die oeffentlichen Schluessel stammen aus bip340 (Paket `nostr`) —
        // damit prueft der Test auch, dass unsere Punkt-Anhebung zu einer
        // fremden Schluesselableitung passt.
        final ck = Nip44.conversationKey(
            privkeyHex: sec1, pubkeyHex: Keychain(sec2).public);
        final ckReverse = Nip44.conversationKey(
            privkeyHex: sec2, pubkeyHex: Keychain(sec1).public);

        expect(hex.encode(ck), c['conversation_key'], reason: 'sec1=$sec1');
        expect(hex.encode(ckReverse), c['conversation_key'],
            reason: 'Gegenrichtung sec2=$sec2');
        expect(Nip44.encrypt(plaintext, ck, nonce: unhex(c['nonce'] as String)),
            c['payload'],
            reason: 'plaintext=$plaintext');
        expect(Nip44.decrypt(c['payload'] as String, ck), plaintext);
      }
    });

    test('encrypt_decrypt_long_msg (bis 65535 Bytes)', () {
      final list = cases(valid, 'encrypt_decrypt_long_msg');
      expect(list, hasLength(3));
      for (final c in list) {
        final ck = unhex(c['conversation_key'] as String);
        final plaintext = (c['pattern'] as String) * (c['repeat'] as int);
        expect(sha256Hex(plaintext), c['plaintext_sha256'],
            reason: 'Vektor selbst falsch aufgebaut?');

        final payload =
            Nip44.encrypt(plaintext, ck, nonce: unhex(c['nonce'] as String));
        expect(sha256Hex(payload), c['payload_sha256']);
        expect(Nip44.decrypt(payload, ck), plaintext);
      }
    });
  });

  group('NIP-44 v2 — Negativfaelle muessen abgewiesen werden', () {
    test('get_conversation_key (Kurvenordnung, Twist-Punkte)', () {
      final list = cases(invalid, 'get_conversation_key');
      expect(list, hasLength(8));
      for (final c in list) {
        expect(
          () => Nip44.conversationKey(
            privkeyHex: c['sec1'] as String,
            pubkeyHex: c['pub2'] as String,
          ),
          throwsA(isA<Nip44Exception>()),
          reason: c['note'] as String,
        );
      }
    });

    test('encrypt_msg_lengths', () {
      final key = Uint8List(32);
      final list = (invalid['encrypt_msg_lengths'] as List).cast<int>();
      expect(list, hasLength(4));
      for (final len in list) {
        expect(() => Nip44.encrypt('a' * len, key),
            throwsA(isA<Nip44Exception>()),
            reason: 'Laenge $len');
      }
    });

    test('decrypt (Version, Base64, MAC, Padding, Laenge)', () {
      final list = cases(invalid, 'decrypt');
      expect(list, hasLength(12));
      for (final c in list) {
        expect(
          () => Nip44.decrypt(
              c['payload'] as String, unhex(c['conversation_key'] as String)),
          throwsA(isA<Nip44Exception>()),
          reason: c['note'] as String,
        );
      }
    });
  });

  group('NIP-44 v2 — Eigenschaften jenseits der Vektoren', () {
    test('zwei Aufrufe erzeugen verschiedene Nutzlasten (Nonce ist zufaellig)',
        () {
      final key = Uint8List(32);
      expect(Nip44.encrypt('hallo', key), isNot(Nip44.encrypt('hallo', key)));
    });

    test('fremder Sitzungsschluessel entschluesselt nicht', () {
      final a = Uint8List(32);
      final b = Uint8List(32)..[31] = 1;
      final payload = Nip44.encrypt('geheim', a);
      expect(Nip44.decrypt(payload, a), 'geheim');
      expect(() => Nip44.decrypt(payload, b), throwsA(isA<Nip44Exception>()));
    });

    // Diese Wache decken die offiziellen Vektoren NICHT ab: ihre drei Faelle
    // "sec1 = 0 / = n / > n" nutzen alle dasselbe pub2, das selbst nicht auf
    // der Kurve liegt (Fall "pub2 is invalid, no sqrt" belegt es). Sie
    // scheitern also schon an der Punktpruefung. Erst mit einem GUELTIGEN
    // Gegenschluessel wird die Bereichspruefung des privaten Schluessels
    // ueberhaupt erreicht.
    test('privater Schluessel ausserhalb der Kurvenordnung wird abgewiesen',
        () {
      final validPub = Keychain('01' * 32).public;
      const curveOrder =
          'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141';
      const zero =
          '0000000000000000000000000000000000000000000000000000000000000000';
      const allFf =
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

      // Gegenprobe: mit gueltigem sec1 klappt es an derselben Stelle.
      expect(
          Nip44.conversationKey(privkeyHex: '02' * 32, pubkeyHex: validPub),
          hasLength(32));

      for (final sec in [zero, curveOrder, allFf]) {
        expect(
          () => Nip44.conversationKey(privkeyHex: sec, pubkeyHex: validPub),
          throwsA(isA<Nip44Exception>()),
          reason: 'sec1=$sec',
        );
      }
    });

    test('verkuerzte Hex-Schluessel werden abgewiesen', () {
      expect(
        () => Nip44.conversationKey(privkeyHex: 'ab', pubkeyHex: 'cd'),
        throwsA(isA<Nip44Exception>()),
      );
    });
  });
}
