// Badge-Sync über Nostr: verschlüsselte Chunks in kind-30078-Events,
// NIP-44 an den eigenen Pubkey. Plan: docs/PLAN_BADGE_SYNC.md.
//
// Ablauf:
//   pull: Relays lesen und mit der lokalen Datei je Veranstaltung
//         vereinigen (MeetupBadge.unionByIdentity). Kein Relay erreichbar:
//         der Lauf scheitert und wird nachgeholt, statt blind zu schreiben.
//         Ist die Datei nicht lesbar, bleiben die Bytes liegen; eine ferne
//         Kopie wird nur daneben geschrieben.
//   push: erst pull, dann aus dem Ergebnis Chunks bauen und nur die
//         veröffentlichen, deren Inhalt sich geändert hat, und nur auf
//         Relays zählen, die das Event bestätigen.
//
// Drei Regeln aus dem Plan, die hier stehen und nicht im Aufrufer:
//   - nie eine leere Liste veröffentlichen (Reset-Pfad)
//   - jedes Gerät liest, bevor es schreibt: vereinigen statt überschreiben
//   - eine nicht lesbare Datei ist keine leere Liste: nichts überschreiben,
//     nichts leeres veröffentlichen, ferne Badges nur zusätzlich sichern

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;
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
  /// Übersteht einen Abbruch mitten im Identitätswechsel. Solange das
  /// gesetzt ist, wird nichts veröffentlicht.
  static const _holdKey = 'badge_restore_hold';
  /// Die aktive Identität beim Beginn des Einspielens. Ob der Schlüssel
  /// gewechselt hat, sagt der Keystore selbst: ein Vergleich damit, kein
  /// eigenes Flag, das zwischen zwei Schreibvorgängen falsch sein kann.
  static const _fromKey = 'badge_restore_from';
  /// Leeres Backup einer anderen Identität: die alte Sammlung muss noch
  /// ins Archiv, bevor irgendetwas veröffentlicht wird. Liegt vor dem
  /// Schlüssel, damit ein Abbruch dazwischen den Riegel nicht öffnet.
  static const _clearKey = 'badge_restore_clear';
  static const _timeout = Duration(seconds: 8);

  static bool _busy = false;

  // Solange ein Backup eingespielt wird, läuft kein Sync. saveBadges feuert
  // dort, bevor der Schlüssel aus dem Backup im Keystore liegt: Der Lauf
  // würde die Badges der neuen Identität unter dem alten Pubkey
  // veröffentlichen. Ein ausgesetzter Auslöser wird beim Fortsetzen
  // einmal nachgeholt.
  static bool _suspended = false;
  static bool _pendingWhileSuspended = false;

  /// Zählt die Läufe von [syncNow], nur für Tests.
  @visibleForTesting
  static int runs = 0;

  /// Speicher des Prozesses leeren. Ein echter Neustart tut dasselbe,
  /// die Prefs bleiben.
  @visibleForTesting
  static void debugResetProcess() {
    _suspended = false;
    _pendingWhileSuspended = false;
    _busy = false;
    _rerun = false;
  }

  // Merkt, dass während eines laufenden Syncs ein weiterer Lauf nötig wurde
  // (saveBadges oder ein Signer, der gerade benutzbar wurde). Der laufende
  // Lauf arbeitet mit einem alten Stand; danach läuft einer nach, auch wenn
  // der laufende scheitert.
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

  /// Sync aussetzen, solange ein Backup eingespielt wird. Der Riegel liegt
  /// auch in den Prefs: ein Abbruch dazwischen veröffentlicht nichts.
  /// [fromNpub] ist die aktive Identität vor dem Einspielen.
  /// Was von einem früheren Einspielen noch liegt, wird erst nach
  /// Keystore-Wahrheit abgeräumt. Bleibt der Riegel trotzdem, werden Puffer
  /// und Leeren-Vormerk verworfen: solange ein Riegel stand, war die aktive
  /// Datei unberührt, und die Backup-Datei gibt es noch.
  static Future<void> beginRestoreHold({String fromNpub = ''}) async {
    await settleRestore();
    final prefs = await SharedPreferences.getInstance();
    await MeetupBadge.discardIncoming();
    await prefs.remove(_clearKey);
    await prefs.setString(_fromKey, fromNpub.trim().toLowerCase());
    await prefs.setBool(_holdKey, true);
    _suspended = true;
  }

  /// Einspielen zu Ende, gleich ob gelungen oder abgebrochen. Der Keystore
  /// entscheidet, was mit dem Puffer passiert ([settleRestore]). Ein
  /// Auslöser, der währenddessen kam, läuft jetzt einmal nach.
  static Future<void> endRestore() async {
    _suspended = false;
    await settleRestore();
    if (_pendingWhileSuspended) {
      _pendingWhileSuspended = false;
      trigger();
    }
  }

  /// Ein Wechsel liegt nur vor, wenn jetzt eine andere Identität lesbar ist.
  /// Ein leerer npub ist ein Lese-Aussetzer, kein vollzogener Wechsel.
  static bool identitySwitched(String from, String now) {
    final current = now.trim().toLowerCase();
    if (current.isEmpty) return false;
    return current != from.trim().toLowerCase();
  }

  /// Vormerken, dass nach dem Schlüssel die alte Sammlung ins Archiv muss.
  /// false heißt: der Riegel hätte danach nichts mehr, woran er sich hält.
  static Future<void> markRestoreClear() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(_clearKey, true)) {
      throw Exception(
          'Die leere Sammlung konnte nicht vorgemerkt werden.');
    }
  }

  /// Die alte Sammlung liegt im Archiv, der Vormerk ist erledigt.
  static Future<void> clearRestoreMark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clearKey);
  }

  /// Räumt einen Riegel ab, auch nach einem Absturz mitten im Wechsel.
  /// Hat die Identität seit dem Beginn gewechselt, wird ein Puffer zur
  /// aktiven Datei und die Chunk-Hashes der alten Identität werden
  /// vergessen. Sonst wird der Puffer verworfen, die alte Datei bleibt
  /// vollständig. Läuft das Einspielen noch in diesem Prozess, passiert
  /// nichts: der Puffer gehört ihm.
  static Future<void> settleRestore() async {
    if (_suspended) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_holdKey) != true) return;
    final from = (prefs.getString(_fromKey) ?? '').trim().toLowerCase();
    final now = ((await SigningService.npub()) ?? '').trim().toLowerCase();
    final switched = identitySwitched(from, now);
    final incoming = prefs.getString(MeetupBadge.incomingPrefsKey);
    final staged = incoming != null && incoming.contains(':');
    var clear = prefs.getBool(_clearKey) == true;
    // Vorher stand eine Identität, jetzt ist kein npub lesbar. Nichts
    // entscheiden: weder übernehmen noch den Riegel öffnen. War vorher
    // keine Identität da, gibt es nichts, das unter einem neuen Schlüssel
    // veröffentlicht werden könnte.
    if (from.isNotEmpty && now.isEmpty && (staged || clear)) {
      AppLogger.warn(_tag, 'npub gerade nicht lesbar, Riegel bleibt');
      return;
    }
    if (staged) {
      if (switched) {
        // Nahm das Archiv die alte Sammlung nicht an, liegt sie noch als
        // aktive Datei. Riegel und Puffer bleiben, sonst ginge sie beim
        // nächsten Lauf unter dem neuen Pubkey raus. Der nächste Sync
        // versucht es erneut.
        if (!await MeetupBadge.promoteIncoming(formerNpub: from)) {
          AppLogger.warn(_tag,
              'Puffer nicht übernommen, Riegel bleibt bis zum nächsten Versuch');
          return;
        }
      } else {
        await MeetupBadge.discardIncoming();
      }
      // Der Puffer ist die neue Sammlung. Ein Leeren-Vormerk daneben
      // würde sie anschließend wegwerfen.
      if (clear) {
        await prefs.remove(_clearKey);
        clear = false;
      }
    }
    if (clear) {
      if (!switched) {
        await prefs.remove(_clearKey);
      } else if (!await _clearActiveWithoutSync()) {
        AppLogger.warn(_tag,
            'Leere Sammlung nicht übernommen, Riegel bleibt');
        return;
      } else {
        await prefs.remove(_clearKey);
      }
    }
    if (switched) await forgetLocalState();
    await prefs.remove(_holdKey);
    await prefs.remove(_fromKey);
  }

  /// Wie das leere Ersetzen im Backup, ohne den Sync anzustoßen: der läuft
  /// erst, wenn der Riegel wirklich weg ist.
  static Future<bool> _clearActiveWithoutSync() async {
    final saved = MeetupBadge.onBadgesSaved;
    MeetupBadge.onBadgesSaved = null;
    try {
      return await MeetupBadge.saveBadges([], discardLocked: true);
    } finally {
      MeetupBadge.onBadgesSaved = saved;
    }
  }

  static Future<bool> _isHeld() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_holdKey) == true;
  }

  /// Nach einem Identitätswechsel ohne Reset: Chunk-Hashes und Generation
  /// gehören zur alten Identität. Ohne das Vergessen würde ein Chunk mit
  /// gleichem Inhalt nicht veröffentlicht, obwohl er unter dem neuen
  /// Pubkey auf keinem Relay liegt.
  static Future<void> forgetLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hashesKey);
    await prefs.remove(_lastGenKey);
    await prefs.remove(_dirtyKey);
  }

  /// Nach `saveBadges` aufrufen. Im Hintergrund, wirft nicht.
  static void trigger() {
    if (_suspended) {
      _pendingWhileSuspended = true;
      return;
    }
    unawaited(() async {
      final prefs = await SharedPreferences.getInstance();
      try {
        final ok = await syncNow();
        // false heißt: Relays, Pull oder Push sind gescheitert. Kein Signer
        // und abgelehntes NIP-44 setzen hier nichts — sonst fragt jedes
        // Aufwachen erneut nach der Freigabe.
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

  /// Einmal hoch- und wieder herunter.
  ///
  /// false: Relays, Pull oder Push sind gescheitert. Der Aufrufer merkt dirty,
  /// das Aufwachen holt genau diesen Fall nach.
  /// true: fertig, oder es gibt gerade keinen Signer bzw. kein NIP-44. Beides
  /// setzt kein dirty. Lief schon ein Sync, wird dieser Aufruf nachgezogen,
  /// sobald der laufende durch ist — auch nach einem Fehlschlag.
  static Future<bool> syncNow() async {
    if (_busy) {
      _rerun = true;
      return true;
    }
    _busy = true;
    runs++;
    try {
      while (true) {
        _rerun = false;
        final attempt = await _syncOnce();
        // Ein Signer, der während dieses Laufs benutzbar wurde, oder ein
        // saveBadges: der Nachzügler zählt, das Ergebnis davor nicht.
        if (_rerun) continue;
        if (attempt == _SyncAttempt.nip44Blocked) {
          // Die Probe hat den Signer schon gefragt. Dirty löschen, sonst
          // kommt beim nächsten Aufwachen dieselbe Freigabe erneut.
          final prefs = await SharedPreferences.getInstance();
          if (_rerun) continue;
          await prefs.setBool(_dirtyKey, false);
          if (_rerun) continue;
          return true;
        }
        if (attempt == _SyncAttempt.noSigner) return true;
        if (attempt == _SyncAttempt.held) return true;
        return attempt == _SyncAttempt.ok;
      }
    } finally {
      _busy = false;
    }
  }

  static Future<_SyncAttempt> _syncOnce() async {
    await settleRestore();
    if (await _isHeld()) return _SyncAttempt.held;

    final me = await SigningService.pubkeyHex();
    if (me == null || me.isEmpty) return _SyncAttempt.noSigner;

    // Der Signer darf NIP-44 nicht können. Dann bleibt der Sync aus,
    // statt dem Nutzer einen Fehler zu zeigen — das Backup ist der Weg.
    // canNip44 fängt selbst; die Zweige bleiben, falls die Probe doch wirft.
    try {
      if (!await SigningService.canNip44()) {
        AppLogger.debug(_tag, 'Signer kann kein NIP-44 — Sync bleibt aus');
        return _SyncAttempt.nip44Blocked;
      }
    } on UnsupportedError {
      AppLogger.debug(_tag, 'Signer kann kein NIP-44 — Sync bleibt aus');
      return _SyncAttempt.nip44Blocked;
    } on SigningException catch (e) {
      AppLogger.debug(_tag, 'NIP-44-Probe abgelehnt — Sync bleibt aus: $e');
      return _SyncAttempt.nip44Blocked;
    }

    final merged = await _pull(me);
    // null: die lokale Datei ist nicht lesbar und die Relays haben keine
    // Kopie. Nicht als leeren Erfolg verbuchen.
    if (merged == null) return _SyncAttempt.failed;
    if (await _isHeld()) return _SyncAttempt.held;
    final pushed = await _push(me, merged);
    final prefs = await SharedPreferences.getInstance();
    // Dirty bleibt, wenn ein Chunk auf keinem Relay bestätigt wurde.
    await prefs.setBool(_dirtyKey, !pushed);
    return pushed ? _SyncAttempt.ok : _SyncAttempt.failed;
  }

  /// Relays lesen, entschlüsseln und mit der lokalen Datei je Veranstaltung
  /// vereinigen. Nichts, was irgendwo liegt, geht verloren; Doppelscans
  /// fallen durch die Vereinigungsregel weg, auf jedem Gerät gleich.
  /// null: kein Relay erreichbar oder lokal nicht speicherbar. Dann gilt
  /// der Lauf als gescheitert und wird nachgeholt, statt blind zu schreiben.
  static Future<List<MeetupBadge>?> _pull(String me) async {
    final local = await MeetupBadge.loadBadges();
    if (MeetupBadge.badgesUnreadable) {
      final remote = await _fetchRemote(me) ?? const <MeetupBadge>[];
      if (remote.isEmpty) {
        AppLogger.warn(_tag,
            'Lokale Badges nicht lesbar, auf den Relays liegt keine Kopie');
        return null;
      }
      // Die alte Datei bleibt als Sicherung. Die ferne Liste wird die
      // lesbare Fassung, vorgemerkte Scans kommen in saveBadges dazu.
      // Ein Restore, der währenddessen begann, hat Vorrang: nicht über
      // seine Datei schreiben.
      if (await _isHeld()) return null;
      final wrote = await MeetupBadge.saveBadges(remote, replaceUnreadable: true);
      if (!wrote) return null;
      return MeetupBadge.loadBadges();
    }
    final remote = await _fetchRemote(me);
    if (remote == null) {
      AppLogger.debug(_tag, 'Kein Relay erreichbar, Sync wird nachgeholt');
      return null;
    }
    final merged = BadgeSyncFormat.merge(local, remote);
    if (MeetupBadge.sameBadges(merged, local)) return local;
    // Ein Restore, der während des Lesens begann, hat Vorrang: nicht über
    // seine Datei schreiben. Kam die Vereinigung lokal nicht an, ist das
    // kein Erfolg: Der Sync bleibt dirty und versucht es wieder.
    if (await _isHeld()) return null;
    if (!await MeetupBadge.saveBadges(merged)) return null;
    return merged;
  }

  /// Lädt alle Chunks von den Relays, entschlüsselt, was geht, und
  /// vereinigt die Badges. Fehlende oder kaputte Chunks fallen weg.
  /// null, wenn kein einziges Relay geantwortet hat.
  static Future<List<MeetupBadge>?> _fetchRemote(String me) async {
    var answered = 0;
    final events = await Future.wait(
      syncRelays.map((url) => _fetchFromRelay(url, me).then((r) {
            answered++;
            return r;
          }).catchError((Object e) {
            AppLogger.debug(_tag, 'Lesen von $url fehlgeschlagen: $e');
            return <int, Map<String, dynamic>>{};
          })),
    );
    if (answered == 0) return null;

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

/// Ein Lauf. Nur [failed] ist ein abgebrochener Relay-Sync und setzt dirty.
enum _SyncAttempt {
  ok,
  noSigner,
  nip44Blocked,
  held,
  failed,
}
