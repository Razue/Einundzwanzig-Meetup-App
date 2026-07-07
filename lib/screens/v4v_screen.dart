// ============================================
//  V4V — Value for Value Spenden-Maske
// ============================================
//  Erklärt Value for Value, nimmt einen frei wählbaren Sats-Betrag,
//  holt eine Invoice über die Lightning-Adresse des Projekts und öffnet
//  die ANDROID-APP-AUSWAHL (System-Chooser via MethodChannel), damit der
//  Nutzer seine Wallet frei wählen kann — statt dass immer die
//  Standard-Wallet startet.
// ============================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/v4v_service.dart';

class V4VScreen extends StatefulWidget {
  const V4VScreen({super.key});

  @override
  State<V4VScreen> createState() => _V4VScreenState();
}

class _V4VScreenState extends State<V4VScreen> {
  static const _channel = MethodChannel('einundzwanzig/amber_signer');

  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _errorText(AppLocalizations t, String code) {
    switch (code) {
      case 'invalid_amount': return t.v4vErrInvalidAmount;
      case 'below_min': return t.v4vErrBelowMin;
      case 'above_max': return t.v4vErrAboveMax;
      case 'unreachable': return t.v4vErrUnreachable;
      default: return t.v4vErrGeneric;
    }
  }

  /// Öffnet die Invoice: auf Android über den System-Chooser (Wallet-
  /// Auswahlliste), sonst per url_launcher. Liefert true bei Erfolg.
  Future<bool> _openInvoice(String invoice) async {
    if (Platform.isAndroid) {
      try {
        final ok = await _channel.invokeMethod<bool>(
          'payLightningInvoice', {'invoice': invoice});
        return ok == true;
      } catch (_) {
        // Fallback: normaler Weg
      }
    }
    final uri = Uri.parse('lightning:$invoice');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _donate() async {
    final t = AppLocalizations.of(context);
    final raw = _controller.text.trim().replaceAll('.', '').replaceAll(',', '');
    final amount = int.tryParse(raw) ?? 0;
    if (amount <= 0) {
      setState(() => _error = t.v4vErrInvalidAmount);
      return;
    }
    setState(() { _loading = true; _error = null; });

    final result = await V4VService.createInvoice(
      amountSats: amount,
      comment: 'V4V – 21Meetup',
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.ok || result.invoice == null) {
      setState(() => _error = _errorText(t, result.error ?? 'generic'));
      return;
    }

    final opened = await _openInvoice(result.invoice!);
    if (!mounted) return;
    if (!opened) {
      _showInvoiceFallback(t, result.invoice!);
    }
  }

  void _showInvoiceFallback(AppLocalizations t, String invoice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.v4vNoWalletTitle, style: const TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(t.v4vNoWalletBody, style: const TextStyle(color: cTextSecondary, fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(kTileRadius)),
            child: Text(invoice, maxLines: 4, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: cTextSecondary, fontSize: 12).copyWith(fontFamily: fontMono)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(t.v4vCopyInvoice),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invoice));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.v4vCopied), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: Text(t.v4vTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        children: [
          // Kopf: Symbol mit Glow
          Center(
            child: Container(
              width: 84, height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  cOrange.withValues(alpha: 0.25),
                  cOrange.withValues(alpha: 0.04),
                ]),
                border: Border.all(color: cOrange.withValues(alpha: 0.35), width: 1),
              ),
              child: const Icon(Icons.bolt_rounded, color: cOrange, size: 42),
            ),
          ),
          const SizedBox(height: 22),
          Text(t.v4vHeadline,
              textAlign: TextAlign.center,
              style: const TextStyle(color: cText, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          const SizedBox(height: 14),

          // Erklärung als Karte
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(kTileRadius),
              border: Border.all(color: cTileBorder, width: 0.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.v4vExplain1,
                  style: const TextStyle(color: cTextSecondary, fontSize: 14.5, height: 1.6)),
              const SizedBox(height: 10),
              Text(t.v4vExplain2,
                  style: const TextStyle(color: cTextSecondary, fontSize: 14.5, height: 1.6)),
            ]),
          ),
          const SizedBox(height: 28),

          // Betrag — groß und zentriert
          Center(
            child: Text(t.v4vAmountLabel.toUpperCase(),
                style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cTileBorder, width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  autofocus: false,
                  style: const TextStyle(color: cText, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 1),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: cTextTertiary, fontSize: 36, fontWeight: FontWeight.w800),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) { if (_error != null) setState(() => _error = null); },
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 12),
                child: Text('Sats', style: TextStyle(color: cOrange, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline_rounded, color: cRed, size: 16),
              const SizedBox(width: 6),
              Flexible(child: Text(_error!, style: const TextStyle(color: cRed, fontSize: 13))),
            ]),
          ],

          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cOrange,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _loading ? null : _donate,
              icon: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                  : const Icon(Icons.bolt_rounded, size: 22),
              label: Text(_loading ? '' : t.v4vDonateButton,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.favorite_rounded, color: cOrange, size: 13),
              const SizedBox(width: 6),
              Text('${t.v4vRecipient}: $kV4VLightningAddress',
                  style: const TextStyle(color: cTextTertiary, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}
