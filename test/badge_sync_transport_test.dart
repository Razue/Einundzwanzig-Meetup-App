import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';
import 'package:einundzwanzig_meetup_app/services/app_logger.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_codec.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_format.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_service.dart';
import 'package:einundzwanzig_meetup_app/services/nip44.dart';
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';

MeetupBadge badge(int i, {String extra = ''}) => MeetupBadge(
  id: 'aschaffenburg',
  meetupName: 'Aschaffenburg',
  meetupEventId: 'aschaffenburg-2026-09-$i',
  date: DateTime.utc(2026, 9, i, 19),
  iconPath: 'assets/badge_icon.png',
  sigContent: extra,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Größenmessung berücksichtigt base64 vor NIP-44 und das Längenpräfix',
    () {
      final random = Random(21);
      for (final bytes in [1, 23, 24, 25, 32, 33, 128, 511, 819, 1500, 9000]) {
        final zipped = List.generate(bytes, (_) => random.nextInt(256));
        final encrypted = Nip44.encrypt(base64Encode(zipped), Uint8List(32));
        expect(
          BadgeSyncFormat.payloadCharsForGzip(bytes),
          encrypted.length,
          reason: 'gzip-Länge $bytes',
        );
      }
    },
  );

  test(
    'Remote-Chunks halten die Grenze mit echten gzip/base64/NIP-44-Daten ein',
    () {
      final random = Random(21);
      final badges = List.generate(
        12,
        (i) => badge(
          i + 1,
          extra: List.generate(
            350,
            (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
          ).join(),
        ),
      );
      const generation = 1792130000;
      final plains = BadgeSyncFormat.plaintexts(
        badges,
        generation,
        (p) => BadgeSyncFormat.payloadCharsForGzip(
          BadgeSyncCodec.deflate(p).length,
        ),
        maxPayloadChars: BadgeSyncFormat.remoteSignerChunkPayloadChars,
      );
      expect(plains.length, greaterThan(1));
      final roundTrip = <MeetupBadge>[];
      for (final p in plains) {
        final sealed = Nip44.encrypt(
          base64Encode(BadgeSyncCodec.deflate(p)),
          Uint8List(32),
        );
        expect(
          sealed.length,
          lessThanOrEqualTo(BadgeSyncFormat.remoteSignerChunkPayloadChars),
        );
        final opened = Nip44.decrypt(sealed, Uint8List(32));
        roundTrip.addAll(
          BadgeSyncFormat.parseEnvelope(
            BadgeSyncCodec.inflate(base64Decode(opened)),
          ).badges,
        );
      }
      expect(
        roundTrip.map(MeetupBadge.unionKey).toSet(),
        badges.map(MeetupBadge.unionKey).toSet(),
      );
    },
  );

  test(
    'Ein einzelnes übergroßes Badge wird nicht still über der Grenze gesendet',
    () {
      expect(
        () => BadgeSyncFormat.plaintexts(
          [badge(1)],
          1792130000,
          (_) => BadgeSyncFormat.remoteSignerChunkPayloadChars + 1,
          maxPayloadChars: BadgeSyncFormat.remoteSignerChunkPayloadChars,
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'Timeout eines Chunks gibt keine Teilsammlung für einen Upload frei',
    () async {
      await AppLogger.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('badge_sync_last_gen', 41);
      final good = base64Encode(
        BadgeSyncCodec.deflate(
          BadgeSyncFormat.envelopeJson(
            badges: [badge(1)],
            index: 0,
            total: 2,
            generation: 42,
          ),
        ),
      );
      final result = await BadgeSyncService.decodeRemoteChunks(
        'public',
        [
          {'content': 'ok'},
          {'content': 'timeout'},
        ],
        decrypt: (_, content) async {
          if (content == 'timeout') {
            throw TimeoutException('Signer antwortet nicht');
          }
          return good;
        },
      );
      expect(result, isNull);
      expect(prefs.getInt('badge_sync_last_gen'), 41);
      expect(
        AppLogger.exportText(),
        contains('kein Upload nach unvollständigem Lesen'),
      );
    },
  );

  test(
    'Ein beschädigter oder leerer Chunk ist kein leerer erfolgreicher Bestand',
    () async {
      for (final content in ['', 'invalid']) {
        final result = await BadgeSyncService.decodeRemoteChunks('public', [
          {'content': content},
        ], decrypt: (_, _) async => 'kein gzip/base64');
        expect(result, isNull);
      }
    },
  );

  test(
    'Alle Chunks erfolgreich: Bestand und Generation werden übernommen',
    () async {
      final result = await BadgeSyncService.decodeRemoteChunks(
        'public',
        [
          {'content': '0'},
          {'content': '1'},
        ],
        decrypt: (_, content) async {
          final i = int.parse(content);
          return base64Encode(
            BadgeSyncCodec.deflate(
              BadgeSyncFormat.envelopeJson(
                badges: [badge(i + 1)],
                index: i,
                total: 2,
                generation: 42,
              ),
            ),
          );
        },
      );
      expect(result!.length, 2);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('badge_sync_last_gen'), 42);
    },
  );
  test(
    'nicht bestätigte Chunks werden erneut gesendet; bestätigte nicht',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('signing_mode', 'nip46');
      var accepting = false;
      var encrypted = 0;
      Future<String> encrypt(String _, String plain) async {
        encrypted++;
        return Nip44.encrypt(plain, Uint8List(32));
      }

      Future<SignedEvent> sign({
        required int kind,
        required List<List<String>> tags,
        required String content,
      }) async => SignedEvent(
        id: 'test-id',
        pubkey: 'test-key',
        createdAt: 1792130000,
        kind: kind,
        tags: tags,
        content: content,
        sig: 'test-sig',
      );
      Future<bool> publish(String _, Map<String, dynamic> event) async =>
          accepting;
      final first = await BadgeSyncService.publishChunks(
        'public',
        [badge(1)],
        0,
        encrypt: encrypt,
        sign: sign,
        publish: publish,
      );
      expect(first, isFalse);
      expect(prefs.getStringList('badge_sync_chunk_hashes'), isNull);
      expect(prefs.getString('badge_sync_outbox_v1'), isNotNull);
      expect(encrypted, 1);
      accepting = true;
      expect(
        await BadgeSyncService.publishChunks(
          'public',
          [badge(1)],
          0,
          encrypt: encrypt,
          sign: sign,
          publish: publish,
        ),
        isTrue,
      );
      expect(encrypted, 1);
      expect(
        prefs.getStringList('badge_sync_chunk_hashes')!.single,
        isNotEmpty,
      );
      expect(
        await BadgeSyncService.publishChunks(
          'public',
          [badge(1)],
          0,
          encrypt: encrypt,
          sign: sign,
          publish: publish,
        ),
        isTrue,
      );
      expect(encrypted, 1);
    },
  );
  test('gleicher Bestand bleibt unabhängig von Generation und Eingabereihenfolge ruhig', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('signing_mode', 'nip46');
    var encrypted = 0;
    final random = Random(21);
    final badges = List.generate(4, (i) => badge(i + 1,
      extra: List.generate(350, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()));
    Future<String> encrypt(String _, String plain) async {
      encrypted++;
      return Nip44.encrypt(plain, Uint8List(32));
    }
    Future<SignedEvent> sign({required int kind, required List<List<String>> tags, required String content}) async => SignedEvent(
      id: tags[0][1], pubkey: 'public', createdAt: 1792130000,
      kind: kind, tags: tags, content: content, sig: 'sig');
    final events = <Map<String, dynamic>>[];
    Future<bool> publish(String _, Map<String, dynamic> event) async { events.add(event); return true; }
    expect(await BadgeSyncService.publishChunks('public', badges, 0,
      encrypt: encrypt, sign: sign, publish: publish), isTrue);
    final count = encrypted;
    await prefs.setInt('badge_sync_last_gen', 1999999999);
    expect(await BadgeSyncService.publishChunks('public', badges.reversed.toList(), 0,
      encrypt: encrypt, sign: sign, publish: publish), isTrue);
    expect(encrypted, count, reason: 'Keine weiteren Signer-Anfragen bei unverändertem Bestand');
    events.clear();
    expect(await BadgeSyncService.publishChunks('public', [...badges, badge(5)], 0,
      encrypt: encrypt, sign: sign, publish: publish), isTrue);
    final envelopes = events.map((e) => BadgeSyncFormat.parseEnvelope(
      BadgeSyncCodec.inflate(base64Decode(Nip44.decrypt(e['content'] as String, Uint8List(32)))))).toList();
    expect(envelopes.map((e) => e.generation).toSet().length, 1);
    expect(envelopes.every((e) => e.total == envelopes.length), isTrue);
    expect(envelopes.expand((e) => e.badges).length, 5);
  });

  test(
    'Signer-Abbruch vor Veröffentlichung lässt Relay-Bestand unverändert',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('signing_mode', 'nip46');
      final random = Random(42);
      final badges = List.generate(
        4,
        (i) => badge(
          i + 1,
          extra: List.generate(
            350,
            (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
          ).join(),
        ),
      );
      var encrypted = 0;
      var published = 0;
      await expectLater(
        BadgeSyncService.publishChunks(
          'public',
          badges,
          0,
          encrypt: (_, plain) async {
            if (++encrypted == 2) throw TimeoutException('lost');
            return Nip44.encrypt(plain, Uint8List(32));
          },
          sign: ({required kind, required tags, required content}) async =>
              SignedEvent(
                id: tags[0][1],
                pubkey: 'public',
                createdAt: 1792130000,
                kind: kind,
                tags: tags,
                content: content,
                sig: 'sig',
              ),
          publish: (_, event) async {
            published++;
            return true;
          },
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(published, 0);
      expect(prefs.getString('badge_sync_outbox_v1'), isNull);
    },
  );

  test('Outbox setzt Teilupload nach Neustart ohne Signer fort', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('signing_mode', 'nip46');
    final random = Random(42);
    final badges = List.generate(
      4,
      (i) => badge(
        i + 1,
        extra: List.generate(
          350,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join(),
      ),
    );
    final uploaded = <Map<String, dynamic>>[];
    var fail = true;
    Future<bool> publish(String _, Map<String, dynamic> event) async {
      if (fail && uploaded.isNotEmpty) return false;
      uploaded.add(event);
      return true;
    }

    expect(
      await BadgeSyncService.publishChunks(
        'public',
        badges,
        0,
        encrypt: (_, plain) async => Nip44.encrypt(plain, Uint8List(32)),
        sign: ({required kind, required tags, required content}) async =>
            SignedEvent(
              id: tags[0][1],
              pubkey: 'public',
              createdAt: 1792130000,
              kind: kind,
              tags: tags,
              content: content,
              sig: 'sig',
            ),
        publish: publish,
      ),
      isFalse,
    );
    expect(uploaded.length, 1);
    final box = jsonDecode(prefs.getString('badge_sync_outbox_v1')!) as Map;
    expect(box['events'].length, greaterThan(1));
    expect(
      prefs.getString('badge_sync_outbox_v1'),
      isNot(contains('Aschaffenburg')),
    );
    BadgeSyncService.debugResetProcess();
    expect(
      await BadgeSyncService.flushOutbox('other-account', 0, publish: publish),
      isFalse,
    );
    expect(uploaded.length, 1);
    fail = false;
    expect(
      await BadgeSyncService.flushOutbox('public', 0, publish: publish),
      isTrue,
    );
    expect(uploaded.length, box['events'].length);
    expect(uploaded.map((e) => e['id']).toSet().length, uploaded.length);
    expect(prefs.getString('badge_sync_outbox_v1'), isNull);
    final restored = await BadgeSyncService.decodeRemoteChunks(
      'public',
      uploaded,
      decrypt: (_, sealed) async => Nip44.decrypt(sealed, Uint8List(32)),
    );
    expect(
      restored!.map(MeetupBadge.unionKey).toSet(),
      badges.map(MeetupBadge.unionKey).toSet(),
    );
  });

  test('kleine Chunks begrenzen normale Sammlungen nicht auf 16 Termine', () {
    final random = Random(21);
    final badges = List.generate(
      40,
      (i) => badge(
        i + 1,
        extra: List.generate(
          350,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join(),
      ),
    );
    final plains = BadgeSyncFormat.plaintexts(
      badges,
      1792130000,
      (p) =>
          BadgeSyncFormat.payloadCharsForGzip(BadgeSyncCodec.deflate(p).length),
      maxPayloadChars: BadgeSyncFormat.remoteSignerChunkPayloadChars,
    );
    expect(plains.length, greaterThan(16));
    expect(plains.length, lessThanOrEqualTo(BadgeSyncFormat.maxChunks));
    final restored = plains
        .expand((p) => BadgeSyncFormat.parseEnvelope(p).badges)
        .toList();
    expect(
      restored.map(MeetupBadge.unionKey).toSet(),
      badges.map(MeetupBadge.unionKey).toSet(),
    );
  });
  test(
    'fehlende Chunks und gemischte Generationen geben keinen Upload frei',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('badge_sync_last_gen', 40);
      for (final events in [
        [
          {'content': '0:42'},
        ],
        [
          {'content': '0:42'},
          {'content': '1:41'},
        ],
      ]) {
        final result = await BadgeSyncService.decodeRemoteChunks(
          'public',
          events,
          decrypt: (_, content) async {
            final parts = content.split(':').map(int.parse).toList();
            return base64Encode(
              BadgeSyncCodec.deflate(
                BadgeSyncFormat.envelopeJson(
                  badges: [badge(parts[0] + 1)],
                  index: parts[0],
                  total: 2,
                  generation: parts[1],
                ),
              ),
            );
          },
        );
        expect(result, isNull);
        expect(prefs.getInt('badge_sync_last_gen'), 40);
      }
    },
  );
}
