import 'dart:convert';
import '../services/haptic_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../models/user.dart';
import '../services/nostr_service.dart';
import '../services/coattendance_service.dart';

/// "Person prüfen" — Präsenz-Check über echte Meetup-Begegnungen.
/// npub eingeben ODER Reputations-/npub-QR scannen -> Verbindungsgrad + Pfad.
class VerifyPersonScreen extends StatefulWidget {
  final String? initialTargetNpub;
  const VerifyPersonScreen({super.key, this.initialTargetNpub});

  @override
  State<VerifyPersonScreen> createState() => _VerifyPersonScreenState();
}

class _VerifyPersonScreenState extends State<VerifyPersonScreen> {
  final TextEditingController _npubCtrl = TextEditingController();
  String _myNpub = '';
  bool _checking = false;
  PresenceCheck? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMe();
    if (widget.initialTargetNpub != null) {
      _npubCtrl.text = widget.initialTargetNpub!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _npubCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    final u = await UserProfile.load();
    if (mounted) setState(() => _myNpub = u.nostrNpub);
  }

  Future<void> _check() async {
    final target = _npubCtrl.text.trim().toLowerCase().replaceFirst('nostr:', '');
    setState(() { _error = null; _result = null; });
    if (!NostrService.isValidNpub(target)) {
      setState(() => _error = AppLocalizations.of(context).vpInvalidNpub);
      return;
    }
    setState(() => _checking = true);
    try {
      final res = await CoAttendanceService.verifyPerson(myNpub: _myNpub, targetNpub: target);
      if (mounted) setState(() => _result = res);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).vpNoneTitle);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _scan() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScanScreen()),
    );
    if (scanned != null) {
      _npubCtrl.text = scanned;
      _check();
    }
  }

  Future<void> _openNostr(String npub) async {
    final nostrUri = Uri.parse('nostr:$npub');
    final webUri = Uri.parse('https://njump.me/$npub');
    try {
      if (!await launchUrl(nostrUri, mode: LaunchMode.externalApplication)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try { await launchUrl(webUri, mode: LaunchMode.externalApplication); } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.vpTitle,
            style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.vpIntro, style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          _buildInput(t),
          const SizedBox(height: 16),
          if (_error != null) _buildError(_error!),
          if (_checking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: cOrange, strokeWidth: 2)),
            ),
          if (!_checking && _result != null) ..._buildResult(t, _result!),
        ],
      ),
    );
  }

  Widget _buildInput(AppLocalizations t) {
    return Column(children: [
      TextField(
        controller: _npubCtrl,
        style: TextStyle(color: cText, fontSize: 13, fontFamily: fontMono),
        decoration: InputDecoration(
          hintText: t.vpEnterNpub,
          hintStyle: const TextStyle(color: cTextTertiary, fontSize: 12),
          prefixIcon: const Icon(Icons.alternate_email_rounded, color: cTextSecondary, size: 18),
          filled: true, fillColor: cCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cOrange, width: 1)),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: cTextSecondary, side: const BorderSide(color: cTileBorder), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _scan,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: Text(t.vpScanQr),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _checking ? null : _check,
            icon: const Icon(Icons.verified_user_rounded, size: 18),
            label: Text(t.vpCheck, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ]);
  }

  Widget _buildError(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cRed.withValues(alpha: 0.3), width: 0.5)),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: cRed, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: cText, fontSize: 13))),
      ]),
    );
  }

  List<Widget> _buildResult(AppLocalizations t, PresenceCheck res) {
    // Status-Bestimmung
    Color color;
    IconData icon;
    String title;
    String sub;

    if (res.isSelf) {
      color = cCyan; icon = Icons.person_rounded;
      title = t.vpSelfTitle; sub = '';
    } else if (res.isDirect) {
      color = cGreen; icon = Icons.verified_rounded;
      title = t.vpDirectTitle;
      sub = res.sharedMeetups.length == 1 ? t.vpDirectSubOne : t.vpDirectSub(res.sharedMeetups.length);
    } else if (res.found) {
      color = cOrange; icon = Icons.hub_rounded;
      title = t.vpIndirectTitle(res.degree);
      sub = t.vpIndirectSub;
    } else {
      color = cTextTertiary; icon = Icons.link_off_rounded;
      title = t.vpNoneTitle;
      sub = res.targetInNetwork ? t.vpNoneSub : t.vpNotInNetwork;
    }

    return [
      // Status-Karte
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
        ),
        child: Column(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center,
              style: TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w800)),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(sub, textAlign: TextAlign.center,
                style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4)),
          ],
        ]),
      ),

      // Pfad-Visualisierung (nur wenn gefunden und nicht selbst/direkt-trivial)
      if (res.found && !res.isSelf && res.path.length >= 2) ...[
        const SizedBox(height: 20),
        Text(t.vpPathTitle,
            style: const TextStyle(color: cTextTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ..._buildPath(t, res),
      ],

      // Vertrauens-Hinweis
      if (res.found && !res.isSelf) ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(color: cOrange.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(children: [
            const Icon(Icons.lightbulb_outline_rounded, color: cOrange, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(t.vpTrustNote,
                style: const TextStyle(color: cTextSecondary, fontSize: 11, height: 1.4))),
          ]),
        ),
      ],
    ];
  }

  List<Widget> _buildPath(AppLocalizations t, PresenceCheck res) {
    final widgets = <Widget>[];
    for (int i = 0; i < res.path.length; i++) {
      final npub = res.path[i];
      final isFirst = i == 0;
      final isLast = i == res.path.length - 1;
      final color = isFirst ? cCyan : (isLast ? cOrange : cTextSecondary);
      final label = isFirst ? t.vpYou : (isLast ? t.vpTarget : NostrService.shortenNpub(npub));

      widgets.add(
        InkWell(
          onTap: (isFirst) ? null : () => _openNostr(npub),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(kTileRadius),
              border: Border.all(
                color: (isFirst || isLast) ? color.withValues(alpha: 0.4) : cTileBorder,
                width: (isFirst || isLast) ? 1 : 0.5),
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(
                  isFirst ? Icons.person_rounded : (isLast ? Icons.flag_rounded : Icons.person_outline_rounded),
                  color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
                  if (!isFirst && !isLast)
                    Text(NostrService.shortenNpub(npub),
                        style: TextStyle(color: cTextTertiary, fontSize: 10, fontFamily: fontMono)),
                ]),
              ),
              if (!isFirst)
                Icon(Icons.open_in_new_rounded, color: cTextTertiary.withValues(alpha: 0.6), size: 14),
            ]),
          ),
        ),
      );

      // Verbindungslinie zwischen den Knoten
      if (!isLast) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 29),
          child: Row(children: [
            Container(width: 2, height: 20, color: cTileBorder),
            const SizedBox(width: 12),
            Icon(Icons.groups_rounded, size: 11, color: cTextTertiary),
            const SizedBox(width: 5),
            Text(t.vpMetAt, style: const TextStyle(color: cTextTertiary, fontSize: 10, fontStyle: FontStyle.italic)),
          ]),
        ));
      }
    }
    return widgets;
  }
}

// QR-Scanner: erkennt sowohl reine npub-QRs als auch Reputations-QRs (JSON mit id.np)
class _QrScanScreen extends StatefulWidget {
  const _QrScanScreen();
  @override
  State<_QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<_QrScanScreen> {
  bool _done = false;

  String? _extractNpub(String raw) {
    String code = raw.trim();
    // 1. Reiner npub (evtl. mit nostr: Prefix)
    String lower = code.toLowerCase();
    if (lower.startsWith('nostr:')) lower = lower.replaceFirst('nostr:', '');
    if (lower.startsWith('npub1') && lower.length > 50) return lower;
    // 2. Reputations-QR (JSON mit id.np)
    try {
      final data = jsonDecode(code);
      if (data is Map && data['id'] is Map) {
        final np = (data['id'] as Map)['np'];
        if (np is String && np.toLowerCase().startsWith('npub1')) {
          return np.toLowerCase();
        }
      }
    } catch (_) {}
    return null;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null) {
        final npub = _extractNpub(raw);
        if (npub != null) {
          setState(() => _done = true);
          HapticService.medium();
          Navigator.pop(context, npub);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(AppLocalizations.of(context).vpScanQr), backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(children: [
        MobileScanner(onDetect: _onDetect),
        Positioned(
          bottom: 60, left: 40, right: 40,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cOrange)),
            child: Text(AppLocalizations.of(context).vpEnterNpub,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4), textAlign: TextAlign.center),
          ),
        ),
      ]),
    );
  }
}
