import 'dart:convert';
import 'dart:io';

import 'package:einundzwanzig_meetup_app/services/meetup_calendar_service.dart';
import 'package:einundzwanzig_meetup_app/services/meetup_event_matcher.dart';
import 'package:einundzwanzig_meetup_app/services/meetup_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('portal ingestion retains meetup link separately from event URL', () async {
    const portalLink =
        'https://portal.einundzwanzig.space/de/meetup/einundzwanzig-suedniedersachsen';
    final start = DateTime.now().toUtc().add(const Duration(days: 10));
    final client = MockClient((request) async {
      if (request.url.path == '/api/mobile/meetups') {
        return http.Response(
          jsonEncode([
            {
              'id': 107,
              'name': 'Einundzwanzig Südniedersachsen',
              'city': 'Göttingen',
              'slug': 'einundzwanzig-suedniedersachsen',
            },
            {
              'id': 32,
              'name': 'Einundzwanzig Sachsen',
              'city': 'Sachsen',
              'portalLink':
                  'https://portal.einundzwanzig.space/de/meetup/einundzwanzig-sachsen',
            },
          ]),
          200,
        );
      }
      expect(request.url.path, startsWith('/api/meetup-events/'));
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 3869,
              'start': start.toIso8601String(),
              'meetup.name': 'Einundzwanzig Südniedersachsen',
              'meetup.portalLink': portalLink,
              'meetup.city': 'Göttingen',
              'location': 'Dinx Diner',
              'link': 'https://example.com/event',
            },
          ],
        }),
        200,
      );
    });
    addTearDown(client.close);
    await http.runWithClient(() async {
      final groups = await MeetupService.fetchMeetups();
      final events = await MeetupCalendarService().fetchMeetupsPortalFirst();
      expect(events, hasLength(1));
      final e = events.single;
      expect(e.meetupId, isEmpty);
      expect(e.meetupPortalLink, portalLink);
      expect(e.url, 'https://example.com/event');
      expect(e.portalEventId, 3869);
      expect(MeetupEventMatcher.resolve(e, groups)?.id, '107');
    }, () => client);
  });

  test(
    'live portal: Südniedersachsen events resolve to 107, never Sachsen',
    () async {
      // Explicit opt-in only: no network dependency in the regression suite.
      final previous = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previous);
      final groups = await MeetupService.fetchMeetups();
      final events = await MeetupCalendarService().fetchMeetupsPortalFirst();
      final southern = events
          .where((e) => e.title == 'Einundzwanzig Südniedersachsen')
          .toList();
      expect(southern, isNotEmpty);
      for (final e in southern) {
        expect(MeetupEventMatcher.resolve(e, groups)?.id, '107');
      }
      // ignore: avoid_print
      print(
        'Verified ${southern.length} live Südniedersachsen event(s): '
        '${southern.map((e) => e.portalEventId).join(", ")}',
      );
    },
    skip: !const bool.fromEnvironment('LIVE_PORTAL_TEST'),
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
