// Der Vault haelt VOLLSTAENDIGE Kopien des privaten Schluessels — nur
// passwortverschluesselt. Deshalb pruefen diese Tests vor allem eines: dass
// `clearAll()` wirklich alles loescht. Bleibt dort ein Wrap liegen, ueberlebt
// die Identitaet ein „Zuruecksetzen", von dem der Nutzer das Gegenteil erwartet.

import 'package:einundzwanzig_meetup_app/services/local_key_vault.dart';
import 'package:einundzwanzig_meetup_app/services/passkey_prf_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_easy_auth_test.dart' show mockSecureStorage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'secure_migration_done': true});
    mockSecureStorage();
    await LocalKeyVault.clearAll();
  });

  test('leerer Vault meldet nichts', () async {
    expect(await LocalKeyVault.getPasswordWrap(), isNull);
    expect(await LocalKeyVault.getPasskeyWrap(), isNull);
    expect(await LocalKeyVault.getPasskeyCredentialId(), isNull);
    expect(await LocalKeyVault.hasPasskeyWrap(), isFalse);
  });

  test('Passwort- und Passkey-Wrap liegen getrennt', () async {
    await LocalKeyVault.savePasswordWrap(
      'ncryptsec1-passwort',
      npub: 'npub1test',
    );
    await LocalKeyVault.savePasskeyWrap(
      ncryptsec: 'ncryptsec1-passkey',
      credentialId: 'cred-abc',
    );

    expect(await LocalKeyVault.getPasswordWrap(), 'ncryptsec1-passwort');
    expect(await LocalKeyVault.getPasswordWrapNpub(), 'npub1test');
    expect(await LocalKeyVault.getPasskeyWrap(), 'ncryptsec1-passkey');
    expect(await LocalKeyVault.getPasskeyCredentialId(), 'cred-abc');
    expect(await LocalKeyVault.hasPasskeyWrap(), isTrue);
  });

  test('clearPasskeyWrap laesst den Passwort-Wrap stehen', () async {
    await LocalKeyVault.savePasswordWrap(
      'ncryptsec1-passwort',
      npub: 'npub1test',
    );
    await LocalKeyVault.savePasskeyWrap(
      ncryptsec: 'ncryptsec1-passkey',
      credentialId: 'cred-abc',
    );

    await LocalKeyVault.clearPasskeyWrap();

    // Wer den Passkey entfernt, will nicht den letzten Weg zum Schluessel
    // verlieren: das Passwort muss bleiben.
    expect(await LocalKeyVault.getPasswordWrap(), 'ncryptsec1-passwort');
    expect(await LocalKeyVault.getPasskeyWrap(), isNull);
    expect(await LocalKeyVault.getPasskeyCredentialId(), isNull);
    expect(await LocalKeyVault.hasPasskeyWrap(), isFalse);
  });

  test('clearAll loescht alle Felder inklusive npub-Bindung', () async {
    await LocalKeyVault.savePasswordWrap(
      'ncryptsec1-passwort',
      npub: 'npub1test',
    );
    await LocalKeyVault.savePasskeyWrap(
      ncryptsec: 'ncryptsec1-passkey',
      credentialId: 'cred-abc',
    );

    await LocalKeyVault.clearAll();

    expect(await LocalKeyVault.getPasswordWrap(), isNull);
    expect(await LocalKeyVault.getPasswordWrapNpub(), isNull);
    expect(await LocalKeyVault.getPasskeyWrap(), isNull);
    expect(await LocalKeyVault.getPasskeyCredentialId(), isNull);
  });

  test('passwordWrapMatchesNpub verlangt passende Bindung', () async {
    await LocalKeyVault.savePasswordWrap(
      'ncryptsec1-passwort',
      npub: 'npub1alice',
    );
    expect(await LocalKeyVault.passwordWrapMatchesNpub('npub1alice'), isTrue);
    expect(await LocalKeyVault.passwordWrapMatchesNpub('npub1bob'), isFalse);
  });

  test('Wrap ohne npub-Bindung gilt als Nicht-Treffer', () async {
    // Altbestand / manipulierter Store: Wrap da, Bindung fehlt → nicht exportieren.
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
        }
        return null;
      },
    );
    store['easyauth_password_ncryptsec'] = 'ncryptsec1-orphan';
    expect(await LocalKeyVault.passwordWrapMatchesNpub('npub1x'), isFalse);
  });

  test('hasPasskeyWrap verlangt Wrap UND credential_id', () async {
    // Halber Zustand: ohne die credential_id findet `unlock()` den Passkey
    // nicht, der Wrap allein ist also nicht benutzbar.
    await LocalKeyVault.savePasskeyWrap(
      ncryptsec: 'ncryptsec1-passkey',
      credentialId: '',
    );
    expect(await LocalKeyVault.getPasskeyWrap(), 'ncryptsec1-passkey');
    expect(await LocalKeyVault.hasPasskeyWrap(), isFalse);
  });

  test('geteilte Domains stehen NICHT auf der Passkey-Erlaubnisliste', () {
    // Ein Passkey im Browser gehoert der rpId = dem Host. Auf `*.github.io`
    // liegt dieser Namensraum bei allen Projekten gemeinsam. Wer hier einen
    // github.io-Host eintraegt, um den Passkey „zum Laufen" zu bringen, legt
    // Schluesselmaterial in einen Namensraum, den er nicht kontrolliert.
    for (final host in PasskeyPrfService.allowedWebHosts) {
      expect(host.endsWith('.github.io'), isFalse, reason: host);
      expect(host.endsWith('.pages.dev'), isFalse, reason: host);
      expect(host.endsWith('.netlify.app'), isFalse, reason: host);
      expect(host.endsWith('.vercel.app'), isFalse, reason: host);
    }
  });
}
