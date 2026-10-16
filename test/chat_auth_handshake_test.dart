import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/services/chat_service.dart';
import 'package:einundzwanzig_meetup_app/services/app_logger.dart';
import 'package:einundzwanzig_meetup_app/services/relay_socket.dart';
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';

class TestRelay extends Fake implements RelaySocket {
  final incoming = StreamController<dynamic>.broadcast();
  final sent = <List<dynamic>>[];
  bool closed = false;
  @override
  StreamSubscription listen(void Function(dynamic) onData, {
    Function? onError, void Function()? onDone, bool? cancelOnError,
  }) => incoming.stream.listen(onData, onError: onError, onDone: onDone,
      cancelOnError: cancelOnError);
  @override
  void add(String frame) {
    if (closed) throw StateError('Closed socket');
    sent.add(jsonDecode(frame) as List<dynamic>);
  }
  void push(List<dynamic> frame) => incoming.add(jsonEncode(frame));
  @override
  Future<void> close() async {
    if (closed) return;
    closed = true;
    await incoming.close();
  }
}

SignedEvent signed() => SignedEvent(id: 'auth-id', pubkey: 'test-key',
    createdAt: 1792144000, kind: 22242,
    tags: [['relay', kGroupRelay], ['challenge', 'challenge']],
    content: '', sig: 'test-sig');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const deadline = Duration(seconds: 10);

  testWidgets('langsamer Signer gibt Verbindung erst nach passendem AUTH-OK frei', (tester) async {
    final ws = TestRelay();
    final approval = Completer<SignedEvent>();
    var ready = false;
    var calls = 0;
    Object? requestedKind;
    Object? requestedTags;
    final connection = ChatService.authenticateSocket(ws, (_) {}, timeout: deadline,
      sign: ({required kind, required tags, required content}) {
        calls++;
        requestedKind = kind;
        requestedTags = tags;
        return approval.future;
      });
    connection.then((_) => ready = true);
    ws.push(['AUTH', 'challenge']);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(ready, isFalse, reason: 'Keine Drei-Sekunden-Freigabe');
    expect(ws.sent, isEmpty);
    ws.push(['AUTH', 'challenge']);
    await tester.pump();
    expect(calls, 1, reason: 'Keine doppelte Signer-Freigabe');
    expect(requestedKind, 22242);
    expect(requestedTags, [['relay', kGroupRelay], ['challenge', 'challenge']]);
    approval.complete(signed());
    await tester.pump();
    expect(ws.sent.single.first, 'AUTH');
    expect(ready, isFalse);
    ws.push(['OK', 'other-id', true, '']);
    await tester.pump();
    expect(ready, isFalse);
    ws.push(['OK', 'auth-id', true, '']);
    await tester.pump();
    expect(await connection, same(ws));
    await ws.close();
  });

  testWidgets('ohne AUTH wird keine Verbindung vorzeitig freigegeben', (tester) async {
    final ws = TestRelay();
    var ready = false;
    final connection = ChatService.authenticateSocket(ws, (_) {}, timeout: deadline);
    connection.then((_) => ready = true);
    await tester.pump(const Duration(seconds: 4));
    expect(ready, isFalse);
    await tester.pump(const Duration(seconds: 6));
    expect(await connection, isNull);
    expect(ws.closed, isTrue);
  });

  testWidgets('Abgelaufene Anmeldefrist verwirft eine verspätete Signatur', (tester) async {
    final ws = TestRelay();
    final approval = Completer<SignedEvent>();
    final connection = ChatService.authenticateSocket(ws, (_) {}, timeout: deadline,
      sign: ({required kind, required tags, required content}) => approval.future);
    ws.push(['AUTH', 'challenge']);
    await tester.pump();
    await tester.pump(deadline);
    expect(await connection, isNull);
    approval.complete(signed());
    await tester.pump();
    expect(ws.closed, isTrue);
    expect(ws.sent, isEmpty);
  });

  for (final abort in ['Anmeldefrist', 'geänderte Challenge', 'Verbindungsabbruch']) {
    testWidgets('späte Signer-Ablehnung bleibt nach Abbruch ohne weitere Warnung ($abort)', (tester) async {
      final ws = TestRelay();
      final approval = Completer<SignedEvent>();
      var calls = 0;
      final connection = ChatService.authenticateSocket(ws, (_) {}, timeout: deadline,
        sign: ({required kind, required tags, required content}) {
          calls++;
          return approval.future;
        });
      ws.push(['AUTH', 'challenge']);
      await tester.pump();
      if (abort == 'Anmeldefrist') {
        await tester.pump(deadline);
      } else if (abort == 'geänderte Challenge') {
        ws.push(['AUTH', 'changed']);
        await tester.pump();
      } else {
        await ws.close();
        await tester.pump();
      }
      expect(await connection, isNull);
      expect(ws.closed, isTrue);
      final warnings = AppLogger.entries.where((entry) =>
        entry.tag == 'Chat' && entry.level == 'WARN').length;
      approval.completeError(const SigningException('user rejected'));
      await tester.pump();
      expect(AppLogger.entries.where((entry) =>
        entry.tag == 'Chat' && entry.level == 'WARN').length, warnings);
      expect(calls, 1);
      expect(ws.sent, isEmpty);
    });
  }

  for (final accepted in [false, null]) {
    testWidgets('fehlendes oder abgelehntes AUTH-OK bleibt fehlgeschlagen ($accepted)', (tester) async {
      final ws = TestRelay();
      final connection = ChatService.authenticateSocket(ws, (_) {}, timeout: deadline,
        sign: ({required kind, required tags, required content}) async => signed());
      ws.push(['AUTH', 'challenge']);
      await tester.pump();
      if (accepted == false) {
        ws.push(['OK', 'auth-id', false, 'denied']);
        await tester.pump();
      } else {
        await tester.pump(deadline);
      }
      expect(await connection, isNull);
      expect(ws.closed, isTrue);
    });
  }

  testWidgets('explizite Signer-Ablehnung beendet die Anmeldung', (tester) async {
    final ws = TestRelay();
    final connection = ChatService.authenticateSocket(ws, (_) {}, timeout: deadline,
      sign: ({required kind, required tags, required content}) async {
        throw const SigningException('user rejected');
      });
    ws.push(['AUTH', 'challenge']);
    await tester.pump();
    expect(await connection, isNull);
    expect(ws.sent, isEmpty);
    expect(ws.closed, isTrue);
  });

  testWidgets('geänderte Challenge startet keine parallele Freigabe', (tester) async {
    final ws = TestRelay();
    final approval = Completer<SignedEvent>();
    var calls = 0;
    final connection = ChatService.authenticateSocket(ws, (_) {}, timeout: deadline,
      sign: ({required kind, required tags, required content}) {
        calls++;
        return approval.future;
      });
    ws.push(['AUTH', 'challenge']);
    await tester.pump();
    ws.push(['AUTH', 'changed']);
    await tester.pump();
    expect(await connection, isNull);
    approval.complete(signed());
    await tester.pump();
    expect(calls, 1);
    expect(ws.sent, isEmpty);
  });

  testWidgets('Verbindungsabbruch während Freigabe verwirft spätes Ergebnis', (tester) async {
    final ws = TestRelay();
    final approval = Completer<SignedEvent>();
    final connection = ChatService.authenticateSocket(ws, (_) {}, timeout: deadline,
      sign: ({required kind, required tags, required content}) => approval.future);
    ws.push(['AUTH', 'challenge']);
    await tester.pump();
    await ws.close();
    await tester.pump();
    expect(await connection, isNull);
    approval.complete(signed());
    await tester.pump();
    expect(ws.sent, isEmpty);
  });
}
