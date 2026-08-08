// VERANSTALTUNGSKALENDER — NIP-52 Calendar Events
// ============================================
// Liest und publiziert Kalender-Events über Nostr (NIP-52):
//   - kind 31923: zeitbasiertes Event (mit Start/Ende als Unix-Zeit)
//   - kind 31922: datumsbasiertes Event (ganztägig, nur Datum)
// Damit eingetragene Events (z.B. BTC Prag, Zitadelle) für ALLE sichtbar
// werden, die denselben Relays folgen.
//
// Quelle/Ziel: dieselben Relays wie der Rest der App. Signiert über den
// bestehenden SigningService (lokaler nsec ODER Amber, transparent).
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'relay_config.dart';
import 'signing_service.dart';
import 'app_logger.dart';
import 'relay_socket.dart';

const String _tag = 'Calendar';
const int kTimeEventKind = 31923; // zeitbasiert
const int kDateEventKind = 31922; // datumsbasiert (ganztägig)

/// Ein Kalender-Event (aus einem NIP-52-Event).
class NostrCalendarEvent {
  final String id;
  final String pubkey;
  final String dTag;
  final String title;
  final String description;
  final String location;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final int kind;
  final bool fromApp; // true, wenn via dieser App erstellt (client-Tag)

  NostrCalendarEvent({
    required this.id,
    required this.pubkey,
    required this.dTag,
    required this.title,
    required this.description,
    required this.location,
    required this.start,
    required this.end,
    required this.allDay,
    required this.kind,
    this.fromApp = false,
  });

  /// Tag (ohne Uhrzeit) für die Kalender-Gruppierung.
  DateTime get day => DateTime(start.year, start.month, start.day);

  static NostrCalendarEvent? fromEvent(Map<String, dynamic> e) {
    try {
      final kind = e['kind'] as int? ?? 0;
      if (kind != kTimeEventKind && kind != kDateEventKind) return null;
      final allDay = kind == kDateEventKind;

      final tags = (e['tags'] as List<dynamic>?)
              ?.map((t) => (t as List<dynamic>).map((x) => x.toString()).toList())
              .toList() ??
          [];
      String tagVal(String key) {
        final t = tags.firstWhere((t) => t.isNotEmpty && t[0] == key, orElse: () => const []);
        return t.length >= 2 ? t[1] : '';
      }

      final title = tagVal('title').isNotEmpty ? tagVal('title') : tagVal('name');
      final startRaw = tagVal('start');
      if (title.isEmpty || startRaw.isEmpty) return null;

      DateTime? start, end;
      if (allDay) {
        // start ist ein ISO-Datum (YYYY-MM-DD)
        start = DateTime.tryParse(startRaw);
        final endRaw = tagVal('end');
        if (endRaw.isNotEmpty) end = DateTime.tryParse(endRaw);
      } else {
        // start ist Unix-Sekunden
        final s = int.tryParse(startRaw);
        if (s != null) start = DateTime.fromMillisecondsSinceEpoch(s * 1000);
        final endRaw = tagVal('end');
        final en = int.tryParse(endRaw);
        if (en != null) end = DateTime.fromMillisecondsSinceEpoch(en * 1000);
      }
      if (start == null) return null;

      final client = tagVal('client');
      final fromApp = client == 'einundzwanzig-meetup-app';

      return NostrCalendarEvent(
        id: (e['id'] ?? '').toString(),
        pubkey: (e['pubkey'] ?? '').toString(),
        dTag: tagVal('d'),
        title: title,
        description: (e['content'] ?? '').toString(),
        location: tagVal('location'),
        start: start,
        end: end,
        allDay: allDay,
        kind: kind,
        fromApp: fromApp,
      );
    } catch (_) {
      return null;
    }
  }
}

class CalendarEventService {
  static const Duration _timeout = Duration(seconds: 8);

  /// Das Community-Relay für App-Events. Im Community-Modus werden nur
  /// Events von diesem Relay geladen (überschaubar). Im Weltweit-Modus
  /// werden alle aktiven Relays abgefragt.
  static const String kCommunityRelay = 'wss://nostr.einundzwanzig.space';

  /// Lädt Kalender-Events (NIP-52).
  /// [worldwide]=false (Standard): nur das Community-Relay, und nur Events,
  ///   die über diese App erstellt wurden (client-Tag) -> überschaubar.
  /// [worldwide]=true: alle aktiven Relays, alle Events (die ganze Nostr-Welt).
  /// Dedupliziert (pubkey:dTag -> neueste Version) und nach Startdatum sortiert.
  static Future<List<NostrCalendarEvent>> fetchEvents({int limit = 200, bool worldwide = false}) async {
    final List<String> relays;
    if (worldwide) {
      relays = await RelayConfig.getActiveRelays();
    } else {
      relays = [kCommunityRelay];
    }

    final byKey = <String, NostrCalendarEvent>{};
    for (final relayUrl in relays) {
      final list = await _fetchFromRelay(relayUrl, limit);
      if (list == null) continue;
      for (final ev in list) {
        // Community-Modus: nur Events, die über die App erstellt wurden.
        if (!worldwide && !ev.fromApp) continue;
        final key = '${ev.pubkey}:${ev.dTag}:${ev.kind}';
        byKey[key] = ev;
      }
    }

    final all = byKey.values.toList()..sort((a, b) => a.start.compareTo(b.start));
    return all;
  }

  static Future<List<NostrCalendarEvent>?> _fetchFromRelay(String relayUrl, int limit) async {
    RelaySocket? ws;
    final tally = RelayParseTally('Calendar', 'Nostr-Kalender von $relayUrl');
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final completer = Completer<List<NostrCalendarEvent>?>();
      final results = <NostrCalendarEvent>[];

      final random = Random.secure();
      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subId = 'cal-$subIdHex';

      ws.listen(
        (data) {
          tally.message();
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;
            if (type == 'EVENT' && message.length >= 3) {
              final ev = NostrCalendarEvent.fromEvent(message[2] as Map<String, dynamic>);
              if (ev != null) results.add(ev);
            } else if (type == 'EOSE') {
              if (!completer.isCompleted) completer.complete(results);
            }
          } catch (e) { tally.failed(e); }
        },
        onError: (_) { if (!completer.isCompleted) completer.complete(results); },
        onDone: () { if (!completer.isCompleted) completer.complete(results); },
      );

      ws.add(jsonEncode(['REQ', subId, {'kinds': [kTimeEventKind, kDateEventKind], 'limit': limit}]));
      final res = await completer.future.timeout(_timeout, onTimeout: () => results);
      return res;
    } catch (e) {
      AppLogger.debug(_tag, '$relayUrl Lesefehler: $e');
      return null;
    } finally {
      tally.report();
      try { ws?.close(); } catch (_) {}
    }
  }

  /// Publiziert ein zeitbasiertes Kalender-Event (kind 31923).
  /// Gibt die Anzahl Relays zurück, die akzeptiert haben (0 = Fehler).
  static Future<int> publishEvent({
    required String title,
    required String description,
    required String location,
    required DateTime start,
    DateTime? end,
    bool allDay = false,
  }) async {
    try {
      final random = Random.secure();
      final dTag = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

      final List<List<String>> tags;
      final int kind;
      if (allDay) {
        kind = kDateEventKind;
        String ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        tags = [
          ['d', dTag],
          ['title', title],
          ['start', ymd(start)],
          if (end != null) ['end', ymd(end)],
          if (location.trim().isNotEmpty) ['location', location.trim()],
          ['client', 'einundzwanzig-meetup-app'],
        ];
      } else {
        kind = kTimeEventKind;
        final startUnix = (start.toUtc().millisecondsSinceEpoch ~/ 1000).toString();
        tags = [
          ['d', dTag],
          ['title', title],
          ['start', startUnix],
          if (end != null) ['end', (end.toUtc().millisecondsSinceEpoch ~/ 1000).toString()],
          if (location.trim().isNotEmpty) ['location', location.trim()],
          ['client', 'einundzwanzig-meetup-app'],
        ];
      }

      final signed = await SigningService.signEvent(kind: kind, tags: tags, content: description.trim());
      return await _publish(signed);
    } catch (e) {
      AppLogger.debug(_tag, 'Event-Publish fehlgeschlagen: $e');
      return 0;
    }
  }

  static Future<int> _publish(SignedEvent event) async {
    final active = await RelayConfig.getActiveRelays();
    // Community-Relay IMMER einschließen, damit App-Events dort landen und
    // im Community-Modus auffindbar sind (auch wenn der Nutzer es abgewählt hat).
    final relays = <String>{...active, kCommunityRelay}.toList();
    if (relays.isEmpty) return 0;

    final eventJson = jsonEncode([
      'EVENT',
      {
        'id': event.id,
        'pubkey': event.pubkey,
        'created_at': event.createdAt,
        'kind': event.kind,
        'tags': event.tags,
        'content': event.content,
        'sig': event.sig,
      }
    ]);

    int ok = 0;
    for (final relayUrl in relays) {
      try {
        final ws = await RelaySocket.connect(relayUrl).timeout(RelayConfig.publishTimeout);
        ws.add(eventJson);
        await Future.delayed(const Duration(seconds: 2));
        ws.close();
        ok++;
      } catch (e) {
        AppLogger.debug(_tag, '$relayUrl Publish fehlgeschlagen: $e');
      }
    }
    return ok;
  }
}
