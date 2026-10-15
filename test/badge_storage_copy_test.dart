// Die Badge-Datei liegt zusätzlich im sicheren Speicher, neben ihrem
// Schlüssel. SharedPreferences bleibt der erste Ort und wird nie deswegen
// geräumt. Jede Fassung, die sich öffnen lässt, zählt.

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';

const _blobKey = 'badges_encrypted';

/// Nur die Zweitkopie ist nicht lesbar, der Schlüssel schon.
class _CopyUnreadable extends TestFlutterSecureStoragePlatform {
  _CopyUnreadable(super.data);
  @override
  Future<String?> read({required String key, required Map<String, String> options}) {
    if (key == _blobKey) throw PlatformException(code: 'keystore');
    return super.read(key: key, options: options);
  }
}

/// Nur die Zweitkopie lässt sich nicht schreiben, der Schlüssel schon.
class _CopyUnwritable extends TestFlutterSecureStoragePlatform {
  _CopyUnwritable(super.data);
  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) {
    if (key == _blobKey) throw PlatformException(code: 'keystore');
    return super.write(key: key, value: value, options: options);
  }
}

// Je Id eine eigene Veranstaltung: die Vereinigung arbeitet je
// Veranstaltung (MeetupBadge.unionByIdentity), nicht je Id.
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
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    MeetupBadge.badgesUnreadable = false;
  });

  test('Speichern legt dieselbe Datei an beiden Orten ab', () async {
    expect(await MeetupBadge.saveBadges([_badge('a')]), isTrue);

    final prefs = await SharedPreferences.getInstance();
    final inPrefs = prefs.getString(_blobKey);
    final inSecure = await const FlutterSecureStorage().read(key: _blobKey);
    expect(inPrefs, isNotNull);
    expect(inSecure, inPrefs, reason: 'Zweitkopie ist derselbe Blob');
  });

  test('Neuinstallation auf iOS: Prefs leer, Schlüsselbund voll', () async {
    await MeetupBadge.saveBadges([_badge('a'), _badge('b')]);
    // Der App-Container ist neu, der Schlüsselbund nicht.
    SharedPreferences.setMockInitialValues({});

    final loaded = await MeetupBadge.loadBadges();
    expect(loaded.map((b) => b.id), ['a', 'b']);

    // Die Zweitkopie ist wieder der Primäre in den Prefs.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), isNotNull);
    expect(prefs.getString(_blobKey),
        await const FlutterSecureStorage().read(key: _blobKey));
  });

  test('Zweitkopie nicht lesbar: Laden aus den Prefs, nichts geräumt', () async {
    await MeetupBadge.saveBadges([_badge('a')]);
    final secure = await const FlutterSecureStorage().readAll();
    FlutterSecureStoragePlatform.instance = _CopyUnreadable(Map.of(secure));

    final loaded = await MeetupBadge.loadBadges();
    expect(loaded.map((b) => b.id), ['a']);
    expect(MeetupBadge.badgesUnreadable, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), isNotNull);
  });

  test('Zweitkopie nicht schreibbar: Speichern gelingt in den Prefs', () async {
    FlutterSecureStoragePlatform.instance = _CopyUnwritable({});

    expect(await MeetupBadge.saveBadges([_badge('a')]), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), isNotNull);
    expect(prefs.getStringList('badges'), isNull, reason: 'kein Klartext');
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['a']);
  });

  test('Reset räumt beide Orte', () async {
    await MeetupBadge.saveBadges([_badge('a')]);
    await MeetupBadge.resetAll();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), isNull);
    expect(await const FlutterSecureStorage().read(key: _blobKey), isNull);
    expect(await MeetupBadge.loadBadges(), isEmpty);
  });

  test('ältere Installation ohne Zweitkopie liest wie bisher', () async {
    await MeetupBadge.saveBadges([_badge('a')]);
    // Die Zweitkopie fehlt, als wäre sie nie geschrieben worden.
    await const FlutterSecureStorage().delete(key: _blobKey);

    final loaded = await MeetupBadge.loadBadges();
    expect(loaded.map((b) => b.id), ['a']);
  });

  test('Puffer ändert die aktive Sammlung nicht, Übernahme schon', () async {
    expect(await MeetupBadge.saveBadges([_badge('bleibt')]), isTrue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('badges_encrypted_preserved', 'alt:blob');
    expect(await MeetupBadge.stageIncoming([_badge('neu')]), isTrue);
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['bleibt']);
    expect(await MeetupBadge.promoteIncoming(formerNpub: 'npub1alt'), isTrue);
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['neu']);
    expect(prefs.getString(MeetupBadge.incomingPrefsKey), isNull);
    expect(prefs.getString('badges_encrypted_preserved'), isNull);
    // Eine Fassung für das Lesbare, der unlesbare Blob extra.
    final former = await MeetupBadge.formerCollections();
    expect(former.map((f) => f.reason), ['replaced', 'replaced']);
    final readable = former.where((f) => f.badges != null).single;
    expect(readable.npub, 'npub1alt');
    expect(readable.badges?.map((b) => b.id), ['bleibt']);
    expect(former.where((f) => f.badges == null), hasLength(1));
  });

  test('Übernahme nach Abbruch etikettiert die neue Sammlung nicht als alte',
      () async {
    await MeetupBadge.saveBadges([_badge('a')]);
    expect(await MeetupBadge.stageIncoming([_badge('b')]), isTrue);
    expect(await MeetupBadge.promoteIncoming(formerNpub: 'npub1alt'), isTrue);
    // Der Prozess starb, bevor der Puffer entfernt war.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        MeetupBadge.incomingPrefsKey, prefs.getString(_blobKey)!);

    expect(await MeetupBadge.promoteIncoming(formerNpub: 'npub1alt'), isTrue);
    expect(prefs.getString(MeetupBadge.incomingPrefsKey), isNull);
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['b']);
    final former = await MeetupBadge.formerCollections();
    expect(former.single.badges?.map((b) => b.id), ['a']);
  });

  test('Archiv: frühere Sammlung lässt sich wieder vereinigen', () async {
    await MeetupBadge.saveBadges([_badge('a')]);
    expect(await MeetupBadge.stageIncoming([_badge('b')]), isTrue);
    expect(await MeetupBadge.promoteIncoming(), isTrue);
    expect((await MeetupBadge.loadBadges()).map((b) => b.id), ['b']);

    final former = await MeetupBadge.formerCollections();
    expect(former.single.badges?.map((b) => b.id), ['a']);
    expect(await MeetupBadge.mergeFormer(former.single.index), isTrue);
    expect((await MeetupBadge.loadBadges()).map((b) => b.id),
        containsAll(['a', 'b']));
    // Das Archiv bleibt, Vereinigen verbraucht nichts.
    expect(await MeetupBadge.formerCollections(), hasLength(1));
  });

  test('Archiv: Leeren und die dritte Rotation landen dort', () async {
    await MeetupBadge.saveBadges([_badge('a')]);
    // Drei bewusste Ersetzungen: a wandert preserved -> older -> Archiv.
    await MeetupBadge.saveBadges([_badge('b')], replaceUnreadable: true);
    await MeetupBadge.saveBadges([_badge('c')], replaceUnreadable: true);
    await MeetupBadge.saveBadges([_badge('d')], replaceUnreadable: true);
    var former = await MeetupBadge.formerCollections();
    expect(former.map((f) => f.reason), ['rotated']);
    expect(former.single.badges?.map((b) => b.id), ['a']);

    // Leeren beim Identitätswechsel archiviert die aktive Datei.
    expect(await MeetupBadge.saveBadges([], discardLocked: true), isTrue);
    former = await MeetupBadge.formerCollections();
    expect(former.first.reason, 'cleared');
    expect(await MeetupBadge.loadBadges(), isEmpty);
  });

  test('Archiv: Zweitkopie im Schlüsselbund überlebt leere Prefs', () async {
    await MeetupBadge.saveBadges([_badge('a')]);
    expect(await MeetupBadge.stageIncoming([_badge('b')]), isTrue);
    expect(await MeetupBadge.promoteIncoming(), isTrue);
    expect(await const FlutterSecureStorage().read(key: 'badges_former'),
        isNotNull);
    // Neuer Container: Prefs leer, Schlüsselbund voll.
    SharedPreferences.setMockInitialValues({});

    final former = await MeetupBadge.formerCollections();
    expect(former.single.badges?.map((b) => b.id), ['a']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(MeetupBadge.formerPrefsKey), isNotNull,
        reason: 'kommt zurück in die Prefs');
  });

  test('Reset räumt das Archiv an beiden Orten', () async {
    await MeetupBadge.saveBadges([_badge('a')]);
    expect(await MeetupBadge.stageIncoming([_badge('b')]), isTrue);
    expect(await MeetupBadge.promoteIncoming(), isTrue);
    expect(await MeetupBadge.formerCollections(), hasLength(1));

    await MeetupBadge.resetAll();

    expect(await MeetupBadge.formerCollections(), isEmpty);
    expect(await const FlutterSecureStorage().read(key: 'badges_former'),
        isNull);
    expect(await MeetupBadge.loadBadges(), isEmpty);
  });

  test('Leeren ohne Reset löscht das Archiv nicht, sondern füllt es', () async {
    await MeetupBadge.saveBadges([_badge('a')]);
    expect(await MeetupBadge.stageIncoming([_badge('b')]), isTrue);
    expect(await MeetupBadge.promoteIncoming(), isTrue);
    expect(await MeetupBadge.formerCollections(), hasLength(1));

    // Ein leeres Backup ohne Identität, wie restoreBadges es schreibt.
    expect(await MeetupBadge.saveBadges([], replaceUnreadable: true), isTrue);

    final former = await MeetupBadge.formerCollections();
    expect(former.map((f) => f.reason), ['cleared', 'replaced']);
    expect(former.first.badges?.map((b) => b.id), ['b']);
  });
}
