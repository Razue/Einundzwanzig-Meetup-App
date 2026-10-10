// ============================================
// REGRESSIONSTEST H2/M1 — zentrale Signaturprüfung eingehender Events
// ============================================
// Ein Relay (oder ein Angreifer dazwischen) schiebt ein Kalender-Event
// ohne gültige Signatur unter. Vor dem Fix wurde es ungeprüft geparst.
// ============================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart';
import 'package:einundzwanzig_meetup_app/services/relay_socket.dart';
import 'package:einundzwanzig_meetup_app/services/calendar_event_service.dart';

void main() {
  final kc = Keychain.generate();
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  Map<String, dynamic> signedCalendarEvent() {
    final ev = Event.from(
      kind: 31923,
      tags: [
        ['d', 'test-meetup'],
        ['title', 'Echtes Meetup'],
        ['start', '${now + 86400}'],
      ],
      content: '',
      privkey: kc.private,
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

  test('Gültig signiertes Kalender-Event passiert und wird geparst', () {
    final raw = RelaySocket.verifiedEvent(signedCalendarEvent(), tag: 'Test');
    expect(raw, isNotNull);
    final cal = NostrCalendarEvent.fromEvent(raw!);
    expect(cal, isNotNull);
    expect(cal!.title, 'Echtes Meetup');
  });

  test('Unsigniertes Kalender-Event wird verworfen', () {
    final fake = signedCalendarEvent()..['sig'] = '';
    expect(RelaySocket.verifiedEvent(fake, tag: 'Test'), isNull);
  });

  test('Manipulierter Titel nach dem Signieren wird verworfen', () {
    final tampered = signedCalendarEvent();
    (tampered['tags'] as List)[1] = ['title', 'Gefälschtes Meetup'];
    expect(RelaySocket.verifiedEvent(tampered, tag: 'Test'), isNull);
  });

  test('Fremder Pubkey mit fremder Signatur wird verworfen', () {
    final other = Keychain.generate();
    final spoofed = signedCalendarEvent()..['pubkey'] = other.public;
    expect(RelaySocket.verifiedEvent(spoofed, tag: 'Test'), isNull);
  });

  test('Gültige Signatur, aber nachträglich geänderte ID wird verworfen', () {
    final forged = signedCalendarEvent()..['id'] = 'ab' * 32;
    expect(RelaySocket.verifiedEvent(forged, tag: 'Test'), isNull);
  });

  test('Kein Hex in Pubkey oder Signatur wird verworfen statt zu werfen', () {
    final badSig = signedCalendarEvent()..['sig'] = 'zz' * 64;
    final badKey = signedCalendarEvent()..['pubkey'] = 'xyz';
    expect(RelaySocket.verifiedEvent(badSig, tag: 'Test'), isNull);
    expect(RelaySocket.verifiedEvent(badKey, tag: 'Test'), isNull);
  });

  test('Gültige Signatur der falschen Art oder des falschen Autors passt nicht zur Anfrage', () {
    final raw = signedCalendarEvent();
    final asAsked = <String, dynamic>{
      'kinds': [31923],
      'authors': [raw['pubkey']],
      '#d': ['test-meetup'],
    };
    expect(RelaySocket.answersFilter(raw, asAsked), isTrue);
    expect(
      RelaySocket.answersFilter(raw, <String, dynamic>{
        'kinds': [0],
        'authors': [raw['pubkey']],
      }),
      isFalse,
    );
    expect(
      RelaySocket.answersFilter(raw, <String, dynamic>{
        'kinds': [31923],
        'authors': ['ab' * 32],
      }),
      isFalse,
    );
    expect(
      RelaySocket.answersFilter(raw, <String, dynamic>{
        'kinds': [31923],
        '#d': ['anderer-termin'],
      }),
      isFalse,
    );
  });

  test('created_at in der Zukunft zählt nicht als neuestes ersetzbares Event', () {
    final raw = signedCalendarEvent();
    expect(RelaySocket.replaceableCreatedAt(raw), raw['created_at']);
    raw['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    expect(RelaySocket.replaceableCreatedAt(raw), isNull);
  });

  test('Kaputte Nachricht crasht nicht', () {
    expect(RelaySocket.verifiedEvent('kein objekt'), isNull);
    expect(RelaySocket.verifiedEvent({'kind': 'x', 'tags': 42}), isNull);
    expect(RelaySocket.rejectedEventCount, greaterThan(0));
  });
}
