// ============================================
//  Bitcoin Dashboard — Vollansicht
// ============================================
//  Zeigt die wichtigsten Netzwerk-Kennzahlen im Einundzwanzig-Design,
//  nachempfunden der Blockclock-Optik: große Blockhöhe oben, darunter
//  Detailzeilen (Fees, Moscow, EUR/BTC, Supply, Hashrate, Difficulty) +
//  Lightning-Netzwerk-Daten. Daten von mempool.space (kein API-Key,
//  kein eigener Server). Aktualisierung: beim Öffnen + alle 60 s.
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/mempool.dart';

class BitcoinDashboardScreen extends StatefulWidget {
  const BitcoinDashboardScreen({super.key});

  @override
  State<BitcoinDashboardScreen> createState() => _BitcoinDashboardScreenState();
}

class _BitcoinDashboardScreenState extends State<BitcoinDashboardScreen> {
  BitcoinDashboardData? _data;
  bool _loading = true;
  bool _fresh = false; // grüner Punkt kurz hell nach Update
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

  @override
  Widget build(BuildContext context) {
    final d = _data;
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
                  // Live-Punkt + Uhrzeit
                  Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _fresh ? cGreen : cGreen.withValues(alpha: 0.55),
                          boxShadow: _fresh ? [BoxShadow(color: cGreen.withValues(alpha: 0.6), blurRadius: 8)] : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        d != null ? _timeLabel(d.updatedAt) : '--:--',
                        style: const TextStyle(color: cTextSecondary, fontSize: 14).copyWith(fontFamily: fontMono),
                      ),
                    ]),
                  ),
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
                    _row('FEES  L·M·H', '${d.feeLow}·${d.feeMedium}·${d.feeHigh}'),
                    _row('MOSCOW', d.moscowTime),
                    _row('EUR/BTC', d.priceEur > 0 ? _fmtInt(d.priceEur.round()) : '––'),
                    _row('SUPPLY', _fmtInt(d.supply)),
                    _row('HASHRATE', d.hashrateEhs > 0 ? '${d.hashrateEhs.toStringAsFixed(0)} EH/s' : '––'),
                    _row('DIFFICULTY',
                        '${d.difficultyChangePct >= 0 ? '+' : ''}${d.difficultyChangePct.toStringAsFixed(1)}% / ${d.difficultyRemainingBlocks} blk'),

                    // Lightning-Abschnitt
                    const SizedBox(height: 20),
                    Row(children: [
                      const Icon(Icons.bolt_rounded, color: cOrange, size: 16),
                      const SizedBox(width: 6),
                      Text('LIGHTNING', style: const TextStyle(color: cOrange, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      Expanded(child: Container(height: 0.5, color: cTileBorder)),
                    ]),
                    const SizedBox(height: 8),
                    _row('KAPAZITÄT', d.lnCapacityBtc > 0 ? '${_fmtInt(d.lnCapacityBtc.round())} BTC' : '––'),
                    _row('NODES', d.lnNodeCount > 0 ? _fmtInt(d.lnNodeCount) : '––'),
                    _row('CHANNELS', d.lnChannelCount > 0 ? _fmtInt(d.lnChannelCount) : '––'),
                  ],

                  const SizedBox(height: 24),
                  const Center(
                    child: Text('Daten: mempool.space',
                        style: TextStyle(color: cTextTertiary, fontSize: 11)),
                  ),
                ],
              ),
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
