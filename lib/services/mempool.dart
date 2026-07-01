import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_logger.dart';

class MempoolService {
  static const String _baseUrl = 'https://mempool.space/api';

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
}