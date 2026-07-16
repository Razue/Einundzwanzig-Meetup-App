// ============================================
// SATOSHIDUELL SERVICE — offene Duelle zählen
// ============================================
// Liest die öffentliche Supabase-REST-API von satoshiduell.de mit dem
// anon-Key. Der Key ist KEIN Geheimnis: er steckt identisch im
// JavaScript-Bundle der WebApp und ist durch Row-Level-Security begrenzt —
// die Meetup-App kann damit exakt das lesen, was die WebApp selbst liest.
//
// Die Zähl-Logik ist 1:1 von fetchOpenDuels() der WebApp übernommen
// (satoshiduell-v2/src/services/supabase.js):
//   status = 'open'  UND  creator != ich  UND
//   (target_player IS NULL  ODER  target_player = ich)
// -> also: alle Duelle, die ich annehmen könnte — offene Herausforderungen
//    an alle plus gezielte Herausforderungen an mich.
//
// Scheitert IRGENDETWAS (offline, RLS, Nutzer hat nie gespielt), gibt es
// still 0 zurück — die Kachel zeigt dann einfach kein Badge. Ein Spiele-
// Badge darf nie eine Fehlermeldung produzieren.
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'signing_service.dart';
import 'app_logger.dart';

class SatoshiDuellService {
  static const String _tag = 'SatoshiDuell';

  static const String _base = 'https://uydjemquyogdemjtxyyv.supabase.co/rest/v1';

  /// Öffentlicher anon-Key (identisch im WebApp-Bundle, RLS-begrenzt).
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV5ZGplbXF1eW9nZGVtanR4eXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5OTEzNDcsImV4cCI6MjA4NDU2NzM0N30.YPTpsDEF1_aSFnGU2Qp-nR12QSv3sTBK8CGlhD4fVIU';

  static const Duration _timeout = Duration(seconds: 8);

  static Map<String, String> get _headers => {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Accept': 'application/json',
      };

  // RAM-Cache: das Badge muss nicht bei jedem Hub-Aufbau neu laden.
  static int? _cachedCount;
  static DateTime? _cachedAt;
  static const Duration _ttl = Duration(minutes: 10);

  /// SatoshiDuell-Spielername zum npub — oder null, wenn der Nutzer dort
  /// noch nie gespielt hat. Die WebApp speichert npubs lowercase.
  static Future<String?> _usernameFor(String npub) async {
    final uri = Uri.parse(
        '$_base/profiles?npub=eq.${Uri.encodeQueryComponent(npub.toLowerCase())}&select=username&limit=1');
    final r = await http.get(uri, headers: _headers).timeout(_timeout);
    if (r.statusCode != 200) {
      AppLogger.diag(_tag, 'profiles-Abfrage: HTTP ${r.statusCode}');
      return null;
    }
    final list = jsonDecode(r.body);
    if (list is List && list.isNotEmpty && list.first is Map) {
      final u = (list.first['username'] ?? '').toString();
      return u.isEmpty ? null : u;
    }
    return null; // noch nie gespielt
  }

  /// Anzahl offener Duelle, die der Nutzer annehmen könnte.
  /// 0 bei Fehlern jeder Art (bewusst still — siehe Kopfkommentar).
  static Future<int> openDuelCount({bool forceRefresh = false}) async {
    // Cache
    if (!forceRefresh && _cachedCount != null && _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _ttl) {
      return _cachedCount!;
    }

    try {
      final npub = await SigningService.npub();
      if (npub == null || npub.isEmpty) return 0;

      final username = await _usernameFor(npub);
      if (username == null) return 0; // dort kein Konto -> kein Badge

      // Duelle zählen — Filter wie fetchOpenDuels() der WebApp.
      // Zählung über den Content-Range-Header (Prefer: count=exact,
      // Range 0-0), damit keine Datensätze übertragen werden.
      final me = Uri.encodeQueryComponent(username.toLowerCase());
      final uri = Uri.parse(
          '$_base/duels?select=id&status=eq.open&creator=neq.$me'
          '&or=(target_player.is.null,target_player.eq.$me)');
      final r = await http.get(uri, headers: {
        ..._headers,
        'Prefer': 'count=exact',
        'Range': '0-0',
      }).timeout(_timeout);

      if (r.statusCode != 200 && r.statusCode != 206) {
        AppLogger.diag(_tag, 'duels-Abfrage: HTTP ${r.statusCode}');
        return _cachedCount ?? 0;
      }

      // Content-Range: "0-0/17" -> 17
      final range = r.headers['content-range'] ?? '';
      final total = int.tryParse(range.split('/').last) ??
          // Fallback, falls der Header fehlt: gelieferte Zeilen zählen.
          ((jsonDecode(r.body) is List) ? (jsonDecode(r.body) as List).length : 0);

      _cachedCount = total;
      _cachedAt = DateTime.now();
      return total;
    } catch (e) {
      AppLogger.diag(_tag, 'openDuelCount fehlgeschlagen: ${e.runtimeType}');
      return _cachedCount ?? 0;
    }
  }
}
