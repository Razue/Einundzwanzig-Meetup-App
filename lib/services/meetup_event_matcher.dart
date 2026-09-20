import '../models/calendar_event.dart';
import '../models/meetup.dart';

/// Shared, conservative event ownership for home, calendar and RSVPs.
class MeetupEventMatcher {
  static String portalIdentity(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.toLowerCase() != 'portal.einundzwanzig.space') {
      return '';
    }
    final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    final index = parts.indexOf('meetup');
    if (index < 0 || index != parts.length - 2) return '';
    return parts.last;
  }

  static Meetup? resolve(CalendarEvent event, List<Meetup> meetups) {
    Meetup? unique(Iterable<Meetup> matches) {
      final list = matches.toList();
      return list.length == 1 ? list.single : null;
    }

    // An explicit identity must never fall through to a different meetup.
    if (event.meetupId.isNotEmpty) {
      return unique(meetups.where((m) => m.id == event.meetupId));
    }
    if (event.meetupPortalLink.isNotEmpty) {
      final identity = portalIdentity(event.meetupPortalLink);
      if (identity.isEmpty) return null;
      return unique(
        meetups.where((m) => portalIdentity(m.portalLink) == identity),
      );
    }

    final named = meetups
        .where(
          (m) =>
              m.name.trim().isNotEmpty &&
              m.name.trim().toLowerCase() == event.title.trim().toLowerCase(),
        )
        .toList();
    if (named.isNotEmpty) return unique(named);
    // Legacy/ICS events have no identity. Only accept an unambiguous city.
    return unique(meetups.where((m) => matchesCity(event, m.city)));
  }

  static bool matchesCity(CalendarEvent event, String city) {
    if (event.meetupId.isNotEmpty || event.meetupPortalLink.isNotEmpty) {
      return false;
    }
    final term = city.trim().toLowerCase();
    if (term.length < 3 ||
        {'bitcoin', 'meetup', 'einundzwanzig', 'stammtisch'}.contains(term)) {
      return false;
    }
    final hay = '${event.title} ${event.location}'.toLowerCase();
    return RegExp(
      '(^|[^\\p{L}\\p{N}])${RegExp.escape(term)}'
      r'($|[^\p{L}\p{N}])',
      unicode: true,
    ).hasMatch(hay);
  }
}
