// ============================================
// ROLLING QR SCREEN v3 — UNIFIED SESSION
// ============================================
//
// Dieser Screen generiert KEINE eigene Session mehr.
// Er setzt voraus, dass über den AdminPanelScreen
// bereits eine Session gestartet wurde.
//
// Der QR enthält:
//   - Badge-Daten (kompakt, EINMALIG Schnorr-signiert)
//   - Rolling Nonce (10s gültig, Screenshot = wertlos)
//   - Session-Ablauf (4h)
//
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/rolling_qr_service.dart';
import '../services/nostr_service.dart';
import '../services/app_logger.dart';

class RollingQRScreen extends StatefulWidget {
  const RollingQRScreen({super.key});

  @override
  State<RollingQRScreen> createState() => _RollingQRScreenState();
}

class _RollingQRScreenState extends State<RollingQRScreen> with WidgetsBindingObserver {
  String _qrData = '';
  String _meetupInfo = '';
  int _blockHeight = 0;
  int _secondsLeft = 10;
  String _adminNpub = '';

  bool _isLoading = true;
  bool _isActive = false;
  MeetupSession? _session;

  Timer? _refreshTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // App-Lifecycle beobachten
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// App kommt in den Vordergrund → Session fortsetzen
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _session != null && !_session!.isExpired) {
      _resumeRolling();
    }
  }

  Future<void> _initialize() async {
    final npub = await NostrService.getNpub();
    setState(() => _adminNpub = npub ?? '');

    // Session hat IMMER Vorrang: ihr tatsächlicher Name wird angezeigt.
    // (Kein Home-Meetup-Fallback mehr — der angezeigte Name kommt
    // ausschließlich aus der laufenden Session, siehe _checkExistingSession.)
    await _checkExistingSession();
  }

  /// Prüft ob eine laufende Session existiert
  Future<void> _checkExistingSession() async {
    final session = await RollingQRService.loadSession();
    
    if (session != null && !session.isExpired) {
      setState(() {
        _session = session;
        _blockHeight = session.blockHeight;
        _isActive = true;
        _isLoading = false;
        // Angezeigter Name = der TATSÄCHLICHE Session-Name (z.B. manuell
        // eingegeben "im Garten"), NICHT das Home-Meetup aus dem Profil.
        _meetupInfo = session.meetupCountry.isNotEmpty
            ? "📍 ${session.meetupName}, ${session.meetupCountry}"
            : "📍 ${session.meetupName}";
      });
      _startTimers();
      await _refreshQR();
    } else {
      // Keine aktive Session gefunden!
      setState(() {
        _isActive = false;
        _isLoading = false;
      });
    }
  }

  /// Rolling fortsetzen (nach App-Resume)
  void _resumeRolling() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _startTimers();
    _refreshQR();
  }

  void _startTimers() {
    // QR alle 10 Sekunden neu
    _refreshTimer = Timer.periodic(
      const Duration(seconds: RollingQRService.intervalSeconds),
      (_) => _refreshQR(),
    );

    // Countdown jede Sekunde
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        // Session abgelaufen?
        if (_session != null && _session!.isExpired) {
          _stopSessionUIOnly();
          return;
        }

        setState(() {
          _secondsLeft = RollingQRService.secondsUntilNextChange();
        });
      },
    );
  }

  Future<void> _refreshQR() async {
    if (_session == null || _session!.isExpired) return;

    try {
      final qrString = await RollingQRService.generateQRString(_session!);
      if (mounted) {
        setState(() {
          _qrData = qrString;
          _secondsLeft = RollingQRService.secondsUntilNextChange();
        });
      }
    } catch (e) {
      // Reine Log-Zeile: der Text geht ins Diagnose-Log, nicht auf den
      // Bildschirm. Uebersetzung ueber den Context waere hier nach dem
      // await ohnehin unsicher und brachte nichts.
      AppLogger.debug('RollingQR', 'QR-Erzeugung fehlgeschlagen: $e');
    }
  }

  // Beendet nur die QR-Anzeige, falls die 6h abgelaufen sind
  Future<void> _stopSessionUIOnly() async {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _isActive = false;
        _session = null;
        _qrData = '';
      });
    }
  }

  // Beendet die Session manuell (Löscht sie auch aus SharedPreferences)
  Future<void> _stopSession() async {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    await RollingQRService.endSession();
    if (mounted) {
      // Gehe zurück ins Admin Panel, da die Session beendet wurde
      Navigator.pop(context);
    }
  }

  void _confirmStopSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: Text(AppLocalizations.of(context).rqEndSessionQ, style: const TextStyle(color: Colors.white)),
        content: Text(
          AppLocalizations.of(context).rqRemainingTime(_session?.remainingTimeString ?? '-') +
          AppLocalizations.of(context).rqEndSessionBody,
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).apCancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _stopSession();
            },
            child: Text(AppLocalizations.of(context).rqEnd, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =============================================
  // UI
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).rqTitle),
        backgroundColor: cOrange,
        actions: [
          if (_isActive)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.white70),
              onPressed: _confirmStopSession,
              tooltip: AppLocalizations.of(context).rqEndSession,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : _isActive
              ? _buildActiveQR()
              : _buildNoSessionScreen(),
    );
  }

  Widget _buildNoSessionScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent, width: 3),
              ),
              child: const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
            ),
            const SizedBox(height: 30),
            Text(AppLocalizations.of(context).rqNoActiveSession,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).rqNoSessionBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5)
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: Text(AppLocalizations.of(context).rqBackToAdmin, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveQR() {
    final progress = _secondsLeft / RollingQRService.intervalSeconds;
    final remaining = _session?.remainingTimeString ?? '-';

    return Column(
      children: [
        // Session-Info Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          color: cOrange.withValues(alpha: 0.15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_meetupInfo, style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(AppLocalizations.of(context).rqSessionRemaining(remaining), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              // Session-Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(AppLocalizations.of(context).rqActive, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // QR Code (dominanter Bereich)
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // QR mit weißem Hintergrund
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: cOrange.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: _qrData.isNotEmpty
                      ? QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 260,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        )
                      : const SizedBox(
                          width: 260, height: 260,
                          child: Center(child: CircularProgressIndicator(color: cOrange)),
                        ),
                ),
                const SizedBox(height: 24),

                // Rolling Countdown
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60, height: 60,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: Colors.grey.withValues(alpha: 0.3),
                        color: _secondsLeft <= 3 ? Colors.red : cOrange,
                      ),
                    ),
                    Text('$_secondsLeft',
                      style: TextStyle(
                        color: _secondsLeft <= 3 ? Colors.red : Colors.white,
                        fontSize: 22, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _secondsLeft <= 3 ? AppLocalizations.of(context).rqCodeRenewing : AppLocalizations.of(context).rqNextCodeIn,
                  style: TextStyle(color: _secondsLeft <= 3 ? Colors.red : Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // Footer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: cCard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("⛓️ Block $_blockHeight",
                style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 12)),
              if (_adminNpub.isNotEmpty)
                Text(NostrService.shortenNpub(_adminNpub),
                  style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}


