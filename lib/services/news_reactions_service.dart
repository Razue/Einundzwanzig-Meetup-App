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
    'wss://relay.nostr.band',
  ];

  /// Zielrelays: die News-Relays PLUS die vom Nutzer eingeschalteten.
  ///
  /// Nur die vier festen zu nehmen war zu eng — relay.nostr.band etwa ist
  /// ein Suchdienst und nimmt fremde Ereignisse gar nicht an. Je mehr
  /// Relays es versuchen, desto wahrscheinlicher bleibt die Reaktion
  /// irgendwo liegen.
  static Future<List<String>> _targets() async {
    final all = <String>{...newsRelays};
    try {
      all.addAll(await RelayConfig.getActiveRelays());
    } catch (_) {
      // Ohne Nutzer-Relays laeuft es mit den festen weiter.
    }
    return all.toList();
  }

  static const Duration _timeout = Duration(seconds: 8);

  /// Inhalte, die NIP-25 als Zustimmung wertet. Ein "-" ist ausdruecklich
  /// eine Ablehnung und zaehlt nicht mit; alles andere (Emoji) gilt als
  /// positiv, so machen es die gaengigen Clients auch.
  static bool _isPositive(String content) {
    final c = content.trim();
    if (c == '-') return false;
    return true;
  }

  /// Laedt die Herzen zu einer Artikeladresse (`30023:<pubkey>:<d>`).
  static Future<ArticleLikes> fetchLikes(String articleAddress) async {
    final myPubkey = await SigningService.pubkeyHex();

    // Set statt Zaehler: dieselbe Reaktion kommt von mehreren Relays zurueck.
    final reactors = <String>{};
    var mine = false;

    final targets = await _targets();
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

    Timer(_timeout, finish);

    // Auf EOSE aller Relays warten waere sauberer, dauert aber genauso lang
    // wie der Timeout, sobald ein Relay traege ist. Deshalb: sammeln, bis
    // die Zeit um ist, und dann zeigen was da ist.
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
          }, onError: (_) {}, onDone: () {});
        } catch (_) {
          // Relay nicht erreichbar — die anderen laufen weiter.
        }
      }();
    }

    await done.future;
    AppLogger.debug(_tag,
        'Herzen fuer $articleAddress: ${reactors.length} gesamt, eigenes: $mine, '
        'pro Relay: ${perRelay.isEmpty ? "keine Treffer" : perRelay}');
    return ArticleLikes(count: reactors.length, mine: mine);
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

    final targets = await _targets();
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
        } catch (e) {
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

    return accepted.isNotEmpty;
  }
}
