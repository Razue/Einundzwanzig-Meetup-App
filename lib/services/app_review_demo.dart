// ============================================
// APP-REVIEW-DEMO — statischer QR für Apple
// ============================================
// Live-Meetup-QRs laufen alle paar Sekunden ab (Anti-Screenshot). Für die
// Prüfung braucht Apple ein Bild, das sie scannen können. Kein Portal-Konto,
// kein echter Organisator-Schlüssel.

import 'package:flutter/material.dart';

import '../theme.dart';

class AppReviewDemo {
  static const payload = '21review:einundzwanzig-meetup-demo';

  static bool matches(String? raw) =>
      raw != null && raw.trim() == payload;

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
