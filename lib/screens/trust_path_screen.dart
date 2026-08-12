import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../models/user.dart';
import '../services/nostr_service.dart';
import '../services/trust_path_service.dart';

class TrustPathScreen extends StatefulWidget {
  /// Optional: direkt mit einem Ziel-npub starten (z.B. nach Scan im Profil).
  final String? initialTargetNpub;
  const TrustPathScreen({super.key, this.initialTargetNpub});

  @override
  State<TrustPathScreen> createState() => _TrustPathScreenState();
}

class _TrustPathScreenState extends State<TrustPathScreen> {
  final TextEditingController _npubCtrl = TextEditingController();
  String _myNpub = '';
  bool _searching = false;
  TrustPathResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMe();
    if (widget.initialTargetNpub != null) {
      _npubCtrl.text = widget.initialTargetNpub!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _npubCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    final user = await UserProfile.load();
    if (mounted) setState(() => _myNpub = user.nostrNpub);
  }

  Future<void> _search() async {
    final target = _npubCtrl.text.trim().toLowerCase().replaceFirst('nostr:', '');
    setState(() {
      _error = null;
      _result = null;
    });

    if (!NostrService.isValidNpub(target)) {
      setState(() => _error = AppLocalizations.of(context).tpInvalidNpub);
      return;
    }
    if (_myNpub.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).tpNoPathSelf);
      return;
    }

    setState(() => _searching = true);
    try {
      final res = await TrustPathService.findPath(fromNpub: _myNpub, toNpub: target);
      if (mounted) setState(() => _result = res);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).tpNoPath);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _scan() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _NpubScanScreen()),
    );
    if (scanned != null) {
      _npubCtrl.text = scanned;
      _search();
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
        title: Text(t.tpTitle,
            style: const TextStyle(
                color: cText, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.tpSubtitle,
              style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          _buildInput(t),
          const SizedBox(height: 16),
          if (_error != null) _buildError(_error!),
          if (_searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: cOrange, strokeWidth: 2)),
            ),
          if (!_searching && _result != null) _buildResult(t, _result!),
          const SizedBox(height: 24),
          _buildHint(t),
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
          hintText: t.tpEnterNpub,
          hintStyle: const TextStyle(color: cTextTertiary, fontSize: 13),
          prefixIcon: const Icon(Icons.key_rounded, color: cTextSecondary, size: 18),
          filled: true,
          fillColor: cCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cTileBorder, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cTileBorder, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cOrange, width: 1),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: cTextSecondary,
              side: const BorderSide(color: cTileBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _scan,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: Text(t.tpScan),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: cOrange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _searching ? null : _search,
            icon: const Icon(Icons.route_rounded, size: 18),
            label: Text(t.tpFind, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ]);
  }

  Widget _buildError(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cRed.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: cRed, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: cText, fontSize: 13))),
      ]),
    );
  }

  Widget _buildResult(AppLocalizations t, TrustPathResult res) {
    if (!res.found) {
      String reason;
      if (!res.selfIsInNetwork) {
        reason = t.tpNoPathSelf;
      } else if (!res.targetIsInNetwork) {
        reason = t.tpNoPathTarget;
      } else {
        reason = t.tpNoPathBetween;
      }
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: Column(children: [
          const Icon(Icons.link_off_rounded, color: cTextTertiary, size: 44),
          const SizedBox(height: 14),
          Text(t.tpNoPath,
              textAlign: TextAlign.center,
              style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(reason,
              textAlign: TextAlign.center,
              style: const TextStyle(color: cTextSecondary, fontSize: 12, height: 1.4)),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header: Anzahl Sprünge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cGreen.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, color: cGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              res.degrees <= 1 ? t.tpDirect : t.tpFound(res.degrees),
              style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      // Die Kette
      ..._buildChain(t, res),
    ]);
  }

  List<Widget> _buildChain(AppLocalizations t, TrustPathResult res) {
    final widgets = <Widget>[];
    for (int i = 0; i < res.path.length; i++) {
      final node = res.path[i];
      final isFirst = i == 0;
      final isLast = i == res.path.length - 1;
      widgets.add(_buildNodeRow(t, node, isFirst: isFirst, isLast: isLast));
      if (!isLast) widgets.add(_buildConnector(t));
    }
    return widgets;
  }

  Widget _buildNodeRow(AppLocalizations t, TrustPathNode node,
      {required bool isFirst, required bool isLast}) {
    final Color accent = isFirst ? cCyan : (isLast ? cOrange : cTextSecondary);
    final String roleLabel = isFirst ? t.tpYou : (isLast ? t.tpTarget : '');
    final displayName = node.name.isNotEmpty
        ? node.name
        : (isFirst ? t.tpYou : NostrService.shortenNpub(node.npub));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(
            color: (isFirst || isLast) ? accent.withValues(alpha: 0.4) : cTileBorder,
            width: (isFirst || isLast) ? 1 : 0.5),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFirst ? Icons.person_rounded : (isLast ? Icons.flag_rounded : Icons.person_outline_rounded),
            color: accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              if (roleLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(roleLabel,
                      style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text(
              node.meetup.isNotEmpty ? node.meetup : NostrService.shortenNpub(node.npub),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cTextTertiary, fontSize: 11, fontFamily: fontMono),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildConnector(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.only(left: 33),
      child: Row(children: [
        Container(width: 2, height: 28, color: cTileBorder),
        const SizedBox(width: 14),
        Icon(Icons.arrow_downward_rounded, size: 12, color: cTextTertiary),
        const SizedBox(width: 6),
        Text(t.tpVouchesFor,
            style: const TextStyle(color: cTextTertiary, fontSize: 10, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildHint(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: cTextTertiary, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(t.tpHint,
              style: const TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4)),
        ),
      ]),
    );
  }
}

// Kompakter npub-QR-Scanner
class _NpubScanScreen extends StatefulWidget {
  const _NpubScanScreen();
  @override
  State<_NpubScanScreen> createState() => _NpubScanScreenState();
}

class _NpubScanScreenState extends State<_NpubScanScreen> {
  bool _done = false;

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      String? code = barcode.rawValue;
      if (code != null) {
        code = code.trim().toLowerCase();
        if (code.startsWith('nostr:')) code = code.replaceFirst('nostr:', '');
        if (code.startsWith('npub1') && code.length > 50) {
          setState(() => _done = true);
          HapticService.medium();
          Navigator.pop(context, code);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).tpScan),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(children: [
        MobileScanner(onDetect: _onDetect),
        Positioned(
          bottom: 60,
          left: 40,
          right: 40,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(kTileRadius),
              border: Border.all(color: cOrange),
            ),
            child: Text(
              AppLocalizations.of(context).tpEnterNpub,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ]),
    );
  }
}
