// NEWS-SCREEN — Einundzwanzig Artikel lesen
// ============================================
// Eine schlanke Ansicht:
//   - Button: media.einundzwanzig.space im Browser öffnen.
//   - Darunter: Liste der NIP-23-Artikel (kind 30023) von den Relays,
//     voll lesbar in der App (Markdown gerendert), im App-Design.
// ============================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/news_service.dart';
import '../widgets/markdown_view.dart';

const String _websiteUrl = 'https://media.einundzwanzig.space/s/einundzwanzig-news';

/// Wandelt einen Hex-Pubkey sicher in eine kurze npub-Anzeige um.
String _authorLabel(String author) {
  // Aus dem RSS-Feed kommt der Autor-NAME direkt (nicht mehr ein Hex-Pubkey).
  if (author.isEmpty) return 'Einundzwanzig';
  return author;
}

Future<void> _openWebsite() async {
  final uri = Uri.parse(_websiteUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsArticle> _articles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await NewsService.fetchArticles();
    if (!mounted) return;
    setState(() { _articles = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.newsTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: cTextSecondary),
            tooltip: t.newsOpenWebsite,
            onPressed: _openWebsite,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: cOrange,
        backgroundColor: cCard,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _websiteCard(t),
            const SizedBox(height: 16),
            if (_loading)
              _loadingState(t)
            else if (_articles.isEmpty)
              _emptyState(t)
            else
              ..._articles.map(_articleCard),
            const SizedBox(height: 8),
            Center(child: Text(t.newsSource, style: const TextStyle(color: cTextTertiary, fontSize: 11))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _websiteCard(AppLocalizations t) => GestureDetector(
    onTap: _openWebsite,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF2A1E0A), cCard],
        ),
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cOrange.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.public_rounded, color: cOrange, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.newsOpenWebsite, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('media.einundzwanzig.space', style: const TextStyle(color: cTextTertiary, fontSize: 12)),
        ])),
        const Icon(Icons.open_in_new_rounded, color: cOrange, size: 18),
      ]),
    ),
  );

  Widget _loadingState(AppLocalizations t) => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [
      const CircularProgressIndicator(color: cOrange),
      const SizedBox(height: 14),
      Text(t.newsLoading, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
    ]),
  );

  Widget _emptyState(AppLocalizations t) => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [
      const Icon(Icons.article_outlined, color: cTextTertiary, size: 44),
      const SizedBox(height: 12),
      Text(t.newsEmpty, style: const TextStyle(color: cTextSecondary, fontSize: 14)),
    ]),
  );

  Widget _articleCard(NewsArticle a) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ArticleDetail(article: a))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (a.image.isNotEmpty)
            Image.network(
              a.image, height: 150, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              loadingBuilder: (ctx, child, p) => p == null ? child : Container(height: 150, color: cSurface),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w800, height: 1.3)),
              if (a.summary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(a.summary, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.person_outline_rounded, color: cTextTertiary, size: 13),
                const SizedBox(width: 4),
                Text(_authorLabel(a.pubkey), style: const TextStyle(color: cTextTertiary, fontSize: 11)),
                const Spacer(),
                Text('${a.date.day}.${a.date.month}.${a.date.year}', style: const TextStyle(color: cTextTertiary, fontSize: 11)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ============================================
//  ARTIKEL-DETAIL (voll lesbar, Markdown)
// ============================================
class _ArticleDetail extends StatelessWidget {
  final NewsArticle article;
  const _ArticleDetail({required this.article});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(t.newsTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (article.image.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(kTileRadius),
              child: Image.network(article.image, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
            const SizedBox(height: 18),
          ],
          Text(article.title, style: const TextStyle(color: cText, fontSize: 24, fontWeight: FontWeight.w800, height: 1.25)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.person_outline_rounded, color: cTextTertiary, size: 14),
            const SizedBox(width: 5),
            Text(_authorLabel(article.pubkey), style: const TextStyle(color: cTextTertiary, fontSize: 12)),
            const SizedBox(width: 12),
            Text('${article.date.day}.${article.date.month}.${article.date.year}',
                style: const TextStyle(color: cTextTertiary, fontSize: 12)),
          ]),
          const SizedBox(height: 20),
          // Voller Artikel IN DER APP: HTML aus dem Feed -> Markdown -> Render
          MarkdownView(NewsService.htmlToMarkdown(article.content)),
          const SizedBox(height: 24),
          Center(child: Text(t.newsSource, style: const TextStyle(color: cTextTertiary, fontSize: 11))),
        ],
      ),
    );
  }
}
