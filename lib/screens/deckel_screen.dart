import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/deckel/deckel_backend.dart';
import '../services/deckel/deckel_command.dart';
import '../services/deckel/deckel_demo.dart';
import '../services/deckel/deckel_events.dart';
import '../services/deckel/deckel_ledger.dart';
import '../services/deckel/deckel_netting.dart';
import '../services/deckel/deckel_oracle.dart';
import '../services/deckel/deckel_table.dart';
import '../services/speech/on_device_speech.dart';
import '../services/speech/on_device_voice.dart';
import '../services/speech/system_on_device_speech.dart';
import '../services/speech/system_on_device_voice.dart';
import '../services/voice_wallet/cashu_mint.dart';
import '../theme.dart';
import 'cashu_scan_screen.dart';

/// Der Bierdeckel: anschreiben, Kassensturz, nur die Differenz zahlen.
///
/// Ohne Tisch zeigt die Seite drei Wege hinein: einen neuen Deckel
/// aufmachen, einen scannen oder den Demo-Tisch. Am Tisch stehen oben der
/// eigene Stand, darunter Kassensturz und Runden, unten Runde, Mikrofon und
/// Kassensturz.
class DeckelScreen extends StatefulWidget {
  /// Ein Deckel aus dem Scanner, an den man sich gleich setzt.
  final ({String deckelId, String name})? join;

  /// Öffnet sofort den Demo-Tisch.
  final bool demo;

  /// Abstand zwischen den Handlungen der Demo-Gäste.
  final Duration demoPace;

  /// Der Demo-Tisch spielt sich selbst, auch den Menschen am Handy.
  final bool demoAutoplay;

  final DeckelBackend? backend;
  final DeckelSigner? signer;
  final DeckelPurse? purse;
  final DeckelLedger? ledger;

  /// Woher die Frage für Wetten kommt. Ohne Angabe das Orakel von Kickstr.
  final DeckelOracle? oracle;
  final OnDeviceSpeech? speech;
  final OnDeviceVoice? voice;

  const DeckelScreen({
    super.key,
    this.join,
    this.demo = false,
    this.demoPace = const Duration(milliseconds: 1400),
    this.demoAutoplay = false,
    this.backend,
    this.signer,
    this.purse,
    this.ledger,
    this.oracle,
    this.speech,
    this.voice,
  });

  @override
  State<DeckelScreen> createState() => _DeckelScreenState();
}

/// Worauf die Seite gerade ein Ja oder Nein erwartet.
sealed class _Pending {
  const _Pending();
}

class _PendingRound extends _Pending {
  final int sats;
  final bool perHead;
  final String subject;
  const _PendingRound(this.sats, this.perHead, this.subject);
}

class _PendingClose extends _Pending {
  const _PendingClose();
}

class _PendingPay extends _Pending {
  final DeckelPayment payment;
  const _PendingPay(this.payment);
}

class _PendingBet extends _Pending {
  final bool yes;
  final int sats;
  const _PendingBet(this.yes, this.sats);
}

class _DeckelScreenState extends State<DeckelScreen> {
  static const _idKey = 'deckel_current_id_v1';
  static const _nameKey = 'deckel_current_name_v1';
  static const _voiceOutputKey = 'voice_wallet_output_v1';

  late final OnDeviceSpeech _speech = widget.speech ?? SystemOnDeviceSpeech();
  late final OnDeviceVoice _voice = widget.voice ?? SystemOnDeviceVoice();

  DeckelTable? _table;
  DeckelBackend? _backend;
  DeckelDemo? _demo;

  bool _loading = true;
  bool _busy = false;
  bool _listening = false;
  bool _awaitingAmount = false;
  bool _mute = false;
  _Pending? _pending;

  /// Was die Seite zuletzt gehört oder geantwortet hat.
  String _line = '';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _speech.stop();
    _voice.stop();
    _leaveTable();
    super.dispose();
  }

  // ── Tisch öffnen und verlassen ────────────────────────────────────────

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    _mute = prefs.getString(_voiceOutputKey) == 'text';
    if (!mounted) return;
    if (widget.demo) {
      await _openDemo();
    } else if (widget.join != null) {
      await _openTable(widget.join!.deckelId, widget.join!.name);
    } else {
      final id = prefs.getString(_idKey);
      if (id != null) await _openTable(id, prefs.getString(_nameKey) ?? '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openTable(String deckelId, String name) async {
    final signer = widget.signer ?? const AppDeckelSigner();
    final backend = widget.backend ?? RelayDeckelBackend();
    final table = DeckelTable(
      deckelId: deckelId,
      name: name,
      backend: backend,
      signer: signer,
      purse: widget.purse ?? CashuDeckelPurse(),
      ledger: widget.ledger,
      // Ein Tisch aus einem Test bringt sein Orakel mit oder hat keins.
      oracle: widget.oracle ?? (widget.backend == null ? KickstrOracle() : null),
    );
    try {
      await table.open();
    } catch (_) {
      // Ohne Identität bleibt `me` leer; die Seite sagt es.
    }
    if (!mounted) {
      table.dispose();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, deckelId);
    await prefs.setString(_nameKey, name);
    table.addListener(_onTable);
    setState(() {
      _backend = backend;
      _table = table;
    });
  }

  Future<void> _openDemo() async {
    final t = AppLocalizations.of(context);
    final demo = DeckelDemo(pace: widget.demoPace, autoplay: widget.demoAutoplay);
    demo.me.addListener(_onTable);
    setState(() {
      _demo = demo;
      _table = demo.me;
      _line = '';
    });
    await demo.start(myName: t.dkYou);
  }

  void _onTable() {
    if (mounted) setState(() {});
  }

  void _leaveTable() {
    _table?.removeListener(_onTable);
    if (_demo != null) {
      _demo!.stop();
    } else {
      _table?.dispose();
      if (widget.backend == null) _backend?.close();
    }
    _table = null;
    _backend = null;
    _demo = null;
  }

  Future<void> _leave() async {
    final wasDemo = _demo != null;
    _leaveTable();
    if (!wasDemo) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_idKey);
      await prefs.remove(_nameKey);
    }
    if (mounted) {
      setState(() {
        _pending = null;
        _awaitingAmount = false;
        _line = '';
      });
    }
  }

  Future<void> _newDeckel() async {
    final t = AppLocalizations.of(context);
    final name = await _askText(title: t.dkTableName, initial: t.dkTableNameDefault);
    if (name == null || !mounted) return;
    final random = Random.secure();
    final id = [for (var i = 0; i < 8; i++) random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
    await _openTable(id, name.isEmpty ? t.dkTableNameDefault : name);
    await _sit();
  }

  Future<void> _scanDeckel() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _DeckelScanPage()),
    );
    if (code == null || !mounted) return;
    final deckel = parseDeckelQr(code);
    if (deckel == null) {
      _tell(AppLocalizations.of(context).dkNotDeckel);
      return;
    }
    await _openTable(deckel.deckelId, deckel.name);
    await _sit();
  }

  Future<void> _sit() async {
    final table = _table;
    if (table == null || table.me == null || table.seated || !mounted) return;
    final t = AppLocalizations.of(context);
    // Der Spitzname aus dem Profil als Vorschlag.
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final known = (prefs.getString('nickname') ?? '').trim();
    final name = await _askText(title: t.dkYourName, initial: known == 'Anon' ? '' : known);
    if (name == null || name.isEmpty || !mounted) return;
    await _run(() => table.sit(name));
  }

  // ── Handlungen ────────────────────────────────────────────────────────

  /// Führt etwas aus, das signiert und veröffentlicht. Sagt, wenn es scheitert.
  Future<bool> _run(Future<bool> Function() action) async {
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return ok;
    setState(() => _busy = false);
    if (!ok) await _tell(AppLocalizations.of(context).dkPublishFailed);
    return ok;
  }

  Future<void> _addRound(int sats, {required bool perHead, required String subject}) async {
    final table = _table!;
    final t = AppLocalizations.of(context);
    if (table.state.seats.length < 2) {
      await _tell(t.dkNeedTwo);
      return;
    }
    if (await _run(() => table.addRound(sats: sats, perHead: perHead, subject: subject)) && mounted) {
      await _tell('${t.dkSaidRound} ${_balanceSentence(table.myBalance)}');
    }
  }

  Future<void> _close() async {
    final table = _table!;
    final t = AppLocalizations.of(context);
    if (table.state.open.isEmpty) {
      await _tell(t.dkNothingToClose);
      return;
    }
    if (await _run(table.closeTab) && mounted) {
      final summary = table.state.closing!.summary;
      await _tell(t.dkSaidClosed(summary.debts, summary.payments));
    }
  }

  Future<void> _pay(DeckelPayment payment) async {
    final table = _table!;
    final t = AppLocalizations.of(context);
    final again = await table.tokenOf(payment) != null;
    final String token;
    setState(() => _busy = true);
    try {
      token = await table.pay(payment);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      final short = e is! CashuException || e.fail == CashuFail.notEnough;
      await _tell(short ? t.dkNotEnough(_group(await table.walletBalance())) : t.dkRejected);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _demo?.showToGuest(payment, token);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      builder: (_) => _PaySheet(table: table, payment: payment, token: token, again: again),
    );
  }

  Future<void> _redeem(DeckelPayment payment) async {
    final table = _table!;
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CashuScanScreen()),
    );
    if (code == null || !mounted) return;
    setState(() => _busy = true);
    final fail = await table.redeem(payment, code);
    if (!mounted) return;
    setState(() => _busy = false);
    final t = AppLocalizations.of(context);
    await _tell(switch (fail) {
      null => t.dkSaidGot(_group(payment.sats), table.state.nameOf(payment.from)),
      DeckelRedeemFail.notAToken => t.dkNotToken,
      DeckelRedeemFail.wrongAmount => t.dkWrongAmount,
      DeckelRedeemFail.rejected => t.dkRejected,
      DeckelRedeemFail.receiptFailed => t.dkReceiptFailed,
    });
  }

  Future<void> _confirmByHand(DeckelPayment payment) async {
    final table = _table!;
    final t = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        content: Text(
          t.dkConfirmGot(table.state.nameOf(payment.from), _group(payment.sats)),
          style: const TextStyle(color: cText, fontSize: 17, height: 1.35),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.dkNo)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t.dkYes)),
        ],
      ),
    );
    if (yes == true && mounted) await _run(() => table.confirmReceived(payment));
  }

  Future<void> _placeBet(bool yes, int sats) async {
    final table = _table!;
    final t = AppLocalizations.of(context);
    if (table.question == null) {
      await _tell(t.dkNoQuestion);
      return;
    }
    if (!await _run(() => table.bet(yes: yes, sats: sats)) || !mounted) return;
    DeckelWager? mine;
    for (final wager in table.state.wagers) {
      if (wager.matched && wager.sats == sats && (yes ? wager.yes : wager.no) == table.me) mine = wager;
    }
    await _tell(
      mine == null
          ? t.dkSaidBetOpen
          : t.dkSaidBetMatched(table.state.nameOf(yes ? mine.no! : mine.yes!)),
    );
  }

  Future<void> _betDialog(bool yes) async {
    final t = AppLocalizations.of(context);
    final text = await _askText(
      title: t.dkBetOn(t.dkBetAmount, yes ? t.dkYes : t.dkNo),
      initial: '2000',
      digits: true,
    );
    final sats = int.tryParse(text ?? '');
    if (sats == null || sats <= 0 || !mounted) return;
    await _placeBet(yes, sats);
  }

  Future<void> _roundDialog() async {
    final t = AppLocalizations.of(context);
    final table = _table!;
    if (table.state.seats.length < 2) {
      await _tell(t.dkNeedTwo);
      return;
    }
    final round = await showModalBottomSheet<_PendingRound>(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      builder: (_) => _RoundSheet(heads: table.state.seats.length),
    );
    if (round == null || !mounted) return;
    await _addRound(round.sats, perHead: round.perHead, subject: round.subject);
  }

  // ── Sprache ───────────────────────────────────────────────────────────

  Future<void> _toggleMic() async {
    await _voice.stop();
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    await _listen();
  }

  Future<void> _listen() async {
    final t = AppLocalizations.of(context);
    final failure = await _speech.listen(
      localeId: onDeviceSpeechLocale(Localizations.localeOf(context).languageCode),
      onWords: _onWords,
    );
    if (!mounted) return;
    if (failure != null) {
      await _tell(switch (failure) {
        SpeechFailure.denied => t.vwSpeechDenied,
        SpeechFailure.unavailable =>
          Theme.of(context).platform == TargetPlatform.android ? t.vwAndroidOff : t.vwSpeechOff,
      });
      return;
    }
    setState(() => _listening = true);
  }

  Future<void> _onWords(String words, bool isFinal) async {
    if (!mounted || _busy) return;
    if (!isFinal) {
      setState(() => _line = words);
      return;
    }
    await _speech.stop();
    if (!mounted) return;
    setState(() => _listening = false);
    await _apply(words);
    // Auf eine Frage soll die Antwort gleich gesprochen werden können.
    if (mounted && (_pending != null || _awaitingAmount)) await _listen();
  }

  Future<void> _apply(String words) async {
    final table = _table;
    if (table == null) return;
    final t = AppLocalizations.of(context);
    var command = parseDeckelCommand(words);

    final pending = _pending;
    if (pending != null) {
      if (command.kind == DeckelCommandKind.confirm) {
        await _answer(true);
        return;
      }
      if (command.kind == DeckelCommandKind.cancel) {
        await _answer(false);
        return;
      }
    }

    switch (command.kind) {
      case DeckelCommandKind.round:
        if (command.sats == null) {
          setState(() {
            _awaitingAmount = true;
            _pending = null;
          });
          await _tell(t.dkAskAmount);
          return;
        }
        final heads = table.state.seats.length;
        final total = command.perHead ? command.sats! * heads : command.sats!;
        setState(() {
          _awaitingAmount = false;
          _pending = _PendingRound(command.sats!, command.perHead, command.subject);
        });
        await _tell(t.dkAskRound(_group(total), heads));
      case DeckelCommandKind.bet:
        final open = table.question;
        if (open == null || command.sats == null || command.yes == null) {
          _clearQuestion();
          await _tell(open == null ? t.dkNoQuestion : t.dkBetHow);
          return;
        }
        setState(() {
          _awaitingAmount = false;
          _pending = _PendingBet(command.yes!, command.sats!);
        });
        await _tell(t.dkAskBet(
          _group(command.sats!),
          command.yes! ? t.dkYes : t.dkNo,
          _clock(open.closes),
          _group(open.strike),
        ));
      case DeckelCommandKind.balance:
        _clearQuestion();
        final due = table.myDues.where((p) => !table.state.closing!.paid(p)).toList();
        await _tell(
          due.isNotEmpty
              ? t.dkSaidOwes(_group(due.fold<int>(0, (sum, p) => sum + p.sats)))
              : _balanceSentence(table.myBalance),
        );
      case DeckelCommandKind.close:
        if (table.state.open.isEmpty) {
          _clearQuestion();
          await _tell(t.dkNothingToClose);
          return;
        }
        setState(() {
          _awaitingAmount = false;
          _pending = const _PendingClose();
        });
        await _tell(t.dkAskClose(table.state.open.length));
      case DeckelCommandKind.pay:
        final due = _firstOpen(table.myDues);
        if (due == null) {
          _clearQuestion();
          await _tell(table.myBalance < 0 ? t.dkFirstClose : t.dkNothingToPay);
          return;
        }
        setState(() {
          _awaitingAmount = false;
          _pending = _PendingPay(due);
        });
        await _tell(t.dkAskPay(_group(due.sats), table.state.nameOf(due.to)));
      case DeckelCommandKind.redeem:
        _clearQuestion();
        final claim = _firstOpen(table.myClaims);
        if (claim == null) {
          await _tell(t.dkNothingToRedeem);
          return;
        }
        await _redeem(claim);
      case DeckelCommandKind.help:
        _clearQuestion();
        await _tell(t.dkHelp);
      case DeckelCommandKind.confirm:
      case DeckelCommandKind.cancel:
      case DeckelCommandKind.unknown:
        await _tell(t.dkUnknown);
    }
  }

  void _clearQuestion() {
    setState(() {
      _pending = null;
      _awaitingAmount = false;
    });
  }

  /// Ja oder Nein auf die offene Frage, gesprochen oder getippt.
  Future<void> _answer(bool yes) async {
    final pending = _pending;
    await _voice.stop();
    await _speech.stop();
    if (!mounted) return;
    setState(() {
      _pending = null;
      _awaitingAmount = false;
      _listening = false;
      if (!yes) _line = '';
    });
    if (!yes || pending == null) return;
    switch (pending) {
      case _PendingRound():
        await _addRound(pending.sats, perHead: pending.perHead, subject: pending.subject);
      case _PendingClose():
        await _close();
      case _PendingPay():
        await _pay(pending.payment);
      case _PendingBet():
        await _placeBet(pending.yes, pending.sats);
    }
  }

  DeckelPayment? _firstOpen(List<DeckelPayment> payments) {
    final closing = _table!.state.closing;
    for (final payment in payments) {
      if (closing != null && !closing.paid(payment)) return payment;
    }
    return null;
  }

  String _balanceSentence(int balance) {
    final t = AppLocalizations.of(context);
    if (balance > 0) return t.dkSaidGets(_group(balance));
    if (balance < 0) return t.dkSaidOwes(_group(-balance));
    return t.dkSaidEven;
  }

  /// Zeigt einen Satz und spricht ihn, wenn die Stimme an ist.
  Future<void> _tell(String text) async {
    if (!mounted) return;
    setState(() => _line = text);
    if (_mute) return;
    await _voice.speak(
      text.replaceAll('.', ''),
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  Future<String?> _askText({required String title, required String initial, bool digits = false}) {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Text(title, style: const TextStyle(color: cText, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          keyboardType: digits ? TextInputType.number : TextInputType.text,
          inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: const TextStyle(color: cText, fontSize: 18),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.dkCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(t.dkOk),
          ),
        ],
      ),
    );
  }

  void _showQr() {
    final table = _table!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cCard,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QrBox(data: deckelQr(deckelId: table.deckelId, name: table.name), size: 240),
              const SizedBox(height: 16),
              Text(
                table.name,
                style: const TextStyle(color: cText, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bild ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final table = _table;
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        foregroundColor: cTextSecondary,
        centerTitle: true,
        title: Text(
          table == null ? t.dkTitle : (_demo != null ? t.dkDemoBanner : table.name),
          style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (table != null && _demo == null)
            IconButton(
              tooltip: t.dkShowQr,
              onPressed: _showQr,
              icon: const Icon(Icons.qr_code_2_rounded),
            ),
          if (table != null)
            IconButton(
              tooltip: t.dkLeave,
              onPressed: _leave,
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: cOrange))
            : table == null
                ? _start(t)
                : _atTable(t, table),
      ),
    );
  }

  Widget _start(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.sports_bar_rounded, color: cOrange, size: 72),
          const SizedBox(height: 20),
          Text(
            t.dkIntro,
            textAlign: TextAlign.center,
            style: const TextStyle(color: cText, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
          ),
          if (_line.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_line, textAlign: TextAlign.center, style: const TextStyle(color: cOrangeLight, fontSize: 16)),
          ],
          const Spacer(),
          _BigButton(label: t.dkNew, icon: Icons.add_rounded, filled: true, onTap: _newDeckel),
          const SizedBox(height: 12),
          _BigButton(label: t.dkScan, icon: Icons.qr_code_scanner_rounded, onTap: _scanDeckel),
          const SizedBox(height: 12),
          _BigButton(label: t.dkDemo, icon: Icons.play_arrow_rounded, onTap: _openDemo),
          const SizedBox(height: 10),
          Text(
            t.dkDemoSub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: cTextTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _atTable(AppLocalizations t, DeckelTable table) {
    if (table.me == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            t.dkNoIdentity,
            textAlign: TextAlign.center,
            style: const TextStyle(color: cText, fontSize: 20, height: 1.3),
          ),
        ),
      );
    }
    final state = table.state;
    final closing = state.closing;
    final alone = state.seats.length < 2;
    final question = _pending != null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            children: [
              _hero(t, table),
              const SizedBox(height: 14),
              _seats(t, table),
              if (!table.seated) ...[
                const SizedBox(height: 16),
                _BigButton(label: t.dkSit, icon: Icons.event_seat_rounded, filled: true, onTap: _sit),
              ],
              if (alone && table.seated && _demo == null) ...[
                const SizedBox(height: 20),
                Center(child: _QrBox(data: deckelQr(deckelId: table.deckelId, name: table.name), size: 200)),
                const SizedBox(height: 12),
                Text(
                  t.dkAlone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: cTextSecondary, fontSize: 15, height: 1.3),
                ),
              ],
              if (table.question != null || state.wagers.isNotEmpty) ...[
                const SizedBox(height: 18),
                _questionCard(t, table),
              ],
              if (closing != null) ...[
                const SizedBox(height: 18),
                _closingCard(t, table, closing),
              ],
              if (state.open.isNotEmpty || closing == null) ...[
                const SizedBox(height: 18),
                _sheet(t, table),
              ],
            ],
          ),
        ),
        if (table.seated)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              _line.isNotEmpty ? _line : (_listening ? t.dkHintListening : t.dkHintIdle),
              key: const Key('deckel-line'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _line.isEmpty
                    ? cTextTertiary
                    : (question || _awaitingAmount ? cText : cOrangeLight),
                fontSize: question ? 20 : (_line.isEmpty ? 14 : 16),
                fontWeight: question ? FontWeight.w700 : FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        if (table.seated) _bar(t, table, question),
      ],
    );
  }

  Widget _hero(AppLocalizations t, DeckelTable table) {
    final closing = table.state.closing;
    // Nach dem Kassensturz zählt, was davon noch offen ist; sonst das Blatt.
    var amount = table.myBalance;
    if (closing != null && table.state.open.isEmpty) {
      amount = 0;
      for (final p in closing.payments) {
        if (closing.paid(p)) continue;
        if (p.from == table.me) amount -= p.sats;
        if (p.to == table.me) amount += p.sats;
      }
    }
    final color = amount > 0 ? cGreen : (amount < 0 ? cOrange : cText);
    final caption = amount > 0 ? t.dkGets : (amount < 0 ? t.dkOwes : t.dkEven);
    return Column(
      children: [
        Text(
          amount == 0 ? '0' : _group(amount.abs()),
          key: const Key('deckel-hero'),
          style: TextStyle(color: color, fontSize: 72, fontWeight: FontWeight.w700, height: 1.05),
        ),
        Text(caption, style: const TextStyle(color: cTextSecondary, fontSize: 18)),
      ],
    );
  }

  Widget _seats(AppLocalizations t, DeckelTable table) {
    final names = [
      for (final seat in table.state.seats.entries) seat.key == table.me ? t.dkYou : seat.value,
    ]..sort();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final name in names)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cTileBorder),
            ),
            child: Text(name, style: const TextStyle(color: cTextSecondary, fontSize: 14)),
          ),
      ],
    );
  }

  Widget _closingCard(AppLocalizations t, DeckelTable table, DeckelClosing closing) {
    final summary = closing.summary;
    return Container(
      key: const Key('deckel-closing'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cOrange.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.dkClose.toUpperCase(),
            style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Text(
            t.dkBefore(summary.debts, _group(summary.debtSats)),
            style: const TextStyle(
              color: cTextTertiary,
              fontSize: 16,
              decoration: TextDecoration.lineThrough,
              decorationColor: cTextTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            t.dkAfter(summary.payments, _group(summary.paymentSats)),
            style: const TextStyle(color: cText, fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final payment in closing.payments) _paymentRow(t, table, closing, payment),
          if (closing.settled) ...[
            const SizedBox(height: 8),
            Text(t.dkAllPaid, style: const TextStyle(color: cGreen, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _paymentRow(AppLocalizations t, DeckelTable table, DeckelClosing closing, DeckelPayment payment) {
    final paid = closing.paid(payment);
    String name(String key) => key == table.me ? t.dkYou : table.state.nameOf(key);
    final mine = payment.from == table.me;
    final toMe = payment.to == table.me;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${name(payment.from)} → ${name(payment.to)}',
              style: TextStyle(
                color: mine || toMe ? cText : cTextSecondary,
                fontSize: 17,
                fontWeight: mine || toMe ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(_group(payment.sats), style: const TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          if (paid)
            const Icon(Icons.check_circle_rounded, color: cGreen, size: 26)
          else if (mine)
            _SmallButton(label: t.dkPay, onTap: _busy ? null : () => _pay(payment))
          else if (toMe && _demo == null)
            _SmallButton(
              label: t.dkRedeem,
              onTap: _busy ? null : () => _redeem(payment),
              onLongPress: _busy ? null : () => _confirmByHand(payment),
            )
          else
            const Icon(Icons.schedule_rounded, color: cTextTertiary, size: 24),
        ],
      ),
    );
  }

  /// Die Frage des Orakels, die Wetten dazu, und Ja und Nein zum Tippen.
  Widget _questionCard(AppLocalizations t, DeckelTable table) {
    final open = table.question;
    final share = table.yesShare;
    String name(String key) => key == table.me ? t.dkYou : table.state.nameOf(key);
    return Container(
      key: const Key('deckel-question'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.dkQuestionTitle.toUpperCase(),
            style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
          if (open != null) ...[
            const SizedBox(height: 8),
            Text(
              t.dkQuestion(_clock(open.closes), _group(open.strike)),
              style: const TextStyle(color: cText, fontSize: 20, fontWeight: FontWeight.w700, height: 1.25),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    share == null ? '' : t.dkMarketYes((share * 100).round()),
                    style: const TextStyle(color: cTextSecondary, fontSize: 15),
                  ),
                ),
                // Solange unten eine Frage auf Ja oder Nein wartet, gibt es hier keine zweiten.
                if (table.seated && _pending == null) ...[
                  _SmallButton(label: t.dkYes, onTap: _busy ? null : () => _betDialog(true)),
                  const SizedBox(width: 8),
                  _SmallButton(label: t.dkNo, onTap: _busy ? null : () => _betDialog(false)),
                ],
              ],
            ),
          ],
          for (final wager in table.state.wagers)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                wager.matched
                    ? t.dkWagerMatched(
                        name(wager.yes!),
                        name(wager.no!),
                        _group(wager.sats),
                        _clockOf(table.questionOf(wager.questionId)),
                      )
                    : t.dkWagerOpen(
                        name(wager.yes ?? wager.no!),
                        _group(wager.sats),
                        wager.yes != null ? t.dkYes : t.dkNo,
                      ),
                style: TextStyle(
                  color: wager.matched ? cText : cTextSecondary,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sheet(AppLocalizations t, DeckelTable table) {
    final rounds = table.state.open;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.dkSheet.toUpperCase(),
          style: const TextStyle(color: cTextTertiary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        if (rounds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(t.dkSheetEmpty, style: const TextStyle(color: cTextTertiary, fontSize: 15)),
          ),
        for (final round in rounds.reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        round.bet
                            ? t.dkBetRound(_group(int.tryParse(round.subject) ?? 0))
                            : (round.subject.isEmpty ? t.dkRound : round.subject),
                        style: const TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        round.payer == table.me
                            ? (round.bet ? t.dkBetWonYou : t.dkRoundByYou)
                            : (round.bet
                                ? t.dkBetWon(table.state.nameOf(round.payer))
                                : t.dkRoundBy(table.state.nameOf(round.payer))),
                        style: const TextStyle(color: cTextTertiary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _group(round.sats),
                      style: const TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    if (!round.bet)
                      Text(
                        t.dkEach(_group(round.share)),
                        style: const TextStyle(color: cTextTertiary, fontSize: 13),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _bar(AppLocalizations t, DeckelTable table, bool question) {
    if (question) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: _BigButton(key: const Key('deckel-answer-no'), label: t.dkNo, onTap: () => _answer(false)),
            ),
            const SizedBox(width: 12),
            _mic(),
            const SizedBox(width: 12),
            Expanded(
              child: _BigButton(
                key: const Key('deckel-answer-yes'),
                label: t.dkYes,
                filled: true,
                onTap: () => _answer(true),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: _BigButton(label: t.dkRound, icon: Icons.add_rounded, onTap: _busy ? null : _roundDialog),
          ),
          const SizedBox(width: 12),
          _mic(),
          const SizedBox(width: 12),
          Expanded(
            child: _BigButton(
              label: t.dkClose,
              filled: table.state.open.isNotEmpty,
              onTap: _busy || table.state.open.isEmpty ? null : _close,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mic() {
    return GestureDetector(
      key: const Key('deckel-mic'),
      onTap: _busy ? null : _toggleMic,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cOrange.withValues(alpha: _listening ? 0.25 : 0.12),
          border: Border.all(color: cOrange, width: _listening ? 3 : 1.5),
        ),
        child: _busy
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: cOrange, strokeWidth: 2.5),
              )
            : const Icon(Icons.mic_rounded, color: cOrange, size: 32),
      ),
    );
  }
}

/// Uhrzeit eines Zeitpunkts in Unix-Sekunden, wie die Uhr am Handy sie zeigt.
String _clock(int unix) {
  final at = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
  return '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
}

String _clockOf(DeckelQuestion? question) => question == null ? '…' : _clock(question.closes);

String _group(int sats) {
  final s = sats.toString();
  return s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
}

class _BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback? onTap;

  const _BigButton({super.key, required this.label, this.icon, this.filled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    final color = filled && on ? cDark : (on ? cText : cTextTertiary);
    return Material(
      color: filled && on ? cOrange : cCard,
      borderRadius: BorderRadius.circular(kTileRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kTileRadius),
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(color: filled && on ? cOrange : cTileBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _SmallButton({required this.label, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cOrange,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(label, style: const TextStyle(color: cDark, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _QrBox extends StatelessWidget {
  final String data;
  final double size;

  const _QrBox({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: QrImageView(
        data: data,
        size: size,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
      ),
    );
  }
}

/// Betrag, Zweck und "pro Kopf" für eine Runde.
class _RoundSheet extends StatefulWidget {
  final int heads;

  const _RoundSheet({required this.heads});

  @override
  State<_RoundSheet> createState() => _RoundSheetState();
}

class _RoundSheetState extends State<_RoundSheet> {
  final _amount = TextEditingController();
  final _subject = TextEditingController();
  bool _perHead = false;

  @override
  void dispose() {
    _amount.dispose();
    _subject.dispose();
    super.dispose();
  }

  void _submit() {
    final sats = int.tryParse(_amount.text.replaceAll('.', '').trim());
    if (sats == null || sats <= 0) return;
    final total = _perHead ? sats * widget.heads : sats;
    if (total > kDeckelMaxRoundSats) return;
    Navigator.pop(context, _PendingRound(sats, _perHead, _subject.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    const field = TextStyle(color: cText, fontSize: 20);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.dkRoundTitle, style: const TextStyle(color: cText, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          TextField(
            key: const Key('deckel-amount'),
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: field,
            decoration: InputDecoration(labelText: t.dkAmount),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('deckel-subject'),
            controller: _subject,
            maxLength: 40,
            style: field,
            decoration: InputDecoration(labelText: t.dkSubject),
            onSubmitted: (_) => _submit(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: cOrange,
            value: _perHead,
            onChanged: (value) => setState(() => _perHead = value),
            title: Text(t.dkPerHead, style: const TextStyle(color: cText, fontSize: 17)),
          ),
          const SizedBox(height: 8),
          _BigButton(label: t.dkWrite, filled: true, onTap: _submit),
        ],
      ),
    );
  }
}

/// Der Token einer eigenen Zahlung als QR. Schließt sich, sobald quittiert ist.
class _PaySheet extends StatelessWidget {
  final DeckelTable table;
  final DeckelPayment payment;
  final String token;
  final bool again;

  const _PaySheet({required this.table, required this.payment, required this.token, required this.again});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final name = table.state.nameOf(payment.to);
    return ListenableBuilder(
      listenable: table,
      builder: (context, _) {
        final paid = table.state.closing?.paid(payment) ?? false;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.dkPayTo(_group(payment.sats), name),
                  style: const TextStyle(color: cText, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (paid)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Icon(Icons.check_circle_rounded, color: cGreen, size: 120),
                  )
                else
                  _QrBox(data: token, size: 260),
                const SizedBox(height: 16),
                Text(
                  paid ? t.dkPaidLine : (again ? t.dkPayAgain : t.dkShowTo(name)),
                  key: const Key('deckel-pay-line'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: paid ? cGreen : cTextSecondary, fontSize: 16, height: 1.3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Kamera, die nur einen Bierdeckel-Code zurückgibt.
class _DeckelScanPage extends StatefulWidget {
  const _DeckelScanPage();

  @override
  State<_DeckelScanPage> createState() => _DeckelScanPageState();
}

class _DeckelScanPageState extends State<_DeckelScanPage> {
  final MobileScannerController _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code == null || !code.startsWith('21d:')) continue;
      _done = true;
      Navigator.pop(context, code);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      body: Stack(children: [
        MobileScanner(controller: _scanner, onDetect: _onDetect),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Text(
                t.dkScan,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(blurRadius: 12, color: Colors.black)],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
