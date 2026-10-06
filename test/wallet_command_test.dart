import 'package:einundzwanzig_meetup_app/services/voice_wallet/wallet_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WalletCommandKind kind(String words) => parseWalletCommand(words).kind;
  int? sats(String words) => parseWalletCommand(words).sats;

  test('Kontostand und Balance', () {
    expect(kind('Wie ist der Kontostand?'), WalletCommandKind.balance);
    expect(kind("what's my balance"), WalletCommandKind.balance);
    expect(kind('how much do I have'), WalletCommandKind.balance);
  });

  test('Scannen', () {
    expect(kind('Token scannen'), WalletCommandKind.scan);
    expect(kind('scanne token'), WalletCommandKind.scan);
    expect(kind('scan the token'), WalletCommandKind.scan);
    expect(kind('token'), WalletCommandKind.scan);
    expect(kind('Kamera'), WalletCommandKind.scan);
    expect(kind('QR-Code'), WalletCommandKind.scan);
    expect(kind('empfangen'), WalletCommandKind.scan);
    expect(kind('schick den token'), WalletCommandKind.send);
    expect(kind('token senden'), WalletCommandKind.send);
    expect(kind('sats senden'), WalletCommandKind.send);
    expect(kind('tokensenden'), WalletCommandKind.send);
    expect(kind('Einfügen'), WalletCommandKind.paste);
    expect(kind('Galerie'), WalletCommandKind.gallery);
    expect(kind('Bild einfügen'), WalletCommandKind.gallery);
    expect(kind('Foto'), WalletCommandKind.scan);
  });

  test('Senden mit Ziffern und Zahlwoertern', () {
    expect(sats('schick 1000 sats'), 1000);
    expect(sats('schick 1.000 Sats'), 1000);
    expect(sats('sende einundzwanzig sats'), 21);
    expect(sats('send twenty one sats'), 21);
    expect(sats('send two thousand sats'), 2000);
    expect(sats('schick zweitausend'), 2000);
    expect(sats('pay a hundred'), 100);
    expect(kind('schick'), WalletCommandKind.send);
    expect(sats('schick'), isNull);
  });

  test('Bestaetigen, abbrechen, Hilfe, unbekannt', () {
    expect(kind('ja'), WalletCommandKind.confirm);
    expect(kind('yes'), WalletCommandKind.confirm);
    expect(kind('nein'), WalletCommandKind.cancel);
    expect(kind('Hilfe'), WalletCommandKind.help);
    expect(kind('hello there'), WalletCommandKind.unknown);
    expect(parseWalletCommand('nur Ton').output, WalletOutput.sound);
    expect(parseWalletCommand('nur Text').output, WalletOutput.text);
    expect(parseWalletCommand('Beides').output, WalletOutput.both);
    expect(parseWalletCommand('no text').output, WalletOutput.sound);
    expect(parseWalletCommand('mute').output, WalletOutput.text);
    expect(kind('ja'), WalletCommandKind.confirm);
  });

  test('Eine gesprochene Summe ueber ein Bitcoin wird nicht angenommen', () {
    expect(parseSpokenSats('send 100000001 sats'), isNull);
  });

  test('Bark und Cashu', () {
    final bark = parseWalletCommand('Bark');
    expect(bark.kind, WalletCommandKind.rail);
    expect(bark.rail, WalletRail.bark);
    expect(parseWalletCommand('Ark Wallet').rail, WalletRail.bark);
    expect(parseWalletCommand('Cashu').rail, WalletRail.cashu);
    final both = parseWalletCommand('Bark Kontostand');
    expect(both.kind, WalletCommandKind.balance);
    expect(both.rail, WalletRail.bark);
    expect(parseWalletCommand('empfangen').kind, WalletCommandKind.scan);
    expect(
      parseWalletCommand('empfangen', rail: WalletRail.bark).kind,
      WalletCommandKind.address,
    );
    final invoice = parseWalletCommand('Bark empfangen zweitausend');
    expect(invoice.kind, WalletCommandKind.invoice);
    expect(invoice.sats, 2000);
    expect(parseWalletCommand('Rechnung 2100').kind, WalletCommandKind.invoice);
    expect(parseWalletCommand('Rechnung 2100').sats, 2100);
    expect(parseWalletCommand('Adresse').kind, WalletCommandKind.address);
    expect(parseWalletCommand('bezahlen').kind, WalletCommandKind.pay);
    expect(parseWalletCommand('auszahlen 5000').sats, 5000);
    expect(parseWalletCommand('pay a hundred').kind, WalletCommandKind.send);
    expect(parseWalletCommand('pay the invoice').kind, WalletCommandKind.pay);
  });
}
