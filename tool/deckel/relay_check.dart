// Ein ganzer Abend über echte Relays, ohne Handy.
//
// Drei frisch gewürfelte Schlüssel setzen sich an einen Deckel, schreiben
// drei Runden an, machen Kassensturz und quittieren. Danach liest ein
// unbeteiligter Vierter den Deckel vom Relay und rechnet nach.
//
// Zeigt je Relay, ob es die vier Ereignisarten annimmt und nach dem d-Tag
// wieder herausgibt — das ist die Voraussetzung dafür, dass der Deckel
// zwischen zwei Handys funktioniert.
//
//   dart run tool/deckel/relay_check.dart                 die Standard-Relays der App
//   dart run tool/deckel/relay_check.dart ws://localhost:4000/relay/websocket
//
// Die Ereignisse bleiben auf den Relays liegen. Sie tragen eine zufällige
// Deckel-Kennung, die mit "test" beginnt.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:einundzwanzig_meetup_app/services/deckel/deckel_events.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_netting.dart';
import 'package:nostr/nostr.dart';

const _defaults = [
  'wss://relay.damus.io',
  'wss://nos.lol',
  'wss://relay.nostr.band',
  'wss://nostr.einundzwanzig.space',
];

const _timeout = Duration(seconds: 8);

Future<void> main(List<String> args) async {
  final relays = args.isEmpty ? _defaults : args;
  var failed = false;
  for (final url in relays) {
    final ok = await _evening(url);
    failed = failed || !ok;
  }
  exit(failed ? 1 : 0);
}

Future<bool> _evening(String url) async {
  stdout.writeln('\n$url');
  final random = Random.secure();
  final deckelId = 'test${[for (var i = 0; i < 6; i++) random.nextInt(256).toRadixString(16).padLeft(2, '0')].join()}';
  final anna = Keychain.generate();
  final ben = Keychain.generate();
  final clara = Keychain.generate();
  final heads = [anna.public, ben.public, clara.public];
  var now = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 20;

  Map<String, dynamic> sign(Keychain who, DeckelDraft draft) => Event.from(
        createdAt: now++,
        kind: draft.kind,
        tags: draft.tags,
        content: draft.content,
        privkey: who.private,
      ).toJson();

  final rounds = [
    sign(anna, roundDraft(deckelId: deckelId, sats: 12600, sharers: heads, subject: 'Bier')),
    sign(ben, roundDraft(deckelId: deckelId, sats: 9000, sharers: heads, subject: 'Pizza')),
    sign(clara, roundDraft(deckelId: deckelId, sats: 6000, sharers: heads, subject: 'Taxi')),
  ];
  final close = sign(ben, closeDraft(deckelId: deckelId, roundIds: rounds.map((r) => r['id'] as String)));
  final closingId = close['id'] as String;
  final claraPays = DeckelPayment(from: clara.public, to: anna.public, sats: 3200);
  final benPays = DeckelPayment(from: ben.public, to: anna.public, sats: 200);

  final steps = <(String, Map<String, dynamic>)>[
    ('Platz Anna      (30251)', sign(anna, seatDraft(deckelId: deckelId, name: 'Anna'))),
    ('Platz Ben       (30251)', sign(ben, seatDraft(deckelId: deckelId, name: 'Ben'))),
    ('Platz Clara     (30251)', sign(clara, seatDraft(deckelId: deckelId, name: 'Clara'))),
    ('Runde Bier       (1251)', rounds[0]),
    ('Runde Pizza      (1251)', rounds[1]),
    ('Runde Taxi       (1251)', rounds[2]),
    ('Kassensturz      (1252)', close),
    ('Quittung Clara   (1253)', sign(anna, receiptDraft(deckelId: deckelId, closingId: closingId, payment: claraPays))),
    ('Quittung Ben     (1253)', sign(anna, receiptDraft(deckelId: deckelId, closingId: closingId, payment: benPays, rail: 'hand'))),
  ];

  for (final (label, event) in steps) {
    final answer = await _publish(url, event);
    stdout.writeln('  ${answer == null ? 'ok  ' : 'NEIN'}  $label${answer == null ? '' : '  — $answer'}');
    if (answer != null) return false;
    // Manche Relays bremsen, wenn Ereignisse zu dicht aufeinander folgen.
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  await Future<void>.delayed(const Duration(seconds: 1));
  final read = await _query(url, {
    'kinds': kDeckelKinds,
    '#d': [deckelId],
  });
  final state = reduceDeckel(deckelId, read);
  final closing = state.closing;
  final checks = <String, bool>{
    '${read.length} von ${steps.length} Ereignissen zurückgelesen': read.length == steps.length,
    'drei am Tisch': state.seats.length == 3,
    'Kassensturz gefunden': closing != null,
    '6 Schulden über 18.400 werden 2 Zahlungen über 3.400': closing != null &&
        closing.summary.debts == 6 &&
        closing.summary.debtSats == 18400 &&
        closing.summary.payments == 2 &&
        closing.summary.paymentSats == 3400,
    'Zahlungen: Clara→Anna 3.200, Ben→Anna 200':
        closing != null && closing.payments.length == 2 && closing.payments[0] == claraPays && closing.payments[1] == benPays,
    'beide quittiert, Deckel ausgeglichen': closing != null && closing.settled,
  };
  for (final check in checks.entries) {
    stdout.writeln('  ${check.value ? 'ok  ' : 'NEIN'}  ${check.key}');
  }
  return checks.values.every((ok) => ok);
}

/// Null, wenn das Relay angenommen hat, sonst seine Antwort.
Future<String?> _publish(String url, Map<String, dynamic> event) async {
  WebSocket? ws;
  try {
    ws = await WebSocket.connect(url).timeout(_timeout);
    final done = Completer<String?>();
    ws.listen(
      (data) {
        final msg = jsonDecode(data as String);
        if (msg is! List || done.isCompleted) return;
        if (msg[0] == 'OK' && msg[1] == event['id']) {
          done.complete(msg[2] == true ? null : '${msg.length > 3 ? msg[3] : 'abgelehnt'}');
        } else if (msg[0] == 'NOTICE') {
          done.complete('NOTICE ${msg[1]}');
        }
      },
      onError: (Object e) {
        if (!done.isCompleted) done.complete('$e');
      },
      onDone: () {
        if (!done.isCompleted) done.complete('Verbindung geschlossen');
      },
    );
    ws.add(jsonEncode(['EVENT', event]));
    return await done.future.timeout(_timeout, onTimeout: () => 'keine Antwort');
  } catch (e) {
    return '$e';
  } finally {
    await ws?.close();
  }
}

Future<List<Map<String, dynamic>>> _query(String url, Map<String, dynamic> filter) async {
  final out = <Map<String, dynamic>>[];
  WebSocket? ws;
  try {
    ws = await WebSocket.connect(url).timeout(_timeout);
    final done = Completer<void>();
    ws.listen(
      (data) {
        final msg = jsonDecode(data as String);
        if (msg is! List) return;
        if (msg[0] == 'EVENT' && msg.length >= 3) {
          final event = Map<String, dynamic>.from(msg[2] as Map);
          try {
            Event.fromJson(event, verify: true);
            out.add(event);
          } catch (_) {}
        } else if ((msg[0] == 'EOSE' || msg[0] == 'CLOSED') && !done.isCompleted) {
          done.complete();
        }
      },
      onError: (_) {
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
    );
    ws.add(jsonEncode(['REQ', 'check', filter]));
    await done.future.timeout(_timeout, onTimeout: () {});
  } catch (_) {
    // Ein stummes Relay liefert nichts; die Prüfung unten sagt es.
  } finally {
    await ws?.close();
  }
  return out;
}
