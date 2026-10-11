// Badge-Sync über Nostr: verschlüsselte Chunks in kind-30078-Events,
// NIP-44 an den eigenen Pubkey. Plan: docs/PLAN_BADGE_SYNC.md.
//
// Ablauf:
//   pull: Relays lesen, Chunks entschlüsseln, mit der lokalen Liste
//         vereinigen, lokal speichern.
//   push: erst pull, dann aus dem Ergebnis Chunks bauen und nur die
//         veröffentlichen, deren Klartext sich geändert hat.
//
// Drei Regeln aus dem Plan, die hier stehen und nicht im Aufrufer:
//   - nie eine leere Liste veröffentlichen (Reset-Pfad)
//   - ein Gerät ohne lokale Badges liest erst, bevor es je schreibt
//   - immer lesen, vereinigen, schreiben

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/badge.dart';
import 'app_logger.dart';
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
  static bool _pullInProgress = false;

  /// Einmal beim Start aufrufen: verknüpft saveBadges mit dem Sync und
  /// holt einmal fern, damit ein zweites Gerät ohne Scan schon sieht,
  /// was das andere hat. "Ein Gerät ohne lokale Badges liest erst."
  static void init() {
    MeetupBadge.onBadgesSaved = trigger;
    trigger();
  }

  /// Nach `saveBadges` aufrufen. Im Hintergrund, wirft nicht.
  static void trigger() {
    if (_pullInProgress) return;
    unawaited(() async {
      try {
        await syncNow();
      } catch (e) {
        AppLogger.debug(_tag, 'Sync fehlgeschlagen: $e');
      }
    }());
  }

  /// Einmal hoch- und wieder herunter. Gibt false, wenn der Signer kein
  /// NIP-44 kann oder gerade ein Lauf aktiv ist.
  static Future<bool> syncNow() async {
    if (_busy) return false;
    _busy = true;
    try {
      if (!await SigningService.canNip44()) {
        AppLogger.debug(_tag, 'Signer kann kein NIP-44 — Sync bleibt aus');
        return false;
      }
      final me = await SigningService.pubkeyHex();
      if (me == null || me.isEmpty) return false;

      final merged = await _pull(me);
      await _push(me, merged);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dirtyKey, false);
      return true;
    } finally {
      _busy = false;
    }
  }

  /// Relays lesen, entschlüsseln, mit der lokalen Liste vereinigen und
  /// das Ergebnis lokal speichern. Gibt die vereinigte Liste zurück.
  static Future<List<MeetupBadge>> _pull(String me) async {
    final remote = await _fetchRemote(me);
    final local = await MeetupBadge.loadBadges();
    final merged = BadgeSyncFormat.merge(local, remote);
    if (merged.length != local.length || remote.isNotEmpty) {
      // Das saveBadges unten würde den Sync erneut auslösen. Die Sperre
      // hält nur diesen eigenen Schreibvorgang heraus.
      _pullInProgress = true;
      try {
        await MeetupBadge.saveBadges(merged);
      } finally {
        _pullInProgress = false;
      }
    }
    return merged;
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
        final env = BadgeSyncFormat.parseEnvelope(plain);
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
  /// deren Klartext-Hash sich geändert hat. Nie eine leere Liste.
  static Future<void> _push(String me, List<MeetupBadge> merged) async {
    if (merged.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final generation =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000)
            .clamp(prefs.getInt(_lastGenKey) ?? 0, 1 << 62);
    // measure wie NIP-44: die Payload-Länge des Klartexts. Sie hängt vom
    // Verschlüsseln ab, darum eine Probe über den Signer.
    final plaintexts = BadgeSyncFormat.plaintexts(
      merged,
      generation,
      (p) => p.length,
    );
    final oldHashes = prefs.getStringList(_hashesKey) ?? const [];

    final newHashes = <String>[];
    var published = 0;
    for (var i = 0; i < plaintexts.length; i++) {
      final plain = plaintexts[i];
      final hash = BadgeSyncFormat.chunkHash(plain);
      newHashes.add(hash);
      if (i < oldHashes.length && oldHashes[i] == hash) continue;

      final sealed = await SigningService.nip44Encrypt(me, plain);
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
      for (final url in syncRelays) {
        try {
          await _publish(url, event);
          published++;
        } catch (e) {
          AppLogger.debug(_tag, 'Veröffentlichen auf $url fehlgeschlagen: $e');
        }
      }
    }
    await prefs.setStringList(_hashesKey, newHashes);
    await prefs.setInt(_lastGenKey, generation);
    if (published > 0) {
      AppLogger.debug(_tag, '$published Chunk-Events veröffentlicht');
    }
  }

  static Future<void> _publish(
    String relayUrl,
    Map<String, dynamic> event,
  ) async {
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(relayUrl)
          .timeout(const Duration(seconds: 5));
      ws.add(jsonEncode(['EVENT', event]));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      ws?.close();
    }
  }
}
