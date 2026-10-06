// ============================================
// NOSTR PROFILE SERVICE
// Lädt Profilbild (picture) aus kind:0 Metadata
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';
import 'relay_config.dart';
import 'relay_socket.dart';
import 'nostr_profile_lookup.dart';

class NostrProfileService {
  static const Duration _timeout = Duration(seconds: 6);
  static const String _localPicKey = 'local_profile_picture';
  static final _pictureLookup = NostrProfileLookup();

  /// Öffentliche Metadaten abrufen, unabhängig vom aktiven Signiermodus.
  static Future<String?> fetchProfilePicture(String pubkeyHex) =>
      _pictureLookup.fetchPicture(pubkeyHex);

  /// Anzeigename zu einem Pubkey, null wenn keiner hinterlegt ist.
  ///
  /// Eigener Zwischenspeicher und eigene Abfrage neben dem Profilbild: Die
  /// Namen haben eigene Cache- und Batch-Abfragen; die Profilsuche fuer
  /// Avatare entdeckt zusaetzlich die Write-Relays des Autors.
  static final Map<String, String?> _nameCache = {};

  static Future<String?> fetchDisplayName(String pubkeyHex) async {
    if (pubkeyHex.isEmpty) return null;
    if (_nameCache.containsKey(pubkeyHex)) return _nameCache[pubkeyHex];

    String? found;
    try {
      final relays = await RelayConfig.getActiveRelays();

      // 1. Das Nostr-Profil (kind 0) — der uebliche Ort fuer einen Namen.
      for (final r in relays) {
        found = await _fetchNameFromRelay(r, pubkeyHex);
        if (found != null && found.isNotEmpty) break;
      }

      // 2. Der Spitzname aus dem Reputations-Ereignis.
      //
      // Die App veroeffentlicht KEIN Nostr-Profil. Wer sich in der App einen
      // Namen gibt, hat ihn nur hier stehen — unter identity.nickname. Ohne
      // diesen zweiten Weg blieben ausgerechnet die Leute namenlos, die ihre
      // Identitaet in der App angelegt haben: also fast alle. Im
      // Vertrauensnetzwerk standen deshalb nur npubs.
      if (found == null || found.isEmpty) {
        for (final r in relays) {
          found = await _fetchNicknameFromRelay(r, pubkeyHex);
          if (found != null && found.isNotEmpty) break;
        }
      }
    } catch (_) {
      // Ohne Namen bleibt der gekuerzte npub — kein Grund zu scheitern.
    }
    _nameCache[pubkeyHex] = found;
    return found;
  }

  // ============================================
  // NAMEN FUER VIELE PERSONEN AUF EINMAL
  // ============================================
  //
  // Das Vertrauensnetzwerk zeigt schnell hundert Personen und mehr. Einzeln
  // abgefragt waeren das hundert Mal "Relay fuer Relay nacheinander" — viele
  // Sekunden, hunderte Verbindungen. Hier geht es paketweise: eine Abfrage je
  // Relay fuer bis zu hundert Personen, alle Relays gleichzeitig.
  //
  // Gefundene Namen bleiben gespeichert, damit sie beim naechsten Oeffnen
  // SOFORT dastehen. Nach einem Tag werden sie im Hintergrund erneuert —
  // Leute benennen sich um.

  static const String _namesKey = 'nostr_display_names_v1';
  static const Duration _namesMaxAge = Duration(days: 1);
  static const int _namesBatch = 100;

  /// Gespeicherte Namen (hex → Name), ohne Relay-Abfrage.
  static Future<Map<String, String>> cachedDisplayNames() async {
    final out = <String, String>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_namesKey);
      if (raw == null) return out;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      m.forEach((hex, v) {
        if (v is Map && v['n'] is String) out[hex] = v['n'] as String;
      });
    } catch (_) {}
    // Auch der Einzelabruf (NpubChip) soll davon profitieren.
    out.forEach((hex, name) => _nameCache.putIfAbsent(hex, () => name));
    return out;
  }

  /// Namen fuer viele Personen. Liefert hex → Name fuer alle, die einen
  /// haben; wer keinen hat, fehlt in der Antwort.
  static Future<Map<String, String>> fetchDisplayNames(
      Iterable<String> pubkeysHex) async {
    final wanted = pubkeysHex.where((h) => h.isNotEmpty).toSet();
    final result = <String, String>{};
    if (wanted.isEmpty) return result;

    final prefs = await SharedPreferences.getInstance();
    final stored = <String, Map<String, dynamic>>{};
    try {
      final raw = prefs.getString(_namesKey);
      if (raw != null) {
        (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
          if (v is Map<String, dynamic>) stored[k] = v;
        });
      }
    } catch (_) {}

    final now = DateTime.now().millisecondsSinceEpoch;
    final missing = <String>[];
    for (final hex in wanted) {
      final s = stored[hex];
      final name = s?['n'];
      final at = s?['t'];
      if (name is String && name.isNotEmpty) {
        result[hex] = name;
        _nameCache.putIfAbsent(hex, () => name);
        // Frisch genug: nicht noch einmal fragen.
        if (at is int && now - at < _namesMaxAge.inMilliseconds) continue;
      } else if (_nameCache.containsKey(hex)) {
        // In dieser Sitzung schon ohne Ergebnis gefragt.
        final known = _nameCache[hex];
        if (known != null && known.isNotEmpty) result[hex] = known;
        continue;
      }
      missing.add(hex);
    }
    if (missing.isEmpty) return result;

    List<String> relays;
    try {
      relays = await RelayConfig.getActiveRelays();
    } catch (_) {
      relays = const [];
    }
    if (relays.isEmpty) return result;

    // 1. Nostr-Profile (kind 0), danach 2. Spitznamen aus dem
    //    Reputations-Ereignis fuer alle, die noch keinen Namen haben —
    //    die App selbst veroeffentlicht kein kind 0 (siehe fetchDisplayName).
    final fresh = <String, String>{};
    for (var k = 0; k < missing.length; k += _namesBatch) {
      final part = missing.sublist(k, min(k + _namesBatch, missing.length));
      final answers = await Future.wait(relays.map((r) => _batchNames(r, part,
          kinds: const [0], dTag: null, parse: _nameFromProfile)));
      _mergeNewest(answers, fresh);
    }
    final noName = missing.where((h) => !fresh.containsKey(h)).toList();
    for (var k = 0; k < noName.length; k += _namesBatch) {
      final part = noName.sublist(k, min(k + _namesBatch, noName.length));
      final answers = await Future.wait(relays.map((r) => _batchNames(r, part,
          kinds: const [30078],
          dTag: 'einundzwanzig-reputation',
          parse: _nameFromReputation)));
      _mergeNewest(answers, fresh);
    }

    for (final hex in missing) {
      final name = fresh[hex];
      if (name != null) {
        result[hex] = name;
        _nameCache[hex] = name;
        stored[hex] = {'n': name, 't': now};
      } else {
        // Kein Name gefunden. Ein frueher gespeicherter bleibt stehen —
        // ein Relay, das gerade nicht antwortet, loescht keinen Namen.
        _nameCache.putIfAbsent(hex, () => null);
      }
    }
    try {
      await prefs.setString(_namesKey, jsonEncode(stored));
    } catch (_) {}
    AppLogger.diag('NostrProfile',
        'Namen: ${missing.length} abgefragt, ${fresh.length} gefunden.');
    return result;
  }

  /// Fuehrt die Antworten mehrerer Relays zusammen — je Person gilt das
  /// NEUESTE Ereignis, nicht das zuerst eingetroffene.
  static void _mergeNewest(
      List<Map<String, MapEntry<int, String>>> answers, Map<String, String> into) {
    final best = <String, MapEntry<int, String>>{};
    for (final a in answers) {
      a.forEach((hex, e) {
        final cur = best[hex];
        if (cur == null || e.key > cur.key) best[hex] = e;
      });
    }
    best.forEach((hex, e) => into.putIfAbsent(hex, () => e.value));
  }

  static String? _nameFromProfile(String content) {
    final profile = jsonDecode(content) as Map<String, dynamic>;
    final n = (profile['display_name'] as String?)?.trim();
    final alt = (profile['name'] as String?)?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (alt != null && alt.isNotEmpty) return alt;
    return null;
  }

  static String? _nameFromReputation(String content) {
    final body = jsonDecode(content) as Map<String, dynamic>;
    final identity = body['identity'];
    final nick =
        identity is Map ? (identity['nickname'] as String?)?.trim() : null;
    if (nick == null || nick.isEmpty || nick.toLowerCase() == 'anon') {
      return null;
    }
    return nick;
  }

  /// Eine Paket-Abfrage an EIN Relay. Ergebnis: hex → (created_at, Name).
  static Future<Map<String, MapEntry<int, String>>> _batchNames(
    String relayUrl,
    List<String> authors, {
    required List<int> kinds,
    required String? dTag,
    required String? Function(String content) parse,
  }) async {
    final out = <String, MapEntry<int, String>>{};
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final done = Completer<void>();
      final random = Random.secure();
      final subId =
          'names-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
      ws.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as List<dynamic>;
            if (msg[0] == 'EVENT' && msg.length >= 3) {
              final ev = msg[2] as Map<String, dynamic>;
              final hex = ev['pubkey'] as String? ?? '';
              final at = ev['created_at'] is int ? ev['created_at'] as int : 0;
              final name = parse(ev['content'] as String? ?? '');
              if (hex.isEmpty || name == null) return;
              final cur = out[hex];
              if (cur == null || at > cur.key) out[hex] = MapEntry(at, name);
            } else if (msg[0] == 'EOSE') {
              if (!done.isCompleted) done.complete();
            }
          } catch (_) {}
        },
        onError: (_) { if (!done.isCompleted) done.complete(); },
        onDone: () { if (!done.isCompleted) done.complete(); },
      );
      final filter = <String, dynamic>{
        'kinds': kinds,
        'authors': authors,
        'limit': authors.length * 2,
      };
      if (dTag != null) filter['#d'] = [dTag];
      ws.add(jsonEncode(['REQ', subId, filter]));
      await done.future.timeout(_timeout, onTimeout: () {});
    } catch (_) {
      // Ein Relay ohne Antwort ist kein Fehler — die anderen reichen.
    } finally {
      ws?.close();
    }
    return out;
  }

  /// Spitzname aus dem Reputations-Ereignis (kind 30078).
  ///
  /// "Anon" ist der Platzhalter fuer "kein Name gesetzt" und wird wie ein
  /// fehlender Name behandelt — sonst hiesse im Netzwerk die Haelfte "Anon".
  static Future<String?> _fetchNicknameFromRelay(
      String relayUrl, String pubkeyHex) async {
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final completer = Completer<String?>();
      final random = Random.secure();
      final subId =
          'nick-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            if (message[0] == 'EVENT' && message.length >= 3) {
              final content =
                  (message[2] as Map<String, dynamic>)['content'] as String? ?? '';
              final body = jsonDecode(content) as Map<String, dynamic>;
              final identity = body['identity'];
              final nick = identity is Map
                  ? (identity['nickname'] as String?)?.trim()
                  : null;
              final usable = (nick != null &&
                      nick.isNotEmpty &&
                      nick.toLowerCase() != 'anon')
                  ? nick
                  : null;
              if (!completer.isCompleted) completer.complete(usable);
            } else if (message[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete(null);
            }
          } catch (_) {}
        },
        onError: (_) { if (!completer.isCompleted) completer.complete(null); },
        onDone: () { if (!completer.isCompleted) completer.complete(null); },
      );

      ws.add(jsonEncode(['REQ', subId, {
        'kinds': [30078],
        'authors': [pubkeyHex],
        '#d': ['einundzwanzig-reputation'],
        'limit': 1,
      }]));
      return await completer.future.timeout(_timeout, onTimeout: () => null);
    } catch (_) {
      return null;
    } finally {
      ws?.close();
    }
  }

  static Future<String?> _fetchNameFromRelay(
      String relayUrl, String pubkeyHex) async {
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final completer = Completer<String?>();
      final random = Random.secure();
      final subId =
          'nam-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            if (message[0] == 'EVENT' && message.length >= 3) {
              final content =
                  (message[2] as Map<String, dynamic>)['content'] as String? ??
                      '';
              final profile = jsonDecode(content) as Map<String, dynamic>;
              // display_name hat Vorrang — das ist der Name, den Leute fuer
              // die Anzeige waehlen; name ist oft der technische Kurzname.
              final n = (profile['display_name'] as String?)?.trim();
              final alt = (profile['name'] as String?)?.trim();
              if (!completer.isCompleted) {
                completer.complete(
                    (n != null && n.isNotEmpty) ? n : (alt ?? ''));
              }
            } else if (message[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete(null);
            }
          } catch (_) {}
        },
        onError: (_) { if (!completer.isCompleted) completer.complete(null); },
        onDone: () { if (!completer.isCompleted) completer.complete(null); },
      );

      ws.add(jsonEncode(['REQ', subId, {'kinds': [0], 'authors': [pubkeyHex], 'limit': 1}]));
      return await completer.future.timeout(_timeout, onTimeout: () => null);
    } catch (_) {
      return null;
    } finally {
      ws?.close();
    }
  }

  /// Lokales Profilbild speichern (wenn kein Nostr-Bild vorhanden)
  static Future<void> setLocalPicture(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localPicKey, path);
  }

  /// Lokales Profilbild laden
  static Future<String?> getLocalPicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localPicKey);
  }

  /// Cache löschen (z.B. bei App-Reset)
  static Future<void> clearCache() async {
    _pictureLookup.invalidate();
    final prefs = await SharedPreferences.getInstance();
    // pubkey-spezifische Einträge (und evtl. alte globale) entfernen
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('nostr_profile_picture') ||
          key.startsWith('nostr_profile_metadata_v2_') ||
          key.startsWith('nostr_profile_relays_v2_')) {
        await prefs.remove(key);
      }
    }
    await prefs.remove(_localPicKey);
  }
}

