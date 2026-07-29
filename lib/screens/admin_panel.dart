import 'dart:async';
import '../services/app_logger.dart';
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
import '../services/coattendance_service.dart';
import '../services/meetup_location_service.dart';
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
    // ---- GPS-PFLICHT: Standort ermitteln + Meetup zuordnen ----
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: cOrange)),
    );
    final locResult = await MeetupLocationService.resolveLocation();
    if (mounted) Navigator.pop(context); // Lade-Dialog schließen

    if (locResult.status != GpsStatus.ok) {
      // DIAGNOSE (Feldtest): Beim Meetup konnte ein Organisator das Tag
      // nicht beschreiben, obwohl der Standort nach seiner Aussage aktiv war.
      // Der konkrete Status unterscheidet die beiden moeglichen Ursachen:
      //   serviceDisabled = Standortdienst des Systems ist AUS
      //   error           = Dienst an, aber kein Fix (drinnen, Timeout)
      //   denied          = App-Berechtigung fehlt
      AppLogger.warn('Organisator',
          'Standort fuer Meetup-Erstellung NICHT ermittelbar: ${locResult.status.name}');
      // WEICHE PRUEFUNG: Frueher war hier Schluss. Das hat Organisatoren auf
      // Geraeten ohne Netzwerkortung (z.B. GrapheneOS ohne Play Services)
      // komplett blockiert — obwohl der Standort hier ohnehin nur den
      // Meetup-Vorschlag liefert und wer ausserhalb des Radius ist, den
      // Namen sowieso frei eintippen darf. Der Organisator entscheidet jetzt
      // selbst, wird aber ueber die Folge aufgeklaert.
      if (!mounted) return;
      final weiter = await _askContinueWithoutGps(locResult.status);
      if (weiter != true) return;
    } else {
      AppLogger.diag('Organisator',
          'Standort erfasst — ${locResult.candidates.length} Meetup(s) im Umkreis bekannt, '
          '${locResult.withinCreationRadius.length} davon im Erstellungs-Radius.');
    }
    // Meetups im 10km-Radius um den erfassten Standort.
    // Leer = entweder keines im Radius ODER Portal nicht erreichbar.
    // Beide Fälle führen unten zur manuellen Namenseingabe.
    final nearby = locResult.withinCreationRadius;

    String meetupId;
    String meetupCountry;
    // Der ECHTE erfasste GPS-Standort des Organisators wird der Meetup-Ort
    // (nicht die groben Portal-Koordinaten der Stadt).
    final orgLat = locResult.lat;
    final orgLng = locResult.lng;

    if (nearby.isEmpty) {
      // Kein bekanntes Portal-Meetup in der Nähe -> Organisator gibt den
      // Namen manuell ein. Standort (orgLat/orgLng) wird trotzdem erfasst,
      // damit der 5km-Teilnehmer-Check weiter funktioniert.
      final manualName = await _askMeetupName();
      if (manualName == null || manualName.trim().isEmpty) return; // abgebrochen
      meetupId = manualName.trim();
      meetupCountry = '';
    } else {
      // Eines im Radius -> automatisch. Mehrere -> Organisator wählt.
      MeetupCandidate chosen;
      if (nearby.length == 1) {
        chosen = nearby.first;
      } else {
        final picked = await _pickMeetup(nearby);
        if (picked == null) return; // abgebrochen
        chosen = picked;
      }
      meetupId = chosen.meetup.city;
      meetupCountry = chosen.meetup.country;
    }

    final compactId = meetupId.toLowerCase().replaceAll(' ', '-');

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: cOrange)),
    );

    try {
      // Eventuell noch laufende (alte) Session zuerst sauber beenden, damit
      // garantiert eine FRISCHE Session mit dem aktuellen Namen/Standort
      // erstellt wird (sonst könnte eine alte Session denselben Slot belegen).
      await RollingQRService.endSession();

      final session = await RollingQRService.getOrCreateSession(
        meetupId: compactId,
        meetupName: meetupId,
        meetupCountry: meetupCountry,
        blockHeight: 0,
        lat: orgLat,
        lng: orgLng,
      );

      // Organisator nimmt automatisch am Co-Attendance-Netzwerk teil
      // (kein Reputations-Badge, aber Marker-Badge + Netzwerk-Teilnahme).
      // Blockhöhe aus der Session übernehmen (sie hat sie schon von Mempool geholt).
      // GPS-Koordinaten des Erstellungsorts werden mitgegeben.
      await CoAttendanceService.recordOrganizerAttendance(
        meetupName: meetupId,
        date: DateTime.now(),
        blockHeight: session?.blockHeight ?? 0,
        lat: orgLat,
        lng: orgLng,
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

  /// Fragt, ob ohne Standort weitergemacht werden soll. Klaert ueber die
  /// Folge auf: Ohne Organisator-Standort koennen Teilnehmer nicht
  /// standortgeprueft werden — ihre Badges gelten als ungeprueft.
  Future<bool?> _askContinueWithoutGps(GpsStatus status) {
    final t = AppLocalizations.of(context);
    final msg = status == GpsStatus.denied
        ? t.gpsDenied
        : status == GpsStatus.serviceDisabled
            ? t.gpsDisabled
            : t.gpsError;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.location_off_rounded, color: cOrange, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(t.orgGpsSoftTitle,
              style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Text('$msg\n\n${t.orgGpsSoftBody}',
            style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4)),
        actions: [
          if (status == GpsStatus.serviceDisabled)
            TextButton(
              onPressed: () => MeetupLocationService.openLocationSettings(),
              child: Text(t.gpsOpenLocationSettings, style: const TextStyle(color: cTextSecondary)),
            ),
          if (status == GpsStatus.denied)
            TextButton(
              onPressed: () => MeetupLocationService.openAppSettings(),
              child: Text(t.gpsOpenAppSettings, style: const TextStyle(color: cTextSecondary)),
            ),
          TextButton(
            onPressed: () { Navigator.pop(ctx, false); _startNewSession(); },
            child: Text(t.gpsRetry, style: const TextStyle(color: cOrange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.orgGpsSoftContinue,
                style: const TextStyle(color: cOrange, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showGpsError(GpsStatus status) {
    final t = AppLocalizations.of(context);
    String msg;
    switch (status) {
      case GpsStatus.denied: msg = t.gpsDenied; break;
      case GpsStatus.serviceDisabled: msg = t.gpsDisabled; break;
      default: msg = t.gpsError;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.location_off_rounded, color: cRed, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(t.gpsRequired, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Text('${t.gpsRequiredOrg}\n\n$msg', style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4)),
        actions: [
          // Direkter Weg in die Einstellungen — beim Feldtest stand das
          // Meetup genau vor dieser Wand. Der Dialog bleibt bewusst OFFEN,
          // damit man nach dem Umschalten gleich "Erneut versuchen" tippen kann.
          if (status == GpsStatus.serviceDisabled)
            TextButton(
              onPressed: () => MeetupLocationService.openLocationSettings(),
              child: Text(t.gpsOpenLocationSettings, style: const TextStyle(color: cTextSecondary)),
            ),
          if (status == GpsStatus.denied)
            TextButton(
              onPressed: () => MeetupLocationService.openAppSettings(),
              child: Text(t.gpsOpenAppSettings, style: const TextStyle(color: cTextSecondary)),
            ),
          TextButton(onPressed: () { Navigator.pop(ctx); _startNewSession(); }, child: Text(t.gpsRetry, style: const TextStyle(color: cOrange))),
        ],
      ),
    );
  }

  /// Fragt den Meetup-Namen ab, wenn kein Portal-Meetup in der Nähe ist.
  /// Der GPS-Standort wurde bereits erfasst und wird als Veranstaltungsort
  /// genutzt — hier fehlt nur der Name.
  Future<String?> _askMeetupName() {
    final t = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    String? errorText;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.add_location_alt_rounded, color: cOrange, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(t.gpsNoMeetupTitle,
                style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700))),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.gpsNoMeetupBody, style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: cText, fontSize: 14),
              decoration: InputDecoration(
                labelText: t.gpsMeetupNameLabel,
                labelStyle: const TextStyle(color: cTextSecondary, fontSize: 13),
                hintText: t.gpsMeetupNameHint,
                hintStyle: const TextStyle(color: cTextTertiary, fontSize: 12),
                errorText: errorText,
                filled: true, fillColor: cSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cOrange, width: 1)),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel, style: const TextStyle(color: cTextSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                if (ctrl.text.trim().isEmpty) {
                  setLocal(() => errorText = t.gpsNameRequired);
                  return;
                }
                Navigator.pop(ctx, ctrl.text.trim());
              },
              child: Text(t.gpsStartAnyway, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  /// Lässt den Organisator bei mehreren nahen Meetups das richtige wählen.
  Future<MeetupCandidate?> _pickMeetup(List<MeetupCandidate> candidates) {
    final t = AppLocalizations.of(context);
    return showModalBottomSheet<MeetupCandidate>(
      context: context,
      backgroundColor: cDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(t.gpsPickMeetup, style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(t.gpsPickMeetupSub, style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          ...candidates.take(5).map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => Navigator.pop(ctx, c),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cCard,
                  borderRadius: BorderRadius.circular(kTileRadius),
                  border: Border.all(color: cTileBorder, width: 0.5),
                ),
                child: Row(children: [
                  const Icon(Icons.location_on_rounded, color: cOrange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.meetup.city, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(t.gpsDistanceKm(c.distanceKm.toStringAsFixed(1)), style: const TextStyle(color: cTextTertiary, fontSize: 12)),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 20),
                ]),
              ),
            ),
          )),
        ]),
      ),
    );
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



