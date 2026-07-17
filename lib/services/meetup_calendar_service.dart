import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import '../models/calendar_event.dart'; // Importiere das neue Modell
import 'recurrence_expander.dart';
import 'portal_api_service.dart';
import 'app_logger.dart';

class MeetupCalendarService {
  static bool _loggedStartFormat = false;

  /// Zeitzonensicheres Parsen der Portal-'start'-Angabe.
  /// Ohne Zone ("2026-07-21 18:00") -> ist bereits lokale Portal-Zeit.
  /// Mit 'Z'/Offset -> als UTC parsen und in Geraetezeit umrechnen.
  /// Loggt einmal pro Session Rohformat UND Ergebnis ins Diagnose-Log.
  static DateTime? portalStart(String rawIn) {
    final s = rawIn.trim();
    if (s.isEmpty) return null;
    final logThis = !_loggedStartFormat;
    _loggedStartFormat = true;
    final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    final result = hasZone ? dt.toLocal() : dt;
    if (logThis) {
      AppLogger.diag('Portal',
          'start-Rohformat "$s" -> angezeigt ${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')} (Zone erkannt: $hasZone)');
    }
    return result;
  }

  static bool _loggedUtcFormat = false;

  /// Fuer Endpunkte, die die ROHE Datenbank-Zeit liefern (z.B.
  /// /my-meetup-events im Organisator-Bereich): Laravel speichert UTC,
  /// dieser Endpunkt gibt sie OHNE Zonenkennung heraus ("2026-07-21 16:00"
  /// = 16:00 UTC = 18:00 MESZ). Deshalb hier: ohne Kennung -> als UTC
  /// interpretieren und in Geraetezeit umrechnen. Mit Z/Offset -> normal.
  /// (Gegenstueck: /meetup-events/{datum} liefert bereits Berlin-Zeit ->
  /// dafuer gilt portalStart, NICHT diese Funktion.)
  static DateTime? portalStartUtc(String rawIn) {
    final s = rawIn.trim();
    if (s.isEmpty) return null;
    if (!_loggedUtcFormat) {
      _loggedUtcFormat = true;
      AppLogger.diag('Portal', 'my-meetup-events Rohformat: "' + s + '"');
    }
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    if (dt.isUtc) return dt.toLocal(); // hatte Z/Offset
    return DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
        .toLocal();
  }

  /// WAPPEN-REGISTRY: Meetup-Name -> Logo-URL, gefüllt beim Portal-Laden.
  /// So können Home-Kachel & Co. das Wappen zum Termin/Meetup finden.
  static final Map<String, String> portalLogos = {};

  /// Liefert das Wappen zu einem Titel/Stadtnamen (exakter Name oder enthalten).
  static String logoFor(String titleOrCity) {
    final q = titleOrCity.trim().toLowerCase();
    if (q.isEmpty) return '';
    for (final entry in portalLogos.entries) {
      final name = entry.key.toLowerCase();
      if (name == q || name.contains(q) || q.contains(name)) return entry.value;
    }
    return '';
  }

  /// ZENTRALE QUELLE für Meetup-Termine (Anzeige): PORTAL ZUERST
  /// (/api/meetup-events — exakte Meetup-Namen, saubere Daten),
  /// Fallback iCal-Feed. Alle Screens sollen DIESE Methode nutzen,
  /// damit überall dasselbe, konsistente Bild entsteht.
  Future<List<CalendarEvent>> fetchMeetupsPortalFirst() async {
    try {
      final portal = await PortalApiService.getAllMeetupEvents();
      final cutoff = DateTime.now().subtract(const Duration(hours: 6));
      final events = <CalendarEvent>[];
      for (final e in portal) {
        final start = portalStart((e['start'] ?? '').toString());
        if (start == null || start.isBefore(cutoff)) continue;
        // WICHTIG: Die API liefert die Meetup-Felder FLACH mit Punkt-
        // Schlüsseln ("meetup.name", "meetup.logo") — nicht verschachtelt!
        String mv(String key) {
          final nested = e['meetup'];
          if (nested is Map && nested[key] != null) return nested[key].toString();
          final flat = e['meetup.$key'];
          return flat == null ? '' : flat.toString();
        }
        final name = mv('name').trim().isNotEmpty ? mv('name').trim() : 'Meetup';
        final logo = mv('logo');
        if (logo.isNotEmpty) portalLogos[name] = logo;
        final link = (e['link'] ?? '').toString();
        events.add(CalendarEvent(
          title: name,
          description: (e['description'] ?? '').toString(),
          location: (e['location'] ?? '').toString(),
          startTime: start,
          url: link.isNotEmpty ? link : mv('portalLink'),
        ));
      }
      if (events.isNotEmpty) {
        events.sort((a, b) => a.startTime.compareTo(b.startTime));
        return events;
      }
    } catch (e) {
      AppLogger.debug('Calendar', 'Portal-Termine fehlgeschlagen, iCal-Fallback: $e');
    }
    return fetchMeetups(); // iCal-Fallback
  }

  static const String calendarUrl = 'https://portal.einundzwanzig.space/stream-calendar';

  Future<List<CalendarEvent>> fetchMeetups() async {
    try {
      final response = await http.get(Uri.parse(calendarUrl));

      if (response.statusCode == 200) {
        final iCalString = utf8.decode(response.bodyBytes);
        final iCalendar = ICalendar.fromString(iCalString);
        
        List<CalendarEvent> events = [];
        
        if (iCalendar.data != null) {
          for (var item in iCalendar.data) {
            if (item['type'] == 'VEVENT') {
              // Basis-Event parsen
              final base = CalendarEvent.fromMap(item);
              // Wiederkehrende Termine (RRULE) in einzelne Vorkommen expandieren.
              // Ohne RRULE liefert expand() einfach nur [base].
              final rrule = item['rrule']?.toString();
              events.addAll(RecurrenceExpander.expand(base, rrule));
            }
          }
        }
        
        // Sortieren: Nächste Termine zuerst
        events.sort((a, b) => a.startTime.compareTo(b.startTime));

        // Nur Termine in der Zukunft anzeigen (optional)
        // events = events.where((e) => e.startTime.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();

        return events;
      } else {
        throw Exception('Server Fehler: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug('App', "Fehler im CalendarService: $e");
      return [];
    }
  }
}


