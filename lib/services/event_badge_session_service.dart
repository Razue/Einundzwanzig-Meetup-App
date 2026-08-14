// EVENT-BADGE-SESSION
// ============================================
// Der Weg, auf dem ein HELFER Badges ausgibt — ohne Organisator-Rolle und
// ohne Zugang zum Organisator-Bereich. Seine Berechtigung steht im
// Kalender-Event, nicht in der Admin-Registry.
//
// Vor dem Start werden drei Dinge geprueft, jedes aus einem eigenen Grund:
//
//   1. Bin ich eingetragen?  — sonst koennte jeder fuer jedes Event Badges
//      ausgeben, und der Ersteller haette keine Kontrolle darueber.
//   2. Ist heute der Tag?    — ohne Zeitfenster waere ein einmal angelegtes
//      Event ein Badge-Automat auf Dauer.
//   3. Bin ich vor Ort?      — sonst haette ein eingetragener Helfer in
//      Muenchen Badges fuer ein Frankfurter Event verteilen koennen.
//
// Der QR selbst wird lokal erzeugt und mit dem EIGENEN Schluessel des
// Helfers signiert. Es gibt nichts zu uebergeben und nichts geheim zu
// halten — die Ausstellerliste im Event macht seine Signatur gueltig.
// ============================================

import 'app_logger.dart';
import 'badge_security.dart';
import 'calendar_event_service.dart';
import 'meetup_location_service.dart';
import 'rolling_qr_service.dart';
import 'signing_service.dart';

const String _tag = 'EventSession';

/// Warum eine Session nicht starten darf.
enum EventSessionError {
  noIdentity,
  notIssuer,
  outsideWindow,
  noEventLocation,
  locationUnavailable,
  tooFarAway,
  sessionFailed,
}

class EventSessionResult {
  final MeetupSession? session;
  final EventSessionError? error;

  /// Entfernung zum Veranstaltungsort in km — nur bei [tooFarAway] gesetzt,
  /// damit die Meldung sagen kann, WIE weit es war.
  final double? distanceKm;

  const EventSessionResult.success(this.session)
      : error = null,
        distanceKm = null;
  const EventSessionResult.failure(this.error, {this.distanceKm})
      : session = null;

  bool get ok => session != null;
}

class EventBadgeSessionService {
  EventBadgeSessionService._();

  /// Wie nah der Aussteller am Veranstaltungsort sein muss.
  ///
  /// 5 km — anders als bei Meetups, wo 50 km gelten. Dort stammen die
  /// Koordinaten aus der Portal-Liste und zeigen bei Regionen wie
  /// "Westerwald" auf einen groben Mittelpunkt. Hier hat der Ersteller den
  /// Punkt selbst auf der Karte gesetzt, der darf also genau sein.
  static const double issuerRadiusKm = 5.0;

  /// Prueft alles und legt die Session an.
  static Future<EventSessionResult> start(NostrCalendarEvent event) async {
    final myPubkey = await SigningService.pubkeyHex();
    if (myPubkey == null || myPubkey.isEmpty) {
      return const EventSessionResult.failure(EventSessionError.noIdentity);
    }

    if (!event.isIssuer(myPubkey)) {
      AppLogger.warn(_tag, 'Nicht als Aussteller eingetragen.');
      return const EventSessionResult.failure(EventSessionError.notIssuer);
    }

    if (!event.isBadgeWindowOpen) {
      AppLogger.debug(_tag, 'Ausserhalb des Zeitfensters (${event.start}).');
      return const EventSessionResult.failure(EventSessionError.outsideWindow);
    }

    if (event.lat == 0 && event.lng == 0) {
      return const EventSessionResult.failure(
          EventSessionError.noEventLocation);
    }

    final loc = await MeetupLocationService.resolveLocation();
    if (loc.lat == 0 && loc.lng == 0) {
      return const EventSessionResult.failure(
          EventSessionError.locationUnavailable);
    }

    final distance = MeetupLocationService.distanceKm(
        loc.lat, loc.lng, event.lat, event.lng);
    if (distance > issuerRadiusKm) {
      AppLogger.warn(_tag,
          'Zu weit weg: ${distance.toStringAsFixed(1)} km (erlaubt $issuerRadiusKm).');
      return EventSessionResult.failure(EventSessionError.tooFarAway,
          distanceKm: distance);
    }

    try {
      final session = await RollingQRService.getOrCreateSession(
        // Die Event-Adresse steckt im meetupId und wandert damit in den
        // signierten Payload — daran haengt spaeter die Pruefkette.
        meetupId: BadgeSecurity.eventMeetupId(
          eventAddress: event.address,
          title: event.title,
        ),
        meetupName: event.title,
        meetupCountry: '',
        blockHeight: 0,
        // Der EVENT-Ort, nicht der gemessene: Teilnehmer sollen am
        // Veranstaltungsort gemessen werden, nicht an dem Punkt, an dem der
        // Helfer zufaellig stand, als er die Session startete.
        lat: event.lat,
        lng: event.lng,
      );
      if (session == null) {
        return const EventSessionResult.failure(
            EventSessionError.sessionFailed);
      }
      AppLogger.debug(_tag,
          'Session fuer "${event.title}" gestartet, ${distance.toStringAsFixed(2)} km entfernt.');
      return EventSessionResult.success(session);
    } catch (e) {
      AppLogger.warn(_tag, 'Session konnte nicht erstellt werden', e);
      return const EventSessionResult.failure(EventSessionError.sessionFailed);
    }
  }
}
