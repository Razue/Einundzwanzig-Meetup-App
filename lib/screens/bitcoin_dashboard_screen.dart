// ============================================
//  Bitcoin Dashboard — Vollansicht
// ============================================
//  Zeigt die wichtigsten Netzwerk-Kennzahlen im Einundzwanzig-Design,
//  nachempfunden der Blockclock-Optik: große Blockhöhe oben, darunter
//  Detailzeilen (Fees, Moscow, EUR/BTC, Supply, Hashrate, Difficulty) +
//  Lightning-Netzwerk-Daten. Daten von der konfigurierten Mempool-Instanz
//  (Standard: mempool.space). Aktualisierung: beim Öffnen + alle 60 s.
//
//  STATUSPUNKT (v1.3.0 korrigiert):
//  Vorher war der Punkt IMMER grün, weil getDashboardData() auch bei
//  komplettem Netzausfall ein Objekt (voller Nullen) zurückgab. Nutzer sahen
//  "grün, Stand 07:41" neben lauter "––". Jetzt spiegelt der Punkt wider,
//  wie viele Quellen wirklich geliefert haben:
//    grün  = alle 6
//    gelb  = 1..5 (teilweise)
//    rot   = 0    -> Banner mit Ursache + Weg zu den Server-Einstellungen
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/mempool.dart';
import '../services/mempool_config.dart';
import 'mempool_settings_screen.dart';

class BitcoinDashboardScreen extends StatefulWidget {
  const BitcoinDashboardScreen({super.key});

  @override
  State<BitcoinDashboardScreen> createState() => _BitcoinDashboardScreenState();
}

class _BitcoinDashboardScreenState extends State<BitcoinDashboardScreen> {
  BitcoinDashboardData? _data;
  bool _loading = true;
  bool _fresh = false; // Punkt kurz hell nach Update
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _data = MempoolService.lastDashboard; // sofort etwas zeigen, falls vorhanden
    _load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await MempoolService.getDashboardData();
    if (!mounted) return;
    setState(() { _data = d; _loading = false; _fresh = true; });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _fresh = false);
    });
  }

  String _fmtInt(int v) {
    // Tausenderpunkte (deutsches Format)
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Farbe des Statuspunkts — spiegelt den ECHTEN Ladezustand.
  Color _statusColor(BitcoinDashboardData? d) {
    if (d == null) return cTextTertiary;
    if (d.isDead) return cRed;
    if (d.isLive) return cGreen;
    return cOrange; // teilweise geladen
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final d = _data;
    final dot = _statusColor(d);

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: const Text('Bitcoin', style: TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: cTextSecondary, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: (d == null && _loading)
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : RefreshIndicator(
              color: cOrange,
              backgroundColor: cCard,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                children: [
                  // Statuspunkt + Uhrzeit
                  Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _fresh ? dot : dot.withValues(alpha: 0.55),
                          boxShadow: _fresh ? [BoxShadow(color: dot.withValues(alpha: 0.6), blurRadius: 8)] : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        d != null && !d.isDead ? _timeLabel(d.updatedAt) : '--:--',
                        style: const TextStyle(color: cTextSecondary, fontSize: 14).copyWith(fontFamily: fontMono),
                      ),
                    ]),
                  ),

                  // Fehlerbanner — nur wenn wirklich nichts (oder wenig) kam.
                  if (d != null && d.isDead) ...[
                    const SizedBox(height: 20),
                    _errorBanner(t, d),
                  ] else if (d != null && !d.isLive) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '${t.dashPartial} (${d.sourcesOk}/${d.sourcesTotal})',
                        style: const TextStyle(color: cOrange, fontSize: 12),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // BLOCK groß
                  const Center(child: Text('BLOCK',
                      style: TextStyle(color: cTextSecondary, fontSize: 13, letterSpacing: 3, fontWeight: FontWeight.w600))),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      d != null && d.blockHeight > 0 ? _fmtInt(d.blockHeight) : '––',
                      style: const TextStyle(color: cOrange, fontSize: 64, fontWeight: FontWeight.w800, letterSpacing: 1, height: 1.0),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (d != null) ...[
                    _row('FEES  L·M·H',
                        d.feeHigh > 0 ? '${d.feeLow}·${d.feeMedium}·${d.feeHigh}' : '––'),
                    _row('MOSCOW', d.moscowTime),
                    _row('EUR/BTC', d.priceEur > 0 ? _fmtInt(d.priceEur.round()) : '––'),
                    _row('SUPPLY', d.supply > 0 ? _fmtInt(d.supply) : '––'),
                    _row('HASHRATE', d.hashrateEhs > 0 ? '${d.hashrateEhs.toStringAsFixed(0)} EH/s' : '––'),
                    _row('DIFFICULTY',
                        d.blockHeight > 0
                            ? '${d.difficultyChangePct >= 0 ? '+' : ''}${d.difficultyChangePct.toStringAsFixed(1)}% / ${d.difficultyRemainingBlocks} blk'
                            : '––'),

                    // Lightning-Abschnitt
                    const SizedBox(height: 20),
                    Row(children: [
                      const Icon(Icons.bolt_rounded, color: cOrange, size: 16),
                      const SizedBox(width: 6),
                      const Text('LIGHTNING', style: TextStyle(color: cOrange, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      Expanded(child: Container(height: 0.5, color: cTileBorder)),
                    ]),
                    const SizedBox(height: 8),
                    _row('KAPAZITÄT', d.lnCapacityBtc > 0 ? '${_fmtInt(d.lnCapacityBtc.round())} BTC' : '––'),
                    _row('NODES', d.lnNodeCount > 0 ? _fmtInt(d.lnNodeCount) : '––'),
                    _row('CHANNELS', d.lnChannelCount > 0 ? _fmtInt(d.lnChannelCount) : '––'),
                  ],

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      // Zeigt die TATSÄCHLICH genutzte Quelle — nicht mehr
                      // stur "mempool.space", wenn eine eigene Instanz läuft.
                      '${t.dashSource}: ${_hostLabel()}',
                      style: const TextStyle(color: cTextTertiary, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _hostLabel() {
    final h = MempoolConfig.host
        .replaceFirst('https://', '')
        .replaceFirst('http://', '');
    // Onion-Adressen sind 56 Zeichen lang — gekürzt anzeigen.
    if (h.length > 28) return '${h.substring(0, 12)}…${h.substring(h.length - 12)}';
    return h;
  }

  /// Ehrliches Fehlerbanner: sagt, WAS los ist, und bietet den Weg zur Lösung.
  Widget _errorBanner(AppLocalizations t, BitcoinDashboardData d) {
    final blocked = d.blocked;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cRed.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cRed.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.cloud_off_rounded, color: cRed, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                blocked ? t.dashBlockedTitle : t.dashOfflineTitle,
                style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            blocked ? t.dashBlockedBody : t.dashOfflineBody,
            style: const TextStyle(color: cTextSecondary, fontSize: 12, height: 1.4),
          ),
          if (d.lastError.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              d.lastError,
              style: const TextStyle(color: cTextTertiary, fontSize: 11).copyWith(fontFamily: fontMono),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: cOrange,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.dns_rounded, size: 16),
              label: Text(t.dashChangeServer, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const MempoolSettingsScreen()));
                if (mounted) _load();
              },
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(color: cOrange, fontSize: 20, fontWeight: FontWeight.w800).copyWith(fontFamily: fontMono)),
      ],
    ),
  );
}
