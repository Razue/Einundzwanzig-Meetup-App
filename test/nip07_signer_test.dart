// Prueft die drei Sicherheitspruefungen des NIP-07-Signers.
//
// Sie sind der sicherheitsrelevante Teil: eine Erweiterung ist fremder Code,
// den der Nutzer installiert hat. Signiert sie mit einem anderen Konto oder
// veraendert Typ oder Inhalt, darf die App das nicht stillschweigend
// uebernehmen — sie wuerde sonst Fremdes unter dem Namen des Nutzers
// veroeffentlichen und ihre eigene Logik darauf aufbauen.
//
// Moeglich wird das durch die debugSignFn-Naht: nip07SignEvent ist eine
// Top-Level-Funktion hinter einem bedingten Export und nicht ersetzbar.
import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';

const _mine =
    'fa5e3477d2d6b92d667dcab66c8bbb1527014599c5eecddd545e3a39d7870268';
const _someoneElse =
    '0000000000000000000000000000000000000000000000000000000000000001';

// Platzhalter in plausibler Laenge. Der Signer prueft die Signatur nicht
// kryptographisch — das tut die Erweiterung — sondern nur, dass ueberhaupt
// eine da ist.
const _sig =
    'abababababababababababababababababababababababababababababababab'
    'abababababababababababababababababababababababababababababababab';
const _eventId =
    'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd';

/// Baut eine Antwort, wie eine Erweiterung sie liefern wuerde.
Map<String, dynamic> reply({
  String pubkey = _mine,
  int kind = 1,
  String content = 'hallo',
  List<dynamic>? tags,
  String sig = _sig,
}) =>
    {
      'id': _eventId,
      'pubkey': pubkey,
      'created_at': 1786000000,
      'kind': kind,
      'tags': tags ?? [['t', 'test']],
      'content': content,
      'sig': sig,
    };

Nip07NostrSigner signerReturning(Map<String, dynamic> r) =>
    Nip07NostrSigner(expectedPubkeyHex: _mine, debugSignFn: (_) async => r);

void main() {
  group('Der gute Fall', () {
    test('uebernimmt id, sig und created_at der Erweiterung', () async {
      final signed = await signerReturning(reply()).signEvent(
          kind: 1, tags: [['t', 'test']], content: 'hallo');

      expect(signed.pubkey, _mine);
      expect(signed.id, _eventId);
      expect(signed.sig, _sig);
      // created_at MUSS von der Erweiterung kommen: id und sig sind darueber
      // berechnet, ein eigener Zeitstempel machte das Event ungueltig.
      expect(signed.createdAt, 1786000000);
    });

    test('uebernimmt normalisierte Tags der Erweiterung', () async {
      // Legitimer Fall: die Erweiterung sortiert oder ergaenzt Tags. Die
      // Caller-Kopie waere dann falsch, weil id/sig ueber die normalisierte
      // Form berechnet sind.
      final signed = await signerReturning(
        reply(tags: [['t', 'test'], ['client', 'alby']]),
      ).signEvent(kind: 1, tags: [['t', 'test']], content: 'hallo');

      expect(signed.tags, [
        ['t', 'test'],
        ['client', 'alby'],
      ]);
    });

    test('faellt bei kaputtem tags-Format auf die Caller-Tags zurueck', () async {
      final signed = await signerReturning(reply(tags: ['kein-array']))
          .signEvent(kind: 1, tags: [['t', 'test']], content: 'hallo');
      expect(signed.tags, [['t', 'test']]);
    });
  });

  group('Sicherheitspruefungen', () {
    test('anderes Konto -> WrongAccountException', () async {
      // Der Nutzer hat in der Erweiterung das Konto gewechselt. Ohne diese
      // Pruefung wuerde die App eine fremde Signatur als die eigene ausgeben.
      await expectLater(
        signerReturning(reply(pubkey: _someoneElse)).signEvent(
            kind: 1, tags: const [], content: 'hallo'),
        throwsA(isA<WrongAccountException>()),
      );
    });

    test('veraenderter Event-Typ -> SigningException', () async {
      await expectLater(
        signerReturning(reply(kind: 4)).signEvent(
            kind: 1, tags: const [], content: 'hallo'),
        throwsA(isA<SigningException>()),
      );
    });

    test('veraenderter Inhalt -> SigningException', () async {
      // Der gefaehrlichste Fall: die App wuerde fremden Text unter dem Namen
      // des Nutzers veroeffentlichen.
      await expectLater(
        signerReturning(reply(content: 'etwas ganz anderes')).signEvent(
            kind: 1, tags: const [], content: 'hallo'),
        throwsA(isA<SigningException>()),
      );
    });

    test('fehlende Signatur -> SigningException', () async {
      await expectLater(
        signerReturning(reply(sig: '')).signEvent(
            kind: 1, tags: const [], content: 'hallo'),
        throwsA(isA<SigningException>()),
      );
    });
  });
}
