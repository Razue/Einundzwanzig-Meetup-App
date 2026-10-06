import 'package:einundzwanzig_meetup_app/services/deckel/deckel_backend.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_events.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_netting.dart';
import 'package:flutter_test/flutter_test.dart';

const _deckel = 'stammtisch01';

/// Drei Leute mit eigenen Schlüsseln und einer Uhr, die bei jeder Signatur
/// eine Sekunde weitergeht.
class _Table {
  final anna = KeyDeckelSigner();
  final ben = KeyDeckelSigner();
  final clara = KeyDeckelSigner();
  final events = <Map<String, dynamic>>[];
  int _now = 1790000000;

  _Table() {
    for (final signer in [anna, ben, clara]) {
      signer.clock = () => _now;
    }
  }

  Future<Map<String, dynamic>> sign(KeyDeckelSigner who, DeckelDraft draft) async {
    _now++;
    final event = await who.sign(draft);
    events.add(event);
    return event;
  }

  Future<void> seatAll() async {
    await sign(anna, seatDraft(deckelId: _deckel, name: 'Anna'));
    await sign(ben, seatDraft(deckelId: _deckel, name: 'Ben'));
    await sign(clara, seatDraft(deckelId: _deckel, name: 'Clara'));
  }

  List<String> get heads => [anna.public, ben.public, clara.public];

  Future<Map<String, dynamic>> round(KeyDeckelSigner payer, int sats, [String subject = '']) =>
      sign(payer, roundDraft(deckelId: _deckel, sats: sats, sharers: heads, subject: subject));

  DeckelState get state => reduceDeckel(_deckel, events);
}

void main() {
  test('Plätze, Runden und Salden folgen aus den Ereignissen', () async {
    final t = _Table();
    await t.seatAll();
    await t.round(t.anna, 12600, 'Bier');
    await t.round(t.ben, 9000, 'Pizza');
    await t.round(t.clara, 6000, 'Taxi');

    final state = t.state;
    expect(state.seats.values, containsAll(['Anna', 'Ben', 'Clara']));
    expect(state.open.map((r) => r.subject), ['Bier', 'Pizza', 'Taxi']);
    expect(state.openBalances, {t.anna.public: 3400, t.ben.public: -200, t.clara.public: -3200});
    expect(state.closing, isNull);
  });

  test('Die Reihenfolge, in der Ereignisse ankommen, ändert nichts', () async {
    final t = _Table();
    await t.seatAll();
    await t.round(t.anna, 12600);
    await t.round(t.ben, 9000);
    await t.sign(t.clara, closeDraft(deckelId: _deckel, roundIds: t.state.open.map((r) => r.id)));

    final forward = reduceDeckel(_deckel, t.events);
    final backward = reduceDeckel(_deckel, [...t.events.reversed, ...t.events]);
    expect(backward.closing!.id, forward.closing!.id);
    expect(backward.closing!.payments, forward.closing!.payments);
    expect(backward.seats, forward.seats);
  });

  test('Schulden kann nur, wer sich gesetzt hat', () async {
    final t = _Table();
    await t.sign(t.anna, seatDraft(deckelId: _deckel, name: 'Anna'));
    await t.sign(t.ben, seatDraft(deckelId: _deckel, name: 'Ben'));
    // Clara sitzt nicht, wird aber genannt.
    await t.round(t.anna, 9000);

    final round = t.state.open.single;
    expect(round.sharers, unorderedEquals([t.anna.public, t.ben.public]));
    expect(t.state.openBalances[t.clara.public], isNull);
    expect(t.state.openBalances[t.ben.public], -4500);
  });

  test('Eine Runde von jemandem ohne Platz zählt nicht', () async {
    final t = _Table();
    await t.sign(t.anna, seatDraft(deckelId: _deckel, name: 'Anna'));
    await t.sign(t.ben, seatDraft(deckelId: _deckel, name: 'Ben'));
    await t.round(t.clara, 50000);

    expect(t.state.open, isEmpty);
  });

  test('Runden mit unsinnigem Betrag oder ohne zweiten Kopf fallen raus', () async {
    final t = _Table();
    await t.seatAll();
    await t.sign(t.anna, roundDraft(deckelId: _deckel, sats: 0, sharers: t.heads));
    await t.sign(t.anna, roundDraft(deckelId: _deckel, sats: kDeckelMaxRoundSats + 1, sharers: t.heads));
    await t.sign(t.anna, roundDraft(deckelId: _deckel, sats: 5000, sharers: [t.anna.public]));
    await t.sign(
      t.anna,
      const DeckelDraft(kind: kDeckelRound, tags: [
        ['d', _deckel],
        ['amount', 'viel'],
      ]),
    );

    expect(t.state.open, isEmpty);
  });

  test('Ein Kassensturz rechnet seine Runden ab; was danach kommt, steht auf dem nächsten Blatt', () async {
    final t = _Table();
    await t.seatAll();
    await t.round(t.anna, 12600);
    await t.round(t.ben, 9000);
    await t.round(t.clara, 6000);
    final close = await t.sign(t.ben, closeDraft(deckelId: _deckel, roundIds: t.state.open.map((r) => r.id)));
    await t.round(t.anna, 3000, 'Absacker');

    final state = t.state;
    expect(state.closing!.id, close['id']);
    expect(state.closing!.payments, [
      DeckelPayment(from: t.clara.public, to: t.anna.public, sats: 3200),
      DeckelPayment(from: t.ben.public, to: t.anna.public, sats: 200),
    ]);
    expect(state.closing!.summary.debts, 6);
    expect(state.closing!.summary.payments, 2);
    expect(state.open.single.subject, 'Absacker');
  });

  test('Zwei Kassenstürze über dieselben Runden: der frühere gilt', () async {
    final t = _Table();
    await t.seatAll();
    await t.round(t.anna, 12600);
    final ids = t.state.open.map((r) => r.id).toList();
    final first = await t.sign(t.ben, closeDraft(deckelId: _deckel, roundIds: ids));
    await t.sign(t.clara, closeDraft(deckelId: _deckel, roundIds: ids));

    expect(t.state.closing!.id, first['id']);
    expect(t.state.open, isEmpty);
  });

  test('Ein Kassensturz von jemandem ohne Platz gilt nicht', () async {
    final t = _Table();
    await t.sign(t.anna, seatDraft(deckelId: _deckel, name: 'Anna'));
    await t.sign(t.ben, seatDraft(deckelId: _deckel, name: 'Ben'));
    await t.round(t.anna, 8000);
    await t.sign(t.clara, closeDraft(deckelId: _deckel, roundIds: t.state.open.map((r) => r.id)));

    expect(t.state.closing, isNull);
    expect(t.state.open, hasLength(1));
  });

  test('Nur die Quittung des Empfängers zählt', () async {
    final t = _Table();
    await t.seatAll();
    await t.round(t.anna, 12600);
    await t.round(t.ben, 9000);
    await t.round(t.clara, 6000);
    final close = await t.sign(t.anna, closeDraft(deckelId: _deckel, roundIds: t.state.open.map((r) => r.id)));
    final closingId = close['id'] as String;
    final claraPays = t.state.closing!.payments.first;

    // Clara quittiert sich selbst: zählt nicht.
    await t.sign(t.clara, receiptDraft(deckelId: _deckel, closingId: closingId, payment: claraPays));
    expect(t.state.closing!.paid(claraPays), isFalse);

    // Anna quittiert: zählt.
    await t.sign(t.anna, receiptDraft(deckelId: _deckel, closingId: closingId, payment: claraPays));
    expect(t.state.closing!.paid(claraPays), isTrue);
    expect(t.state.closing!.settled, isFalse);

    await t.sign(
      t.anna,
      receiptDraft(deckelId: _deckel, closingId: closingId, payment: t.state.closing!.payments.last, rail: 'hand'),
    );
    expect(t.state.closing!.settled, isTrue);
  });

  test('Ereignisse eines anderen Deckels bleiben draußen', () async {
    final t = _Table();
    await t.seatAll();
    await t.sign(t.anna, roundDraft(deckelId: 'andererdeckel', sats: 9000, sharers: t.heads));

    expect(t.state.open, isEmpty);
  });

  test('Kaputte Ereignisse werfen nichts um', () {
    final state = reduceDeckel(_deckel, [
      {'id': 'kurz', 'pubkey': 'x', 'created_at': 1, 'kind': kDeckelRound, 'tags': [], 'content': ''},
      {'id': 1, 'tags': 'nein'},
      <String, dynamic>{},
    ]);
    expect(state.seats, isEmpty);
    expect(state.open, isEmpty);
  });

  test('Der once-Schlüssel hängt an Kassensturz, Schuldner und Gläubiger', () {
    const p = DeckelPayment(from: 'a', to: 'b', sats: 100);
    expect(onceKey('k1', p), onceKey('k1', const DeckelPayment(from: 'a', to: 'b', sats: 999)));
    expect(onceKey('k1', p), isNot(onceKey('k2', p)));
    expect(onceKey('k1', p), isNot(onceKey('k1', const DeckelPayment(from: 'b', to: 'a', sats: 100))));
    expect(onceKey('k1', p), hasLength(64));
  });

  test('QR-Code des Bierdeckels hin und zurück', () {
    final code = deckelQr(deckelId: 'a1b2c3d4e5f60718', name: 'Stammtisch Kölle');
    expect(code, startsWith('21d:1:a1b2c3d4e5f60718:'));
    expect(parseDeckelQr(code), (deckelId: 'a1b2c3d4e5f60718', name: 'Stammtisch Kölle'));

    // So steht es auf den gedruckten Bierdeckeln (docs/deckel/bierdeckel.html).
    expect(parseDeckelQr('21d:1:btcppberlin01:VGlzY2ggMQ'), (deckelId: 'btcppberlin01', name: 'Tisch 1'));

    expect(parseDeckelQr('21:irgendwas'), isNull);
    expect(parseDeckelQr('21d:2:a1b2c3d4e5f60718:QQ'), isNull);
    expect(parseDeckelQr('21d:1:KURZ:QQ'), isNull);
    expect(parseDeckelQr('21d:1:a1b2c3d4e5f60718:%%%'), isNull);
  });

  test('Signierte Ereignisse bestehen die Prüfung, veränderte nicht', () async {
    final signer = KeyDeckelSigner();
    final event = await signer.sign(seatDraft(deckelId: _deckel, name: 'Anna'));
    expect(deckelEventValid(event), isTrue);

    final forged = Map<String, dynamic>.from(event)..['content'] = 'anders';
    expect(deckelEventValid(forged), isFalse);
  });
}
