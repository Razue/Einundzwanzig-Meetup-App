// Web-Umsetzung: PBKDF2 über WebCrypto (`crypto.subtle`).
//
// WARUM: dieselbe Ableitung in Dart braucht unter dart2js für die 600.000
// Runden rund 100 Sekunden — gemessen im Browser, und dabei stand die
// Oberfläche. WebCrypto rechnet das in nativem Code in Bruchteilen einer
// Sekunde, weil es nicht durch JavaScript läuft.
//
// Das Ergebnis ist bitgleich: PBKDF2-HMAC-SHA256 ist vollständig
// spezifiziert, es gibt keine Freiheitsgrade. Geprüft wird das trotzdem —
// test/pbkdf2_web_equality_test.dart vergleicht im echten Browser gegen einen
// Wert, den eine unabhängige Implementierung (pointycastle) erzeugt hat.
//
// `crypto.subtle` gibt es NUR in einem sicheren Kontext (https oder
// localhost). Auf einer per plain http ausgelieferten Seite fehlt es —
// deshalb liefert diese Funktion dort null und der Aufrufer rechnet selbst.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// `window.crypto.subtle`, oder null wenn es das hier nicht gibt.
JSObject? _subtle() {
  if (!globalContext.has('crypto')) return null;
  final crypto = globalContext.getProperty<JSObject?>('crypto'.toJS);
  if (crypto == null || !crypto.has('subtle')) return null;
  return crypto.getProperty<JSObject?>('subtle'.toJS);
}

Future<Uint8List?> pbkdf2Fast({
  required List<int> password,
  required List<int> salt,
  required int iterations,
  required int keyBytes,
}) async {
  final subtle = _subtle();
  if (subtle == null) return null;

  try {
    // Die Parameter-Objekte werden Feld für Feld gesetzt statt über jsify():
    // salt muss eine BufferSource (Uint8Array) sein, und jsify() macht aus
    // einer Dart-Liste ein gewöhnliches JS-Array — das lehnt WebCrypto ab.
    final importAlgorithm = JSObject()
      ..setProperty('name'.toJS, 'PBKDF2'.toJS);

    // importKey braucht fünf Argumente, callMethod nimmt nur vier.
    final keyMaterial = await subtle.callMethodVarArgs<JSPromise<JSObject>>(
      'importKey'.toJS,
      [
        'raw'.toJS,
        Uint8List.fromList(password).toJS,
        importAlgorithm,
        false.toJS,
        <JSAny?>['deriveBits'.toJS].toJS,
      ],
    ).toDart;

    final deriveAlgorithm = JSObject()
      ..setProperty('name'.toJS, 'PBKDF2'.toJS)
      ..setProperty('salt'.toJS, Uint8List.fromList(salt).toJS)
      ..setProperty('iterations'.toJS, iterations.toJS)
      ..setProperty('hash'.toJS, 'SHA-256'.toJS);

    final bits = await subtle.callMethodVarArgs<JSPromise<JSArrayBuffer>>(
      'deriveBits'.toJS,
      [deriveAlgorithm, keyMaterial, (keyBytes * 8).toJS],
    ).toDart;

    final out = bits.toDart.asUint8List();
    // Sicherheitsnetz: ein falsch langer Schlüssel darf nicht stillschweigend
    // in die Verschlüsselung wandern.
    if (out.length != keyBytes) return null;
    return out;
  } catch (_) {
    // Jeder Fehlschlag führt zurück auf die Dart-Rechnung. Langsam, aber
    // richtig — und ein unlesbares Backup wäre der schlimmere Ausgang.
    return null;
  }
}
