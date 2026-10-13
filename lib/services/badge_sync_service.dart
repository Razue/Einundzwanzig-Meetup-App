// Badge-Sync über Nostr: verschlüsselte Chunks in kind-30078-Events,
// NIP-44 an den eigenen Pubkey. Plan: docs/PLAN_BADGE_SYNC.md.
//
// Ablauf:
//   pull: Ist die lokale Datei lesbar und nicht leer, gilt sie.
//         Ist sie leer, kommen die Relays und werden lokal gespeichert.
//         Ist sie nicht lesbar, bleiben die Bytes liegen; eine ferne
//         Kopie wird nur daneben geschrieben.
//   push: erst pull, dann aus dem Ergebnis Chunks bauen und nur die
//         veröffentlichen, deren Inhalt sich geändert hat, und nur auf
//         Relays zählen, die das Event bestätigen.
//
// Drei Regeln aus dem Plan, die hier stehen und nicht im Aufrufer:
//   - nie eine leere Liste veröffentlichen (Reset-Pfad)
//   - ein Gerät ohne lokale Badges liest erst, bevor es je schreibt
//   - eine nicht lesbare Datei ist keine leere Liste: nichts überschreiben,
//     nichts leeres veröffentlichen, ferne Badges nur zusätzlich sichern

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/badge.dart';
import 'app_logger.dart';
import 'badge_sync_codec.dart';
import 'badge_sync_format.dart';
import 'relay_socket.dart';
import 'signing_service.dart';

class BadgeSyncService {
  BadgeSyncService._();

  static const _tag = 'BadgeSync';

  /// Eigene Liste, nicht die der App-Relays. Aus der Relay-Sonde:
  /// nos.lol trägt von den App-Relays als einziges zuverlässig.
  static const List<String> syncRelays = [
    'wss://nos.lol',
    'wss://relay.primal.net',
    'wss://nostr.mom',
    'wss://relay.snort.social',
  ];

  static const _dirtyKey = 'badge_sync_dirty';
  static const _hashesKey = 'badge_sync_chunk_hashes';
  static const _lastGenKey = 'badge_sync_last_gen';
  static const _timeout = Duration(seconds: 8);

  static bool _busy = false;

  // Merkt, dass während eines laufenden Syncs ein weiteres saveBadges kam.
  // Der laufende Lauf arbeitet mit einem alten Stand; danach läuft einer
  // nach, statt dirty zu löschen und den neuen Zustand zu verlieren.
  static bool _rerun = false;

  /// Einmal beim Start aufrufen: verknüpft saveBadges mit dem Sync und
  /// holt einmal fern, damit ein zweites Gerät ohne Scan schon sieht,
  /// was das andere hat. "Ein Gerät ohne lokale Badges liest erst."
  static void init() {
    MeetupBadge.onBadgesSaved = trigger;
    // Der Startlauf liegt oft vor der Anmeldung. Sobald Amber, Bunker oder
    // ein lokaler Schlüssel benutzbar ist, noch einmal lesen.
    SigningService.onSignerReady = trigger;
    trigger();
  }

  /// Nach `saveBadges` aufrufen. Im Hintergrund, wirft nicht.
  static void trigger() {
    unawaited(() async {
      final prefs = await SharedPreferences.getInstance();
      try {
        final ok = await syncNow();
        if (!ok) {
          await prefs.setBool(_dirtyKey, true);
        }
      } catch (e) {
        await prefs.setBool(_dirtyKey, true);
        AppLogger.debug(_tag, 'Sync fehlgeschlagen: $e');
      }
    }());
  }

  /// Beim Start: war der letzte Sync unvollständig, nochmal versuchen.
  static Future<void> retryIfDirty() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dirtyKey) != true) return;
    try {
      await syncNow();
    } catch (e) {
      AppLogger.debug(_tag, 'Sync-Retry fehlgeschlagen: $e');
    }
  }

  /// Einmal hoch- und wieder herunter. Gibt false, wenn der Signer kein
  /// NIP-44 kann oder gerade ein Lauf aktiv ist.
  static Future<bool> syncNow() async {
    if (_busy) {
      // Ein saveBadges während eines Laufs: der aktuelle Lauf arbeitet mit
      // einem alten Stand. Danach einer nachholen, nicht dirty setzen.
      _rerun = true;
      return true;
    }
    _busy = true;
    try {
      do {
        _rerun = false;
        if (!await _syncOnce()) return false;
      } while (_rerun);
      return true;
    } finally {
      _busy = false;
    }
  }

  static Future<bool> _syncOnce() async {
    final me = await SigningService.pubkeyHex();
    if (me == null || me.isEmpty) return false;

    // Der Signer darf NIP-44 nicht können. Dann bleibt der Sync aus,
    // statt dem Nutzer einen Fehler zu zeigen — das Backup ist der Weg.
    try {
      if (!await SigningService.canNip44()) {
        AppLogger.debug(_tag, 'Signer kann kein NIP-44 — Sync bleibt aus');
        return false;
      }
    } on UnsupportedError {
      AppLogger.debug(_tag, 'Signer kann kein NIP-44 — Sync bleibt aus');
      return false;
    } on SigningException catch (e) {
      AppLogger.debug(_tag, 'NIP-44-Probe abgelehnt — Sync bleibt aus: $e');
      return false;
    }

    final merged = await _pull(me);
    // null: die lokale Datei ist nicht lesbar und die Relays haben keine
    // Kopie. Nicht als leeren Erfolg verbuchen.
    if (merged == null) return false;
    final pushed = await _push(me, merged);
    final prefs = await SharedPreferences.getInstance();
    // Dirty bleibt, wenn ein Chunk auf keinem Relay bestätigt wurde.
    await prefs.setBool(_dirtyKey, !pushed);
    return pushed;
  }

  /// Relays lesen, entschlüsseln und die ferne Liste mit der lokalen
  /// vereinigen. Ein leeres lokales Gerät ist dabei der Empfänger: es
  /// bekommt alles aus der Ferne. Ein Gerät mit lokalen Badges ist
  /// Autorität: was lokal fehlt, wird nicht wieder aus der Ferne geholt,
  /// sonst kämen nach der Duplikat-Bereinigung die fern liegenden
  /// Exemplare über den Merge sofort zurück.
  static Future<List<MeetupBadge>?> _pull(String me) async {
    final local = await MeetupBadge.loadBadges();
    if (MeetupBadge.badgesUnreadable) {
      final remote = await _fetchRemote(me);
      if (remote.isEmpty) {
        AppLogger.warn(_tag,
            'Lokale Badges nicht lesbar, auf den Relays liegt keine Kopie');
        return null;
      }
      // Die alte Datei bleibt als Sicherung. Die ferne Liste wird die
      // lesbare Fassung, vorgemerkte Scans kommen in saveBadges dazu.
      final wrote = await MeetupBadge.saveBadges(remote, replaceUnreadable: true);
      if (!wrote) return null;
      return MeetupBadge.loadBadges();
    }
    if (local.isEmpty) {
      final remote = await _fetchRemote(me);
      if (remote.isNotEmpty) {
        // Kam die ferne Kopie lokal nicht an, ist das kein Erfolg: Der Sync
        // bleibt dirty und versucht es wieder, statt die Sammlung als
        // wiederhergestellt zu verbuchen, obwohl lokal nichts liegt.
        if (!await MeetupBadge.saveBadges(remote)) return null;
      }
      return remote;
    }
    return local;
  }

  /// Lädt alle Chunks von den Relays, entschlüsselt, was geht, und
  /// vereinigt die Badges. Fehlende oder kaputte Chunks fallen weg.
  static Future<List<MeetupBadge>> _fetchRemote(String me) async {
    final events = await Future.wait(
      syncRelays.map((url) => _fetchFromRelay(url, me).catchError((Object e) {
            AppLogger.debug(_tag, 'Lesen von $url fehlgeschlagen: $e');
            return <int, Map<String, dynamic>>{};
          })),
    );

    // Pro d gewinnt das neueste Event über alle Relays.
    final byIndex = <int, Map<String, dynamic>>{};
    for (final fromRelay in events) {
      for (final entry in fromRelay.entries) {
        final existing = byIndex[entry.key];
        if (existing == null ||
            (entry.value['created_at'] as int? ?? 0) >
                (existing['created_at'] as int? ?? 0)) {
          byIndex[entry.key] = entry.value;
        }
      }
    }

    final badges = <MeetupBadge>[];
    var newestGen = 0;
    for (final event in byIndex.values) {
      final content = (event['content'] ?? '').toString();
      if (content.isEmpty) continue;
      try {
        final plain = await SigningService.nip44Decrypt(me, content);
        // Inhalt ist base64(gzip(Hülle)), nicht die Hülle selbst.
        final env = BadgeSyncFormat.parseEnvelope(
            BadgeSyncCodec.inflate(base64Decode(plain)));
        badges.addAll(env.badges);
        if (env.generation > newestGen) newestGen = env.generation;
      } catch (e) {
        AppLogger.debug(_tag, 'Chunk nicht lesbar: $e');
      }
    }
    if (newestGen > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastGenKey, newestGen);
    }
    return badges;
  }

  static Future<Map<int, Map<String, dynamic>>> _fetchFromRelay(
    String relayUrl,
    String me,
  ) async {
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final completer = Completer<Map<int, Map<String, dynamic>>>();
      final random = Random.secure();
      final subId =
          'badgesync-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
      final out = <int, Map<String, dynamic>>{};

      final filter = <String, dynamic>{
        'kinds': [BadgeSyncFormat.kind],
        'authors': [me],
        '#d': [
          for (var i = 0; i < BadgeSyncFormat.maxChunks; i++)
            BadgeSyncFormat.dTag(i),
        ],
      };

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            if (message[0] == 'EVENT' && message.length >= 3) {
              final event =
                  RelaySocket.verifiedEvent(message[2], tag: _tag);
              if (event == null ||
                  !RelaySocket.answersFilter(event, filter)) {
                return;
              }
              final created = RelaySocket.replaceableCreatedAt(event);
              if (created == null) return;
              final tags = event['tags'] as List<dynamic>? ?? const [];
              for (final tag in tags) {
                if (tag is List && tag.length >= 2 && tag[0] == 'd') {
                  final name = tag[1].toString();
                  if (name.startsWith('badges-')) {
                    final index = int.tryParse(name.substring(7));
                    if (index != null &&
                        index >= 0 &&
                        index < BadgeSyncFormat.maxChunks) {
                      final existing = out[index];
                      if (existing == null ||
                          created >
                              (existing['created_at'] as int? ?? 0)) {
                        out[index] = event;
                      }
                    }
                  }
                }
              }
            } else if (message[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete(out);
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(out);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(out);
        },
      );

      ws.add(jsonEncode(['REQ', subId, filter]));
      return await completer.future.timeout(_timeout, onTimeout: () => out);
    } finally {
      ws?.close();
    }
  }

  /// Baut aus [merged] Chunks, verschlüsselt und veröffentlicht nur die,
  /// deren Inhalt sich geändert hat. Zählt ein Relay erst, wenn es das
  /// Event bestätigt. Gibt false, wenn ein geänderter Chunk auf keinem
  /// Relay ankam — dann bleibt der Sync dirty.
  static Future<bool> _push(String me, List<MeetupBadge> merged) async {
    if (merged.isEmpty) return true;

    // Mehr Chunks als gelesen werden: lieber nichts schreiben, als
    // unleserliche Events auf den Relays zu hinterlassen.
    final wouldBe = BadgeSyncFormat.chunkBadges(merged, (p) => p.length);
    if (wouldBe.length > BadgeSyncFormat.maxChunks) {
      AppLogger.warn(_tag,
          '${wouldBe.length} Chunks nötig, gelesen werden nur ${BadgeSyncFormat.maxChunks} — Sync bleibt aus');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final generation =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000)
            .clamp(prefs.getInt(_lastGenKey) ?? 0, 1 << 62);
    // Chunk-Grenze an der NIP-44-Payload, nicht am Klartext: gzip und
    // base64 machen das Event größer als die Hülle.
    final plaintexts = BadgeSyncFormat.plaintexts(
      merged,
      generation,
      (p) => BadgeSyncFormat.payloadCharsForGzip(
          BadgeSyncCodec.deflate(p).length),
    );
    final oldHashes = prefs.getStringList(_hashesKey) ?? const [];

    final newHashes = <String>[];
    var ok = true;
    for (var i = 0; i < plaintexts.length; i++) {
      final plain = plaintexts[i];
      // Der Hash hängt nur am Inhalt, nicht an der Generation. Sonst
      // änderte er sich bei jedem Start und jeder Chunk ginge wieder raus.
      final hash = BadgeSyncFormat.contentHash(plain);
      newHashes.add(hash);
      if (i < oldHashes.length && oldHashes[i] == hash) continue;

      final sealed = await SigningService.nip44Encrypt(
          me, base64Encode(BadgeSyncCodec.deflate(plain)));
      final signed = await SigningService.signEvent(
        kind: BadgeSyncFormat.kind,
        tags: [
          ['d', BadgeSyncFormat.dTag(i)],
          ['client', 'einundzwanzig-meetup-app'],
        ],
        content: sealed,
      );
      final event = {
        'id': signed.id,
        'pubkey': signed.pubkey,
        'created_at': signed.createdAt,
        'kind': signed.kind,
        'tags': signed.tags,
        'content': signed.content,
        'sig': signed.sig,
      };
      var accepted = false;
      for (final url in syncRelays) {
        try {
          if (await _publish(url, event)) {
            accepted = true;
            break;
          }
        } catch (e) {
          AppLogger.debug(_tag, 'Veröffentlichen auf $url fehlgeschlagen: $e');
        }
      }
      if (!accepted) {
        AppLogger.warn(_tag, 'Chunk $i auf keinem Relay bestätigt');
        ok = false;
      }
    }
    await prefs.setStringList(_hashesKey, newHashes);
    await prefs.setInt(_lastGenKey, generation);
    return ok;
  }

  /// Veröffentlicht [event] und wartet auf das OK des Relays.
  static Future<bool> _publish(
    String relayUrl,
    Map<String, dynamic> event,
  ) async {
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(relayUrl)
          .timeout(const Duration(seconds: 5));
      final done = Completer<bool>();
      final id = (event['id'] ?? '').toString();
      ws.listen((data) {
        try {
          final msg = jsonDecode(data as String) as List<dynamic>;
          if (msg.length >= 3 && msg[0] == 'OK' && msg[1] == id) {
            if (!done.isCompleted) done.complete(msg[2] == true);
          }
        } catch (_) {}
      }, onError: (_) {
        if (!done.isCompleted) done.complete(false);
      }, onDone: () {
        if (!done.isCompleted) done.complete(false);
      });
      ws.add(jsonEncode(['EVENT', event]));
      return await done.future.timeout(_timeout, onTimeout: () => false);
    } finally {
      ws?.close();
    }
  }
}
