import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/services/nostr_profile_lookup.dart';
import 'package:einundzwanzig_meetup_app/services/nostr_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secret =
      '0000000000000000000000000000000000000000000000000000000000000001';
  var now = DateTime.utc(2026, 10, 6);
  Event event({
    int kind = 0,
    String content = '{"picture":"https://images.example/avatar.png"}',
    List<List<String>> tags = const [],
    int age = 10,
    String key = secret,
  }) => Event.from(
    kind: kind,
    content: content,
    tags: tags,
    privkey: key,
    createdAt: now.millisecondsSinceEpoch ~/ 1000 - age,
  );
  final pubkey = event().pubkey;
  const image = 'https://images.example/avatar.png';
  final calls = <String>[];
  final responses = <String, List<Map<String, dynamic>>>{};
  late NostrProfileLookup lookup;
  setUp(() {
    now = DateTime.utc(2026, 10, 6);
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    responses.clear();
    lookup = NostrProfileLookup(
      now: () => now,
      relays: () async => ['wss://app.example'],
      query: (relay, author) async {
        expect(author, matches(RegExp(r'^[0-9a-f]{64}$')));
        calls.add(relay);
        return author == pubkey ? responses[relay] ?? [] : [];
      },
    );
  });

  test(
    'first import finds signed metadata on profile index without local key or NIP-05',
    () async {
      responses[NostrProfileLookup.indexRelay] = [event().toJson()];
      expect(await lookup.fetchPicture(pubkey), image);
      expect(
        calls,
        containsAll(['wss://app.example', NostrProfileLookup.indexRelay]),
      );
      calls.clear();
      expect(await lookup.fetchPicture(pubkey), image);
      expect(calls, isEmpty);
    },
  );

  test(
    'NIP-65 write and unmarked relays compete with bootstrap metadata; read relays excluded',
    () async {
      responses[NostrProfileLookup.indexRelay] = [
        event(age: 100).toJson(),
        event(
          kind: 10002,
          content: '',
          tags: [
            ['r', 'wss://read.example', 'read'],
            ['r', 'wss://write.example/', 'write'],
            ['r', 'wss://both.example'],
            ['r', 'wss://write.example'],
          ],
        ).toJson(),
      ];
      responses['wss://write.example'] = [
        event(content: '{"picture":"https://images.example/new.png"}').toJson(),
      ];
      expect(
        await lookup.fetchPicture(pubkey),
        'https://images.example/new.png',
      );
      expect(calls.where((r) => r == 'wss://write.example'), hasLength(1));
      expect(calls, contains('wss://both.example'));
      expect(calls, isNot(contains('wss://read.example')));
      now = now.add(const Duration(hours: 13));
      responses.remove(NostrProfileLookup.indexRelay);
      calls.clear();
      expect(
        await lookup.fetchPicture(pubkey),
        'https://images.example/new.png',
      );
      expect(calls, contains('wss://write.example')); // persisted relay hints
    },
  );

  test(
    'latest relay list replaces older hints, including removal of all relays',
    () async {
      responses['wss://app.example'] = [
        event(
          kind: 10002,
          content: '',
          age: 100,
          tags: [
            ['r', 'wss://old.example'],
          ],
        ).toJson(),
      ];
      responses[NostrProfileLookup.indexRelay] = [
        event(kind: 10002, content: '').toJson(),
      ];
      expect(await lookup.fetchPicture(pubkey), isNull);
      expect(calls, isNot(contains('wss://old.example')));
    },
  );

  test(
    'newest metadata wins regardless of arrival order; equal timestamps use lowest ID',
    () async {
      final a = event();
      final b = event(content: '{"picture":"https://images.example/b.png"}');
      final winner = a.id.compareTo(b.id) < 0 ? a : b;
      responses['wss://app.example'] = [
        b.toJson(),
        event(age: 100).toJson(),
        a.toJson(),
      ];
      expect(
        await lookup.fetchPicture(pubkey),
        (jsonDecode(winner.content) as Map)['picture'],
      );
    },
  );

  test(
    'rejects tampering, wrong author/kind, future timestamp and malformed metadata',
    () async {
      final tampered = event().toJson()
        ..['content'] = '{"picture":"https://evil.example"}';
      responses['wss://app.example'] = [
        tampered,
        event(
          key:
              '0000000000000000000000000000000000000000000000000000000000000002',
        ).toJson(),
        event(kind: 1).toJson(),
        event(age: -1).toJson(),
        event(content: '[]').toJson(),
        event(content: 'not JSON').toJson(),
        event().toJson(),
      ];
      expect(await lookup.fetchPicture(pubkey), image);
    },
  );

  test(
    'stale signed cache survives outage and older responses cannot downgrade it',
    () async {
      responses['wss://app.example'] = [event().toJson()];
      expect(await lookup.fetchPicture(pubkey), image);
      now = now.add(const Duration(hours: 13));
      responses.clear();
      expect(await lookup.fetchPicture(pubkey), image);
      responses['wss://app.example'] = [
        event(
          age: 100000,
          content: '{"picture":"https://images.example/old.png"}',
        ).toJson(),
      ];
      expect(await lookup.fetchPicture(pubkey), image);
    },
  );

  test(
    'signed picture removal wins, is cached, and never revives legacy URL',
    () async {
      responses['wss://app.example'] = [event().toJson()];
      await lookup.fetchPicture(pubkey);
      now = now.add(const Duration(hours: 13));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nostr_profile_picture_$pubkey', image);
      responses['wss://app.example'] = [event(content: '{}').toJson()];
      expect(await lookup.fetchPicture(pubkey), isNull);
      calls.clear();
      expect(await lookup.fetchPicture(pubkey), isNull);
      expect(calls, isEmpty);
      now = now.add(const Duration(hours: 13));
      responses.clear();
      expect(await lookup.fetchPicture(pubkey), isNull);
      expect(prefs.containsKey('nostr_profile_picture_$pubkey'), isFalse);
    },
  );

  test(
    'legacy cache migrates on expiry and remains an outage fallback',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nostr_profile_picture_$pubkey', image);
      await prefs.setInt(
        'nostr_profile_picture_time_$pubkey',
        now.millisecondsSinceEpoch,
      );
      expect(await lookup.fetchPicture(pubkey), image);
      expect(calls, isEmpty);
      now = now.add(const Duration(hours: 13));
      expect(await lookup.fetchPicture(pubkey), image);
      responses['wss://app.example'] = [event().toJson()];
      expect(await lookup.fetchPicture(pubkey), image);
      expect(prefs.containsKey('nostr_profile_metadata_v2_$pubkey'), isTrue);
      expect(prefs.containsKey('nostr_profile_picture_$pubkey'), isFalse);
    },
  );

  test(
    'invalid cache and invalid key fail safely; missing metadata is retried',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'nostr_profile_metadata_v2_$pubkey',
        jsonEncode({
          'event': event(kind: 10002, content: '').toJson(),
          'fetchedAt': now.millisecondsSinceEpoch,
        }),
      );
      expect(await lookup.fetchPicture('npub-invalid'), isNull);
      expect(calls, isEmpty);
      expect(await lookup.fetchPicture(pubkey), isNull);
      responses['wss://app.example'] = [event().toJson()];
      expect(await lookup.fetchPicture(pubkey), image);
      expect(
        await lookup.fetchPicture('0' * 64),
        isNull,
      ); // another identity cannot borrow this cache
    },
  );

  test(
    'simultaneous lookups coalesce; invalidation prevents old cache writes',
    () async {
      final pending = Completer<List<Map<String, dynamic>>>();
      var count = 0;
      lookup = NostrProfileLookup(
        now: () => now,
        relays: () async => [],
        query: (_, _) {
          count++;
          return pending.future;
        },
      );
      final first = lookup.fetchPicture(pubkey);
      final second = lookup.fetchPicture(pubkey);
      await Future<void>.delayed(Duration.zero);
      expect(count, 1);
      lookup.invalidate();
      pending.complete([event().toJson()]);
      expect(await first, image);
      expect(await second, image);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('nostr_profile_metadata_v2_$pubkey'), isFalse);
    },
  );

  test('discovered relay destinations are deduplicated and bounded', () async {
    responses[NostrProfileLookup.indexRelay] = [
      event(
        kind: 10002,
        content: '',
        tags: [
          ['r', 'ws://insecure.example'],
          ['r', 'wss://127.0.0.1'],
          ['r', 'wss://10.0.0.1'],
          ['r', 'wss://user:pass@host.example'],
          ['r', 'wss://localhost'],
          for (var i = 0; i < 10; i++) ['r', 'wss://relay$i.example'],
        ],
      ).toJson(),
    ];
    await lookup.fetchPicture(pubkey);
    expect(calls.where((r) => r.startsWith('wss://relay')), hasLength(4));
    expect(calls, hasLength(6));
  });

  test(
    'bad relay failures are isolated and initial fan-out is bounded',
    () async {
      lookup = NostrProfileLookup(
        now: () => now,
        relays: () async => [
          for (var i = 0; i < 30; i++) 'wss://relay$i.example',
        ],
        query: (relay, _) async {
          calls.add(relay);
          if (relay == NostrProfileLookup.indexRelay) return [event().toJson()];
          throw StateError('offline');
        },
      );
      expect(await lookup.fetchPicture(pubkey), image);
      expect(calls, hasLength(NostrProfileLookup.maxInitialRelays));
    },
  );

  test('picture URL accepts HTTP(S) only without embedded credentials', () {
    for (final value in [
      null,
      12,
      '',
      'file:///tmp/picture',
      'data:image/png,abc',
      'javascript:alert(1)',
      'https://user:pass@images.example/a',
    ]) {
      expect(NostrProfileLookup.pictureUrl(value), isNull);
    }
    expect(NostrProfileLookup.pictureUrl(image), image);
  });

  test(
    'new relay hints from author relays are retained without recursive fan-out',
    () async {
      responses[NostrProfileLookup.indexRelay] = [
        event(
          kind: 10002,
          content: '',
          age: 100,
          tags: [
            ['r', 'wss://old.example'],
          ],
        ).toJson(),
      ];
      responses['wss://old.example'] = [
        event(
          kind: 10002,
          content: '',
          tags: [
            ['r', 'wss://new.example'],
          ],
        ).toJson(),
      ];
      expect(await lookup.fetchPicture(pubkey), isNull);
      expect(calls, isNot(contains('wss://new.example')));
      responses.clear();
      calls.clear();
      responses['wss://new.example'] = [event().toJson()];
      expect(await lookup.fetchPicture(pubkey), image);
      expect(calls, contains('wss://new.example'));
    },
  );

  test(
    'app reset clears both cache generations and hints but preserves unrelated preferences',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nostr_profile_metadata_v2_$pubkey', '{}');
      await prefs.setString('nostr_profile_relays_v2_$pubkey', '{}');
      await prefs.setString('nostr_profile_picture_$pubkey', image);
      await prefs.setInt('nostr_profile_picture_time_$pubkey', 1);
      await prefs.setString('local_profile_picture', '/local.png');
      await prefs.setString('nickname', 'Example');
      await NostrProfileService.clearCache();
      expect(prefs.getKeys(), {'nickname'});
    },
  );

  test(
    'relay hint URL rejects private, abbreviated and invalid literal addresses',
    () {
      for (final host in [
        '127.1',
        '10.1',
        '192.168.1.1',
        '172.16.0.1',
        '169.254.1.1',
        '100.64.0.1',
        '0.0.0.0',
        '999.1.1.1',
        '[::1]',
      'relay.local',
      'relay.local.',
      'localhost.localdomain',
      '127.0.0.1.',
      ]) {
        expect(
          NostrProfileLookup.relayUrl('wss://$host', discovered: true),
          isNull,
        );
      }
      expect(
        NostrProfileLookup.relayUrl('wss://relay.example/', discovered: true),
        'wss://relay.example',
      );
      expect(
        NostrProfileLookup.relayUrl(
          'wss://relay.example/path',
          discovered: true,
        ),
        'wss://relay.example/path',
      );
    },
  );
}
