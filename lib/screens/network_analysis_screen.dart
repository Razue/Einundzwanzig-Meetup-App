import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../models/user.dart';
import '../services/nostr_service.dart';
import '../services/coattendance_service.dart';

class NetworkAnalysisScreen extends StatefulWidget {
  final String? initialTargetNpub;
  const NetworkAnalysisScreen({super.key, this.initialTargetNpub});

  @override
  State<NetworkAnalysisScreen> createState() => _NetworkAnalysisScreenState();
}

class _NetworkAnalysisScreenState extends State<NetworkAnalysisScreen> {
  final TextEditingController _npubCtrl = TextEditingController();
  String _myNpub = '';
  bool _loading = false;
  CoAttNetwork? _net;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMe();
    if (widget.initialTargetNpub != null) {
      _npubCtrl.text = widget.initialTargetNpub!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _analyze());
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

  Future<void> _analyze() async {
    final target = _npubCtrl.text.trim().toLowerCase().replaceFirst('nostr:', '');
    setState(() {
      _error = null;
      _net = null;
    });
    if (!NostrService.isValidNpub(target)) {
      setState(() => _error = AppLocalizations.of(context).cnInvalidNpub);
      return;
    }
    setState(() => _loading = true);
    try {
      final net = await CoAttendanceService.analyze(myNpub: _myNpub, targetNpub: target);
      if (mounted) setState(() => _net = net);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).cnNoConnection);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scan() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _NpubScanScreen()),
    );
    if (scanned != null) {
      _npubCtrl.text = scanned;
      _analyze();
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
        title: Text(t.cnTitle,
            style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.cnSubtitle, style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          _buildInput(t),
          const SizedBox(height: 16),
          if (_error != null) _buildError(_error!),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: cOrange, strokeWidth: 2)),
            ),
          if (!_loading && _net != null) ..._buildResult(t, _net!),
          const SizedBox(height: 20),
          _buildPrivacyNote(t),
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
          hintText: t.cnEnterNpub,
          hintStyle: const TextStyle(color: cTextTertiary, fontSize: 13),
          prefixIcon: const Icon(Icons.key_rounded, color: cTextSecondary, size: 18),
          filled: true,
          fillColor: cCard,
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
            label: Text(t.cnScan),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _loading ? null : _analyze,
            icon: const Icon(Icons.hub_rounded, size: 18),
            label: Text(t.cnAnalyze, style: const TextStyle(fontWeight: FontWeight.w700)),
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

  List<Widget> _buildResult(AppLocalizations t, CoAttNetwork net) {
    if (!net.hasAnyConnection) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
          child: Column(children: [
            const Icon(Icons.hub_outlined, color: cTextTertiary, size: 44),
            const SizedBox(height: 14),
            Text(t.cnNoConnection, textAlign: TextAlign.center, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(t.cnNoConnectionSub, textAlign: TextAlign.center, style: const TextStyle(color: cTextSecondary, fontSize: 12, height: 1.4)),
          ]),
        ),
      ];
    }

    return [
      // Direkt-getroffen-Banner
      if (net.hasDirectOverlap)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: cGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cGreen.withValues(alpha: 0.3), width: 0.5)),
          child: Row(children: [
            const Icon(Icons.celebration_rounded, color: cGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(t.cnDirectMet, style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700))),
          ]),
        ),

      // Graph
      Container(
        height: 240,
        decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
        child: CustomPaint(
          painter: _NetworkGraphPainter(
            sharedCount: net.sharedMeetups.length,
            mutualCount: net.mutualContacts.length,
            youLabel: t.cnYou,
            targetLabel: t.cnTarget,
          ),
          child: const SizedBox.expand(),
        ),
      ),
      const SizedBox(height: 16),

      // Stat-Kacheln
      Row(children: [
        _statTile(t.cnSharedMeetups, '${net.sharedMeetups.length}', Icons.groups_rounded, cOrange),
        const SizedBox(width: 10),
        _statTile(t.cnMutualContacts, '${net.mutualContacts.length}', Icons.people_alt_rounded, cCyan),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _statTile(t.cnTotalMeetups, '${net.targetTotalMeetups}', Icons.event_rounded, cTextSecondary),
        const SizedBox(width: 10),
        _statTile(t.cnTotalContacts, '${net.targetTotalContacts}', Icons.diversity_3_rounded, cTextSecondary),
      ]),
      const SizedBox(height: 16),

      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cOrange.withValues(alpha: 0.2), width: 0.5)),
        child: Row(children: [
          const Icon(Icons.lightbulb_outline_rounded, color: cOrange, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(t.cnTrustHint, style: const TextStyle(color: cTextSecondary, fontSize: 11, height: 1.4))),
        ]),
      ),
    ];
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: cText, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildPrivacyNote(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
      child: Row(children: [
        const Icon(Icons.privacy_tip_outlined, color: cTextTertiary, size: 15),
        const SizedBox(width: 8),
        Expanded(child: Text(t.cnPrivacyNote, style: const TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4))),
      ]),
    );
  }
}

/// Zeichnet einen einfachen Netzwerk-Graph: Du (links) — gemeinsame Kontakte
/// (Mitte) — Zielperson (rechts), mit Verbindungslinien.
class _NetworkGraphPainter extends CustomPainter {
  final int sharedCount;
  final int mutualCount;
  final String youLabel;
  final String targetLabel;

  _NetworkGraphPainter({
    required this.sharedCount,
    required this.mutualCount,
    required this.youLabel,
    required this.targetLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final you = Offset(size.width * 0.18, size.height * 0.5);
    final target = Offset(size.width * 0.82, size.height * 0.5);

    final linePaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Mittlere Knoten (gemeinsame Kontakte), max 5 zeichnen
    final n = mutualCount.clamp(0, 5);
    final midPoints = <Offset>[];
    if (n > 0) {
      for (int i = 0; i < n; i++) {
        final frac = (i + 1) / (n + 1);
        midPoints.add(Offset(size.width * 0.5, size.height * frac));
      }
    }

    // Direkte Verbindung (gemeinsame Meetups) als dickere Linie
    if (sharedCount > 0) {
      final directPaint = Paint()
        ..color = const Color(0xFF4ADE80).withValues(alpha: 0.6)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(you, target, directPaint);
    }

    // Linien you<->mid<->target
    for (final m in midPoints) {
      canvas.drawLine(you, m, linePaint);
      canvas.drawLine(m, target, linePaint);
    }
    if (midPoints.isEmpty && sharedCount == 0) {
      canvas.drawLine(you, target, linePaint);
    }

    // Mittlere Knoten zeichnen
    final midNode = Paint()..color = const Color(0xFF22D3EE);
    for (final m in midPoints) {
      canvas.drawCircle(m, 7, midNode);
    }

    // Du-Knoten (cyan)
    _drawNode(canvas, you, const Color(0xFF22D3EE), 16);
    _drawLabel(canvas, you, youLabel, size, below: true);

    // Ziel-Knoten (orange)
    _drawNode(canvas, target, const Color(0xFFF7931A), 16);
    _drawLabel(canvas, target, targetLabel, size, below: true);
  }

  void _drawNode(Canvas canvas, Offset c, Color color, double r) {
    final glow = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(c, r + 4, glow);
    canvas.drawCircle(c, r, Paint()..color = color);
  }

  void _drawLabel(Canvas canvas, Offset c, String text, Size size, {bool below = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.35);
    final dy = below ? c.dy + 22 : c.dy - 22 - tp.height;
    tp.paint(canvas, Offset(c.dx - tp.width / 2, dy));
  }

  @override
  bool shouldRepaint(covariant _NetworkGraphPainter old) =>
      old.sharedCount != sharedCount || old.mutualCount != mutualCount;
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
          HapticFeedback.mediumImpact();
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
      appBar: AppBar(title: Text(AppLocalizations.of(context).cnScan), backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(children: [
        MobileScanner(onDetect: _onDetect),
        Positioned(
          bottom: 60, left: 40, right: 40,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cCyan)),
            child: Text(AppLocalizations.of(context).cnEnterNpub, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4), textAlign: TextAlign.center),
          ),
        ),
      ]),
    );
  }
}
