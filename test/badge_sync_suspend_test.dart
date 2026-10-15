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
const _npubC = 'npub1ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

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

  test('offener Wechsel blockiert ein Einspielen, das nicht ersetzt',
      () async {
    await MeetupBadge.saveBadges([_badge('bleibt')]);
    await BadgeSyncService.beginRestoreHold(fromNpub: _npubA);
    expect(await MeetupBadge.stageIncoming([_badge('fremd')]), isTrue);
    BadgeSyncService.debugResetProcess();
    // Der npub ist nicht lesbar: der Riegel bleibt.
    await BadgeSyncService.settleRestore();

    await expectLater(
      BadgeSyncService.beginRestoreHold(fromNpub: ''),
      throwsA(isA<Exception>()),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('badge_restore_hold'), isTrue);
    expect(prefs.getString(MeetupBadge.incomingPrefsKey), isNotNull);
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['bleibt']);
  });

  test('Leeren-Vormerk verwirft einen älteren Puffer', () async {
    await BadgeSyncService.beginRestoreHold(fromNpub: _npubA);
    expect(await MeetupBadge.stageIncoming([_badge('fremd')]), isTrue);
    await BadgeSyncService.markRestoreClear();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(MeetupBadge.incomingPrefsKey), isNull);
    expect(prefs.getBool('badge_restore_clear'), isTrue);
  });

  test('andere Identität als die versprochene übernimmt den Puffer nicht',
      () async {
    FlutterSecureStorage.setMockInitialValues({'nostr_npub_key': _npubC});
    await MeetupBadge.saveBadges([_badge('alt')]);
    await BadgeSyncService.beginRestoreHold(
        fromNpub: _npubA, expectNpubs: [_npubB]);
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    BadgeSyncService.debugResetProcess();

    await BadgeSyncService.settleRestore();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('badge_restore_hold'), isTrue);
    expect(prefs.getString(MeetupBadge.incomingPrefsKey), isNotNull);
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['alt']);
  });

  test('offener Wechsel: Ersetzen darf weiter und behält den Ursprung',
      () async {
    await MeetupBadge.saveBadges([_badge('alt')]);
    await BadgeSyncService.beginRestoreHold(
        fromNpub: _npubA, expectNpubs: [_npubB], replace: true);
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    // Der Schlüssel kam nur halb an: npub B, privHex passt nicht.
    final store = const FlutterSecureStorage();
    await store.write(key: 'nostr_npub_key', value: _npubB);
    await store.write(key: 'nostr_priv_hex', value: 'ab');
    BadgeSyncService.debugResetProcess();
    await BadgeSyncService.settleRestore();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('badge_restore_hold'), isTrue);
    expect(await BadgeSyncService.pendingFrom(), _npubA,
        reason: 'die Sammlung gehört noch A');

    // Ersetzen darf weiter: from bleibt A, der Puffer bleibt bis zum neuen.
    await BadgeSyncService.beginRestoreHold(
        fromNpub: 'egal', expectNpubs: [_npubB], replace: true);
    expect(prefs.getString('badge_restore_from'), _npubA);
    expect(prefs.getString(MeetupBadge.incomingPrefsKey), isNotNull);
    expect(await MeetupBadge.stageIncoming([_badge('neu2')]), isTrue);
    // Diesmal liegt der Schlüssel ganz.
    await store.delete(key: 'nostr_priv_hex');

    await BadgeSyncService.endRestore();
    expect(prefs.getBool('badge_restore_hold'), isNot(true));
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['neu2']);
    final former = await MeetupBadge.formerCollections();
    expect(former.single.npub, _npubA);
    expect(former.single.badges?.map((b) => b.id), ['alt']);
  });

  test('Rückfall auf den lokalen Schlüssel des Backups zählt als Wechsel',
      () async {
    // Mischzustand im Backup: aktiv B, lokaler Schlüssel C. Der externe
    // Signer kam nicht, der Keystore trägt C.
    FlutterSecureStorage.setMockInitialValues({'nostr_npub_key': _npubC});
    await MeetupBadge.saveBadges([_badge('alt')]);
    await BadgeSyncService.beginRestoreHold(
        fromNpub: _npubA, expectNpubs: [_npubB, _npubC], replace: true);
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    BadgeSyncService.debugResetProcess();

    await BadgeSyncService.settleRestore();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('badge_restore_hold'), isNot(true));
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['neu']);
  });

  test('privater Schlüssel muss zum npub passen', () async {
    await MeetupBadge.saveBadges([_badge('alt')]);
    final store = const FlutterSecureStorage();
    await store.write(key: 'nostr_npub_key', value: _npubB);
    await store.write(key: 'nostr_priv_hex', value: 'ab');
    await BadgeSyncService.beginRestoreHold(
        fromNpub: _npubA, expectNpubs: [_npubB]);
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    BadgeSyncService.debugResetProcess();

    await BadgeSyncService.settleRestore();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('badge_restore_hold'), isTrue);
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['alt']);
  });

  test('Wechsel räumt Nachweise der alten Identität', () async {
    FlutterSecureStorage.setMockInitialValues({'nostr_npub_key': _npubB});
    await MeetupBadge.saveBadges([_badge('alt')]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('humanity_verified', true);
    await prefs.setString('platform_proofs', '[{"platform":"a"}]');
    await BadgeSyncService.beginRestoreHold(
        fromNpub: _npubA, expectNpubs: [_npubB]);
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    BadgeSyncService.debugResetProcess();

    await BadgeSyncService.settleRestore();

    expect(prefs.getBool('humanity_verified'), isFalse);
    expect(prefs.getString('platform_proofs'), isNull);
    expect(prefs.getBool('badge_restore_proofs'), isNot(true));
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['neu']);
  });

  test('schon geschriebene Nachweise der neuen Identität bleiben', () async {
    FlutterSecureStorage.setMockInitialValues({'nostr_npub_key': _npubB});
    await MeetupBadge.saveBadges([_badge('alt')]);
    await BadgeSyncService.beginRestoreHold(
        fromNpub: _npubA, expectNpubs: [_npubB]);
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    await BadgeSyncService.clearIdentityProofs();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('humanity_verified', true);
    await prefs.setString('platform_proofs', '[{"platform":"b"}]');
    BadgeSyncService.debugResetProcess();

    await BadgeSyncService.settleRestore();

    expect(prefs.getBool('humanity_verified'), isTrue);
    expect(prefs.getString('platform_proofs'), '[{"platform":"b"}]');
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
