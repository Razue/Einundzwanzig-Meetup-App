import 'dart:typed_data';

import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_crypto.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_mint.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_token.dart';

/// Ein Mint im Speicher, der wirklich blind signiert und doppeltes Einlösen
/// ablehnt. Wie in cashu_wallet_test.dart, hier zum Teilen zwischen Tests.
class FakeCashuMint implements CashuMintClient {
  static const url = 'https://mint.test';

  final BigInt key = BigInt.parse('7', radix: 16);
  late final String pub = publicFromPrivate(key);
  final Set<String> spent = {};
  int swaps = 0;

  CashuProof issue(int amount) {
    final blinded = blindSecret();
    final signature = signBlindedMessage(blinded: blinded.blinded, privateKey: key);
    return CashuProof(
      amount: amount,
      id: '00',
      secret: blinded.secret,
      c: unblindSignature(blindedSignature: signature, r: blinded.r, mintKey: pub),
    );
  }

  /// Ein Token über [sats], in Zweierpotenzen gestückelt.
  String tokenOf(int sats) => encodeCashuToken(
        mint: url,
        proofs: [
          for (var bit = 0; bit <= 30; bit++)
            if (sats & (1 << bit) != 0) issue(1 << bit),
        ],
      );

  @override
  Future<({String id, int ppk})?> identifyKeyset(String mintUrl, String id) async => null;

  @override
  Future<MintSnapshot> snapshot(String mintUrl) async {
    return MintSnapshot(
      activeId: '00',
      keys: {for (var bit = 0; bit <= 30; bit++) 1 << bit: pub},
      feePpk: const {'00': 0},
      keysetIds: const {'00'},
    );
  }

  @override
  Future<List<BlindSignature>> swap({
    required String mintUrl,
    required List<CashuProof> inputs,
    required List<BlindedOutput> outputs,
  }) async {
    swaps++;
    final inSum = inputs.fold(0, (sum, p) => sum + p.amount);
    final outSum = outputs.fold(0, (sum, p) => sum + p.amount);
    if (inSum != outSum) throw const CashuException(CashuFail.mintRejected);
    for (final input in inputs) {
      if (spent.contains(input.secret)) throw const CashuException(CashuFail.spent);
      final expected = signBlindedMessage(
        blinded: encodePoint(hashToCurve(Uint8List.fromList(input.secret.codeUnits))),
        privateKey: key,
      );
      if (expected != input.c) throw const CashuException(CashuFail.mintRejected);
    }
    spent.addAll(inputs.map((p) => p.secret));
    return [
      for (final output in outputs)
        BlindSignature(
          amount: output.amount,
          id: '00',
          cBlind: signBlindedMessage(blinded: output.blinded, privateKey: key),
        ),
    ];
  }
}
