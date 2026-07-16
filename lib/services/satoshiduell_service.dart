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

  /// Öffentlicher Client-Key (Supabase "publishable key", neues Format).
  /// Exakt der Key, den die WebApp selbst nutzt (satoshiduell-v2/.env) —
  /// per Design öffentlich und durch Row-Level-Security begrenzt.
  /// HINWEIS: Der ältere JWT-anon-Key des Projekts lieferte HTTP 401 —
  /// das Projekt läuft auf dem neuen Supabase-Key-System.
  static const String _anonKey =
      'sb_publishable_RESZrjWqb-l_AIiqZcE7-g_JenFWO_d';

  static const Duration _timeout = Duration(seconds: 8);

  static Map<String, String> get _headers => {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Accept': 'application/json',
      };

  // RAM-Cache: das Badge muss nicht bei jedem Hub-Aufbau neu laden.
  static DuellStatus? _cachedStatus;
  static DateTime? _cachedAt;
  static const Duration _ttl = Duration(minutes: 2);

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

  /// Voller Duell-Status für die Kachel. Kategorisierung 1:1 aus der
  /// ActiveGamesView der WebApp übernommen:
  ///  - myTurn:  status open/active, MEIN Score ist noch null
  ///             (Ausnahme: eigenes offenes Duell ohne Gegner = warten)
  ///  - waiting: status open/active, mein Score gesetzt -> Gegner ist dran
  ///  - lobby:   fremde offene Duelle, die ich annehmen könnte
  ///
  /// Bewusste Vereinfachung: Arena-Spiele, in denen man nur über die
  /// participants-Liste hängt (weder creator noch challenger/target), werden
  /// nicht als "dran/warten" erkannt — dafür bräuchte es den zweiten
  /// Arena-Scan der WebApp. Für ein Kachel-Badge ist das die richtige
  /// Abwägung; die WebApp selbst zeigt dann alles exakt.
  static Future<DuellStatus> fetchStatus({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedStatus != null && _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _ttl) {
      return _cachedStatus!;
    }

    try {
      final npub = await SigningService.npub();
      if (npub == null || npub.isEmpty) return DuellStatus.empty;

      final username = await _usernameFor(npub);
      if (username == null) return DuellStatus.empty; // dort kein Konto

      final me = username.toLowerCase();
      // PostgREST-or(): Kommas/Klammern im Wert wuerden die Filter-Syntax
      // sprengen -> Wert in doppelte Anfuehrungszeichen setzen. NUR fuer
      // or() verwenden — in Einzelfiltern (eq./neq.) wirken die Quotes
      // NICHT als Quoting und verfaelschen den Vergleich!
      final safeName = me.replaceAll('"', '');
      final quoted = '"' + safeName + '"';
      final meEnc = Uri.encodeQueryComponent(quoted);

      // Call 1: MEINE Duelle (wie fetchUserGames der WebApp, ohne Arena-Scan).
      final mine = await http.get(
        Uri.parse('$_base/duels?select=status,creator,challenger,target_player,'
            'creator_score,challenger_score'
            '&or=(creator.eq.$meEnc,challenger.eq.$meEnc,target_player.eq.$meEnc)'
            '&order=created_at.desc&limit=50'),
        headers: _headers,
      ).timeout(_timeout);

      var myTurn = 0, waiting = 0;
      if (mine.statusCode == 200) {
        final list = jsonDecode(mine.body);
        if (list is List) {
          for (final g in list.whereType<Map>()) {
            final st = (g['status'] ?? '').toString();
            if (st != 'open' && st != 'active') continue; // finished etc.
            final isCreator = (g['creator'] ?? '').toString().toLowerCase() == me;
            final myScore = isCreator ? g['creator_score'] : g['challenger_score'];
            if (myScore == null) {
              // Eigenes offenes Duell ohne Gegner: ich warte, bin nicht dran.
              if (st == 'open' && isCreator) {
                waiting++;
              } else {
                myTurn++;
              }
            } else {
              waiting++;
            }
          }
        }
      } else {
        AppLogger.diag(_tag, 'meine-Duelle-Abfrage: HTTP ${mine.statusCode}');
      }

      // Call 2: Lobby — fremde offene Duelle, die ich annehmen könnte.
      // WICHTIG (Fix): Serverseitig wird nur noch status=open gefiltert,
      // creator/target werden CLIENTSEITIG geprüft. Grund: Das PostgREST-
      // Quoting verhält sich in Einzelfiltern anders als in or() — ein
      // gequoteter Wert in creator=neq. wurde wörtlich verglichen, wodurch
      // das EIGENE offene Spiel faelschlich in der Lobby mitzaehlte.
      // Clientseitige Filterung umgeht diese Syntax-Fallenklasse komplett;
      // offene Lobbies sind klein, limit=100 ist mehr als genug.
      var lobby = 0;
      final open = await http.get(
        Uri.parse('$_base/duels?select=creator,target_player&status=eq.open&limit=100'),
        headers: _headers,
      ).timeout(_timeout);
      if (open.statusCode == 200) {
        final list = jsonDecode(open.body);
        if (list is List) {
          for (final g in list.whereType<Map>()) {
            final creator = (g['creator'] ?? '').toString().toLowerCase();
            final target = g['target_player']?.toString().toLowerCase();
            if (creator == me) continue; // eigenes Spiel ist keine Lobby
            if (target == null || target.isEmpty || target == me) lobby++;
          }
        }
      } else {
        AppLogger.diag(_tag, 'Lobby-Abfrage: HTTP ${open.statusCode}');
      }

      final status = DuellStatus(myTurn: myTurn, waiting: waiting, lobby: lobby);
      AppLogger.diag(_tag,
          'Status für "$me": dran=$myTurn · wartet=$waiting · Lobby=$lobby');
      _cachedStatus = status;
      _cachedAt = DateTime.now();
      return status;
    } catch (e) {
      AppLogger.diag(_tag, 'fetchStatus fehlgeschlagen: ${e.runtimeType}');
      return _cachedStatus ?? DuellStatus.empty;
    }
  }

  /// Kompatibilität: Zahl der Duelle, die eine AKTION von mir erlauben
  /// (dran + Lobby) — das ist die Badge-Zahl.
  static Future<int> openDuelCount({bool forceRefresh = false}) async {
    final s = await fetchStatus(forceRefresh: forceRefresh);
    return s.myTurn + s.lobby;
  }
}

/// Zustand meiner SatoshiDuell-Welt, kompakt fürs Kachel-Badge.
class DuellStatus {
  final int myTurn;  // Spiele, in denen ICH ziehen muss (inkl. Challenges an mich)
  final int waiting; // Spiele, in denen der Gegner dran ist
  final int lobby;   // fremde offene Spiele, die ich annehmen könnte

  const DuellStatus({required this.myTurn, required this.waiting, required this.lobby});
  static const empty = DuellStatus(myTurn: 0, waiting: 0, lobby: 0);

  bool get hasAny => myTurn > 0 || waiting > 0 || lobby > 0;
}
