// ============================================
// WEB OF TRUST DASHBOARD
// ============================================
//
//   Tab 1: NETZWERK  — Gesundheitsstatus, alle Admins, Konsens-Meter
//   Tab 2: BÜRGEN    — Eigene Vouching-Liste verwalten
//   Tab 3: MELDUNGEN — Distrust-Reports einsehen + erstellen
//
// ÄNDERUNG: Wiederherstellung der eigenen Bürgschaften von den Relays
//   - Auto-Sync beim Öffnen (_loadAll) und beim manuellen Refresh
//   - Buttons AppLocalizations.of(context).wotRestore + AppLocalizations.of(context).wotRevokeAll im BÜRGEN-Tab
// ============================================

import 'package:flutter/material.dart';
import '../widgets/npub_chip.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/vouching_service.dart';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';
import 'trust_path_screen.dart';
import 'verify_person_screen.dart';
import 'dart:math';

class WotDashboardScreen extends StatefulWidget {
  const WotDashboardScreen({super.key});

  @override
  State<WotDashboardScreen> createState() => _WotDashboardScreenState();
}

class _WotDashboardScreenState extends State<WotDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  NetworkConsensus? _consensus;
  List<AdminEntry> _myVouches = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isPublishing = false;
  String? _myNpub;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    try {
      _myNpub = await NostrService.getNpub();

      // AUTO-SYNC: zuerst meine publizierte Bürgschafts-Liste von den
      // Relays zurücklesen (überschreibt lokal NICHT, wenn Relay leer ist).
      // So kommen nach Neuinstallation/Backup-Wechsel die Bürgschaften zurück.
      try {
        await AdminRegistry.recoverMyVouchesFromRelays();
      } catch (_) {/* still — lokaler Stand bleibt */}

      _myVouches = await AdminRegistry.getMyVouches();

      try {
        _consensus = await VouchingService.calculateConsensus();
      } catch (e) {
        _consensus = null;
      }
    } catch (e) {
      _statusMessage = AppLocalizations.of(context).wotErrorLoading(e.toString());
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      // Auch beim manuellen Refresh meine Liste von den Relays abgleichen
      try {
        await AdminRegistry.recoverMyVouchesFromRelays();
      } catch (_) {}
      _consensus = await VouchingService.calculateConsensus(forceRefresh: true);
      _myVouches = await AdminRegistry.getMyVouches();
      _statusMessage = '';
    } catch (e) {
      _statusMessage = AppLocalizations.of(context).wotSyncFailed(e.toString());
    }
    if (mounted) setState(() => _isRefreshing = false);
  }

  // =============================================
  // WIEDERHERSTELLEN / NOTAUSGANG
  // =============================================

  Future<void> _recoverMyVouches() async {
    setState(() => _isRefreshing = true);
    try {
      final count = await AdminRegistry.recoverMyVouchesFromRelays();
      _myVouches = await AdminRegistry.getMyVouches();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count < 0
                ? AppLocalizations.of(context).wotNoRelay
                : count == 0
                    ? AppLocalizations.of(context).wotNoVouchesFound
                    : AppLocalizations.of(context).wotVouchesRestored(count)),
            backgroundColor: count > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).wotRestoreFailed(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _revokeAllVouches() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Text(AppLocalizations.of(context).wotRevokeAllTitle,
            style: const TextStyle(color: cRed, fontWeight: FontWeight.w700, fontSize: 15)),
        content: Text(
          AppLocalizations.of(context).wotRevokeAllBody +
          AppLocalizations.of(context).wotVouchesSignedOnNostr +
          AppLocalizations.of(context).wotVisibleLocally +
          AppLocalizations.of(context).wotCantResolveOld,
          style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).dialogCancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cRed),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isPublishing = true);
              try {
                await AdminRegistry.revokeAllVouches();
                _myVouches = await AdminRegistry.getMyVouches();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context).wotAllRevoked),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).wotRevocationFailed(e.toString())),
                        backgroundColor: Colors.red),
                  );
                }
              }
              if (mounted) setState(() => _isPublishing = false);
            },
            child: Text(AppLocalizations.of(context).wotRevokeAll,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).wotTitle),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cCyan))
                : const Icon(Icons.sync_rounded, color: cTextSecondary),
            tooltip: AppLocalizations.of(context).wotSyncNetwork,
            onPressed: _isRefreshing ? null : _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: cOrange,
          labelColor: cOrange,
          unselectedLabelColor: cTextTertiary,
          dividerColor: cTileBorder,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
          tabs: [
            Tab(icon: const Icon(Icons.hub, size: 20), text: AppLocalizations.of(context).wotTabNetwork),
            Tab(icon: const Icon(Icons.shield, size: 20), text: AppLocalizations.of(context).wotVouch),
            Tab(icon: const Icon(Icons.report_outlined, size: 20), text: AppLocalizations.of(context).wotTabReports),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNetworkTab(),
                _buildVouchingTab(),
                _buildDistrustTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddVouchDialog,
              backgroundColor: cOrange,
              icon: const Icon(Icons.shield_rounded, color: Colors.black),
              label: const Text('RITTERSCHLAG',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            )
          : null,
    );
  }

  // =============================================
  // TAB 1: NETZWERK-ÜBERSICHT
  // =============================================

  Widget _buildNetworkTab() {
    final consensus = _consensus;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: cOrange,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNetworkHealthCard(consensus),
          const SizedBox(height: 16),
          if (consensus != null) ...[
            _buildThresholdsCard(consensus),
            const SizedBox(height: 16),
          ],
          _buildMyStatusCard(consensus),
          const SizedBox(height: 16),
          _buildTrustPathCard(),
          const SizedBox(height: 12),
          _buildNetworkAnalysisCard(),
          const SizedBox(height: 24),
          _buildSectionHeader(AppLocalizations.of(context).wotActiveOrganizers, Icons.verified_user),
          const SizedBox(height: 12),
          if (consensus == null)
            _buildEmptyState(
              icon: Icons.cloud_off,
              title: AppLocalizations.of(context).wotOffline,
              subtitle: AppLocalizations.of(context).wotNoDataLoaded,
            )
          else if (consensus.effectiveAdmins.isEmpty)
            _buildEmptyState(
              icon: Icons.group_off,
              title: AppLocalizations.of(context).wotNoActiveAdmins,
              subtitle: AppLocalizations.of(context).wotNoOrganizersEnough,
            )
          else
            ...consensus.effectiveAdmins.map((admin) =>
                _buildAdminCard(admin, consensus)),
          if (consensus != null && consensus.suspendedAdmins.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('SUSPENDIERT', Icons.block, color: cRed),
            const SizedBox(height: 12),
            ...consensus.suspendedAdmins.map((admin) =>
                _buildAdminCard(admin, consensus, suspended: true)),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTrustPathCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrustPathScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cCyan.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.route_rounded, color: cCyan, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).tpTitle,
                  style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(AppLocalizations.of(context).tpSubtitle,
                  style: const TextStyle(color: cTextTertiary, fontSize: 12, height: 1.3)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 22),
        ]),
      ),
    );
  }

  Widget _buildNetworkAnalysisCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VerifyPersonScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cOrange.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hub_rounded, color: cOrange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).cnTitle,
                  style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(AppLocalizations.of(context).cnSubtitle,
                  style: const TextStyle(color: cTextTertiary, fontSize: 12, height: 1.3)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 22),
        ]),
      ),
    );
  }

  Widget _buildNetworkHealthCard(NetworkConsensus? consensus) {
    final effectiveCount = consensus?.effectiveAdmins.length ?? 0;
    final totalVoters = consensus?.totalVoters ?? 0;
    final isSunset = consensus?.isSunset ?? false;    final suspendedCount = consensus?.suspendedAdmins.length ?? 0;

    double health = 0.0;
    if (consensus != null && effectiveCount > 0) {
      health = (effectiveCount / (effectiveCount + suspendedCount + 1)).clamp(0.0, 1.0);
      if (effectiveCount >= 5) health = (health + 0.2).clamp(0.0, 1.0);
      if (totalVoters >= 3) health = (health + 0.1).clamp(0.0, 1.0);
    }

    final healthColor = health > 0.7
        ? Colors.green
        : health > 0.4
            ? Colors.orange
            : cRed;
    final healthLabel = health > 0.7
        ? AppLocalizations.of(context).wotHealthGood
        : health > 0.4
            ? AppLocalizations.of(context).wotHealthBuilding
            : AppLocalizations.of(context).wotHealthCritical;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: healthColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(kTileRadius),
                ),
                child: Icon(Icons.hub, color: healthColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).wotNetworkHealth(healthLabel),
                        style: TextStyle(color: healthColor, fontWeight: FontWeight.w800,
                            fontSize: 14, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      isSunset ? AppLocalizations.of(context).wotDecentralized : AppLocalizations.of(context).wotBootstrapPhase,
                      style: TextStyle(color: cTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatBox(effectiveCount.toString(), AppLocalizations.of(context).wotActive, Colors.green),
              const SizedBox(width: 12),
              _buildStatBox(totalVoters.toString(), AppLocalizations.of(context).wotVotes, cCyan),
              const SizedBox(width: 12),
              _buildStatBox(suspendedCount.toString(), AppLocalizations.of(context).wotSuspended,
                  suspendedCount > 0 ? cRed : cTextTertiary),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: health,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(healthColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(kTileRadius),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800,
                fontSize: 22, fontFamily: 'monospace')),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10,
                fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdsCard(NetworkConsensus consensus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildThresholdItem(
              icon: Icons.how_to_vote,
              label: AppLocalizations.of(context).wotMinVouches,
              value: '${consensus.minVouches}',
              color: cCyan,
            ),
          ),
          Container(width: 1, height: 40, color: cBorder),
          Expanded(
            child: _buildThresholdItem(
              icon: Icons.report,
              label: AppLocalizations.of(context).wotDistrustThreshold,
              value: '${consensus.distrustThreshold}',
              color: Colors.orange,
            ),
          ),
          Container(width: 1, height: 40, color: cBorder),
          Expanded(
            child: _buildThresholdItem(
              icon: Icons.landscape,
              label: AppLocalizations.of(context).wotPhase,
              value: consensus.isSunset ? AppLocalizations.of(context).wotPhaseDecentralized : AppLocalizations.of(context).wotPhaseBootstrap,
              color: consensus.isSunset ? Colors.green : cPurple,
              small: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool small = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800,
            fontSize: small ? 11 : 16, fontFamily: small ? null : 'monospace')),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: cTextTertiary, fontSize: 9,
            fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMyStatusCard(NetworkConsensus? consensus) {
    if (_myNpub == null || _myNpub!.isEmpty) return const SizedBox.shrink();

    final myStatus = consensus?.allAdmins
        .where((a) => a.npub == _myNpub)
        .firstOrNull;

    final isAdmin = myStatus?.isEffectiveAdmin ?? false;
    final vouchCount = myStatus?.vouchCount ?? 0;
    final distrustCount = myStatus?.distrustCount ?? 0;
    final minV = consensus?.minVouches ?? 2;

    final statusColor = isAdmin ? Colors.green : Colors.orange;
    final statusIcon = isAdmin ? Icons.verified : Icons.pending;
    final statusLabel = isAdmin ? AppLocalizations.of(context).wotActiveOrganizer : AppLocalizations.of(context).wotNotEnoughVouchers;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).wotMyStatus, style: TextStyle(color: statusColor,
                  fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(statusLabel, style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMiniStat(Icons.how_to_vote, AppLocalizations.of(context).wotVouchProgress(vouchCount, minV),
                  vouchCount >= minV ? Colors.green : Colors.orange),
              const SizedBox(width: 16),
              if (distrustCount > 0)
                _buildMiniStat(Icons.warning_amber, AppLocalizations.of(context).wotReportsCount(distrustCount), cRed),
            ],
          ),
          if (!isAdmin && vouchCount < minV) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).wotNeedMoreVouches(minV - vouchCount) +
              AppLocalizations.of(context).wotFromOtherOrgs,
              style: TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAdminCard(VouchingStatus admin, NetworkConsensus consensus,
      {bool suspended = false}) {
    final isMe = admin.npub == _myNpub;
    final color = suspended ? cRed : (isMe ? cOrange : Colors.white);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(
          color: suspended ? cRed.withValues(alpha: 0.3) : (isMe ? cOrange.withValues(alpha: 0.3) : cBorder),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (suspended ? cRed : cPurple).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            suspended ? Icons.block : Icons.verified_user,
            color: suspended ? cRed : cPurple,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub),
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            if (isMe)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('DU', style: TextStyle(color: cOrange,
                    fontSize: 9, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (admin.meetup.isNotEmpty)
              Text(admin.meetup, style: TextStyle(color: cOrange.withValues(alpha: 0.8),
                  fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            _buildVouchBar(admin.vouchCount, consensus.minVouches, suspended),
          ],
        ),
        children: [
          _buildDetailRow(Icons.how_to_vote, AppLocalizations.of(context).wotVouchers,
              AppLocalizations.of(context).wotVouchesRequired(admin.vouchCount, consensus.minVouches)),
          if (admin.distrustCount > 0)
            _buildDetailRow(Icons.warning_amber, AppLocalizations.of(context).wotReportsLabel,
                AppLocalizations.of(context).wotSuspensionProgress(admin.distrustCount, consensus.distrustThreshold),
                color: cRed),
          _buildDetailRow(Icons.fingerprint, 'npub',
              NostrService.shortenNpub(admin.npub, chars: 12)),
          if (admin.vouchers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).wotVouchersLabel, style: const TextStyle(color: cTextTertiary, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: admin.vouchers.map((v) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v == _myNpub ? 'Du' : NostrService.shortenNpub(v, chars: 6),
                  style: TextStyle(
                    color: v == _myNpub ? cOrange : cPurple,
                    fontSize: 10, fontFamily: 'monospace',
                    fontWeight: v == _myNpub ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVouchBar(int count, int required, bool suspended) {
    final ratio = count / max(required, 1);
    final color = suspended ? cRed : (ratio >= 1.0 ? Colors.green : Colors.orange);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$count', style: TextStyle(color: color, fontSize: 10,
            fontWeight: FontWeight.w700, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color color = cTextSecondary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.6), size: 14),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: cTextTertiary, fontSize: 11)),
          Expanded(
            child: Text(value, style: TextStyle(color: color, fontSize: 11,
                fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  // =============================================
  // TAB 2: BÜRGEN
  // =============================================

  Widget _buildVouchingTab() {
    final myStatus = _consensus?.allAdmins
        .where((a) => a.npub == _myNpub)
        .firstOrNull;
    final myVouchers = myStatus?.vouchers ?? [];

    final suspendedNpubs = _myVouches.where((v) {
      final status = _consensus?.allAdmins
          .where((a) => a.npub == v.npub).firstOrNull;
      return status?.isSuspended ?? false;
    }).toList();

    final warnedNpubs = _myVouches.where((v) {
      final status = _consensus?.allAdmins
          .where((a) => a.npub == v.npub).firstOrNull;
      return (status?.distrustCount ?? 0) > 0 && !(status?.isSuspended ?? false);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          icon: Icons.shield,
          color: cPurple,
          title: AppLocalizations.of(context).wotMyVouches,
          body: AppLocalizations.of(context).wotWhoYouVouchExplain +
              AppLocalizations.of(context).wotEachVouchPersonal +
              AppLocalizations.of(context).wotAfterPublishAll,
        ),
        const SizedBox(height: 16),

        if (suspendedNpubs.isNotEmpty)
          _buildLiabilityWarning(
            icon: Icons.error,
            color: cRed,
            title: AppLocalizations.of(context).wotLiability(suspendedNpubs.length),
            body: AppLocalizations.of(context).wotLiabilityBody(suspendedNpubs.map((v) =>
                v.name.isNotEmpty ? v.name : NostrService.shortenNpub(v.npub, chars: 6)
            ).join(", ")),
          ),
        if (warnedNpubs.isNotEmpty)
          _buildLiabilityWarning(
            icon: Icons.warning_amber,
            color: Colors.orange,
            title: AppLocalizations.of(context).wotWarningCount(warnedNpubs.length),
            body: AppLocalizations.of(context).wotWarningBody(warnedNpubs.map((v) =>
                v.name.isNotEmpty ? v.name : NostrService.shortenNpub(v.npub, chars: 6)
            ).join(", ")) +
                AppLocalizations.of(context).wotNotSuspendedWatch,
          ),

        _buildPublishButton(),
        const SizedBox(height: 12),

        // WIEDERHERSTELLEN + NOTAUSGANG
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isRefreshing ? null : _recoverMyVouches,
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: const Text('WIEDERHERSTELLEN', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cCyan,
                  side: const BorderSide(color: cCyan),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isPublishing ? null : _revokeAllVouches,
                icon: const Icon(Icons.block, size: 18),
                label: Text(AppLocalizations.of(context).wotRevokeAll, style: const TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cRed,
                  side: const BorderSide(color: cRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context).wotRestoreExplain +
          AppLocalizations.of(context).wotRestoreListBack,
          style: TextStyle(color: cTextTertiary, fontSize: 10, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        _buildSectionHeader(AppLocalizations.of(context).wotWhoYouVouchFor, Icons.how_to_vote),
        const SizedBox(height: 12),

        if (_myVouches.isEmpty)
          _buildEmptyState(
            icon: Icons.group_add,
            title: AppLocalizations.of(context).wotNobodyYet,
            subtitle: AppLocalizations.of(context).wotTapPlusFirst,
          )
        else
          ..._myVouches.map(_buildVouchEntry),

        const SizedBox(height: 24),

        _buildSectionHeader(AppLocalizations.of(context).wotWhoVouchesForYou, Icons.verified_user, color: cCyan),
        const SizedBox(height: 12),

        if (myVouchers.isEmpty)
          _buildEmptyState(
            icon: Icons.person_search,
            title: AppLocalizations.of(context).wotNoVouchersYet,
            subtitle: AppLocalizations.of(context).wotAskOthersVouch +
                AppLocalizations.of(context).wotYourNpub(_myNpub != null ? NostrService.shortenNpub(_myNpub!, chars: 10) : "?"),
            color: cCyan,
          )
        else
          ...myVouchers.map((voucher) => _buildVoucherEntry(voucher)),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildLiabilityWarning({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700,
                    fontSize: 11, letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: cTextSecondary, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherEntry(String voucherNpub) {
    final voucherStatus = _consensus?.allAdmins
        .where((a) => a.npub == voucherNpub).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.verified, color: cTextSecondary, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucherStatus?.name.isNotEmpty == true
                      ? voucherStatus!.name
                      : NostrService.shortenNpub(voucherNpub, chars: 10),
                  style: TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                if (voucherStatus?.meetup.isNotEmpty == true)
                  Text(voucherStatus!.meetup, style: TextStyle(color: cOrange,
                      fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isPublishing ? null : _publishToRelays,
        icon: _isPublishing
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.satellite_alt, color: Colors.white),
        label: Text(
          _isPublishing
              ? AppLocalizations.of(context).wotSigningPublishing
              : _myVouches.isEmpty
                  ? AppLocalizations.of(context).wotPublishRevocation
                  : AppLocalizations.of(context).wotPublishNostr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
              fontSize: 13, letterSpacing: 0.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _myVouches.isEmpty ? cRed.withValues(alpha: 0.8) : cOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildVouchEntry(AdminEntry admin) {
    final status = _consensus?.allAdmins
        .where((a) => a.npub == admin.npub).firstOrNull;
    final isSuspended = status?.isSuspended ?? false;
    final hasWarnings = (status?.distrustCount ?? 0) > 0;
    final borderColor = isSuspended ? cRed : (hasWarnings ? Colors.orange : cBorder);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: borderColor.withValues(alpha: isSuspended || hasWarnings ? 0.5 : 1.0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isSuspended ? cRed : cPurple).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(kTileRadius),
          ),
          child: Icon(
            isSuspended ? Icons.block : (hasWarnings ? Icons.warning_amber : Icons.verified_user),
            color: isSuspended ? cRed : (hasWarnings ? Colors.orange : cPurple),
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub),
                style: TextStyle(
                  color: isSuspended ? cRed : Colors.white,
                  fontWeight: FontWeight.w600, fontSize: 14,
                  decoration: isSuspended ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (isSuspended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('SUSPENDIERT', style: TextStyle(color: cRed,
                    fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (admin.meetup.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(admin.meetup, style: TextStyle(color: cOrange, fontSize: 11,
                    fontWeight: FontWeight.w600)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: NpubChip(admin.npub, style: TextStyle(color: cTextTertiary, fontSize: 10,
                      fontFamily: 'monospace')),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: cRed, size: 22),
          tooltip: AppLocalizations.of(context).wotWithdrawVouch,
          onPressed: () => _revokeVouch(admin),
        ),
      ),
    );
  }

  // =============================================
  // TAB 3: MELDUNGEN
  // =============================================

  Widget _buildDistrustTab() {
    final distrusts = _consensus?.allAdmins
        .where((a) => a.distrustCount > 0)
        .toList() ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          icon: Icons.shield_outlined,
          color: Colors.orange,
          title: AppLocalizations.of(context).wotWeightedReporting,
          body: AppLocalizations.of(context).wotSingleReportNoWeight +
              AppLocalizations.of(context).wotOnlyMultipleIndep +
              AppLocalizations.of(context).wotWarnSuspend +
              AppLocalizations.of(context).wotNobodyAlonePower,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _showReportDialog,
            icon: const Icon(Icons.report_outlined, size: 20),
            label: Text(AppLocalizations.of(context).wotReportNpub, style: const TextStyle(fontWeight: FontWeight.w700,
                letterSpacing: 0.3)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(AppLocalizations.of(context).wotActiveWarnings, Icons.warning_amber,
            color: distrusts.isNotEmpty ? Colors.orange : cTextTertiary),
        const SizedBox(height: 12),
        if (distrusts.isEmpty)
          _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: AppLocalizations.of(context).wotNoReports,
            subtitle: AppLocalizations.of(context).wotNoCleanNetwork,
            color: Colors.green,
          )
        else
          ...distrusts.map(_buildDistrustEntry),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDistrustEntry(VouchingStatus admin) {
    final threshold = _consensus?.distrustThreshold ?? 3;
    final ratio = admin.distrustCount / max(threshold, 1);
    final isNearSuspension = ratio >= 0.66;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(
          color: admin.isSuspended
              ? cRed.withValues(alpha: 0.4)
              : (isNearSuspension ? Colors.orange.withValues(alpha: 0.4) : cBorder),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (admin.isSuspended ? cRed : Colors.orange).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            admin.isSuspended ? Icons.block : Icons.warning_amber,
            color: admin.isSuspended ? cRed : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub),
          style: TextStyle(
            color: admin.isSuspended ? cRed : Colors.white,
            fontWeight: FontWeight.w600, fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(
                        admin.isSuspended ? cRed : Colors.orange),
                      minHeight: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${admin.distrustCount} / $threshold',
                  style: TextStyle(
                    color: admin.isSuspended ? cRed : Colors.orange,
                    fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              admin.isSuspended ? 'SUSPENDIERT' : AppLocalizations.of(context).wotActiveWarning,
              style: TextStyle(
                color: admin.isSuspended ? cRed : Colors.orange,
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        children: [
          for (final report in admin.distrusts) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cRed.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: cTextTertiary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        report.authorNpub == _myNpub
                            ? 'Du'
                            : NostrService.shortenNpub(report.authorNpub, chars: 8),
                        style: TextStyle(color: cTextSecondary, fontSize: 10,
                            fontFamily: 'monospace'),
                      ),
                      const Spacer(),
                      if (report.timestamp > 0)
                        Text(
                          _formatTimestamp(report.timestamp),
                          style: TextStyle(color: cTextTertiary, fontSize: 9),
                        ),
                    ],
                  ),
                  if (report.reason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(report.reason, style: TextStyle(color: cTextSecondary,
                        fontSize: 11, height: 1.3)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =============================================
  // DIALOGE
  // =============================================

  void _showReportDialog() {
    final npubController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Row(
          children: [
            Icon(Icons.report_outlined, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).wotReportNpub, style: const TextStyle(color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).wotReportNoWeightThreshold(_consensus?.distrustThreshold ?? 3),
                style: TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: npubController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace',
                          fontSize: 11),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).wotNpubRequired,
                        labelStyle: TextStyle(color: cTextTertiary),
                        hintText: 'npub1...',
                        filled: true, fillColor: cDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: cCyan, size: 22),
                      onPressed: () async {
                        final scanned = await _scanNpub();
                        if (scanned != null) npubController.text = scanned;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 200,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).wotReasonRequired,
                  labelStyle: TextStyle(color: cTextTertiary),
                  hintText: AppLocalizations.of(context).wotReasonExample,
                  hintStyle: TextStyle(color: cTextTertiary.withValues(alpha: 0.5)),
                  filled: true, fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).dialogCancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final npub = npubController.text.trim();
              final reason = reasonController.text.trim();
              if (npub.isEmpty || reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).wotNpubReasonRequired),
                      backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context);
              await _submitDistrust(npub, reason);
            },
            child: const Text('MELDEN', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _revokeVouch(AdminEntry admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Text(AppLocalizations.of(context).wotRevokeVouchTitle,
            style: const TextStyle(color: cRed, fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          '${admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub)} ' +
          AppLocalizations.of(context).wotRemovedFromList +
          AppLocalizations.of(context).wotPublishUpdated +
          AppLocalizations.of(context).wotSoNetworkKnows,
          style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).dialogCancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cRed),
            onPressed: () async {
              await AdminRegistry.removeVouch(admin.npub);
              if (mounted) {
                Navigator.pop(context);
                _myVouches = await AdminRegistry.getMyVouches();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).wotVouchWithdrawn),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('ENTZIEHEN', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddVouchDialog() {
    final npubController = TextEditingController();
    final meetupController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Row(
          children: [
            const Icon(Icons.shield, color: cPurple, size: 22),
            const SizedBox(width: 8),
            const Text('RITTERSCHLAG', style: TextStyle(color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).wotVouchExplain,
                style: TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: npubController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace',
                          fontSize: 11),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).wotNpubRequired,
                        labelStyle: TextStyle(color: cTextTertiary),
                        hintText: 'npub1...',
                        filled: true, fillColor: cDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: cCyan, size: 22),
                      onPressed: () async {
                        final scanned = await _scanNpub();
                        if (scanned != null) npubController.text = scanned;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meetupController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).wotMeetupExample,
                  labelStyle: TextStyle(color: cTextTertiary),
                  filled: true, fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).wotNameAlias,
                  labelStyle: TextStyle(color: cTextTertiary),
                  filled: true, fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).dialogCancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cPurple,
                foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await AdminRegistry.addVouch(AdminEntry(
                  npub: npubController.text.trim(),
                  meetup: meetupController.text.trim(),
                  name: nameController.text.trim(),
                ));
                if (mounted) {
                  Navigator.pop(context);
                  _myVouches = await AdminRegistry.getMyVouches();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context).wotVouchGiven),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text(AppLocalizations.of(context).wotVouchVerb, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // =============================================
  // AKTIONEN
  // =============================================

  Future<void> _publishToRelays() async {
    setState(() => _isPublishing = true);
    try {
      final result = await AdminRegistry.createAndPublishAdminListEvent();
      final data = jsonDecode(result);
      final sentTo = data['sent_to'] ?? 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).wotPublishedLive(sentTo)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).wotErrorShort(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isPublishing = false);
  }

  Future<void> _submitDistrust(String npub, String reason) async {
    try {
      final count = await VouchingService.publishDistrust(
        targetNpub: npub,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).wotReportPublished(count)),
            backgroundColor: Colors.orange,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).wotErrorShort(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _scanNpub() async {
    return await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _NpubScannerScreen()),
    );
  }

  // =============================================
  // WIEDERVERWENDBARE WIDGETS
  // =============================================

  Widget _buildSectionHeader(String title, IconData icon, {Color color = cTextTertiary}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700,
            fontSize: 11, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700,
                  fontSize: 12, letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: cTextSecondary, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = cTextTertiary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: color, fontSize: 14,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: cTextTertiary, fontSize: 12,
              height: 1.4), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  String _formatTimestamp(int unixSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${dt.day}.${dt.month}.${dt.year}';
    if (diff.inDays > 0) return 'vor ${diff.inDays}d';
    if (diff.inHours > 0) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inMinutes}min';
  }
}

// ============================================
// HELPER: NPUB QR SCANNER
// ============================================

class _NpubScannerScreen extends StatefulWidget {
  const _NpubScannerScreen();

  @override
  State<_NpubScannerScreen> createState() => _NpubScannerScreenState();
}

class _NpubScannerScreenState extends State<_NpubScannerScreen> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      String? code = barcode.rawValue;
      if (code != null) {
        code = code.trim().toLowerCase();
        if (code.startsWith('nostr:')) code = code.replaceFirst('nostr:', '');
        if (code.startsWith('npub1') && code.length > 50) {
          setState(() => _isScanned = true);
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
      appBar: AppBar(title: Text(AppLocalizations.of(context).wotScanNpub),
          backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Positioned(
            bottom: 60, left: 40, right: 40,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(kTileRadius),
                border: Border.all(color: cPurple),
              ),
              child: Text(
                AppLocalizations.of(context).wotScanInstruction,
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
