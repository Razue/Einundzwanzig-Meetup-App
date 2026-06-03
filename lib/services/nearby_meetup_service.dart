import 'package:geolocator/geolocator.dart';
import '../models/meetup.dart';
import '../models/calendar_event.dart';
import 'meetup_service.dart';
import 'meetup_calendar_service.dart';
import 'app_logger.dart';

/// Ein Meetup mit (optional) zugeordnetem nächsten Termin und Entfernung
/// zum gewählten Suchzentrum.
class NearbyMeetup {
  final Meetup meetup;
  final CalendarEvent? nextEvent; // nächster passender Termin im Zeitfenster
  final List<CalendarEvent> allEvents; // alle passenden Termine
  final double? distanceKm; // Luftlinie vom Suchzentrum (oder null)

  NearbyMeetup({
    required this.meetup,
    this.nextEvent,
    this.allEvents = const [],
    this.distanceKm,
  });

  bool get hasCoords => meetup.lat != 0 || meetup.lng != 0;
}

/// Ergebnis der Standortabfrage.
enum LocationStatus { ok, denied, serviceDisabled, error }

class LocationResult {
  final LocationStatus status;
  final Position? position;
  const LocationResult(this.status, [this.position]);
}

/// Wie der Zeitpunkt eingegrenzt wird.
enum DateMode { any, singleDay, range }

class NearbyMeetupService {
  // Caches, damit beim Verschieben des Reglers nicht neu geladen wird
  static List<Meetup>? _meetupCache;
  static List<CalendarEvent>? _eventCache;

  /// Holt den aktuellen Standort inkl. Permission-Handling.
  static Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.denied);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationResult(LocationStatus.ok, pos);
    } catch (e) {
      AppLogger.debug('Nearby', 'Standortfehler: $e');
      return const LocationResult(LocationStatus.error);
    }
  }

  /// Lädt Meetups + Termine (mit Cache). [forceReload] umgeht den Cache.
  static Future<void> preload({bool forceReload = false}) async {
    if (!forceReload && _meetupCache != null && _eventCache != null) return;

    final meetupsFuture = MeetupService.fetchMeetups();
    final eventsFuture = MeetupCalendarService().fetchMeetups();
    List<Meetup> meetups = await meetupsFuture;
    final events = await eventsFuture;

    if (meetups.isEmpty) meetups = allMeetups; // Offline-Fallback
    _meetupCache = meetups;
    _eventCache = events;
  }

  /// Hauptsuche: Meetups im [radiusKm] um [centerLat]/[centerLng], gefiltert
  /// nach Zeit. Liefert nach Entfernung sortierte Liste.
  static Future<List<NearbyMeetup>> search({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    required DateMode dateMode,
    DateTime? dayFrom,
    DateTime? dayTo,
  }) async {
    await preload();
    final meetups = _meetupCache ?? [];
    final events = _eventCache ?? [];

    final now = DateTime.now();

    final List<NearbyMeetup> out = [];
    for (final m in meetups) {
      if (m.lat == 0 && m.lng == 0) continue;
      final distKm = Geolocator.distanceBetween(
            centerLat,
            centerLng,
            m.lat,
            m.lng,
          ) /
          1000.0;
      if (distKm > radiusKm) continue;

      final matching = _eventsFor(m, events).where((e) {
        switch (dateMode) {
          case DateMode.any:
            return e.startTime.isAfter(now.subtract(const Duration(hours: 12)));
          case DateMode.singleDay:
            return dayFrom != null && _sameDay(e.startTime, dayFrom);
          case DateMode.range:
            if (dayFrom == null || dayTo == null) return false;
            final start = DateTime(dayFrom.year, dayFrom.month, dayFrom.day);
            final end = DateTime(dayTo.year, dayTo.month, dayTo.day, 23, 59, 59);
            return e.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
                e.startTime.isBefore(end.add(const Duration(seconds: 1)));
        }
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      // "any": auch Meetups OHNE Termin zeigen (sind ja in der Nähe).
      // Datums-Modi: nur Meetups MIT passendem Termin.
      if (dateMode != DateMode.any && matching.isEmpty) continue;

      out.add(NearbyMeetup(
        meetup: m,
        nextEvent: matching.isNotEmpty ? matching.first : null,
        allEvents: matching,
        distanceKm: distKm,
      ));
    }

    out.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return out;
  }

  /// Alle Termine, die zu einem Meetup gehören (Ortsname-Match).
  static List<CalendarEvent> _eventsFor(Meetup m, List<CalendarEvent> events) {
    final city = m.city.toLowerCase().trim();
    if (city.isEmpty) return [];
    return events.where((e) {
      final loc = e.location.toLowerCase();
      final title = e.title.toLowerCase();
      return loc.contains(city) ||
          title.contains(city) ||
          (loc.isNotEmpty && city.contains(loc.split(',').first.trim()));
    }).toList();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
