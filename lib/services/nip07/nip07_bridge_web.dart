// Web-Umsetzung der NIP-07-Bruecke.
//
// NIP-07 legt fest, dass eine Browsererweiterung `window.nostr` bereitstellt
// mit mindestens:
//   getPublicKey(): Promise<string>        — hex-pubkey
//   signEvent(event): Promise<Event>       — vollstaendig signiertes Event
//
// Der private Schluessel verlaesst die Erweiterung dabei NIE. Das ist der
// Grund, warum dieser Weg im Browser so viel besser ist als ein importierter
// nsec: der liegt dort zwangsweise in localStorage.
//
// Die Bruecke liefert absichtlich nur einfache Dart-Typen (bool, String, Map)
// nach aussen. So bleibt js_interop vollstaendig in dieser Datei, und der
// Signer im SigningService ist plattformunabhaengig testbar.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'nip07_exception.dart';

/// Holt `window.nostr`, oder null wenn keine Erweiterung da ist.
JSObject? _nostr() {
  // has() vor getProperty(): ein fehlendes Feld liefert undefined, und das
  // als JSObject zu lesen ist je nach Compiler nicht dasselbe wie null.
  if (!globalContext.has('nostr')) return null;
  return globalContext.getProperty<JSObject?>('nostr'.toJS);
}

Future<bool> nip07Available() async => _nostr() != null;

Future<String> nip07GetPublicKey() async {
  final nostr = _nostr();
  if (nostr == null) {
    throw const Nip07Exception('Keine NIP-07-Erweiterung gefunden.');
  }
  try {
    final promise = nostr.callMethod<JSPromise>('getPublicKey'.toJS);
    final result = await promise.toDart;
    final hex = (result as JSString?)?.toDart;
    if (hex == null || hex.length != 64) {
      throw Nip07Exception('Unerwarteter pubkey von der Erweiterung: $hex');
    }
    return hex;
  } on Nip07Exception {
    rethrow;
  } catch (e) {
    // Erweiterungen melden eine Ablehnung als abgewiesenes Promise. Die
    // Texte sind nicht standardisiert, deshalb die Stichwortsuche.
    if (_looksRejected(e)) throw const Nip07RejectedException();
    throw Nip07Exception('getPublicKey fehlgeschlagen: $e');
  }
}

Future<Map<String, dynamic>> nip07SignEvent(
    Map<String, dynamic> unsigned) async {
  final nostr = _nostr();
  if (nostr == null) {
    throw const Nip07Exception('Keine NIP-07-Erweiterung gefunden.');
  }
  try {
    final jsEvent = unsigned.jsify() as JSObject;
    final promise = nostr.callMethod<JSPromise>('signEvent'.toJS, jsEvent);
    final result = await promise.toDart;
    final dart = result.dartify();
    if (dart is! Map) {
      throw Nip07Exception('signEvent lieferte kein Event: $dart');
    }
    // dartify() gibt Map<Object?, Object?> — auf String-Keys normalisieren,
    // damit die Aufrufstelle nicht raten muss.
    return {
      for (final entry in dart.entries) entry.key.toString(): entry.value,
    };
  } on Nip07Exception {
    rethrow;
  } catch (e) {
    if (_looksRejected(e)) throw const Nip07RejectedException();
    throw Nip07Exception('signEvent fehlgeschlagen: $e');
  }
}

/// Hat der Nutzer abgelehnt? Heuristik ueber den Fehlertext.
///
/// NIP-07 schreibt keine Fehlercodes vor. Alby, nos2x und Flamingo melden
/// unterschiedliche Texte, gemeinsam ist ihnen ein Stichwort wie "denied"
/// oder "rejected". Falsch erkannt schadet wenig: dann steht statt
/// "abgelehnt" eine allgemeine Fehlermeldung.
bool _looksRejected(Object e) {
  final s = e.toString().toLowerCase();
  return s.contains('denied') ||
      s.contains('rejected') ||
      s.contains('declined') ||
      s.contains('cancel');
}
