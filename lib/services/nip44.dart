// ============================================
// NIP-44 v2 — Verschlüsselung für den Remote-Signer-Transport (NIP-46)
// ============================================
// NIP-46 (Bunker) schreibt NIP-44 als Verschlüsselung der kind-24133-Events
// vor. Ohne NIP-44 gibt es keinen Remote-Signer — und damit auf iOS keinen
// externen Signer überhaupt, weil es dort weder Amber (NIP-55) noch eine
// Browser-Erweiterung (NIP-07) gibt.
//
// WARUM SELBST GEBAUT UND NICHT ALS PAKET:
// NIP-44 liegt auf pub.dev nur innerhalb von `ndk`, `nip46` und
// `nostr_bunker`. Alle drei hängen an `bip340 ^0.3.0`, während das hier in
// 18 Dateien genutzte `nostr 1.5.0` `bip340 ^0.2.0` festnagelt — die
// Auflösung scheitert an genau dieser Stelle (dieselbe Wand wie beim
// `nostr` 2.x-Versuch). Ein eigenständiges NIP-44-Paket existiert nicht.
// Der Eigenbau umgeht das vollständig: er braucht nur `pointycastle`
// (ohnehin über `encrypt` im Baum) und fasst `bip340`/`nostr` nicht an.
//
// Reine Dart-Umsetzung, also auch im Browser lauffähig.
//
// GEPRÜFT gegen die offiziellen Testvektoren des NIPs
// (test/nip44_vectors_test.dart, 128 Fälle) — einschließlich der
// Negativfälle: falscher MAC, kaputtes Padding, Kurvenpunkte auf dem Twist.
// Eine NIP-44-Umsetzung, die nur gegen sich selbst prüft, ist wertlos: sie
// muss mit fremden Signern zusammenpassen.
//
// Ablauf (NIP-44 v2):
//   conversation_key = HKDF-Extract(IKM: ECDH-x, salt: "nip44-v2")
//   chacha_key|chacha_nonce|hmac_key = HKDF-Expand(conversation_key, nonce, 76)
//   payload = base64( 0x02 | nonce | ChaCha20(padded) | HMAC(nonce|ct) )
// ============================================

import 'dart:convert';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/hkdf.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/stream/chacha7539.dart';

/// Fehler im NIP-44-Verfahren. Die Meldungen sind absichtlich unspezifisch
/// gegenüber dem Angreifer, aber für das Log brauchbar.
class Nip44Exception implements Exception {
  final String message;
  const Nip44Exception(this.message);

  @override
  String toString() => 'Nip44Exception: $message';
}

class Nip44 {
  Nip44._();

  static const int _version = 2;

  /// Grenzen aus dem NIP: ein leeres Klartext-Feld ist unzulässig.
  static const int minPlaintextSize = 1;
  static const int maxPlaintextSize = 65535;

  // Längengrenzen der Nutzlast. Die Prüfung auf die Länge des Base64-Strings
  // muss VOR dem Dekodieren greifen, sonst würde ein 4 Zeichen langer
  // Schnipsel sauber dekodieren und erst später auffallen.
  static const int _minPayloadChars = 132; // base64(99 Bytes)
  static const int _maxPayloadChars = 87472; // base64(65603 Bytes)
  static const int _minPayloadBytes = 99; // 1 + 32 + 34 + 32
  static const int _maxPayloadBytes = 65603; // 1 + 32 + 65538 + 32

  static final ECDomainParameters _curve = ECCurve_secp256k1();
  static final Uint8List _salt =
      Uint8List.fromList(utf8.encode('nip44-v2'));
  static final Random _random = Random.secure();
  static final BigInt _byteMask = BigInt.from(0xff);

  /// Gemeinsamer Sitzungsschlüssel zweier Parteien.
  ///
  /// [pubkeyHex] ist ein x-only-Schlüssel wie überall in Nostr (32 Bytes).
  /// Die y-Koordinate wird als gerade angenommen; für das Ergebnis ist das
  /// ohne Belang, weil P und -P dieselbe x-Koordinate haben.
  static Uint8List conversationKey({
    required String privkeyHex,
    required String pubkeyHex,
  }) {
    final d = _requirePrivkey(privkeyHex);
    final q = _liftX(pubkeyHex);

    final BigInt sharedX;
    try {
      sharedX = (ECDHBasicAgreement()..init(ECPrivateKey(d, _curve)))
          .calculateAgreement(ECPublicKey(q, _curve));
    } catch (e) {
      throw Nip44Exception('ECDH fehlgeschlagen: $e');
    }

    // HKDF-Extract ist genau ein HMAC über das gemeinsame Geheimnis.
    return _hmac(_salt, _toFixed32(sharedX));
  }

  /// Verschlüsselt [plaintext]. [nonce] nur für Testvektoren setzen —
  /// im Betrieb muss die Nonce zufällig sein, sonst fällt die Sicherheit
  /// des Stromchiffrats zusammen.
  static String encrypt(
    String plaintext,
    Uint8List conversationKey, {
    @visibleForTesting Uint8List? nonce,
  }) {
    final n = nonce ?? _randomNonce();
    final keys = messageKeys(conversationKey, n);
    final padded = _pad(plaintext);

    final ciphertext = (ChaCha7539Engine()
          ..init(true,
              ParametersWithIV(KeyParameter(keys.chachaKey), keys.chachaNonce)))
        .process(padded);
    final mac = _hmacWithAad(keys.hmacKey, ciphertext, n);

    final out = Uint8List(1 + 32 + ciphertext.length + 32);
    out[0] = _version;
    out.setRange(1, 33, n);
    out.setRange(33, 33 + ciphertext.length, ciphertext);
    out.setRange(33 + ciphertext.length, out.length, mac);
    return base64.encode(out);
  }

  /// Entschlüsselt eine NIP-44-Nutzlast. Wirft [Nip44Exception], wenn die
  /// Nutzlast manipuliert wurde oder der Schlüssel nicht passt.
  static String decrypt(String payload, Uint8List conversationKey) {
    final data = _decodePayload(payload);
    final nonce = Uint8List.sublistView(data, 1, 33);
    final ciphertext = Uint8List.sublistView(data, 33, data.length - 32);
    final mac = Uint8List.sublistView(data, data.length - 32);

    final keys = messageKeys(conversationKey, nonce);
    if (!_constantTimeEquals(
        _hmacWithAad(keys.hmacKey, ciphertext, nonce), mac)) {
      throw const Nip44Exception('MAC stimmt nicht.');
    }

    final padded = (ChaCha7539Engine()
          ..init(true,
              ParametersWithIV(KeyParameter(keys.chachaKey), keys.chachaNonce)))
        .process(ciphertext);
    return _unpad(padded);
  }

  /// HKDF-Expand auf 76 Bytes, aufgeteilt in die drei Nachrichtenschlüssel.
  @visibleForTesting
  static ({Uint8List chachaKey, Uint8List chachaNonce, Uint8List hmacKey})
      messageKeys(Uint8List conversationKey, Uint8List nonce) {
    if (conversationKey.length != 32) {
      throw const Nip44Exception('Sitzungsschlüssel muss 32 Bytes haben.');
    }
    if (nonce.length != 32) {
      throw const Nip44Exception('Nonce muss 32 Bytes haben.');
    }
    // skipExtract: der Sitzungsschlüssel IST bereits das PRK.
    final out = (HKDFKeyDerivator(SHA256Digest())
          ..init(HkdfParameters(conversationKey, 76, null, nonce, true)))
        .process(Uint8List(0));
    return (
      chachaKey: Uint8List.sublistView(out, 0, 32),
      chachaNonce: Uint8List.sublistView(out, 32, 44),
      hmacKey: Uint8List.sublistView(out, 44, 76),
    );
  }

  /// Länge des gepolsterten Klartexts. Absichtlich ganzzahlig gerechnet
  /// (`bitLength` statt `log2`), damit es keine Fließkomma-Kanten gibt:
  /// für x >= 32 gilt `floor(log2(x)) + 1 == x.bitLength`.
  @visibleForTesting
  static int calcPaddedLen(int unpaddedLen) {
    if (unpaddedLen <= 32) return 32;
    final nextPower = 1 << (unpaddedLen - 1).bitLength;
    final chunk = nextPower <= 256 ? 32 : nextPower ~/ 8;
    return chunk * ((unpaddedLen - 1) ~/ chunk + 1);
  }

  // ---------- intern ----------

  static Uint8List _pad(String plaintext) {
    final unpadded = Uint8List.fromList(utf8.encode(plaintext));
    final len = unpadded.length;
    if (len < minPlaintextSize || len > maxPlaintextSize) {
      throw Nip44Exception('Ungültige Nachrichtenlänge: $len Bytes.');
    }
    final padded = Uint8List(2 + calcPaddedLen(len));
    padded[0] = (len >> 8) & 0xff;
    padded[1] = len & 0xff;
    padded.setRange(2, 2 + len, unpadded);
    return padded;
  }

  static String _unpad(Uint8List padded) {
    if (padded.length < 2) {
      throw const Nip44Exception('Ungültiges Padding.');
    }
    final len = (padded[0] << 8) | padded[1];
    // Die Längenprüfung des Puffers ist der Kern: sie schließt aus, dass ein
    // Angreifer durch eine erfundene Länge Teile des Puffers abschneidet.
    if (len < minPlaintextSize ||
        len > maxPlaintextSize ||
        padded.length != 2 + calcPaddedLen(len)) {
      throw const Nip44Exception('Ungültiges Padding.');
    }
    return utf8.decode(Uint8List.sublistView(padded, 2, 2 + len));
  }

  static Uint8List _decodePayload(String payload) {
    if (payload.startsWith('#')) {
      throw const Nip44Exception('Unbekannte NIP-44-Version.');
    }
    if (payload.length < _minPayloadChars ||
        payload.length > _maxPayloadChars) {
      throw Nip44Exception('Ungültige Nutzlastlänge: ${payload.length}.');
    }

    final Uint8List data;
    try {
      data = base64.decode(payload);
    } on FormatException {
      throw const Nip44Exception('Nutzlast ist kein gültiges Base64.');
    }

    if (data.length < _minPayloadBytes || data.length > _maxPayloadBytes) {
      throw Nip44Exception('Ungültige Nutzlastlänge: ${data.length} Bytes.');
    }
    if (data[0] != _version) {
      throw Nip44Exception('Unbekannte NIP-44-Version: ${data[0]}.');
    }
    return data;
  }

  static BigInt _requirePrivkey(String privkeyHex) {
    _decodeHex32(privkeyHex, 'Privater Schlüssel');
    final d = BigInt.parse(privkeyHex, radix: 16);
    if (d == BigInt.zero || d >= _curve.n) {
      throw const Nip44Exception(
          'Privater Schlüssel liegt außerhalb der Kurvenordnung.');
    }
    return d;
  }

  /// Hebt einen x-only-Schlüssel auf einen Kurvenpunkt. Punkte, die nicht auf
  /// secp256k1 liegen (kein Wurzel-Kandidat), werden hier abgewiesen — das
  /// ist die Abwehr gegen Punkte auf dem Twist.
  static ECPoint _liftX(String pubkeyHex) {
    final x = _decodeHex32(pubkeyHex, 'Öffentlicher Schlüssel');
    final compressed = Uint8List(33);
    compressed[0] = 0x02;
    compressed.setRange(1, 33, x);

    ECPoint? q;
    try {
      q = _curve.curve.decodePoint(compressed);
    } catch (_) {
      q = null;
    }
    if (q == null || q.isInfinity) {
      throw const Nip44Exception(
          'Öffentlicher Schlüssel liegt nicht auf der Kurve.');
    }
    return q;
  }

  static Uint8List _decodeHex32(String value, String label) {
    final Uint8List bytes;
    try {
      bytes = Uint8List.fromList(hex.decode(value));
    } on FormatException {
      throw Nip44Exception('$label ist kein gültiges Hex.');
    }
    if (bytes.length != 32) {
      throw Nip44Exception('$label muss 32 Bytes haben, hat ${bytes.length}.');
    }
    return bytes;
  }

  static Uint8List _toFixed32(BigInt value) {
    final out = Uint8List(32);
    var v = value;
    for (var i = 31; i >= 0; i--) {
      out[i] = (v & _byteMask).toInt();
      v = v >> 8;
    }
    return out;
  }

  static Uint8List _hmac(Uint8List key, Uint8List data) {
    final mac = HMac(SHA256Digest(), 64)..init(KeyParameter(key));
    return mac.process(data);
  }

  /// HMAC über `aad | message` — bei NIP-44 ist die Nonce das AAD.
  static Uint8List _hmacWithAad(
      Uint8List key, Uint8List message, Uint8List aad) {
    if (aad.length != 32) {
      throw const Nip44Exception('AAD muss 32 Bytes haben.');
    }
    final mac = HMac(SHA256Digest(), 64)..init(KeyParameter(key));
    mac.update(aad, 0, aad.length);
    mac.update(message, 0, message.length);
    final out = Uint8List(mac.macSize);
    mac.doFinal(out, 0);
    return out;
  }

  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static Uint8List _randomNonce() {
    final n = Uint8List(32);
    for (var i = 0; i < n.length; i++) {
      n[i] = _random.nextInt(256);
    }
    return n;
  }
}
