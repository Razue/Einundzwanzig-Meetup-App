// Beweist, dass NIP-44 IM BROWSER laeuft — nicht nur, dass es dafuer
// uebersetzt wird.
//
// Warum als eigene Datei: nip44_vectors_test.dart liest die 128 Vektoren ueber
// `dart:io` aus einer Datei, und die gibt es im Browser nicht. Der grosse Test
// kann dort also gar nicht starten. Hier stehen deshalb einige Vektoren
// woertlich im Quelltext — dieselben Werte aus derselben offiziellen Datei.
//
// Geprueft wird damit der Teil, der unter dart2js anders arbeitet als in der
// VM: BigInt-Arithmetik fuer ECDH auf secp256k1, dazu ChaCha20 und HMAC aus
// pointycastle. Ein reines `flutter build web` haette gezeigt, dass es
// uebersetzt, und nichts darueber gesagt, ob es rechnet.
//
// Beide Wege ausfuehren:
//   flutter test                   test/nip44_web_smoke_test.dart
//   flutter test --platform chrome test/nip44_web_smoke_test.dart

import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:einundzwanzig_meetup_app/services/nip44.dart';
import 'package:flutter_test/flutter_test.dart';

// --- woertlich aus nip44.vectors.json (v2) ---
const _sec1 =
    '315e59ff51cb9209768cf7da80791ddcaae56ac9775eb25b6dee1234bc5d2268';
const _pub2 =
    'c2f9d9948dc8c7c38321e4b85c8558872eafa0641cd269db76848a6073e69133';
const _conversationKey =
    '3dfef0ce2a4d80a25e7a328accf73448ef67096f65f79588e358d9a0eb9013f1';

const _edSec1 =
    '0000000000000000000000000000000000000000000000000000000000000001';
const _edPub2 =
    'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
const _edKey =
    'c41c775356fd92eadc63ff5a0dc1da211b268cbea22316767095b2871ea1412d';
const _edNonce =
    '0000000000000000000000000000000000000000000000000000000000000001';
const _edPayload = 'AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABee0G5VSK0/9Yyp'
    'IObAtDKfYEAjD35uVkHyB0F4DwrcNaCXlCWZKaArsGrY6M9wnuTMxWfp1RTN9Xga8no+kF5Vsb';

const _badMacKey =
    'cff7bd6a3e29a450fd27f6c125d5edeb0987c475fd1e8d97591e0d4d8a89763c';
const _badMacPayload = 'Agn/l3ULCEAS4V7LhGFM6IGA17jsDUaFCKhrbXDANholyySBfeh+EN'
    '8wNB9gaLlg4j6wdBYh+3oK+mnxWu3NKRbSvQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAA';

const _badPaddingKey =
    '5254827d29177622d40a7b67cad014fe7137700c3c523903ebbe3e1b74d40214';
const _badPaddingPayload = 'Anq2XbuLvCuONcr7V0UxTh8FAyWoZNEdBHXvdbNmDZHB573MI7'
    'R7rrTYftpqmvUpahmBC2sngmI14/L0HjOZ7lWGJlzdh6luiOnGPc46cGxf08MRC4CIuxx3i2Lm'
    '0KqgJ7vA';

Uint8List _unhex(String s) => Uint8List.fromList(hex.decode(s));

void main() {
  test('ECDH auf secp256k1 liefert den erwarteten Sitzungsschluessel', () {
    // Der teuerste und plattformabhaengigste Schritt: Punktmultiplikation mit
    // BigInt. Unter dart2js liegt dahinter JavaScript-BigInt statt der
    // VM-Implementierung.
    expect(
      hex.encode(
          Nip44.conversationKey(privkeyHex: _sec1, pubkeyHex: _pub2)),
      _conversationKey,
    );
  });

  test('verschluesselt bitgenau wie die Referenz', () {
    final key = Nip44.conversationKey(privkeyHex: _edSec1, pubkeyHex: _edPub2);
    expect(hex.encode(key), _edKey);
    expect(Nip44.encrypt('a', key, nonce: _unhex(_edNonce)), _edPayload);
  });

  test('entschluesselt die Referenz-Nutzlast', () {
    expect(Nip44.decrypt(_edPayload, _unhex(_edKey)), 'a');
  });

  test('weist falschen MAC ab', () {
    expect(() => Nip44.decrypt(_badMacPayload, _unhex(_badMacKey)),
        throwsA(isA<Nip44Exception>()));
  });

  test('weist gefaelschte Padding-Laenge ab', () {
    expect(() => Nip44.decrypt(_badPaddingPayload, _unhex(_badPaddingKey)),
        throwsA(isA<Nip44Exception>()));
  });

  test('Hin und Rueckweg mit zufaelliger Nonce', () {
    final key = Nip44.conversationKey(privkeyHex: _sec1, pubkeyHex: _pub2);
    const text = 'Grüße vom Meetup 🧡';
    expect(Nip44.decrypt(Nip44.encrypt(text, key), key), text);
  });
}
