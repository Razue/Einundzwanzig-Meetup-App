import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_codec.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_format.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_service.dart';
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';

const generation = 1792157000;

List<MeetupBadge> collection(int count) {
  final random = Random(91);
  return List.generate(
    count,
    (i) => MeetupBadge(
      id: 'badge-$i',
      meetupEventId: 'event-$i',
      meetupName: 'Meetup ${i % 5}',
      date: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
      iconPath: '',
      sigContent: List.generate(
        4000,
        (_) => String.fromCharCode(33 + random.nextInt(94)),
      ).join(),
    ),
  );
}

int measuredChunks(List<MeetupBadge> badges) => BadgeSyncFormat.plaintexts(
  badges,
  generation,
  (plain) =>
      BadgeSyncFormat.payloadCharsForGzip(BadgeSyncCodec.deflate(plain).length),
).length;

class TransportCalls {
  int? rejectedIndex;
  int encryptions = 0;
  int signatures = 0;
  final published = <Map<String, dynamic>>[];

  Future<bool> upload(
    List<MeetupBadge> badges, {
    Future<bool> Function(String, Map<String, dynamic>)? publish,
  }) =>
      BadgeSyncService.uploadChunks(
        'fixture',
        badges,
        0,
        encrypt: (_, _) async {
          encryptions++;
          return 'sealed';
        },
        sign: ({required kind, required tags, required content}) async {
          signatures++;
          return SignedEvent(
            id: 'test-$signatures',
            pubkey: 'fixture',
            createdAt: generation,
            kind: kind,
            tags: tags,
            content: content,
            sig: 'test-signature',
          );
        },
        publish: (url, event) async {
          published.add(event);
          if (publish != null) return publish(url, event);
          final tag = (event['tags'] as List).first[1];
          return rejectedIndex == null ||
              tag != BadgeSyncFormat.dTag(rejectedIndex!);
        },
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'badge_sync_last_gen': generation,
      'badge_sync_chunk_hashes': ['previous-hash'],
      'badge_sync_dirty': true,
    });
    BadgeSyncService.debugResetProcess();
  });

  test(
    '17 tatsächliche Chunks brechen vor Verschlüsselung, Signieren und Upload ab',
    () async {
      final badges = collection(65);
      // Die bisherige Vorprüfung lässt diesen Bestand fälschlich passieren.
      expect(
        BadgeSyncFormat.chunkBadges(badges, (plain) => plain.length).length,
        lessThanOrEqualTo(BadgeSyncFormat.maxChunks),
      );
      expect(measuredChunks(badges), 17);
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final transport = TransportCalls();
      expect(await transport.upload(badges), isFalse);
      expect(transport.encryptions, 0);
      expect(transport.signatures, 0);
      expect(transport.published, isEmpty);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    },
  );

  test(
    'genau 16 tatsächliche Chunks werden vollständig veröffentlicht',
    () async {
      final badges = collection(64);
      expect(measuredChunks(badges), 16);
      final transport = TransportCalls();
      expect(await transport.upload(badges), isTrue);
      expect(transport.encryptions, 16);
      expect(transport.signatures, 16);
      expect(transport.published, hasLength(16));
      expect(
        transport.published.map((event) => (event['tags'] as List).first[1]),
        List.generate(16, BadgeSyncFormat.dTag),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('badge_sync_chunk_hashes'), hasLength(16));
    },
  );

  test('die Teilung misst die Hülle mit der echten Generation', () {
    final seen = <int>[];
    BadgeSyncFormat.plaintexts(collection(1), generation, (plain) {
      seen.add((jsonDecode(plain) as Map<String, dynamic>)['gen'] as int);
      return plain.length;
    });
    expect(seen, isNotEmpty);
    expect(seen, everyElement(generation));
  });

  test('nur der abgelehnte Chunk wird beim nächsten Upload erneut gesendet',
      () async {
    final badges = collection(64);
    final transport = TransportCalls()..rejectedIndex = 3;
    final prefs = await SharedPreferences.getInstance();
    expect(await transport.upload(badges), isFalse);
    expect(transport.encryptions, 16);
    expect(transport.signatures, 16);
    final hashes = prefs.getStringList('badge_sync_chunk_hashes')!;
    expect(hashes, hasLength(16));
    expect(hashes[3], isEmpty);
    expect(hashes.where((hash) => hash.isNotEmpty), hasLength(15));
    expect(prefs.getInt('badge_sync_last_gen'), generation);

    BadgeSyncService.debugResetProcess();
    transport.rejectedIndex = null;
    transport.published.clear();
    expect(await transport.upload(badges), isTrue);
    expect(transport.encryptions, 17);
    expect(transport.signatures, 17);
    expect(transport.published, hasLength(1));
    expect((transport.published.single['tags'] as List).first[1],
        BadgeSyncFormat.dTag(3));
    final retriedHashes = prefs.getStringList('badge_sync_chunk_hashes')!;
    expect(retriedHashes, hasLength(16));
    expect(retriedHashes[3], isNotEmpty);
    for (var i = 0; i < hashes.length; i++) {
      if (i != 3) expect(retriedHashes[i], hashes[i]);
    }
    expect(prefs.getInt('badge_sync_last_gen'), greaterThan(generation));
    final acceptedGeneration = prefs.getInt('badge_sync_last_gen');

    transport.published.clear();
    expect(await transport.upload(badges), isTrue);
    expect(transport.encryptions, 17);
    expect(transport.signatures, 17);
    expect(transport.published, isEmpty);
    expect(prefs.getInt('badge_sync_last_gen'),
        greaterThanOrEqualTo(acceptedGeneration!));
  });

  for (final throws in [false, true]) {
    final failure = throws ? 'Ausnahme' : 'Ablehnung';
    test('$failure aller Relays bleibt auch nach Wiederholung unbestätigt',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final transport = TransportCalls();
      final badges = collection(1);
      Future<bool> fail(String _, Map<String, dynamic> event) async {
        if (throws) throw StateError('Relay nicht erreichbar');
        return false;
      }

      for (var attempt = 0; attempt < 2; attempt++) {
        expect(await transport.upload(badges, publish: fail), isFalse);
        expect(prefs.getStringList('badge_sync_chunk_hashes'), ['']);
        expect(prefs.getInt('badge_sync_last_gen'), generation);
      }
      expect(transport.encryptions, 2);
      expect(transport.signatures, 2);
      expect(transport.published,
          hasLength(2 * BadgeSyncService.syncRelays.length));
    });

    test('$failure eines Relays verhindert die Bestätigung des nächsten nicht',
        () async {
      final transport = TransportCalls();
      final badges = collection(1);
      expect(
        await transport.upload(badges, publish: (url, _) async {
          if (url == BadgeSyncService.syncRelays.first) {
            if (throws) throw StateError('Relay nicht erreichbar');
            return false;
          }
          return true;
        }),
        isTrue,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('badge_sync_chunk_hashes'),
          [isNotEmpty]);
      expect(prefs.getInt('badge_sync_last_gen'), greaterThan(generation));
      expect(transport.published, hasLength(2));
      transport.published.clear();
      expect(await transport.upload(badges), isTrue);
      expect(transport.encryptions, 1);
      expect(transport.signatures, 1);
      expect(transport.published, isEmpty);
    });
  }
}
