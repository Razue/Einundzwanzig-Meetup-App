import 'package:einundzwanzig_meetup_app/models/calendar_event.dart';
import 'package:einundzwanzig_meetup_app/models/meetup.dart';
import 'package:einundzwanzig_meetup_app/services/meetup_event_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

Meetup group(String id, String name, String city, String slug) => Meetup(
  id: id,
  name: name,
  city: city,
  country: 'DE',
  telegramLink: '',
  lat: 0,
  lng: 0,
  portalLink: 'https://portal.einundzwanzig.space/de/meetup/$slug',
);

CalendarEvent event({
  String id = '',
  String link = '',
  String title = 'Einundzwanzig Südniedersachsen',
  String location = 'Dinx Diner',
}) => CalendarEvent(
  title: title,
  location: location,
  description: '',
  startTime: DateTime(2026, 10, 9),
  url: 'https://example.com/event',
  meetupId: id,
  meetupPortalLink: link,
);

void main() {
  final south = group(
    '107',
    'Einundzwanzig Südniedersachsen',
    'Göttingen',
    'einundzwanzig-suedniedersachsen',
  );
  final saxony = group(
    '32',
    'Einundzwanzig Sachsen',
    'Sachsen',
    'einundzwanzig-sachsen',
  );
  final groups = [saxony, south];

  test(
    'issue 53: portal link identifies meetup despite different venue/city',
    () {
      final e = event(link: south.portalLink);
      expect(MeetupEventMatcher.resolve(e, groups)?.id, '107');
      expect(MeetupEventMatcher.matchesCity(e, 'Sachsen'), isFalse);
    },
  );
  test('portal identity tolerates locale, query and trailing slash', () {
    expect(
      MeetupEventMatcher.resolve(
        event(
          link:
              '${south.portalLink.replaceFirst('/de/', '/en/')}/?source=calendar',
        ),
        groups,
      )?.id,
      '107',
    );
  });
  test('explicit different or unknown ID cannot fall back to name or link', () {
    expect(
      MeetupEventMatcher.resolve(
        event(id: '32', link: south.portalLink),
        groups,
      )?.id,
      '32',
    );
    expect(
      MeetupEventMatcher.resolve(
        event(id: 'unknown', link: south.portalLink),
        groups,
      ),
      isNull,
    );
  });
  test('unknown or foreign portal link cannot fall back to title', () {
    expect(
      MeetupEventMatcher.resolve(
        event(link: '${south.portalLink}-unknown'),
        groups,
      ),
      isNull,
    );
    expect(
      MeetupEventMatcher.resolve(
        event(
          link: 'https://example.com/de/meetup/einundzwanzig-suedniedersachsen',
        ),
        groups,
      ),
      isNull,
    );
  });
  test('legacy exact group name works; Sachsen is not a substring match', () {
    expect(MeetupEventMatcher.resolve(event(), groups)?.id, '107');
    expect(MeetupEventMatcher.matchesCity(event(), 'Sachsen'), isFalse);
    expect(
      MeetupEventMatcher.matchesCity(
        event(title: 'Treffen in Sachsen'),
        'Sachsen',
      ),
      isTrue,
    );
    expect(
      MeetupEventMatcher.matchesCity(
        event(title: 'Frankfurter Straße'),
        'Frankfurt',
      ),
      isFalse,
    );
  });
  test('same-city meetups require an unambiguous identity', () {
    final a = group('1', 'BitcoinWalk Würzburg', 'Würzburg', 'walk-wuerzburg');
    final b = group('2', 'Würzburg Meetup', 'Würzburg', 'wuerzburg-meetup');
    expect(
      MeetupEventMatcher.resolve(event(link: b.portalLink), [a, b])?.id,
      '2',
    );
    expect(
      MeetupEventMatcher.resolve(event(title: 'Treffen Würzburg'), [a, b]),
      isNull,
    );
  });
  test('legacy city matches Unicode boundaries and not description', () {
    final munich = group('3', 'Bitcoin München', 'München', 'muenchen');
    expect(
      MeetupEventMatcher.resolve(event(title: 'Treffen in München'), [
        munich,
      ])?.id,
      '3',
    );
    expect(
      MeetupEventMatcher.matchesCity(event(title: 'ÜSachsen'), 'Sachsen'),
      isFalse,
    );
  });
}
