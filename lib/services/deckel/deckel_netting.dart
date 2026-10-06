// Verrechnen statt überweisen.
//
// Am Tisch zahlt mal der eine, mal die andere. Einzeln beglichen wären das
// viele kleine Zahlungen. Verrechnet bleibt für jeden nur die Differenz:
// was er ausgelegt hat, minus was er verzehrt hat.
//
// Alles hier ist reine Rechnung ohne Netz und ohne Uhr. Dieselben Runden
// ergeben auf jedem Gerät dieselbe Zahlungsliste, egal in welcher
// Reihenfolge sie ankamen — sonst könnten sich zwei Handys am selben Tisch
// nicht einig werden, wer wem was zahlt.

/// Eine Runde: einer zahlt, mehrere teilen.
class DeckelRound {
  final String id;

  /// Wer ausgelegt hat (pubkey, hex).
  final String payer;

  /// Der ganze Betrag in Satoshi.
  final int sats;

  /// Wer sich die Runde teilt. Meist ist der Zahler dabei.
  final List<String> sharers;

  final String subject;
  final int createdAt;

  /// Eine entschiedene Wette: der Gewinner steht als Zahler, der Verlierer
  /// teilt allein, und [subject] nennt den Strike der Frage.
  final bool bet;

  const DeckelRound({
    required this.id,
    required this.payer,
    required this.sats,
    required this.sharers,
    this.subject = '',
    this.createdAt = 0,
    this.bet = false,
  });

  /// Anteil pro Kopf. Was beim Teilen übrig bleibt, trägt der Zahler.
  int get share => sharers.isEmpty ? 0 : sats ~/ sharers.length;
}

/// Eine Schuld oder eine Zahlung: [from] gibt [sats] an [to].
class DeckelPayment {
  final String from;
  final String to;
  final int sats;

  const DeckelPayment({required this.from, required this.to, required this.sats});

  @override
  bool operator ==(Object other) =>
      other is DeckelPayment && other.from == from && other.to == to && other.sats == sats;

  @override
  int get hashCode => Object.hash(from, to, sats);

  @override
  String toString() => '$from -> $to: $sats';
}

/// Was ohne Verrechnung zu zahlen wäre: ein Anteil je Kopf und Runde.
List<DeckelPayment> debtsOf(Iterable<DeckelRound> rounds) {
  final out = <DeckelPayment>[];
  for (final round in rounds) {
    final share = round.share;
    if (share <= 0) continue;
    for (final head in round.sharers) {
      if (head == round.payer) continue;
      out.add(DeckelPayment(from: head, to: round.payer, sats: share));
    }
  }
  return out;
}

/// Saldo je Kopf: positiv bekommt, negativ schuldet. Die Summe ist null.
Map<String, int> balancesOf(Iterable<DeckelRound> rounds) {
  final balance = <String, int>{};
  for (final debt in debtsOf(rounds)) {
    balance[debt.from] = (balance[debt.from] ?? 0) - debt.sats;
    balance[debt.to] = (balance[debt.to] ?? 0) + debt.sats;
  }
  return balance;
}

/// Die wenigen Zahlungen, die alle Salden ausgleichen.
///
/// Größter Schuldner zahlt an größten Gläubiger, bis einer von beiden glatt
/// ist. Bei gleichem Betrag entscheidet der Schlüssel, damit die Liste auf
/// jedem Gerät gleich ausfällt. Es werden höchstens Köpfe minus eine Zahlung.
List<DeckelPayment> settle(Map<String, int> balances) {
  int byAmountThenKey(MapEntry<String, int> a, MapEntry<String, int> b) {
    final amount = b.value.compareTo(a.value);
    return amount != 0 ? amount : a.key.compareTo(b.key);
  }

  final owing = [
    for (final e in balances.entries)
      if (e.value < 0) MapEntry(e.key, -e.value),
  ]..sort(byAmountThenKey);
  final owed = [
    for (final e in balances.entries)
      if (e.value > 0) MapEntry(e.key, e.value),
  ]..sort(byAmountThenKey);

  final out = <DeckelPayment>[];
  var i = 0;
  var j = 0;
  var left = owing.isEmpty ? 0 : owing[0].value;
  var open = owed.isEmpty ? 0 : owed[0].value;
  while (i < owing.length && j < owed.length) {
    final sats = left < open ? left : open;
    out.add(DeckelPayment(from: owing[i].key, to: owed[j].key, sats: sats));
    left -= sats;
    open -= sats;
    if (left == 0 && ++i < owing.length) left = owing[i].value;
    if (open == 0 && ++j < owed.length) open = owed[j].value;
  }
  return out;
}

/// Vorher und nachher in vier Zahlen.
class DeckelSummary {
  final int debts;
  final int debtSats;
  final int payments;
  final int paymentSats;

  const DeckelSummary({
    required this.debts,
    required this.debtSats,
    required this.payments,
    required this.paymentSats,
  });

  factory DeckelSummary.of(Iterable<DeckelRound> rounds) {
    final debts = debtsOf(rounds);
    final payments = settle(balancesOf(rounds));
    return DeckelSummary(
      debts: debts.length,
      debtSats: debts.fold(0, (sum, d) => sum + d.sats),
      payments: payments.length,
      paymentSats: payments.fold(0, (sum, p) => sum + p.sats),
    );
  }
}
