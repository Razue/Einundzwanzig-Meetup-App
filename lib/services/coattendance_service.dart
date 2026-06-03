import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:nostr/nostr.dart';
import '../models/badge.dart';
import 'signing_service.dart';
import 'relay_config.dart';
import 'nostr_service.dart';
import 'app_logger.dart';

/// Eine bestätigte Meetup-Teilnahme einer Person (von Relays geladen).
class CoAttendanceRecord {
  final String npub;          // Teilnehmer
  final String meetupEventId; // Welches Meetup-Event
  final int attendedAt;       // Unix-Sekunden (Event-Zeitpunkt)

  CoAttendanceRecord({
    required this.npub,
    required this.meetupEventId,
    required this.attendedAt,
  });
}

/// Ein Knoten im Co-Attendance-Netzwerk.
class CoAttNode {
  final String npub;
  final Set<String> meetups; // meetupEventIds, an denen er teilnahm
  CoAttNode(this.npub) : meetups = <String>{};
}

/// Ergebnis der Netzwerk-Analyse zwischen mir und einer Zielperson.
class CoAttNetwork {
  final String myNpub;
  final String targetNpub;
  final Set<String> sharedMeetups;          // gemeinsame Meetups (ich + Ziel)
  final List<String> mutualContacts;        // npubs, die sowohl mit mir als auch mit Ziel auf Meetups waren
  final Map<String, CoAttNode> nodes;       // alle bekannten Knoten
  final int targetTotalMeetups;             // wie viele Meetups die Zielperson besucht hat
  final int targetTotalContacts;            // mit wie vielen verschiedenen Leuten

  CoAttNetwork({
    required this.myNpub,
    required this.targetNpub,
    required this.sharedMeetups,
    required this.mutualContacts,
    required this.nodes,
    required this.targetTotalMeetups,
    required this.targetTotalContacts,
  });

  bool get hasDirectOverlap => sharedMeetups.isNotEmpty;
  bool get hasAnyConnection => sharedMeetups.isNotEmpty || mutualContacts.isNotEmpty;
}

/// Verwaltet das opt-in Co-Attendance-Netzwerk über Nostr.
///
/// Prinzip:
///  - Beim Badge-Scan (nach Zustimmung) wird ein signiertes Co-Attendance-Event
///    veröffentlicht: "npub X bestätigt Teilnahme an meetupEventId Y".
///  - Das Event ist an ein ECHTES, organisator-signiertes Badge gekoppelt
///    (badge.isNostrSigned + sigId), daher nicht beliebig fälschbar.
///  - Andere können diese Events laden und das Netzwerk rekonstruieren.
class CoAttendanceService {
  static const int kind = 30079; // Parameterized Replaceable (neben 30078 Reputation)
  static const String _client = 'einundzwanzig-meetup-app';
  static const Duration _timeout = Duration(seconds: 8);
  static const String _tag = 'CoAttendance';

  /// Veröffentlicht EIN Co-Attendance-Event für ein Badge.
  /// Nur aufrufen, wenn der Nutzer aktiv zugestimmt hat (Opt-in)!
  /// Gibt Anzahl erreichter Relays zurück (0 = Fehlschlag).
  static Future<int> publishAttendance(MeetupBadge badge) async {
    // Sicherheit: nur echte, organisator-signierte Badges qualifizieren
    if (!badge.isNostrSigned || badge.meetupEventId.isEmpty) {
      AppLogger.debug(_tag, 'Badge nicht qualifiziert (nicht Nostr-signiert)');
      return 0;
    }

    try {
      // Inhalt bewusst minimal (datenschutzbewusst)
      final content = jsonEncode({
        'event': badge.meetupEventId,
        'meetup': badge.meetupName,
        't': badge.date.millisecondsSinceEpoch ~/ 1000,
      });

      // d-Tag = meetupEventId -> pro Meetup genau EIN ersetzbares Event je npub
      final signed = await SigningService.signEvent(
        kind: kind,
        tags: <List<String>>[
          ['d', badge.meetupEventId],
          ['e_ref', badge.sigId], // Referenz auf das Badge-Signatur-Event (Kopplung)
          ['client', _client],
        ],
        content: content,
      );

      return await _publish(signed);
    } catch (e) {
      AppLogger.debug(_tag, 'Publish-Fehler: $e');
      return 0;
    }
  }

  static Future<int> _publish(SignedEvent event) async {
    final relays = await RelayConfig.getActiveRelays();
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
        final ws = await WebSocket.connect(relayUrl).timeout(RelayConfig.publishTimeout);
        ws.add(eventJson);
        await Future.delayed(const Duration(seconds: 2));
        ws.close();
        ok++;
      } catch (e) {
        AppLogger.debug(_tag, '$relayUrl fehlgeschlagen: $e');
      }
    }
    return ok;
  }

  /// Lädt ALLE Co-Attendance-Events von den Relays und baut Knoten auf.
  static Future<Map<String, CoAttNode>> _loadAllNodes() async {
    final relays = await RelayConfig.getActiveRelays();
    final nodes = <String, CoAttNode>{};

    for (final relayUrl in relays) {
      final records = await _fetchFromRelay(relayUrl);
      if (records == null) continue;
      for (final r in records) {
        final node = nodes.putIfAbsent(r.npub, () => CoAttNode(r.npub));
        node.meetups.add(r.meetupEventId);
      }
    }
    return nodes;
  }

  static Future<List<CoAttendanceRecord>?> _fetchFromRelay(String relayUrl) async {
    WebSocket? ws;
    final out = <CoAttendanceRecord>[];
    try {
      ws = await WebSocket.connect(relayUrl).timeout(_timeout);
      final random = Random.secure();
      final subId = 'coatt-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
      final completer = Completer<List<CoAttendanceRecord>?>();

      ws.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as List<dynamic>;
            if (msg[0] == 'EVENT' && msg.length >= 3) {
              final ev = msg[2] as Map<String, dynamic>;
              final authorHex = ev['pubkey'] as String;
              final authorNpub = Nip19.encodePubkey(authorHex);
              final content = jsonDecode(ev['content'] as String) as Map<String, dynamic>;
              final meetupEventId = (content['event'] ?? '').toString();
              final t = (content['t'] is int) ? content['t'] as int : 0;
              if (meetupEventId.isNotEmpty) {
                out.add(CoAttendanceRecord(
                  npub: authorNpub,
                  meetupEventId: meetupEventId,
                  attendedAt: t,
                ));
              }
            }
            if (msg[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete(out);
            }
          } catch (_) {}
        },
        onDone: () { if (!completer.isCompleted) completer.complete(out); },
        onError: (_) { if (!completer.isCompleted) completer.complete(null); },
      );

      ws.add(jsonEncode(['REQ', subId, {'kinds': [kind]}]));

      final res = await completer.future.timeout(
        _timeout,
        onTimeout: () => out.isEmpty ? null : out,
      );
      ws.add(jsonEncode(['CLOSE', subId]));
      return res;
    } catch (e) {
      AppLogger.debug(_tag, 'Fetch-Fehler $relayUrl: $e');
      return null;
    } finally {
      ws?.close();
    }
  }

  /// Analysiert das Netzwerk zwischen [myNpub] und [targetNpub].
  static Future<CoAttNetwork> analyze({
    required String myNpub,
    required String targetNpub,
  }) async {
    final nodes = await _loadAllNodes();

    final myNode = nodes[myNpub];
    final targetNode = nodes[targetNpub];

    final myMeetups = myNode?.meetups ?? <String>{};
    final targetMeetups = targetNode?.meetups ?? <String>{};

    // Gemeinsame Meetups (ich + Ziel)
    final shared = myMeetups.intersection(targetMeetups);

    // Gemeinsame Kontakte: andere npubs, die mit BEIDEN je ein Meetup teilen
    final mutual = <String>[];
    for (final entry in nodes.entries) {
      final npub = entry.key;
      if (npub == myNpub || npub == targetNpub) continue;
      final m = entry.value.meetups;
      final withMe = m.intersection(myMeetups).isNotEmpty;
      final withTarget = m.intersection(targetMeetups).isNotEmpty;
      if (withMe && withTarget) mutual.add(npub);
    }

    // Reichweite der Zielperson: mit wie vielen verschiedenen Leuten war sie?
    final targetContacts = <String>{};
    for (final entry in nodes.entries) {
      if (entry.key == targetNpub) continue;
      if (entry.value.meetups.intersection(targetMeetups).isNotEmpty) {
        targetContacts.add(entry.key);
      }
    }

    return CoAttNetwork(
      myNpub: myNpub,
      targetNpub: targetNpub,
      sharedMeetups: shared,
      mutualContacts: mutual,
      nodes: nodes,
      targetTotalMeetups: targetMeetups.length,
      targetTotalContacts: targetContacts.length,
    );
  }

  static String npubToHex(String npub) => NostrService.npubToHex(npub);
}
