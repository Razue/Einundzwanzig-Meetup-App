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
      final subId = 'news-$subIdHex';

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
              if (!completer.isCompleted) completer.complete(results);
            }
          } catch (_) {/* einzelne fehlerhafte Events ignorieren */}
        },
        onError: (_) { if (!completer.isCompleted) completer.complete(results); },
        onDone: () { if (!completer.isCompleted) completer.complete(results); },
      );

      // REQ: nur Longform-Artikel, nach Datum begrenzt
      ws.add(jsonEncode(['REQ', subId, {'kinds': [kArticleKind], 'limit': limit}]));

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
