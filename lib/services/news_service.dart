// NEWS / ARTIKEL — NIP-23 Longform (kind 30023)
// ============================================
// Liest Einundzwanzig-Artikel von den Relays und erlaubt das
// Veröffentlichen eigener Artikel (Titel, Bild, Zusammenfassung, Text).
// Quelle/Ziel: dieselben Nostr-Relays wie der Rest der App.
//
// Ein Artikel ist ein kind:30023-Event mit den Standard-Tags
// title / image / summary / published_at / d / t (NIP-23).
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'relay_config.dart';
import 'app_logger.dart';

const String _tag = 'News';
const int kArticleKind = 30023; // NIP-23 Longform

/// News-Kuratierung nach dem Discover-Prinzip (EINUNDZWANZIG STANDUP):
/// Ein Artikel wird angezeigt, wenn er ENTWEDER einen der Tags trägt ODER
/// von einem Autor der Watchlist stammt.
///
/// 1) TAGS (NIP-23 t-Tag): breite, themenbasierte Erfassung.
const List<String> kNewsTags = ['einundzwanzig', 'bitcoin', '21', 'meetup'];

/// 2) AUTOREN-WATCHLIST (Hex-Pubkeys): gezielt die Blogs, die auf Discover
///    kuratiert sind. Wartbar: neue Discover-Autoren hier als Hex ergänzen
///    (npub -> hex z.B. über njump.me/<npub>). NUR bestätigte Pubkeys.
const List<String> kNewsAuthors = [
  // markusturm (Einundzwanzig News)
  'f240be2b684f85cc81566f2081386af81d7427ea86250c8bde6b7a8500c761ba',
  // Weitere Discover-Autoren hier ergänzen:
  // '<hex-pubkey>',  // <name>
];


/// Ein einzelner Artikel (aus einem kind:30023-Event).
class NewsArticle {
  final String id;          // Event-ID
  final String pubkey;      // Autor (hex)
  final String dTag;        // Identifier (für Adressierung/Updates)
  final String title;
  final String summary;
  final String image;       // Bild-URL (kann leer sein)
  final String content;     // Markdown
  final int publishedAt;    // Unix-Sekunden
  final List<String> topics; // t-Tags

  NewsArticle({
    required this.id,
    required this.pubkey,
    required this.dTag,
    required this.title,
    required this.summary,
    required this.image,
    required this.content,
    required this.publishedAt,
    required this.topics,
  });

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(publishedAt * 1000);

  static NewsArticle? fromEvent(Map<String, dynamic> e) {
    try {
      final tags = (e['tags'] as List<dynamic>?)
              ?.map((t) => (t as List<dynamic>).map((x) => x.toString()).toList())
              .toList() ??
          [];
      String tagVal(String key) {
        final t = tags.firstWhere((t) => t.isNotEmpty && t[0] == key, orElse: () => const []);
        return t.length >= 2 ? t[1] : '';
      }
      final topics = tags.where((t) => t.isNotEmpty && t[0] == 't' && t.length >= 2).map((t) => t[1]).toList();

      final title = tagVal('title');
      final content = (e['content'] ?? '').toString();
      // Artikel ohne Titel UND ohne Inhalt überspringen
      if (title.isEmpty && content.isEmpty) return null;

      final publishedStr = tagVal('published_at');
      final published = int.tryParse(publishedStr) ?? (e['created_at'] as int? ?? 0);

      return NewsArticle(
        id: (e['id'] ?? '').toString(),
        pubkey: (e['pubkey'] ?? '').toString(),
        dTag: tagVal('d'),
        title: title.isEmpty ? '(ohne Titel)' : title,
        summary: tagVal('summary'),
        image: tagVal('image'),
        content: content,
        publishedAt: published,
        topics: topics,
      );
    } catch (_) {
      return null;
    }
  }
}

class NewsService {
  static const Duration _timeout = Duration(seconds: 8);

  /// Lädt die neuesten Artikel (kind 30023) von allen aktiven Relays.
  /// [limit] begrenzt pro Relay. Ergebnisse werden dedupliziert
  /// (gleiche d-Tag+Autor -> nur neueste Version) und nach Datum sortiert.
  static Future<List<NewsArticle>> fetchArticles({int limit = 50}) async {
    final relays = await RelayConfig.getActiveRelays();
    // Map-Key: pubkey:dTag  -> nur die neueste Version behalten (NIP-23 replaceable)
    final byKey = <String, NewsArticle>{};

    for (final relayUrl in relays) {
      final list = await _fetchFromRelay(relayUrl, limit);
      if (list == null) continue;
      for (final a in list) {
        final key = '${a.pubkey}:${a.dTag}';
        final existing = byKey[key];
        if (existing == null || a.publishedAt > existing.publishedAt) {
          byKey[key] = a;
        }
      }
    }

    final all = byKey.values.toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return all;
  }

  static Future<List<NewsArticle>?> _fetchFromRelay(String relayUrl, int limit) async {
    WebSocket? ws;
    try {
      ws = await WebSocket.connect(relayUrl).timeout(_timeout);
      final completer = Completer<List<NewsArticle>?>();
      final results = <NewsArticle>[];

      final random = Random.secure();
      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      // Zwei Subscriptions: eine nach Tags, eine nach Autoren (ODER-Verknüpfung).
      final subTags = 'news-t-$subIdHex';
      final subAuthors = 'news-a-$subIdHex';

      // Wie viele EOSE erwarten wir? (nur aktive Subscriptions zählen)
      var pending = 0;
      if (kNewsTags.isNotEmpty) pending++;
      if (kNewsAuthors.isNotEmpty) pending++;
      if (pending == 0) pending = 1; // Fallback: unbegrenzt (siehe unten)

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;
            if (type == 'EVENT' && message.length >= 3) {
              final eventData = message[2] as Map<String, dynamic>;
              final article = NewsArticle.fromEvent(eventData);
              if (article != null) results.add(article);
            } else if (type == 'EOSE') {
              pending--;
              if (pending <= 0 && !completer.isCompleted) completer.complete(results);
            }
          } catch (_) {/* einzelne fehlerhafte Events ignorieren */}
        },
        onError: (_) { if (!completer.isCompleted) completer.complete(results); },
        onDone: () { if (!completer.isCompleted) completer.complete(results); },
      );

      // REQ 1: Longform-Artikel mit einem der News-Tags (t-Tag).
      if (kNewsTags.isNotEmpty) {
        ws.add(jsonEncode(['REQ', subTags, {'kinds': [kArticleKind], '#t': kNewsTags, 'limit': limit}]));
      }
      // REQ 2: Longform-Artikel der kuratierten Autoren (Watchlist).
      if (kNewsAuthors.isNotEmpty) {
        ws.add(jsonEncode(['REQ', subAuthors, {'kinds': [kArticleKind], 'authors': kNewsAuthors, 'limit': limit}]));
      }
      // Falls beides leer wäre: alle Longform-Artikel (Sicherheitsnetz).
      if (kNewsTags.isEmpty && kNewsAuthors.isEmpty) {
        ws.add(jsonEncode(['REQ', subTags, {'kinds': [kArticleKind], 'limit': limit}]));
      }

      final res = await completer.future.timeout(_timeout, onTimeout: () => results);
      return res;
    } catch (e) {
      AppLogger.debug(_tag, '$relayUrl Lesefehler: $e');
      return null;
    } finally {
      try { ws?.close(); } catch (_) {}
    }
  }
}
