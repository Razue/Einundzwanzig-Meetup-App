import 'package:flutter/foundation.dart' show visibleForTesting;

import 'app_logger.dart';
import 'meetup_calendar_service.dart';
import 'meetup_key.dart';
import 'meetup_service.dart';

/// Wappen zu einem Badge: ueber die Stadt in der Meetup-Liste, danach exakt
/// in der Termin-Registry. Am Badge-Format aendert sich dafuer nichts, die
/// Freitags-Badges tragen die Stadt schon.
class MeetupCrestLookup {
  MeetupCrestLookup._();

  /// Laeuft gerade ein Nachladen der Wappen-Quellen? Eine Zukunft fuer alle
  /// Karten, sonst fragt jede Badge-Karte die Listen selbst ab.
  static Future<void>? _sources;

  static final List<void Function()> _listeners = [];

  /// Ersetzt den Listen-Abruf in Tests. null: der echte Portal-Abruf.
  @visibleForTesting
  static Future<void> Function()? debugFetchList;

  /// Ersetzt den Termin-Abruf in Tests. null: der echte Kalender-Abruf.
  @visibleForTesting
  static Future<void> Function()? debugFetchCalendar;

  /// Karten, die ein Wappen zeichnen, sobald die Meetup-Liste da ist.
  /// Der Kalender darf danach noch laufen.
  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  @visibleForTesting
  static void debugReset() {
    _sources = null;
    debugFetchList = null;
    debugFetchCalendar = null;
    _listeners.clear();
  }

  static void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  /// Termine (Name und Stadt -> Logo) und die Meetup-Liste. Die Liste kennt
  /// auch Gruppen ohne Termin in den naechsten zwei Monaten; die Termin-Registry
  /// allein wuerde deren Wappen auslassen.
  static Future<void> ensureSources() {
    if (MeetupService.cached.isNotEmpty &&
        MeetupCalendarService.portalLogos.isNotEmpty) {
      return Future<void>.value();
    }
    // Nach dem Lauf vergessen: Schlug er offline fehl, darf die naechste
    // Karte es wieder versuchen, statt bis zum Neustart ohne Wappen zu bleiben.
    return _sources ??= _load().whenComplete(() => _sources = null);
  }

  /// Liste und Kalender parallel. Sobald die Liste da ist, duerfen die
  /// Karten zeichnen. Der Kalender ist nur der Rueckfall fuer Meetups, die
  /// die Liste nicht kennt, und darf die schon bekannten Wappen nicht
  /// zurueckhalten.
  static Future<void> _load() async {
    final list = MeetupService.cached.isEmpty
        ? () async {
            try {
              final fetch = debugFetchList ?? () async {
                await MeetupService.fetchMeetups();
              };
              await fetch();
            } catch (e) {
              AppLogger.debug('Crest', 'Meetup-Liste nicht geladen: $e');
            }
          }()
        : null;
    final calendar = MeetupCalendarService.portalLogos.isEmpty
        ? () async {
            try {
              final fetch = debugFetchCalendar ?? () async {
                await MeetupCalendarService().fetchMeetupsPortalFirst();
              };
              await fetch();
            } catch (e) {
              AppLogger.debug('Crest', 'Termin-Registry nicht geladen: $e');
            }
          }()
        : null;
    if (list != null) {
      await list;
      _notify();
    }
    if (calendar != null) await calendar;
  }

  /// Wappen zu einem Badge-Namen der Form "Stadt, LAND".
  ///
  /// Zuerst die Meetup-Liste ueber den Stadt-Slug und das Land.
  /// "Ostwestfalen-Lippe" und "Einundzwanzig OWL" teilen keine Zeichenfolge,
  /// der Slug der Stadt findet die Gruppe trotzdem. Kennt die Liste das
  /// Meetup, gilt die Liste: ohne Logo kein Wappen, kein Suchen nach dem
  /// Wappen einer anderen Gruppe. Nur ein Meetup, das die Liste nicht kennt,
  /// wird in der Termin-Registry unter der Stadt nachgeschlagen, exakt.
  /// Mehrere Gruppen in einer Stadt kann das Badge nicht unterscheiden; es
  /// gilt die erste in der Liste.
  static String urlFor(String meetupName) {
    final city = meetupName.split(',').first.trim();
    if (city.isEmpty) return '';
    final country = meetupName.contains(',')
        ? meetupName.split(',').sublist(1).join(',').trim()
        : '';
    final listed = MeetupService.bySlug(MeetupKey.slug(city), country);
    if (listed != null) {
      return MeetupCalendarService.absoluteImageUrl(listed.logoUrl);
    }
    // Termin-Registry. Steht ein Land am Badge, zaehlt nur der Schluessel
    // "Stadt, LAND". Den legt das Termin-Laden aus meetup.country ab.
    // Der blosse Stadtname beweist das Land nicht: "Weiden" waere sonst das
    // deutsche Wappen fuer ein oesterreichisches Badge, sobald die
    // Meetup-Liste fehlt. Ohne Land am Badge (alte Badges) bleibt die Stadt.
    if (country.isNotEmpty) {
      return MeetupCalendarService.logoFor('$city, ${country.toUpperCase()}');
    }
    return MeetupCalendarService.logoFor(city);
  }
}
