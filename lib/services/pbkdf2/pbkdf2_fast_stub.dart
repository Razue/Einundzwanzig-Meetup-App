import 'dart:typed_data';

/// Ausserhalb des Browsers gibt es kein WebCrypto.
///
/// `null` heisst nicht „Fehler", sondern „hier nicht verfügbar" — der Aufrufer
/// rechnet dann in Dart weiter, nativ in einem Isolate. Nativ ist das auch
/// vertretbar: AOT-Dart braucht für 600.000 Runden Sekunden, nicht Minuten.
/// Untragbar war nur der Browser, wo dieselbe Rechnung unter dart2js rund
/// 100 Sekunden dauerte und dabei die Oberfläche blockierte.
Future<Uint8List?> pbkdf2Fast({
  required List<int> password,
  required List<int> salt,
  required int iterations,
  required int keyBytes,
}) async =>
    null;
