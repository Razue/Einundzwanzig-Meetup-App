import 'package:einundzwanzig_meetup_app/services/signing_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('recommendedExistingPath', () {
    test('ohne Extension und ohne Amber → bunker', () async {
      // Auf dem Test-Host (macOS/Linux/Windows) ist weder Amber noch
      // eine Browsererweiterung verfügbar.
      final path = await SigningService.recommendedExistingPath();
      if (kIsWeb) {
        // Im Web-Test ohne Extension ebenfalls Bunker.
        expect(path, RecommendedExistingPath.bunker);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Amber-Verfügbarkeit hängt vom MethodChannel ab — ohne Plugin bunker.
        expect(
          path,
          anyOf(
            RecommendedExistingPath.amber,
            RecommendedExistingPath.bunker,
          ),
        );
      } else {
        expect(path, RecommendedExistingPath.bunker);
      }
    });
  });
}
