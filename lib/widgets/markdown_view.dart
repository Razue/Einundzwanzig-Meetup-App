// SCHLANKER MARKDOWN-RENDERER
// ============================================
// Rendert die gängigen Markdown-Elemente ohne externe Abhängigkeit:
// Überschriften (#..###), Absätze, fett (**), kursiv (*), Inline-Code (`),
// Links [text](url), Bilder ![alt](url), Listen (- / 1.), Zitate (>),
// Codeblöcke (```), horizontale Linien (---).
// Bewusst kompakt gehalten (kein vollständiger CommonMark-Parser).
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class MarkdownView extends StatelessWidget {
  final String data;
  const MarkdownView(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  List<Widget> _parseBlocks(String src) {
    final lines = src.replaceAll('\r\n', '\n').split('\n');
    final widgets = <Widget>[];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // Leerzeile
      if (trimmed.isEmpty) { i++; continue; }

      // Codeblock ```
      if (trimmed.startsWith('```')) {
        final buf = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          buf.add(lines[i]); i++;
        }
        if (i < lines.length) i++; // schließendes ```
        widgets.add(_codeBlock(buf.join('\n')));
        continue;
      }

      // Horizontale Linie
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: cTileBorder, height: 1),
        ));
        i++; continue;
      }

      // Überschriften
      if (trimmed.startsWith('### ')) { widgets.add(_heading(trimmed.substring(4), 3)); i++; continue; }
      if (trimmed.startsWith('## '))  { widgets.add(_heading(trimmed.substring(3), 2)); i++; continue; }
      if (trimmed.startsWith('# '))   { widgets.add(_heading(trimmed.substring(2), 1)); i++; continue; }

      // Bild ![alt](url) als eigene Zeile
      final imgMatch = RegExp(r'^!\[[^\]]*\]\(([^)]+)\)$').firstMatch(trimmed);
      if (imgMatch != null) {
        widgets.add(_image(imgMatch.group(1)!));
        i++; continue;
      }

      // Zitat >
      if (trimmed.startsWith('> ')) {
        final buf = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('> ')) {
          buf.add(lines[i].trim().substring(2)); i++;
        }
        widgets.add(_quote(buf.join(' ')));
        continue;
      }

      // Aufzählung (- oder *)
      if (RegExp(r'^[-*] ').hasMatch(trimmed)) {
        final items = <String>[];
        while (i < lines.length && RegExp(r'^[-*] ').hasMatch(lines[i].trim())) {
          items.add(lines[i].trim().substring(2)); i++;
        }
        widgets.add(_bulletList(items, ordered: false));
        continue;
      }
      // Nummerierte Liste
      if (RegExp(r'^\d+\. ').hasMatch(trimmed)) {
        final items = <String>[];
        while (i < lines.length && RegExp(r'^\d+\. ').hasMatch(lines[i].trim())) {
          items.add(lines[i].trim().replaceFirst(RegExp(r'^\d+\. '), '')); i++;
        }
        widgets.add(_bulletList(items, ordered: true));
        continue;
      }

      // Absatz: bis zur nächsten Leerzeile sammeln
      final buf = <String>[];
      while (i < lines.length && lines[i].trim().isNotEmpty &&
             !lines[i].trim().startsWith('#') &&
             !lines[i].trim().startsWith('> ') &&
             !lines[i].trim().startsWith('```') &&
             !RegExp(r'^[-*] ').hasMatch(lines[i].trim()) &&
             !RegExp(r'^\d+\. ').hasMatch(lines[i].trim())) {
        buf.add(lines[i].trim()); i++;
      }
      if (buf.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _richText(buf.join(' '), const TextStyle(color: cText, fontSize: 15, height: 1.6)),
        ));
      }
    }
    return widgets;
  }

  Widget _heading(String text, int level) {
    final sizes = {1: 24.0, 2: 20.0, 3: 17.0};
    return Padding(
      padding: EdgeInsets.only(top: level == 1 ? 8 : 16, bottom: 8),
      child: _richText(text, TextStyle(color: cText, fontSize: sizes[level], fontWeight: FontWeight.w800, height: 1.3)),
    );
  }

  Widget _quote(String text) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: cOrange, width: 3)),
    ),
    child: _richText(text, const TextStyle(color: cTextSecondary, fontSize: 15, height: 1.55, fontStyle: FontStyle.italic)),
  );

  Widget _bulletList(List<String> items, {required bool ordered}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (int n = 0; n < items.length; n++)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 1, right: 8),
              child: Text(ordered ? '${n + 1}.' : '•',
                  style: const TextStyle(color: cOrange, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            Expanded(child: _richText(items[n], const TextStyle(color: cText, fontSize: 15, height: 1.5))),
          ]),
        ),
    ]),
  );

  Widget _codeBlock(String code) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: cSurface,
      borderRadius: BorderRadius.circular(kTileRadius),
      border: Border.all(color: cTileBorder, width: 0.5),
    ),
    child: Text(code, style: const TextStyle(color: cTextSecondary, fontSize: 13, fontFamily: 'monospace', height: 1.5)),
  );

  Widget _image(String url) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(kTileRadius),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : Container(
              height: 160, alignment: Alignment.center,
              color: cCard,
              child: const CircularProgressIndicator(color: cOrange, strokeWidth: 2),
            ),
      ),
    ),
  );

  /// Inline-Formatierung: **fett**, *kursiv*, `code`, [text](url).
  Widget _richText(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'(\*\*([^*]+)\*\*)' // **fett**
      r'|(\*([^*]+)\*)'     // *kursiv*
      r'|(`([^`]+)`)'       // `code`
      r'|(\[([^\]]+)\]\(([^)]+)\))', // [text](url)
    );

    int last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      }
      if (m.group(2) != null) {
        spans.add(TextSpan(text: m.group(2), style: base.copyWith(fontWeight: FontWeight.w800)));
      } else if (m.group(4) != null) {
        spans.add(TextSpan(text: m.group(4), style: base.copyWith(fontStyle: FontStyle.italic)));
      } else if (m.group(6) != null) {
        spans.add(TextSpan(text: m.group(6), style: base.copyWith(fontFamily: 'monospace', color: cOrange, fontSize: (base.fontSize ?? 15) - 1)));
      } else if (m.group(8) != null) {
        final label = m.group(8)!;
        final url = m.group(9)!;
        spans.add(TextSpan(
          text: label,
          style: base.copyWith(color: cOrange, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()..onTap = () => _open(url),
        ));
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
