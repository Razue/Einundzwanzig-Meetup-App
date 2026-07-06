// SCHLANKER MARKDOWN-RENDERER
// ============================================
// Rendert die gängigen Markdown-Elemente ohne externe Abhängigkeit:
// Überschriften (#..###), Absätze, fett (**), kursiv (*), Inline-Code (`),
// Links [text](url), Bilder ![alt](url), Listen (- / 1.), Zitate (>),
// Codeblöcke (```), horizontale Linien (---).
// Bewusst kompakt gehalten (kein vollständiger CommonMark-Parser).
// ============================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class MarkdownView extends StatefulWidget {
  final String data;
  const MarkdownView(this.data, {super.key});

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defensiv: bei komplett leerem Inhalt nichts rendern.
    if (widget.data.trim().isEmpty) return const SizedBox.shrink();
    List<Widget> blocks;
    try {
      blocks = _parseBlocks(widget.data);
    } catch (_) {
      // Sollte das Parsen an einem ungewöhnlichen Inhalt scheitern, zeigen
      // wir den Text sicher als einfachen Fließtext statt abzustürzen.
      return SelectableText(
        _plainFallback(widget.data),
        style: const TextStyle(color: cText, fontSize: 15, height: 1.6),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  /// Entfernt Markdown-/Bild-Syntax grob und liefert lesbaren Reintext.
  String _plainFallback(String src) {
    var s = src;
    // eingebettete Data-URIs und Bild-Syntax entfernen
    s = s.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '');
    s = s.replaceAll(RegExp(r'data:image/[A-Za-z0-9;,+/=._-]+'), '');
    // Markdown-Zeichen entschärfen
    s = s.replaceAll(RegExp(r'[#*`>]'), '');
    // überlange Ketten ohne Leerzeichen (Base64-Reste) raus
    s = s.split('\n').where((l) => !(l.trim().length > 200 && !l.trim().contains(' '))).join('\n');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
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

      // Bild(er) als eigene Zeile — auch mehrere direkt hintereinander
      // ![](a)![](b) und Data-URIs. Alle Bilder der Zeile rendern.
      final allImgs = RegExp(r'!\[[^\]]*\]\(([^)]+)\)').allMatches(trimmed).toList();
      if (allImgs.isNotEmpty) {
        // Prüfen, ob die Zeile NUR aus Bildern besteht (evtl. mit Leerraum).
        final withoutImgs = trimmed.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '').trim();
        if (withoutImgs.isEmpty) {
          for (final im in allImgs) {
            widgets.add(_image(im.group(1)!));
          }
          i++; continue;
        }
      }
      // Einzelbild mit Data-URI (sehr lange URL) als ganze Zeile.
      final imgMatch = RegExp(r'^!\[[^\]]*\]\((.+)\)$', dotAll: true).firstMatch(trimmed);
      if (imgMatch != null) {
        widgets.add(_image(imgMatch.group(1)!));
        i++; continue;
      }

      // Sicherung: eine überlange "Wort"-Zeile ohne Leerzeichen (z.B. ein
      // rohes Base64-Fragment, das nicht als Bild erkannt wurde) NICHT als
      // Textwüste rendern.
      if (trimmed.length > 200 && !trimmed.contains(' ')) {
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
        final lt = lines[i].trim();
        // Data-URI-Bild inmitten des Textes: als Bild rendern, nicht als Text.
        final inlineImg = RegExp(r'!\[[^\]]*\]\((data:image/[^)]+)\)').firstMatch(lt);
        if (inlineImg != null) {
          if (buf.isNotEmpty) {
            widgets.add(Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _richText(buf.join(' '), const TextStyle(color: cText, fontSize: 15, height: 1.6)),
            ));
            buf.clear();
          }
          widgets.add(_image(inlineImg.group(1)!));
          i++;
          continue;
        }
        // Überlange Kette ohne Leerzeichen (rohes Base64) überspringen.
        if (lt.length > 200 && !lt.contains(' ')) { i++; continue; }
        buf.add(lt); i++;
      }
      if (buf.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _richText(buf.join(' '), const TextStyle(color: cText, fontSize: 15, height: 1.6)),
        ));
      } else {
        // FORTSCHRITTS-GARANTIE: Wurde in diesem Durchlauf keine Zeile
        // konsumiert (buf leer und i unverändert), MUSS i erhöht werden,
        // sonst dreht die äußere while-Schleife endlos -> App friert ein
        // ("reagiert nicht"). Diese Zeile überspringen.
        i++;
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

  Widget _image(String url) {
    final u = url.trim();
    // Data-URI (eingebettetes Base64-Bild): direkt aus dem Text rendern.
    if (u.startsWith('data:image/')) {
      try {
        final comma = u.indexOf(',');
        if (comma == -1) return const SizedBox.shrink();
        final b64 = u.substring(comma + 1);
        // Sehr große eingebettete Bilder können beim Dekodieren den Speicher
        // sprengen -> ab ~3 MB Base64 nicht rendern (Platzhalter zeigen).
        if (b64.length > 3 * 1024 * 1024) {
          return Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(kTileRadius),
              border: Border.all(color: cTileBorder, width: 0.5),
            ),
            child: const Text('🖼  Bild', style: TextStyle(color: cTextTertiary, fontSize: 13)),
          );
        }
        final bytes = base64Decode(b64);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kTileRadius),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );
      } catch (_) {
        return const SizedBox.shrink(); // kaputtes Base64 -> nichts anzeigen
      }
    }
    // Sonst nur echte http(s)-URLs.
    final uri = Uri.tryParse(u);
    if (u.isEmpty || uri == null || !uri.hasScheme || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return const SizedBox.shrink();
    }
    // HEIC/HEIF (Apple-Format) kann Android nicht dekodieren -> würde den
    // Screen abstürzen lassen. Solche Bilder als dezenten Platzhalter zeigen.
    final lower = u.toLowerCase();
    if (lower.contains('.heic') || lower.contains('.heif')) {
      return Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: const Text('🖼  Bild', style: TextStyle(color: cTextTertiary, fontSize: 13)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kTileRadius),
        child: Image.network(
          u,
          fit: BoxFit.cover,
          // Speicher schonen: sehr große Fotos herunterskalieren.
          cacheWidth: 1080,
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
  }

  /// Inline-Formatierung: **fett**, *kursiv*, `code`, [text](url).
  Widget _richText(String text, TextStyle base) {
    try {
      return _buildRichText(text, base);
    } catch (_) {
      // Bei problematischem Inhalt: reiner Text statt Absturz.
      return Text(text, style: base);
    }
  }

  Widget _buildRichText(String text, TextStyle base) {
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
        final recognizer = TapGestureRecognizer()..onTap = () => _open(url);
        _recognizers.add(recognizer); // wird in dispose() freigegeben
        spans.add(TextSpan(
          text: label,
          style: base.copyWith(color: cOrange, decoration: TextDecoration.underline),
          recognizer: recognizer,
        ));
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    // Defensiv: leere Span-Liste würde RichText zum Absturz bringen.
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: base));
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
