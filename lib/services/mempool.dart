import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_logger.dart';

/// Gebündelte Kennzahlen fürs Bitcoin-Dashboard.
class BitcoinDashboardData {
  final int blockHeight;
  final int feeLow;      // sat/vB (economy / low)
  final int feeMedium;   // sat/vB (half hour / medium)
  final int feeHigh;     // sat/vB (fastest / high)
  final double priceEur; // BTC/EUR
  final double priceUsd; // BTC/USD (für Moscow Time)
  final int supply;      // aktuell existierende BTC (ganze Coins, berechnet)
  final double hashrateEhs; // EH/s
  final double difficultyChangePct; // z.B. -3.7
  final int difficultyRemainingBlocks; // verbleibende Blöcke bis Anpassung
  final double lnCapacityBtc;  // Lightning-Kapazität in BTC
  final int lnNodeCount;       // Anzahl Lightning-Nodes
  final int lnChannelCount;    // Anzahl Lightning-Kanäle
  final DateTime updatedAt;

  const BitcoinDashboardData({
    required this.blockHeight,
    required this.feeLow,
    required this.feeMedium,
    required this.feeHigh,
    required this.priceEur,
    required this.priceUsd,
    required this.supply,
    required this.hashrateEhs,
    required this.difficultyChangePct,
    required this.difficultyRemainingBlocks,
    required this.lnCapacityBtc,
    required this.lnNodeCount,
    required this.lnChannelCount,
    required this.updatedAt,
  });

  /// Moscow Time = Sats pro 1 USD, gelesen wie eine Uhrzeit.
  /// Beispiel: 1827 Sats/USD -> "18:27".
  String get moscowTime {
    if (priceUsd <= 0) return '--:--';
    final satsPerDollar = (100000000 / priceUsd).round();
    final s = satsPerDollar.toString().padLeft(4, '0');
    final head = s.substring(0, s.length - 2);
    final tail = s.substring(s.length - 2);
    return '$head:$tail';
  }
}

class MempoolService {
  static const String _baseUrl = 'https://mempool.space/api';

  /// Letzter erfolgreich geladener Datensatz — wird angezeigt, während neu
  /// geladen wird oder falls eine Quelle mal ausfällt (keine leere Kachel).
  static BitcoinDashboardData? lastDashboard;

  // Holt die aktuelle Blockhöhe (Tip Height)
  static Future<int> getBlockHeight() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/blocks/tip/height'));
      
      if (response.statusCode == 200) {
        // Die API gibt einfach nur eine Zahl zurück (z.B. 829450)
        return int.parse(response.body);
      } else {
        return 0; // Fehler
      }
    } catch (e) {
      AppLogger.debug('App', "Mempool Fehler: $e");
      return 0; // Offline oder Fehler
    }
  }

  /// Vom mempool.space-Preis-Endpoint unterstützte Fiat-Währungen.
  static const List<String> supportedCurrencies = [
    'EUR', 'USD', 'GBP', 'CHF', 'CAD', 'AUD', 'JPY',
  ];

  /// Holt die aktuellen BTC-Preise in allen unterstützten Währungen.
  /// Gibt eine Map zurück, z.B. {'EUR': 95000.0, 'USD': 103000.0, ...}.
  /// Leere Map bei Fehler/offline.
  static Future<Map<String, double>> getPrices() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/v1/prices'));
      if (response.statusCode != 200) return {};
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = <String, double>{};
      for (final cur in supportedCurrencies) {
        final v = data[cur];
        if (v is num) result[cur] = v.toDouble();
      }
      return result;
    } catch (e) {
      AppLogger.debug('App', "Mempool Preis-Fehler: $e");
      return {};
    }
  }

  /// Errechnet die zum Block-Zeitpunkt existierende BTC-Menge (ganze Coins)
  /// aus dem deterministischen Ausgabeschema (50 BTC, Halbierung alle
  /// 210.000 Blöcke). Braucht keine API.
  static int _circulatingSupply(int height) {
    var reward = 50.0;
    var supply = 0.0;
    var h = height;
    while (h > 0 && reward >= 0.00000001) {
      final blocksInEra = h > 210000 ? 210000 : h;
      supply += blocksInEra * reward;
      h -= blocksInEra;
      reward /= 2;
    }
    return supply.round();
  }

  /// Holt alle Dashboard-Kennzahlen parallel von mempool.space.
  /// Einzelne fehlgeschlagene Quellen fallen auf den letzten bekannten Wert
  /// (bzw. 0) zurück, statt die ganze Kachel leer zu lassen.
  static Future<BitcoinDashboardData> getDashboardData() async {
    final prev = lastDashboard;

    Future<T> safe<T>(Future<T> Function() f, T fallback) async {
      try { return await f().timeout(const Duration(seconds: 12)); }
      catch (_) { return fallback; }
    }

    final results = await Future.wait([
      safe(getBlockHeight, prev?.blockHeight ?? 0),
      safe(() async {
        final r = await http.get(Uri.parse('$_baseUrl/v1/fees/recommended'));
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        return [
          (d['economyFee'] as num?)?.toInt() ?? (d['minimumFee'] as num?)?.toInt() ?? 0,
          (d['halfHourFee'] as num?)?.toInt() ?? 0,
          (d['fastestFee'] as num?)?.toInt() ?? 0,
        ];
      }, [prev?.feeLow ?? 0, prev?.feeMedium ?? 0, prev?.feeHigh ?? 0]),
      safe(getPrices, <String, double>{}),
      safe(() async {
        final r = await http.get(Uri.parse('$_baseUrl/v1/mining/hashrate/3d'));
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        final hr = (d['currentHashrate'] as num?)?.toDouble() ?? 0;
        return hr / 1e18; // H/s -> EH/s
      }, prev?.hashrateEhs ?? 0.0),
      safe(() async {
        final r = await http.get(Uri.parse('$_baseUrl/v1/difficulty-adjustment'));
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        return [
          (d['difficultyChange'] as num?)?.toDouble() ?? 0.0,
          ((d['remainingBlocks'] as num?)?.toInt() ?? 0).toDouble(),
        ];
      }, [prev?.difficultyChangePct ?? 0.0, (prev?.difficultyRemainingBlocks ?? 0).toDouble()]),
      safe(() async {
        final r = await http.get(Uri.parse('$_baseUrl/v1/lightning/statistics/latest'));
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        final latest = d['latest'] as Map<String, dynamic>? ?? d;
        final capSats = (latest['total_capacity'] as num?)?.toDouble() ?? 0;
        return [
          capSats / 1e8, // Sats -> BTC
          ((latest['node_count'] as num?)?.toInt() ?? 0).toDouble(),
          ((latest['channel_count'] as num?)?.toInt() ?? 0).toDouble(),
        ];
      }, [prev?.lnCapacityBtc ?? 0.0, (prev?.lnNodeCount ?? 0).toDouble(), (prev?.lnChannelCount ?? 0).toDouble()]),
    ]);

    final height = results[0] as int;
    final fees = results[1] as List<int>;
    final prices = results[2] as Map<String, double>;
    final hashrate = results[3] as double;
    final diff = results[4] as List<double>;
    final ln = results[5] as List<double>;

    final data = BitcoinDashboardData(
      blockHeight: height,
      feeLow: fees[0],
      feeMedium: fees[1],
      feeHigh: fees[2],
      priceEur: prices['EUR'] ?? prev?.priceEur ?? 0,
      priceUsd: prices['USD'] ?? prev?.priceUsd ?? 0,
      supply: height > 0 ? _circulatingSupply(height) : (prev?.supply ?? 0),
      hashrateEhs: hashrate,
      difficultyChangePct: diff[0],
      difficultyRemainingBlocks: diff[1].toInt(),
      lnCapacityBtc: ln[0],
      lnNodeCount: ln[1].toInt(),
      lnChannelCount: ln[2].toInt(),
      updatedAt: DateTime.now(),
    );
    lastDashboard = data;
    return data;
  }
}