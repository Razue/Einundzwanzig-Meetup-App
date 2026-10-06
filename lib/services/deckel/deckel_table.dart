// Ein Tisch aus der Sicht eines Teilnehmers.
//
// Hört auf die Ereignisse des Deckels, rechnet daraus den Stand und
// veröffentlicht, was der Teilnehmer selbst tut: Platz nehmen, eine Runde
// anschreiben, Kassensturz, zahlen, quittieren.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'deckel_backend.dart';
import 'deckel_events.dart';
import 'deckel_ledger.dart';
import 'deckel_netting.dart';
import 'deckel_oracle.dart';

/// Warum ein Token nicht quittiert wurde.
enum DeckelRedeemFail {
  /// Kein Cashu-Token.
  notAToken,

  /// Ein Token, aber nicht über den Betrag dieser Zahlung.
  wrongAmount,

  /// Der Mint hat ihn nicht angenommen, etwa weil er schon eingelöst ist.
  rejected,

  /// Eingelöst, aber die Quittung ging nicht raus. Noch einmal versuchen
  /// löst nicht doppelt ein — die Quittung wird nur nachgereicht.
  receiptFailed,
}

class DeckelTable extends ChangeNotifier {
  DeckelTable({
    required this.deckelId,
    required this.name,
    required DeckelBackend backend,
    required DeckelSigner signer,
    required DeckelPurse purse,
    DeckelLedger? ledger,
    DeckelOracle? oracle,
    int Function()? clock,
    this.oracleEvery = const Duration(seconds: 20),
  })  : _backend = backend,
        _signer = signer,
        _purse = purse,
        _ledger = ledger ?? DeckelLedger(),
        _oracle = oracle,
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch ~/ 1000),
        state = DeckelState(deckelId: deckelId);

  final String deckelId;

  /// Name des Tisches, wie er auf dem Bierdeckel steht.
  final String name;

  final DeckelBackend _backend;
  final DeckelSigner _signer;
  final DeckelPurse _purse;
  final DeckelLedger _ledger;
  final DeckelOracle? _oracle;
  final int Function() _clock;

  /// Wie oft beim Orakel nachgesehen wird.
  final Duration oracleEvery;

  Timer? _oracleTimer;
  OracleBook _book = const OracleBook();

  /// Die offene Frage des Orakels, auf die gewettet werden kann.
  DeckelQuestion? question;

  /// Welchen Anteil der Markt gerade Ja gibt, 0 bis 1.
  double? yesShare;

  /// Eine Frage nach ihrer Kennung, auch wenn sie schon geschlossen ist.
  DeckelQuestion? questionOf(String id) => _book.questions[id];

  final Map<String, Map<String, dynamic>> _events = {};
  final Set<String> _redeemed = {};
  StreamSubscription<Map<String, dynamic>>? _watch;
  bool _disposed = false;

  DeckelState state;

  /// Eigener Schlüssel, sobald [open] durch ist. Null ohne Identität.
  String? me;

  Future<void> open() async {
    me = await _signer.pubkey();
    _watch = _backend.watch(deckelId).listen(_take);
    _notify();
    if (_oracle != null) {
      _oracleTimer = Timer.periodic(oracleEvery, (_) => refreshOracle());
      unawaited(refreshOracle());
    }
  }

  /// Holt, was das Orakel bisher gesagt hat, und rechnet den Tisch neu:
  /// Eine aufgelöste Frage macht aus einer Wette eine Schuld.
  Future<void> refreshOracle() async {
    final oracle = _oracle;
    if (oracle == null || _disposed) return;
    final events = await oracle.events();
    if (_disposed) return;
    // Ein stummes Orakel löscht nicht, was schon bekannt ist.
    if (events.isNotEmpty) _book = OracleBook.read(oracle.pubkey, events);
    question = _book.fresh(_clock());
    state = reduceDeckel(deckelId, _events.values, oracle: _book);
    _notify();
    final open = question;
    final share = open == null ? null : await oracle.yesShare(open);
    if (_disposed) return;
    yesShare = share;
    _notify();
  }

  void _take(Map<String, dynamic> event) {
    final id = event['id'];
    if (id is! String || _events.containsKey(id)) return;
    _events[id] = event;
    state = reduceDeckel(deckelId, _events.values, oracle: _book);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _oracleTimer?.cancel();
    _watch?.cancel();
    super.dispose();
  }

  bool get seated => me != null && state.seats.containsKey(me);

  /// Saldo auf dem offenen Blatt: positiv bekomme ich, negativ schulde ich.
  int get myBalance => state.openBalances[me] ?? 0;

  /// Zahlungen des letzten Kassensturzes, die ich leisten muss.
  List<DeckelPayment> get myDues => [
        for (final p in state.closing?.payments ?? const <DeckelPayment>[])
          if (p.from == me) p,
      ];

  /// Zahlungen des letzten Kassensturzes, die ich bekomme.
  List<DeckelPayment> get myClaims => [
        for (final p in state.closing?.payments ?? const <DeckelPayment>[])
          if (p.to == me) p,
      ];

  Future<int> walletBalance() => _purse.balance();

  Future<bool> _publish(DeckelDraft draft) async {
    final Map<String, dynamic> event;
    try {
      event = await _signer.sign(draft);
    } catch (_) {
      return false;
    }
    if (!await _backend.publish(event)) return false;
    _take(event);
    return true;
  }

  Future<bool> sit(String myName) => _publish(seatDraft(deckelId: deckelId, name: myName));

  /// Schreibt eine Runde an, die sich alle am Tisch teilen. Mit [perHead]
  /// ist [sats] der Betrag pro Kopf.
  Future<bool> addRound({required int sats, String subject = '', bool perHead = false}) {
    final heads = state.seats.keys.toList();
    final total = perHead ? sats * heads.length : sats;
    if (!seated || heads.length < 2 || total <= 0 || total > kDeckelMaxRoundSats) {
      return Future.value(false);
    }
    return _publish(roundDraft(deckelId: deckelId, sats: total, sharers: heads, subject: subject));
  }

  /// Wettet [sats] auf Ja oder Nein der offenen Frage. Die Wette gilt, sobald
  /// jemand anderes am Tisch denselben Betrag dagegen hält.
  Future<bool> bet({required bool yes, required int sats}) {
    final open = question;
    if (!seated || open == null || _clock() >= open.closes) return Future.value(false);
    if (sats <= 0 || sats > kDeckelMaxRoundSats) return Future.value(false);
    return _publish(betDraft(deckelId: deckelId, questionId: open.id, yes: yes, sats: sats));
  }

  /// Kassensturz über alle Runden des offenen Blatts.
  Future<bool> closeTab() {
    if (!seated || state.open.isEmpty) return Future.value(false);
    return _publish(closeDraft(deckelId: deckelId, roundIds: state.open.map((r) => r.id)));
  }

  /// Der Token einer eigenen Zahlung, falls sie schon einmal ausgelöst wurde.
  Future<String?> tokenOf(DeckelPayment payment) {
    final closing = state.closing;
    if (closing == null) return Future.value(null);
    return _ledger.tokenFor(onceKey(closing.id, payment));
  }

  /// Der Token für eine eigene Zahlung. Beim ersten Mal verlässt Geld die
  /// Wallet, danach kommt immer derselbe Token zurück.
  Future<String> pay(DeckelPayment payment) {
    final closing = state.closing;
    if (closing == null || payment.from != me || !closing.payments.contains(payment)) {
      throw StateError('Diese Zahlung steht nicht auf meinem Deckel.');
    }
    return _ledger.pay(once: onceKey(closing.id, payment), sats: payment.sats, purse: _purse);
  }

  /// Löst den Token einer Zahlung an mich ein und quittiert sie.
  /// Null bei Erfolg, sonst der Grund.
  Future<DeckelRedeemFail?> redeem(DeckelPayment payment, String token) async {
    final closing = state.closing;
    if (closing == null || payment.to != me || !closing.payments.contains(payment)) {
      throw StateError('Diese Zahlung geht nicht an mich.');
    }
    final once = onceKey(closing.id, payment);
    if (!_redeemed.contains(once)) {
      final amount = _purse.amountOf(token);
      if (amount == null) return DeckelRedeemFail.notAToken;
      if (amount != payment.sats) return DeckelRedeemFail.wrongAmount;
      try {
        await _purse.redeem(token);
      } catch (_) {
        return DeckelRedeemFail.rejected;
      }
      _redeemed.add(once);
    }
    final sent = await _publish(
      receiptDraft(deckelId: deckelId, closingId: closing.id, payment: payment),
    );
    return sent ? null : DeckelRedeemFail.receiptFailed;
  }

  /// Quittiert eine Zahlung an mich, die auf anderem Weg ankam: bar, aus
  /// einer anderen Wallet, oder ein Token, der schon eingelöst ist.
  Future<bool> confirmReceived(DeckelPayment payment) {
    final closing = state.closing;
    if (closing == null || payment.to != me || !closing.payments.contains(payment)) {
      throw StateError('Diese Zahlung geht nicht an mich.');
    }
    return _publish(
      receiptDraft(deckelId: deckelId, closingId: closing.id, payment: payment, rail: 'hand'),
    );
  }
}
