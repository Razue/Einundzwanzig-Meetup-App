// ============================================
// NIP-49 — passwortverschlüsselter privater Schlüssel (`ncryptsec`)
// ============================================
// WOFÜR: ein Backup des nsec, das JEDE andere Nostr-App lesen kann.
//
// Bisher gab es nur zwei Wege, den Schlüssel aus dieser App zu bekommen:
// das eigene `.21bkp` (kann keine andere App) oder den nackten nsec im
// Klartext. Wer seinen Schlüssel in einen Signer wie Amber oder Clave
// überführen wollte — der Weg, den „Anderen Signer verbinden" voraussetzt —
// musste ihn also unverschlüsselt durch die Gegend kopieren.
//
// `ncryptsec1…` löst das: passwortverschlüsselt, gefahrlos in einem
// Passwortmanager ablegbar, und in Amber, Clave, Signet, nsec.app und den
// üblichen Clients direkt importierbar.
//
// AUFBAU (91 Bytes vor der bech32-Kodierung):
//   1  Version              0x02
//   1  log_n                Zweierpotenz für scrypt
//  16  Salt
//  24  Nonce                XChaCha20-Poly1305
//   1  Schlüssel-Sicherheit  gleichzeitig AAD
//  48  Chiffrat             32 Byte Schlüssel + 16 Byte Prüfsumme
//
// Schlüsselableitung: scrypt(NFKC(Passwort), Salt, N = 2^log_n, r = 8, p = 1).
//
// XChaCha20-Poly1305 kommt aus package:cryptography. pointycastles Fassung
// scheitert im Browser ("full width integer not supported") — sein Poly1305
// braucht 64-Bit-Ganzzahlen, die dart2js nicht hat.
// Geprüft gegen den offiziellen Testvektor des NIPs (test/nip49_test.dart).
// ============================================

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:bech32/bech32.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/scrypt.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

class Nip49Exception implements Exception {
  final String message;
  const Nip49Exception(this.message);

  @override
  String toString() => message;
}

/// Wie sorgsam wurde mit dem Schlüssel bisher umgegangen? Wandert als AAD in
/// die Verschlüsselung, ist also nicht fälschbar.
enum KeySecurity {
  /// War schon einmal im Klartext unterwegs (z. B. exportiert, kopiert).
  insecure(0x00),

  /// Hat das Gerät nie im Klartext verlassen.
  secure(0x01),

  /// Unbekannt.
  unknown(0x02);

  const KeySecurity(this.byte);
  final int byte;

  static KeySecurity fromByte(int b) => switch (b) {
        0x00 => KeySecurity.insecure,
        0x01 => KeySecurity.secure,
        _ => KeySecurity.unknown,
      };
}

class Nip49 {
  Nip49._();

  static const int _version = 0x02;
  static const String _hrp = 'ncryptsec';

  /// Vom NIP als Beispiel genannt und in der Praxis üblich. Höher heisst
  /// sicherer und langsamer: der Speicherbedarf ist 128 · 2^log_n · r Bytes,
  /// bei 16 also 64 MB.
  static const int defaultLogN = 16;

  /// bech32 begrenzt sich per Voreinstellung auf 90 Zeichen (BIP-173).
  /// `ncryptsec` ist mit 91 Datenbytes deutlich länger — die Grenze gilt für
  /// Bitcoin-Adressen, nicht für Nostr.
  static const int _maxBech32Length = 5000;

  static final Random _random = Random.secure();

  /// Verschlüsselt einen privaten Schlüssel (hex) zu `ncryptsec1…`.
  ///
  /// Achtung: das ist rechenintensiv (scrypt). Aufrufer müssen einen sichtbaren
  /// Wartezustand zeigen.
  static Future<String> encrypt(
    String privkeyHex,
    String password, {
    int logN = defaultLogN,
    KeySecurity keySecurity = KeySecurity.unknown,
  }) async {
    final privkey = _decodePrivkey(privkeyHex);
    if (password.isEmpty) {
      throw const Nip49Exception('Ohne Passwort gibt es keine Verschlüsselung.');
    }
    if (logN < 1 || logN > 22) {
      throw Nip49Exception('log_n ausserhalb des sinnvollen Bereichs: $logN');
    }

    final salt = _randomBytes(16);
    final nonce = _randomBytes(24);
    final key = _scrypt(password, salt, logN);

    final ciphertext = await _seal(
      key: key,
      nonce: nonce,
      aad: Uint8List.fromList([keySecurity.byte]),
      plaintext: privkey,
    );

    final payload = Uint8List(91)
      ..[0] = _version
      ..[1] = logN
      ..setRange(2, 18, salt)
      ..setRange(18, 42, nonce)
      ..[42] = keySecurity.byte
      ..setRange(43, 91, ciphertext);

    return bech32.encode(
        Bech32(_hrp, _toWords(payload)), _maxBech32Length);
  }

  /// Liest `ncryptsec1…` und gibt den privaten Schlüssel als hex zurück.
  static Future<String> decrypt(String ncryptsec, String password) async {
    final payload = _decodeBech32(ncryptsec.trim());

    if (payload.length != 91) {
      throw Nip49Exception(
          'Unerwartete Länge: ${payload.length} statt 91 Bytes.');
    }
    if (payload[0] != _version) {
      throw Nip49Exception('Unbekannte NIP-49-Version: ${payload[0]}.');
    }

    final logN = payload[1];
    final salt = Uint8List.sublistView(payload, 2, 18);
    final nonce = Uint8List.sublistView(payload, 18, 42);
    final keySecurity = payload[42];
    final ciphertext = Uint8List.sublistView(payload, 43, 91);

    final key = _scrypt(password, salt, logN);
    final Uint8List plain;
    try {
      plain = await _open(
        key: key,
        nonce: nonce,
        aad: Uint8List.fromList([keySecurity]),
        sealed: ciphertext,
      );
    } catch (_) {
      // Die Prüfsumme schlägt an: entweder falsches Passwort oder verändertes
      // Chiffrat. Unterscheiden lässt sich das nicht, und es wäre auch nicht
      // hilfreich.
      throw const Nip49Exception(
          'Falsches Passwort — oder der Schlüssel ist beschädigt.');
    }
    if (plain.length != 32) {
      throw const Nip49Exception('Entschlüsselter Schlüssel hat nicht 32 Bytes.');
    }
    return hex.encode(plain);
  }

  /// Nur die Sicherheitsstufe lesen, ohne zu entschlüsseln — geht ohne
  /// Passwort, weil das Byte im Klartext steht.
  static KeySecurity keySecurityOf(String ncryptsec) {
    final payload = _decodeBech32(ncryptsec.trim());
    if (payload.length != 91) {
      throw const Nip49Exception('Unerwartete Länge.');
    }
    return KeySecurity.fromByte(payload[42]);
  }

  /// NUR für Tests: die rohe 91-Byte-Nutzlast lesen und wieder kodieren.
  ///
  /// Ohne diese Naht liesse sich nicht prüfen, dass das Sicherheits-Byte als
  /// AAD GEBUNDEN ist und nicht bloss mitgeschrieben wird — dafür muss man den
  /// Datensatz verändern, ohne ihn neu zu verschlüsseln.
  @visibleForTesting
  static Uint8List debugDecodePayload(String ncryptsec) =>
      _decodeBech32(ncryptsec.trim());

  @visibleForTesting
  static String debugEncodePayload(Uint8List payload) =>
      bech32.encode(Bech32(_hrp, _toWords(payload)), _maxBech32Length);

  // ---------- scrypt ----------

  static Uint8List _scrypt(String password, Uint8List salt, int logN) {
    // Das NIP verlangt NFKC. Bei ASCII-Passwörtern ändert das nichts, bei
    // Umlauten oder zusammengesetzten Zeichen sehr wohl — und ohne
    // Normalisierung liesse sich der Schlüssel in einer anderen App nicht
    // entschlüsseln.
    final normalized = unorm.nfkc(password);
    final derivator = Scrypt()
      ..init(ScryptParameters(1 << logN, 8, 1, 32, salt));
    return derivator.process(Uint8List.fromList(utf8.encode(normalized)));
  }

  // ---------- XChaCha20-Poly1305 ----------

  /// XChaCha20-Poly1305 über `package:cryptography`.
  ///
  /// Hier stand zuerst ein selbst gebautes HChaCha20 plus pointycastles
  /// ChaCha20-Poly1305. Das lief in der VM, brach im Browser aber ab:
  ///
  ///   PlatformException: full width integer not supported on this platform
  ///
  /// pointycastles Poly1305 braucht 64-Bit-Ganzzahlen, und die hat dart2js
  /// nicht. Ausserdem ist dessen `BaseAEADCipher.process()` für das
  /// Verschlüsseln unbrauchbar — es reserviert nur `data.length` Bytes und ruft
  /// `doFinal()` nie auf, die Prüfsumme fehlte also.
  ///
  /// `cryptography` bringt XChaCha20-Poly1305 fertig mit, plattformübergreifend
  /// — und ersetzt damit rund 60 Zeilen Handarbeit an einer Stelle, an der
  /// Handarbeit besonders teuer ist. Der Preis ist eine asynchrone API.
  static Future<Uint8List> _seal({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List plaintext,
  }) async {
    final box = await Xchacha20.poly1305Aead().encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
      aad: aad,
    );
    // NIP-49 legt Chiffrat und Prüfsumme hintereinander in ein Feld.
    return Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
  }

  static Future<Uint8List> _open({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List sealed,
  }) async {
    if (sealed.length <= _macBytes) {
      throw const Nip49Exception('Chiffrat zu kurz.');
    }
    final split = sealed.length - _macBytes;
    final plain = await Xchacha20.poly1305Aead().decrypt(
      SecretBox(
        Uint8List.sublistView(sealed, 0, split),
        nonce: nonce,
        mac: Mac(Uint8List.sublistView(sealed, split)),
      ),
      secretKey: SecretKey(key),
      aad: aad,
    );
    return Uint8List.fromList(plain);
  }

  static const int _macBytes = 16;

  // ---------- bech32 ----------

  static Uint8List _decodeBech32(String value) {
    if (!value.toLowerCase().startsWith('${_hrp}1')) {
      throw const Nip49Exception(
          'Das ist kein ncryptsec — es muss mit "ncryptsec1" beginnen.');
    }
    final Bech32 decoded;
    try {
      decoded = bech32.decode(value, _maxBech32Length);
    } catch (e) {
      throw Nip49Exception('Unlesbar: $e');
    }
    if (decoded.hrp != _hrp) {
      throw Nip49Exception('Falsches Präfix: ${decoded.hrp}.');
    }
    return _fromWords(decoded.data);
  }

  /// 8 Bit → 5 Bit, wie bech32 es verlangt.
  static List<int> _toWords(List<int> bytes) =>
      _convertBits(bytes, 8, 5, pad: true);

  static Uint8List _fromWords(List<int> words) =>
      Uint8List.fromList(_convertBits(words, 5, 8, pad: false));

  static List<int> _convertBits(List<int> data, int from, int to,
      {required bool pad}) {
    var acc = 0;
    var bits = 0;
    final out = <int>[];
    final maxValue = (1 << to) - 1;

    for (final value in data) {
      if (value < 0 || (value >> from) != 0) {
        throw const Nip49Exception('Ungültiger Wert in der Kodierung.');
      }
      acc = (acc << from) | value;
      bits += from;
      while (bits >= to) {
        bits -= to;
        out.add((acc >> bits) & maxValue);
      }
    }

    if (pad) {
      if (bits > 0) out.add((acc << (to - bits)) & maxValue);
    } else if (bits >= from || ((acc << (to - bits)) & maxValue) != 0) {
      throw const Nip49Exception('Überzählige Bits in der Kodierung.');
    }
    return out;
  }

  // ---------- Hilfen ----------

  static Uint8List _decodePrivkey(String privkeyHex) {
    final Uint8List bytes;
    try {
      bytes = Uint8List.fromList(hex.decode(privkeyHex.trim()));
    } on FormatException {
      throw const Nip49Exception('Der private Schlüssel ist kein gültiges Hex.');
    }
    if (bytes.length != 32) {
      throw Nip49Exception(
          'Der private Schlüssel muss 32 Bytes haben, hat ${bytes.length}.');
    }
    return bytes;
  }

  static Uint8List _randomBytes(int count) {
    final out = Uint8List(count);
    for (var i = 0; i < count; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }
}
