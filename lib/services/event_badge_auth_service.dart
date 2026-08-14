// EVENT-BADGES — Berechtigung
// ============================================
// Zwei getrennte Fragen, die gern verwechselt werden:
//
//   1. Wer darf ein Event MIT BADGE anlegen?
//      -> wer in der Admin-Registry steht ODER im Portal Leader ist.
//
//   2. Wer darf fuer ein bestehendes Event Badges AUSSTELLEN?
//      -> wer im Event als issuer eingetragen ist, plus der Ersteller.
//      Das prueft NostrCalendarEvent.isIssuer() und braucht keinen Dienst.
//
// Punkt 1 steht hier. Bewusst zwei Quellen: Die Admin-Registry liegt auf
// Nostr und funktioniert ohne Konto und offline (Zwischenspeicher); die
// Portal-Leader decken alle ab, die dort eingetragen sind, aber nie in die
// Admin-Registry aufgenommen wurden. Wer in EINER der beiden Listen steht,
// darf — sonst schliesst man Leute aus, die heute schon Badges verteilen.
// ============================================

import 'app_logger.dart';
import 'admin_registry.dart';
import 'portal_api_service.dart';
import 'signing_service.dart';

const String _tag = 'EventBadge';

/// Woher die Berechtigung stammt — fuer die Anzeige und fuer das Log.
enum EventBadgeRight { none, adminRegistry, portalLeader }

class EventBadgeAuthService {
  EventBadgeAuthService._();

  /// Darf die eigene Identitaet ein Event mit Badge anlegen?
  ///
  /// Die Admin-Registry wird zuerst gefragt: Sie ist zwischengespeichert und
  /// antwortet auch ohne Netz. Das Portal kommt nur dran, wenn das nichts
  /// ergeben hat — es braucht ein Konto und einen gueltigen Token.
  static Future<EventBadgeRight> myRight() async {
    final npub = await SigningService.npub();
    if (npub == null || npub.isEmpty) {
      AppLogger.debug(_tag, 'Keine Identitaet — keine Berechtigung.');
      return EventBadgeRight.none;
    }

    try {
      final admin = await AdminRegistry.checkAdmin(npub);
      if (admin.isAdmin) {
        AppLogger.debug(_tag, 'Berechtigt ueber Admin-Registry.');
        return EventBadgeRight.adminRegistry;
      }
    } catch (e) {
      // Offline oder Relays nicht erreichbar: kein Grund abzubrechen,
      // das Portal kann trotzdem antworten.
      AppLogger.debug(_tag, 'Admin-Registry nicht abfragbar: $e');
    }

    try {
      final meetups = await PortalApiService.getMyMeetups();
      if (meetups.any((m) => m.isLeader)) {
        AppLogger.debug(_tag, 'Berechtigt ueber Portal-Leader.');
        return EventBadgeRight.portalLeader;
      }
    } catch (e) {
      AppLogger.debug(_tag, 'Portal nicht abfragbar: $e');
    }

    AppLogger.debug(_tag, 'Keine Berechtigung gefunden.');
    return EventBadgeRight.none;
  }

  static Future<bool> mayCreate() async =>
      (await myRight()) != EventBadgeRight.none;
}
