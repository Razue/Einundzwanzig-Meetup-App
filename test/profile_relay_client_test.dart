import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/nostr_profile_lookup.dart';

void main() {
  late HttpServer server;
  final sockets = <WebSocket>[];
  late void Function(WebSocket socket, List<dynamic> request) respond;
  final closed = <Future<void>>[];
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      final done = Completer<void>();
      closed.add(done.future);
      socket.listen(
        (data) => respond(socket, jsonDecode(data as String) as List),
        onDone: done.complete,
      );
    });
  });
  tearDown(() async {
    for (final socket in sockets) {
      await socket.close();
    }
    sockets.clear();
    closed.clear();
    await server.close(force: true);
  });
  Future<List<Map<String, dynamic>>> query({
    Duration timeout = const Duration(seconds: 2),
  }) => ProfileRelayClient(
    timeout: timeout,
  ).query('ws://127.0.0.1:${server.port}', 'test-author');

  test(
    'REQ contains author and metadata kinds, ignores other subscriptions, closes on EOSE',
    () async {
      respond = (socket, request) {
        expect(request, [
          'REQ',
          'profile',
          {
            'kinds': [0, 10002],
            'authors': ['test-author'],
            'limit': 2,
          },
        ]);
        socket.add('invalid JSON');
        socket.add(jsonEncode(['EOSE', 'other']));
        socket.add(
          jsonEncode([
            'EVENT',
            'other',
            {'ignored': true},
          ]),
        );
        socket.add(
          jsonEncode([
            'EVENT',
            'profile',
            {'kind': 0},
          ]),
        );
        socket.add(jsonEncode(['EOSE', 'profile']));
      };
      expect(await query(), [
        {'kind': 0},
      ]);
      await closed.single.timeout(const Duration(seconds: 2));
    },
  );

  test(
    'partial results survive deadline even without EOSE and socket closes',
    () async {
      respond = (socket, _) => socket.add(
        jsonEncode([
          'EVENT',
          'profile',
          {'kind': 0},
        ]),
      );
      expect(await query(timeout: const Duration(milliseconds: 150)), [
        {'kind': 0},
      ]);
      await closed.single.timeout(const Duration(seconds: 2));
    },
  );

  test(
    'bounds responses from a relay that ignores the requested limit',
    () async {
      respond = (socket, _) {
        for (var i = 0; i < 20; i++) {
          socket.add(
            jsonEncode([
              'EVENT',
              'profile',
              {'number': i},
            ]),
          );
        }
      };
      expect(await query(), hasLength(ProfileRelayClient.maxEvents));
      await closed.single.timeout(const Duration(seconds: 2));
    },
  );

  test('oversized frames terminate query safely', () async {
    respond = (socket, _) =>
        socket.add('x' * (ProfileRelayClient.maxMessageLength + 1));
    expect(await query(), isEmpty);
    await closed.single.timeout(const Duration(seconds: 2));
  });

  test('noise frames are bounded even without metadata', () async {
    respond = (socket, _) {
      for (var i = 0; i <= ProfileRelayClient.maxMessages; i++) {
        socket.add('noise');
      }
    };
    expect(await query(), isEmpty);
    await closed.single.timeout(const Duration(seconds: 2));
  });

  test(
    'connection refusal produces empty results without unhandled errors',
    () async {
      expect(
        await const ProfileRelayClient(
          timeout: Duration(milliseconds: 100),
        ).query('ws://127.0.0.1:1', 'test-author'),
        isEmpty,
      );
    },
  );

  test('deadline includes a stalled WebSocket handshake', () async {
    final stalled = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final disconnected = Completer<void>();
    Socket? accepted;
    stalled.listen((socket) {
      accepted = socket;
      // Anfrage lesen, aber den HTTP-Upgrade nicht beantworten.
      socket.listen((_) {}, onDone: disconnected.complete);
    });
    try {
      expect(
        await const ProfileRelayClient(
          timeout: Duration(milliseconds: 150),
        ).query('ws://127.0.0.1:${stalled.port}', 'test-author'),
        isEmpty,
      );
      await disconnected.future.timeout(const Duration(seconds: 2));
    } finally {
      accepted?.destroy();
      await stalled.close();
    }
  });
}
