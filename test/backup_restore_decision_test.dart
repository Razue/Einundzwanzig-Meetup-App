// Ein Backup auf einem Gerät mit Identität: Dieselbe Identität vereinigt
// die Badges, eine andere ersetzt nach Bestätigung, ohne Identität wie bisher.

import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';
import 'package:einundzwanzig_meetup_app/models/user.dart';
import 'package:einundzwanzig_meetup_app/services/backup_service.dart';

const _a = 'npub1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _b = 'npub1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  group('backupIdentityNpub', () {
    test('aktive Identität vor dem lokalen Schlüssel', () {
      expect(
        BackupService.backupIdentityNpub({
          'nostr': {'npub': _a, 'active_npub': _b},
        }),
        _b,
      );
    });

    test('ohne aktive Identität der npub des Schlüssels', () {
      expect(
        BackupService.backupIdentityNpub({
          'nostr': {'npub': ' $_a ', 'active_npub': ''},
        }),
        _a,
      );
    });

    test('Backup ohne Nostr-Block ist leer', () {
      expect(BackupService.backupIdentityNpub({'user': {}}), '');
      expect(BackupService.backupIdentityNpub({'nostr': null}), '');
    });
  });

  group('restoreDecision', () {
    test('ohne Identität auf dem Gerät: wie bisher', () {
      expect(
        BackupService.restoreDecision(existingNpub: '', backupNpub: _a),
        RestoreDecision.fresh,
      );
    });

    test('dieselbe Identität: vereinigen', () {
      expect(
        BackupService.restoreDecision(existingNpub: _a, backupNpub: _a),
        RestoreDecision.sameIdentity,
      );
    });

    test('andere Identität: ersetzen nach Bestätigung', () {
      expect(
        BackupService.restoreDecision(existingNpub: _a, backupNpub: _b),
        RestoreDecision.replacesIdentity,
      );
    });

    test('Backup ohne erkennbare Identität wird hinzugefügt', () {
      expect(
        BackupService.restoreDecision(existingNpub: _a, backupNpub: ''),
        RestoreDecision.addToIdentity,
      );
    });

    test('Großschreibung des npub zählt als dieselbe Identität', () {
      expect(
        BackupService.restoreDecision(
            existingNpub: _a.toUpperCase(), backupNpub: _a),
        RestoreDecision.sameIdentity,
      );
    });
  });

  test('Profil ergänzt nur leere Felder und vereinigt Favoriten', () {
    final device = UserProfile(
      nickname: 'Ada',
      fullName: '',
      homeMeetupId: 'bonn',
      favoriteMeetupIds: ['bonn'],
      nostrNpub: _a,
    );
    device.adminViaPortal = true;
    final merged = BackupService.mergeProfile(device, {
      'nickname': 'Alt',
      'fullName': 'Ada Lovelace',
      'homeMeetupId': 'koeln',
      'favoriteMeetupIds': ['koeln', 'bonn'],
      'nostrNpub': 'npub1other',
    });
    expect(merged.nickname, 'Ada');
    expect(merged.fullName, 'Ada Lovelace');
    expect(merged.homeMeetupId, 'bonn');
    expect(merged.favoriteMeetupIds, containsAll(['bonn', 'koeln']));
    expect(merged.nostrNpub, _a);
    expect(merged.adminViaPortal, isTrue);
    expect(merged.adminViaVouch, isFalse);
  });

  test('Hinzugefügte Badges zählen Veranstaltungen, nicht die Länge', () {
    MeetupBadge scan(String id, String event, DateTime date) => MeetupBadge(
          id: id,
          meetupName: 'Ort',
          meetupEventId: event,
          date: date,
          iconPath: 'assets/badge_icon.png',
        );
    final before = [scan('neu', 'evt-bonn', DateTime.utc(2026, 6, 1))];
    final merged = [
      scan('alt', 'evt-bonn', DateTime.utc(2026, 1, 1)),
      scan('koeln', 'evt-koeln', DateTime.utc(2026, 3, 1)),
    ];
    expect(BackupService.addedBadgeCount(before, merged), 1);
  });

  test('Plattform-Proofs: das Gerät behält denselben Namen', () {
    final merged = BackupService.unionPlatformProofs(
      [
        {'platform': 'telegram', 'username': 'Ada', 'proof_sig': 'device'},
      ],
      [
        {'platform': 'telegram', 'username': 'ada', 'proof_sig': 'backup'},
        {'platform': 'x', 'username': 'ada', 'proof_sig': 'extra'},
      ],
    );
    expect(merged, hasLength(2));
    expect(
      merged.firstWhere((p) => p['platform'] == 'telegram')['proof_sig'],
      'device',
    );
  });
}
