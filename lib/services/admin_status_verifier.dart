// ============================================
// ADMIN STATUS VERIFIER — Kryptographische Prüfung
// ============================================
//
// SECURITY AUDIT C2: Admin-Status darf NICHT nur auf
// einem SharedPreferences Boolean basieren. Auf gerooteten
// Geräten kann jeder User `is_admin = true` setzen.
//
// LÖSUNG: Admin-Status wird bei JEDEM App-Start
// kryptographisch verifiziert durch:
//
//   1. Trust Score live aus Nostr-signierten Badges berechnen
//   2. Seed-Admin Prüfung gegen AdminRegistry
//
// Der SharedPreferences-Wert dient NUR als Cache für
// die Offline-UI. Sicherheitskritische Operationen
// (Signieren, NFC-Tags erstellen) MÜSSEN immer über
// verifyAdminStatus() geprüft werden.
//
// ============================================

import '../models/badge.dart';
import 'admin_registry.dart';
import 'nostr_service.dart';
import 'signing_service.dart';
import 'trust_score_service.dart';

class AdminVerification {
  final bool isAdmin;
  final String source; // 'trust_score', 'seed_admin', 'not_admin'
  final String reason;

  const AdminVerification({
    required this.isAdmin,
    required this.source,
    this.reason = '',
  });

  static const notAdmin = AdminVerification(
    isAdmin: false,
    source: 'not_admin',
    reason: 'Weder Trust Score noch Seed-Admin Bedingungen erfüllt.',
  );
}

class AdminStatusVerifier {
  // =============================================
  // HAUPTMETHODE: Kryptographische Admin-Prüfung
  // =============================================
  //
  // Wird bei jedem App-Start aufgerufen.
  // Gibt verified=true zurück wenn EINE der Bedingungen gilt:
  //
  //   a) Trust Score aus Nostr-signierten Badges >= Schwellenwert
  //   b) User ist in der AdminRegistry als Seed-Admin gelistet
  //
  // =============================================
  static Future<AdminVerification> verifyAdminStatus({
    required List<MeetupBadge> badges,
  }) async {
    // --- CHECK 1: Hat der User überhaupt eine Signier-Identität? ---
    // (lokaler Key ODER Amber verbunden)
    final hasKey = await SigningService.canSign();
    if (!hasKey) {
      return const AdminVerification(
        isAdmin: false,
        source: 'no_key',
        reason: 'Kein Nostr-Key vorhanden.',
      );
    }

    // --- CHECK 2: Trust Score (aus Nostr-signierten Badges) ---
    // calculateScore() filtert bereits v1 Badges raus (Security Audit C1)
    if (badges.isNotEmpty) {
      final sorted = List<MeetupBadge>.from(badges)
        ..sort((a, b) => a.date.compareTo(b.date));
      final score = TrustScoreService.calculateScore(
        badges: badges,
        firstBadgeDate: sorted.first.date,
      );
      if (score.meetsPromotionThreshold) {
        return AdminVerification(
          isAdmin: true,
          source: 'trust_score',
          reason: 'Trust Score ${score.totalScore.toStringAsFixed(1)} '
              'erfüllt Schwellenwert (${score.activeThresholds.promotionScore}).',
        );
      }
    }

    // --- Bürgschafts-Konsens: ENTFERNT (August 2026) ---
    //
    // Hier stand ein dritter Weg zum Organisator: genug Bürgschaften im
    // Netzwerk. Er ist weggefallen, weil er kein offenes Problem loeste.
    //
    // Wer ein Meetup im Portal eintraegt, wird dort automatisch Leader,
    // darf Badges ausstellen und andere befoerdern — das deckt sowohl die
    // Gruendung als auch die Weitergabe ab. Und der Portal-Weg ist
    // WIDERRUFBAR: Ein Eintrag laesst sich austragen. Ein per Bürgschaft
    // befoerderter Organisator haette in keiner Meetup-Struktur gestanden,
    // und der Entzug haette den Widerruf jedes einzelnen Bürgen gebraucht.
    //
    // Es bleiben zwei Wege: Portal (adminViaPortal) und Trust Score.

    // --- CHECK 3: ECHTER Seed-/Super-Admin ---
    // WICHTIG: Für die SELBST-Prüfung zählt NUR ein echter Super-Admin
    // (hardcodierter npub). Die Quellen 'nostr_relay' und 'local_cache'
    // sind SELBST-publizierte Organizer-Claims des eigenen Schlüssels —
    // sie würden den Status zirkulär "beweisen" und einen im Portal
    // entzogenen Organisator fälschlich weiter als Admin führen. Der
    // Portal-Status läuft ohnehin getrennt über adminViaPortal, der
    // Vouch-Status über den Trust Score.
    final npub = await NostrService.getNpub();
    if (npub != null && npub.isNotEmpty) {
      try {
        final result = await AdminRegistry.checkAdmin(npub);
        if (result.isAdmin && result.source == 'super_admin') {
          return AdminVerification(
            isAdmin: true,
            source: 'seed_admin',
            reason: 'Super-Admin (${result.source}).',
          );
        }
      } catch (_) {
        // Registry nicht erreichbar — kein Admin-Status vergeben
        // Sicherheit > Verfügbarkeit: Im Zweifel NICHT Admin
      }
    }

    return AdminVerification.notAdmin;
  }

  // =============================================
  // SCHNELL-CHECK: Für sicherheitskritische Operationen
  // =============================================
  //
  // Kurzform für Guards in Signatur-Operationen.
  // Beispiel:
  //   if (!await AdminStatusVerifier.isVerifiedAdmin(badges)) {
  //     throw SecurityException('Kein verifizierter Admin');
  //   }
  //
  // =============================================
  static Future<bool> isVerifiedAdmin({
    required List<MeetupBadge> badges,
  }) async {
    final result = await verifyAdminStatus(badges: badges);
    return result.isAdmin;
  }
}



