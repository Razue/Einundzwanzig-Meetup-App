// ============================================
// APP-REVIEW-DEMO — Login + statischer QR für Apple
// ============================================
// Live-Meetup-QRs laufen alle paar Sekunden ab (Anti-Screenshot). Für die
// Prüfung braucht Apple (1) ein Login mit User Name / Password und (2) ein
// Bild, das sie scannen können. Beides ist nur für Reviewer; es entsteht
// kein Portal-Konto und kein echter Organisator-Schlüssel.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/badge.dart';
import '../models/user.dart';
import '../theme.dart';
import 'local_easy_auth.dart';
import 'secure_key_store.dart';

class AppReviewDemo {
  static const payload = '21review:einundzwanzig-meetup-demo';

  /// Genau die Werte aus App Store Connect → TestFlight → Testinformationen.
  static const username = 'AppReview';
  static const password = 'ReviewDemo1';

  static const _prefsFlag = 'app_review_demo';

  static bool matches(String? raw) =>
      raw != null && raw.trim() == payload;

  static bool isDemoLogin(String user, String pass) =>
      user.trim() == username && pass == password;

  /// Nur TestFlight (Apple-Beta-Prüfung) und Debug — nicht AltStore / Release.
  static Future<bool> shouldOfferSignIn() async {
    if (kDebugMode) return true;
    if (const bool.fromEnvironment('APP_REVIEW_SIGNIN')) return true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
    try {
      const channel = MethodChannel('einundzwanzig/review');
      final raw = await channel.invokeMethod<bool>('isTestFlight');
      return raw ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Richtet die lokale Demo-Identität ein (oder steigt wieder ein).
  static Future<void> signIn(String user, String pass) async {
    // Dieselbe Umgebungsprüfung wie shouldOfferSignIn(), hier am Eingang:
    // Die UI blendet den Login zwar nur fuer Reviewer ein, aber die
    // Methode selbst muss in Release-/AltStore-Builds ebenfalls dicht sein
    // — die Zugangsdaten stehen im Binary.
    if (!await shouldOfferSignIn()) {
      throw const LocalEasyAuthException(
          'Demo sign-in is not available in this build.');
    }
    if (!isDemoLogin(user, pass)) {
      // Keine Credential-Hinweise in der Fehlermeldung — die Testinformationen
      // stehen in App Store Connect, nicht in der App.
      throw const LocalEasyAuthException('Unknown user name or password.');
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = await UserProfile.load();
    final isDemoProfile = existing.nickname == username &&
        (prefs.getBool(_prefsFlag) ?? false);
    if (isDemoProfile && existing.hasNostrKey) {
      return;
    }

    // register() legt einen NEUEN Schluessel an und wuerde eine vorhandene
    // Identitaet ueberschreiben. Die Demo darf das nie bei einem echten
    // Profil — nur auf einem Geraet ohne eigenen Key.
    if (!isDemoProfile && await SecureKeyStore.hasKey()) {
      throw const LocalEasyAuthException(
          'Demo sign-in is only available on a fresh install.');
    }

    await LocalEasyAuth.register(nickname: username, password: password);

    final userProfile = await UserProfile.load();
    // KEIN adminViaSeed / isAdminVerified: Die Demo soll Organisator-UI
    // zeigen, aber keine echten Rechte erhalten. isReviewDemo speist
    // isAdmin nicht und gilt nicht bei EventBadgeAuthService.
    userProfile.isReviewDemo = true;
    userProfile.homeMeetupId = 'Berlin';
    userProfile.favoriteMeetupIds = ['Berlin'];
    await userProfile.save();

    await MeetupBadge.saveBadges([
      MeetupBadge(
        id: 'review-demo-badge-1',
        meetupName: 'App Review Demo Meetup',
        date: DateTime.now().subtract(const Duration(days: 7)),
        iconPath: '',
        delivery: 'rolling_qr',
        isRetroactive: true,
      ),
    ]);
    await prefs.setBool(_prefsFlag, true);
  }

  static Future<void> showSuccess(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: const Text(
          'Demo scan OK',
          style: TextStyle(color: cText, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This is how participants collect a meetup badge: they scan the '
          'organizer QR on site. Live codes are cryptographically signed and '
          'expire within seconds so a photo cannot be reused. This demo code '
          'does not issue a real badge.',
          style: TextStyle(color: cTextSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: cOrange)),
          ),
        ],
      ),
    );
  }
}
