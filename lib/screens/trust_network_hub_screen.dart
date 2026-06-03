import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import 'trust_path_screen.dart';
import 'network_analysis_screen.dart';

/// Zentraler Einstieg ins Vertrauensnetzwerk — für ALLE Nutzer zugänglich.
/// Bietet Vertrauenspfad und Netzwerk-Analyse als zwei Werkzeuge an.
class TrustNetworkHubScreen extends StatelessWidget {
  const TrustNetworkHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.tnHubTitle,
            style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(t.tnHubIntro,
              style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 20),
          _toolCard(
            context,
            icon: Icons.route_rounded,
            color: cCyan,
            title: t.tnHubPathTitle,
            subtitle: t.tnHubPathSub,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TrustPathScreen())),
          ),
          const SizedBox(height: 12),
          _toolCard(
            context,
            icon: Icons.hub_rounded,
            color: cOrange,
            title: t.tnHubNetTitle,
            subtitle: t.tnHubNetSub,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NetworkAnalysisScreen())),
          ),
        ],
      ),
    );
  }

  Widget _toolCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: cTextTertiary, fontSize: 12, height: 1.3)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 22),
        ]),
      ),
    );
  }
}
