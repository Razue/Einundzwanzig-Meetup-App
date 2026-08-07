import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:nostr/nostr.dart';
import '../models/badge.dart';
import 'signing_service.dart';
import 'relay_config.dart';
import 'nostr_service.dart';
import 'mempool.dart';
import 'app_logger.dart';
import 'relay_socket.dart';

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
  /// Der Schluessel, unter dem Anwesenheit veroeffentlicht wird.
  ///
  /// FRUEHER: nur `meetupEventId`, also "name-JJJJ-MM-TT". Der Name stammt
  /// vom Tag des Organisators — und generische Namen kollidieren weltweit.
  /// Im Feldtest verband das vier wildfremde Leute miteinander, weil alle
  /// am selben Tag eine Session namens "test" angelegt hatten. Auch echte
  /// Faelle sind betroffen: Berlin hat vier Gruppen im Portal, Osnabrueck
  /// und Budapest ebenso — treffen sich zwei davon am selben Abend, waren
  /// bisher alle Beteiligten "direkt bekannt".
  ///
  /// JETZT: zusaetzlich der Signierer. Alle Teilnehmer EINER Session haben
  /// denselben Organisator gescannt, teilen also denselben Wert — die
  /// Verknuepfung innerhalb der Session bleibt exakt erhalten. Zwei
  /// verschiedene Sessions koennen sich aber nicht mehr vermischen, selbst
  /// bei identischem Namen und Datum.
  ///
  /// Die Badge-Identitaet (`meetupEventId`) bleibt UNVERAENDERT — sonst
  /// waere der Duplikatschutz betroffen, und ein Teilnehmer koennte an
  /// einem Abend mehrere Badges sammeln.
  static String attendanceKey(String meetupEventId, String signerNpub) {
    final signer = signerNpub.trim();
    if (signer.isEmpty) return meetupEventId; // Altformat, besser als nichts
    final short = signer.length > 12 ? signer.substring(signer.length - 12) : signer;
    return '$meetupEventId@$short';
  }

  static Future<int> publishAttendance(MeetupBadge badge) async {
    // Sicherheit: nur echte, organisator-signierte Badges qualifizieren
    if (!badge.isNostrSigned || _isDegenerateEventId(badge.meetupEventId)) {
      AppLogger.warn(_tag, 'Badge nicht qualifiziert (nicht Nostr-signiert)');
      return 0;
    }

    try {
      final key = attendanceKey(badge.meetupEventId, badge.signerNpub);

      // Inhalt bewusst minimal (datenschutzbewusst)
      final content = jsonEncode({
        'event': key,
        'meetup': badge.meetupName,
        't': badge.date.millisecondsSinceEpoch ~/ 1000,
      });

      // d-Tag = Schluessel -> pro Session genau EIN ersetzbares Event je npub
      final signed = await SigningService.signEvent(
        kind: kind,
        tags: <List<String>>[
          ['d', key],
          ['e_ref', badge.sigId], // Referenz auf das Badge-Signatur-Event (Kopplung)
          ['client', _client],
        ],
        content: content,
      );

      return await _publish(signed);
    } catch (e) {
      AppLogger.warn(_tag, 'Publish-Fehler: $e');
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
        final ws = await RelaySocket.connect(relayUrl).timeout(RelayConfig.publishTimeout);
        ws.add(eventJson);
        await Future.delayed(const Duration(seconds: 2));
        ws.close();
        ok++;
      } catch (e) {
        AppLogger.warn(_tag, '$relayUrl fehlgeschlagen: $e');
      }
    }
    return ok;
  }

  /// Lädt ALLE Co-Attendance-Events von den Relays und baut Knoten auf.
  /// Erkennt Kennungen, die kein echtes Meetup bezeichnen.
  ///
  /// Notwendig fuer BESTEHENDE Daten: Vor dem Fix konnte ein Tag ohne
  /// Meetup-Namen die Kennung "-2026-02-25" erzeugen — nicht leer, aber
  /// weltweit identisch fuer alle, die an dem Tag scannten. Wer solche
  /// Datensaetze veroeffentlicht hat, wuerde sonst dauerhaft mit Fremden
  /// verknuepft. Sie liegen auf den Relays und lassen sich nicht
  /// zurueckholen, also werden sie hier ignoriert.
  ///
  /// Verworfen wird alles, was vor dem Datum keinen Ortsteil hat, sowie
  /// die uebersetzten Platzhalter fuer "unbekanntes Meetup".
  static bool _isDegenerateEventId(String id) {
    final v = id.trim().toLowerCase();
    if (v.isEmpty) return true;
    if (v.startsWith('-')) return true; // "-2026-02-25"
    const placeholders = [
      'unbekanntes-meetup',
      'unknown-meetup',
      'meetup-desconocido',
    ];
    for (final p in placeholders) {
      if (v.startsWith(p)) return true;
    }
    // Reine Datumsangabe ohne Ort.
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return true;

    // GENERISCHE NAMEN aus Altdaten (vor der Signierer-Erweiterung).
    // Im Feldtest verband "test-2026-07-24" vier wildfremde Leute — jeder
    // Entwickler legt irgendwann eine Session namens "test" an, und ohne
    // Signierer im Schluessel landen sie alle im selben Topf. Solche
    // Eintraege liegen auf den Relays und lassen sich nicht zurueckholen.
    //
    // Betrifft NUR Schluessel im Altformat (ohne "@"): Neue tragen den
    // Signierer und koennen selbst bei generischem Namen nicht kollidieren.
    if (!v.contains('@')) {
      final namePart = v.replaceAll(RegExp(r'-\d{4}-\d{2}-\d{2}$'), '');
      const generic = {
        'test', 'test1', 'test2', 'test3', 'testing', 'demo',
        'home', 'garten', 'ab-test', 'probe', 'temp', 'tmp', 'xxx',
      };
      if (generic.contains(namePart)) return true;
    }
    return false;
  }

  static Future<Map<String, CoAttNode>> _loadAllNodes() async {
    final relays = await RelayConfig.getActiveRelays();
    final nodes = <String, CoAttNode>{};

    for (final relayUrl in relays) {
      final records = await _fetchFromRelay(relayUrl);
      if (records == null) continue;
      for (final r in records) {
        // Fehl-Kennungen ueberspringen — sonst entstehen Verknuepfungen
        // zwischen Leuten, die sich nie begegnet sind.
        if (_isDegenerateEventId(r.meetupEventId)) continue;
        final node = nodes.putIfAbsent(r.npub, () => CoAttNode(r.npub));
        node.meetups.add(r.meetupEventId);
      }
    }
    return nodes;
  }

  static Future<List<CoAttendanceRecord>?> _fetchFromRelay(String relayUrl) async {
    RelaySocket? ws;
    final tally = RelayParseTally('CoAttendance', 'Co-Attendance von $relayUrl');
    final out = <CoAttendanceRecord>[];
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final random = Random.secure();
      final subId = 'coatt-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
      final completer = Completer<List<CoAttendanceRecord>?>();

      ws.listen(
        (data) {
          tally.message();
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
          } catch (_) { tally.failed(); }
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
      AppLogger.warn(_tag, 'Fetch-Fehler $relayUrl: $e');
      return null;
    } finally {
      tally.report();
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

  /// Prüft die physische Verbindung zu EINER bestimmten Person ("Präsenz-Check").
  ///
  /// Berechnet den kürzesten Pfad über echte Meetup-Begegnungen:
  ///   Grad 0 = das bin ich selbst (npub identisch)
  ///   Grad 1 = direkt auf einem Meetup getroffen
  ///   Grad 2 = jemand, den ich getroffen habe, hat die Person getroffen
  ///   Grad 3+ = noch weiter über die Kette
  /// Gibt den konkreten Pfad (Du -> ... -> Zielperson) zurück.
  static Future<PresenceCheck> verifyPerson({
    required String myNpub,
    required String targetNpub,
    int maxDepth = 6,
  }) async {
    final nodes = await _loadAllNodes();

    final myMeetups = nodes[myNpub]?.meetups ?? <String>{};
    final targetMeetups = nodes[targetNpub]?.meetups ?? <String>{};
    final sharedMeetups = myMeetups.intersection(targetMeetups);

    // Sonderfall: man selbst
    if (myNpub == targetNpub) {
      return PresenceCheck(
        targetNpub: targetNpub,
        degree: 0,
        path: [myNpub],
        sharedMeetups: sharedMeetups,
        targetInNetwork: nodes.containsKey(targetNpub),
        targetTotalMeetups: targetMeetups.length,
      );
    }

    // Ungerichtete Adjazenz aufbauen (Kante = gemeinsames Meetup)
    final adj = <String, Set<String>>{};
    final entries = nodes.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      for (int j = i + 1; j < entries.length; j++) {
        if (entries[i].value.meetups.intersection(entries[j].value.meetups).isNotEmpty) {
          adj.putIfAbsent(entries[i].key, () => <String>{}).add(entries[j].key);
          adj.putIfAbsent(entries[j].key, () => <String>{}).add(entries[i].key);
        }
      }
    }

    final targetInNetwork = nodes.containsKey(targetNpub);

    // BFS für kürzesten Pfad my -> target
    List<String>? foundPath;
    if (adj.containsKey(myNpub)) {
      final visited = <String>{myNpub};
      final queue = <List<String>>[[myNpub]];
      while (queue.isNotEmpty) {
        final cur = queue.removeAt(0);
        if (cur.length - 1 > maxDepth) continue;
        final last = cur.last;
        if (last == targetNpub) { foundPath = cur; break; }
        for (final n in (adj[last] ?? const <String>{})) {
          if (!visited.contains(n)) {
            visited.add(n);
            queue.add([...cur, n]);
          }
        }
      }
    }

    return PresenceCheck(
      targetNpub: targetNpub,
      degree: foundPath == null ? -1 : foundPath.length - 1,
      path: foundPath ?? const [],
      sharedMeetups: sharedMeetups,
      targetInNetwork: targetInNetwork,
      targetTotalMeetups: targetMeetups.length,
    );
  }

  /// Erfasst die Teilnahme des ORGANISATORS am eigenen Meetup.
  ///
  /// Anders als beim normalen Badge-Scan:
  ///  - Der Organisator darf sich kein selbst-signiertes Reputations-Badge
  ///    geben (würde den Trust Score manipulieren — bleibt blockiert).
  ///  - ABER: Er war nachweislich da (hat das Event signiert), also nimmt er
  ///    automatisch am Co-Attendance-Netzwerk teil und bekommt ein
  ///    Organisator-MARKER-Badge (isOrganizer = true, zählt NICHT zum Score).
  ///
  /// [meetupName] und [date] müssen identisch zu den Teilnehmer-Badges sein,
  /// damit derselbe meetupEventId entsteht und alle im selben Knoten landen.
  ///
  /// Gibt das erstellte Organisator-Badge zurück (oder null bei Fehler).
  static Future<MeetupBadge?> recordOrganizerAttendance({
    required String meetupName,
    required DateTime date,
    int blockHeight = 0,
    double lat = 0,
    double lng = 0,
  }) async {
    try {
      // Exakt dasselbe Format wie in meetup_verification.dart
      final dateStr = date.toIso8601String().substring(0, 10);
      final meetupEventId =
          '${meetupName.toLowerCase().replaceAll(' ', '-')}-$dateStr';

      // Blockhöhe sicherstellen: falls 0 übergeben (Session hatte sie nicht),
      // selbst von Mempool holen — damit das Badge eine echte Blockzeit hat.
      int finalBlockHeight = blockHeight;
      if (finalBlockHeight <= 0) {
        finalBlockHeight = await MempoolService.getBlockHeight();
      }

      // 1. Organisator-Marker-Badge erstellen (zählt NICHT zum Trust Score)
      final badge = MeetupBadge(
        id: 'org-$meetupEventId',
        meetupName: meetupName,
        date: date,
        iconPath: '',
        blockHeight: finalBlockHeight,
        meetupEventId: meetupEventId,
        delivery: 'organizer',
        isOrganizer: true,
        lat: lat,
        lng: lng,
      );

      // 2. Schon vorhanden? (nicht doppelt anlegen)
      final existing = await MeetupBadge.loadBadges();
      final already = existing.any((b) =>
          b.isOrganizer && b.meetupEventId == meetupEventId);
      if (!already) {
        existing.add(badge);
        await MeetupBadge.saveBadges(existing);
      }

      // 3. Co-Attendance veröffentlichen (Organisator nimmt automatisch teil).
      //    Hier KEIN isNostrSigned-Check wie bei publishAttendance, weil die
      //    Teilnahme durch die Organisator-Signatur der Session ohnehin belegt
      //    ist (nur der Organisator besitzt den Schlüssel).
      await _publishOrganizerAttendance(meetupEventId, meetupName, date);

      return badge;
    } catch (e) {
      AppLogger.warn(_tag, 'Organisator-Teilnahme fehlgeschlagen: $e');
      return null;
    }
  }

  static Future<int> _publishOrganizerAttendance(
      String meetupEventId, String meetupName, DateTime date) async {
    // Der Organisator IST der Signierer seiner eigenen Session — damit
    // stimmt sein Schluessel mit dem seiner Teilnehmer ueberein.
    final ownNpub = await SigningService.npub();
    final key = attendanceKey(meetupEventId, ownNpub ?? '');
    try {
      final content = jsonEncode({
        'event': key,
        'meetup': meetupName,
        't': date.millisecondsSinceEpoch ~/ 1000,
        'role': 'organizer',
      });
      final signed = await SigningService.signEvent(
        kind: kind,
        tags: <List<String>>[
          ['d', key],
          ['role', 'organizer'],
          ['client', _client],
        ],
        content: content,
      );
      return await _publish(signed);
    } catch (e) {
      AppLogger.warn(_tag, 'Organisator-Publish fehlgeschlagen: $e');
      return 0;
    }
  }

  /// Baut das EIGENE Netzwerk auf — automatisch, ohne npub-Eingabe.
  ///
  /// Grad 1 = Leute, die ich auf Meetups getroffen habe (gemeinsamer Event).
  /// Grad 2 = deren Kontakte, die ich selbst noch nicht getroffen habe.
  /// Grad 3 = noch eine Ebene weiter.
  ///
  /// Für jeden Kontakt wird festgehalten, über WEN (Brücke, Grad-1-Kontakt)
  /// er erreichbar ist — das ist die Grundlage des transitiven Vertrauens.
  static Future<MyNetwork> buildMyNetwork({
    required String myNpub,
    int maxDepth = 3,
  }) async {
    final nodes = await _loadAllNodes();

    // Ungerichtete Adjazenz: A--B wenn sie >=1 Meetup teilen
    final adj = <String, Set<String>>{};
    final entries = nodes.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      for (int j = i + 1; j < entries.length; j++) {
        final a = entries[i];
        final b = entries[j];
        if (a.value.meetups.intersection(b.value.meetups).isNotEmpty) {
          adj.putIfAbsent(a.key, () => <String>{}).add(b.key);
          adj.putIfAbsent(b.key, () => <String>{}).add(a.key);
        }
      }
    }

    final myMeetups = nodes[myNpub]?.meetups ?? <String>{};

    // BFS: Grad pro npub + über welchen Grad-1-Kontakt erreichbar
    final degree = <String, int>{myNpub: 0};
    final bridges = <String, Set<String>>{}; // npub -> Grad-1-Brücken
    final queue = <String>[myNpub];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final curDeg = degree[current]!;
      if (curDeg >= maxDepth) continue;
      for (final neighbor in (adj[current] ?? const <String>{})) {
        if (!degree.containsKey(neighbor)) {
          degree[neighbor] = curDeg + 1;
          queue.add(neighbor);
        }
        // Brücke merken: der Grad-1-Knoten auf dem Weg
        if (curDeg == 0) {
          // direkter Nachbar -> er ist seine eigene "Brücke" (Grad 1)
        } else if (degree[neighbor] == curDeg + 1) {
          final via = (curDeg == 1) ? current : null;
          if (via != null) {
            bridges.putIfAbsent(neighbor, () => <String>{}).add(via);
          } else {
            // tiefer: Brücken des current weiterreichen
            final inherited = bridges[current];
            if (inherited != null) {
              bridges.putIfAbsent(neighbor, () => <String>{}).addAll(inherited);
            }
          }
        }
      }
    }

    // Kontakte nach Grad gruppieren
    final byDegree = <int, List<NetworkContact>>{1: [], 2: [], 3: []};
    for (final entry in degree.entries) {
      final npub = entry.key;
      final deg = entry.value;
      if (deg == 0 || deg > maxDepth) continue;

      Set<String> shared = <String>{};
      if (deg == 1) {
        shared = (nodes[npub]?.meetups ?? <String>{}).intersection(myMeetups);
      }

      byDegree.putIfAbsent(deg, () => []).add(NetworkContact(
            npub: npub,
            degree: deg,
            sharedMeetupsWithMe: shared,
            bridges: deg == 1 ? <String>{} : (bridges[npub] ?? <String>{}),
          ));
    }

    // ── DIAGNOSE ────────────────────────────────────────────────────
    // Erscheint jemand faelschlich im 1. Grad, laesst sich hier ablesen,
    // WELCHE Kennung die Verbindung erzeugt. Ohne diese Zeilen bleibt nur
    // Raten — die Kennung steckt weder in der Oberflaeche noch im Badge.
    AppLogger.diag('Netzwerk',
        'Eigene Meetup-Kennungen (${myMeetups.length}): '
        '${myMeetups.join(", ")}');
    for (final c in (byDegree[1] ?? const <NetworkContact>[])) {
      AppLogger.diag('Netzwerk',
          '1. Grad ${c.npub.substring(0, c.npub.length > 16 ? 16 : c.npub.length)}… '
          'ueber: ${c.sharedMeetupsWithMe.join(", ")}');
    }

    // Sortierung: Grad 1 nach Anzahl gemeinsamer Meetups, sonst nach Brücken-Anzahl
    byDegree[1]?.sort((a, b) =>
        b.sharedMeetupsWithMe.length.compareTo(a.sharedMeetupsWithMe.length));
    byDegree[2]?.sort((a, b) => b.bridges.length.compareTo(a.bridges.length));
    byDegree[3]?.sort((a, b) => b.bridges.length.compareTo(a.bridges.length));

    return MyNetwork(
      myNpub: myNpub,
      byDegree: byDegree,
      myMeetupCount: myMeetups.length,
    );
  }
}

/// Ein Kontakt im eigenen Netzwerk.
class NetworkContact {
  final String npub;
  final int degree;                    // 1, 2 oder 3
  final Set<String> sharedMeetupsWithMe; // nur bei Grad 1 befüllt
  final Set<String> bridges;           // Grad-1-Kontakte, über die ich diese Person erreiche (Grad 2+)

  NetworkContact({
    required this.npub,
    required this.degree,
    required this.sharedMeetupsWithMe,
    required this.bridges,
  });
}

/// Das gesamte eigene Netzwerk, nach Graden gruppiert.
class MyNetwork {
  final String myNpub;
  final Map<int, List<NetworkContact>> byDegree;
  final int myMeetupCount;

  MyNetwork({
    required this.myNpub,
    required this.byDegree,
    required this.myMeetupCount,
  });

  int get degree1Count => byDegree[1]?.length ?? 0;
  int get degree2Count => byDegree[2]?.length ?? 0;
  int get degree3Count => byDegree[3]?.length ?? 0;
  int get totalReach => degree1Count + degree2Count + degree3Count;
  bool get isEmpty => totalReach == 0;
}

/// Ergebnis eines Präsenz-Checks zu einer bestimmten Person.
class PresenceCheck {
  final String targetNpub;
  final int degree;              // 0=ich, 1=direkt, 2/3...=über Ecken, -1=keine Verbindung
  final List<String> path;       // konkreter Pfad [myNpub, ..., targetNpub]
  final Set<String> sharedMeetups; // gemeinsame Meetups (bei Grad 1)
  final bool targetInNetwork;    // nimmt die Zielperson überhaupt am Netzwerk teil?
  final int targetTotalMeetups;  // wie viele Meetups die Zielperson besucht hat

  PresenceCheck({
    required this.targetNpub,
    required this.degree,
    required this.path,
    required this.sharedMeetups,
    required this.targetInNetwork,
    required this.targetTotalMeetups,
  });

  bool get found => degree >= 0;
  bool get isDirect => degree == 1;
  bool get isSelf => degree == 0;
}
