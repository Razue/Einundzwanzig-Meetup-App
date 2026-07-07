// ============================================
//  V4V — Value for Value Spenden-Maske
// ============================================
//  Erklärt Value for Value, nimmt einen frei wählbaren Sats-Betrag,
//  holt eine Invoice über die Lightning-Adresse des Projekts und öffnet
//  die Wallet-Auswahl des Systems (lightning:-URI) zum Bezahlen.
// ============================================

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

    // Invoice per lightning:-URI öffnen -> System zeigt Wallet-Auswahl
    final invoice = result.invoice!;
    final uri = Uri.parse('lightning:$invoice');
    final opened = await canLaunchUrl(uri)
        ? await launchUrl(uri, mode: LaunchMode.externalApplication)
        : false;

    if (!mounted) return;
    if (!opened) {
      // Keine Wallet gefunden: Invoice zum Kopieren anbieten
      _showInvoiceFallback(t, invoice);
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
        padding: const EdgeInsets.all(20),
        children: [
          // Symbol
          Center(
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: cOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, color: cOrange, size: 34),
            ),
          ),
          const SizedBox(height: 20),
          Text(t.v4vHeadline,
              textAlign: TextAlign.center,
              style: const TextStyle(color: cText, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(t.v4vExplain1,
              style: const TextStyle(color: cTextSecondary, fontSize: 15, height: 1.6)),
          const SizedBox(height: 10),
          Text(t.v4vExplain2,
              style: const TextStyle(color: cTextSecondary, fontSize: 15, height: 1.6)),
          const SizedBox(height: 24),

          // Betrag
          Text(t.v4vAmountLabel.toUpperCase(),
              style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(color: cTextTertiary),
              suffixText: 'Sats',
              suffixStyle: const TextStyle(color: cTextSecondary, fontSize: 14),
              filled: true,
              fillColor: cCard,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kTileRadius),
                borderSide: const BorderSide(color: cBorder, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kTileRadius),
                borderSide: const BorderSide(color: cOrange, width: 1.5),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.error_outline_rounded, color: cRed, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(_error!, style: const TextStyle(color: cRed, fontSize: 13))),
            ]),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cOrange,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
              ),
              onPressed: _loading ? null : _donate,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                  : Text(t.v4vDonateButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('${t.v4vRecipient}: $kV4VLightningAddress',
                style: const TextStyle(color: cTextTertiary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
