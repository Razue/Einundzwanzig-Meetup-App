import 'package:einundzwanzig_meetup_app/services/deckel/deckel_demo.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wartet, bis [done] wahr ist. Die Gäste handeln auf Timern; wie lange das
/// Signieren dazwischen dauert, hängt vom Rechner ab.
Future<void> _until(bool Function() done, {String? what}) async {
  for (var i = 0; i < 400; i++) {
    if (done()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Nicht eingetreten: ${what ?? 'Bedingung'}');
}

const _pace = Duration(milliseconds: 30);

void main() {
  test('Spielgeld lässt sich nur einmal einlösen', () async {
    final money = PlayMoney();
    final anna = PlayPurse(money, 1000);
    final ben = PlayPurse(money, 0);

    final token = await anna.token(400);
    expect(await anna.balance(), 600);
    expect(ben.amountOf(token), 400);
    expect(await ben.redeem(token), 400);
    expect(await ben.balance(), 400);
    expect(() => ben.redeem(token), throwsStateError);
    expect(() => anna.token(601), throwsStateError);
    expect(ben.amountOf('cashuAirgendwas'), isNull);
  });

  test('Demo-Tisch: Gäste setzen sich, legen aus und warten dann auf den Menschen', () async {
    final demo = DeckelDemo(pace: _pace);
    await demo.start(myName: 'Du');
    await _until(() => demo.me.state.open.length == 2, what: 'zwei Runden');

    expect(demo.me.state.seats.values, containsAll(['Du', 'Anna', 'Ben']));
    // Beide Runden fallen hier in dieselbe Sekunde; dann ordnet die Kennung.
    expect(demo.me.state.open.map((r) => r.subject), unorderedEquals(['Bier', 'Pizza']));
    expect(demo.me.myBalance, -7200);

    await Future<void>.delayed(_pace * 4);
    expect(demo.me.state.open, hasLength(2), reason: 'ohne Selbstläufer tun die Gäste nichts weiter');
    expect(demo.me.state.closing, isNull);
    await demo.stop();
  });

  test('Nach dem Kassensturz zahlen die Gäste von selbst und lösen ein, was man ihnen zeigt', () async {
    final demo = DeckelDemo(pace: _pace);
    await demo.start(myName: 'Du');
    await _until(() => demo.me.state.open.length == 2, what: 'zwei Runden');
    await demo.me.addRound(sats: 6000, subject: 'Taxi');
    await demo.me.closeTab();

    final mine = demo.me.myDues.single;
    expect(mine.sats, 3200);
    await _until(
      () => demo.me.state.closing!.payments.where(demo.me.state.closing!.paid).length == 1,
      what: 'Ben zahlt Anna',
    );

    demo.showToGuest(mine, await demo.me.pay(mine));
    await _until(() => demo.me.state.closing!.settled, what: 'Anna quittiert');
    expect(await demo.me.walletBalance(), 21000 - 3200);
    await demo.stop();
  });

  test('Demo-Orakel: Ben hält gegen die Wette, das Orakel sagt Ja, die Wette wird zur Schuld', () async {
    final demo = DeckelDemo(pace: _pace);
    await demo.start(myName: 'Du');
    await _until(() => demo.me.state.open.length == 2, what: 'zwei Runden');
    expect(demo.me.question!.strike, 86000);
    expect(demo.me.yesShare, 0.55);

    expect(await demo.me.bet(yes: true, sats: 2000), isTrue);
    await _until(() => demo.me.state.wagers.any((w) => w.matched), what: 'Ben hält dagegen');
    await _until(() => demo.me.state.open.any((r) => r.bet), what: 'das Orakel löst auf');

    final won = demo.me.state.open.singleWhere((r) => r.bet);
    expect(won.payer, demo.me.me);
    expect(won.sats, 2000);
    expect(demo.me.myBalance, -7200 + 2000);
    expect(demo.me.state.wagers, isEmpty);
    expect(demo.me.question, isNull, reason: 'die Frage ist entschieden');
    await demo.stop();
  });

  test('Selbstläufer: der ganze Abend ohne einen Tipp', () async {
    final demo = DeckelDemo(pace: _pace, autoplay: true);
    await demo.start(myName: 'Du');
    await _until(() => demo.me.state.closing?.settled ?? false, what: 'alles beglichen');

    final summary = demo.me.state.closing!.summary;
    expect(summary.debts, 6);
    expect(summary.debtSats, 18400);
    expect(summary.payments, 2);
    expect(summary.paymentSats, 3400);
    await demo.stop();
  });

  test('Wer den Tisch verlässt, bevor die Gäste fertig sind, bekommt keine Nachzügler', () async {
    final demo = DeckelDemo(pace: _pace, autoplay: true);
    await demo.start(myName: 'Du');
    await demo.stop();
    await Future<void>.delayed(_pace * 14);
    expect(demo.backend.events, hasLength(1), reason: 'nur der eigene Platz');
  });
}
