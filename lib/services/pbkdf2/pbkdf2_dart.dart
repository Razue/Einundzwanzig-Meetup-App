// PBKDF2-HMAC-SHA256 in reinem Dart.
//
// Der Rückfallweg, wenn die Krypto-Umgebung der Plattform nicht erreichbar
// ist — und nativ der Normalweg, dort ausgeführt in einem Isolate.
//
// Der Rechenkern ist unverändert aus backup_service übernommen: er hat
// bestehende Backups erzeugt, und jede Abweichung machte die unlesbar. Er
// liegt hier nur deshalb in einer eigenen Datei, weil `compute()` eine
// Top-Level-Funktion und ein versendbares Argument braucht — und weil er so
// gegen eine unabhängige Implementierung testbar ist.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Argument für `compute()`. Nur einfache, zwischen Isolates versendbare
/// Felder.
class Pbkdf2Request {
  final List<int> password;
  final List<int> salt;
  final int iterations;
  final int keyBytes;

  const Pbkdf2Request({
    required this.password,
    required this.salt,
    required this.iterations,
    required this.keyBytes,
  });
}

/// Top-Level, damit `compute()` sie in einen Isolate schicken kann.
Uint8List pbkdf2Dart(Pbkdf2Request request) => pbkdf2DartBytes(
      password: request.password,
      salt: request.salt,
      iterations: request.iterations,
      keyBytes: request.keyBytes,
    );

/// PBKDF2-HMAC-SHA256.
///
/// Key = T1 || T2 || … || T_ceil(keyLen/hashLen), Ti = F(P, S, c, i).
Uint8List pbkdf2DartBytes({
  required List<int> password,
  required List<int> salt,
  required int iterations,
  required int keyBytes,
}) {
  if (iterations < 1) {
    throw ArgumentError.value(iterations, 'iterations', 'muss >= 1 sein');
  }
  if (keyBytes < 1) {
    throw ArgumentError.value(keyBytes, 'keyBytes', 'muss >= 1 sein');
  }

  final hmac = Hmac(sha256, password);
  const hashLength = 32; // SHA-256
  final blocks = (keyBytes + hashLength - 1) ~/ hashLength;

  final out = Uint8List(blocks * hashLength);
  for (var block = 1; block <= blocks; block++) {
    final t = _f(hmac, salt, iterations, block);
    out.setRange((block - 1) * hashLength, block * hashLength, t);
  }
  // Für 32 Byte Schlüssel und SHA-256 ist blocks == 1; die Schleife ist
  // trotzdem allgemein, damit die Funktion nicht still falsch rechnet, wenn
  // jemand später eine andere Schlüssellänge einsetzt.
  return Uint8List.sublistView(out, 0, keyBytes);
}

/// F(P, S, c, i) = U1 XOR U2 XOR … XOR Uc
List<int> _f(Hmac hmac, List<int> salt, int iterations, int blockIndex) {
  // U1 = HMAC(P, S || INT_32_BE(i))
  final saltWithIndex = Uint8List(salt.length + 4);
  saltWithIndex.setRange(0, salt.length, salt);
  saltWithIndex[salt.length + 0] = (blockIndex >> 24) & 0xFF;
  saltWithIndex[salt.length + 1] = (blockIndex >> 16) & 0xFF;
  saltWithIndex[salt.length + 2] = (blockIndex >> 8) & 0xFF;
  saltWithIndex[salt.length + 3] = blockIndex & 0xFF;

  var u = hmac.convert(saltWithIndex).bytes;
  final result = List<int>.from(u);

  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < result.length; j++) {
      result[j] ^= u[j];
    }
  }
  return result;
}

/// Bequemlichkeit für Tests und Aufrufer mit Passwort als Text.
Uint8List pbkdf2DartFromPassword({
  required String password,
  required List<int> salt,
  required int iterations,
  required int keyBytes,
}) =>
    pbkdf2DartBytes(
      password: utf8.encode(password),
      salt: salt,
      iterations: iterations,
      keyBytes: keyBytes,
    );
