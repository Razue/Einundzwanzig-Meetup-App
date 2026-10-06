import 'package:einundzwanzig_meetup_app/services/deckel/deckel_backend.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_events.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_ledger.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_netting.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_table.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_cashu_mint.dart';

const _deckel = 'stammtisch01';

/// Ein Teilnehmer mit eigenem Schlüssel, eigener Wallet und eigenem Buch.
class _Guest {
  final KeyDeckelSigner signer = KeyDeckelSigner();
  final CashuWallet wallet;
  final MemoryDeckelLedgerStore ledgerStore = MemoryDeckelLedgerStore();
  late final DeckelTable table;

  _Guest(MemoryDeckelBackend backend, FakeCashuMint mint, int Function() clock)
      : wallet = CashuWallet(store: MemoryProofStore(), mint: mint) {
    signer.clock = clock;
    table = DeckelTable(
      deckelId: _deckel,
      name: 'Stammtisch',
      backend: backend,
      signer: signer,
      purse: CashuDeckelPurse(wallet),
      ledger: DeckelLedger(store: ledgerStore),
    );
  }

  String get key => signer.public;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MemoryDeckelBackend backend;
  late FakeCashuMint mint;
  late _Guest anna;
  late _Guest ben;
  late _Guest clara;
  var now = 1790000000;

  setUp(() async {
    backend = MemoryDeckelBackend();
    mint = FakeCashuMint();
    int clock() => ++now;
    anna = _Guest(backend, mint, clock);
    ben = _Guest(backend, mint, clock);
    clara = _Guest(backend, mint, clock);
    for (final guest in [anna, ben, clara]) {
      await guest.table.open();
    }
    expect(await anna.table.sit('Anna'), isTrue);
    expect(await ben.table.sit('Ben'), isTrue);
    expect(await clara.table.sit('Clara'), isTrue);
    await _settle();
  });

  tearDown(() async {
    for (final guest in [anna, ben, clara]) {
      guest.table.dispose();
    }
    await backend.close();
  });

  Future<void> evening() async {
    expect(await anna.table.addRound(sats: 12600, subject: 'Bier'), isTrue);
    await _settle();
    expect(await ben.table.addRound(sats: 9000, subject: 'Pizza'), isTrue);
    await _settle();
    expect(await clara.table.addRound(sats: 6000, subject: 'Taxi'), isTrue);
    await _settle();
  }

  test('Alle am Tisch sehen denselben Stand', () async {
    await evening();

    for (final guest in [anna, ben, clara]) {
      expect(guest.table.state.seats.length, 3);
      expect(guest.table.state.open.map((r) => r.subject), ['Bier', 'Pizza', 'Taxi']);
    }
    expect(anna.table.myBalance, 3400);
    expect(ben.table.myBalance, -200);
    expect(clara.table.myBalance, -3200);
  });

  test('Betrag pro Kopf wird mit den Köpfen am Tisch malgenommen', () async {
    expect(await anna.table.addRound(sats: 4200, perHead: true), isTrue);
    await _settle();

    expect(ben.table.state.open.single.sats, 12600);
    expect(ben.table.myBalance, -4200);
  });

  test('Allein am Tisch gibt es nichts anzuschreiben', () async {
    final lonely = MemoryDeckelBackend();
    final solo = _Guest(lonely, mint, () => ++now);
    await solo.table.open();
    await solo.table.sit('Solo');

    expect(await solo.table.addRound(sats: 5000), isFalse);
    expect(await solo.table.closeTab(), isFalse);
    solo.table.dispose();
    await lonely.close();
  });

  test('Der ganze Abend: anschreiben, Kassensturz, zahlen, quittieren', () async {
    await clara.wallet.receive(mint.tokenOf(5000));
    await ben.wallet.receive(mint.tokenOf(1000));
    await evening();

    expect(await ben.table.closeTab(), isTrue);
    await _settle();

    final closing = anna.table.state.closing!;
    expect(closing.summary.debts, 6);
    expect(closing.summary.debtSats, 18400);
    expect(closing.summary.payments, 2);
    expect(closing.summary.paymentSats, 3400);
    expect(anna.table.state.open, isEmpty);

    final claraDue = clara.table.myDues.single;
    final benDue = ben.table.myDues.single;
    expect(claraDue, DeckelPayment(from: clara.key, to: anna.key, sats: 3200));
    expect(benDue, DeckelPayment(from: ben.key, to: anna.key, sats: 200));
    expect(anna.table.myClaims, [claraDue, benDue]);

    // Clara zahlt. Der Token verlässt ihre Wallet.
    final token = await clara.table.pay(claraDue);
    expect(await clara.wallet.balance(), 1800);

    // Anna löst ein und quittiert.
    expect(await anna.table.redeem(claraDue, token), isNull);
    await _settle();
    expect(await anna.wallet.balance(), 3200);
    for (final guest in [anna, ben, clara]) {
      expect(guest.table.state.closing!.paid(claraDue), isTrue);
      expect(guest.table.state.closing!.settled, isFalse);
    }

    // Ben zahlt, Anna löst ein: der Deckel ist ausgeglichen.
    expect(await anna.table.redeem(benDue, await ben.table.pay(benDue)), isNull);
    await _settle();
    expect(await anna.wallet.balance(), 3400);
    expect(await ben.wallet.balance(), 800);
    expect(clara.table.state.closing!.settled, isTrue);
  });

  test('Zweimal zahlen gibt denselben Token und nimmt nur einmal Geld', () async {
    await clara.wallet.receive(mint.tokenOf(8000));
    await evening();
    await anna.table.closeTab();
    await _settle();
    final due = clara.table.myDues.single;

    final swapsBefore = mint.swaps;
    final results = await Future.wait([clara.table.pay(due), clara.table.pay(due)]);
    final again = await clara.table.pay(due);

    expect(results[0], results[1]);
    expect(again, results[0]);
    expect(mint.swaps, swapsBefore + 1);
    expect(await clara.wallet.balance(), 4800);
  });

  test('Nach einem Neustart der App kommt derselbe Token wieder', () async {
    await clara.wallet.receive(mint.tokenOf(8000));
    await evening();
    await anna.table.closeTab();
    await _settle();
    final due = clara.table.myDues.single;
    final token = await clara.table.pay(due);

    // Neue Tisch-Instanz mit demselben Schlüssel, derselben Wallet, demselben Buch.
    final restarted = DeckelTable(
      deckelId: _deckel,
      name: 'Stammtisch',
      backend: backend,
      signer: clara.signer,
      purse: CashuDeckelPurse(clara.wallet),
      ledger: DeckelLedger(store: clara.ledgerStore),
    );
    await restarted.open();
    await _settle();

    expect(await restarted.pay(restarted.myDues.single), token);
    expect(await clara.wallet.balance(), 4800);
    restarted.dispose();
  });

  test('Zu wenig in der Wallet: nichts wird gemerkt, später geht es', () async {
    await evening();
    await anna.table.closeTab();
    await _settle();
    final due = clara.table.myDues.single;

    await expectLater(clara.table.pay(due), throwsA(isA<Object>()));
    expect(clara.ledgerStore.tokens, isEmpty);

    await clara.wallet.receive(mint.tokenOf(4000));
    final token = await clara.table.pay(due);
    expect(await anna.table.redeem(due, token), isNull);
  });

  test('Ein Token über den falschen Betrag wird nicht eingelöst und nicht quittiert', () async {
    await evening();
    await anna.table.closeTab();
    await _settle();
    final due = clara.table.myDues.single;

    expect(await anna.table.redeem(due, mint.tokenOf(100)), DeckelRedeemFail.wrongAmount);
    expect(await anna.table.redeem(due, 'kein token'), DeckelRedeemFail.notAToken);
    await _settle();
    expect(await anna.wallet.balance(), 0);
    expect(anna.table.state.closing!.paid(due), isFalse);
  });

  test('Ein schon eingelöster Token wird abgelehnt und nicht quittiert', () async {
    await clara.wallet.receive(mint.tokenOf(8000));
    await evening();
    await anna.table.closeTab();
    await _settle();
    final due = clara.table.myDues.single;
    final token = await clara.table.pay(due);
    await ben.wallet.receive(token); // jemand anderes war schneller

    expect(await anna.table.redeem(due, token), DeckelRedeemFail.rejected);
    await _settle();
    expect(anna.table.state.closing!.paid(due), isFalse);
  });

  test('Bar bezahlt: der Empfänger quittiert von Hand', () async {
    await evening();
    await anna.table.closeTab();
    await _settle();
    final due = ben.table.myDues.single;

    expect(await anna.table.confirmReceived(due), isTrue);
    await _settle();
    expect(ben.table.state.closing!.paid(due), isTrue);
    final receipt = backend.events.last;
    expect(receipt['kind'], kDeckelReceipt);
    expect((receipt['tags'] as List).any((t) => t[0] == 'rail' && t[1] == 'hand'), isTrue);
  });

  test('Fremde Zahlungen kann man weder leisten noch quittieren', () async {
    await evening();
    await anna.table.closeTab();
    await _settle();
    final claraDue = clara.table.myDues.single;

    expect(() => ben.table.pay(claraDue), throwsStateError);
    expect(() => ben.table.redeem(claraDue, 'x'), throwsStateError);
    expect(() => clara.table.confirmReceived(claraDue), throwsStateError);
  });

  test('Nach dem Kassensturz geht es auf einem neuen Blatt weiter', () async {
    await evening();
    await anna.table.closeTab();
    await _settle();
    await ben.table.addRound(sats: 3000, subject: 'Absacker');
    await _settle();

    expect(clara.table.state.open.single.subject, 'Absacker');
    expect(clara.table.myBalance, -1000);
    expect(clara.table.state.closing!.payments, hasLength(2));
  });
}
