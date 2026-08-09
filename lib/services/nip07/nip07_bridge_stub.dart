// Nicht-Web-Umsetzung der NIP-07-Bruecke.
//
// NIP-07 ist per Definition ein Browser-Standard: die Erweiterung stellt
// `window.nostr` bereit. Auf iOS und Android gibt es das nicht — dort ist
// Amber (NIP-55) der Weg zum externen Signer.
//
// Diese Datei existiert nur, damit `dart:js_interop` nicht in den
// Mobil-Build gerät. Der Import wuerde dort schon beim Uebersetzen
// scheitern, deshalb der bedingte Export in nip07_bridge.dart.

import 'nip07_exception.dart';

/// Auf iOS/Android niemals verfuegbar.
Future<bool> nip07Available() async => false;

Future<String> nip07GetPublicKey() async =>
    throw const Nip07Exception('NIP-07 gibt es nur im Browser.');

Future<Map<String, dynamic>> nip07SignEvent(
        Map<String, dynamic> unsigned) async =>
    throw const Nip07Exception('NIP-07 gibt es nur im Browser.');
