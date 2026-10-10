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
//
// Eine nicht leere Signatur reicht nicht. Die guten Fälle sind echt
// signiert; eine Platzhalter-Signatur wird abgewiesen.
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart' show Event, Keychain;
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';

const _mine =
    'fa5e3477d2d6b92d667dcab66c8bbb1527014599c5eecddd545e3a39d7870268';
const _someoneElse =
    '0000000000000000000000000000000000000000000000000000000000000001';

// Platzhalter in plausibler Laenge. Kind, Inhalt und Konto können stimmen
// und die Signatur trotzdem nicht dazu gehören.
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

/// Echt signierte Antwort. [pubkey] der Erweiterung ist der des Schlüsselpaars.
Map<String, dynamic> signedReply(
  Keychain kc, {
  int kind = 1,
  String content = 'hallo',
  List<List<String>>? tags,
}) {
  final ev = Event.from(
    kind: kind,
    tags: tags ?? const [
      ['t', 'test'],
    ],
    content: content,
    privkey: kc.private,
    createdAt: 1786000000,
  );
  return {
    'id': ev.id,
    'pubkey': ev.pubkey,
    'created_at': ev.createdAt,
    'kind': ev.kind,
    'tags': ev.tags,
    'content': ev.content,
    'sig': ev.sig,
  };
}

void main() {
  group('Der gute Fall', () {
    test('uebernimmt id, sig und created_at der Erweiterung', () async {
      final kc = Keychain.generate();
      final raw = signedReply(kc);
      final signed = await Nip07NostrSigner(
        expectedPubkeyHex: kc.public,
        debugSignFn: (_) async => raw,
      ).signEvent(kind: 1, tags: [
        ['t', 'test']
      ], content: 'hallo');

      expect(signed.pubkey, kc.public);
      expect(signed.id, raw['id']);
      expect(signed.sig, raw['sig']);
      // created_at MUSS von der Erweiterung kommen: id und sig sind darueber
      // berechnet, ein eigener Zeitstempel machte das Event ungueltig.
      expect(signed.createdAt, 1786000000);
    });

    test('uebernimmt normalisierte Tags der Erweiterung', () async {
      // Legitimer Fall: die Erweiterung sortiert oder ergaenzt Tags und
      // signiert diese Fassung. Die Caller-Kopie waere dann falsch.
      final kc = Keychain.generate();
      final tags = [
        ['t', 'test'],
        ['client', 'alby'],
      ];
      final raw = signedReply(kc, tags: tags);
      final signed = await Nip07NostrSigner(
        expectedPubkeyHex: kc.public,
        debugSignFn: (_) async => raw,
      ).signEvent(kind: 1, tags: [
        ['t', 'test']
      ], content: 'hallo');

      expect(signed.tags, tags);
    });

    test('kaputtes tags-Format wird abgewiesen', () async {
      // Unlesbare Tags kann man nicht gegen die Signatur halten. Auf die
      // Caller-Kopie auszuweichen und eine ungeprüfte Signatur anzunehmen
      // würde genau die Lücke öffnen, die isValid schließt.
      await expectLater(
        signerReturning(reply(tags: ['kein-array'])).signEvent(
            kind: 1, tags: [
          ['t', 'test']
        ], content: 'hallo'),
        throwsA(isA<SigningException>()),
      );
    });

    test('Platzhaltersignatur wird abgewiesen', () async {
      await expectLater(
        signerReturning(reply()).signEvent(
            kind: 1, tags: [
          ['t', 'test']
        ], content: 'hallo'),
        throwsA(isA<SigningException>()),
      );
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
