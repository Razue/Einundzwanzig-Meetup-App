// Bruecke zu einer NIP-07-Browsererweiterung (Alby, nos2x, Flamingo, …).
//
// Bedingter Export, weil `dart:js_interop` im Mobil-Build nicht uebersetzt.
// Dasselbe Muster nutzt web_socket_channel intern, um dart:io und Browser
// unter einer API zu halten.
//
// Aufrufer sehen nur einfache Dart-Typen und muessen nicht wissen, auf
// welcher Plattform sie laufen — nip07Available() antwortet ausserhalb des
// Browsers schlicht mit false.
export 'nip07_bridge_stub.dart'
    if (dart.library.js_interop) 'nip07_bridge_web.dart';
