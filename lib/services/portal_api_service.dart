// PORTAL-API-ANBINDUNG (einundzwanzig.space)
// ============================================
// Spricht die REST-API des Einundzwanzig-Portals an — lesend UND schreibend.
// Authentifizierung per persönlichem Bearer-Token (Sanctum), der nach dem
// Login vom Portal kommt und im sicheren Keystore liegt.
//
// Vorbild: die offizielle "TWENTY ONE Companion"-App
// (github.com/HolgerHatGarKeineNode/twenty-one-companion). Endpunkte & Auth
// sind daran angelehnt.
//
// LOGIN (stateless, kind 22242 / NIP-42-artig):
//   1. App würfelt k1 lokal (32 Zufallsbytes)
//   2. baut unsigniertes kind-22242 mit ["challenge", k1]
//   3. signiert es über den bestehenden SigningService (lokaler nsec ODER
//      Amber — beides transparent, KEIN neuer Signier-Code nötig)
//   4. POST {k1, event, device_name} an /api/mobile/token -> {token, user}
//   -> siehe loginWithNostr(). KEIN Vorab-Request, KEINE Redirect-URI,
//      KEINE Allowlist, KEINE Portal-Koordination nötig (das Portal merkt
//      sich nichts; verifyEvent prüft k1 nur gegen das signierte Event).
//
// Alternativ kann der Token auch manuell über setManualToken() gesetzt
// werden (z.B. ein im Portal erzeugter persönlicher Token).
// ============================================

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_logger.dart';
import 'signing_service.dart';

const String _tag = 'PortalAPI';

/// Ein vom Nutzer erstelltes/verwaltetes Meetup (aus /my-meetups).
class PortalMeetup {
  final int id;
  final String name;
  final String slug;
  final bool isLeader;

  PortalMeetup({required this.id, required this.name, required this.slug, this.isLeader = false});

  static PortalMeetup? fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    if (id is! int) return null;
    return PortalMeetup(
      id: id,
      name: (j['name'] ?? '').toString(),
      slug: (j['slug'] ?? '').toString(),
      isLeader: j['is_leader'] == true,
    );
  }
}

/// Ein Meetup-Termin (aus /meetup-events bzw. als Ergebnis von Anlegen/Update).
class PortalMeetupEvent {
  final int? id;
  final int meetupId;
  final String start;        // ISO 8601 (RFC 3339)
  final String? location;
  final String? description;
  final String? link;

  PortalMeetupEvent({
    this.id,
    required this.meetupId,
    required this.start,
    this.location,
    this.description,
    this.link,
  });

  static PortalMeetupEvent? fromJson(Map<String, dynamic> j) {
    final start = j['start'];
    if (start == null) return null;
    final mId = j['meetup_id'];
    return PortalMeetupEvent(
      id: j['id'] as int?,
      meetupId: mId is int ? mId : 0,
      start: start.toString(),
      location: j['location'] as String?,
      description: j['description'] as String?,
      link: j['link'] as String?,
    );
  }
}

/// Ergebnis eines schreibenden Aufrufs (anlegen/aktualisieren).
class PortalResult {
  final bool ok;
  final int statusCode;
  final String? error;       // menschenlesbare Fehlermeldung (falls !ok)
  final dynamic data;        // Antwort-JSON bei Erfolg

  PortalResult({required this.ok, required this.statusCode, this.error, this.data});
}

class PortalApiService {
  static const String baseUrl = 'https://portal.einundzwanzig.space';
  static const String _apiBase = '$baseUrl/api';
  static const String _tokenKey = 'portal_api_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static const Duration _timeout = Duration(seconds: 15);

  // ---------------------------------------------------------------
  // TOKEN-VERWALTUNG
  // ---------------------------------------------------------------

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasToken() async => (await getToken()) != null;

  static Future<void> storeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Manuelles Setzen eines Tokens (z.B. ein im Portal erzeugter persönlicher
  /// Token) — nützlich, solange der Deep-Link-Login noch nicht steht.
  static Future<void> setManualToken(String token) => storeToken(token.trim());

  /// STATELESS NOSTR-LOGIN (NIP-42-artig, kind 22242).
  ///
  /// Der elegante Weg: Das Portal vergibt KEIN k1 und merkt sich nichts.
  /// Die App würfelt das k1 selbst, baut ein kind-22242-Event mit dem Tag
  /// ["challenge", k1], lässt es über den bestehenden SigningService
  /// signieren (lokaler nsec ODER Amber — beides transparent) und schickt
  /// {k1, event, device_name} an POST /api/mobile/token. Das Portal prüft
  /// nur, dass Event und k1 zusammenpassen und das Event frisch ist
  /// (< 300 s), und gibt {token, user} zurück.
  ///
  /// KEIN Vorab-Request, KEINE Redirect-URI-Registrierung, KEINE Allowlist.
  ///
  /// Gibt PortalResult zurück: ok=true + data=user bei Erfolg.
  static Future<PortalResult> loginWithNostr({String deviceName = 'Einundzwanzig Meetup App'}) async {
    try {
      // 1. k1 = 32 zufällige Bytes als Hex (lokal, selbstgewählt)
      final random = Random.secure();
      final k1 = List.generate(32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

      // 2. + 3. kind-22242 mit ["challenge", k1] bauen und signieren lassen.
      //    SigningService kümmert sich transparent um lokal-nsec ODER Amber.
      final signed = await SigningService.signEvent(
        kind: 22242,
        tags: [['challenge', k1]],
        content: '',
      );

      // 4. Einziger Portal-Call: Event gegen Token tauschen.
      final r = await http.post(
        Uri.parse('$_apiBase/mobile/token'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'k1': k1,
          'event': signed.toJson(),
          'device_name': deviceName,
        }),
      ).timeout(_timeout);

      if (r.statusCode != 200 && r.statusCode != 201) {
        return PortalResult(ok: false, statusCode: r.statusCode, error: _errorFrom(r));
      }

      final body = jsonDecode(r.body);
      final token = (body is Map) ? body['token'] : null;
      if (token is! String || token.isEmpty) {
        return PortalResult(ok: false, statusCode: r.statusCode, error: 'Kein Token vom Portal erhalten.');
      }

      await storeToken(token);
      return PortalResult(ok: true, statusCode: r.statusCode, data: (body as Map)['user']);
    } catch (e) {
      AppLogger.debug(_tag, 'loginWithNostr Fehler: $e');
      return PortalResult(ok: false, statusCode: 0, error: 'Anmeldung fehlgeschlagen: $e');
    }
  }

  static Future<void> deleteToken() async {
    try { await _storage.delete(key: _tokenKey); } catch (_) {}
  }

  /// Logout: Token serverseitig widerrufen (best effort) und lokal löschen.
  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http.delete(
          Uri.parse('$_apiBase/mobile/token'),
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        ).timeout(_timeout);
      } catch (_) {/* Token läuft serverseitig ohnehin ab */}
    }
    await deleteToken();
  }

  // ---------------------------------------------------------------
  // GEMEINSAME HELFER
  // ---------------------------------------------------------------

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Extrahiert eine sinnvolle Fehlermeldung aus einer Fehler-Antwort.
  static String _errorFrom(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      if (body is Map) {
        if (body['message'] is String && (body['message'] as String).isNotEmpty) {
          return body['message'] as String;
        }
        if (body['errors'] is Map) {
          final first = (body['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
      }
    } catch (_) {}
    // Standard-Mappings analog zur Portal-Doku
    switch (r.statusCode) {
      case 401: return 'Nicht authentifiziert. Bitte erneut anmelden.';
      case 403: return 'Keine Berechtigung (nur Ersteller oder Admin).';
      case 404: return 'Nicht gefunden.';
      case 422: return 'Validierungsfehler. Bitte Eingaben prüfen.';
      default:  return 'Fehler (HTTP ${r.statusCode}).';
    }
  }

  // ---------------------------------------------------------------
  // LESEN
  // ---------------------------------------------------------------

  /// Profil des Token-Inhabers (GET /user). null bei fehlendem/ungültigem Token.
  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      final r = await http.get(Uri.parse('$_apiBase/user'), headers: await _authHeaders()).timeout(_timeout);
      if (r.statusCode == 401) { await deleteToken(); return null; }
      if (r.statusCode != 200) return null;
      final body = jsonDecode(r.body);
      return body is Map<String, dynamic> ? body : null;
    } catch (e) {
      AppLogger.debug(_tag, 'getProfile Fehler: $e');
      return null;
    }
  }

  /// Vom Nutzer erstellte Meetups (GET /my-meetups). Braucht Token.
  static Future<List<PortalMeetup>> getMyMeetups() async {
    try {
      final r = await http.get(Uri.parse('$_apiBase/my-meetups'), headers: await _authHeaders()).timeout(_timeout);
      if (r.statusCode != 200) return [];
      final body = jsonDecode(r.body);
      final list = (body is Map && body['data'] is List) ? body['data'] as List : const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(PortalMeetup.fromJson)
          .whereType<PortalMeetup>()
          .toList();
    } catch (e) {
      AppLogger.debug(_tag, 'getMyMeetups Fehler: $e');
      return [];
    }
  }

  /// Eigene Meetup-Termine (GET /my-meetup-events). Braucht Token.
  static Future<List<PortalMeetupEvent>> getMyMeetupEvents() async {
    try {
      final r = await http.get(Uri.parse('$_apiBase/my-meetup-events'), headers: await _authHeaders()).timeout(_timeout);
      if (r.statusCode != 200) return [];
      final body = jsonDecode(r.body);
      final list = (body is Map && body['data'] is List) ? body['data'] as List : const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(PortalMeetupEvent.fromJson)
          .whereType<PortalMeetupEvent>()
          .toList();
    } catch (e) {
      AppLogger.debug(_tag, 'getMyMeetupEvents Fehler: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------
  // SCHREIBEN
  // ---------------------------------------------------------------

  /// Legt einen Meetup-Termin an (POST /meetup-events). Braucht Token.
  /// [start] und [recurrenceEndDate] im RFC-3339-Format (z.B. 2026-07-21T17:32:28Z).
  /// Werden recurrenceType UND recurrenceEndDate gesetzt, erzeugt das Portal
  /// eine Terminserie (max. 100), sonst einen Einzeltermin.
  static Future<PortalResult> createMeetupEvent({
    required int meetupId,
    required String start,
    String? location,
    String? description,
    String? link,
    String? recurrenceType,       // daily|weekly|monthly|yearly|custom
    String? recurrenceDayOfWeek,
    String? recurrenceDayPosition,
    int? recurrenceInterval,
    String? recurrenceEndDate,
  }) async {
    final payload = <String, dynamic>{
      'meetup_id': meetupId,
      'start': start,
      'location': location,
      'description': description,
      'link': link,
      'recurrence_type': recurrenceType,
      'recurrence_day_of_week': recurrenceDayOfWeek,
      'recurrence_day_position': recurrenceDayPosition,
      'recurrence_interval': recurrenceInterval,
      'recurrence_end_date': recurrenceEndDate,
    };
    return _write('POST', '$_apiBase/meetup-events', payload);
  }

  /// Aktualisiert einen Meetup-Termin (PATCH /meetup-events/{id}).
  /// Nur der Ersteller oder ein Super-Admin darf das. Nur gesetzte Felder
  /// werden übergeben.
  static Future<PortalResult> updateMeetupEvent({
    required int eventId,
    int? meetupId,
    String? start,
    String? location,
    String? description,
    String? link,
    String? recurrenceType,
    String? recurrenceDayOfWeek,
    String? recurrenceDayPosition,
    int? recurrenceInterval,
    String? recurrenceEndDate,
  }) async {
    final payload = <String, dynamic>{
      if (meetupId != null) 'meetup_id': meetupId,
      if (start != null) 'start': start,
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      if (link != null) 'link': link,
      if (recurrenceType != null) 'recurrence_type': recurrenceType,
      if (recurrenceDayOfWeek != null) 'recurrence_day_of_week': recurrenceDayOfWeek,
      if (recurrenceDayPosition != null) 'recurrence_day_position': recurrenceDayPosition,
      if (recurrenceInterval != null) 'recurrence_interval': recurrenceInterval,
      if (recurrenceEndDate != null) 'recurrence_end_date': recurrenceEndDate,
    };
    return _write('PATCH', '$_apiBase/meetup-events/$eventId', payload);
  }

  /// Gemeinsamer schreibender Aufruf mit einheitlicher Fehlerbehandlung.
  static Future<PortalResult> _write(String method, String url, Map<String, dynamic> payload) async {
    final token = await getToken();
    if (token == null) {
      return PortalResult(ok: false, statusCode: 401, error: 'Nicht angemeldet. Bitte zuerst mit dem Portal verbinden.');
    }
    try {
      final headers = await _authHeaders();
      final body = jsonEncode(payload);
      final uri = Uri.parse(url);
      final http.Response r;
      switch (method) {
        case 'POST':
          r = await http.post(uri, headers: headers, body: body).timeout(_timeout);
          break;
        case 'PATCH':
          r = await http.patch(uri, headers: headers, body: body).timeout(_timeout);
          break;
        default:
          return PortalResult(ok: false, statusCode: 0, error: 'Unbekannte Methode.');
      }
      if (r.statusCode == 200 || r.statusCode == 201) {
        dynamic data;
        try { data = jsonDecode(r.body); } catch (_) {}
        return PortalResult(ok: true, statusCode: r.statusCode, data: data);
      }
      if (r.statusCode == 401) await deleteToken();
      return PortalResult(ok: false, statusCode: r.statusCode, error: _errorFrom(r));
    } catch (e) {
      AppLogger.debug(_tag, '$method $url Fehler: $e');
      return PortalResult(ok: false, statusCode: 0, error: 'Netzwerkfehler. Bist du online?');
    }
  }
}
