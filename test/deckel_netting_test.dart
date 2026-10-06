import 'dart:math';

import 'package:einundzwanzig_meetup_app/services/deckel/deckel_netting.dart';
import 'package:flutter_test/flutter_test.dart';

DeckelRound _round(String id, String payer, int sats, List<String> sharers) =>
    DeckelRound(id: id, payer: payer, sats: sats, sharers: sharers);

void main() {
  const table = ['anna', 'ben', 'clara'];

  // Der Abend aus der Vorführung: Bier, Pizza, Taxi.
  final evening = [
    _round('1', 'anna', 12600, table),
    _round('2', 'ben', 9000, table),
    _round('3', 'clara', 6000, table),
  ];

  test('Drei Runden: sechs Schulden werden zwei Zahlungen', () {
    expect(balancesOf(evening), {'anna': 3400, 'ben': -200, 'clara': -3200});
    expect(settle(balancesOf(evening)), const [
      DeckelPayment(from: 'clara', to: 'anna', sats: 3200),
      DeckelPayment(from: 'ben', to: 'anna', sats: 200),
    ]);

    final summary = DeckelSummary.of(evening);
    expect(summary.debts, 6);
    expect(summary.debtSats, 18400);
    expect(summary.payments, 2);
    expect(summary.paymentSats, 3400);
  });

  test('Im Kreis geschuldet: wer gleich viel bekommt wie schuldet, zahlt nichts', () {
    // A schuldet B 5.000, B schuldet C 5.000, C schuldet A 3.000.
    final rounds = [
      _round('1', 'b', 5000, ['a']),
      _round('2', 'c', 5000, ['b']),
      _round('3', 'a', 3000, ['c']),
    ];
    expect(debtsOf(rounds).fold<int>(0, (sum, d) => sum + d.sats), 13000);
    expect(settle(balancesOf(rounds)), const [
      DeckelPayment(from: 'a', to: 'c', sats: 2000),
    ]);
  });

  test('Der Rest beim Teilen bleibt beim Zahler', () {
    final rounds = [_round('1', 'anna', 100, table)];
    expect(rounds.single.share, 33);
    expect(balancesOf(rounds), {'anna': 66, 'ben': -33, 'clara': -33});
  });

  test('Wer zahlt, ohne mitzutrinken, bekommt alles zurück', () {
    final rounds = [
      _round('1', 'anna', 9000, ['ben', 'clara']),
    ];
    expect(balancesOf(rounds), {'anna': 9000, 'ben': -4500, 'clara': -4500});
  });

  test('Eine Runde nur für sich selbst ändert nichts', () {
    expect(balancesOf([_round('1', 'anna', 5000, ['anna'])]), isEmpty);
    expect(settle(const {}), isEmpty);
  });

  test('Die Reihenfolge der Runden ändert die Zahlungsliste nicht', () {
    final forward = settle(balancesOf(evening));
    final backward = settle(balancesOf(evening.reversed));
    expect(backward, forward);
  });

  test('Gleiche Beträge: der Schlüssel entscheidet, nicht der Zufall', () {
    final balances = {'d': -500, 'c': -500, 'b': 500, 'a': 500};
    expect(settle(balances), const [
      DeckelPayment(from: 'c', to: 'a', sats: 500),
      DeckelPayment(from: 'd', to: 'b', sats: 500),
    ]);
    final shuffled = Map.fromEntries(balances.entries.toList().reversed);
    expect(settle(shuffled), settle(balances));
  });

  test('Zufällige Abende: Salden ergeben null, Zahlungen gleichen genau aus', () {
    final random = Random(21);
    for (var evening = 0; evening < 200; evening++) {
      final heads = [for (var i = 0; i < 2 + random.nextInt(7); i++) 'p$i'];
      final rounds = [
        for (var i = 0; i < 1 + random.nextInt(12); i++)
          _round(
            '$i',
            heads[random.nextInt(heads.length)],
            1 + random.nextInt(50000),
            [...heads]..shuffle(random),
          ),
      ];
      final balances = balancesOf(rounds);
      expect(balances.values.fold<int>(0, (sum, v) => sum + v), 0);

      final payments = settle(balances);
      final after = Map.of(balances);
      for (final p in payments) {
        expect(p.sats, greaterThan(0));
        after[p.from] = after[p.from]! + p.sats;
        after[p.to] = after[p.to]! - p.sats;
      }
      expect(after.values.every((v) => v == 0), isTrue);
      expect(payments.length, lessThan(heads.length));
      expect(
        payments.fold<int>(0, (sum, p) => sum + p.sats),
        lessThanOrEqualTo(debtsOf(rounds).fold<int>(0, (sum, d) => sum + d.sats)),
      );
    }
  });
}
