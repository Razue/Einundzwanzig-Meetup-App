// Der Deckel als Nostr-Ereignisse.
//
// Ein Deckel ist nur eine Kennung — sie steht im QR-Code auf dem Bierdeckel.
// Alles andere sind vier signierte Ereignisse, die diese Kennung im d-Tag
// tragen:
//
//   Platz        30251  "Ich sitze an diesem Tisch."      ["name", …]
//   Runde         1251  "Ich habe ausgelegt."             ["amount", sats], ["p", Kopf]…
//   Kassensturz   1252  "Diese Runden rechnen wir ab."    ["e", Runde]…
//   Quittung      1253  "Ich habe mein Geld bekommen."    ["e", Kassensturz], ["once", …], ["rail", …]
//   Wette         1254  "Ich halte Ja (oder Nein)."       ["e", Frage des Orakels], ["side", …], ["amount", sats]
//
// Die Nummern sind vorläufig und nirgends registriert.
//
// Wer wem was zahlt, steht in keinem Ereignis. Jedes Gerät rechnet es aus
// den Runden des Kassensturzes selbst aus (deckel_netting.dart) und kommt
// auf dieselbe Liste.
//
// Regeln:
//   * Schulden kann nur, wer sich gesetzt hat. Wer in einer Runde genannt
//     wird, ohne Platz genommen zu haben, zählt nicht mit.
//   * Eine Runde gehört zum ersten Kassensturz, der sie nennt. Runden, die
//     danach kommen, stehen auf dem nächsten Blatt.
//   * Eine Wette ist ein Handschlag, kein gesperrter Topf. Zwei Wetten auf
//     dieselbe Frage, gleicher Betrag, Ja gegen Nein, von zwei verschiedenen
//     Leuten am Tisch, gehören zusammen — die frühesten zuerst. Löst das
//     Orakel die Frage auf, schuldet der Verlierer dem Gewinner den Betrag.
//     Diese Schuld steht dann wie eine Runde auf dem Blatt.
//   * Eine Quittung gilt nur vom Empfänger der Zahlung. Auf welchem Weg das
//     Geld kam, sagt "rail": "cashu" für einen eingelösten Token, "hand"
//     für alles andere, vom Geldschein bis zur Zahlung aus einer anderen Wallet.

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'deckel_netting.dart';
import 'deckel_oracle.dart';

const int kDeckelSeat = 30251;
const int kDeckelRound = 1251;
const int kDeckelClose = 1252;
const int kDeckelReceipt = 1253;
const int kDeckelBet = 1254;

const List<int> kDeckelKinds = [kDeckelSeat, kDeckelRound, kDeckelClose, kDeckelReceipt, kDeckelBet];

const int kDeckelMaxRoundSats = 10000000;
const int _maxName = 24;
const int _maxSubject = 40;

final _hex64 = RegExp(r'^[0-9a-f]{64}$');

/// Ein Ereignis vor dem Signieren.
class DeckelDraft {
  final int kind;
  final List<List<String>> tags;
  final String content;

  const DeckelDraft({required this.kind, required this.tags, this.content = ''});
}

DeckelDraft seatDraft({required String deckelId, required String name}) => DeckelDraft(
      kind: kDeckelSeat,
      tags: [
        ['d', deckelId],
        ['name', _clip(name, _maxName)],
      ],
    );

DeckelDraft roundDraft({
  required String deckelId,
  required int sats,
  required Iterable<String> sharers,
  String subject = '',
}) =>
    DeckelDraft(
      kind: kDeckelRound,
      content: _clip(subject, _maxSubject),
      tags: [
        ['d', deckelId],
        ['amount', '$sats'],
        for (final head in {...sharers}) ['p', head],
      ],
    );

DeckelDraft closeDraft({required String deckelId, required Iterable<String> roundIds}) => DeckelDraft(
      kind: kDeckelClose,
      tags: [
        ['d', deckelId],
        for (final id in {...roundIds}) ['e', id],
      ],
    );

DeckelDraft receiptDraft({
  required String deckelId,
  required String closingId,
  required DeckelPayment payment,
  String rail = 'cashu',
}) =>
    DeckelDraft(
      kind: kDeckelReceipt,
      tags: [
        ['d', deckelId],
        ['e', closingId],
        ['p', payment.from],
        ['once', onceKey(closingId, payment)],
        ['amount', '${payment.sats}'],
        ['rail', rail],
      ],
    );

DeckelDraft betDraft({
  required String deckelId,
  required String questionId,
  required bool yes,
  required int sats,
}) =>
    DeckelDraft(
      kind: kDeckelBet,
      tags: [
        ['d', deckelId],
        ['e', questionId],
        ['side', yes ? 'yes' : 'no'],
        ['amount', '$sats'],
      ],
    );

/// Schlüssel einer Zahlung. Jede Zahlung eines Kassensturzes hat genau einen,
/// und unter ihm geht sie höchstens einmal raus.
String onceKey(String closingId, DeckelPayment payment) =>
    sha256.convert(utf8.encode('$closingId:${payment.from}:${payment.to}')).toString();

/// Ein Kassensturz mit dem, was aus ihm folgt.
class DeckelClosing {
  final String id;
  final String by;
  final int createdAt;
  final List<DeckelRound> rounds;
  final List<DeckelPayment> payments;

  /// Quittierte Zahlungen, nach ihrem once-Schlüssel.
  final Set<String> receipts;

  const DeckelClosing({
    required this.id,
    required this.by,
    required this.createdAt,
    required this.rounds,
    required this.payments,
    required this.receipts,
  });

  DeckelSummary get summary => DeckelSummary.of(rounds);

  bool paid(DeckelPayment payment) => receipts.contains(onceKey(id, payment));

  bool get settled => payments.every(paid);
}

/// Eine Wette, die noch nicht entschieden ist: ein Angebot, das auf die
/// Gegenseite wartet, oder ein Paar, das auf das Orakel wartet.
class DeckelWager {
  final String questionId;
  final int sats;

  /// Wer Ja hält und wer Nein. Bei einem offenen Angebot fehlt eine Seite.
  final String? yes;
  final String? no;

  const DeckelWager({required this.questionId, required this.sats, this.yes, this.no});

  bool get matched => yes != null && no != null;
}

/// Der Tisch, wie er aus den Ereignissen folgt.
class DeckelState {
  final String deckelId;

  /// Wer sitzt: Schlüssel und Name.
  final Map<String, String> seats;

  /// Runden auf dem offenen Blatt, älteste zuerst.
  final List<DeckelRound> open;

  /// Der letzte Kassensturz, falls es einen gab.
  final DeckelClosing? closing;

  /// Wetten, die noch offen sind. Entschiedene stehen als Runde in [open].
  final List<DeckelWager> wagers;

  const DeckelState({
    required this.deckelId,
    this.seats = const {},
    this.open = const [],
    this.closing,
    this.wagers = const [],
  });

  String nameOf(String pubkey) => seats[pubkey] ?? '${pubkey.substring(0, 6)}…';

  Map<String, int> get openBalances => balancesOf(open);
}

/// Liest den Tisch aus geprüften Ereignissen. Reihenfolge und Doppelte sind egal.
/// [oracle] ist, was das Orakel bisher gesagt hat; ohne es bleiben Wetten offen.
DeckelState reduceDeckel(
  String deckelId,
  Iterable<Map<String, dynamic>> events, {
  OracleBook oracle = const OracleBook(),
}) {
  final mine = <String, _Ev>{};
  for (final raw in events) {
    final ev = _Ev.read(raw);
    if (ev == null || ev.tag('d') != deckelId) continue;
    mine[ev.id] = ev;
  }
  final sorted = mine.values.toList()
    ..sort((a, b) {
      final time = a.createdAt.compareTo(b.createdAt);
      return time != 0 ? time : a.id.compareTo(b.id);
    });

  // Plätze: je Kopf der jüngste.
  final seats = <String, String>{};
  for (final ev in sorted.where((e) => e.kind == kDeckelSeat)) {
    final name = _clip(ev.tag('name') ?? '', _maxName);
    seats[ev.pubkey] = name.isEmpty ? '${ev.pubkey.substring(0, 6)}…' : name;
  }

  // Runden: Zahler sitzt, Betrag stimmt, mindestens ein anderer teilt.
  final rounds = <String, DeckelRound>{};
  for (final ev in sorted.where((e) => e.kind == kDeckelRound)) {
    final sats = int.tryParse(ev.tag('amount') ?? '');
    if (sats == null || sats <= 0 || sats > kDeckelMaxRoundSats) continue;
    if (!seats.containsKey(ev.pubkey)) continue;
    final sharers = <String>{
      for (final head in ev.all('p'))
        if (seats.containsKey(head)) head,
    }.toList()
      ..sort();
    if (!sharers.any((head) => head != ev.pubkey)) continue;
    rounds[ev.id] = DeckelRound(
      id: ev.id,
      payer: ev.pubkey,
      sats: sats,
      sharers: sharers,
      subject: _clip(ev.content, _maxSubject),
      createdAt: ev.createdAt,
    );
  }

  // Wetten: Ja und Nein über denselben Betrag finden sich, die frühesten zuerst.
  // Ein entschiedenes Paar wird zur Runde: der Gewinner als Zahler, der Verlierer teilt allein.
  final waiting = <String, List<_Ev>>{};
  final wagers = <DeckelWager>[];
  for (final ev in sorted.where((e) => e.kind == kDeckelBet)) {
    if (!seats.containsKey(ev.pubkey)) continue;
    final questionId = ev.tag('e') ?? '';
    final side = ev.tag('side');
    final sats = int.tryParse(ev.tag('amount') ?? '');
    if (!_hex64.hasMatch(questionId) || (side != 'yes' && side != 'no')) continue;
    if (sats == null || sats <= 0 || sats > kDeckelMaxRoundSats) continue;
    final question = oracle.questions[questionId];
    if (question != null && ev.createdAt >= question.closes) continue; // nach Marktschluss gewettet

    final others = waiting['$questionId:$sats:${side == 'yes' ? 'no' : 'yes'}'] ?? [];
    final at = others.indexWhere((other) => other.pubkey != ev.pubkey);
    if (at < 0) {
      waiting.putIfAbsent('$questionId:$sats:$side', () => []).add(ev);
      continue;
    }
    final other = others.removeAt(at);
    final yes = side == 'yes' ? ev.pubkey : other.pubkey;
    final no = side == 'yes' ? other.pubkey : ev.pubkey;
    final verdict = oracle.verdicts[questionId];
    if (verdict == null || question == null) {
      wagers.add(DeckelWager(questionId: questionId, sats: sats, yes: yes, no: no));
      continue;
    }
    rounds[ev.id] = DeckelRound(
      id: ev.id,
      payer: verdict ? yes : no,
      sats: sats,
      sharers: [verdict ? no : yes],
      subject: '${question.strike}',
      createdAt: question.closes,
      bet: true,
    );
  }
  for (final entry in waiting.entries) {
    final parts = entry.key.split(':');
    // Ein Angebot, dessen Frage schon entschieden ist, hat niemand angenommen.
    if (oracle.verdicts.containsKey(parts[0])) continue;
    for (final ev in entry.value) {
      wagers.add(DeckelWager(
        questionId: parts[0],
        sats: int.parse(parts[1]),
        yes: parts[2] == 'yes' ? ev.pubkey : null,
        no: parts[2] == 'no' ? ev.pubkey : null,
      ));
    }
  }

  // Kassenstürze: der früheste, der eine Runde nennt, bekommt sie.
  final settled = <String>{};
  _Ev? lastClose;
  var lastRounds = <DeckelRound>[];
  for (final ev in sorted.where((e) => e.kind == kDeckelClose)) {
    if (!seats.containsKey(ev.pubkey)) continue;
    final taken = <DeckelRound>[
      for (final id in {...ev.all('e')})
        if (rounds.containsKey(id) && !settled.contains(id)) rounds[id]!,
    ]..sort(_byTimeThenId);
    if (taken.isEmpty) continue;
    settled.addAll(taken.map((r) => r.id));
    lastClose = ev;
    lastRounds = taken;
  }

  DeckelClosing? closing;
  if (lastClose != null) {
    final payments = settle(balancesOf(lastRounds));
    final byOnce = {for (final p in payments) onceKey(lastClose.id, p): p};
    final receipts = <String>{};
    for (final ev in sorted.where((e) => e.kind == kDeckelReceipt)) {
      if (ev.tag('e') != lastClose.id) continue;
      final once = ev.tag('once');
      final payment = byOnce[once];
      if (payment != null && payment.to == ev.pubkey) receipts.add(once!);
    }
    closing = DeckelClosing(
      id: lastClose.id,
      by: lastClose.pubkey,
      createdAt: lastClose.createdAt,
      rounds: lastRounds,
      payments: payments,
      receipts: receipts,
    );
  }

  return DeckelState(
    deckelId: deckelId,
    seats: seats,
    open: [
      for (final round in rounds.values)
        if (!settled.contains(round.id)) round,
    ]..sort(_byTimeThenId),
    closing: closing,
    wagers: wagers,
  );
}

int _byTimeThenId(DeckelRound a, DeckelRound b) {
  final time = a.createdAt.compareTo(b.createdAt);
  return time != 0 ? time : a.id.compareTo(b.id);
}

String _clip(String text, int max) {
  final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return clean.length <= max ? clean : clean.substring(0, max);
}

/// Ein Ereignis, so weit gelesen, wie der Deckel es braucht. Ereignisse
/// kommen von Relays; was nicht die erwartete Form hat, fällt hier raus.
class _Ev {
  final String id;
  final String pubkey;
  final int createdAt;
  final int kind;
  final List<List<String>> tags;
  final String content;

  _Ev(this.id, this.pubkey, this.createdAt, this.kind, this.tags, this.content);

  static _Ev? read(Map<String, dynamic> raw) {
    final id = raw['id'];
    final pubkey = raw['pubkey'];
    final createdAt = raw['created_at'];
    final kind = raw['kind'];
    final tags = raw['tags'];
    final content = raw['content'];
    if (id is! String || pubkey is! String || createdAt is! int || kind is! int) return null;
    if (!_hex64.hasMatch(id) || !_hex64.hasMatch(pubkey)) return null;
    if (!kDeckelKinds.contains(kind) || tags is! List) return null;
    return _Ev(
      id,
      pubkey,
      createdAt,
      kind,
      [
        for (final tag in tags)
          if (tag is List && tag.length >= 2 && tag.every((part) => part is String)) tag.cast<String>(),
      ],
      content is String ? content : '',
    );
  }

  String? tag(String name) {
    for (final tag in tags) {
      if (tag[0] == name) return tag[1];
    }
    return null;
  }

  Iterable<String> all(String name) sync* {
    for (final tag in tags) {
      if (tag[0] == name && _hex64.hasMatch(tag[1])) yield tag[1];
    }
  }
}

// ── QR-Code auf dem Bierdeckel ──────────────────────────────────────────

/// `21d:1:<Kennung>:<Name, base64url>`
String deckelQr({required String deckelId, required String name}) =>
    '21d:1:$deckelId:${base64Url.encode(utf8.encode(_clip(name, _maxName))).replaceAll('=', '')}';

final _deckelId = RegExp(r'^[0-9a-z]{8,32}$');

/// Kennung und Name aus dem QR-Code, oder null, wenn es kein Deckel ist.
({String deckelId, String name})? parseDeckelQr(String code) {
  final parts = code.trim().split(':');
  if (parts.length != 4 || parts[0] != '21d' || parts[1] != '1') return null;
  if (!_deckelId.hasMatch(parts[2])) return null;
  try {
    final padded = parts[3] + '=' * ((4 - parts[3].length % 4) % 4);
    return (deckelId: parts[2], name: _clip(utf8.decode(base64Url.decode(padded)), _maxName));
  } on FormatException {
    return null;
  }
}
