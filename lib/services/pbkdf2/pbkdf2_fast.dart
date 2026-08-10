// Schnelle PBKDF2-Ableitung über die Krypto-Umgebung der Plattform.
//
// Bedingter Export, weil `dart:js_interop` im Mobil-Build nicht übersetzt —
// dasselbe Muster wie bei der NIP-07-Brücke.
//
// Ausserhalb des Browsers (und im Browser ohne verfügbares WebCrypto) liefert
// die Funktion `null`. Der Aufrufer rechnet dann selbst weiter. Das ist
// absichtlich so gebaut: die Ableitung MUSS bitgleich bleiben, egal welcher
// Weg genommen wird — sonst wären bestehende Backups nicht mehr lesbar.
export 'pbkdf2_fast_stub.dart'
    if (dart.library.js_interop) 'pbkdf2_fast_web.dart';
