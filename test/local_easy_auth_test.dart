import 'package:einundzwanzig_meetup_app/models/user.dart';
import 'package:einundzwanzig_meetup_app/services/local_easy_auth.dart';
import 'package:einundzwanzig_meetup_app/services/local_key_vault.dart';
import 'package:einundzwanzig_meetup_app/services/nip49.dart';
import 'package:einundzwanzig_meetup_app/services/nostr_service.dart';
import 'package:einundzwanzig_meetup_app/services/secure_key_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-Memory-Ersatz fuer flutter_secure_storage (wie nip46_signing_service_test).
void mockSecureStorage() {
  final store = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      switch (call.method) {
        case 'write':
          store['${args['key']}'] = '${args['value']}';
          return null;
        case 'read':
          return store['${args['key']}'];
        case 'delete':
          store.remove('${args['key']}');
          return null;
        case 'readAll':
          return store;
        case 'deleteAll':
          store.clear();
          return null;
        case 'containsKey':
          return store.containsKey('${args['key']}');
      }
      return null;
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'secure_migration_done': true});
    mockSecureStorage();
    await SecureKeyStore.deleteKeys();
    await LocalKeyVault.clearAll();
  });

  test('register legt Key, Nickname und password-wrap an', () async {
    await LocalEasyAuth.register(
      nickname: 'Ralph',
      password: 'test-password-ok',
    );

    expect(await SecureKeyStore.hasKey(), isTrue);
    final wrap = await LocalKeyVault.getPasswordWrap();
    expect(wrap, isNotNull);
    expect(wrap!.startsWith('ncryptsec1'), isTrue);

    final user = await UserProfile.load();
    expect(user.nickname, 'Ralph');
    expect(user.isOnboarded, isTrue);

    final privBefore = await SecureKeyStore.getPrivHex();
    await SecureKeyStore.deleteKeys();
    expect(await SecureKeyStore.hasKey(), isFalse);

    await LocalEasyAuth.unlockWithPassword('test-password-ok');
    expect(await SecureKeyStore.getPrivHex(), privBefore);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('register lehnt kurzes Passwort und Anon ab', () async {
    expect(
      () => LocalEasyAuth.register(nickname: 'Anon', password: 'longenough'),
      throwsA(isA<LocalEasyAuthException>()),
    );
    expect(
      () => LocalEasyAuth.register(nickname: 'Ok', password: 'short'),
      throwsA(isA<LocalEasyAuthException>()),
    );
  });

  test('importNcryptsec lädt denselben Key', () async {
    final keys = await NostrService.generateKeyPair();
    final priv = await SecureKeyStore.getPrivHex();
    final wrap = await Nip49.encrypt(priv!, 'pw-import-test');
    await SecureKeyStore.deleteKeys();

    final imported = await NostrService.importNcryptsec(wrap, 'pw-import-test');
    expect(imported['npub'], keys['npub']);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('register raeumt alten Passkey-Wrap und bindet npub', () async {
    await LocalKeyVault.savePasskeyWrap(
      ncryptsec: 'ncryptsec1-alt',
      credentialId: 'cred-alt',
    );
    await LocalEasyAuth.register(
      nickname: 'Neu',
      password: 'test-password-ok',
    );

    expect(await LocalKeyVault.hasPasskeyWrap(), isFalse);
    final npub = await SecureKeyStore.getNpub();
    expect(npub, isNotNull);
    expect(await LocalKeyVault.passwordWrapMatchesNpub(npub!), isTrue);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
