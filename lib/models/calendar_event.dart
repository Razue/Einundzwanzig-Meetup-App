import 'package:icalendar_parser/icalendar_parser.dart';
import '../services/app_logger.dart';

class CalendarEvent {
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final String url;

  CalendarEvent({
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.url,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    // Standard-Fallback (falls alles schiefgeht): Datum in der Zukunft
    DateTime start = DateTime.now().add(const Duration(days: 365));

    try {
      final dtStart = map['dtstart'];

      // ZEITZONEN-REGEL (Fix: App zeigte 16:30 statt 18:30, exakt -2h MESZ):
      // Endet der ICS-Rohwert auf 'Z', ist es UTC -> in Geraetezeit
      // umrechnen. Ohne 'Z' (floating/TZID) ist es bereits lokale Zeit.
      // WICHTIG: dtStart.toDateTime() des icalendar_parser-Pakets liefert
      // UTC-Zeiten als NAIVES DateTime ohne isUtc-Flag — dessen .toLocal()
      // war ein No-op und die 2 Stunden Sommerzeit fehlten still. Deshalb
      // wird jetzt IMMER der ROHE String zeitzonenbewusst geparst. Ueber den
      // RecurrenceExpander erben ALLE Serien-Vorkommen diese Startzeit.
      String raw = '';
      if (dtStart is IcsDateTime) {
        raw = dtStart.dt;
      } else if (dtStart is String) {
        raw = dtStart;
      }

      if (raw.isNotEmpty) {
        final isUtc = raw.trim().endsWith('Z') || raw.trim().endsWith('z');
        final s = raw.replaceAll(RegExp(r'[^0-9]'), '');
        if (s.length >= 8) {
          int y = int.parse(s.substring(0, 4));
          int m = int.parse(s.substring(4, 6));
          int d = int.parse(s.substring(6, 8));
          int h = 19; // Fallback, falls keine Uhrzeit dabei ist
          int min = 0;
          if (s.length >= 12) {
            h = int.parse(s.substring(8, 10));
            min = int.parse(s.substring(10, 12));
          }
          start = isUtc
              ? DateTime.utc(y, m, d, h, min).toLocal() // UTC -> Geraetezeit
              : DateTime(y, m, d, h, min);              // schon lokale Zeit
        }
      }
    } catch (e) {
      AppLogger.debug('App', "PARSE ERROR: $e");
    }

    // Beschreibung säubern (Zeilenumbrüche fixen)
    String rawDesc = map['description']?.toString() ?? '';
    String cleanDesc = rawDesc
        .replaceAll('\\n', '\n')
        .replaceAll('\\', '')
        .replaceAll('\,', ',');

    return CalendarEvent(
      title: map['summary']?.toString() ?? 'Meetup',
      description: cleanDesc,
      location: map['location']?.toString() ?? 'Ort unbekannt',
      startTime: start,
      url: '',
    );
  }
}