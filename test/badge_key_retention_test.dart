// Der Badge-Schlüssel darf bei einem Lese-Fehler nicht neu erzeugt werden.
// Die verschlüsselte Datei bleibt liegen, ein anderer Schlüssel im Speicher
// kann sie noch öffnen, und ein Speichern überschreibt sie nicht.

import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';

const _blobKey = 'badges_encrypted';
const _preservedKey = 'badges_encrypted_preserved';
const _olderKey = 'badges_encrypted_preserved_older';
const _keyAlias = 'badge_encryption_key';
const _suspectKeyAlias = 'badge_encryption_key_suspect';
const _pendingBlobKey = 'badges_pending_encrypted';
const _pendingKeyAlias = 'badge_pending_key';
const _legacyPendingKey = 'badges_pending';

class _BrokenRead extends TestFlutterSecureStoragePlatform {
  _BrokenRead(super.data);

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) =>
      throw PlatformException(code: 'keystore');
}

MeetupBadge _badge(String id) => MeetupBadge(
      id: id,
      meetupName: 'Aschaffenburg',
      date: DateTime.utc(2026, 10, 11, 19),
      iconPath: 'assets/badge_icon.png',
    );

MeetupBadge _privateBadge(String id) => MeetupBadge(
      id: id,
      meetupName: 'Geheimtreffen Hinterzimmer',
      date: DateTime.utc(2026, 10, 11, 19),
      iconPath: 'assets/badge_icon.png',
      lat: 49.97654,
      lng: 9.14321,
      claimSig: 'c' * 128,
    );

String _hexKey() => enc.Key.fromSecureRandom(32)
    .bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0'))
    .join();

String _blob(String keyHex, List<MeetupBadge> badges) {
  final key = enc.Key(Uint8List.fromList(List.generate(
      32, (i) => int.parse(keyHex.substring(i * 2, i * 2 + 2), radix: 16))));
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

  test('legt einen Schlüssel an und liest die Badges wieder', () async {
    await MeetupBadge.saveBadges([_badge('a')]);
    final loaded = await MeetupBadge.loadBadges();
    expect(loaded.map((b) => b.id), ['a']);
    expect(MeetupBadge.badgesUnreadable, isFalse);
    expect(secure[_keyAlias], hasLength(64));
  });

  test('fehlender Schlüssel erzeugt keinen neuen und lässt die Datei liegen',
      () async {
    final good = _hexKey();
    final blob = _blob(good, [_badge('a')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});

    final loaded = await MeetupBadge.loadBadges();

    expect(loaded, isEmpty);
    expect(MeetupBadge.badgesUnreadable, isTrue);
    expect(secure.containsKey(_keyAlias), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), blob);
    expect(prefs.getString(_preservedKey), blob);
  });

  test('ein Lese-Fehler schreibt keinen neuen Schlüssel', () async {
    final blob = _blob(_hexKey(), [_badge('a')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});
    FlutterSecureStoragePlatform.instance = _BrokenRead(secure);

    final loaded = await MeetupBadge.loadBadges();

    expect(loaded, isEmpty);
    expect(MeetupBadge.badgesUnreadable, isTrue);
    expect(secure, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), blob);
  });

  test('ein Schlüssel mit falscher Länge wird nicht ersetzt', () async {
    secure[_keyAlias] = 'kein-schluessel';
    final blob = _blob(_hexKey(), [_badge('a')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});

    await MeetupBadge.loadBadges();

    expect(secure[_keyAlias], 'kein-schluessel');
    expect(MeetupBadge.badgesUnreadable, isTrue);
  });

  test('ein anderer Wert im Speicher öffnet die Datei wieder', () async {
    final good = _hexKey();
    secure[_keyAlias] = _hexKey();
    secure['old_badge_key'] = good;
    final blob = _blob(good, [_badge('a')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});

    final loaded = await MeetupBadge.loadBadges();

    expect(loaded.map((b) => b.id), ['a']);
    expect(secure[_keyAlias], good);
    expect(MeetupBadge.badgesUnreadable, isFalse);
  });

  test('Speichern überschreibt eine nicht lesbare Datei nicht', () async {
    final blob = _blob(_hexKey(), [_badge('a')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});
    await MeetupBadge.loadBadges();

    final wrote = await MeetupBadge.saveBadges([_badge('neu')]);

    expect(wrote, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), blob);
    expect(secure.containsKey(_keyAlias), isFalse);
  });

  test('vorgemerkter Scan kommt dazu, sobald der Schlüssel wieder da ist',
      () async {
    final good = _hexKey();
    final blob = _blob(good, [_badge('alt')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});
    await MeetupBadge.loadBadges();
    await MeetupBadge.keepAside(_badge('neu'));

    secure[_keyAlias] = good;
    final loaded = await MeetupBadge.loadBadges();

    expect(loaded.map((b) => b.id), containsAll(['alt', 'neu']));
    expect(MeetupBadge.badgesUnreadable, isFalse);
  });

  test('Reset räumt auch die Sicherung ab', () async {
    final blob = _blob(_hexKey(), [_badge('a')]);
    SharedPreferences.setMockInitialValues({
      _blobKey: blob,
      _preservedKey: blob,
    });
    await MeetupBadge.loadBadges();

    final wrote = await MeetupBadge.saveBadges([], discardLocked: true);

    expect(wrote, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), isNull);
    expect(prefs.getString(_preservedKey), isNull);
    expect(MeetupBadge.badgesUnreadable, isFalse);
  });

  test('Leer-Speichern löscht eine nicht lesbare Datei nicht', () async {
    final blob = _blob(_hexKey(), [_badge('a')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});
    await MeetupBadge.loadBadges();

    final wrote = await MeetupBadge.saveBadges([]);

    expect(wrote, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), blob);
  });

  test('vorgemerkter Scan liegt nicht im Klartext', () async {
    final blob = _blob(_hexKey(), [_badge('alt')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});
    await MeetupBadge.loadBadges();

    await MeetupBadge.keepAside(_privateBadge('neu'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(_legacyPendingKey), isFalse);
    expect(prefs.getString(_pendingBlobKey), contains(':'));
    for (final key in prefs.getKeys()) {
      final value = '${prefs.get(key)}';
      expect(value, isNot(contains('Geheimtreffen')), reason: key);
      expect(value, isNot(contains('49.97')), reason: key);
      expect(value, isNot(contains('c' * 128)), reason: key);
    }
    // Eigener Schlüssel, der kaputte Badge-Schlüssel bleibt unangetastet.
    expect(secure[_pendingKeyAlias], hasLength(64));
    expect(secure.containsKey(_keyAlias), isFalse);
  });

  test('nach dem Zusammenführen sind Vormerkung und ihr Schlüssel weg',
      () async {
    final good = _hexKey();
    final blob = _blob(good, [_badge('alt')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});
    await MeetupBadge.loadBadges();
    await MeetupBadge.keepAside(_privateBadge('neu'));

    secure[_keyAlias] = good;
    final loaded = await MeetupBadge.loadBadges();

    final neu = loaded.firstWhere((b) => b.id == 'neu');
    expect(neu.meetupName, 'Geheimtreffen Hinterzimmer');
    expect(neu.lat, 49.97654);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(_pendingBlobKey), isFalse);
    expect(secure.containsKey(_pendingKeyAlias), isFalse);
  });

  test('Klartext-Vormerkung aus Testbuilds wird verschlüsselt übernommen',
      () async {
    final good = _hexKey();
    SharedPreferences.setMockInitialValues({
      _blobKey: _blob(good, [_badge('alt')]),
      _legacyPendingKey: [jsonEncode(_privateBadge('klartext').toJson())],
    });
    await MeetupBadge.loadBadges();

    await MeetupBadge.keepAside(_badge('neu'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(_legacyPendingKey), isFalse);
    expect(prefs.getString(_pendingBlobKey), isNot(contains('Geheimtreffen')));

    secure[_keyAlias] = good;
    final loaded = await MeetupBadge.loadBadges();
    expect(loaded.map((b) => b.id), containsAll(['alt', 'klartext', 'neu']));
  });

  test('eine nicht lesbare Vormerkung wird beim Speichern nicht verworfen',
      () async {
    final pendingBlob = _blob(_hexKey(), [_badge('vorgemerkt')]);
    SharedPreferences.setMockInitialValues({_pendingBlobKey: pendingBlob});

    final wrote = await MeetupBadge.saveBadges([_badge('a')]);

    expect(wrote, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_pendingBlobKey), pendingBlob);
  });

  test('keepAside meldet true, wenn die Vormerkung klappt', () async {
    expect(await MeetupBadge.keepAside(_badge('neu')), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_pendingBlobKey), contains(':'));
  });

  test('keepAside meldet false, wenn die Vormerkung nicht lesbar ist', () async {
    final pendingBlob = _blob(_hexKey(), [_badge('vorgemerkt')]);
    SharedPreferences.setMockInitialValues({_pendingBlobKey: pendingBlob});

    expect(await MeetupBadge.keepAside(_badge('neu')), isFalse);
  });

  test('öffnen vereinigt Primärdatei und Sicherung nach Id', () async {
    final keyA = _hexKey();
    final keyB = _hexKey();
    final primaryBlob = _blob(keyA, [_badge('a'), _badge('b')]);
    secure[_keyAlias] = keyA;
    secure['old_badge_key'] = keyB;
    SharedPreferences.setMockInitialValues({
      _blobKey: primaryBlob,
      _preservedKey: _blob(keyB, [_badge('b'), _badge('c')]),
    });

    final loaded = await MeetupBadge.loadBadges();

    expect(loaded.map((b) => b.id), containsAll(['a', 'b', 'c']));
    expect(MeetupBadge.badgesUnreadable, isFalse);
    // Der Primäre ist die Datei geblieben, nicht durch die Sicherung ersetzt.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_blobKey), primaryBlob);
  });

  test('ein zweites Ersetzen schiebt die Sicherung eine Stufe älter',
      () async {
    final blob = _blob(_hexKey(), [_badge('alt')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});
    await MeetupBadge.loadBadges();

    final ok1 =
        await MeetupBadge.saveBadges([_badge('fern1')], replaceUnreadable: true);
    final ok2 =
        await MeetupBadge.saveBadges([_badge('fern2')], replaceUnreadable: true);
    expect(ok1, isTrue);
    expect(ok2, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_olderKey), blob);
    expect(prefs.getString(_preservedKey), isNot(blob));

    // Beide neuen Fassungen kommen über die Vereinigung dazu.
    final loaded = await MeetupBadge.loadBadges();
    expect(loaded.map((b) => b.id), containsAll(['fern1', 'fern2']));
    expect(MeetupBadge.badgesUnreadable, isFalse);
  });

  test('Ersetzen mit unbrauchbarem Schlüsselwert legt ihn beiseite', () async {
    secure[_keyAlias] = 'kein-schluessel';
    final blob = _blob(_hexKey(), [_badge('alt')]);
    SharedPreferences.setMockInitialValues({_blobKey: blob});
    await MeetupBadge.loadBadges();

    final wrote =
        await MeetupBadge.saveBadges([_badge('neu')], replaceUnreadable: true);

    expect(wrote, isTrue);
    expect(secure[_suspectKeyAlias], 'kein-schluessel');
    expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(secure[_keyAlias] ?? ''), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_preservedKey), blob);
    final loaded = await MeetupBadge.loadBadges();
    expect(loaded.map((b) => b.id), ['neu']);
    expect(MeetupBadge.badgesUnreadable, isFalse);
  });
}
