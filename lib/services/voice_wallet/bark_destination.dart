/// Wohin Bark zahlen kann, gelesen aus Zwischenablage oder QR.
///
/// Beträge aus einer BOLT11-Rechnung kommen aus dem lesbaren Vorspann.
/// Die Prüfsumme wird hier nicht geprüft — das macht barkd.
enum PayKind { bolt11, lnurl, lightningAddress, ark, onchain, bip321 }

class PayDestination {
  final PayKind kind;
  final String raw;

  /// Gesetzt, wenn die Rechnung den Betrag schon trägt.
  final int? amountSat;

  const PayDestination(this.kind, this.raw, {this.amountSat});

  /// Ark-Adresse, Lightning-Adresse und Kette brauchen einen Betrag.
  /// Eine Rechnung mit Betrag nicht.
  bool get needsAmount => amountSat == null;
}

final _token = RegExp(
  r'ln(?:bc|tb|bcrt)\d*[munp]?1[0-9a-z]+|lnurl1[0-9a-z]+|ark1[0-9a-z]+|(?:bc1|tb1|bcrt1)[0-9a-z]+|bitcoin:\S+|lightning:\S+|\S+@\S+\.\S+',
  caseSensitive: false,
);

final _bolt = RegExp(r'^ln(bc|tb|bcrt)(\d*)([munp])?1', caseSensitive: false);

/// Erste Zahlungsangabe im Text, sonst null.
PayDestination? parsePayDestination(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final found = _token.firstMatch(text);
  if (found == null) return null;
  var piece = found.group(0)!;
  if (piece.toLowerCase().startsWith('lightning:')) {
    piece = piece.substring('lightning:'.length);
  }
  final lower = piece.toLowerCase();

  final bolt = _bolt.firstMatch(lower);
  if (bolt != null) {
    return PayDestination(
      PayKind.bolt11,
      lower,
      amountSat: _boltAmount(bolt.group(2)!, bolt.group(3)),
    );
  }
  if (lower.startsWith('lnurl1')) {
    return PayDestination(PayKind.lnurl, lower);
  }
  if (lower.startsWith('ark1')) {
    return PayDestination(PayKind.ark, lower);
  }
  if (lower.startsWith('bc1') ||
      lower.startsWith('tb1') ||
      lower.startsWith('bcrt1')) {
    return PayDestination(PayKind.onchain, lower);
  }
  if (lower.startsWith('bitcoin:')) {
    return PayDestination(
      PayKind.bip321,
      piece,
      amountSat: _uriAmount(piece),
    );
  }
  if (piece.contains('@')) {
    return PayDestination(PayKind.lightningAddress, piece);
  }
  return null;
}

/// BOLT11-Vorspann in Satoshi. `n` und `p` nur, wenn es aufgeht.
int? _boltAmount(String digits, String? unit) {
  if (digits.isEmpty) return null;
  final n = int.tryParse(digits);
  if (n == null || n <= 0) return null;
  switch (unit) {
    case null:
      if (n > 21) return null;
      return n * 100000000;
    case 'm':
      return n * 100000;
    case 'u':
      return n * 100;
    case 'n':
      if (n % 10 != 0) return null;
      return n ~/ 10;
    case 'p':
      if (n % 10000 != 0) return null;
      return n ~/ 10000;
    default:
      return null;
  }
}

int? _uriAmount(String uri) {
  final parsed = Uri.tryParse(uri);
  if (parsed == null) return null;
  final raw = parsed.queryParameters['amount'];
  if (raw == null || raw.isEmpty) return null;
  final btc = double.tryParse(raw);
  if (btc == null || btc <= 0) return null;
  final sats = (btc * 100000000).round();
  if (sats <= 0) return null;
  return sats;
}
