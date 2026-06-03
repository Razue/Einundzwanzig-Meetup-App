import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_logger.dart';

/// Ein Geocoding-Treffer (Ort → Koordinaten) via OpenStreetMap Nominatim.
class GeoPlace {
  final String displayName; // z.B. "Hamburg, Deutschland"
  final String shortName; // z.B. "Hamburg"
  final double lat;
  final double lng;

  GeoPlace({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lng,
  });
}

/// Sucht Orte per Freitext über Nominatim (OpenStreetMap).
/// Kein API-Key nötig. Fair-Use: max 1 Anfrage/Sekunde, User-Agent Pflicht.
class GeocodingService {
  static const String _base = 'https://nominatim.openstreetmap.org/search';

  /// Sucht bis zu [limit] Orte zum [query]. Gibt leere Liste bei Fehler.
  static Future<List<GeoPlace>> search(String query, {int limit = 5}) async {
    final q = query.trim();
    if (q.length < 2) return [];
    try {
      final uri = Uri.parse(_base).replace(queryParameters: {
        'q': q,
        'format': 'jsonv2',
        'limit': '$limit',
        'addressdetails': '1',
        'accept-language': 'de,en',
      });
      final res = await http.get(uri, headers: {
        // Nominatim verlangt einen aussagekräftigen User-Agent
        'User-Agent': 'EinundzwanzigMeetupApp/1.0 (nostr meetup app)',
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        AppLogger.debug('Geocode', 'Status ${res.statusCode}');
        return [];
      }
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) {
        final display = (e['display_name'] ?? '').toString();
        final name = (e['name'] ?? '').toString();
        return GeoPlace(
          displayName: display,
          shortName: name.isNotEmpty ? name : display.split(',').first.trim(),
          lat: double.tryParse(e['lat']?.toString() ?? '') ?? 0,
          lng: double.tryParse(e['lon']?.toString() ?? '') ?? 0,
        );
      }).where((p) => p.lat != 0 || p.lng != 0).toList();
    } catch (e) {
      AppLogger.debug('Geocode', 'Fehler: $e');
      return [];
    }
  }
}
