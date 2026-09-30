import 'dart:convert';

/// Was ein gescannter Text als Cashu-Token hergibt.
///
/// [isCashu] heisst: das Format ist ein Token. [sats] ist die Summe der
/// Proofs, aber nur bei `cashuA` und nur in Satoshi. `cashuB` und andere
/// Einheiten bleiben ohne Betrag — lieber nichts anzeigen als eine
/// erfundene Zahl.
class CashuPeek {
  final bool isCashu;
  final int? sats;

  const CashuPeek({required this.isCashu, this.sats});

  static const notToken = CashuPeek(isCashu: false);
}

CashuPeek peekCashuToken(String raw) {
  final text = raw.trim();
  if (text.startsWith('cashuB')) return const CashuPeek(isCashu: true);
  if (!text.startsWith('cashuA')) return CashuPeek.notToken;

  try {
    final payload = base64Url.normalize(text.substring('cashuA'.length));
    final decoded = utf8.decode(base64Url.decode(payload));
    final json = jsonDecode(decoded);
    if (json is! Map) return const CashuPeek(isCashu: true);

    final unit = json['unit'];
    if (unit != null && unit != 'sat') return const CashuPeek(isCashu: true);

    final token = json['token'];
    if (token is! List) return const CashuPeek(isCashu: true);

    var sum = 0;
    for (final entry in token) {
      if (entry is! Map) return const CashuPeek(isCashu: true);
      final proofs = entry['proofs'];
      if (proofs is! List) return const CashuPeek(isCashu: true);
      for (final proof in proofs) {
        if (proof is! Map) return const CashuPeek(isCashu: true);
        final amount = proof['amount'];
        if (amount is! int || amount < 0) return const CashuPeek(isCashu: true);
        sum += amount;
      }
    }
    return CashuPeek(isCashu: true, sats: sum);
  } catch (_) {
    return const CashuPeek(isCashu: true);
  }
}
