import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import '../models/calendar_event.dart'; // Importiere das neue Modell
import 'recurrence_expander.dart';
import 'portal_api_service.dart';
import 'app_logger.dart';

class MeetupCalendarService {
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
        final start = DateTime.tryParse((e['start'] ?? '').toString())?.toLocal();
        if (start == null || start.isBefore(cutoff)) continue;
        final meetup = (e['meetup'] is Map) ? e['meetup'] as Map : const {};
        events.add(CalendarEvent(
          title: (meetup['name'] ?? 'Meetup').toString(),
          description: (e['description'] ?? '').toString(),
          location: (e['location'] ?? '').toString(),
          startTime: start,
          url: (e['link'] ?? meetup['portal'] ?? '').toString(),
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


