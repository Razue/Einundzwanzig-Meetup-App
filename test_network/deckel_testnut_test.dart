// Der ganze Abend gegen einen echten Mint — mit Spiel-Sats.
//
// testnut.cashu.space markiert jede Lightning-Rechnung als bezahlt und gibt
// dafür Token aus. Die Token sind nichts wert, aber der Mint verhält sich
// wie ein echter: Er signiert blind, lehnt doppeltes Einlösen ab und nimmt
// eine Gebühr je Eingabe. Der Test braucht Netz und läuft deshalb nicht mit
// der normalen Suite:
//
//   flutter test test_network/deckel_testnut_test.dart

import 'dart:convert';

import 'package:einundzwanzig_meetup_app/services/deckel/deckel_backend.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_ledger.dart';
import 'package:einundzwanzig_meetup_app/services/deckel/deckel_table.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_crypto.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_mint.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_token.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_wallet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _mint = 'https://testnut.cashu.space';
const _deckel = 'testnut01';

/// Holt beim Test-Mint einen Token über [sats] (NUT-04).
Future<String> _mintToken(int sats) async {
  final snapshot = await HttpsCashuMint().snapshot(_mint);
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_mint$path'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) fail('$path: ${response.statusCode} ${response.body}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  final quote = await post('/v1/mint/quote/bolt11', {'amount': sats, 'unit': 'sat'});
  final id = quote['quote'] as String;
  for (var i = 0; i < 20; i++) {
    final state = await http.get(Uri.parse('$_mint/v1/mint/quote/bolt11/$id'));
    if ((jsonDecode(state.body) as Map)['state'] == 'PAID') break;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  final amounts = splitCashuAmount(sats, snapshot.keys.keys.toSet())..sort();
  final blinded = [for (final _ in amounts) blindSecret()];
  final minted = await post('/v1/mint/bolt11', {
    'quote': id,
    'outputs': [
      for (var i = 0; i < amounts.length; i++)
        {'amount': amounts[i], 'id': snapshot.activeId, 'B_': blinded[i].blinded},
    ],
  });
  final signatures = minted['signatures'] as List;
  return encodeCashuToken(
    mint: _mint,
    proofs: [
      for (var i = 0; i < amounts.length; i++)
        CashuProof(
          amount: amounts[i],
          id: signatures[i]['id'] as String,
          secret: blinded[i].secret,
          c: unblindSignature(
            blindedSignature: signatures[i]['C_'] as String,
            r: blinded[i].r,
            mintKey: snapshot.keys[amounts[i]]!,
          ),
        ),
    ],
  );
}

class _Guest {
  final KeyDeckelSigner signer = KeyDeckelSigner();
  final CashuWallet wallet = CashuWallet(store: MemoryProofStore());
  late final DeckelTable table;

  _Guest(MemoryDeckelBackend backend) {
    table = DeckelTable(
      deckelId: _deckel,
      name: 'Testnut',
      backend: backend,
      signer: signer,
      purse: CashuDeckelPurse(wallet),
      ledger: DeckelLedger(store: MemoryDeckelLedgerStore()),
    );
  }
}

void main() {
  test('Bier, Pizza, Taxi: zwei Zahlungen über einen echten Mint', () async {
    final backend = MemoryDeckelBackend();
    final anna = _Guest(backend);
    final ben = _Guest(backend);
    final clara = _Guest(backend);
    for (final guest in [anna, ben, clara]) {
      await guest.table.open();
    }
    await anna.table.sit('Anna');
    await ben.table.sit('Ben');
    await clara.table.sit('Clara');

    // Clara und Ben haben etwas in der Wallet, Anna nichts.
    final claraStart = (await clara.wallet.receive(await _mintToken(4096))).balance;
    final benStart = (await ben.wallet.receive(await _mintToken(512))).balance;
    printOnFailure('Start: Clara $claraStart, Ben $benStart');
    expect(claraStart, greaterThanOrEqualTo(4090));

    expect(await anna.table.addRound(sats: 12600, subject: 'Bier'), isTrue);
    expect(await ben.table.addRound(sats: 9000, subject: 'Pizza'), isTrue);
    expect(await clara.table.addRound(sats: 6000, subject: 'Taxi'), isTrue);
    expect(await ben.table.closeTab(), isTrue);

    final claraDue = clara.table.myDues.single;
    final benDue = ben.table.myDues.single;
    expect(claraDue.sats, 3200);
    expect(benDue.sats, 200);

    // Clara zahlt; zweimal tippen gibt denselben Token.
    final token = await clara.table.pay(claraDue);
    expect(await clara.table.pay(claraDue), token);
    final claraAfter = await clara.wallet.balance();
    expect(claraStart - claraAfter, inInclusiveRange(3200, 3205), reason: 'Betrag plus Gebühr des Mints');

    // Anna löst ein und quittiert. Dieselbe Quittung ein zweites Mal ändert nichts am Geld.
    expect(await anna.table.redeem(claraDue, token), isNull);
    final annaAfterClara = await anna.wallet.balance();
    expect(annaAfterClara, inInclusiveRange(3195, 3200), reason: 'Betrag minus Gebühr des Mints');
    expect(await anna.table.redeem(claraDue, token), isNull);
    expect(await anna.wallet.balance(), annaAfterClara);

    // Der Mint kennt den Token als verbraucht: ein Dritter bekommt ihn nicht.
    expect(() => ben.wallet.receive(token), throwsA(isA<CashuException>()));

    expect(await anna.table.redeem(benDue, await ben.table.pay(benDue)), isNull);
    await Future<void>.delayed(Duration.zero);

    for (final guest in [anna, ben, clara]) {
      expect(guest.table.state.closing!.settled, isTrue);
    }
    final annaEnd = await anna.wallet.balance();
    expect(annaEnd, inInclusiveRange(3390, 3400));
    // ignore: avoid_print
    print('Testnut: Clara $claraStart -> $claraAfter, Ben $benStart -> ${await ben.wallet.balance()}, Anna 0 -> $annaEnd');

    for (final guest in [anna, ben, clara]) {
      guest.table.dispose();
    }
    await backend.close();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
