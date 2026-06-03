import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';
import '../services/rolling_qr_service.dart';
import '../services/meetup_service.dart';
import 'wot_dashboard.dart';
import 'meetup_session_wizard.dart';
import 'rolling_qr_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _isSuperAdmin = false;
  String _adminNpub = '';
  String _promotionSource = '';

  // --- Session State ---
  DateTime? _sessionExpiry;
  Timer? _countdownTimer;
  String _timeLeft = "";

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _checkSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _loadAdminInfo() async {
    final user = await UserProfile.load();
    final npub = await NostrService.getNpub();
    if (mounted) {
      setState(() {
        _isSuperAdmin = npub == AdminRegistry.superAdminNpub;
        _adminNpub = npub ?? '';
        _promotionSource = user.promotionSource;
      });
    }
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final int? expiryUnix = prefs.getInt('rqr_session_expires');

    if (expiryUnix != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiryUnix * 1000);
      if (DateTime.now().isBefore(expiry)) {
        setState(() {
          _sessionExpiry = expiry;
        });
        _startTimer();
      } else {
        await RollingQRService.endSession();
        setState(() {
          _sessionExpiry = null;
        });
      }
    } else {
      setState(() {
        _sessionExpiry = null;
      });
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionExpiry != null) {
        final diff = _sessionExpiry!.difference(DateTime.now());
        if (diff.isNegative) {
          _checkSession();
        } else {
          if (mounted) {
            setState(() {
              _timeLeft = "${diff.inHours}h ${(diff.inMinutes % 60).toString().padLeft(2, '0')}m ${(diff.inSeconds % 60).toString().padLeft(2, '0')}s";
            });
          }
        }
      }
    });
  }

  Future<void> _startNewSession() async {
    final user = await UserProfile.load();
    final meetupId = user.homeMeetupId.isNotEmpty ? user.homeMeetupId : 'unknown-meetup';
    final compactId = meetupId.toLowerCase().replaceAll(' ', '-');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: cOrange)),
    );

    try {
      await RollingQRService.getOrCreateSession(
        meetupId: compactId,
        meetupName: meetupId,
        meetupCountry: '',
        blockHeight: 0,
      );

      if (mounted) {
        Navigator.pop(context);
        _checkSession();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MeetupSessionWizard()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).wotErrorShort(e.toString())), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _endSessionEarly() async {
    await RollingQRService.endSession();
    _countdownTimer?.cancel();
    setState(() {
      _sessionExpiry = null;
    });
  }

  // Öffnet das Einundzwanzig-Portal, damit der Organisator dort einen
  // Termin eintragen kann. Aktuell der direkte Weg ins Portal (Login nötig);
  // echte In-App-Erstellung folgt, sobald das Portal eine API bereitstellt.
  Future<void> _openPortalForEvent() async {
    final user = await UserProfile.load();

    // Home-Meetup laden, um direkt auf dessen Portal-Seite zu landen
    String url = 'https://portal.einundzwanzig.space/login';
    if (user.homeMeetupId.isNotEmpty) {
      try {
        List<Meetup> meetups = await MeetupService.fetchMeetups();
        if (meetups.isEmpty) meetups = allMeetups;
        final hm = meetups.where((m) => m.city == user.homeMeetupId).firstOrNull;
        if (hm != null && hm.portalLink.isNotEmpty) {
          url = hm.portalLink;
        }
      } catch (_) {/* Fallback bleibt Login-Seite */}
    }

    if (!mounted) return;

    // Transparenter Hinweis-Dialog vor dem Öffnen
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.event_available_rounded, color: cOrange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(AppLocalizations.of(ctx).apCreateEventTitle,
                style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(ctx).apCreateEventBody,
                style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cTileBorder, width: 0.5),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: cTextTertiary, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(AppLocalizations.of(ctx).apPortalHint,
                      style: const TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4)),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).apCancel, style: const TextStyle(color: cTextSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(AppLocalizations.of(ctx).apOpenPortal),
          ),
        ],
      ),
    );

    if (go == true) {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context).errorOpenLink}: $url'),
              backgroundColor: cRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSessionActive = _sessionExpiry != null;

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: Text(AppLocalizations.of(context).apOrganizer)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kompakter Status-Header
            Row(children: [
              const Icon(Icons.verified_rounded, color: cOrange, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _promotionSource == 'trust_score' ? AppLocalizations.of(context).apViaTrustScore : AppLocalizations.of(context).apOrganizer,
                style: const TextStyle(color: cTextSecondary, fontSize: 12),
              )),
              if (_adminNpub.isNotEmpty)
                Text(NostrService.shortenNpub(_adminNpub, chars: 8),
                  style: const TextStyle(color: cTextTertiary, fontSize: 11, fontFamily: 'monospace')),
            ]),
            const SizedBox(height: 20),
            // legacy Wrap compat — keep chip builder for session area below
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (false) _buildStatusChip(
                icon: _promotionSource == 'trust_score' ? Icons.trending_up : Icons.star,
                label: _promotionSource == 'trust_score'
                    ? AppLocalizations.of(context).apViaTrustScore
                    : _promotionSource == 'seed_admin'
                        ? AppLocalizations.of(context).apSeedAdmin
                        : AppLocalizations.of(context).apOrganizer,
                color: _promotionSource == 'trust_score' ? Colors.green : cOrange,
              ),
            ]),

            const SizedBox(height: 32),

            // --- UNIFIED SESSION CONTROLLER ---
            Text(AppLocalizations.of(context).apMeetupSession, style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            if (isSessionActive) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cCard,
                  borderRadius: BorderRadius.circular(kTileRadius),
                  border: Border.all(color: cGreen.withValues(alpha: 0.3), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: cGreen, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).apSessionRunning, style: const TextStyle(color: cGreen, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      const Spacer(),
                      Text(_timeLeft, style: TextStyle(color: cText, fontSize: 12, fontFamily: fontMono, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 4),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RollingQRScreen()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(AppLocalizations.of(context).apOpenActiveMeetup, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        bool? confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: cCard,
                            title: Text(AppLocalizations.of(context).apSessionEndQ, style: const TextStyle(color: Colors.white)),
                            content: Text(AppLocalizations.of(context).apSessionEndBody, style: const TextStyle(color: Colors.grey)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).apCancel, style: const TextStyle(color: Colors.grey))),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context).apEnd, style: const TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) _endSessionEarly();
                      },
                      child: Text(AppLocalizations.of(context).apEndMeetupEarly, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // INACTIVE SESSION UI
              _buildAdminTile(
                context: context,
                icon: Icons.power_settings_new,
                color: cOrange,
                title: AppLocalizations.of(context).apStartMeetup,
                subtitle: AppLocalizations.of(context).apGeneratesProof,
                onTap: () async {
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: cCard,
                      title: Text(AppLocalizations.of(context).apNewMeetupQ, style: const TextStyle(color: Colors.white)),
                      content: Text(AppLocalizations.of(context).apNewMeetupBody, style: const TextStyle(color: Colors.grey)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).apCancel, style: const TextStyle(color: Colors.grey))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(AppLocalizations.of(context).apStart),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) _startNewSession();
                },
              ),
            ],

            // Web of Trust Dashboard (für ALLE Admins)
            const SizedBox(height: 32),
            const Divider(color: Colors.white10),
            const SizedBox(height: 24),

            Text(
              AppLocalizations.of(context).apNetwork,
              style: TextStyle(color: cOrange, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),

            _buildAdminTile(
              context: context,
              icon: Icons.hub,
              color: cPurple,
              title: AppLocalizations.of(context).apWebOfTrust,
              subtitle: AppLocalizations.of(context).apManageVouches,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WotDashboardScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            _buildAdminTile(
              context: context,
              icon: Icons.event_available_rounded,
              color: cOrange,
              title: AppLocalizations.of(context).apCreateEvent,
              subtitle: AppLocalizations.of(context).apCreateEventSub,
              onTap: _openPortalForEvent,
            ),

            // Admin-Verwaltung (nur Super-Admin — Legacy)
            if (_isSuperAdmin) ...[
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 32),

            // Info Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cOrange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.info_outline, color: cOrange, size: 20),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).apHowItWorks, style: const TextStyle(color: cOrange, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).apHowStep1 +
                    AppLocalizations.of(context).apHowStep2 +
                    AppLocalizations.of(context).apHowStep3 +
                    AppLocalizations.of(context).apHowStep4,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6, color: cTextSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAdminTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: cTextTertiary, fontSize: 11, height: 1.3)),
            ],
          )),
          const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 16),
        ]),
      ),
    );
  }
}



