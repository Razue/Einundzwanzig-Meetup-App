// Realistische Scan-/Restore-Fälle mit echten Testsignaturen. Keine
// Produktionsschlüssel und keine Netzwerk- oder Simulatorzugriffe.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';
import 'package:einundzwanzig_meetup_app/services/backup_service.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_format.dart';
import 'package:einundzwanzig_meetup_app/services/trust_score_service.dart';

final _organizer = Keychain('1'.padLeft(64, '0'));
final _attendee = Keychain('2'.padLeft(64, '0'));
final _firstDate = DateTime.now().subtract(const Duration(days: 180));

MeetupBadge scan({
  String meetup = 'Aschaffenburg',
  int daysAgo = 14,
  int secondsLater = 0,
  String? id,
}) {
  final now = DateTime.now();
  final date = DateTime.utc(
    now.year,
    now.month,
    now.day,
    19,
  ).subtract(Duration(days: daysAgo)).add(Duration(seconds: secondsLater));
  final eventKey =
      '${meetup.toLowerCase()}-${date.toIso8601String().substring(0, 10)}';
  final org = Event.from(
    kind: 21000,
    tags: [
      ['t', 'badge'],
      ['m', meetup.toLowerCase()],
    ],
    content: jsonEncode({'meetup': meetup, 'event': eventKey}),
    createdAt: date.millisecondsSinceEpoch ~/ 1000,
    privkey: _organizer.private,
  );
  final claim = Event.from(
    kind: 21002,
    tags: [
      ['t', 'badge_claim'],
      ['p', _organizer.public],
    ],
    content: jsonEncode({
      'action': 'claim_badge',
      'org_event_id': org.id,
      'org_sig': org.sig,
    }),
    createdAt: date.millisecondsSinceEpoch ~/ 1000,
    privkey: _attendee.private,
  );
  return MeetupBadge(
    // Wie beim normalen Scanner: die Meetup-ID bleibt über Besuche gleich.
    id: id ?? meetup.toLowerCase(),
    meetupName: meetup,
    meetupEventId: eventKey,
    date: date,
    iconPath: 'assets/badge_icon.png',
    delivery: 'rolling_qr',
    blockHeight: 971000,
    signerNpub: Nip19.encodePubkey(_organizer.public),
    sigVersion: 2,
    sig: org.sig,
    sigId: org.id,
    sigContent: org.content,
    adminPubkey: _organizer.public,
    claimSig: claim.sig,
    claimEventId: claim.id,
    claimPubkey: _attendee.public,
    claimTimestamp: claim.createdAt,
  );
}

MeetupBadge marker(MeetupBadge participant) => MeetupBadge(
  id: 'org-${participant.meetupEventId}',
  meetupName: participant.meetupName,
  meetupEventId: participant.meetupEventId,
  date: participant.date,
  iconPath: '',
  delivery: 'organizer',
  isOrganizer: true,
);

TrustScore score(List<MeetupBadge> badges) => TrustScoreService.calculateScore(
  badges: badges,
  firstBadgeDate: _firstDate,
);

void sameReputation(List<MeetupBadge> baseline, List<MeetupBadge> actual) {
  final expected = score(baseline);
  final observed = score(actual);
  expect(observed.totalBadges, expected.totalBadges);
  expect(observed.uniqueMeetups, expected.uniqueMeetups);
  expect(observed.uniqueSigners, expected.uniqueSigners);
  expect(observed.uniqueCities, expected.uniqueCities);
  expect(observed.totalScore, closeTo(expected.totalScore, 1e-9));
  expect(observed.activityScore, closeTo(expected.activityScore, 1e-9));
  expect(observed.diversityScore, expected.diversityScore);
  expect(observed.qualityScore, expected.qualityScore);
  expect(observed.currentPhase, expected.currentPhase);
  expect(observed.meetsPromotionThreshold, expected.meetsPromotionThreshold);
  for (final key in expected.progress.keys) {
    expect(observed.progress[key]!.current, expected.progress[key]!.current);
    expect(observed.progress[key]!.required, expected.progress[key]!.required);
  }
  expect(
    TrustScoreService.calculateBridgeScore(actual),
    TrustScoreService.calculateBridgeScore(baseline),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    MeetupBadge.badgesUnreadable = false;
    MeetupBadge.onBadgesSaved = null;
  });

  test(
    'monatliche Besuche: gleiche Meetup-ID, beide Termine bleiben und zählen',
    () async {
      final visits = [scan(daysAgo: 42), scan(daysAgo: 14)];
      expect(visits[0].id, visits[1].id);
      expect(visits[0].meetupEventId, isNot(visits[1].meetupEventId));
      expect(await BackupService.restoreBadges(visits), isTrue);
      final loaded = await MeetupBadge.loadBadges();
      expect(loaded.length, 2);
      expect(score(loaded).totalBadges, 2);
      expect(score(loaded).uniqueMeetups, 1);
      expect(
        score(loaded).activityScore,
        greaterThan(score([visits.last]).activityScore),
      );
      sameReputation(visits, loaded);
    },
  );

  test(
    'Rolling-QR: verschiedene Scan-IDs und Signaturen am selben Termin zählen einmal',
    () async {
      final first = scan();
      final second = scan(id: 'scan-2', secondsLater: 10);
      expect(first.sigId, isNot(second.sigId));
      final copies = [first, second, first, second];
      sameReputation([first], copies); // Auch vor der Speicherbereinigung.
      expect(await BackupService.restoreBadges(copies), isTrue);
      final loaded = await MeetupBadge.loadBadges();
      expect(loaded.length, 1);
      sameReputation([first], loaded);
    },
  );

  test(
    'Teilnahme und Organisator-Marker bleiben getrennt, Reputation zählt nur Teilnahme',
    () async {
      final participant = scan();
      final org = marker(participant);
      expect(
        await BackupService.restoreBadges([participant, org, org]),
        isTrue,
      );
      final loaded = await MeetupBadge.loadBadges();
      expect(loaded.length, 2);
      expect(loaded.where((b) => b.isOrganizer).length, 1);
      sameReputation([participant], loaded);
      expect(score([org, org]).totalScore, 0);
    },
  );

  test(
    'Sync und erneuter Restore erhöhen weder Score noch Aufstiegsfortschritt',
    () async {
      final visits = [scan(daysAgo: 70), scan(daysAgo: 42), scan(daysAgo: 14)];
      final extraVisit = scan(meetup: 'Darmstadt', daysAgo: 21);
      final baseline = [...visits, extraVisit];
      final duplicateScans = [
        for (final b in visits) b.copyWith(id: '${b.id}-rescan'),
      ];
      final markers = visits.map(marker).toList();
      final merged = BadgeSyncFormat.merge(baseline, [
        ...baseline,
        ...duplicateScans,
        ...markers,
      ]);
      expect(merged.length, 7); // Vier Teilnahmen + drei Marker.
      sameReputation(baseline, merged);
      expect(await BackupService.restoreBadges(merged), isTrue);
      final reimported = BadgeSyncFormat.merge(
        await MeetupBadge.loadBadges(),
        merged,
      );
      expect(await BackupService.restoreBadges(reimported), isTrue);
      final loaded = await MeetupBadge.loadBadges();
      expect(loaded.length, 7);
      sameReputation(baseline, loaded);
      sameReputation(baseline, [...baseline, ...duplicateScans, ...markers]);
    },
  );

  test(
    'Bridge-Score: ein Mehrfachscan darf die Drei-Badge-Schwelle nicht erreichen',
    () {
      final a = scan();
      final b = scan(meetup: 'Darmstadt', daysAgo: 21);
      sameReputation([a, b], [a, b, a.copyWith(id: 'rescan')]);
    },
  );

  test(
    'Bridge-Score: ein Organisator-Marker darf die Drei-Badge-Schwelle nicht erreichen',
    () {
      final a = scan();
      final b = scan(meetup: 'Darmstadt', daysAgo: 21);
      sameReputation([a, b], [a, b, marker(a)]);
    },
  );

  test(
    'Organisator-Marker anderer Städte erzeugen keine zusätzliche Reichweite',
    () {
      final visits = [
        scan(daysAgo: 42),
        scan(daysAgo: 14),
        scan(meetup: 'Darmstadt', daysAgo: 21),
      ];
      sameReputation(visits, [...visits, marker(scan(meetup: 'Berlin'))]);
    },
  );
  test('Mehrfachscans belegen keine zusätzlichen Plätze im Wochenlimit', () {
    final visits = [
      scan(daysAgo: 14),
      scan(meetup: 'Darmstadt', daysAgo: 14),
      scan(meetup: 'Frankfurt', daysAgo: 14),
    ];
    final inflated = [
      ...visits,
      for (var i = 0; i < 20; i++) visits.first.copyWith(id: 'rescan-$i'),
    ];
    sameReputation(visits, inflated);
    expect(
      score(inflated).badgeValues.where((v) => v.totalValue > 0).length,
      2,
    );
  });

  test('auch Marker mit Signatur erhöhen keine Reputation', () {
    final participant = scan();
    final signedMarker = participant.copyWith(
      id: 'org-marker',
      isOrganizer: true,
    );
    expect(signedMarker.isNostrSigned, isTrue);
    sameReputation([participant], [participant, signedMarker, signedMarker]);
    expect(score([signedMarker]).totalScore, 0);
  });
}
