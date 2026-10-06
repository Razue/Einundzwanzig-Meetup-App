import 'package:einundzwanzig_meetup_app/services/deckel/deckel_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DeckelCommand p(String words) => parseDeckelCommand(words);

  test('Eine Runde mit Betrag und Zweck', () {
    final c = p('Runde 12600 für Bier');
    expect(c.kind, DeckelCommandKind.round);
    expect(c.sats, 12600);
    expect(c.perHead, isFalse);
    expect(c.subject, 'Bier');
  });

  test('Betrag mit Tausenderpunkt und in Worten', () {
    expect(p('Runde 12.600').sats, 12600);
    expect(p('runde zwölftausend sechshundert für pizza').sats, 12600);
    expect(p('round twelve thousand for beer').sats, 12000);
    expect(p('round twelve thousand for beer').subject, 'Beer');
  });

  test('Pro Kopf', () {
    final c = p('4200 pro Kopf für Bier');
    expect(c.kind, DeckelCommandKind.round);
    expect(c.sats, 4200);
    expect(c.perHead, isTrue);
    expect(c.subject, 'Bier');

    expect(p('3000 each for pizza').perHead, isTrue);
    expect(p('Runde 3000 für Pizza pro Nase').subject, 'Pizza');
  });

  test('Eine Zahl allein reicht zum Anschreiben', () {
    final c = p('9000');
    expect(c.kind, DeckelCommandKind.round);
    expect(c.sats, 9000);
    expect(c.subject, '');
  });

  test('"Eine Runde" ist kein Betrag von einem Sat', () {
    final c = p('eine Runde');
    expect(c.kind, DeckelCommandKind.round);
    expect(c.sats, isNull);

    expect(p('a round for beer').sats, isNull);
    expect(p('a round for beer').subject, 'Beer');
    expect(p('eine Runde 6000 für Taxi').sats, 6000);
  });

  test('Zweck: Umlaute bleiben, Zahlen und Einheiten fallen weg', () {
    expect(p('Runde 5000 für Kölsch und Brötchen').subject, 'Kölsch und Brötchen');
    expect(p('Runde für Bier 5000 Sats').subject, 'Bier');
    expect(p('Runde 5000').subject, '');
  });

  test('Stand, Kassensturz, Zahlen, Einlösen', () {
    expect(p('Deckel').kind, DeckelCommandKind.balance);
    expect(p('Was steht auf meinem Deckel').kind, DeckelCommandKind.balance);
    expect(p('how much do I owe').kind, DeckelCommandKind.balance);

    expect(p('Kassensturz').kind, DeckelCommandKind.close);
    expect(p('Bitte abrechnen').kind, DeckelCommandKind.close);
    expect(p('settle up').kind, DeckelCommandKind.close);

    expect(p('Zahlen').kind, DeckelCommandKind.pay);
    expect(p('Ich will bezahlen').kind, DeckelCommandKind.pay);
    expect(p('pay').kind, DeckelCommandKind.pay);

    expect(p('Einlösen').kind, DeckelCommandKind.redeem);
    expect(p('scannen').kind, DeckelCommandKind.redeem);
    expect(p('receive').kind, DeckelCommandKind.redeem);
  });

  test('Wetten: Betrag und Seite', () {
    final c = p('Wette 2000 auf Ja');
    expect(c.kind, DeckelCommandKind.bet);
    expect(c.sats, 2000);
    expect(c.yes, isTrue);

    expect(p('Wette zweitausend auf nein').yes, isFalse);
    expect(p('Wette zweitausend auf nein').sats, 2000);
    expect(p('bet 500 on yes').yes, isTrue);
    expect(p('ich wette 1000 dass es drüber ist').yes, isTrue);
    expect(p('Wette 1000 drunter').yes, isFalse);
  });

  test('Wette ohne Seite oder ohne Betrag bleibt eine Wette, die nachfragt', () {
    expect(p('Wette 2000').kind, DeckelCommandKind.bet);
    expect(p('Wette 2000').yes, isNull);
    expect(p('Wette auf ja').kind, DeckelCommandKind.bet);
    expect(p('Wette auf ja').sats, isNull);
    expect(p('wetten').kind, DeckelCommandKind.bet);
  });

  test('Ja und Nein allein bleiben Antwort, keine Wette', () {
    expect(p('ja').kind, DeckelCommandKind.confirm);
    expect(p('nein').kind, DeckelCommandKind.cancel);
    // Eine Runde, in der das Wort Wette nicht vorkommt, bleibt eine Runde.
    expect(p('Runde 2000 für Bier').kind, DeckelCommandKind.round);
  });

  test('Ja, Nein, Hilfe', () {
    expect(p('Ja').kind, DeckelCommandKind.confirm);
    expect(p('stimmt').kind, DeckelCommandKind.confirm);
    expect(p('Nein').kind, DeckelCommandKind.cancel);
    expect(p('abbrechen bitte').kind, DeckelCommandKind.cancel);
    expect(p('Hilfe').kind, DeckelCommandKind.help);
  });

  test('Ein Wortteil ist kein Befehl', () {
    // "Standard" enthält "stand", "Zahlenspiel" enthält "zahlen".
    expect(p('Standard').kind, DeckelCommandKind.unknown);
    expect(p('Zahlenspiel').kind, DeckelCommandKind.unknown);
    expect(p('').kind, DeckelCommandKind.unknown);
    expect(p('Guten Abend zusammen').kind, DeckelCommandKind.unknown);
  });
}
