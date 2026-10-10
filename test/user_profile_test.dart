import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/models/user.dart';
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const author =
      'fa5e3477d2d6b92d667dcab66c8bbb1527014599c5eecddd545e3a39d7870268';
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  group('UserProfile onboarding', () {
    test('requires a custom nickname or verified identity', () {
      expect(UserProfile().isOnboarded, isFalse);
      expect(UserProfile(nickname: '').isOnboarded, isFalse);
      expect(UserProfile(nickname: 'Anon').isOnboarded, isFalse);

      expect(UserProfile(nickname: 'Satoshi').isOnboarded, isTrue);
      expect(UserProfile(isNostrVerified: true).isOnboarded, isTrue);
      expect(UserProfile(isAdminVerified: true).isOnboarded, isTrue);
    });
  });

  test(
    'first public NPUB import is available to profile lookup without a private key',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nostr', Nip19.encodePubkey(author));
      final profile = await UserProfile.load();
      expect(profile.hasNostrKey, isFalse);
      expect(Nip19.decodePubkey(profile.nostrNpub), author);
    },
  );

  test(
    'restored remote signer preserves public identity even without a signing session',
    () async {
      await SigningService.restoreNip46(
        npub: Nip19.encodePubkey(author),
        bunkerUri: 'bunker://$author?relay=wss://relay.example',
      );
      final profile = await UserProfile.load();
      expect(profile.hasNostrKey, isFalse);
      expect(await SigningService.canSign(), isFalse);
      expect(Nip19.decodePubkey(profile.nostrNpub), author);
    },
  );
}
