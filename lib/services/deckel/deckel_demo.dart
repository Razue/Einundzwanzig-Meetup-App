// Demo-Tisch: der Deckel auf einem einzigen Handy.
//
// Zwei erfundene Gäste sitzen mit am Tisch und tun, was Gäste tun: Runden
// ausgeben, nach dem Kassensturz zahlen, eingehende Zahlungen quittieren.
// Alles läuft durch dieselben Ereignisse und dieselbe Verrechnung wie am
// echten Tisch — nur steht der Tisch im Speicher, die Schlüssel sind
// frisch gewürfelt und das Geld ist Spielgeld. Nichts wird veröffentlicht,
// und die echte Wallet bleibt unberührt.
//
// Auch das Orakel ist gespielt: Es legt sich beim Start auf eine Frage fest.
// Wettet der Mensch am Handy, hält Ben dagegen, und kurz darauf löst das
// Orakel auf — immer mit Ja.

import 'dart:async';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'deckel_backend.dart';
import 'deckel_events.dart';
import 'deckel_ledger.dart';
import 'deckel_netting.dart';
import 'deckel_oracle.dart';
import 'deckel_table.dart';

/// Spielgeld. Ein Token ist `spielgeld:<Betrag>:<Nummer>` und lässt sich
/// wie ein echter nur einmal einlösen.
class PlayMoney {
  final Set<String> _redeemed = {};
  final Random _random = Random();

  String issue(int sats) => 'spielgeld:$sats:${_random.nextInt(1 << 32)}';

  int? amountOf(String token) {
    final parts = token.split(':');
    if (parts.length != 3 || parts[0] != 'spielgeld') return null;
    return int.tryParse(parts[1]);
  }

  /// Wahr beim ersten Einlösen, falsch bei jedem weiteren.
  bool redeem(String token) => amountOf(token) != null && _redeemed.add(token);
}

class PlayPurse implements DeckelPurse {
  PlayPurse(this._money, this._sats);

  final PlayMoney _money;
  int _sats;

  @override
  Future<int> balance() async => _sats;

  @override
  Future<String> token(int sats) async {
    if (sats > _sats) throw StateError('Zu wenig Spielgeld.');
    _sats -= sats;
    return _money.issue(sats);
  }

  @override
  int? amountOf(String token) => _money.amountOf(token);

  @override
  Future<int> redeem(String token) async {
    if (!_money.redeem(token)) throw StateError('Schon eingelöst.');
    final sats = _money.amountOf(token)!;
    _sats += sats;
    return sats;
  }
}

class DeckelDemo {
  DeckelDemo({this.pace = const Duration(milliseconds: 1400), this.autoplay = false}) {
    me = _table(_meSigner, 21000);
    _anna = _table(KeyDeckelSigner(), 21000);
    _ben = _table(KeyDeckelSigner(), 21000);
  }

  static const deckelId = 'demotisch';

  /// Abstand zwischen zwei Handlungen der Gäste.
  final Duration pace;

  /// Selbstläufer: auch der Mensch am Handy wird gespielt — Taxi anschreiben,
  /// Kassensturz, zahlen. Für einen Bildschirm, den niemand bedient.
  final bool autoplay;

  final MemoryDeckelBackend backend = MemoryDeckelBackend();
  final PlayMoney _money = PlayMoney();
  final KeyDeckelSigner _meSigner = KeyDeckelSigner();
  final KeyDeckelSigner _oracleSigner = KeyDeckelSigner();
  final List<Timer> _timers = [];
  final Set<String> _handled = {};
  bool _stopped = false;

  /// Das gespielte Orakel und seine beiden Geheimnisse.
  late final MemoryOracle oracle = MemoryOracle(_oracleSigner.public)..share = 0.55;
  final String _secretYes = _randomHex();
  final String _secretNo = _randomHex();
  Map<String, dynamic>? _commitment;

  static String _randomHex() {
    final random = Random.secure();
    return hex.encode([for (var i = 0; i < 32; i++) random.nextInt(256)]);
  }

  /// Der Tisch aus Sicht dessen, der das Handy hält.
  late final DeckelTable me;
  late final DeckelTable _anna;
  late final DeckelTable _ben;

  DeckelTable _table(KeyDeckelSigner signer, int sats) => DeckelTable(
        deckelId: deckelId,
        name: 'Demo',
        backend: backend,
        signer: signer,
        purse: PlayPurse(_money, sats),
        ledger: DeckelLedger(store: MemoryDeckelLedgerStore()),
        oracle: oracle,
        oracleEvery: pace,
      );

  /// Setzt alle an den Tisch und lässt die Gäste zwei Runden ausgeben.
  Future<void> start({required String myName}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _commitment = await _oracleSigner.sign(DeckelDraft(
      kind: kOracleCommit,
      tags: [
        ['d', 'glimpse:21'],
        ['strike', '86000'],
        ['closes', '${now + 3600}'],
        ['yes', sha256.convert(hex.decode(_secretYes)).toString()],
        ['no', sha256.convert(hex.decode(_secretNo)).toString()],
      ],
    ));
    oracle.published.add(_commitment!);
    for (final table in [me, _anna, _ben]) {
      await table.open();
    }
    await me.refreshOracle();
    await me.sit(myName);
    me.addListener(_react);
    _later(1, () => _anna.sit('Anna'));
    _later(2, () => _ben.sit('Ben'));
    _later(3, () => _anna.addRound(sats: 12600, subject: 'Bier'));
    _later(4, () => _ben.addRound(sats: 9000, subject: 'Pizza'));
    if (!autoplay) return;
    _later(6, () => me.addRound(sats: 6000, subject: 'Taxi'));
    _later(8, me.closeTab);
    _later(11, () async {
      for (final payment in me.myDues) {
        showToGuest(payment, await me.pay(payment));
      }
    });
  }

  void _later(int steps, FutureOr<void> Function() run) {
    _timers.add(Timer(pace * steps, () {
      if (!_stopped) run();
    }));
  }

  /// Nach einem Kassensturz: Gäste zahlen, was sie schulden, und lösen ein,
  /// was man ihnen zeigt. Auf eine Wette hält Ben dagegen, dann löst das
  /// Orakel auf.
  void _react() {
    for (final wager in me.state.wagers) {
      final mineYes = wager.yes == me.me;
      if (!mineYes && wager.no != me.me) continue;
      if (!wager.matched && _handled.add('offer:${wager.sats}:$mineYes')) {
        _later(1, () async {
          await _ben.refreshOracle();
          await _ben.bet(yes: !mineYes, sats: wager.sats);
        });
      }
      if (wager.matched && _handled.add('reveal')) _later(2, _reveal);
    }
    final closing = me.state.closing;
    if (closing == null || !_handled.add(closing.id)) return;
    var step = 1;
    for (final payment in closing.payments) {
      if (payment.from == me.me) continue; // das zahlt der Mensch am Handy
      _later(step++, () => _guestPays(payment));
    }
  }

  Future<void> _guestPays(DeckelPayment payment) async {
    final payer = _guest(payment.from);
    if (payer == null) return;
    final token = await payer.pay(payment);
    final receiver = payment.to == me.me ? me : _guest(payment.to);
    await receiver?.redeem(payment, token);
  }

  Future<void> _reveal() async {
    final commitment = _commitment;
    if (commitment == null) return;
    oracle.published.add(await _oracleSigner.sign(DeckelDraft(
      kind: kOracleReveal,
      tags: [
        ['d', 'glimpse:21'],
        ['e', commitment['id'] as String],
        ['outcome', 'yes'],
        ['preimage', _secretYes],
      ],
    )));
    for (final table in [me, _anna, _ben]) {
      await table.refreshOracle();
    }
  }

  /// Der Mensch am Handy zeigt seinen Token; der Gast scannt ihn kurz darauf.
  void showToGuest(DeckelPayment payment, String token) {
    _later(2, () => _guest(payment.to)?.redeem(payment, token));
  }

  DeckelTable? _guest(String key) {
    if (key == _anna.me) return _anna;
    if (key == _ben.me) return _ben;
    return null;
  }

  Future<void> stop() async {
    _stopped = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    me.removeListener(_react);
    for (final table in [me, _anna, _ben]) {
      table.dispose();
    }
    await backend.close();
  }
}
