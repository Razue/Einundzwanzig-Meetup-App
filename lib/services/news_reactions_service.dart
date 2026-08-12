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

  /// Dieselben Relays wie im NewsService — Reaktionen muessen dort landen,
  /// wo auch die Artikel liegen, sonst sieht sie die Webseite nie.
  static const List<String> relays = [
    'wss://nostr.einundzwanzig.space',
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.nostr.band',
  ];

  static const Duration _timeout = Duration(seconds: 6);

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
    for (final url in relays) {
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
    return ArticleLikes(count: reactors.length, mine: mine);
  }

  /// Sendet ein Herz auf den Artikel.
  ///
  /// [articleAddress] ist die a-Adresse, [authorPubkey] der Autor (fuer die
  /// Benachrichtigung per p-Tag). Gibt true zurueck, sobald MINDESTENS ein
  /// Relay das Ereignis angenommen hat — mehr Sicherheit gibt es bei Nostr
  /// nicht, und auf alle zu warten hiesse auf das langsamste zu warten.
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

    final frame = signed.toEventMessage();
    final accepted = Completer<bool>();
    final sockets = <RelaySocket>[];
    var settled = false;

    void finish(bool ok) {
      if (settled) return;
      settled = true;
      for (final ws in sockets) {
        try {
          ws.close();
        } catch (_) {}
      }
      if (!accepted.isCompleted) accepted.complete(ok);
    }

    Timer(_timeout, () => finish(false));

    for (final url in relays) {
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
          ws.listen((data) {
            try {
              final msg = jsonDecode(data as String) as List<dynamic>;
              // ["OK", <id>, <true|false>, <message>]
              if (msg.length >= 3 &&
                  msg[0] == 'OK' &&
                  msg[1] == signed.id &&
                  msg[2] == true) {
                finish(true);
              }
            } catch (_) {}
          }, onError: (_) {}, onDone: () {});
          ws.add(frame);
        } catch (_) {
          // Relay nicht erreichbar — die anderen laufen weiter.
        }
      }();
    }

    return accepted.future;
  }
}
