// Das Einspielen eines Backups darf keinen Erfolg melden, wenn die Badges
// nicht geschrieben wurden.

import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';
import 'package:einundzwanzig_meetup_app/services/backup_service.dart';

const _blobKey = 'badges_encrypted';
const _keyAlias = 'badge_encryption_key';
const _suspectKeyAlias = 'badge_encryption_key_suspect';

class _BrokenStorage extends TestFlutterSecureStoragePlatform {
  _BrokenStorage(super.data);

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) =>
      throw PlatformException(code: 'keystore');
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

String _blob(List<MeetupBadge> badges) {
  final key = enc.Key.fromSecureRandom(32);
  final iv = enc.IV.fromSecureRandom(12);
  final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
  final encrypted = encrypter.encrypt(
      jsonEncode(badges.map((b) => b.toJson()).toList()),
      iv: iv);
  return '${iv.base64}:${encrypted.base64}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> secure;

  setUp(() {
    secure = {};
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(secure);
    MeetupBadge.badgesUnreadable = false;
    MeetupBadge.onBadgesSaved = null;
  });

  test('kaputter Badge-Schlüssel ohne Datei: Restore schiebt ihn beiseite und schreibt', () async {
    secure[_keyAlias] = 'kein-schluessel';

    final ok = await BackupService.restoreBadges([_badge('a')]);

    expect(ok, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(_blobKey), isTrue);
    // Der unbrauchbare Wert bleibt für eine spätere Untersuchung liegen.
    expect(secure[_suspectKeyAlias], 'kein-schluessel');
    expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(secure[_keyAlias] ?? ''), isTrue);
    final loaded = await MeetupBadge.loadBadges();
    expect(loaded.map((b) => b.id), ['a']);
  });

  test('nicht lesbarer sicherer Speicher: Restore meldet Fehlschlag',
      () async {
    final blob = _blob([_badge('alt')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});
    FlutterSecureStoragePlatform.instance = _BrokenStorage(secure);
    await MeetupBadge.loadBadges();

    final ok = await BackupService.restoreBadges([_badge('a')]);

    expect(ok, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), blob);
  });

  test('leeres Backup bei nicht lesbarer Sammlung ist kein Fehler', () async {
    final blob = _blob([_badge('alt')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});
    await MeetupBadge.loadBadges();

    final ok = await BackupService.restoreBadges([]);

    expect(ok, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), blob);
  });

  test('gelungener Restore schreibt die Badges', () async {
    final ok = await BackupService.restoreBadges([_badge('a'), _badge('b')]);

    expect(ok, isTrue);
    final loaded = await MeetupBadge.loadBadges();
    expect(loaded.map((b) => b.id), ['a', 'b']);
  });
}
