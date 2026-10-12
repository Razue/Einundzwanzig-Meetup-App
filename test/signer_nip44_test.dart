// Der Badge-Sync braucht NIP-44 über jeden Signer. Local rechnet selbst,
// die anderen reichen an Amber, die Erweiterung oder den Bunker weiter.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/services/nip44.dart';
import 'package:einundzwanzig_meetup_app/services/secure_key_store.dart';
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final kc = Keychain.generate();
  final other = Keychain.generate();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'secure_migration_done': true});
    FlutterSecureStorage.setMockInitialValues({});
    await SecureKeyStore.saveKeys(
      nsec: Nip19.encodePrivkey(kc.private),
      npub: Nip19.encodePubkey(kc.public),
      privHex: kc.private,
    );
  });

  test('Local signiert NIP-44 hin und zurück', () async {
    final signer = LocalNostrSigner();
    final sealed = await signer.nip44Encrypt(other.public, 'hallo sync');
    final opened = await signer.nip44Decrypt(other.public, sealed);
    expect(opened, 'hallo sync');
  });

  test('Local nutzt denselben Schlüssel wie die App-NIP-44', () async {
    final signer = LocalNostrSigner();
    final sealed = await signer.nip44Encrypt(other.public, 'rundreise');
    final key = Nip44.conversationKey(
      privkeyHex: kc.private, pubkeyHex: other.public);
    expect(Nip44.decrypt(sealed, key), 'rundreise');
  });

  test('NIP-07-Signer reicht an die Erweiterung weiter', () async {
    final seen = <String>[];
    final signer = Nip07NostrSigner(
      expectedPubkeyHex: kc.public,
      debugNip44EncryptFn: (pk, text) async {
        seen.add('encrypt:$pk:$text');
        return 'sealed:$text';
      },
      debugNip44DecryptFn: (pk, payload) async {
        seen.add('decrypt:$pk:$payload');
        return payload.replaceFirst('sealed:', '');
      },
    );
    final sealed = await signer.nip44Encrypt(other.public, 'chunk');
    expect(sealed, 'sealed:chunk');
    expect(await signer.nip44Decrypt(other.public, sealed), 'chunk');
    expect(seen, ['encrypt:${other.public}:chunk', 'decrypt:${other.public}:sealed:chunk']);
  });

  test('NIP-46-Signer ruft die Bunker-Methoden', () async {
    final calls = <String>[];
    final signer = Nip46NostrSigner(
      expectedPubkeyHex: kc.public,
      clientProvider: () => throw StateError('kein echter Client im Test'),
      debugNip44Fn: (method, pk, value) async {
        calls.add('$method:$pk:$value');
        return method == 'nip44_encrypt' ? 'out:$value' : value.substring(4);
      },
    );
    final sealed = await signer.nip44Encrypt(other.public, 'chunk');
    expect(sealed, 'out:chunk');
    expect(await signer.nip44Decrypt(other.public, sealed), 'chunk');
    expect(calls, [
      'nip44_encrypt:${other.public}:chunk',
      'nip44_decrypt:${other.public}:out:chunk',
    ]);
  });

  test('canNip44 ist true im lokalen Modus mit Schlüssel', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('signing_mode', 'local');
    expect(await SigningService.canNip44(), isTrue);
  });
}
