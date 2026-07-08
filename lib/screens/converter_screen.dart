// WECHSELRECHNER — Fiat <-> Satoshi/Bitcoin
// ============================================
// Standard: EUR <-> Satoshi.
// Fiat-Seite: viele Währungen wählbar (mempool.space unterstützt
//   EUR/USD/GBP/CHF/CAD/AUD/JPY).
// Krypto-Seite: zwischen Satoshi und Bitcoin umschaltbar.
// Kursquelle: mempool.space (Bitcoin-native, privatsphärefreundlich).
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/mempool.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  static const int _satsPerBtc = 100000000; // 100 Mio Sats = 1 BTC

  final TextEditingController _fiatCtrl = TextEditingController();
  final TextEditingController _cryptoCtrl = TextEditingController();

  String _currency = 'EUR';      // gewählte Fiat-Währung
  bool _cryptoIsBtc = false;     // false = Satoshi, true = Bitcoin
  bool _fiatIsInput = true;      // welche Seite zuletzt bearbeitet wurde

  Map<String, double> _prices = {}; // BTC-Preis je Währung
  bool _loading = true;
  bool _error = false;
  DateTime? _updated;

  // Auf-/Abschlag fürs Trading (in Prozent, mit Nachkommastelle).
  final TextEditingController _premiumCtrl = TextEditingController();
  double _premiumPercent = 0; // positiv = Aufschlag, negativ = Abschlag

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  @override
  void dispose() {
    _fiatCtrl.dispose();
    _cryptoCtrl.dispose();
    _premiumCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrices() async {
    setState(() { _loading = true; _error = false; });
    final prices = await MempoolService.getPrices();
    if (!mounted) return;
    if (prices.isEmpty) {
      setState(() { _loading = false; _error = true; });
      return;
    }
    setState(() {
      _prices = prices;
      _loading = false;
      _updated = DateTime.now();
    });
    _recalculate();
  }

  /// Aktueller BTC-Preis in der gewählten Währung (0 wenn unbekannt).
  double get _btcPrice => _prices[_currency] ?? 0;

  /// Der aktuelle Fiat-Betrag (aus dem Fiat-Feld oder berechnet).
  double get _currentFiat {
    final direct = double.tryParse(_fiatCtrl.text.replaceAll(',', '.'));
    if (direct != null) return direct;
    final raw = double.tryParse(_cryptoCtrl.text.replaceAll(',', '.'));
    if (raw != null && _btcPrice > 0) {
      final btc = _cryptoIsBtc ? raw : raw / _satsPerBtc;
      return btc * _btcPrice;
    }
    return 0;
  }

  /// Fiat-Betrag mit Auf-/Abschlag (fürs Trading).
  double get _fiatWithPremium => _currentFiat * (1 + _premiumPercent / 100);

  void _onPremiumChanged(String v) {
    setState(() {
      _premiumPercent = double.tryParse(v.replaceAll(',', '.')) ?? 0;
    });
  }

  /// Berechnet die jeweils andere Seite neu, je nachdem welche
  /// Seite zuletzt bearbeitet wurde.
  void _recalculate() {
    if (_btcPrice <= 0) return;
    if (_fiatIsInput) {
      final fiat = double.tryParse(_fiatCtrl.text.replaceAll(',', '.'));
      if (fiat == null) { _cryptoCtrl.text = ''; return; }
      final btc = fiat / _btcPrice;
      _cryptoCtrl.text = _formatCrypto(btc);
    } else {
      final raw = double.tryParse(_cryptoCtrl.text.replaceAll(',', '.'));
      if (raw == null) { _fiatCtrl.text = ''; return; }
      final btc = _cryptoIsBtc ? raw : raw / _satsPerBtc;
      final fiat = btc * _btcPrice;
      _fiatCtrl.text = fiat.toStringAsFixed(2);
    }
  }

  /// Formatiert einen BTC-Wert je nach Einheit (Sats = ganzzahlig, BTC = 8 Dezimalstellen).
  String _formatCrypto(double btc) {
    if (_cryptoIsBtc) {
      return btc.toStringAsFixed(8);
    } else {
      final sats = btc * _satsPerBtc;
      return sats.round().toString();
    }
  }

  void _onFiatChanged(String _) {
    _fiatIsInput = true;
    setState(_recalculate);
  }

  void _onCryptoChanged(String _) {
    _fiatIsInput = false;
    setState(_recalculate);
  }

  void _swapUnit() {
    // Satoshi <-> Bitcoin umschalten, aktuellen Betrag mitnehmen
    setState(() {
      _cryptoIsBtc = !_cryptoIsBtc;
      // Krypto-Feld in neue Einheit umrechnen, falls befüllt
      final raw = double.tryParse(_cryptoCtrl.text.replaceAll(',', '.'));
      if (raw != null) {
        if (_cryptoIsBtc) {
          // war Sats -> jetzt BTC
          _cryptoCtrl.text = (raw / _satsPerBtc).toStringAsFixed(8);
        } else {
          // war BTC -> jetzt Sats
          _cryptoCtrl.text = (raw * _satsPerBtc).round().toString();
        }
      }
    });
  }

  void _pickCurrency() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).convSelectCurrency,
              style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...MempoolService.supportedCurrencies.map((cur) {
            final selected = cur == _currency;
            return ListTile(
              title: Text(cur, style: TextStyle(color: selected ? cOrange : cText, fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
              trailing: selected ? const Icon(Icons.check_rounded, color: cOrange, size: 20) : null,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _currency = cur);
                _recalculate();
              },
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.convTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: cTextSecondary),
            tooltip: t.convRefresh,
            onPressed: _loading ? null : _loadPrices,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (_error) _errorBanner(t),
            // ── Fiat-Feld ──
            _fieldCard(
              label: t.convYouPay,
              controller: _fiatCtrl,
              onChanged: _onFiatChanged,
              trailing: _currencyChip(),
            ),
            // ── Tausch-Symbol (nur Deko zwischen den Feldern) ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: cCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: cTileBorder, width: 0.5),
                  ),
                  child: const Icon(Icons.swap_vert_rounded, color: cOrange, size: 20),
                ),
              ),
            ),
            // ── Krypto-Feld ──
            _fieldCard(
              label: _cryptoIsBtc ? t.convUnitBtc : t.convUnitSats,
              controller: _cryptoCtrl,
              onChanged: _onCryptoChanged,
              trailing: _unitToggle(t),
            ),
            const SizedBox(height: 20),
            // ── Auf-/Abschlag fürs Trading ──
            _premiumSection(t),
            const SizedBox(height: 20),
            // ── Kursinfo ──
            _rateInfo(t),
          ]),
        ),
      ),
    );
  }

  /// Auf-/Abschlag-Bereich fürs Trading: Schieberegler + manuelle Eingabe,
  /// zeigt den angepassten Fiat-Preis UND die resultierende Sats-Menge.
  Widget _premiumSection(AppLocalizations t) {
    final base = _currentFiat;
    final withP = _fiatWithPremium;
    final hasValue = base > 0;
    // Sats, die bei diesem angepassten Fiat-Betrag herauskommen.
    final satsWithP = (_btcPrice > 0) ? (withP / _btcPrice * _satsPerBtc).round() : 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.trending_up_rounded, color: cOrange, size: 16),
          const SizedBox(width: 8),
          Text(t.convPremiumTitle,
              style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          // Manuelle Eingabe (kompakt, rechts)
          SizedBox(
            width: 82,
            child: Container(
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cTileBorder, width: 0.5),
              ),
              child: TextField(
                controller: _premiumCtrl,
                onChanged: _onPremiumChanged,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                textAlign: TextAlign.center,
                style: const TextStyle(color: cOrange, fontSize: 15, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  hintText: '0,0',
                  hintStyle: TextStyle(color: cTextTertiary),
                  suffixText: '%',
                  suffixStyle: TextStyle(color: cOrange, fontWeight: FontWeight.w700, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(t.convPremiumHint,
            style: const TextStyle(color: cTextTertiary, fontSize: 11)),
        const SizedBox(height: 8),
        // Schieberegler von -20% bis +20% in 0,5-Schritten
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: cOrange,
            inactiveTrackColor: cSurface,
            thumbColor: cOrange,
            overlayColor: cOrange.withValues(alpha: 0.15),
            trackHeight: 3,
          ),
          child: Slider(
            value: _premiumPercent.clamp(-20.0, 20.0),
            min: -20,
            max: 20,
            divisions: 80, // 0,5-Schritte
            label: '${_premiumPercent > 0 ? '+' : ''}${_premiumPercent.toStringAsFixed(1)}%',
            onChanged: (v) {
              setState(() {
                _premiumPercent = (v * 2).round() / 2; // auf 0,5 runden
                _premiumCtrl.text = _premiumPercent == 0 ? '' : _premiumPercent.toString();
              });
            },
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          Text('−20%', style: TextStyle(color: cTextTertiary, fontSize: 10)),
          Text('0', style: TextStyle(color: cTextTertiary, fontSize: 10)),
          Text('+20%', style: TextStyle(color: cTextTertiary, fontSize: 10)),
        ]),
        if (hasValue) ...[
          const SizedBox(height: 14),
          Container(height: 0.5, color: cTileBorder),
          const SizedBox(height: 14),
          // Ergebnis: angepasster Fiat-Preis
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(t.convPremiumResult, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
            Text('${withP.toStringAsFixed(2)} $_currency',
                style: const TextStyle(color: cOrange, fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
          // Ergebnis: resultierende Sats-Menge
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(t.convPremiumSats, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
            Text('${_fmtSats(satsWithP)} sats',
                style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(t.convPremiumBase, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
            Text('${base.toStringAsFixed(2)} $_currency',
                style: const TextStyle(color: cTextTertiary, fontSize: 12)),
          ]),
        ],
      ]),
    );
  }

  /// Tausenderpunkte für Sats.
  String _fmtSats(int v) {
    final s = v.abs().toString();
    final buf = StringBuffer(v < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _errorBanner(AppLocalizations t) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: cRed.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(kTileRadius),
      border: Border.all(color: cRed.withValues(alpha: 0.3), width: 0.5),
    ),
    child: Row(children: [
      const Icon(Icons.cloud_off_rounded, color: cRed, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(t.convOffline, style: const TextStyle(color: cRed, fontSize: 12))),
      TextButton(onPressed: _loadPrices, child: Text(t.convRefresh, style: const TextStyle(color: cOrange))),
    ]),
  );

  Widget _fieldCard({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              style: const TextStyle(color: cText, fontSize: 26, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '0',
                hintStyle: TextStyle(color: cTextTertiary, fontSize: 26, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ]),
      ]),
    );
  }

  /// Währungs-Auswahl-Chip (Fiat-Seite).
  Widget _currencyChip() => InkWell(
    onTap: _pickCurrency,
    borderRadius: BorderRadius.circular(kTileRadius),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(_currency, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        const Icon(Icons.expand_more_rounded, color: cTextSecondary, size: 18),
      ]),
    ),
  );

  /// Sats/BTC-Umschalter (Krypto-Seite).
  Widget _unitToggle(AppLocalizations t) => InkWell(
    onTap: _swapUnit,
    borderRadius: BorderRadius.circular(kTileRadius),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cOrange.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(_cryptoIsBtc ? 'BTC' : 'sats',
            style: const TextStyle(color: cOrange, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        const Icon(Icons.swap_horiz_rounded, color: cOrange, size: 16),
      ]),
    ),
  );

  Widget _rateInfo(AppLocalizations t) {
    if (_loading) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(t.convLoading, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
      ));
    }
    if (_btcPrice <= 0) return const SizedBox.shrink();
    final priceStr = _btcPrice.toStringAsFixed(0);
    return Column(children: [
      Text(t.convRateInfo(priceStr, _currency),
          style: const TextStyle(color: cTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      if (_updated != null)
        Text(t.convUpdated(_fmtTime(_updated!)),
            style: const TextStyle(color: cTextTertiary, fontSize: 11)),
      const SizedBox(height: 2),
      Text(t.convSource, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
    ]);
  }

  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
