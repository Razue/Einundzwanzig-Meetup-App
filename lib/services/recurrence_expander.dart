import '../models/calendar_event.dart';

/// Expandiert wiederkehrende Kalender-Termine (iCal RRULE) in einzelne
/// Vorkommen. Bewusst konservativ: deckt die häufigsten Meetup-Muster ab
/// (WEEKLY / MONTHLY, mit INTERVAL, BYDAY, COUNT, UNTIL). Bei unbekannten
/// oder fehlerhaften Regeln wird NUR das Basis-Event behalten (kein Verlust).
class RecurrenceExpander {
  /// Wie weit in die Zukunft expandiert wird (passend zum Datepicker-Limit).
  static const int horizonDays = 366;

  /// Sicherheits-Obergrenze gegen Endlosschleifen.
  static const int maxOccurrences = 200;

  static const Map<String, int> _weekdayMap = {
    'MO': DateTime.monday,
    'TU': DateTime.tuesday,
    'WE': DateTime.wednesday,
    'TH': DateTime.thursday,
    'FR': DateTime.friday,
    'SA': DateTime.saturday,
    'SU': DateTime.sunday,
  };

  /// Gibt alle Vorkommen eines Events zurück. Ohne gültige RRULE: [base].
  static List<CalendarEvent> expand(CalendarEvent base, String? rrule) {
    if (rrule == null || rrule.trim().isEmpty) return [base];

    try {
      final rule = _parseRule(rrule);
      final freq = rule['FREQ'];
      if (freq != 'WEEKLY' && freq != 'MONTHLY') return [base];

      final intervalRaw = int.tryParse(rule['INTERVAL'] ?? '1') ?? 1;
      // Absicherung: INTERVAL <= 0 ist ungültig und würde zu Division-by-Zero
      // (weekly) bzw. Endlosschleife (monthly) führen. Auf 1 klemmen.
      final interval = intervalRaw < 1 ? 1 : intervalRaw;
      final count = int.tryParse(rule['COUNT'] ?? '');
      final until = _parseUntil(rule['UNTIL']);
      final horizon = DateTime.now().add(const Duration(days: horizonDays));
      final limit = until != null && until.isBefore(horizon) ? until : horizon;

      final results = <CalendarEvent>[base];

      if (freq == 'WEEKLY') {
        _expandWeekly(base, interval, rule['BYDAY'], count, limit, results);
      } else {
        _expandMonthly(base, interval, rule['BYDAY'], count, limit, results);
      }

      // Nach Datum sortieren, auf Obergrenze begrenzen
      results.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (results.length > maxOccurrences) {
        return results.sublist(0, maxOccurrences);
      }
      return results;
    } catch (_) {
      return [base]; // Bei jedem Fehler: nur das Basis-Event
    }
  }

  static Map<String, String> _parseRule(String rrule) {
    final map = <String, String>{};
    // evtl. "RRULE:" Präfix entfernen
    final clean = rrule.replaceFirst(RegExp(r'^RRULE:', caseSensitive: false), '');
    for (final part in clean.split(';')) {
      final kv = part.split('=');
      if (kv.length == 2) map[kv[0].toUpperCase().trim()] = kv[1].trim();
    }
    return map;
  }

  static DateTime? _parseUntil(String? until) {
    if (until == null) return null;
    final s = until.replaceAll(RegExp(r'[^0-9]'), '');
    if (s.length < 8) return null;
    try {
      return DateTime.utc(
        int.parse(s.substring(0, 4)),
        int.parse(s.substring(4, 6)),
        int.parse(s.substring(6, 8)),
        23, 59, 59,
      ).toLocal();
    } catch (_) {
      return null;
    }
  }

  static CalendarEvent _cloneAt(CalendarEvent base, DateTime newStart) {
    return CalendarEvent(
      title: base.title,
      description: base.description,
      location: base.location,
      startTime: newStart,
      url: base.url,
    );
  }

  static void _expandWeekly(CalendarEvent base, int interval, String? byDay,
      int? count, DateTime limit, List<CalendarEvent> out) {
    final start = base.startTime;
    // Wochentage bestimmen (BYDAY oder der Wochentag des Start-Events)
    final weekdays = <int>{};
    if (byDay != null && byDay.isNotEmpty) {
      for (final d in byDay.split(',')) {
        final wd = _weekdayMap[d.trim().toUpperCase()];
        if (wd != null) weekdays.add(wd);
      }
    }
    if (weekdays.isEmpty) weekdays.add(start.weekday);

    int produced = 1; // base zählt
    // Beginn der Woche des Start-Events (Montag als Wochenstart)
    DateTime weekStart = DateTime(start.year, start.month, start.day)
        .subtract(Duration(days: start.weekday - 1));
    int weekIndex = 0;

    while (true) {
      // nur jede `interval`-te Woche
      if (weekIndex % interval == 0) {
        for (final wd in weekdays) {
          final occ = weekStart.add(Duration(days: wd - 1, hours: start.hour, minutes: start.minute));
          if (occ.isAfter(start) && !occ.isAfter(limit)) {
            out.add(_cloneAt(base, occ));
            produced++;
            if (count != null && produced >= count) return;
          }
        }
      }
      weekStart = weekStart.add(const Duration(days: 7));
      weekIndex++;
      if (weekStart.isAfter(limit)) return;
      if (produced >= maxOccurrences) return;
    }
  }

  static void _expandMonthly(CalendarEvent base, int interval, String? byDay,
      int? count, DateTime limit, List<CalendarEvent> out) {
    final start = base.startTime;
    int produced = 1;

    // BYDAY der Form "2TU" (2. Dienstag) oder schlicht Tag-des-Monats
    int? ordinal; // z.B. 2 = zweiter, -1 = letzter
    int? weekday;
    if (byDay != null && byDay.isNotEmpty) {
      final match = RegExp(r'^(-?\d+)?(MO|TU|WE|TH|FR|SA|SU)$')
          .firstMatch(byDay.trim().toUpperCase());
      if (match != null) {
        ordinal = match.group(1) != null ? int.tryParse(match.group(1)!) : null;
        weekday = _weekdayMap[match.group(2)];
      }
    }

    int monthIndex = interval;
    int safety = 0;
    while (true) {
      // Harte Obergrenze (Gürtel & Hosenträger): nie mehr als ~10 Jahre
      // an Monaten durchlaufen, egal was passiert.
      if (++safety > 120) return;
      final base0 = DateTime(start.year, start.month + monthIndex, 1);
      if (base0.isAfter(limit)) return;

      DateTime? occ;
      if (weekday != null && ordinal != null) {
        occ = _nthWeekdayOfMonth(base0.year, base0.month, weekday, ordinal,
            start.hour, start.minute);
      } else {
        // Gleicher Tag-des-Monats wie das Start-Event
        final day = start.day;
        final lastDay = DateTime(base0.year, base0.month + 1, 0).day;
        if (day <= lastDay) {
          occ = DateTime(base0.year, base0.month, day, start.hour, start.minute);
        }
      }

      if (occ != null && occ.isAfter(start) && !occ.isAfter(limit)) {
        out.add(_cloneAt(base, occ));
        produced++;
        if (count != null && produced >= count) return;
      }

      monthIndex += interval;
      if (produced >= maxOccurrences) return;
    }
  }

  /// n-ter Wochentag eines Monats (ordinal -1 = letzter).
  static DateTime? _nthWeekdayOfMonth(
      int year, int month, int weekday, int ordinal, int hour, int minute) {
    if (ordinal > 0) {
      final first = DateTime(year, month, 1);
      int offset = (weekday - first.weekday) % 7;
      if (offset < 0) offset += 7;
      final day = 1 + offset + (ordinal - 1) * 7;
      final lastDay = DateTime(year, month + 1, 0).day;
      if (day > lastDay) return null;
      return DateTime(year, month, day, hour, minute);
    } else if (ordinal == -1) {
      final lastDay = DateTime(year, month + 1, 0).day;
      final last = DateTime(year, month, lastDay);
      int offset = (last.weekday - weekday) % 7;
      if (offset < 0) offset += 7;
      return DateTime(year, month, lastDay - offset, hour, minute);
    }
    return null;
  }
}
