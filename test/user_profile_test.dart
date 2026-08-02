import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/models/user.dart';

void main() {
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
}
