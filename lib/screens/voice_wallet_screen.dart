import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/speech/on_device_speech.dart';
import '../services/speech/system_on_device_speech.dart';
import '../services/voice_wallet/cashu_token_amount.dart';
import '../services/voice_wallet/wallet_command.dart';
import '../theme.dart';
import 'cashu_scan_screen.dart';

/// Leere Wallet-Seite. Ein Mikrofon, sonst nichts.
///
/// Der Kontostand ist noch immer 0: Token werden hier noch nicht gehalten.
/// Senden merkt den Betrag nur vor. Scannen zeigt den Betrag eines
/// `cashuA`-Tokens, ohne ihn einloesen.
class VoiceWalletScreen extends StatefulWidget {
  final OnDeviceSpeech? speech;

  const VoiceWalletScreen({super.key, this.speech});

  @override
  State<VoiceWalletScreen> createState() => _VoiceWalletScreenState();
}

class _VoiceWalletScreenState extends State<VoiceWalletScreen>
    with SingleTickerProviderStateMixin {
  late final OnDeviceSpeech _speech;
  late final AnimationController _pulse;

  bool _listening = false;
  bool _awaitingAmount = false;
  int? _pendingSats;

  String _primary = '';
  String _caption = '';
  bool _huge = false;

  @override
  void initState() {
    super.initState();
    _speech = widget.speech ?? SystemOnDeviceSpeech();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.stop();
    super.dispose();
  }

  String _localeId() => onDeviceSpeechLocale(Localizations.localeOf(context).languageCode);

  String _languageName(AppLocalizations t) =>
      _localeId() == 'de_DE' ? t.vwLangDe : t.vwLangEn;

  Future<void> _toggle() async {
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
      setState(() {
        _listening = false;
        _huge = false;
        _primary = _failureText(failure);
        _caption = '';
      });
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

  void _onWords(String words, bool isFinal) {
    if (!mounted) return;
    if (!isFinal) {
      setState(() {
        _huge = false;
        _primary = words;
        _caption = '';
      });
      return;
    }
    _speech.stop();
    setState(() => _listening = false);
    _apply(words);
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
        setState(() {
          _pendingSats = null;
          _awaitingAmount = false;
          _huge = false;
          _primary = t.vwSendPending;
          _caption = '';
        });
        return;
      }
      if (command.kind == WalletCommandKind.cancel) {
        setState(() {
          _pendingSats = null;
          _awaitingAmount = false;
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
          _huge = true;
          _primary = '0';
          _caption = t.vwEmpty;
        });
      case WalletCommandKind.scan:
        setState(() {
          _awaitingAmount = false;
          _pendingSats = null;
        });
        await _scan();
      case WalletCommandKind.send:
        if (command.sats == null) {
          setState(() {
            _awaitingAmount = true;
            _pendingSats = null;
            _huge = false;
            _primary = t.vwAskAmount;
            _caption = '';
          });
          return;
        }
        setState(() {
          _awaitingAmount = false;
          _pendingSats = command.sats;
          _huge = true;
          _primary = _group(command.sats!);
          _caption = t.vwHintConfirm;
        });
      case WalletCommandKind.help:
        setState(() {
          _huge = false;
          _primary = t.vwHelp;
          _caption = '';
        });
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
        }
    }
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CashuScanScreen()),
    );
    if (!mounted || code == null) return;
    final t = AppLocalizations.of(context);
    final peek = peekCashuToken(code);
    setState(() {
      if (!peek.isCashu) {
        _huge = false;
        _primary = t.vwNotToken;
        _caption = '';
      } else if (peek.sats == null) {
        _huge = false;
        _primary = t.vwTokenNoAmount;
        _caption = '';
      } else {
        _huge = true;
        _primary = _group(peek.sats!);
        _caption = t.vwBalanceCaption;
      }
    });
  }

  String _group(int sats) {
    final s = sats.toString();
    return s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hint = _listening
        ? t.vwHintListening
        : (_pendingSats != null ? t.vwHintConfirm : t.vwHintIdle(_languageName(t)));

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        foregroundColor: cTextSecondary,
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(children: [
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
          ]),
        ),
      ),
    );
  }
}
