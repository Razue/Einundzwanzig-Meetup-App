// Während ein Backup eingespielt wird, läuft kein Sync. Ein Auslöser in der
// Zeit wird am Ende genau einmal nachgeholt. Was mit dem Puffer eines
// Identitätswechsels passiert, entscheidet der Keystore, nicht ein Flag.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_service.dart';

const _npubA = 'npub1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _npubB = 'npub1bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

MeetupBadge _badge(String id) => MeetupBadge(
      id: id,
      meetupName: 'Aschaffenburg',
      meetupEventId: id,
      date: DateTime.utc(2026, 10, 11, 19),
      iconPath: 'assets/badge_icon.png',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Ohne Identität endet ein Lauf sofort (kein Signer), zählt aber.
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    MeetupBadge.badgesUnreadable = false;
    BadgeSyncService.runs = 0;
    BadgeSyncService.debugResetProcess();
  });

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('ohne Riegel läuft jeder Auslöser', () async {
    BadgeSyncService.trigger();
    await settle();
    expect(BadgeSyncService.runs, 1);
  });

  test('ausgesetzt: kein Lauf, am Ende genau einer', () async {
    await BadgeSyncService.beginRestoreHold();
    BadgeSyncService.trigger();
    BadgeSyncService.trigger();
    await settle();
    expect(BadgeSyncService.runs, 0, reason: 'während des Backups kein Sync');

    await BadgeSyncService.endRestore();
    await settle();
    expect(BadgeSyncService.runs, 1, reason: 'zwei Auslöser, ein Nachlauf');
  });

  test('Ende ohne Auslöser startet nichts', () async {
    await BadgeSyncService.beginRestoreHold();
    await BadgeSyncService.endRestore();
    await settle();
    expect(BadgeSyncService.runs, 0);
  });

  test('Riegel ohne Identitätswechsel: Puffer wird verworfen, Datei bleibt',
      () async {
    await MeetupBadge.saveBadges([_badge('bleibt')]);
    // Keine Identität vorher, keine nachher: nichts hat gewechselt.
    await BadgeSyncService.beginRestoreHold();
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    // Prozess stirbt, der Riegel liegt in den Prefs.
    BadgeSyncService.debugResetProcess();

    await BadgeSyncService.settleRestore();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(MeetupBadge.incomingPrefsKey), isNull);
    expect(prefs.getBool('badge_restore_hold'), isNot(true));
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['bleibt']);
  });

  test('Riegel mit Identitätswechsel: Puffer wird übernommen', () async {
    // Vorher Identität A mit einer Sammlung, dann liegt im Keystore B.
    FlutterSecureStorage.setMockInitialValues({'nostr_npub_key': _npubB});
    await MeetupBadge.saveBadges([_badge('alt')]);
    await BadgeSyncService.beginRestoreHold(fromNpub: _npubA);
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('badge_sync_chunk_hashes', ['x']);
    BadgeSyncService.debugResetProcess();

    await BadgeSyncService.settleRestore();

    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['neu']);
    expect(prefs.getString(MeetupBadge.incomingPrefsKey), isNull);
    expect(prefs.getBool('badge_restore_hold'), isNot(true));
    expect(prefs.getStringList('badge_sync_chunk_hashes'), isNull,
        reason: 'Hashes der alten Identität vergessen');
    // Die alte Sammlung ist nicht weg, sie liegt im Archiv.
    final former = await MeetupBadge.formerCollections();
    expect(former.single.reason, 'replaced');
    expect(former.single.npub, _npubA);
    expect(former.single.badges?.map((b) => b.id), ['alt']);
  });

  test('npub nicht lesbar gilt nicht als Wechsel', () async {
    await MeetupBadge.saveBadges([_badge('bleibt')]);
    await BadgeSyncService.beginRestoreHold(fromNpub: _npubA);
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    BadgeSyncService.debugResetProcess();

    await BadgeSyncService.settleRestore();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('badge_restore_hold'), isTrue);
    expect(prefs.getString(MeetupBadge.incomingPrefsKey), isNotNull);
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['bleibt']);
    expect(BadgeSyncService.identitySwitched(_npubA, ''), isFalse);
    expect(BadgeSyncService.identitySwitched(_npubA, _npubB), isTrue);
  });

  test('neues Einspielen räumt Reste eines liegengebliebenen weg', () async {
    await MeetupBadge.saveBadges([_badge('bleibt')]);
    // Erstes Einspielen: Puffer und Vormerk liegen, der npub ist nicht
    // lesbar, der Riegel bleibt stehen.
    await BadgeSyncService.beginRestoreHold(fromNpub: _npubA);
    expect(await MeetupBadge.stageIncoming([_badge('fremd')]), isTrue);
    await BadgeSyncService.markRestoreClear();
    BadgeSyncService.debugResetProcess();
    await BadgeSyncService.settleRestore();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('badge_restore_hold'), isTrue);

    // Zweites Einspielen fängt sauber an.
    await BadgeSyncService.beginRestoreHold(fromNpub: '');
    expect(prefs.getString(MeetupBadge.incomingPrefsKey), isNull);
    expect(prefs.getBool('badge_restore_clear'), isNot(true));
    expect(prefs.getString('badge_restore_from'), '');

    await BadgeSyncService.endRestore();
    expect(prefs.getBool('badge_restore_hold'), isNot(true));
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['bleibt']);
  });

  test('neues Einspielen übernimmt erst, was der Keystore schon entschied',
      () async {
    FlutterSecureStorage.setMockInitialValues({'nostr_npub_key': _npubB});
    await MeetupBadge.saveBadges([_badge('alt')]);
    await BadgeSyncService.beginRestoreHold(fromNpub: _npubA);
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    // Absturz nach dem Schlüssel, vor der Übernahme.
    BadgeSyncService.debugResetProcess();

    await BadgeSyncService.beginRestoreHold(fromNpub: _npubB);
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['neu']);
    final former = await MeetupBadge.formerCollections();
    expect(former.single.npub, _npubA);
    expect(former.single.badges?.map((b) => b.id), ['alt']);
  });

  test('leeres Ersetzen räumt erst, wenn die Identität wirklich neu ist',
      () async {
    await MeetupBadge.saveBadges([_badge('alt')]);
    await BadgeSyncService.beginRestoreHold(fromNpub: _npubA);
    await BadgeSyncService.markRestoreClear();
    BadgeSyncService.debugResetProcess();

    await BadgeSyncService.settleRestore();
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('badge_restore_hold'), isTrue,
        reason: 'ohne lesbaren npub bleibt der Riegel');
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['alt']);

    await const FlutterSecureStorage()
        .write(key: 'nostr_npub_key', value: _npubB);
    await BadgeSyncService.settleRestore();
    prefs = await SharedPreferences.getInstance();
    expect((await MeetupBadge.loadBadges()), isEmpty);
    expect(prefs.getBool('badge_restore_hold'), isNot(true));
    expect(prefs.getBool('badge_restore_clear'), isNot(true));
    final former = await MeetupBadge.formerCollections();
    expect(former.single.badges?.map((b) => b.id), ['alt']);
  });

  test('laufendes Einspielen im selben Prozess: settle rührt nichts an',
      () async {
    await BadgeSyncService.beginRestoreHold(fromNpub: _npubA);
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    await BadgeSyncService.settleRestore();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(MeetupBadge.incomingPrefsKey), isNotNull);
    expect(prefs.getBool('badge_restore_hold'), isTrue);
  });

  test('forgetLocalState räumt Hashes, Generation und dirty', () async {
    SharedPreferences.setMockInitialValues({
      'badge_sync_chunk_hashes': ['x'],
      'badge_sync_last_gen': 5,
      'badge_sync_dirty': true,
    });
    await BadgeSyncService.forgetLocalState();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('badge_sync_chunk_hashes'), isNull);
    expect(prefs.getInt('badge_sync_last_gen'), isNull);
    expect(prefs.getBool('badge_sync_dirty'), isNull);
  });
}
