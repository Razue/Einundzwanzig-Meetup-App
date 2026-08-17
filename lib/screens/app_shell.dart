import 'dart:ui';
import '../services/haptic_service.dart';
import '../widgets/shadows.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../services/app_logger.dart';
import '../services/guide_service.dart';
import '../tours/home_tour.dart';
import 'home_screen.dart';
import 'badge_wallet.dart';
import 'events_hub_screen.dart';
import 'meetup_verification.dart';
import 'reputation_qr.dart';
import 'nearby_meetups_screen.dart';
import '../models/meetup.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _checkHomeTour();
  }

  /// Startet die Dashboard-Tour beim ersten Mal.
  ///
  /// Warum das Warten: Der HomeScreen laedt Nutzer, Badges und Termine
  /// asynchron. Die GlobalKeys der Kacheln existieren erst, wenn er MIT
  /// Daten gezeichnet wurde — startete die Tour vorher, faende sie kein
  /// einziges Ziel und arbeitete sich unsichtbar durch alle Schritte.
  ///
  /// Geprueft werden die beiden Pflicht-Kacheln: Trust Score und
  /// Home-Meetup lassen sich nicht ausblenden, sie sind also immer da,
  /// sobald der Bildschirm steht.
  Future<void> _checkHomeTour() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final guide = context.read<GuideService>();
      if (await guide.wasTourCompleted(GuideTour.home)) return;
      if (!mounted) return;

      // ERST FRAGEN, dann fuehren.
      //
      // Die Einrichtung der Identitaet leitet inzwischen selbst Schritt fuer
      // Schritt an — eine zweite Fuehrung gleich hinterher, ungefragt und
      // ueber neunzehn Kacheln, waere zu viel. Wer ablehnt, wird nicht
      // wieder gefragt; ueber "Tour wiederholen" in den Einstellungen
      // kommt man jederzeit zurueck.
      if (await guide.shouldAskForOnboarding()) {
        await guide.markOnboardingAsked();
        if (!mounted) return;
        final wants = await _askForTour();
        if (wants != true) return;
      }
      if (!mounted) return;

      const maxAttempts = 10;
      const waitPerAttempt = Duration(milliseconds: 500);

      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        await Future.delayed(waitPerAttempt);
        if (!mounted) return;

        final ready = HomeTour.homeMeetupKey.currentContext != null &&
            HomeTour.trustScoreKey.currentContext != null;
        AppLogger.debug('Guide',
            'Dashboard-Tour, Versuch $attempt/$maxAttempts — Ziele bereit: $ready');
        if (ready) {
          await guide.startTour(GuideTour.home, HomeTour.steps());
          return;
        }
      }

      AppLogger.warn('Guide',
          'Ziel-Widgets nach ${maxAttempts * waitPerAttempt.inMilliseconds} ms nicht gefunden — Dashboard-Tour startet nicht.');
    });
  }

  /// Fragt, ob die Tour laufen soll. null oder false = nein.
  Future<bool?> _askForTour() {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cOrange, width: 1.5),
        ),
        title: Row(children: [
          const Icon(Icons.lightbulb_outline, color: cOrange, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.guideWelcomeTitle,
                style: const TextStyle(
                    color: cText, fontSize: 19, fontWeight: FontWeight.bold)),
          ),
        ]),
        content: Text(l10n.guideWelcomeBody,
            style: const TextStyle(
                color: cTextSecondary, fontSize: 15, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.guideNoThanks,
                style: const TextStyle(color: cTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cOrange,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.guideStart,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _doHaptic() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('haptic_enabled') ?? true) HapticService.light();
  }

  void _onTabTap(int index) {
    if (index == 2) return;
    _doHaptic();
    setState(() => _currentIndex = index);
    // Beim Zurückwechseln auf den Home-Tab die Kachel-Daten auffrischen,
    // damit ein neu angelegter/aktualisierter Termin sofort erscheint.
    if (index == 0) {
      _homeKey.currentState?.refreshAfterScan();
    }
  }

  // Öffnet den "Meetups in der Nähe"-Screen als eigene Route
  void _openNearby() async {
    _doHaptic();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NearbyMeetupsScreen()),
    );
  }

  // Öffnet das Scan-Auswahlmenü mit drei Optionen
  void _openScanner() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('haptic_enabled') ?? true) HapticService.medium();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ScanSheet(
        onBadge: () async {
          Navigator.pop(ctx);
          final d = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0);
          await Navigator.push<bool>(context, PageRouteBuilder(
            pageBuilder: (_, _, _) => MeetupVerificationScreen(meetup: d),
            transitionsBuilder: (_, a, _, c) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c)));
          // Bei Erfolg wechselt der Verification-Screen selbst direkt in die
          // Wallet (pushReplacement). Hier danach nur Home-Daten auffrischen.
          _homeKey.currentState?.refreshAfterScan();
        },
        onReputation: () async {
          Navigator.pop(ctx);
          await Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, _, _) => const ReputationQRScreen(),
            transitionsBuilder: (_, a, _, c) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c)));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: cDark,
      body: IndexedStack(
        index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
        children: [
          HomeScreen(key: _homeKey),
          BadgeWalletScreen(),
          const EventsHubScreen(),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 56 + bottomPad + 16,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0, right: 0, bottom: 0,
              height: 56 + bottomPad,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cDark.withValues(alpha: 0.92),
                      border: const Border(top: BorderSide(color: cBorder, width: 0.5)),
                    ),
                    padding: EdgeInsets.only(bottom: bottomPad),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _navItem(0, Icons.home_rounded, Icons.home_outlined, AppLocalizations.of(context).navHome,
                            navKey: HomeTour.homeTabKey),
                        _navItem(1, Icons.style_rounded, Icons.style_outlined, AppLocalizations.of(context).navWalletTab,
                            navKey: HomeTour.badgeTabKey),
                        const SizedBox(width: 60),
                        _navItem(3, Icons.event_rounded, Icons.event_outlined, AppLocalizations.of(context).navEvents,
                            navKey: HomeTour.eventsTabKey),
                        _navAction(Icons.near_me_rounded, Icons.near_me_outlined, AppLocalizations.of(context).navNearby, _openNearby,
                            navKey: HomeTour.nearbyTabKey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: bottomPad + 10,
              left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  key: HomeTour.scanFabKey,
                  onTap: _openScanner,
                  child: Container(
                    width: 62, height: 62,
                    decoration: BoxDecoration(
                      gradient: gradientOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: cDark, width: 3),
                      boxShadow: shadowForElevation(4, accent: cOrange),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 26),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData a, IconData ia, String l, {Key? navKey}) {
    final active = _currentIndex == i;
    return GestureDetector(
      key: navKey,
      behavior: HitTestBehavior.opaque, onTap: () => _onTabTap(i),
      child: SizedBox(width: 60, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(active ? a : ia, color: active ? cText : cTextTertiary, size: 24),
        const SizedBox(height: 2),
        Text(l, style: TextStyle(color: active ? cText : cTextTertiary, fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ])));
  }

  // Leisten-Eintrag, der eine Route öffnet (kein Tab-State)
  Widget _navAction(IconData a, IconData ia, String l, VoidCallback onTap,
      {Key? navKey}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: onTap,
      child: SizedBox(width: 60, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(ia, color: cTextTertiary, size: 24),
        const SizedBox(height: 2),
        Text(l, style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w400)),
      ])));
  }
}

// ═══════════════════════════════════════════════════════
// Scan-Auswahl-Sheet — drei Optionen
// ═══════════════════════════════════════════════════════
class _ScanSheet extends StatelessWidget {
  final VoidCallback onBadge;
  final VoidCallback onReputation;

  const _ScanSheet({required this.onBadge, required this.onReputation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        // Option 1: Badge / Meetup QR
        _ScanOption(
          icon: Icons.qr_code_rounded,
          iconColor: cOrange,
          title: AppLocalizations.of(context).scanBadge,
          subtitle: AppLocalizations.of(context).scanBadgeSub,
          onTap: onBadge,
        ),
        const SizedBox(height: 8),

        // Option 2: Reputation prüfen
        _ScanOption(
          icon: Icons.workspace_premium_rounded,
          iconColor: Colors.amber,
          title: AppLocalizations.of(context).scanReputation,
          subtitle: AppLocalizations.of(context).scanReputationSub,
          onTap: onReputation,
        ),

        const SizedBox(height: 16),
      ]),
    );
  }
}

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ScanOption({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 18),
        ]),
      ),
    );
  }
}



