// NEWS-REAKTIONEN — Herzen auf Artikel (NIP-25)
// ============================================
// Die Artikel im News-Bereich sind adressierbare Nostr-Ereignisse
// (kind 30023). Ihre Adresse steht bereits in NewsArticle.id und hat die
// Form "30023:<pubkey>:<d>" — genau das, was NIP-25 als a-Tag erwartet.
// Deshalb braucht es hier keine eigene Datenhaltung: Reaktionen sind
// signierte Ereignisse auf denselben Relays, von denen die Artikel kommen.
//
// Gezaehlt wird PRO PUBKEY, nicht pro Ereignis. Wer mehrfach reagiert oder
// dessen Reaktion ueber mehrere Relays zurueckkommt, zaehlt einmal.
// ============================================

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';
import 'relay_config.dart';
import 'relay_socket.dart';
import 'signing_service.dart';

const String _tag = 'NewsReactions';

/// Zustand der Herzen zu einem Artikel.
class ArticleLikes {
  /// Anzahl unterschiedlicher Pubkeys, die positiv reagiert haben.
  final int count;

  /// Hat die eigene Identitaet bereits reagiert?
  final bool mine;

  const ArticleLikes({required this.count, required this.mine});

  static const empty = ArticleLikes(count: 0, mine: false);

  ArticleLikes withMine() =>
      mine ? this : ArticleLikes(count: count + 1, mine: true);
}

class NewsReactionsService {
  NewsReactionsService._();

  /// Relays, von denen die Artikel kommen. Reaktionen muessen dort landen,
  /// sonst sieht sie die Webseite nie.
  static const List<String> newsRelays = [
    'wss://nostr.einundzwanzig.space',
    'wss://relay.damus.io',
    'wss://nos.lol',
  ];

  /// Nur zum LESEN. relay.nostr.band ist ein Aggregator: Beim Abrufen
  /// liefert es die meisten Treffer (im Test 10 gegenueber 6 und 7), fremde
  /// Ereignisse nimmt es aber nicht an. Beim Schreiben laeuft es deshalb
  /// jedes Mal in die Zeitgrenze, ohne dass etwas dabei herauskommt.
  static const List<String> readOnlyRelays = [
    'wss://relay.nostr.band',
  ];

  /// Relays zum Abrufen: alles, was Treffer liefern kann.
  ///
  /// Oeffentlich, weil auch NewsZapService das Autorenprofil ueber genau
  /// diese Relays sucht — zwei getrennte Listen wuerden frueher oder
  /// spaeter auseinanderlaufen.
  static Future<List<String>> readTargets() async {
    final all = <String>{...newsRelays, ...readOnlyRelays};
    try {
      all.addAll(await RelayConfig.getActiveRelays());
    } catch (_) {
      // Ohne Nutzer-Relays laeuft es mit den festen weiter.
    }
    return all.toList();
  }

  /// Relays zum Senden: dieselbe Menge OHNE die reinen Lesequellen.
  static Future<List<String>> _writeTargets() async {
    final all = await readTargets();
    return all.where((r) => !readOnlyRelays.contains(r)).toList();
  }

  static const Duration _timeout = Duration(seconds: 8);

  /// Merkzettel der eigenen Herzen.
  ///
  /// Warum ueberhaupt lokal, wo doch alles auf Relays liegt? Weil die App
  /// nicht das Netz fragen muss, um zu wissen, was der Nutzer selbst getan
  /// hat. Im Test kam die eigene Reaktion bei einer spaeteren Abfrage nicht
  /// zurueck, obwohl drei Relays sie angenommen und zwei sie nachweislich
  /// abgelegt hatten — ohne Merkzettel liess sich dasselbe Herz beliebig oft
  /// erneut senden. Der Merkzettel ist die Wahrheit ueber die EIGENE
  /// Handlung; die Relays bleiben die Wahrheit ueber alle anderen.
  static const String _likedKey = 'news_liked_reactions';

  /// Ein Eintrag lautet `<pubkey>|<artikeladresse>` — mit Schluessel, damit
  /// ein Identitaetswechsel nicht die Herzen der vorigen Identitaet erbt.
  static String _entry(String pubkey, String address) => '$pubkey|$address';

  static Future<Set<String>> _likedEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_likedKey) ?? const <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> _rememberLike(String pubkey, String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_likedKey) ?? <String>[];
      final entry = _entry(pubkey, address);
      if (list.contains(entry)) return;
      list.add(entry);
      // Deckel gegen unbegrenztes Wachsen: Die aeltesten Eintraege fallen
      // heraus. 500 Artikel reichen weit ueber jede reale Lesehistorie.
      if (list.length > 500) list.removeRange(0, list.length - 500);
      await prefs.setStringList(_likedKey, list);
    } catch (e) {
      AppLogger.warn(_tag, 'Merkzettel konnte nicht geschrieben werden', e);
    }
  }

  /// Inhalte, die NIP-25 als Zustimmung wertet. Ein "-" ist ausdruecklich
  /// eine Ablehnung und zaehlt nicht mit; alles andere (Emoji) gilt als
  /// positiv, so machen es die gaengigen Clients auch.
  static bool _isPositive(String content) {
    final c = content.trim();
    if (c == '-') return false;
    return true;
  }

  /// Hat die eigene Identitaet diesen Artikel schon beherzt?
  ///
  /// Nur der Merkzettel, kein Netz — Antwort in Millisekunden. [fetchLikes]
  /// prueft dasselbe erst NACH der Relay-Abfrage; solange sah das Herz leer
  /// aus und lud zum zweiten Druck ein.
  static Future<bool> hasLikedLocally(String articleAddress) async {
    final myPubkey = await SigningService.pubkeyHex();
    if (myPubkey == null) return false;
    final entries = await _likedEntries();
    return entries.contains(_entry(myPubkey, articleAddress));
  }

  /// Laedt die Herzen zu einer Artikeladresse (`30023:<pubkey>:<d>`).
  static Future<ArticleLikes> fetchLikes(String articleAddress) async {
    final myPubkey = await SigningService.pubkeyHex();

    // Set statt Zaehler: dieselbe Reaktion kommt von mehreren Relays zurueck.
    final reactors = <String>{};
    var mine = false;

    final targets = await readTargets();
    // Wie viele Reaktionen kam von welchem Relay? Ohne diese Zeile ist
    // "das Herz ist weg" nicht von "kein Relay hat es" zu unterscheiden.
    final perRelay = <String, int>{};

    final sockets = <RelaySocket>[];
    final done = Completer<void>();
    var settled = false;

    void finish() {
      if (settled) return;
      settled = true;
      for (final ws in sockets) {
        try {
          ws.close();
        } catch (_) {}
      }
      if (!done.isCompleted) done.complete();
    }

    // Fertig, sobald jedes Relay geantwortet hat. Vorher lief die Abfrage
    // IMMER bis zur Zeitgrenze, auch wenn nach 300 ms alles da war. Der
    // Timer bleibt als Notbremse fuer traege Relays.
    final finished = <String>{};
    void relayDone(String url) {
      finished.add(url);
      if (finished.length >= targets.length) finish();
    }

    Timer(_timeout, finish);

    for (final url in targets) {
      () async {
        try {
          final ws = await RelaySocket.connect(url)
              .timeout(const Duration(seconds: 4));
          if (settled) {
            try {
              ws.close();
            } catch (_) {}
            return;
          }
          sockets.add(ws);
          ws.add(jsonEncode([
            'REQ',
            'likes',
            {
              'kinds': [7],
              '#a': [articleAddress],
              'limit': 500,
            }
          ]));
          ws.listen((data) {
            try {
              final msg = jsonDecode(data as String) as List<dynamic>;
              // EOSE = "mehr habe ich nicht". Damit ist dieses Relay durch.
              if (msg.isNotEmpty && msg[0] == 'EOSE') {
                relayDone(url);
                return;
              }
              if (msg.length >= 3 && msg[0] == 'EVENT') {
                final event = msg[2] as Map<String, dynamic>;
                final content = (event['content'] ?? '').toString();
                final pubkey = (event['pubkey'] ?? '').toString();
                if (pubkey.isEmpty || !_isPositive(content)) return;
                reactors.add(pubkey);
                perRelay[url] = (perRelay[url] ?? 0) + 1;
                if (myPubkey != null && pubkey == myPubkey) mine = true;
              }
            } catch (_) {
              // Eine kaputte Nachricht darf die uebrigen nicht verhindern.
            }
          }, onError: (_) => relayDone(url), onDone: () => relayDone(url));
        } catch (_) {
          // Relay nicht erreichbar — die anderen laufen weiter.
          relayDone(url);
        }
      }();
    }

    await done.future;

    // Merkzettel schlaegt die Relay-Antwort: Wer selbst reagiert hat, sieht
    // das Herz gefuellt, auch wenn kein Relay die eigene Reaktion
    // zurueckliefert.
    var localOnly = false;
    if (myPubkey != null && !mine) {
      final entries = await _likedEntries();
      if (entries.contains(_entry(myPubkey, articleAddress))) {
        mine = true;
        localOnly = true;
      }
    }

    AppLogger.debug(_tag,
        'Herzen fuer $articleAddress: ${reactors.length} gesamt, eigenes: $mine, '
        'pro Relay: ${perRelay.isEmpty ? "keine Treffer" : perRelay}');
    AppLogger.debug(_tag,
        'eigener Pubkey: ${myPubkey == null ? "keiner" : "${myPubkey.substring(0, 8)}…"} | '
        'eigenes Herz aus Merkzettel: $localOnly | '
        'gefundene Reagierende: ${reactors.map((p) => "${p.substring(0, 8)}…").join(", ")}');
    // Kam die eigene Reaktion nicht von den Relays zurueck, ist sie auch
    // nicht mitgezaehlt — dann eine dazurechnen, sonst faende sich ein
    // gefuelltes Herz neben einer Zahl, die es nicht enthaelt.
    final count = reactors.length + (localOnly ? 1 : 0);
    return ArticleLikes(count: count, mine: mine);
  }

  /// Sendet ein Herz auf den Artikel.
  ///
  /// [articleAddress] ist die a-Adresse, [authorPubkey] der Autor (fuer die
  /// Benachrichtigung per p-Tag).
  ///
  /// Wichtig: Es wird auf ALLE Relays gewartet, nicht nur auf das erste
  /// "OK". Die erste Fassung hat beim ersten Erfolg sofort alle Verbindungen
  /// geschlossen — damit lag die Reaktion oft nur auf einem einzigen Relay,
  /// und wenn ausgerechnet das die Webseite nicht liest, kommt sie dort nie
  /// an. Jede Antwort wird protokolliert, auch die Ablehnungen: Nur so ist
  /// hinterher zu sehen, welches Relay was gesagt hat.
  static Future<bool> like({
    required String articleAddress,
    required String authorPubkey,
  }) async {
    // Doppelt senden waere doppelt gezaehlt: Die Webseite zaehlt Ereignisse,
    // nicht Personen. Der Merkzettel verhindert das schon vor dem Signieren.
    final myPubkey = await SigningService.pubkeyHex();
    if (myPubkey != null) {
      final entries = await _likedEntries();
      if (entries.contains(_entry(myPubkey, articleAddress))) {
        AppLogger.debug(_tag, 'Herz bereits vergeben — nichts gesendet.');
        return true;
      }
    }

    final SignedEvent signed;
    try {
      signed = await SigningService.signEvent(
        kind: 7,
        content: '+',
        tags: [
          ['a', articleAddress],
          if (authorPubkey.isNotEmpty) ['p', authorPubkey],
          ['k', '30023'],
        ],
      );
    } catch (e) {
      AppLogger.warn(_tag, 'Signieren fehlgeschlagen', e);
      return false;
    }

    final targets = await _writeTargets();
    final frame = signed.toEventMessage();
    final results = <String, String>{};
    final accepted = <String>{};

    final sockets = <RelaySocket>[];
    final done = Completer<void>();
    var settled = false;

    void finish() {
      if (settled) return;
      settled = true;
      for (final ws in sockets) {
        try {
          ws.close();
        } catch (_) {}
      }
      if (!done.isCompleted) done.complete();
    }

    // Nicht beim ersten OK abbrechen — erst wenn ALLE geantwortet haben
    // oder die Zeit um ist.
    void maybeFinishEarly() {
      if (results.length >= targets.length) finish();
    }

    Timer(_timeout, finish);

    for (final url in targets) {
      () async {
        try {
          final ws = await RelaySocket.connect(url)
              .timeout(const Duration(seconds: 5));
          if (settled) {
            try {
              ws.close();
            } catch (_) {}
            return;
          }
          sockets.add(ws);
          ws.listen((data) {
            try {
              final msg = jsonDecode(data as String) as List<dynamic>;
              // ["OK", <id>, <true|false>, <message>]
              if (msg.length >= 3 && msg[0] == 'OK' && msg[1] == signed.id) {
                final ok = msg[2] == true;
                final reason = msg.length >= 4 ? msg[3].toString() : '';
                results[url] = ok ? 'angenommen' : 'abgelehnt: $reason';
                if (ok) accepted.add(url);
                maybeFinishEarly();
              } else if (msg.isNotEmpty && msg[0] == 'NOTICE') {
                // Manche Relays antworten statt mit OK nur mit NOTICE.
                AppLogger.debug(_tag, 'NOTICE von $url: ${msg.length > 1 ? msg[1] : ""}');
              }
            } catch (_) {}
          }, onError: (_) {}, onDone: () {});
          ws.add(frame);
        } catch (_) {
          results[url] = 'nicht erreichbar';
          maybeFinishEarly();
        }
      }();
    }

    await done.future;

    for (final url in targets) {
      AppLogger.debug(_tag, '$url -> ${results[url] ?? "keine Antwort"}');
    }
    AppLogger.debug(_tag,
        'Herz ${signed.id} auf $articleAddress: '
        '${accepted.length} von ${targets.length} Relays angenommen');

    if (accepted.isNotEmpty) {
      await _rememberLike(signed.pubkey, articleAddress);
    }

    return accepted.isNotEmpty;
  }
}
