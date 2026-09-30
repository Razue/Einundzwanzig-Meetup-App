import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/speech/on_device_speech.dart';
import '../services/speech/on_device_voice.dart';
import '../services/speech/system_on_device_speech.dart';
import '../services/speech/system_on_device_voice.dart';
import '../services/voice_wallet/cashu_mint.dart';
import '../services/voice_wallet/cashu_wallet.dart';
import '../services/voice_wallet/spoken_reply.dart';
import '../services/voice_wallet/wallet_command.dart';
import '../theme.dart';
import 'cashu_scan_screen.dart';

/// Leere Wallet-Seite. Ein Mikrofon, sonst nichts.
///
/// Scannen löst den Token beim Mint ein. Senden zeigt den neuen Token
/// als QR, der Rest bleibt auf dem Gerät.
class VoiceWalletScreen extends StatefulWidget {
  final OnDeviceSpeech? speech;
  final OnDeviceVoice? voice;
  final CashuWallet? wallet;

  const VoiceWalletScreen({super.key, this.speech, this.voice, this.wallet});

  @override
  State<VoiceWalletScreen> createState() => _VoiceWalletScreenState();
}

class _VoiceWalletScreenState extends State<VoiceWalletScreen>
    with SingleTickerProviderStateMixin {
  late final OnDeviceSpeech _speech;
  late final OnDeviceVoice _voice;
  late final CashuWallet _wallet;
  late final AnimationController _pulse;

  bool _listening = false;
  bool _busy = false;
  bool _awaitingAmount = false;
  int? _pendingSats;
  String? _outgoing;

  String _primary = '';
  String _caption = '';
  bool _huge = false;

  @override
  void initState() {
    super.initState();
    _speech = widget.speech ?? SystemOnDeviceSpeech();
    _voice = widget.voice ?? SystemOnDeviceVoice();
    _wallet = widget.wallet ?? CashuWallet();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.stop();
    _voice.stop();
    super.dispose();
  }

  String _localeId() => onDeviceSpeechLocale(Localizations.localeOf(context).languageCode);

  String _languageName(AppLocalizations t) =>
      _localeId() == 'de_DE' ? t.vwLangDe : t.vwLangEn;

  Future<void> _toggle() async {
    await _voice.stop();
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final failure = await _speech.listen(
      localeId: _localeId(),
      onWords: _onWords,
    );
    if (!mounted) return;
    if (failure != null) {
      final failureText = _failureText(failure);
      setState(() {
        _listening = false;
        _huge = false;
        _primary = failureText;
        _caption = '';
      });
      _say(failureText);
      return;
    }
    setState(() => _listening = true);
  }

  String _failureText(SpeechFailure failure) {
    final t = AppLocalizations.of(context);
    switch (failure) {
      case SpeechFailure.denied:
        return t.vwSpeechDenied;
      case SpeechFailure.unavailable:
        return Theme.of(context).platform == TargetPlatform.android
            ? t.vwAndroidOff
            : t.vwSpeechOff;
    }
  }

  Future<void> _onWords(String words, bool isFinal) async {
    if (!mounted || _busy) return;
    if (!isFinal) {
      setState(() {
        _huge = false;
        _primary = words;
        _caption = '';
      });
      return;
    }
    await _speech.stop();
    if (!mounted) return;
    setState(() => _listening = false);
    await _apply(words);
  }

  void _say(String? text) {
    if (!mounted || text == null || text.isEmpty) return;
    final language = Localizations.localeOf(context).languageCode;
    unawaited(_voice.speak(text, languageCode: language));
  }

  Future<void> _apply(String words) async {
    final t = AppLocalizations.of(context);
    var command = parseWalletCommand(words);

    if (_awaitingAmount && command.kind == WalletCommandKind.unknown) {
      final sats = parseSpokenSats(words);
      if (sats != null) command = WalletCommand(WalletCommandKind.send, sats: sats);
    }

    if (_pendingSats != null) {
      if (command.kind == WalletCommandKind.confirm) {
        final amount = _pendingSats!;
        setState(() {
          _pendingSats = null;
          _awaitingAmount = false;
          _busy = true;
          _outgoing = null;
          _huge = false;
          _primary = t.vwWorking;
          _caption = '';
        });
        await _send(amount);
        return;
      }
      if (command.kind == WalletCommandKind.cancel) {
        await _voice.stop();
        setState(() {
          _pendingSats = null;
          _awaitingAmount = false;
          _outgoing = null;
          _huge = false;
          _primary = '';
          _caption = '';
        });
        return;
      }
    }

    switch (command.kind) {
      case WalletCommandKind.balance:
        setState(() {
          _awaitingAmount = false;
          _pendingSats = null;
          _outgoing = null;
          _busy = true;
          _huge = false;
          _primary = t.vwWorking;
          _caption = '';
        });
        await _showBalance();
      case WalletCommandKind.scan:
        setState(() {
          _awaitingAmount = false;
          _pendingSats = null;
          _outgoing = null;
        });
        await _scan();
      case WalletCommandKind.send:
        if (command.sats == null) {
          setState(() {
            _awaitingAmount = true;
            _pendingSats = null;
            _outgoing = null;
            _huge = false;
            _primary = t.vwAskAmount;
            _caption = '';
          });
          _say(t.vwAskAmount);
          return;
        }
        setState(() {
          _awaitingAmount = false;
          _pendingSats = command.sats;
          _outgoing = null;
          _huge = true;
          _primary = _group(command.sats!);
          _caption = t.vwHintConfirm;
        });
        _say(spokenReply(amount: command.sats, sentence: t.vwHintConfirm));
      case WalletCommandKind.help:
        setState(() {
          _outgoing = null;
          _huge = false;
          _primary = t.vwHelp;
          _caption = '';
        });
        _say(t.vwHelp);
      case WalletCommandKind.confirm:
      case WalletCommandKind.cancel:
      case WalletCommandKind.unknown:
        {
          final pending = _pendingSats;
          setState(() {
            if (pending != null) {
              _huge = true;
              _primary = _group(pending);
              _caption = t.vwUnknown;
            } else {
              _huge = false;
              _primary = t.vwUnknown;
              _caption = '';
            }
          });
          _say(spokenReply(amount: pending, sentence: t.vwUnknown));
        }
    }
  }

  Future<void> _showBalance() async {
    try {
      final balance = await _wallet.balance();
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() {
        _busy = false;
        _huge = true;
        _primary = _group(balance);
        _caption = balance == 0 ? t.vwEmpty : t.vwBalanceCaption;
      });
      _say(spokenReply(amount: balance));
    } on CashuException catch (e) {
      _showFail(e.fail);
    }
  }

  Future<void> _send(int amount) async {
    try {
      final sent = await _wallet.send(amount);
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() {
        _busy = false;
        _huge = true;
        _primary = _group(sent.amount);
        _caption = t.vwSent(sent.balance);
        _outgoing = sent.token;
      });
      _say(spokenReply(amount: sent.amount, sentence: t.vwSent(sent.balance)));
    } on CashuException catch (e) {
      _showFail(e.fail);
    }
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CashuScanScreen()),
    );
    if (!mounted || code == null) return;
    setState(() {
      _busy = true;
      _outgoing = null;
      _huge = false;
      _primary = AppLocalizations.of(context).vwWorking;
      _caption = '';
    });
    try {
      final received = await _wallet.receive(code);
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      setState(() {
        _busy = false;
        _huge = true;
        _primary = _group(received.received);
        _caption = t.vwReceived(received.balance);
      });
      _say(spokenReply(amount: received.received, sentence: t.vwReceived(received.balance)));
    } on CashuException catch (e) {
      _showFail(e.fail, e.detail);
    }
  }

  void _showFail(CashuFail fail, [String? detail]) {
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    final text = switch (fail) {
      CashuFail.already => t.vwAlready,
      CashuFail.spent => t.vwSpent,
      CashuFail.notEnough => t.vwNotEnough,
      CashuFail.network => t.vwNet,
      CashuFail.mintRejected => t.vwMintNo,
      CashuFail.badMint => t.vwBadMint,
      CashuFail.unknownKeyset => t.vwUnknownKeyset,
      CashuFail.unsupportedUnit => t.vwOnlySat,
      CashuFail.feeTooHigh => t.vwFeeHigh,
      CashuFail.noSatKey => t.vwNoSat,
      CashuFail.badToken => switch (detail) {
          'lightning' => t.vwLightning,
          'none' => t.vwNotCashu,
          _ => t.vwBadToken,
        },
    };
    final parts = detail?.split(':');
    final caption = fail == CashuFail.badToken && parts != null && parts.length == 2
        ? t.vwReadDetail(parts[0], int.tryParse(parts[1]) ?? 0)
        : '';
    setState(() {
      _busy = false;
      _huge = false;
      _outgoing = null;
      _primary = text;
      _caption = caption;
    });
    _say(text);
  }

  String _group(int sats) {
    final s = sats.toString();
    return s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pad = MediaQuery.paddingOf(context);
    final hint = _listening
        ? t.vwHintListening
        : (_pendingSats != null ? t.vwHintConfirm : t.vwHintIdle(_languageName(t)));

    // Seitlicher Rand nur auf einer Seite wuerde die Spalte verschieben.
    // Dazu ein kleiner Schritt nach rechts: auf dem breiten Display
    // stand Text und Mikrofon sonst knapp links der Mitte.
    final side = pad.left > pad.right ? pad.left : pad.right;
    const nudge = 10.0;

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        foregroundColor: cTextSecondary,
        title: const SizedBox.shrink(),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(28 + side + nudge, 0, 28 + side - nudge, 28 + pad.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              _primary,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cText,
                fontSize: _huge ? 84 : 28,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
            if (_caption.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                _caption,
                textAlign: TextAlign.center,
                style: const TextStyle(color: cTextSecondary, fontSize: 18, height: 1.3),
              ),
            ],
            if (_outgoing != null) ...[
              const SizedBox(height: 22),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  data: _outgoing!,
                  size: 220,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
                ),
              ),
            ],
            const Spacer(),
            GestureDetector(
              onTap: _toggle,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1, end: _listening ? 1.12 : 1.05).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cOrange.withValues(alpha: _listening ? 0.22 : 0.12),
                    border: Border.all(color: cOrange, width: _listening ? 3 : 1.5),
                  ),
                  child: const Icon(Icons.mic_rounded, color: cOrange, size: 84),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: cTextTertiary, fontSize: 15, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
