// Stufe A (N1 + N3): Amber-Antwort wie NIP-07 prüfen und
// Backup-Schlüsselkonsistenz erzwingen.
//
// N1: Amber ist fremder Code wie eine Browsererweiterung. Signiert es mit
// einem anderen Konto oder verändert Typ/Inhalt, darf die App das nicht
// stillschweigend übernehmen. Amber nutzt jetzt verifySignerResponse —
// diese Tests prüfen genau die Fälle, die NIP-07 schon abdeckt, über die
// Amber-Antwort-Form ({'event': '<json>'}).
//
// N3: Ein manipuliertes Backup darf keine Identität schreiben, deren npub
// nicht zum privaten Schlüssel passt.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart' show Event, Keychain, Nip19;
import 'package:einundzwanzig_meetup_app/services/backup_service.dart';
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';

const _mine =
    'fa5e3477d2d6b92d667dcab66c8bbb1527014599c5eecddd545e3a39d7870268';
const _someoneElse =
    '0000000000000000000000000000000000000000000000000000000000000001';
const _sig =
    'abababababababababababababababababababababababababababababababab'
    'abababababababababababababababababababababababababababababababab';
const _eventId =
    'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd';

/// Amber liefert das signierte Event als JSON-String in 'event'.
Map<String, dynamic> amberReply({
  String pubkey = _mine,
  int kind = 1,
  String content = 'hallo',
  String sig = _sig,
}) =>
    {
      'event': jsonEncode({
        'id': _eventId,
        'pubkey': pubkey,
        'created_at': 1786000000,
        'kind': kind,
        'tags': [['t', 'test']],
        'content': content,
        'sig': sig,
      }),
    };

void main() {
  group('N1 — Amber-Antwort durch verifySignerResponse', () {
    // Wir testen verifySignerResponse direkt mit der Amber-Antwort-Form,
    // weil der MethodChannel zu Amber im Test nicht erreichbar ist. Genau
    // diese Übergabe ist der geänderte Teil in AmberNostrSigner.signEvent.
    SignedEvent check(Map<String, dynamic> raw) {
      final signed =
          jsonDecode(raw['event'] as String) as Map<String, dynamic>;
      return verifySignerResponse(
        signed: signed,
        expectedPubkeyHex: _mine,
        kind: 1,
        tags: const [['t', 'test']],
        content: 'hallo',
        fallbackCreatedAt: 1786000000,
        actor: 'Amber',
      );
    }

    test('guter Fall: korrekt signierte Amber-Antwort wird übernommen', () {
      final kc = Keychain.generate();
      final event = Event.from(
        kind: 1,
        tags: const [
          ['t', 'test'],
        ],
        content: 'hallo',
        privkey: kc.private,
        createdAt: 1786000000,
      );
      final ev = verifySignerResponse(
        signed: {
          'id': event.id,
          'pubkey': event.pubkey,
          'created_at': event.createdAt,
          'kind': event.kind,
          'tags': event.tags,
          'content': event.content,
          'sig': event.sig,
        },
        expectedPubkeyHex: kc.public,
        kind: 1,
        tags: const [
          ['t', 'test'],
        ],
        content: 'hallo',
        fallbackCreatedAt: 1786000000,
        actor: 'Amber',
      );
      expect(ev.pubkey, kc.public);
      expect(ev.sig, event.sig);
      expect(ev.kind, 1);
      expect(ev.content, 'hallo');
    });

    test('Platzhaltersignatur wird abgewiesen', () {
      expect(() => check(amberReply()), throwsA(isA<SigningException>()));
    });

    test('Kontowechsel -> WrongAccountException', () {
      expect(() => check(amberReply(pubkey: _someoneElse)),
          throwsA(isA<WrongAccountException>()));
    });

    test('veränderter Event-Typ -> SigningException', () {
      expect(() => check(amberReply(kind: 4)),
          throwsA(isA<SigningException>()));
    });

    test('veränderter Inhalt -> SigningException', () {
      // Der gefährlichste Fall: die App würde fremden Text unter dem
      // Namen des Nutzers veröffentlichen.
      expect(() => check(amberReply(content: 'etwas ganz anderes')),
          throwsA(isA<SigningException>()));
    });

    test('fehlende Signatur -> SigningException', () {
      expect(() => check(amberReply(sig: '')),
          throwsA(isA<SigningException>()));
    });
  });

  group('N3 — Backup-Schlüsselkonsistenz', () {
    final key = Keychain.generate();
    final priv = key.private;
    final npub = Nip19.encodePubkey(key.public);
    final nsec = Nip19.encodePrivkey(priv);

    test('konsistentes Backup wird akzeptiert', () {
      expect(BackupService.backupKeyConsistent(nsec, npub, priv), isTrue);
    });

    test('npub passt nicht zum privaten Schlüssel -> abgelehnt', () {
      final other = Keychain.generate();
      final wrongNpub = Nip19.encodePubkey(other.public);
      // npub einer fremden Identität: die App würde sonst einen npub
      // anzeigen, zu dem der gespeicherte Schlüssel nicht signiert.
      expect(BackupService.backupKeyConsistent(nsec, wrongNpub, priv), isFalse);
    });

    test('nsec und priv_hex widersprechen sich -> abgelehnt', () {
      final other = Keychain.generate();
      expect(BackupService.backupKeyConsistent(nsec, npub, other.private), isFalse);
    });

    test('kaputtes priv_hex -> abgelehnt', () {
      expect(BackupService.backupKeyConsistent(nsec, npub, 'zz-not-hex'), isFalse);
    });
  });
}
