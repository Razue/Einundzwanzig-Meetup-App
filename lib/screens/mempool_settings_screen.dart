// ============================================
// MEMPOOL SETTINGS SCREEN — Datenquelle wählen
// ============================================
// Drei Modi:
//   1. mempool.space (Standard, Clearnet)
//   2. Tor / Onion — offizielle .onion von mempool.space
//   3. Eigene Instanz — z.B. Umbrel/Start9/RaspiBlitz im Heimnetz
//
// WARUM TOR NÖTIG IST:
// mempool.space liegt hinter Cloudflare. Von Tor-Exit-Knoten kommen dort
// regelmäßig 403/429 zurück (die IP wird von tausenden Nutzern geteilt).
// Die App bekam dann kein JSON und zeigte stumm Nullen. Über die .onion
// läuft die Verbindung gar nicht erst über einen Exit-Knoten — Cloudflare
// sieht sie nie.
//
// VORAUSSETZUNG: Orbot im VPN-Modus (löst .onion selbst auf). Ohne Orbot
// ist eine .onion-Adresse nicht erreichbar — deshalb der Warnhinweis.
//
// Erreichbar über: Home → Einstellungen → Netzwerk → Mempool-Server
// ============================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/mempool.dart';
import '../services/mempool_config.dart';

class MempoolSettingsScreen extends StatefulWidget {
  const MempoolSettingsScreen({super.key});

  @override
  State<MempoolSettingsScreen> createState() => _MempoolSettingsScreenState();
}

class _MempoolSettingsScreenState extends State<MempoolSettingsScreen> {
  MempoolMode _mode = MempoolMode.clearnet;
  final _customCtrl = TextEditingController();

  bool _testing = false;
  String _testResult = '';
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await MempoolConfig.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _mode = MempoolConfig.mode;
      if (_mode == MempoolMode.custom) _customCtrl.text = MempoolConfig.host;
    });
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  /// Der Host, der zum aktuell gewählten Modus gehört.
  String get _selectedHost {
    switch (_mode) {
      case MempoolMode.clearnet:
        return MempoolConfig.clearnetHost;
      case MempoolMode.tor:
        return MempoolConfig.torHost;
      case MempoolMode.custom:
        return MempoolConfig.normalize(_customCtrl.text);
    }
  }

  Future<void> _select(MempoolMode m) async {
    setState(() {
      _mode = m;
      _testResult = '';
    });
    // Custom erst speichern, wenn die Eingabe plausibel ist — sonst würden
    // wir bei jedem Tastendruck Müll persistieren.
    if (m == MempoolMode.custom && !MempoolConfig.looksValid(_customCtrl.text)) {
      return;
    }
    await MempoolConfig.setMode(m, custom: _customCtrl.text);
    MempoolService.lastDashboard = null; // alte Werte gehören zur alten Quelle
  }

  Future<void> _saveCustom() async {
    final t = AppLocalizations.of(context);
    if (!MempoolConfig.looksValid(_customCtrl.text)) {
      setState(() {
        _testOk = false;
        _testResult = t.mempoolInvalidUrl;
      });
      return;
    }
    await MempoolConfig.setMode(MempoolMode.custom, custom: _customCtrl.text);
    MempoolService.lastDashboard = null;
    if (!mounted) return;
    setState(() {
      _customCtrl.text = MempoolConfig.host;
      _testResult = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.mempoolSaved), backgroundColor: cCard),
    );
  }

  Future<void> _test() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _testing = true;
      _testResult = '';
      _testOk = false;
    });

    final host = _selectedHost;
    try {
      final height = await MempoolService.testHost(host);
      if (!mounted) return;
      setState(() {
        _testOk = true;
        _testResult = '${t.mempoolTestOk} · Block $height';
      });
    } catch (e) {
      if (!mounted) return;
      String msg;
      if (e is MempoolHttpException) {
        msg = e.looksBlocked
            ? '${t.mempoolTestBlocked} (HTTP ${e.statusCode})'
            : '${t.mempoolTestFail} — HTTP ${e.statusCode}';
      } else if (host.contains('.onion')) {
        // Häufigster Grund: Orbot läuft nicht / App nicht im Orbot-VPN.
        msg = t.mempoolTestOnionFail;
      } else {
        msg = '${t.mempoolTestFail} — ${e.runtimeType}';
      }
      setState(() {
        _testOk = false;
        _testResult = msg;
      });
    } finally {
      if (mounted) setState(() => _testing = false);
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
        title: Text(t.mempoolTitle,
            style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Text(t.mempoolIntro,
              style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.45)),
          const SizedBox(height: 20),

          _option(
            mode: MempoolMode.clearnet,
            icon: Icons.public_rounded,
            color: cOrange,
            title: t.mempoolClearnetTitle,
            subtitle: 'mempool.space',
          ),
          _option(
            mode: MempoolMode.tor,
            icon: Icons.shield_rounded,
            color: cPurple,
            title: t.mempoolTorTitle,
            subtitle: t.mempoolTorSub,
          ),
          _option(
            mode: MempoolMode.custom,
            icon: Icons.dns_rounded,
            color: cGreen,
            title: t.mempoolCustomTitle,
            subtitle: t.mempoolCustomSub,
          ),

          // Hinweis, wenn Tor gewählt ist: ohne Orbot geht gar nichts.
          if (_mode == MempoolMode.tor) ...[
            const SizedBox(height: 12),
            _hint(Icons.info_outline_rounded, cPurple, t.mempoolTorHint),
          ],

          // Freie Eingabe für die eigene Instanz.
          if (_mode == MempoolMode.custom) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _customCtrl,
              style: const TextStyle(color: cText, fontSize: 14),
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'https://mempool.mein-node.local',
                hintStyle: const TextStyle(color: cTextTertiary, fontSize: 13),
                filled: true,
                fillColor: cCard,
              ),
              onSubmitted: (_) => _saveCustom(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveCustom,
                child: Text(t.mempoolSave),
              ),
            ),
          ],

          const SizedBox(height: 22),

          // Verbindungstest — beantwortet die Frage "geht es überhaupt?"
          // ohne dass der Nutzer erst ins Dashboard zurückwechseln muss.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testing ? null : _test,
              icon: _testing
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: cOrange))
                  : const Icon(Icons.network_check_rounded, size: 18),
              label: Text(_testing ? t.mempoolTesting : t.mempoolTest),
            ),
          ),

          if (_testResult.isNotEmpty) ...[
            const SizedBox(height: 12),
            _hint(
              _testOk ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              _testOk ? cGreen : cRed,
              _testResult,
            ),
          ],

          const SizedBox(height: 24),
          Text(
            '${t.mempoolActive}:\n${MempoolConfig.host}',
            style: const TextStyle(color: cTextTertiary, fontSize: 11, height: 1.5)
                .copyWith(fontFamily: fontMono),
          ),
        ],
      ),
    );
  }

  Widget _option({
    required MempoolMode mode,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final selected = _mode == mode;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius + 2),
        border: Border.all(
          color: selected ? cOrange : cBorder,
          width: selected ? 1.4 : 0.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        title: Text(title,
            style: TextStyle(
                color: cText,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: cTextSecondary, fontSize: 12)),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded, color: cOrange, size: 20)
            : const Icon(Icons.circle_outlined, color: cTextTertiary, size: 20),
        onTap: () => _select(mode),
      ),
    );
  }

  Widget _hint(IconData icon, Color color, String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.7),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 9),
            Expanded(
              child: Text(text,
                  style: const TextStyle(color: cTextSecondary, fontSize: 12, height: 1.4)),
            ),
          ],
        ),
      );
}
