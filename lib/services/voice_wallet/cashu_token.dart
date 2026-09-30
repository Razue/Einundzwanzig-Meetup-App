import 'dart:convert';
import 'dart:typed_data';

import 'cashu_cbor.dart';

/// Ein Proof. Das Geheimnis und `C` zusammen sind das Geld.
class CashuProof {
  final int amount;
  final String id;
  final String secret;
  final String c;
  final String? witness;

  const CashuProof({
    required this.amount,
    required this.id,
    required this.secret,
    required this.c,
    this.witness,
  });

  Map<String, Object> toJson() => {
        'amount': amount,
        'id': id,
        'secret': secret,
        'C': c,
        'witness': ?witness,
      };
}

/// Ein gelesener Token, noch nicht eingelöst.
class CashuToken {
  final String mint;
  final String unit;
  final List<CashuProof> proofs;

  const CashuToken({
    required this.mint,
    required this.unit,
    required this.proofs,
  });

  int get sats => proofs.fold(0, (sum, p) => sum + p.amount);
}

/// Was die Sprachseite anzeigen kann, ohne den Mint zu fragen.
class CashuPeek {
  final bool isCashu;
  final int? sats;

  const CashuPeek({required this.isCashu, this.sats});

  static const notToken = CashuPeek(isCashu: false);
}

CashuPeek peekCashuToken(String raw) {
  try {
    final token = parseCashuToken(raw);
    if (token.unit != 'sat') return const CashuPeek(isCashu: true);
    return CashuPeek(isCashu: true, sats: token.sats);
  } on FormatException {
    final text = raw.trim();
    if (text.startsWith('cashuA') ||
        text.startsWith('cashuB') ||
        text.startsWith('cashu:')) {
      return const CashuPeek(isCashu: true);
    }
    return CashuPeek.notToken;
  }
}

CashuToken parseCashuToken(String raw) {
  var text = raw.trim();
  if (text.startsWith('cashu:')) text = text.substring('cashu:'.length).trim();
  if (text.startsWith('cashuA')) return _parseV3(text.substring('cashuA'.length));
  if (text.startsWith('cashuB')) return _parseV4(text.substring('cashuB'.length));
  throw const FormatException('Kein Cashu-Token.');
}

String encodeCashuToken({required String mint, required List<CashuProof> proofs}) {
  final json = jsonEncode({
    'token': [
      {
        'mint': _mint(mint),
        'proofs': proofs.map((p) => p.toJson()).toList(),
      },
    ],
    'unit': 'sat',
  });
  final encoded = base64Url.encode(utf8.encode(json)).replaceAll('=', '');
  return 'cashuA$encoded';
}

CashuToken _parseV3(String payload) {
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload))));
  } catch (_) {
    throw const FormatException('cashuA ist kein Token.');
  }
  if (json is! Map) throw const FormatException('cashuA ist kein Token.');
  final unit = json['unit'] ?? 'sat';
  if (unit is! String) throw const FormatException('Einheit fehlt.');
  final entries = json['token'];
  if (entries is! List || entries.isEmpty) {
    throw const FormatException('Token ohne Proofs.');
  }
  if (entries.length != 1) {
    throw const FormatException('Mehrere Mints in einem Token.');
  }
  final entry = entries.first;
  if (entry is! Map) throw const FormatException('Token ohne Proofs.');
  final mint = entry['mint'];
  final proofs = entry['proofs'];
  if (mint is! String || proofs is! List || proofs.isEmpty) {
    throw const FormatException('Token ohne Proofs.');
  }
  return CashuToken(
    mint: _mint(mint),
    unit: unit,
    proofs: [
      for (final proof in proofs) _proofMap(proof),
    ],
  );
}

CashuToken _parseV4(String payload) {
  final Object? decoded;
  try {
    decoded = decodeCbor(Uint8List.fromList(base64Url.decode(base64Url.normalize(payload))));
  } catch (_) {
    throw const FormatException('cashuB ist kein Token.');
  }
  if (decoded is! Map) throw const FormatException('cashuB ist kein Token.');
  final mint = decoded['m'];
  final unit = decoded['u'];
  final groups = decoded['t'];
  if (mint is! String || unit is! String || groups is! List || groups.isEmpty) {
    throw const FormatException('cashuB ist kein Token.');
  }
  final proofs = <CashuProof>[];
  for (final group in groups) {
    if (group is! Map) throw const FormatException('cashuB ist kein Token.');
    final idBytes = group['i'];
    final list = group['p'];
    if (idBytes is! Uint8List || list is! List) {
      throw const FormatException('cashuB ist kein Token.');
    }
    final id = _hex(idBytes);
    for (final item in list) {
      if (item is! Map) throw const FormatException('cashuB ist kein Token.');
      final amount = item['a'];
      final secret = item['s'];
      final c = item['c'];
      final witness = item['w'];
      if (amount is! int || amount < 0 || secret is! String || c is! Uint8List) {
        throw const FormatException('cashuB ist kein Token.');
      }
      proofs.add(CashuProof(
        amount: amount,
        id: id,
        secret: secret,
        c: _hex(c),
        witness: witness is String ? witness : null,
      ));
    }
  }
  if (proofs.isEmpty) throw const FormatException('Token ohne Proofs.');
  return CashuToken(mint: _mint(mint), unit: unit, proofs: proofs);
}

CashuProof _proofMap(Object? raw) {
  if (raw is! Map) throw const FormatException('Proof unvollständig.');
  final amount = raw['amount'];
  final id = raw['id'];
  final secret = raw['secret'];
  final c = raw['C'];
  final witness = raw['witness'];
  if (amount is! int || amount < 0 || id is! String || secret is! String || c is! String) {
    throw const FormatException('Proof unvollständig.');
  }
  return CashuProof(
    amount: amount,
    id: id,
    secret: secret,
    c: c,
    witness: witness is String ? witness : null,
  );
}

String _mint(String url) => url.trim().replaceAll(RegExp(r'/+$'), '');

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
