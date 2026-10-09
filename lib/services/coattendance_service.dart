import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
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

  /// Meetup-Begegnungen. Der Kern des Vertrauensnetzwerks: kleine Runden,
  /// in denen man sich tatsaechlich getroffen hat.
  final Set<String> meetups;

  /// Event-Begegnungen — getrennt gefuehrt.
  ///
  /// Auf einem Meetup mit fuenfzehn Leuten trifft man jeden. Auf einem
  /// Event mit fuenfhundert nicht. Wuerden beide im selben Topf liegen,
  /// machte ein einziges Grossevent Tausende Menschen zu "direkten
  /// Begegnungen" und die Aussage des Netzwerks waere dahin.
  final Set<String> events;

  CoAttNode(this.npub)
      : meetups = <String>{},
        events = <String>{};

  /// Alles zusammen — fuer Ansichten, die beides zeigen wollen.
  Set<String> get all => {...meetups, ...events};

  /// Unabhaengige Kopie — der Cache darf beim Nachladen nicht mitwachsen.
  CoAttNode copy() => CoAttNode(npub)
    ..meetups.addAll(meetups)
    ..events.addAll(events);
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
  /// Praefix fuer Event-Anwesenheiten. Es steht VOR dem Schluessel, damit
  /// beim Einlesen ohne Zusatzwissen erkennbar ist, in welchen Topf ein
  /// Eintrag gehoert — die Relay-Daten tragen sonst keinen Typ.
  static const String eventPrefix = 'ev|';

  static bool isEventKey(String key) => key.startsWith(eventPrefix);

  /// Anwesenheitsschluessel.
  ///
  /// Bei MEETUPS haengt der Signierer mit dran. Grund: Zwei unabhaengige
  /// Sitzungen mit demselben Namen und Datum — jeder Entwickler legt
  /// irgendwann eine "test"-Session an — wuerden sonst Fremde miteinander
  /// verknuepfen. Das ist im Feld passiert und war der Anlass fuer diese
  /// Ergaenzung.
  ///
  /// Bei EVENTS faellt er weg, und zwar aus zwei Gruenden. Erstens ist die
  /// Gefahr nicht gegeben: In der Event-Adresse steckt der Pubkey des
  /// Erstellers, sie ist also von Natur aus eindeutig — ein zweites
  /// "Blocktrainer Event" von jemand anderem hat einen anderen Schluessel.
  /// Zweitens gehoert es zur Sache: Ein Event IST ein Event, egal bei
  /// welchem Helfer man gescannt hat. Ohne diese Zusammenfassung zerfiele
  /// eine Veranstaltung in so viele Gruppen, wie Helfer im Einsatz waren.
  /// Gemeinsame Kennungen zweier Teilnehmer.
  ///
  /// Nicht einfach `intersection`, weil ZWEI FORMATE nebeneinander im Netz
  /// liegen:
  ///
  ///   aschaffenburg-2026-06-03                 (alt, ohne Signierer)
  ///   aschaffenburg-2026-06-03@u8qf5q534jzc    (neu, mit Signierer)
  ///
  /// Der Anhang kam spaeter dazu, um zwei Organisatoren am selben Abend
  /// auseinanderzuhalten. Aeltere Badges tragen keinen Signierer, und ein
  /// exakter Vergleich laesst beide Formate aneinander vorbeilaufen — genau
  /// deshalb blieb das Netzwerk bei Bestaenden aus der Zeit davor leer.
  ///
  /// Regel: Gleich ist gleich. Fehlt EINER Seite der Anhang, entscheidet der
  /// Teil davor. Haben BEIDE einen Anhang, muss er uebereinstimmen — sonst
  /// waren es verschiedene Sessions, und die Unterscheidung bliebe wertlos.
  static Set<String> sharedKeys(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return <String>{};

    String base(String k) {
      final i = k.indexOf('@');
      return i < 0 ? k : k.substring(0, i);
    }

    final out = <String>{};
    for (final x in a) {
      final xb = base(x);
      final xHasSigner = x.length != xb.length;
      for (final y in b) {
        if (x == y) {
          out.add(x);
          continue;
        }
        final yb = base(y);
        if (xb != yb) continue;
        // Nur wenn mindestens eine Seite aus der Zeit ohne Anhang stammt.
        final yHasSigner = y.length != yb.length;
        if (!xHasSigner || !yHasSigner) out.add(xb);
      }
    }
    return out;
  }

  static String attendanceKey(
    String meetupEventId,
    String signerNpub, {
    bool isEvent = false,
  }) {
    if (isEvent) return '$eventPrefix$meetupEventId';

    final signer = signerNpub.trim();
    if (signer.isEmpty) return meetupEventId; // Altformat, besser als nichts
    final short = signer.length > 12 ? signer.substring(signer.length - 12) : signer;
    return '$meetupEventId@$short';
  }

  // ============================================
  // VEROEFFENTLICHUNGSSTATUS (Issue #57, Punkt 5)
  // ============================================
  //
  // Wer beim Scannen zustimmt, dass seine Teilnahme ins Netzwerk geht, soll
  // erfahren, ob das geklappt hat — und es wiederholen koennen.
  //
  // Vorher: Schlug die Veroeffentlichung fehl, zeigte die App NICHTS. Die
  // Erfolgsmeldung kam nur bei Erfolg, der Fehlschlag verschwand still, und
  // es gab keinen Weg, es spaeter nachzuholen. Die Teilnahme fehlte im
  // Netzwerk fuer immer.
  //
  // Gespeichert wird je Badge-Signatur die Zahl der Relays, die angenommen
  // haben. 0 heisst: zugestimmt, aber nicht angekommen. Nicht gespeichert =
  // nie zugestimmt — das bleibt eine freie Entscheidung und wird nicht als
  // Fehler gezaehlt.

  static const String _statusKey = 'coatt_publish_status';

  static Future<Map<String, int>> publishStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_statusKey);
      if (raw == null) return {};
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, v is int ? v : 0));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveStatus(String sigId, int relays) async {
    if (sigId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await publishStatus();
      current[sigId] = relays;
      await prefs.setString(_statusKey, jsonEncode(current));
    } catch (_) {}
  }

  /// Badges, deren Veroeffentlichung zugestimmt wurde, aber fehlschlug.
  static Future<List<MeetupBadge>> failedBadges(List<MeetupBadge> all) async {
    final status = await publishStatus();
    return all.where((b) => status[b.sigId] == 0).toList();
  }

  /// Versucht alle fehlgeschlagenen erneut. Gibt zurueck, wie viele jetzt
  /// angekommen sind.
  static Future<int> retryFailed(List<MeetupBadge> all) async {
    final failed = await failedBadges(all);
    var fixed = 0;
    for (final b in failed) {
      if (await publishAttendance(b) > 0) fixed++;
    }
    AppLogger.info(_tag,
        'Erneut veroeffentlicht: $fixed von ${failed.length} Teilnahmen.');
    return fixed;
  }

  static Future<int> publishAttendance(MeetupBadge badge) async {
    // Sicherheit: nur echte, organisator-signierte Badges qualifizieren
    if (!badge.isNostrSigned || _isDegenerateEventId(badge.meetupEventId)) {
      AppLogger.warn(_tag, 'Badge nicht qualifiziert (nicht Nostr-signiert)');
      return 0;
    }

    try {
      final key = attendanceKey(badge.meetupEventId, badge.signerNpub,
          isEvent: badge.isEvent);

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

      final n = await _publish(signed);
      await _saveStatus(badge.sigId, n);
      return n;
    } catch (e) {
      AppLogger.warn(_tag, 'Publish-Fehler: $e');
      // Auch der Fehlschlag wird festgehalten — sonst taucht er in der
      // Liste der erneut zu sendenden gar nicht erst auf.
      await _saveStatus(badge.sigId, 0);
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

    // Alle Relays GLEICHZEITIG, und gezaehlt wird nur, was ein Relay mit
    // ["OK", <id>, true, …] bestaetigt hat.
    //
    // Vorher: senden, zwei Sekunden warten, schliessen, ok++. Ein Relay, das
    // das Ereignis ABGEWIESEN hatte — falsches Format, Rate-Limit,
    // Anmeldung verlangt —, zaehlte als Erfolg. Die App meldete
    // "veroeffentlicht", und die Teilnahme fehlte danach im Netzwerk ohne
    // jeden Hinweis (Issue #57, Punkt 3).
    final results = await Future.wait(relays.map((relayUrl) async {
      RelaySocket? ws;
      try {
        ws = await RelaySocket.connect(relayUrl)
            .timeout(RelayConfig.publishTimeout);
        final done = Completer<bool>();
        ws.listen((data) {
          try {
            final msg = jsonDecode(data as String) as List<dynamic>;
            if (msg.length >= 3 && msg[0] == 'OK' && msg[1] == event.id) {
              final accepted = msg[2] == true;
              if (!accepted) {
                AppLogger.warn(_tag,
                    '$relayUrl hat abgelehnt: ${msg.length >= 4 ? msg[3] : "ohne Grund"}');
              }
              if (!done.isCompleted) done.complete(accepted);
            }
          } catch (_) {}
        }, onError: (_) {
          if (!done.isCompleted) done.complete(false);
        }, onDone: () {
          if (!done.isCompleted) done.complete(false);
        });
        ws.add(eventJson);
        // Keine Antwort binnen der Frist zaehlt als NICHT angenommen — eine
        // Stille ist keine Zusage.
        return await done.future
            .timeout(const Duration(seconds: 6), onTimeout: () {
          AppLogger.warn(_tag, '$relayUrl: keine Bestaetigung erhalten.');
          return false;
        });
      } catch (e) {
        AppLogger.warn(_tag, '$relayUrl fehlgeschlagen: $e');
        return false;
      } finally {
        try {
          ws?.close();
        } catch (_) {}
      }
    }));

    final ok = results.where((r) => r).length;
    AppLogger.diag(_tag,
        'Teilnahme ${event.id.substring(0, 8)}…: $ok von ${relays.length} Relays haben angenommen.');
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

  /// Obergrenzen je Nachladestufe.
  ///
  /// Ohne sie wuechse jede Stufe mit der Netzwerkgroesse: Wer zwanzig Meetups
  /// besucht hat, bei denen je dreissig Leute waren, deren jeder weitere
  /// zwanzig Meetups hat … Die Grenzen halten Relays und Ladezeit im Rahmen.
  /// Wird eine erreicht, steht es im Log — abgeschnitten wird NIE still.
  static const int _maxMeetupsPerStage = 60;
  static const int _maxPeoplePerStage = 300;

  /// Wie viele Autoren eine Abfrage hoechstens enthaelt. Manche Relays
  /// begrenzen die Filtergroesse und antworten sonst gar nicht.
  static const int _authorBatch = 100;

  /// Wie viele Meetup-Kennungen eine Abfrage hoechstens enthaelt. Jede
  /// zaehlt doppelt (mit und ohne Signierer-Anhang).
  static const int _keyBatch = 60;

  /// Wie viele Abfrage-Pakete gleichzeitig laufen. Jedes Paket geht an alle
  /// Relays — drei Pakete sind bei vier Relays schon zwoelf Verbindungen.
  /// Mehr bringt kaum Tempo, aber Relays mit Rate-Limit antworten dann gar
  /// nicht mehr.
  static const int _parallelBatches = 3;

  /// Nach dieser Zeit wird einmal alles neu geholt statt nur das Neue.
  /// Nur so faellt auf, wenn eine Teilnahme von den Relays verschwunden ist.
  static const Duration _fullSyncEvery = Duration(hours: 24);

  /// Ueberlappung beim inkrementellen Abruf. Eine Teilnahme kann etwas
  /// spaeter beim Relay ankommen, als ihr Zeitstempel sagt (langsames Netz,
  /// Signierer-App). Ohne Puffer fiele sie genau zwischen zwei Abrufe.
  static const Duration _sinceOverlap = Duration(hours: 1);

  static const String _cacheKey = 'coatt_graph_cache_v1';

  // ============================================
  // NETZWERK-CACHE
  // ============================================
  //
  // Gespeichert wird der VERBINDUNGSGRAPH (wer war bei welchem Meetup),
  // nicht die fertigen Grade. Die Grade werden bei jedem Oeffnen per
  // Breitensuche neu berechnet.
  //
  // Grund: Grade aendern sich, ohne dass sich an der Person selbst etwas
  // aendert. War der Weg vorher Ich → A → B → C und bin ich inzwischen mit
  // B auf einem Meetup gewesen, ist B jetzt Grad 1 und C Grad 2. Gespeicherte
  // Grade wuessten davon nichts; der Graph liefert es von selbst.

  static String _base(String k) {
    final i = k.indexOf('@');
    return i < 0 ? k : k.substring(0, i);
  }

  /// Dieselbe Regel wie [sharedKeys], fuer zwei einzelne Kennungen.
  static bool _keysMatch(String a, String b) {
    if (a == b) return true;
    final ab = _base(a);
    final bb = _base(b);
    if (ab != bb) return false;
    return a.length == ab.length || b.length == bb.length;
  }

  /// Kennungen fuer die Relay-Abfrage: jede auch OHNE Signierer-Anhang,
  /// weil aeltere Teilnahmen in dem Format veroeffentlicht wurden.
  static Set<String> _wantedKeys(Iterable<String> keys) {
    final wanted = <String>{};
    for (final k in keys) {
      wanted.add(k);
      final b = _base(k);
      if (b.length != k.length && b.isNotEmpty) wanted.add(b);
    }
    return wanted;
  }

  static Future<_GraphCache?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      return _GraphCache.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // Kaputter Cache ist kein Fehler — dann wird eben alles neu geholt.
      AppLogger.warn('Netzwerk', 'Cache nicht lesbar, wird neu aufgebaut: $e');
      return null;
    }
  }

  static Future<void> _writeCache(_GraphCache cache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(cache.toJson()));
    } catch (e) {
      AppLogger.warn('Netzwerk', 'Cache nicht gespeichert: $e');
    }
  }

  /// Fuehrt die Aufgaben aus, hoechstens [max] gleichzeitig.
  static Future<void> _runLimited(
      List<Future<void> Function()> tasks, int max) async {
    if (tasks.isEmpty) return;
    var next = 0;
    Future<void> worker() async {
      while (next < tasks.length) {
        final i = next++;
        await tasks[i]();
      }
    }

    await Future.wait(List.generate(min(max, tasks.length), (_) => worker()));
  }

  /// Fragt ALLE Relays gleichzeitig und entdoppelt.
  static Future<_BatchAnswer> _queryRelays(
    List<String> relays, {
    Set<String>? keys,
    List<String>? authorsHex,
    int? since,
  }) async {
    final answers = await Future.wait(relays.map((url) => _fetchFromRelay(url,
        myKeys: keys, authorsHex: authorsHex, since: since)));
    final seen = <String>{};
    final out = <CoAttendanceRecord>[];
    var any = false;
    var all = relays.isNotEmpty;
    for (final a in answers) {
      if (a == null) {
        all = false;
        continue;
      }
      if (a.complete) {
        any = true;
      } else {
        all = false;
      }
      for (final r in a.records) {
        if (seen.add('${r.npub}|${r.meetupEventId}')) out.add(r);
      }
    }
    return _BatchAnswer(out, anyComplete: any, allComplete: all);
  }

  /// Baut den Verbindungsgraphen GRADWEISE auf.
  ///
  /// ============================================
  /// WARUM GESTAFFELT (Issue #57, Punkt 1)
  /// ============================================
  ///
  /// Frueher gab es zwei falsche Extreme:
  ///
  ///   - Alles holen, ungefiltert, Limit 500: Bei einem gewachsenen Netzwerk
  ///     kamen irgendwelche fremden Meetups an, aber nicht die eigenen.
  ///   - Nur die EIGENEN Meetups holen (die Korrektur danach): Grad 1
  ///     funktionierte wieder, aber die WEITEREN Meetups der Kontakte fehlten.
  ///     Eine Kette ich – B (gemeinsam bei X) – C (B und C bei Y) liess sich
  ///     so nie bilden, solange ich nicht selbst bei Y war. Grad 2 und 3
  ///     blieben leer, egal wie viele Meetups man besuchte.
  ///
  /// Jetzt wird nur geholt, was fuer die naechste Stufe gebraucht wird:
  ///
  ///   eigene Teilnahmen
  ///     → Teilnehmer dieser Meetups                     (Grad 1)
  ///     → deren weitere Teilnahmen
  ///     → Teilnehmer DIESER Meetups                     (Grad 2)
  ///     → deren weitere Teilnahmen
  ///     → Teilnehmer dieser Meetups                     (Grad 3)
  ///
  /// ============================================
  /// MIT CACHE (inkrementell)
  /// ============================================
  ///
  /// Ist [cache] gesetzt und [fullSync] aus, startet der Graph mit dem
  /// gespeicherten Stand. Personen und Meetups, die schon einmal VOLLSTAENDIG
  /// abgefragt wurden, werden nur noch nach Neuem seit dem letzten Abruf
  /// gefragt (`since`). Unbekannte werden ganz geholt. Die Stufen bleiben
  /// dieselben — nur die Antworten werden viel kleiner.
  ///
  /// Beim vollstaendigen Abruf startet der Graph leer, damit verschwundene
  /// Teilnahmen auch verschwinden. Ausnahme: Hat nicht JEDES Relay
  /// vollstaendig geantwortet, bleibt fuer die betroffenen Personen und
  /// Meetups der gespeicherte Stand erhalten. Ein haengendes Relay soll
  /// keine Verbindungen loeschen.
  ///
  /// Innerhalb eines Durchlaufs wird keine Person und kein Meetup zweimal
  /// abgefragt. Die Pakete einer Stufe laufen parallel, hoechstens
  /// [_parallelBatches] auf einmal.
  ///
  /// [extraNpubs] werden wie der eigene Schluessel als Ausgangspunkt
  /// behandelt — fuer die Pruefung einer bestimmten Person muessen DEREN
  /// Teilnahmen dabei sein, auch wenn sie weiter als drei Stufen entfernt ist.
  ///
  /// Veranstaltungen gehen in die Knoten ein, dienen aber NICHT zum
  /// Weiterhangeln: Bei fuenfhundert Besuchern ist gemeinsame Anwesenheit
  /// keine Begegnung, und der Graph wuerde sonst ueber jedes Grossevent
  /// explodieren.
  ///
  /// [onStage] wird nach jeder abgeschlossenen Stufe mit dem bisherigen
  /// Graphen aufgerufen — die Anzeige kann Grad fuer Grad nachziehen.
  static Future<_GraphRun> _loadGraph({
    required String myNpub,
    List<String> extraNpubs = const [],
    int maxDepth = 3,
    _GraphCache? cache,
    bool fullSync = true,
    void Function(Map<String, CoAttNode> graph, int depth)? onStage,
  }) async {
    final relays = await RelayConfig.getActiveRelays();
    // Startpunkt des inkrementellen Abrufs — null beim vollstaendigen.
    final start = (cache != null && !fullSync) ? cache : null;
    final incremental = start != null;

    final graph = <String, CoAttNode>{};
    final knownAuthors = <String>{};
    final knownKeys = <String>{};
    int? since;
    if (start != null) {
      start.nodes.forEach((k, v) => graph[k] = v.copy());
      knownAuthors.addAll(start.knownAuthors);
      knownKeys.addAll(start.knownKeys);
      since = (start.syncAt ~/ 1000) - _sinceOverlap.inSeconds;
    }

    var batchesTotal = 0;
    var batchesAnswered = 0;
    var recordsFetched = 0;

    void add(CoAttendanceRecord r) {
      // Fehl-Kennungen ueberspringen — sonst entstehen Verknuepfungen
      // zwischen Leuten, die sich nie begegnet sind.
      if (_isDegenerateEventId(r.meetupEventId)) return;
      final node = graph.putIfAbsent(r.npub, () => CoAttNode(r.npub));
      if (isEventKey(r.meetupEventId)) {
        node.events.add(r.meetupEventId);
      } else {
        node.meetups.add(r.meetupEventId);
      }
    }

    // Gespeicherten Stand fuer Personen behalten, deren Abruf unvollstaendig
    // war. Im inkrementellen Modus steckt er ohnehin schon im Graphen.
    void keepCachedAuthors(Iterable<String> npubs) {
      if (cache == null) return;
      for (final n in npubs) {
        final c = cache.nodes[n];
        if (c == null) continue;
        final node = graph.putIfAbsent(n, () => CoAttNode(n));
        node.meetups.addAll(c.meetups);
        node.events.addAll(c.events);
      }
    }

    void keepCachedKeys(Set<String> wanted) {
      if (cache == null) return;
      cache.nodes.forEach((npub, c) {
        final hits = c.meetups.where(wanted.contains);
        if (hits.isEmpty) return;
        graph.putIfAbsent(npub, () => CoAttNode(npub)).meetups.addAll(hits);
      });
    }

    String? toHex(String npub) {
      try {
        return Nip19.decodePubkey(npub);
      } catch (_) {
        return null;
      }
    }

    // Personen abfragen: bekannte nur nach Neuem, unbekannte ganz.
    Future<void> fetchAuthors(Iterable<String> npubs) async {
      final known = <String>[];
      final fresh = <String>[];
      for (final n in npubs) {
        (knownAuthors.contains(n) ? known : fresh).add(n);
      }
      final tasks = <Future<void> Function()>[];
      void plan(List<String> group, int? sinceArg) {
        for (var k = 0; k < group.length; k += _authorBatch) {
          final part = group.sublist(k, min(k + _authorBatch, group.length));
          final hexes = part.map(toHex).whereType<String>().toList();
          if (hexes.isEmpty) continue;
          tasks.add(() async {
            batchesTotal++;
            final res = await _queryRelays(relays,
                authorsHex: hexes, since: sinceArg);
            res.records.forEach(add);
            recordsFetched += res.records.length;
            if (res.anyComplete) batchesAnswered++;
            if (!res.allComplete) keepCachedAuthors(part);
            if (res.anyComplete) {
              knownAuthors.addAll(part);
            } else {
              // Naechstes Mal komplett — sonst fiele das Fenster weg.
              knownAuthors.removeAll(part);
            }
          });
        }
      }

      plan(known, since);
      plan(fresh, null);
      await _runLimited(tasks, _parallelBatches);
    }

    // Meetups abfragen: Wer war dort? Bekannte nur nach Neuem.
    Future<void> fetchKeys(Set<String> keys) async {
      final known = <String>[];
      final fresh = <String>[];
      for (final k in keys) {
        (knownKeys.contains(k) ? known : fresh).add(k);
      }
      final tasks = <Future<void> Function()>[];
      void plan(List<String> group, int? sinceArg) {
        for (var k = 0; k < group.length; k += _keyBatch) {
          final part = group.sublist(k, min(k + _keyBatch, group.length)).toSet();
          tasks.add(() async {
            batchesTotal++;
            final res =
                await _queryRelays(relays, keys: part, since: sinceArg);
            res.records.forEach(add);
            recordsFetched += res.records.length;
            if (res.anyComplete) batchesAnswered++;
            if (!res.allComplete) keepCachedKeys(_wantedKeys(part));
            if (res.anyComplete) {
              knownKeys.addAll(part);
            } else {
              knownKeys.removeAll(part);
            }
          });
        }
      }

      plan(known, since);
      plan(fresh, null);
      await _runLimited(tasks, _parallelBatches);
    }

    // Teilnehmer der Meetups [keys] laut aktuellem Graphen — mit derselben
    // toleranten Regel wie [sharedKeys], damit Alt- und Neuformat sich finden.
    Set<String> peopleAt(Set<String> keys) {
      final byBase = <String, List<String>>{};
      for (final q in keys) {
        byBase.putIfAbsent(_base(q), () => <String>[]).add(q);
      }
      final out = <String>{};
      graph.forEach((npub, node) {
        for (final k in node.meetups) {
          final qs = byBase[_base(k)];
          if (qs != null && qs.any((q) => _keysMatch(k, q))) {
            out.add(npub);
            return;
          }
        }
      });
      return out;
    }

    Set<String> meetupKeysOf(Iterable<String> npubs) => {
          for (final n in npubs) ...?graph[n]?.meetups,
        };

    final seeds = <String>{myNpub, ...extraNpubs}
        .where((n) => toHex(n) != null)
        .toList();
    if (seeds.isEmpty || relays.isEmpty) {
      return _GraphRun(graph, knownAuthors, knownKeys,
          answered: false);
    }

    // --- Stufe 0: eigene Teilnahmen (und die der zu pruefenden Person) ---
    await fetchAuthors(seeds);

    final seenPeople = <String>{...seeds};
    final seenKeys = <String>{};
    var frontierKeys = meetupKeysOf(seeds);

    AppLogger.diag('Netzwerk',
        'Stufe 0: ${frontierKeys.length} eigene Meetups '
        '(${incremental ? "nur Neues seit letztem Abruf" : "vollstaendig"}).');

    for (var depth = 1; depth <= maxDepth; depth++) {
      frontierKeys = frontierKeys.difference(seenKeys);
      if (frontierKeys.isEmpty) break;

      var keys = frontierKeys;
      if (keys.length > _maxMeetupsPerStage) {
        AppLogger.warn('Netzwerk',
            'Grad $depth: ${keys.length} Meetups, begrenzt auf $_maxMeetupsPerStage.');
        keys = keys.take(_maxMeetupsPerStage).toSet();
      }
      seenKeys.addAll(keys);

      // Wer war bei diesen Meetups?
      await fetchKeys(keys);

      var newPeople = peopleAt(keys).difference(seenPeople);
      if (newPeople.length > _maxPeoplePerStage) {
        AppLogger.warn('Netzwerk',
            'Grad $depth: ${newPeople.length} Personen, begrenzt auf $_maxPeoplePerStage.');
        newPeople = newPeople.take(_maxPeoplePerStage).toSet();
      }
      seenPeople.addAll(newPeople);

      AppLogger.diag('Netzwerk',
          'Grad $depth: ${keys.length} Meetups abgefragt, ${newPeople.length} neue Personen.');

      onStage?.call(graph, depth);

      if (depth == maxDepth || newPeople.isEmpty) break;

      // Wo waren diese Personen sonst noch?
      await fetchAuthors(newPeople);
      frontierKeys = meetupKeysOf(newPeople);
    }

    AppLogger.diag('Netzwerk',
        'Abruf: $batchesAnswered von $batchesTotal Paketen beantwortet, '
        '$recordsFetched Eintraege geladen, ${graph.length} Personen im Graphen.');

    return _GraphRun(graph, knownAuthors, knownKeys,
        answered: batchesAnswered > 0);
  }

  /// Kompatibel zu den Aufrufern ohne Cache (Pruefung einer Person).
  static Future<Map<String, CoAttNode>> _loadAllNodes({
    required String myNpub,
    List<String> extraNpubs = const [],
    int maxDepth = 3,
  }) async {
    final run = await _loadGraph(
        myNpub: myNpub, extraNpubs: extraNpubs, maxDepth: maxDepth);
    return run.graph;
  }

  /// Ungerichtete Nachbarschaft: A–B, wenn sie mindestens ein Meetup teilen.
  ///
  /// Gruppiert nach Kennung statt jeden mit jedem zu vergleichen. Der
  /// paarweise Vergleich wuchs quadratisch mit der Zahl der Personen und
  /// wurde bei tausend Knoten auf dem Handy spuerbar — jetzt, wo die
  /// Anzeige nach jeder Stufe neu rechnet, erst recht.
  static Map<String, Set<String>> _adjacency(Map<String, CoAttNode> nodes) {
    final groups = <String, List<MapEntry<String, String>>>{};
    nodes.forEach((npub, node) {
      for (final k in node.meetups) {
        groups
            .putIfAbsent(_base(k), () => <MapEntry<String, String>>[])
            .add(MapEntry(npub, k));
      }
    });
    final adj = <String, Set<String>>{};
    for (final g in groups.values) {
      for (var i = 0; i < g.length; i++) {
        for (var j = i + 1; j < g.length; j++) {
          final a = g[i];
          final b = g[j];
          if (a.key == b.key) continue;
          if (!_keysMatch(a.value, b.value)) continue;
          adj.putIfAbsent(a.key, () => <String>{}).add(b.key);
          adj.putIfAbsent(b.key, () => <String>{}).add(a.key);
        }
      }
    }
    return adj;
  }

  static Future<_RelayAnswer?> _fetchFromRelay(
    String relayUrl, {
    Set<String>? myKeys,
    List<String>? authorsHex,
    int? since,
  }) async {
    RelaySocket? ws;
    final tally = RelayParseTally('CoAttendance', 'Co-Attendance von $relayUrl');
    final out = <CoAttendanceRecord>[];
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final random = Random.secure();
      final subId = 'coatt-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
      // true = EOSE erhalten, false = Verbindung vorher zu, null = Fehler.
      final completer = Completer<bool?>();

      ws.listen(
        (data) {
          tally.message();
          try {
            final msg = jsonDecode(data as String) as List<dynamic>;
            if (msg[0] == 'EVENT' && msg.length >= 3) {
              final ev = RelaySocket.verifiedEvent(msg[2], tag: 'CoAttendance');
              if (ev == null) return;
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
              if (!completer.isCompleted) completer.complete(true);
            }
          } catch (e) { tally.failed(e); }
        },
        onDone: () { if (!completer.isCompleted) completer.complete(false); },
        onError: (_) { if (!completer.isCompleted) completer.complete(null); },
      );

      final filter = <String, dynamic>{'kinds': [kind]};
      if (authorsHex != null && authorsHex.isNotEmpty) {
        filter['authors'] = authorsHex;
        // Bis zu hundert Personen je Abfrage, jede mit etlichen Teilnahmen —
        // 500 waren dafuer zu knapp und schnitten still ab (Issue #57,
        // Punkt 4). 5000 reicht fuer den Normalfall; wird es erreicht,
        // meldet das Log es weiter unten.
        filter['limit'] = 5000;
      } else if (myKeys != null && myKeys.isNotEmpty) {
        // Gezielt nach den Kennungen fragen — und nach denen OHNE
        // Signierer-Anhang gleich mit, weil aeltere Teilnahmen in dem Format
        // veroeffentlicht wurden und sonst durchs Raster fielen.
        filter['#d'] = _wantedKeys(myKeys).toList();
        // Grosszuegiges Limit: Bei einem gut besuchten Meetup kommen leicht
        // dreissig Teilnahmen je Termin zusammen.
        filter['limit'] = 1000;
      }
      if (since != null && since > 0) filter['since'] = since;
      ws.add(jsonEncode(['REQ', subId, filter]));

      final state = await completer.future.timeout(
        _timeout,
        onTimeout: () {
          // Teilmenge statt nichts — aber NICHT stillschweigend.
          //
          // Vorher kam ein halber Abruf zurueck, als waere er vollstaendig.
          // Im Netzwerk fehlten dann Kontakte, und niemand konnte sehen,
          // dass nur die Zeit abgelaufen war (Issue #57, Punkt 4).
          if (out.isNotEmpty) {
            AppLogger.warn(_tag,
                '$relayUrl: Zeit abgelaufen, ${out.length} Eintraege erhalten — Ergebnis moeglicherweise unvollstaendig.');
          }
          return null;
        },
      );
      ws.add(jsonEncode(['CLOSE', subId]));

      if (state == null && out.isEmpty) return null;

      // Limit erreicht heisst: Es gibt vermutlich mehr, als geliefert wurde.
      final limit = filter['limit'];
      final hitLimit = limit is int && out.length >= limit;
      if (hitLimit) {
        AppLogger.warn(_tag,
            '$relayUrl: Limit von $limit erreicht — es gibt vermutlich weitere Eintraege.');
      }
      return _RelayAnswer(out, complete: state == true && !hitLimit);
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
    final nodes = await _loadAllNodes(myNpub: myNpub, extraNpubs: [targetNpub]);

    final myNode = nodes[myNpub];
    final targetNode = nodes[targetNpub];

    final myMeetups = myNode?.meetups ?? <String>{};
    final targetMeetups = targetNode?.meetups ?? <String>{};

    // Gemeinsame Meetups (ich + Ziel)
    final shared = sharedKeys(myMeetups, targetMeetups);

    // Gemeinsame Kontakte: andere npubs, die mit BEIDEN je ein Meetup teilen
    final mutual = <String>[];
    for (final entry in nodes.entries) {
      final npub = entry.key;
      if (npub == myNpub || npub == targetNpub) continue;
      final m = entry.value.meetups;
      final withMe = sharedKeys(m, myMeetups).isNotEmpty;
      final withTarget = sharedKeys(m, targetMeetups).isNotEmpty;
      if (withMe && withTarget) mutual.add(npub);
    }

    // Reichweite der Zielperson: mit wie vielen verschiedenen Leuten war sie?
    final targetContacts = <String>{};
    for (final entry in nodes.entries) {
      if (entry.key == targetNpub) continue;
      if (sharedKeys(entry.value.meetups, targetMeetups).isNotEmpty) {
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
    // Die Pruefung braucht die Teilnahmen der Zielperson — deshalb als
    // zweiter Ausgangspunkt. Tiefer als drei Stufen wird nicht geladen,
    // auch wenn die Suche weiter reicht: Die Kette ergibt sich von beiden
    // Enden her.
    final nodes = await _loadAllNodes(
        myNpub: myNpub, extraNpubs: [targetNpub], maxDepth: 3);

    final myMeetups = nodes[myNpub]?.meetups ?? <String>{};
    final targetMeetups = nodes[targetNpub]?.meetups ?? <String>{};
    final sharedMeetups = sharedKeys(myMeetups, targetMeetups);

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
    final adj = _adjacency(nodes);

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
    /// Event statt Meetup. Muss durchgereicht werden, sonst landete der
    /// Helfer selbst im Meetup-Graphen, waehrend alle, die bei ihm gescannt
    /// haben, im Event-Graphen sitzen — er waere von seinen eigenen
    /// Teilnehmern getrennt.
    bool isEvent = false,
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
        isEvent: isEvent,
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
      await _publishOrganizerAttendance(meetupEventId, meetupName, date,
          isEvent: isEvent);

      return badge;
    } catch (e) {
      AppLogger.warn(_tag, 'Organisator-Teilnahme fehlgeschlagen: $e');
      return null;
    }
  }

  static Future<int> _publishOrganizerAttendance(
      String meetupEventId, String meetupName, DateTime date,
      {bool isEvent = false}) async {
    // Der Organisator IST der Signierer seiner eigenen Session — damit
    // stimmt sein Schluessel mit dem seiner Teilnehmer ueberein.
    final ownNpub = await SigningService.npub();
    final key =
        attendanceKey(meetupEventId, ownNpub ?? '', isEvent: isEvent);
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

  /// Laufender Netzwerk-Aufbau. Oeffnet jemand den Bildschirm erneut oder
  /// zieht zum Aktualisieren, waehrend noch geladen wird, haengt er sich an
  /// den laufenden Durchlauf an, statt dieselben Abfragen ein zweites Mal
  /// an die Relays zu schicken.
  static _NetworkJob? _job;

  /// Das Netzwerk aus dem gespeicherten Graphen — ohne Relay-Abfrage.
  ///
  /// Fuer die sofortige Anzeige beim Oeffnen. Null, wenn nichts gespeichert
  /// ist oder der Cache zu einem anderen Schluessel gehoert.
  static Future<MyNetwork?> cachedNetwork({
    required String myNpub,
    int maxDepth = 3,
  }) async {
    final cache = await _readCache();
    if (cache == null || cache.owner != myNpub) return null;
    return _networkFromGraph(myNpub, cache.nodes, maxDepth,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(cache.syncAt));
  }

  /// Baut das EIGENE Netzwerk auf — automatisch, ohne npub-Eingabe.
  ///
  /// Grad 1 = Leute, die ich auf Meetups getroffen habe (gemeinsamer Event).
  /// Grad 2 = deren Kontakte, die ich selbst noch nicht getroffen habe.
  /// Grad 3 = noch eine Ebene weiter.
  ///
  /// Für jeden Kontakt wird festgehalten, über WEN (Brücke, Grad-1-Kontakt)
  /// er erreichbar ist — das ist die Grundlage des transitiven Vertrauens.
  ///
  /// Ablauf mit Cache:
  ///   Cache lesen → Grad 1 aktualisieren → Grad 2 → Grad 3
  ///   → Grade aus dem Graphen neu berechnen → Cache speichern.
  ///
  /// [onStage] meldet nach jeder Stufe ein Zwischenergebnis. Beim
  /// vollstaendigen Abruf stammen die noch nicht erneuerten Grade dabei aus
  /// dem Cache — sonst verschwaenden Grad 2 und 3 kurz, waehrend Grad 1 laedt.
  ///
  /// [forceFull] erzwingt den vollstaendigen Abruf (Herunterziehen zum
  /// Aktualisieren). Sonst geschieht das einmal am Tag von selbst.
  static Future<MyNetwork> buildMyNetwork({
    required String myNpub,
    int maxDepth = 3,
    bool forceFull = false,
    void Function(MyNetwork net, int doneDepth)? onStage,
  }) {
    final running = _job;
    if (running != null && running.owner == myNpub) {
      if (onStage != null) running.listeners.add(onStage);
      AppLogger.diag('Netzwerk', 'Aufbau laeuft bereits — schliesse mich an.');
      return running.future;
    }

    final job = _NetworkJob(myNpub);
    if (onStage != null) job.listeners.add(onStage);
    _job = job;
    job.future = _buildMyNetwork(
      myNpub: myNpub,
      maxDepth: maxDepth,
      forceFull: forceFull,
      emit: (net, d) {
        for (final l in List.of(job.listeners)) {
          try {
            l(net, d);
          } catch (_) {}
        }
      },
    ).whenComplete(() {
      if (identical(_job, job)) _job = null;
    });
    return job.future;
  }

  static Future<MyNetwork> _buildMyNetwork({
    required String myNpub,
    required int maxDepth,
    required bool forceFull,
    required void Function(MyNetwork net, int doneDepth) emit,
  }) async {
    final startedAt = DateTime.now().millisecondsSinceEpoch;
    final stored = await _readCache();
    final cache = (stored != null && stored.owner == myNpub) ? stored : null;
    final previous = cache == null
        ? null
        : _networkFromGraph(myNpub, cache.nodes, maxDepth,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(cache.syncAt));

    final fullSync = forceFull ||
        cache == null ||
        startedAt - cache.fullSyncAt > _fullSyncEvery.inMilliseconds;

    final incremental = cache != null && !fullSync;

    AppLogger.diag('Netzwerk',
        cache == null
            ? 'Kein Cache — baue vollstaendig auf.'
            : '${fullSync ? "Vollstaendiger" : "Inkrementeller"} Abruf, '
                'Cache mit ${cache.nodes.length} Personen.');

    final run = await _loadGraph(
      myNpub: myNpub,
      maxDepth: maxDepth,
      cache: cache,
      fullSync: fullSync,
      onStage: (graph, depth) {
        final fresh = _networkFromGraph(myNpub, graph, maxDepth);
        // Inkrementell enthaelt der Graph schon den ganzen Cache, die
        // Rechnung stimmt also fuer alle Grade. Beim vollstaendigen Abruf
        // nur bis zur fertigen Stufe — der Rest kommt aus dem Cache.
        emit(incremental ? fresh : _mergeStage(fresh, previous, depth),
            depth);
      },
    );

    // Keine einzige Antwort: Den gespeicherten Stand zeigen und NICHT
    // ueberschreiben — sonst loeschte ein Funkloch das ganze Netzwerk.
    if (!run.answered) {
      AppLogger.warn('Netzwerk',
          'Keine Relay-Antwort — zeige den gespeicherten Stand.');
      if (previous != null) return previous.markStale();
      return MyNetwork(
          myNpub: myNpub,
          byDegree: {1: [], 2: [], 3: []},
          myMeetupCount: 0,
          stale: true);
    }

    final net = _networkFromGraph(myNpub, run.graph, maxDepth,
        log: true, updatedAt: DateTime.fromMillisecondsSinceEpoch(startedAt));
    _logChanges(previous, net);

    await _writeCache(_GraphCache(
      owner: myNpub,
      // Ist fullSync falsch, gibt es zwingend einen Cache — das erkennt
      // auch der Analyzer aus der Bedingung oben.
      fullSyncAt: fullSync ? startedAt : cache.fullSyncAt,
      syncAt: startedAt,
      knownAuthors: run.knownAuthors,
      knownKeys: run.knownKeys,
      nodes: run.graph,
    ));
    return net;
  }

  /// Zwischenstand beim vollstaendigen Abruf: Grade bis [doneDepth] aus dem
  /// neuen Graphen, die tieferen aus dem Cache. Wer schon in einem neuen
  /// Grad steht, wird aus den alten entfernt — so rueckt B sichtbar von
  /// Grad 2 auf Grad 1, statt doppelt zu erscheinen.
  static MyNetwork _mergeStage(
      MyNetwork fresh, MyNetwork? previous, int doneDepth) {
    if (previous == null) return fresh;
    final placed = <String>{};
    final out = <int, List<NetworkContact>>{};
    for (var d = 1; d <= 3; d++) {
      if (d > doneDepth) continue;
      final list = fresh.byDegree[d] ?? <NetworkContact>[];
      out[d] = list;
      placed.addAll(list.map((c) => c.npub));
    }
    for (var d = 1; d <= 3; d++) {
      if (d <= doneDepth) continue;
      final list = (previous.byDegree[d] ?? const <NetworkContact>[])
          .where((c) => !placed.contains(c.npub))
          .toList();
      out[d] = list;
      placed.addAll(list.map((c) => c.npub));
    }
    return MyNetwork(
      myNpub: fresh.myNpub,
      byDegree: out,
      myMeetupCount: fresh.myMeetupCount,
      updatedAt: previous.updatedAt,
      // Fuer die Wege im Detail: alte Teilnahmen, von neuen ueberschrieben.
      meetupsOf: {...previous.meetupsOf, ...fresh.meetupsOf},
    );
  }

  /// Schreibt ins Log, was sich gegenueber dem Cache veraendert hat.
  static void _logChanges(MyNetwork? before, MyNetwork after) {
    if (before == null) return;
    final b = before.degreeOf;
    final a = after.degreeOf;
    var added = 0, closer = 0, farther = 0, gone = 0;
    a.forEach((npub, d) {
      final old = b[npub];
      if (old == null) {
        added++;
      } else if (d < old) {
        closer++;
      } else if (d > old) {
        farther++;
      }
    });
    for (final npub in b.keys) {
      if (!a.containsKey(npub)) gone++;
    }
    AppLogger.diag('Netzwerk',
        'Gegenueber Cache: $added neu, $closer naeher gerueckt, '
        '$farther weiter weg, $gone nicht mehr im Netzwerk.');
  }

  /// Berechnet die Grade aus dem Graphen (Breitensuche ab mir).
  static MyNetwork _networkFromGraph(
    String myNpub,
    Map<String, CoAttNode> nodes,
    int maxDepth, {
    bool log = false,
    DateTime? updatedAt,
  }) {
    final adj = _adjacency(nodes);
    final myMeetups = nodes[myNpub]?.meetups ?? <String>{};

    // BFS: Grad pro npub + über welchen Grad-1-Kontakt erreichbar
    final degree = <String, int>{myNpub: 0};
    final bridges = <String, Set<String>>{}; // npub -> Grad-1-Brücken
    // Vorgaenger auf EINEM kuerzesten Weg — fuer die Anzeige "Du → Anna →
    // Carla". Weil die direkten Kontakte nach Zahl gemeinsamer Meetups
    // geordnet in die Suche gehen, fuehrt der Weg bevorzugt ueber die
    // staerkste Verbindung.
    final parent = <String, String>{};
    final queue = Queue<String>()..add(myNpub);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final curDeg = degree[current]!;
      if (curDeg >= maxDepth) continue;
      var neighbors = adj[current] ?? const <String>{};
      if (curDeg == 0) {
        final strength = <String, int>{
          for (final n in neighbors)
            n: sharedKeys(nodes[n]?.meetups ?? <String>{}, myMeetups).length,
        };
        neighbors = (neighbors.toList()
              ..sort((a, b) => strength[b]!.compareTo(strength[a]!)))
            .toSet();
      }
      for (final neighbor in neighbors) {
        if (!degree.containsKey(neighbor)) {
          degree[neighbor] = curDeg + 1;
          parent[neighbor] = current;
          queue.add(neighbor);
        }
        // Brücke merken: der Grad-1-Knoten auf dem Weg
        if (curDeg == 0) {
          // direkter Nachbar -> er ist seine eigene "Brücke" (Grad 1)
        } else if (degree[neighbor] == curDeg + 1) {
          if (curDeg == 1) {
            bridges.putIfAbsent(neighbor, () => <String>{}).add(current);
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
        shared = sharedKeys(nodes[npub]?.meetups ?? <String>{}, myMeetups);
      }

      byDegree.putIfAbsent(deg, () => []).add(NetworkContact(
            npub: npub,
            degree: deg,
            sharedMeetupsWithMe: shared,
            bridges: deg == 1 ? <String>{} : (bridges[npub] ?? <String>{}),
            parent: parent[npub],
          ));
    }

    if (log) {
      // ── DIAGNOSE ──────────────────────────────────────────────────
      // Erscheint jemand faelschlich im 1. Grad, laesst sich hier ablesen,
      // WELCHE Kennung die Verbindung erzeugt. Ohne diese Zeilen bleibt nur
      // Raten — die Kennung steckt weder in der Oberflaeche noch im Badge.
      AppLogger.diag('Netzwerk',
          'Eigene Meetup-Kennungen (${myMeetups.length}): '
          '${myMeetups.join(", ")}');
      // Zaehlt mit, ob ueberhaupt fremde Teilnahmen ankamen. Ohne diese Zahl
      // sieht ein leeres Netzwerk gleich aus, egal ob die Relays nichts
      // lieferten oder ob die Kennungen nicht zusammenpassten.
      AppLogger.diag('Netzwerk',
          '${nodes.length} Teilnehmer im Graphen, davon ${(byDegree[1] ?? const []).length} im 1. Grad, '
          '${(byDegree[2] ?? const []).length} im 2. Grad, '
          '${(byDegree[3] ?? const []).length} im 3. Grad.');

      // Bei NULL Treffern eine Stichprobe der FREMDEN Kennungen ausgeben.
      //
      // Ohne sie sieht man nur, dass nichts passt — nicht warum. Und der
      // Vergleich der beiden Formate nebeneinander beantwortet die Frage
      // sofort: gleiche Meetups mit anderem Anhang, andere Schreibweise, oder
      // schlicht andere Meetups.
      if ((byDegree[1] ?? const []).isEmpty && nodes.isNotEmpty) {
        final fremde = <String>{};
        for (final e in nodes.entries) {
          if (e.key == myNpub) continue;
          fremde.addAll(e.value.meetups);
          if (fremde.length >= 15) break;
        }
        AppLogger.diag('Netzwerk',
            'Keine Treffer. Fremde Kennungen (Stichprobe): ${fremde.take(15).join(", ")}');
      }
      for (final c in (byDegree[1] ?? const <NetworkContact>[])) {
        AppLogger.diag('Netzwerk',
            '1. Grad ${c.npub.substring(0, c.npub.length > 16 ? 16 : c.npub.length)}… '
            'ueber: ${c.sharedMeetupsWithMe.join(", ")}');
      }
    }

    // Sortierung: Grad 1 nach Anzahl gemeinsamer Meetups (bei Gleichstand
    // das juengste zuerst), sonst nach Brücken-Anzahl
    byDegree[1]?.sort((a, b) {
      final c =
          b.sharedMeetupsWithMe.length.compareTo(a.sharedMeetupsWithMe.length);
      if (c != 0) return c;
      final da = AttendanceKeyLabel.newest(a.sharedMeetupsWithMe);
      final db = AttendanceKeyLabel.newest(b.sharedMeetupsWithMe);
      return (db ?? DateTime(0)).compareTo(da ?? DateTime(0));
    });
    byDegree[2]?.sort((a, b) => b.bridges.length.compareTo(a.bridges.length));
    byDegree[3]?.sort((a, b) => b.bridges.length.compareTo(a.bridges.length));

    return MyNetwork(
      myNpub: myNpub,
      byDegree: byDegree,
      myMeetupCount: myMeetups.length,
      updatedAt: updatedAt,
      meetupsOf: {
        for (final n in degree.keys)
          if (degree[n]! <= maxDepth) n: Set.of(nodes[n]?.meetups ?? const <String>{}),
      },
    );
  }
}

/// Ein laufender Aufbau des eigenen Netzwerks (siehe [CoAttendanceService.buildMyNetwork]).
class _NetworkJob {
  final String owner;
  final List<void Function(MyNetwork net, int doneDepth)> listeners = [];
  late Future<MyNetwork> future;
  _NetworkJob(this.owner);
}

/// Antwort EINES Relays.
class _RelayAnswer {
  final List<CoAttendanceRecord> records;

  /// Ende der gespeicherten Eintraege (EOSE) erreicht und Limit nicht
  /// ausgeschoepft — die Antwort ist also vollstaendig.
  final bool complete;
  const _RelayAnswer(this.records, {required this.complete});
}

/// Zusammengefasste Antwort aller Relays auf EIN Abfrage-Paket.
class _BatchAnswer {
  final List<CoAttendanceRecord> records;

  /// Mindestens ein Relay hat vollstaendig geantwortet. Reicht, um die
  /// Personen/Meetups als "bekannt" zu fuehren — Teilnahmen gehen an alle
  /// Relays gleichzeitig raus.
  final bool anyComplete;

  /// JEDES Relay hat vollstaendig geantwortet. Erst dann darf eine
  /// fehlende Teilnahme als "nicht mehr vorhanden" gelten.
  final bool allComplete;

  const _BatchAnswer(this.records,
      {required this.anyComplete, required this.allComplete});
}

/// Ergebnis eines Graph-Aufbaus.
class _GraphRun {
  final Map<String, CoAttNode> graph;
  final Set<String> knownAuthors;
  final Set<String> knownKeys;

  /// Hat ueberhaupt ein Relay geantwortet?
  final bool answered;

  _GraphRun(this.graph, this.knownAuthors, this.knownKeys,
      {required this.answered});
}

/// Der gespeicherte Verbindungsgraph.
class _GraphCache {
  /// Wessen Netzwerk. Wechselt der Schluessel, ist der Cache wertlos.
  final String owner;

  /// Letzter vollstaendiger Abruf (ms).
  final int fullSyncAt;

  /// Beginn des letzten Abrufs (ms) — Bezugspunkt fuer `since`.
  final int syncAt;

  /// Personen, deren Teilnahmen schon einmal vollstaendig geholt wurden.
  final Set<String> knownAuthors;

  /// Meetups, deren Teilnehmer schon einmal vollstaendig geholt wurden.
  final Set<String> knownKeys;

  final Map<String, CoAttNode> nodes;

  _GraphCache({
    required this.owner,
    required this.fullSyncAt,
    required this.syncAt,
    required this.knownAuthors,
    required this.knownKeys,
    required this.nodes,
  });

  Map<String, dynamic> toJson() => {
        'v': 1,
        'owner': owner,
        'full': fullSyncAt,
        'sync': syncAt,
        'ka': knownAuthors.toList(),
        'kk': knownKeys.toList(),
        'n': {
          for (final e in nodes.entries)
            e.key: {
              'm': e.value.meetups.toList(),
              if (e.value.events.isNotEmpty) 'e': e.value.events.toList(),
            },
        },
      };

  static _GraphCache? fromJson(Map<String, dynamic> j) {
    if (j['v'] != 1) return null;
    List<String> strings(Object? v) =>
        v is List ? v.map((e) => e.toString()).toList() : const <String>[];
    final nodes = <String, CoAttNode>{};
    final raw = j['n'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final node = CoAttNode(k.toString());
        if (v is Map) {
          node.meetups.addAll(strings(v['m']));
          node.events.addAll(strings(v['e']));
        }
        nodes[node.npub] = node;
      });
    }
    return _GraphCache(
      owner: (j['owner'] ?? '').toString(),
      fullSyncAt: j['full'] is int ? j['full'] as int : 0,
      syncAt: j['sync'] is int ? j['sync'] as int : 0,
      knownAuthors: strings(j['ka']).toSet(),
      knownKeys: strings(j['kk']).toSet(),
      nodes: nodes,
    );
  }
}

/// Ein Kontakt im eigenen Netzwerk.
class NetworkContact {
  final String npub;
  final int degree;                    // 1, 2 oder 3
  final Set<String> sharedMeetupsWithMe; // nur bei Grad 1 befüllt
  final Set<String> bridges;           // Grad-1-Kontakte, über die ich diese Person erreiche (Grad 2+)

  /// Vorgaenger auf einem kuerzesten Weg (bei Grad 1: ich selbst).
  final String? parent;

  NetworkContact({
    required this.npub,
    required this.degree,
    required this.sharedMeetupsWithMe,
    required this.bridges,
    this.parent,
  });
}

/// Das gesamte eigene Netzwerk, nach Graden gruppiert.
class MyNetwork {
  final String myNpub;
  final Map<int, List<NetworkContact>> byDegree;
  final int myMeetupCount;

  /// Stand der Daten (Beginn des Abrufs, aus dem sie stammen).
  final DateTime? updatedAt;

  /// Die Aktualisierung kam nicht zustande — gezeigt wird der gespeicherte
  /// Stand.
  final bool stale;

  /// Meetup-Kennungen je Person (ich und alle Kontakte) — fuer die Angabe,
  /// bei welchem Meetup sich zwei Personen auf dem Weg begegnet sind.
  final Map<String, Set<String>> meetupsOf;

  MyNetwork({
    required this.myNpub,
    required this.byDegree,
    required this.myMeetupCount,
    this.updatedAt,
    this.stale = false,
    this.meetupsOf = const {},
  });

  MyNetwork markStale() => MyNetwork(
        myNpub: myNpub,
        byDegree: byDegree,
        myMeetupCount: myMeetupCount,
        updatedAt: updatedAt,
        stale: true,
        meetupsOf: meetupsOf,
      );

  /// Alle Kontakte nach npub.
  late final Map<String, NetworkContact> contactsByNpub = {
    for (final list in byDegree.values)
      for (final c in list) c.npub: c,
  };

  /// Weg von mir zu [npub], z. B. [ich, Anna, Carla]. Leer, wenn er sich
  /// nicht vollstaendig zusammensetzen laesst.
  List<String> pathTo(String npub) {
    final chain = <String>[npub];
    var cur = npub;
    for (var i = 0; i < 4; i++) {
      final p = contactsByNpub[cur]?.parent;
      if (p == null) break;
      chain.add(p);
      if (p == myNpub) break;
      cur = p;
    }
    if (chain.last != myNpub) return const [];
    return chain.reversed.toList();
  }

  /// Gemeinsame Meetups zweier Personen, das juengste zuerst.
  List<String> sharedBetween(String a, String b) =>
      AttendanceKeyLabel.newestFirst(CoAttendanceService.sharedKeys(
          meetupsOf[a] ?? const <String>{}, meetupsOf[b] ?? const <String>{}));

  /// Grad je Person — zum Vergleich zweier Staende.
  Map<String, int> get degreeOf => {
        for (final e in byDegree.entries)
          for (final c in e.value) c.npub: e.key,
      };

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

/// Macht aus einer Anwesenheits-Kennung etwas Lesbares.
///
/// Kennungen sehen so aus: `wuerzburg-2026-09-12@u8qf5q534jzc` — Meetup-Name
/// in Kleinbuchstaben mit Bindestrichen, Datum, optional der Signierer.
/// Angezeigt wird daraus "Wuerzburg, 12.09.2026". Der Signierer-Anhang ist
/// reine Technik und verschwindet.
class AttendanceKeyLabel {
  static final RegExp _dated = RegExp(r'^(.*)-(\d{4})-(\d{2})-(\d{2})$');

  static String _strip(String key) {
    var k = key;
    if (k.startsWith(CoAttendanceService.eventPrefix)) {
      k = k.substring(CoAttendanceService.eventPrefix.length);
    }
    final i = k.indexOf('@');
    return i < 0 ? k : k.substring(0, i);
  }

  static DateTime? date(String key) {
    final m = _dated.firstMatch(_strip(key));
    if (m == null) return null;
    return DateTime(
        int.parse(m.group(2)!), int.parse(m.group(3)!), int.parse(m.group(4)!));
  }

  static String place(String key) {
    final s = _strip(key);
    final m = _dated.firstMatch(s);
    final raw = m == null ? s : m.group(1)!;
    return raw
        .split('-')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// "12.09.2026", mit [withYear] = false nur "12.09.".
  static String dateText(DateTime d, {bool withYear = true}) {
    String two(int v) => v.toString().padLeft(2, '0');
    return withYear
        ? '${two(d.day)}.${two(d.month)}.${d.year}'
        : '${two(d.day)}.${two(d.month)}.';
  }

  /// "Wuerzburg, 12.09.2026"
  static String label(String key) {
    final d = date(key);
    final p = place(key);
    return d == null ? p : '$p, ${dateText(d)}';
  }

  static List<String> newestFirst(Iterable<String> keys) => keys.toList()
    ..sort((a, b) =>
        (date(b) ?? DateTime(0)).compareTo(date(a) ?? DateTime(0)));

  /// Datum der juengsten Kennung, null wenn keine ein Datum traegt.
  static DateTime? newest(Iterable<String> keys) {
    DateTime? best;
    for (final k in keys) {
      final d = date(k);
      if (d != null && (best == null || d.isAfter(best))) best = d;
    }
    return best;
  }
}
