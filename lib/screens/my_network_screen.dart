import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../models/user.dart';
import '../services/nostr_service.dart';
import '../services/coattendance_service.dart';
import 'verify_person_screen.dart';

/// Automatische Übersicht des eigenen Co-Attendance-Netzwerks (Grad 1-3).
/// Kein npub-Input — lädt direkt beim Öffnen.
class MyNetworkScreen extends StatefulWidget {
  const MyNetworkScreen({super.key});

  @override
  State<MyNetworkScreen> createState() => _MyNetworkScreenState();
}

class _MyNetworkScreenState extends State<MyNetworkScreen> {
  bool _loading = true;
  MyNetwork? _net;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await UserProfile.load();
      if (user.nostrNpub.isEmpty) {
        if (mounted) setState(() { _loading = false; _net = null; });
        return;
      }
      final net = await CoAttendanceService.buildMyNetwork(myNpub: user.nostrNpub);
      if (mounted) setState(() { _net = net; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _net = null; });
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
        title: Text(t.mnTitle,
            style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded, color: cTextSecondary, size: 22),
            tooltip: t.mnCheckPerson,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VerifyPersonScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cOrange, strokeWidth: 2))
          : RefreshIndicator(
              color: cOrange,
              backgroundColor: cCard,
              onRefresh: _load,
              child: _net == null || _net!.isEmpty
                  ? _buildEmpty(t)
                  : _buildContent(t, _net!),
            ),
    );
  }

  Widget _buildEmpty(AppLocalizations t) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.hub_outlined, color: cTextTertiary, size: 56),
        const SizedBox(height: 20),
        Text(t.mnEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(t.mnEmptySub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
      ],
    );
  }

  Widget _buildContent(AppLocalizations t, MyNetwork net) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(t.mnIntro,
            style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 20),

        // Graph
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(color: cTileBorder, width: 0.5),
          ),
          child: CustomPaint(
            painter: _RadialNetworkPainter(
              d1: net.degree1Count,
              d2: net.degree2Count,
              d3: net.degree3Count,
              youLabel: t.mnReachLabel,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 16),

        // Reichweiten-Kacheln
        Row(children: [
          _reachTile('${net.degree1Count}', t.mnDirectLabel, cGreen),
          const SizedBox(width: 8),
          _reachTile('${net.degree2Count}', '2.', cCyan),
          const SizedBox(width: 8),
          _reachTile('${net.degree3Count}', '3.', cOrange),
        ]),
        const SizedBox(height: 20),

        // Aufklappbare Listen pro Grad
        _degreeSection(t, net, 1, t.mnDegree1, t.mnDegree1Sub, cGreen),
        const SizedBox(height: 10),
        _degreeSection(t, net, 2, t.mnDegree2, t.mnDegree2Sub, cCyan),
        const SizedBox(height: 10),
        _degreeSection(t, net, 3, t.mnDegree3, t.mnDegree3Sub, cOrange),
        const SizedBox(height: 20),

        // Vertrauens-Hinweis
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
            Expanded(child: Text(t.mnTrustHint,
                style: const TextStyle(color: cTextSecondary, fontSize: 11, height: 1.4))),
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cSurface,
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(color: cTileBorder, width: 0.5),
          ),
          child: Row(children: [
            const Icon(Icons.privacy_tip_outlined, color: cTextTertiary, size: 15),
            const SizedBox(width: 8),
            Expanded(child: Text(t.mnPrivacyNote,
                style: const TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4))),
          ]),
        ),
      ],
    );
  }

  Widget _reachTile(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _degreeSection(AppLocalizations t, MyNetwork net, int degree,
      String title, String subtitle, Color color) {
    final contacts = net.byDegree[degree] ?? [];
    return Container(
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: color,
          collapsedIconColor: cTextTertiary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Center(child: Text('$degree.',
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800))),
          ),
          title: Text(title,
              style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
          subtitle: Text('${contacts.length} · $subtitle',
              style: const TextStyle(color: cTextTertiary, fontSize: 11)),
          children: contacts.isEmpty
              ? [Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('—', style: TextStyle(color: cTextTertiary)),
                )]
              : contacts.take(50).map((c) => _contactRow(t, c, color)).toList(),
        ),
      ),
    );
  }

  Widget _contactRow(AppLocalizations t, NetworkContact c, Color color) {
    String detail;
    if (c.degree == 1) {
      final n = c.sharedMeetupsWithMe.length;
      detail = n == 1 ? t.mnOneSharedMeetup : t.mnSharedMeetups(n);
    } else {
      final n = c.bridges.length;
      detail = n == 1 ? t.mnViaOneContact : t.mnViaContacts(n);
    }
    return InkWell(
      onTap: () => _openNostrProfile(c.npub),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: cTileBorder, width: 0.5)),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(
              c.degree == 1 ? Icons.person_rounded : Icons.person_outline_rounded,
              color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(NostrService.shortenNpub(c.npub),
                  style: TextStyle(color: cText, fontSize: 13, fontFamily: fontMono)),
              const SizedBox(height: 2),
              Text(detail, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
            ]),
          ),
          Icon(Icons.open_in_new_rounded, color: cTextTertiary.withValues(alpha: 0.6), size: 15),
        ]),
      ),
    );
  }

  /// Öffnet das Nostr-Profil: erst per nostr:-Schema (installierte App),
  /// Fallback auf njump.me im Browser.
  Future<void> _openNostrProfile(String npub) async {
    final nostrUri = Uri.parse('nostr:$npub');
    final webUri = Uri.parse('https://njump.me/$npub');
    try {
      if (!await launchUrl(nostrUri, mode: LaunchMode.externalApplication)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }
}

/// Zeichnet konzentrische Ringe: Ich (Mitte) -> Grad 1 -> 2 -> 3.
class _RadialNetworkPainter extends CustomPainter {
  final int d1, d2, d3;
  final String youLabel;
  _RadialNetworkPainter({required this.d1, required this.d2, required this.d3, required this.youLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = min(size.width, size.height) / 2 - 30;
    final r1 = maxR * 0.42;
    final r2 = maxR * 0.72;
    final r3 = maxR;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Ringe
    ringPaint.color = const Color(0xFF4ADE80).withValues(alpha: 0.25);
    canvas.drawCircle(center, r1, ringPaint);
    ringPaint.color = const Color(0xFF22D3EE).withValues(alpha: 0.20);
    canvas.drawCircle(center, r2, ringPaint);
    ringPaint.color = const Color(0xFFF7931A).withValues(alpha: 0.18);
    canvas.drawCircle(center, r3, ringPaint);

    // Knoten auf den Ringen verteilen
    _drawRingNodes(canvas, center, r1, d1, const Color(0xFF4ADE80), 5);
    _drawRingNodes(canvas, center, r2, d2, const Color(0xFF22D3EE), 4);
    _drawRingNodes(canvas, center, r3, d3, const Color(0xFFF7931A), 3.5);

    // Zentrum (ich)
    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 16, glow);
    canvas.drawCircle(center, 11, Paint()..color = Colors.white);
  }

  void _drawRingNodes(Canvas canvas, Offset center, double radius, int count, Color color, double nodeR) {
    if (count <= 0) return;
    final shown = min(count, 14);
    final lp = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    for (int i = 0; i < shown; i++) {
      final angle = (2 * pi * i / shown) - pi / 2;
      final p = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(center, p, lp);
      canvas.drawCircle(p, nodeR, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialNetworkPainter old) =>
      old.d1 != d1 || old.d2 != d2 || old.d3 != d3;
}
