import 'package:geolocator/geolocator.dart';
import '../models/meetup.dart';
import 'meetup_service.dart';
import 'nearby_meetup_service.dart';

/// Status der Standort-Ermittlung beim Erstellen/Scannen.
enum GpsStatus { ok, denied, serviceDisabled, error }

/// Ein Meetup-Kandidat mit Entfernung zum aktuellen Standort.
class MeetupCandidate {
  final Meetup meetup;
  final double distanceKm;
  MeetupCandidate(this.meetup, this.distanceKm);
}

/// Ergebnis der Standort-basierten Meetup-Zuordnung.
class LocationMeetupResult {
  final GpsStatus status;
  final double lat;
  final double lng;
  final List<MeetupCandidate> candidates; // nach Entfernung sortiert (nächstes zuerst)

  LocationMeetupResult({
    required this.status,
    this.lat = 0,
    this.lng = 0,
    this.candidates = const [],
  });

  MeetupCandidate? get nearest => candidates.isNotEmpty ? candidates.first : null;

  /// Meetups innerhalb des Erstellungs-Radius (10km) um den Standort.
  List<MeetupCandidate> get withinCreationRadius =>
      candidates.where((c) => c.distanceKm <= MeetupLocationService.creationRadiusKm).toList();

  /// Mehrere Meetups sehr nah beieinander? (Nutzer sollte gefragt werden)
  bool get isAmbiguous {
    if (candidates.length < 2) return false;
    return (candidates[1].distanceKm - candidates[0].distanceKm).abs() < ambiguityThresholdKm;
  }

  static const double ambiguityThresholdKm = 2.0; // < 2km Differenz = mehrdeutig
}

/// Ermittelt anhand des GPS-Standorts, welches Meetup am nächsten ist.
class MeetupLocationService {
  /// Maximale Entfernung Teilnehmer <-> Organisator-Standort.
  static const double participantRadiusKm = 5.0;

  /// Radius beim Erstellen: welche Meetups gelten als "hier in der Nähe".
  static const double creationRadiusKm = 10.0;

  /// Holt den aktuellen Standort und ordnet die nächstgelegenen Meetups zu.
  static Future<LocationMeetupResult> resolveLocation() async {
    final loc = await NearbyMeetupService.getCurrentLocation();
    if (loc.status != LocationStatus.ok || loc.position == null) {
      return LocationMeetupResult(status: _mapStatus(loc.status));
    }
    final pos = loc.position!;

    List<Meetup> meetups;
    try {
      meetups = await MeetupService.fetchMeetups();
    } catch (_) {
      meetups = const [];
    }

    final candidates = <MeetupCandidate>[];
    for (final m in meetups) {
      if (m.lat == 0 && m.lng == 0) continue;
      final distM = Geolocator.distanceBetween(pos.latitude, pos.longitude, m.lat, m.lng);
      candidates.add(MeetupCandidate(m, distM / 1000.0));
    }
    candidates.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return LocationMeetupResult(
      status: GpsStatus.ok,
      lat: pos.latitude,
      lng: pos.longitude,
      candidates: candidates,
    );
  }

  /// Prüft, ob ein Teilnehmer-Standort nah genug am Badge-Ort liegt.
  /// Gibt die Entfernung in km zurück (auch wenn außerhalb).
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000.0;
  }

  static bool isWithinParticipantRadius(double lat1, double lng1, double lat2, double lng2) {
    if ((lat2 == 0 && lng2 == 0)) return true; // Badge ohne Org-Koordinaten -> kein Check möglich
    return distanceKm(lat1, lng1, lat2, lng2) <= participantRadiusKm;
  }

  static GpsStatus _mapStatus(LocationStatus s) {
    switch (s) {
      case LocationStatus.denied: return GpsStatus.denied;
      case LocationStatus.serviceDisabled: return GpsStatus.serviceDisabled;
      case LocationStatus.error: return GpsStatus.error;
      case LocationStatus.ok: return GpsStatus.ok;
    }
  }
}
