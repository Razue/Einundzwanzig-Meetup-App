// ============================================
// HUMANITY PROOF SCREEN — Lightning-Verifizierung
// ============================================
// Dezentral, keine hardcodierten Adressen.
//
// Die App prüft einfach: "Hat dieser npub jemals
// einen Nostr-Zap gesendet?" Wenn ja → verifiziert.
//
// Für Nutzer die noch nie gezappt haben:
//   - Erklärung was Zaps sind
//   - AppLocalizations.of(context).humZapReturn
//   - AppLocalizations.of(context).humCheckAgainShort Button
// ============================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/humanity_proof_service.dart';
import '../services/reputation_publisher.dart';

class HumanityProofScreen extends StatefulWidget {
  const HumanityProofScreen({super.key});

  @override
  State<HumanityProofScreen> createState() => _HumanityProofScreenState();
}

class _HumanityProofScreenState extends State<HumanityProofScreen> {
  HumanityStatus? _status;
  bool _isLoading = true;
  bool _isChecking = false;
  String? _resultMessage;
  bool? _resultSuccess;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _loadStatus() async {
    final status = await HumanityProofService.getStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _isLoading = false;
      });
    }
  }

  // =============================================
  // PRÜFUNG STARTEN
  // =============================================

  void _checkForZaps() async {
    setState(() {
      _isChecking = true;
      _resultMessage = null;
      _resultSuccess = null;
    });

    final result = await HumanityProofService.checkForZaps();

    if (mounted) {
      setState(() {
        _isChecking = false;
        _resultMessage = result.message;
        _resultSuccess = result.found;
      });

      if (result.found) {
        _loadStatus(); // Status neu laden

        // Reputation-Event aktualisieren (Proof integrieren)
        _publishUpdate();
      }
    }
  }

  void _publishUpdate() async {
    try {
      // Sanftes Update im Hintergrund
      ReputationPublisher.publishInBackground([]);
    } catch (_) {}
  }

  // =============================================
  // UI
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: Text(AppLocalizations.of(context).humTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _buildExplanation(),
                  const SizedBox(height: 24),
                  _buildActionSection(),
                ],
              ),
            ),
    );
  }

  // =============================================
  // STATUS CARD
  // =============================================

  Widget _buildStatusCard() {
    final verified = _status?.verified ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: verified ? Colors.green.withValues(alpha: 0.4) : Colors.amber.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: (verified ? Colors.green : Colors.amber).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              verified ? Icons.verified_user : Icons.person_search,
              color: verified ? Colors.green : Colors.amber,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            verified ? AppLocalizations.of(context).humVerified : AppLocalizations.of(context).humNotVerified,
            style: TextStyle(
              color: verified ? Colors.green : Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            verified
                ? AppLocalizations.of(context).humPaidOn(_status!.firstZapDateStr) +
                  AppLocalizations.of(context).humProofInEvent1 +
                  AppLocalizations.of(context).humReputationSaved
                : AppLocalizations.of(context).humIntro1 +
                  AppLocalizations.of(context).humIntro2 +
                  AppLocalizations.of(context).humIntro3,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5),
          ),

          if (verified) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Text(AppLocalizations.of(context).humLightningActive,
                    style: TextStyle(color: Colors.green.shade300, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =============================================
  // ERKLÄRUNG
  // =============================================

  Widget _buildExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).humHowTitle,
            style: TextStyle(color: Colors.grey.shade300, fontSize: 12,
              fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 12),

          _buildStep("1", AppLocalizations.of(context).humStep1,
            AppLocalizations.of(context).humStepInstruction),
          _buildStep("2", AppLocalizations.of(context).humStep2,
            AppLocalizations.of(context).humCryptoProof),
          _buildStep("3", AppLocalizations.of(context).humStep3,
            AppLocalizations.of(context).humCheckInstruction),
          _buildStep("4", AppLocalizations.of(context).humVerifiedSub,
            AppLocalizations.of(context).humProofPrivacy),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield, color: Colors.amber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).humExplain1 +
                    AppLocalizations.of(context).humExplain2 +
                    AppLocalizations.of(context).humExplain3,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: cOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ACTION SECTION
  // =============================================

  Widget _buildActionSection() {
    final verified = _status?.verified ?? false;

    return Column(
      children: [
        // Prüfen-Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isChecking ? null : _checkForZaps,
            icon: _isChecking
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Icon(verified ? Icons.refresh : Icons.bolt, size: 22),
            label: Text(
              _isChecking
                  ? AppLocalizations.of(context).humSearchingRelays
                  : verified
                      ? AppLocalizations.of(context).humCheckAgain
                      : AppLocalizations.of(context).humCheckNow,
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: verified ? Colors.grey.shade800 : Colors.amber,
              foregroundColor: verified ? Colors.white : Colors.black,
              disabledBackgroundColor: Colors.amber.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),

        // Letzte Prüfung
        if (_status != null && _status!.lastCheckedAt > 0) ...[
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).humLastCheck(_status!.lastCheckedStr),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        ],

        // Ergebnis
        if (_resultMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_resultSuccess == true ? Colors.green : Colors.amber).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (_resultSuccess == true ? Colors.green : Colors.amber).withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _resultSuccess == true ? Icons.check_circle : Icons.info_outline,
                  color: _resultSuccess == true ? Colors.green : Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_resultMessage!,
                    style: TextStyle(
                      color: _resultSuccess == true ? Colors.green.shade300 : Colors.amber.shade300,
                      fontSize: 12, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}


