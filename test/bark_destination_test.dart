import 'package:einundzwanzig_meetup_app/services/voice_wallet/bark_destination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BOLT11 Betrag aus dem Vorspann', () {
    final invoice = parsePayDestination('bitte lnbc210n1p4txxxx zahlen');
    expect(invoice, isNotNull);
    expect(invoice!.kind, PayKind.bolt11);
    expect(invoice.amountSat, 21);
    expect(invoice.needsAmount, isFalse);

    final bigger = parsePayDestination('LNBC250U1PEXAMPLE');
    expect(bigger!.amountSat, 25000);

    final open = parsePayDestination('lnbc1pamountless');
    expect(open!.kind, PayKind.bolt11);
    expect(open.amountSat, isNull);
    expect(open.needsAmount, isTrue);
  });

  test('Ark, Kette, Lightning-Adresse und BIP 321', () {
    expect(parsePayDestination('ark1qqexample')!.kind, PayKind.ark);
    expect(parsePayDestination('bc1qexample')!.kind, PayKind.onchain);
    expect(
      parsePayDestination('alice@example.com')!.kind,
      PayKind.lightningAddress,
    );
    final uri = parsePayDestination('bitcoin:bc1qexample?amount=0.00002100');
    expect(uri!.kind, PayKind.bip321);
    expect(uri.amountSat, 2100);
    expect(parsePayDestination('hallo'), isNull);
  });
}
