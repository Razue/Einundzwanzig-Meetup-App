// ============================================
//  NEWS / ARTIKEL — RSS-Feed von media.einundzwanzig.space
// ============================================
//  Quelle: https://media.einundzwanzig.space/s/einundzwanzig-news/feed.xml
//  Zeigt EXAKT die Artikel, die auch auf der Webseite
//  media.einundzwanzig.space/s/einundzwanzig-news erscheinen.
//  Ersetzt die frühere Nostr-Relay-Abfrage (kind 30023).
// ============================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../services/app_logger.dart';
import 'relay_socket.dart';

const String kNewsFeedUrl =
    'https://media.einundzwanzig.space/s/einundzwanzig-news/feed.xml';
const String kNewsWebsiteUrl =
    'https://media.einundzwanzig.space/s/einundzwanzig-news';

/// Ein einzelner Artikel (aus einem RSS <item>).
class NewsArticle {
  final String id;
  final String pubkey;      // Autor-Name (RSS: <dc:creator>/<author>)
  final String dTag;        // ungenutzt (Kompat)
  final String title;
  final String summary;
  final String image;
  final String content;
  final int publishedAt;
  final List<String> topics;
  final String link;        // URL zum Artikel auf der Webseite

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
    required this.link,
  });

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(publishedAt * 1000);
}

class NewsService {
  static const Duration _timeout = Duration(seconds: 12);
  static const String _tag = 'NewsService';

  // Relays, auf denen die Einundzwanzig-Longform-Artikel liegen.
  static const List<String> _relays = [
    'wss://nostr.einundzwanzig.space',
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.nostr.band',
  ];

  /// Lädt die Artikel aus dem RSS-Feed der Einundzwanzig-News-Seite.
  // ============================================================
  // UNGELESEN-ZAEHLER
  // ============================================================
  // Merkt sich den Veroeffentlichungs-Zeitstempel des neuesten Artikels,
  // den der Nutzer gesehen hat. Alles Neuere gilt als ungelesen.
  //
  // Bewusst der ARTIKEL-Zeitstempel und nicht "jetzt": RSS-Beitraege
  // trudeln mit aelterem pubDate nach. Wuerde man die Uhrzeit des
  // Lesens speichern, blieben solche Nachzuegler dauerhaft unsichtbar.
  static const String _kLastReadTs = 'news_last_read_ts';

  // Kurzlebiger Zwischenspeicher: Das Dashboard fragt den Zaehler bei
  // jedem Aufbau ab — ohne Cache waere das ein Feed-Abruf pro Rueckkehr
  // auf die Startseite.
  static List<NewsArticle>? _cache;
  static DateTime? _cachedAt;
  static const Duration _cacheTtl = Duration(minutes: 10);

  /// Artikel mit Zwischenspeicher — fuer Zaehler und Kacheln.
  static Future<List<NewsArticle>> cachedArticles({int limit = 50}) async {
    final c = _cache;
    if (c != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return c;
    }
    final fresh = await fetchArticles(limit: limit);
    if (fresh.isNotEmpty) {
      _cache = fresh;
      _cachedAt = DateTime.now();
    }
    return fresh;
  }

  /// Anzahl der Artikel, die seit dem letzten Besuch dazugekommen sind.
  /// Beim allerersten Aufruf 0 — sonst begruesst die App neue Nutzer mit
  /// "50 neue Artikel".
  static Future<int> unreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRead = prefs.getInt(_kLastReadTs);
      final articles = await cachedArticles();
      if (articles.isEmpty) return 0;
      if (lastRead == null) {
        await _storeNewest(articles);
        return 0;
      }
      return articles.where((a) => a.publishedAt > lastRead).length;
    } catch (e) {
      AppLogger.warn(_tag, 'Ungelesen-Zaehler fehlgeschlagen', e);
      return 0;
    }
  }

  /// Setzt den Zaehler zurueck — beim Oeffnen der News.
  static Future<void> markRead() async {
    try {
      final articles = await cachedArticles();
      if (articles.isNotEmpty) await _storeNewest(articles);
    } catch (e) {
      AppLogger.warn(_tag, 'markRead fehlgeschlagen', e);
    }
  }

  static Future<void> _storeNewest(List<NewsArticle> articles) async {
    final newest =
        articles.map((a) => a.publishedAt).reduce((a, b) => a > b ? a : b);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastReadTs, newest);
  }

  static Future<List<NewsArticle>> fetchArticles({int limit = 50}) async {
    try {
      final r = await http
          .get(Uri.parse(kNewsFeedUrl), headers: {
            'Accept': 'application/rss+xml, application/xml, text/xml',
            'User-Agent': 'Einundzwanzig-Meetup-App/1.0 (Android)'
          })
          .timeout(_timeout);
      if (r.statusCode != 200) {
        AppLogger.debug(_tag, 'Feed HTTP ${r.statusCode}');
        return [];
      }
      final xml = utf8.decode(r.bodyBytes, allowMalformed: true);
      final articles = _parseRss(xml);
      if (articles.length > limit) return articles.sublist(0, limit);
      return articles;
    } catch (e) {
      AppLogger.debug(_tag, 'Feed-Fehler: $e');
      return [];
    }
  }

  /// Holt den VOLLEN Artikeltext (Markdown) zu einem Feed-Artikel aus dem
  /// zugehörigen Nostr-Longform-Event (kind 30023). Die RSS-guid hat das
  /// Format "30023:<pubkey>:<d-identifier>". Damit fragen wir das
  /// adressierbare Event gezielt über mehrere Relays ab und nehmen das erste
  /// Ergebnis. Gibt den Markdown-Content zurück, oder null bei Misserfolg.
  static Future<String?> fetchArticleContent(String guid) async {
    // guid parsen
    final parts = guid.split(':');
    if (parts.length < 3) return null;
    final pubkey = parts[1];
    final dId = parts.sublist(2).join(':'); // d kann ':' enthalten (selten)
    if (pubkey.isEmpty || dId.isEmpty) return null;

    final completer = Completer<String?>();
    final sockets = <RelaySocket>[];
    var settled = false;
    // EIN Zaehler fuer alle Relays dieses Abrufs: hier laufen mehrere
    // Verbindungen parallel, ein Zaehler je Socket waere unuebersichtlich.
    // Gemeldet wird beim Abschluss, also auch bei Timeout.
    final tally = RelayParseTally(_tag, 'Artikel-Volltext');

    void finish(String? result) {
      if (settled) return;
      settled = true;
      tally.report();
      for (final ws in sockets) {
        try { ws.close(); } catch (_) {}
      }
      if (!completer.isCompleted) completer.complete(result);
    }

    // Timeout-Sicherung
    Timer(_timeout, () => finish(null));

    for (final url in _relays) {
      () async {
        try {
          final ws = await RelaySocket.connect(url).timeout(const Duration(seconds: 6));
          if (settled) { try { ws.close(); } catch (_) {} return; }
          sockets.add(ws);
          const subId = 'article';
          ws.add(jsonEncode([
            'REQ',
            subId,
            {
              'kinds': [30023],
              'authors': [pubkey],
              '#d': [dId],
              'limit': 1,
            }
          ]));
          ws.listen((data) {
            tally.message();
            try {
              final msg = jsonDecode(data as String) as List<dynamic>;
              if (msg.isNotEmpty && msg[0] == 'EVENT' && msg.length >= 3) {
                final event = msg[2] as Map<String, dynamic>;
                final content = (event['content'] ?? '').toString();
                if (content.isNotEmpty) finish(content);
              }
            } catch (e) {
              tally.failed(e);
            }
          }, onError: (_) {}, onDone: () {});
        } catch (_) {
          // dieser Relay nicht erreichbar — die anderen laufen weiter
        }
      }();
    }

    return completer.future;
  }

  /// Parst RSS 2.0 <item>-Elemente. Bewusst tolerant (RegExp statt XML-Lib),
  /// damit keine zusätzliche Abhängigkeit nötig ist.
  static List<NewsArticle> _parseRss(String xml) {
    final items = <NewsArticle>[];
    final itemRe =
        RegExp(r'<item\b[^>]*>(.*?)</item>', dotAll: true, caseSensitive: false);
    for (final m in itemRe.allMatches(xml)) {
      final block = m.group(1) ?? '';
      final title = _clean(_extract(block, 'title'));
      final link = _clean(_extract(block, 'link'));
      final guid = _clean(_extract(block, 'guid'));
      final author = _clean(_extract(block, 'dc:creator').isNotEmpty
          ? _extract(block, 'dc:creator')
          : _extract(block, 'author'));
      final descRaw = _extract(block, 'description');
      final contentRaw = _extract(block, 'content:encoded').isNotEmpty
          ? _extract(block, 'content:encoded')
          : descRaw;
      final pubDate = _extract(block, 'pubDate');

      String image = '';
      final enc = RegExp(r'<enclosure[^>]*url="([^"]+)"', caseSensitive: false)
          .firstMatch(block);
      if (enc != null) {
        image = enc.group(1) ?? '';
      } else {
        final img = RegExp(r'<img[^>]*src="([^"]+)"', caseSensitive: false)
            .firstMatch(contentRaw);
        if (img != null) image = img.group(1) ?? '';
      }

      if (title.isEmpty && descRaw.isEmpty) continue;

      items.add(NewsArticle(
        id: guid.isNotEmpty ? guid : link,
        pubkey: author,
        dTag: '',
        title: title.isEmpty ? '(ohne Titel)' : title,
        summary: _stripHtml(_clean(descRaw)).trim(),
        image: image,
        content: _clean(contentRaw),
        publishedAt: _parseDate(pubDate),
        topics: const [],
        link: link.isNotEmpty ? link : guid,
      ));
    }
    return items;
  }

  static String _extract(String block, String tag) {
    final re = RegExp(
        '<${RegExp.escape(tag)}\\b[^>]*>(.*?)</${RegExp.escape(tag)}>',
        dotAll: true,
        caseSensitive: false);
    final m = re.firstMatch(block);
    if (m == null) return '';
    return m.group(1) ?? '';
  }

  static String _clean(String s) {
    var out = s.trim();
    out = out.replaceAll(RegExp(r'<!\[CDATA\[', caseSensitive: false), '');
    out = out.replaceAll(']]>', '');
    out = out
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ');
    return out.trim();
  }

  static String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ');

  /// Wandelt den HTML-Inhalt des Feeds in einfaches Markdown um, damit er
  /// im vorhandenen MarkdownView (ohne externe Abhängigkeit) IN DER APP
  /// gerendert werden kann. Deckt die gängigen Elemente ab.
  static String htmlToMarkdown(String html) {
    var s = html;
    // Skripte/Styles komplett raus
    s = s.replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', dotAll: true, caseSensitive: false), '');
    // Überschriften
    for (var i = 1; i <= 6; i++) {
      s = s.replaceAllMapped(
          RegExp('<h$i[^>]*>(.*?)</h$i>', dotAll: true, caseSensitive: false),
          (m) => '\n\n${'#' * i} ${_stripInline(m.group(1) ?? '')}\n\n');
    }
    // Bilder  ![](src)
    s = s.replaceAllMapped(
        RegExp(r'<img[^>]*src="([^"]+)"[^>]*>', caseSensitive: false),
        (m) => '\n\n![](${m.group(1)})\n\n');
    // Links [text](href)
    s = s.replaceAllMapped(
        RegExp(r'<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', dotAll: true, caseSensitive: false),
        (m) => '[${_stripInline(m.group(2) ?? '')}](${m.group(1)})');
    // fett / kursiv
    s = s.replaceAllMapped(RegExp(r'<(strong|b)[^>]*>(.*?)</\1>', dotAll: true, caseSensitive: false),
        (m) => '**${_stripInline(m.group(2) ?? '')}**');
    s = s.replaceAllMapped(RegExp(r'<(em|i)[^>]*>(.*?)</\1>', dotAll: true, caseSensitive: false),
        (m) => '*${_stripInline(m.group(2) ?? '')}*');
    // Listenpunkte
    s = s.replaceAllMapped(RegExp(r'<li[^>]*>(.*?)</li>', dotAll: true, caseSensitive: false),
        (m) => '\n- ${_stripInline(m.group(1) ?? '')}');
    // Zitate
    s = s.replaceAllMapped(RegExp(r'<blockquote[^>]*>(.*?)</blockquote>', dotAll: true, caseSensitive: false),
        (m) => '\n\n> ${_stripInline(m.group(1) ?? '')}\n\n');
    // Absätze / Zeilenumbrüche
    s = s.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    // horizontale Linie
    s = s.replaceAll(RegExp(r'<hr\s*/?>', caseSensitive: false), '\n\n---\n\n');
    // alle übrigen Tags entfernen
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    // Entities
    s = _clean(s);
    // überflüssige Leerzeilen zusammenfassen
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  static String _stripInline(String s) =>
      _clean(s.replaceAll(RegExp(r'<[^>]+>'), '')).trim();

  static int _parseDate(String s) {
    if (s.isEmpty) return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    try {
      final months = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      };
      final m = RegExp(
              r'(\d{1,2})\s+(\w{3})\w*\s+(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?')
          .firstMatch(s.toLowerCase());
      if (m != null) {
        final day = int.parse(m.group(1)!);
        final mon = months[m.group(2)!] ?? 1;
        final year = int.parse(m.group(3)!);
        final hour = int.parse(m.group(4)!);
        final min = int.parse(m.group(5)!);
        final sec = int.tryParse(m.group(6) ?? '0') ?? 0;
        final dt = DateTime.utc(year, mon, day, hour, min, sec);
        return dt.millisecondsSinceEpoch ~/ 1000;
      }
    } catch (_) {}
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
}
