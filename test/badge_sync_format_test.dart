// Reine Funktionen des Badge-Sync-Formats: Sortierung, Chunking,
// Vereinigung. Kein Netz, kein Signer.

import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_format.dart';

void main() {
  MeetupBadge badge(
    String id, {
    required DateTime date,
    int claimTimestamp = 0,
    bool claimed = true,
    bool presenceVerified = true,
    bool long = false,
  }) {
    // long macht das Badge groß genug, dass sich mehrere Chunks ergeben.
    final filler = long ? 'x' * 800 : '';
    return MeetupBadge(
      id: id,
      meetupName: 'M $id',
      date: date,
      iconPath: '',
      sig: filler,
      sigContent: filler,
      claimSig: claimed ? 'sig$id' : '',
      claimPubkey: claimed ? 'pk' : '',
      claimTimestamp: claimTimestamp,
      presenceVerified: presenceVerified,
    );
  }

  // measure wie NIP-44: Länge des Klartexts bestimmt die Payload.
  int measure(String plaintext) => plaintext.length;

  test('Sortierung nach date, bei Gleichstand nach id', () {
    final list = BadgeSyncFormat.sortBadges([
      badge('b', date: DateTime(2026, 5, 2)),
      badge('a', date: DateTime(2026, 5, 2)),
      badge('c', date: DateTime(2026, 5, 1)),
    ]);
    expect(list.map((b) => b.id), ['c', 'a', 'b']);
  });

  test('Hülle macht eine Rundreise', () {
    final badges = [
      badge('x', date: DateTime(2026, 1, 1), claimTimestamp: 100),
      badge('y', date: DateTime(2026, 1, 2), claimTimestamp: 90),
    ];
    final plain = BadgeSyncFormat.envelopeJson(
      badges: badges, index: 1, total: 2, generation: 42);
    final parsed = BadgeSyncFormat.parseEnvelope(plain);
    expect(parsed.index, 1);
    expect(parsed.total, 2);
    expect(parsed.generation, 42);
    expect(parsed.badges.map((b) => b.id), ['x', 'y']);
    expect(parsed.badges.first.claimTimestamp, 100);
  });

  test('Chunks teilen an der Grenze und bleiben unter ihr', () {
    final badges = List.generate(
      40,
      (i) => badge('b$i', date: DateTime(2026, 1, 1).add(Duration(days: i)), long: true),
    );
    final chunks = BadgeSyncFormat.chunkBadges(badges, measure);
    expect(chunks.length, greaterThan(1));
    for (var i = 0; i < chunks.length; i++) {
      final plain = BadgeSyncFormat.envelopeJson(
        badges: chunks[i], index: i, total: chunks.length, generation: 0);
      expect(plain.length, lessThanOrEqualTo(BadgeSyncFormat.chunkPayloadChars));
    }
    // Kein Badge geht verloren.
    final all = chunks.expand((c) => c).toList();
    expect(all.length, badges.length);
  });

  test('Determinismus: dieselbe Menge in anderer Reihenfolge ergibt dieselben Chunks', () {
    final a = [
      badge('1', date: DateTime(2026, 1, 1)),
      badge('2', date: DateTime(2026, 1, 2)),
      badge('3', date: DateTime(2026, 1, 3)),
    ];
    final b = a.reversed.toList();
    final pa = BadgeSyncFormat.plaintexts(a, 7, measure);
    final pb = BadgeSyncFormat.plaintexts(b, 7, measure);
    expect(pa, pb);
  });

  test('Vereinigung: fernes Badge ohne lokalen Partner bleibt', () {
    final merged = BadgeSyncFormat.merge(
      [badge('local', date: DateTime(2026, 1, 1))],
      [badge('remote', date: DateTime(2026, 1, 2))],
    );
    expect(merged.map((b) => b.id), ['local', 'remote']);
  });

  test('Vereinigung: bei gleicher Id gewinnt der Claim', () {
    final withClaim = badge('same', date: DateTime(2026, 1, 1), claimed: true);
    final without = badge('same', date: DateTime(2026, 1, 1), claimed: false);
    final merged = BadgeSyncFormat.merge([without], [withClaim]);
    expect(merged.single.claimSig, isNotEmpty);
    // Umgekehrt: das lokale mit Claim schlägt das ferne ohne.
    final merged2 = BadgeSyncFormat.merge([withClaim], [without]);
    expect(merged2.single.claimSig, isNotEmpty);
  });

  test('Vereinigung: bei gleichem Claim gewinnt presenceVerified, dann lokal', () {
    final local = badge('same', date: DateTime(2026, 1, 1), presenceVerified: false);
    final remote = badge('same', date: DateTime(2026, 1, 1), presenceVerified: true);
    expect(
      BadgeSyncFormat.merge([local], [remote]).single.presenceVerified,
      isTrue,
    );
    final localV = badge('same', date: DateTime(2026, 1, 1), presenceVerified: true);
    final remoteV = badge('same', date: DateTime(2026, 1, 1), presenceVerified: true);
    expect(
      identical(BadgeSyncFormat.merge([localV], [remoteV]).single, localV),
      isTrue,
    );
  });

  test('chunkHash ist stabil am Klartext', () {
    final p = BadgeSyncFormat.envelopeJson(
      badges: [badge('x', date: DateTime(2026, 1, 1))],
      index: 0, total: 1, generation: 3);
    expect(BadgeSyncFormat.chunkHash(p), BadgeSyncFormat.chunkHash(p));
    expect(
      BadgeSyncFormat.chunkHash(p),
      isNot(BadgeSyncFormat.chunkHash(
        BadgeSyncFormat.envelopeJson(
          badges: [badge('x', date: DateTime(2026, 1, 1))],
          index: 0, total: 1, generation: 4))),
    );
  });

  test('Vereinigung je Veranstaltung: zwei Ids, ein Abend, ein Badge', () {
    MeetupBadge scan(String id,
            {required int hour, bool claimed = true, bool organizer = false}) =>
        MeetupBadge(
          id: id,
          meetupName: 'Koblenz',
          meetupEventId: 'koblenz-2026-10-11',
          date: DateTime(2026, 10, 11, hour),
          iconPath: '',
          claimSig: claimed ? 'sig' : '',
          claimPubkey: claimed ? 'pk' : '',
          isOrganizer: organizer,
        );
    // Beide geclaimt: der erste Scan bleibt, von beiden Seiten gesehen.
    final first = scan('koblenz-2026-10-11', hour: 19);
    final second = scan('koblenz-2026-10-11-2', hour: 20);
    expect(BadgeSyncFormat.merge([first], [second]).map((b) => b.id),
        ['koblenz-2026-10-11']);
    expect(BadgeSyncFormat.merge([second], [first]).map((b) => b.id),
        ['koblenz-2026-10-11']);
    // Nur der zweite trägt den Claim: der bleibt.
    final unclaimed = scan('koblenz-2026-10-11', hour: 19, claimed: false);
    expect(BadgeSyncFormat.merge([unclaimed], [second]).map((b) => b.id),
        ['koblenz-2026-10-11-2']);
    // Der Organisator-Marker desselben Abends ist kein Doppelscan.
    final marker = scan('org-koblenz-2026-10-11', hour: 18, organizer: true);
    expect(BadgeSyncFormat.merge([first, marker], [second]).length, 2);
  });
}
