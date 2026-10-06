import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_backend.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_demo.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_events.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_ledger.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_netting.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_oracle.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_table.dart';
import 'package:flutter_test/flutter_test.dart';

const _deckel = 'stammtisch01';

String _hash(String secretHex) => sha256.convert(hex.decode(secretHex)).toString();

/// Ein Orakel mit eigenem Schlüssel, das festlegt und auflöst wie Kickstr.
class _Oracle {
  final signer = KeyDeckelSigner();
  final secretYes = 'a1' * 32;
  final secretNo = 'b2' * 32;
  final events = <Map<String, dynamic>>[];
  int now = 1790000000;

  _Oracle() {
    signer.clock = () => now;
  }

  String get key => signer.public;

  Future<Map<String, dynamic>> commit({int topic = 4297, int strike = 86000, int closesIn = 3600}) async {
    final event = await signer.sign(DeckelDraft(
      kind: kOracleCommit,
      content: 'Bitcoin at or above $strike USD at the close?',
      tags: [
        ['d', 'glimpse:$topic'],
        ['strike', '$strike'],
        ['closes', '${now + closesIn}'],
        ['yes', _hash(secretYes)],
        ['no', _hash(secretNo)],
      ],
    ));
    events.add(event);
    return event;
  }

  Future<Map<String, dynamic>> reveal(Map<String, dynamic> commitment, {required bool yes, String? secret}) async {
    final event = await signer.sign(DeckelDraft(
      kind: kOracleReveal,
      tags: [
        ['d', (commitment['tags'] as List).first[1] as String],
        ['e', commitment['id'] as String],
        ['outcome', yes ? 'yes' : 'no'],
        ['preimage', secret ?? (yes ? secretYes : secretNo)],
        ['bucket', '86200-86400'],
      ],
    ));
    events.add(event);
    return event;
  }

  OracleBook get book => OracleBook.read(key, events);
}

/// Drei am Tisch, Uhr geht bei jeder Signatur eine Sekunde weiter.
class _Table {
  final anna = KeyDeckelSigner();
  final ben = KeyDeckelSigner();
  final clara = KeyDeckelSigner();
  final events = <Map<String, dynamic>>[];
  int now = 1790000000;

  _Table() {
    for (final signer in [anna, ben, clara]) {
      signer.clock = () => now;
    }
  }

  Future<Map<String, dynamic>> sign(KeyDeckelSigner who, DeckelDraft draft) async {
    now++;
    final event = await who.sign(draft);
    events.add(event);
    return event;
  }

  Future<void> seatAll() async {
    await sign(anna, seatDraft(deckelId: _deckel, name: 'Anna'));
    await sign(ben, seatDraft(deckelId: _deckel, name: 'Ben'));
    await sign(clara, seatDraft(deckelId: _deckel, name: 'Clara'));
  }

  Future<Map<String, dynamic>> bet(KeyDeckelSigner who, String questionId, {required bool yes, int sats = 2000}) =>
      sign(who, betDraft(deckelId: _deckel, questionId: questionId, yes: yes, sats: sats));
}

void main() {
  group('Orakel', () {
    test('Festlegung wird gelesen, die zuletzt festgelegte offene Frage ist die frische', () async {
      final oracle = _Oracle();
      final near = await oracle.commit(topic: 4296, strike: 86000, closesIn: 900);
      final fresh = await oracle.commit(topic: 4297, strike: 86200, closesIn: 4500);

      final book = oracle.book;
      expect(book.questions, hasLength(2));
      expect(book.fresh(oracle.now)!.id, fresh['id']);
      expect(book.fresh(oracle.now)!.strike, 86200);
      expect(book.fresh(oracle.now + 1000)!.id, fresh['id']);
      expect(book.fresh(oracle.now + 5000), isNull);
      expect(book.questions[near['id']]!.topicId, 4296);
    });

    test('Eine Auflösung zählt nur mit dem Geheimnis, das zur Festlegung passt', () async {
      final oracle = _Oracle();
      final a = await oracle.commit(topic: 1);
      final b = await oracle.commit(topic: 2);
      final c = await oracle.commit(topic: 3);
      await oracle.reveal(a, yes: true);
      await oracle.reveal(b, yes: false);
      await oracle.reveal(c, yes: true, secret: oracle.secretNo); // sagt Ja, zeigt das Nein-Geheimnis

      final book = oracle.book;
      expect(book.verdicts, {a['id']: true, b['id']: false});
      expect(book.fresh(oracle.now)!.id, c['id'], reason: 'ohne gültige Auflösung bleibt die Frage offen');
    });

    test('Was nicht vom Orakel stammt oder nicht die Form hat, fällt raus', () async {
      final oracle = _Oracle();
      final impostor = _Oracle();
      final real = await oracle.commit();
      final fake = await impostor.commit();
      final broken = await oracle.signer.sign(const DeckelDraft(kind: kOracleCommit, tags: [
        ['d', 'glimpse:x'],
        ['strike', 'viel'],
      ]));

      final book = OracleBook.read(oracle.key, [real, fake, broken, <String, dynamic>{}]);
      expect(book.questions.keys, [real['id']]);
    });

    test('Ja-Anteil des Marktes: Preise der Buckets ab dem Strike', () {
      final quotes = jsonDecode('''
        {"outcomes": [
          {"name": "85800-86000", "yes_price_millisats": 20000},
          {"name": "86000-86200", "yes_price_millisats": 50000},
          {"name": "86200-86400", "yes_price_millisats": 30000},
          {"name": "86400-86600", "yes_price_millisats": 0}
        ]}''');
      expect(yesShareOf(quotes, 86000), closeTo(0.8, 1e-9));
      expect(yesShareOf(quotes, 86200), closeTo(0.3, 1e-9));
      expect(yesShareOf({'outcomes': []}, 86000), isNull);
      expect(yesShareOf('kaputt', 86000), isNull);
    });
  });

  group('Wetten auf dem Deckel', () {
    late _Oracle oracle;
    late _Table t;
    late Map<String, dynamic> commitment;
    late String q;

    setUp(() async {
      oracle = _Oracle();
      t = _Table();
      await t.seatAll();
      commitment = await oracle.commit();
      q = commitment['id'] as String;
    });

    DeckelState state() => reduceDeckel(_deckel, t.events, oracle: oracle.book);

    test('Ja gegen Nein über denselben Betrag gehört zusammen und wartet auf das Orakel', () async {
      await t.bet(t.anna, q, yes: true);
      expect(state().wagers.single.yes, t.anna.public);
      expect(state().wagers.single.matched, isFalse);

      await t.bet(t.ben, q, yes: false);
      final wager = state().wagers.single;
      expect(wager.matched, isTrue);
      expect(wager.yes, t.anna.public);
      expect(wager.no, t.ben.public);
      expect(wager.sats, 2000);
      expect(state().open, isEmpty, reason: 'vor der Auflösung schuldet niemand etwas');
    });

    test('Nach der Auflösung schuldet der Verlierer dem Gewinner den Betrag', () async {
      await t.bet(t.anna, q, yes: true);
      final second = await t.bet(t.ben, q, yes: false);
      await oracle.reveal(commitment, yes: true);

      final s = state();
      expect(s.wagers, isEmpty);
      final round = s.open.single;
      expect(round.bet, isTrue);
      expect(round.id, second['id']);
      expect(round.payer, t.anna.public);
      expect(round.sharers, [t.ben.public]);
      expect(round.subject, '86000');
      expect(s.openBalances, {t.anna.public: 2000, t.ben.public: -2000});
    });

    test('Geht Nein auf, gewinnt die Nein-Seite', () async {
      await t.bet(t.anna, q, yes: true, sats: 500);
      await t.bet(t.ben, q, yes: false, sats: 500);
      await oracle.reveal(commitment, yes: false);

      expect(state().openBalances, {t.ben.public: 500, t.anna.public: -500});
    });

    test('Die gewonnene Wette verrechnet sich mit den Runden des Abends', () async {
      await t.sign(t.ben, roundDraft(
        deckelId: _deckel,
        sats: 9000,
        sharers: [t.anna.public, t.ben.public, t.clara.public],
        subject: 'Pizza',
      ));
      await t.bet(t.anna, q, yes: true, sats: 3000);
      await t.bet(t.ben, q, yes: false, sats: 3000);
      await oracle.reveal(commitment, yes: true);

      // Anna schuldet Ben 3.000 für die Pizza und bekommt 3.000 aus der Wette: quitt.
      final s = state();
      expect(s.openBalances[t.anna.public], 0);
      await t.sign(t.clara, closeDraft(deckelId: _deckel, roundIds: s.open.map((r) => r.id)));
      expect(state().closing!.payments, [
        DeckelPayment(from: t.clara.public, to: t.ben.public, sats: 3000),
      ]);
      expect(state().closing!.summary.debts, 3);
    });

    test('Wer zuerst kam, wird zuerst angenommen; mit sich selbst wettet niemand', () async {
      await t.bet(t.anna, q, yes: true);
      await t.bet(t.anna, q, yes: false); // dieselbe Person auf der Gegenseite
      expect(state().wagers.where((w) => w.matched), isEmpty);
      expect(state().wagers, hasLength(2));

      await t.bet(t.ben, q, yes: true);
      // Bens Ja trifft Annas Nein; Annas Ja wartet weiter.
      final s = state();
      final matched = s.wagers.singleWhere((w) => w.matched);
      expect(matched.yes, t.ben.public);
      expect(matched.no, t.anna.public);
      expect(s.wagers.singleWhere((w) => !w.matched).yes, t.anna.public);
    });

    test('Verschiedene Beträge finden sich nicht', () async {
      await t.bet(t.anna, q, yes: true, sats: 2000);
      await t.bet(t.ben, q, yes: false, sats: 1000);
      expect(state().wagers.where((w) => w.matched), isEmpty);
    });

    test('Ein Angebot ohne Gegenseite verfällt mit der Auflösung', () async {
      await t.bet(t.anna, q, yes: true);
      await oracle.reveal(commitment, yes: true);
      expect(state().wagers, isEmpty);
      expect(state().open, isEmpty);
    });

    test('Nach Marktschluss, ohne Platz oder mit Unsinn gewettet zählt nicht', () async {
      final stranger = KeyDeckelSigner()..clock = () => t.now;
      t.events.add(await stranger.sign(betDraft(deckelId: _deckel, questionId: q, yes: true, sats: 2000)));
      await t.sign(t.anna, betDraft(deckelId: _deckel, questionId: q, yes: true, sats: 0));
      await t.sign(t.anna, const DeckelDraft(kind: kDeckelBet, tags: [
        ['d', _deckel],
        ['e', 'kurz'],
        ['side', 'vielleicht'],
        ['amount', '2000'],
      ]));
      t.now += 4000; // der Markt ist zu
      await t.bet(t.ben, q, yes: false);

      expect(state().wagers, isEmpty);
    });

    test('Ohne Orakel bleiben Wetten offen, nichts wird zur Schuld', () async {
      await t.bet(t.anna, q, yes: true);
      await t.bet(t.ben, q, yes: false);
      await oracle.reveal(commitment, yes: true);

      final blind = reduceDeckel(_deckel, t.events);
      expect(blind.wagers.single.matched, isTrue);
      expect(blind.open, isEmpty);
    });
  });

  group('Wetten am Tisch', () {
    test('Frage sehen, wetten, das Orakel löst auf, Kassensturz', () async {
      var now = 1790000000;
      final oracle = _Oracle()..now = now;
      final feed = MemoryOracle(oracle.key)..share = 0.55;
      final backend = MemoryDeckelBackend();
      final money = PlayMoney();

      DeckelTable guest() {
        final signer = KeyDeckelSigner()..clock = () => ++now;
        return DeckelTable(
          deckelId: _deckel,
          name: 'Stammtisch',
          backend: backend,
          signer: signer,
          purse: PlayPurse(money, 21000),
          ledger: DeckelLedger(store: MemoryDeckelLedgerStore()),
          oracle: feed,
          clock: () => now,
          oracleEvery: const Duration(hours: 1),
        );
      }

      final anna = guest();
      final ben = guest();
      await anna.open();
      await ben.open();
      await anna.sit('Anna');
      await ben.sit('Ben');

      // Noch keine Frage: wetten geht nicht.
      expect(anna.question, isNull);
      expect(await anna.bet(yes: true, sats: 2000), isFalse);

      final commitment = await oracle.commit();
      feed.published.addAll(oracle.events);
      await anna.refreshOracle();
      await ben.refreshOracle();
      expect(anna.question!.strike, 86000);
      expect(anna.yesShare, 0.55);

      expect(await anna.bet(yes: true, sats: 2000), isTrue);
      expect(await ben.bet(yes: false, sats: 2000), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(anna.state.wagers.single.matched, isTrue);
      expect(anna.myBalance, 0);

      // Der Markt schließt, das Orakel löst auf: Ja.
      now += 4000;
      await oracle.reveal(commitment, yes: true);
      feed.published
        ..clear()
        ..addAll(oracle.events);
      await anna.refreshOracle();
      await ben.refreshOracle();
      expect(anna.question, isNull);
      expect(anna.myBalance, 2000);
      expect(ben.myBalance, -2000);
      expect(anna.questionOf(commitment['id'] as String)!.strike, 86000);

      expect(await ben.closeTab(), isTrue);
      await Future<void>.delayed(Duration.zero);
      final due = ben.myDues.single;
      expect(due.sats, 2000);
      expect(await anna.redeem(due, await ben.pay(due)), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(ben.state.closing!.settled, isTrue);

      anna.dispose();
      ben.dispose();
      await backend.close();
    });

    test('Nach Marktschluss nimmt der Tisch keine Wette mehr an', () async {
      var now = 1790000000;
      final oracle = _Oracle()..now = now;
      await oracle.commit(closesIn: 100);
      final feed = MemoryOracle(oracle.key)..published.addAll(oracle.events);
      final backend = MemoryDeckelBackend();
      final table = DeckelTable(
        deckelId: _deckel,
        name: 'Stammtisch',
        backend: backend,
        signer: KeyDeckelSigner(),
        purse: PlayPurse(PlayMoney(), 1000),
        ledger: DeckelLedger(store: MemoryDeckelLedgerStore()),
        oracle: feed,
        clock: () => now,
        oracleEvery: const Duration(hours: 1),
      );
      await table.open();
      await table.sit('Anna');
      await table.refreshOracle();
      expect(table.question, isNotNull);

      now += 200;
      expect(await table.bet(yes: true, sats: 500), isFalse);
      table.dispose();
      await backend.close();
    });
  });
}
