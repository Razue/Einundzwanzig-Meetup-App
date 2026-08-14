// TEILBARE BADGE-KARTE
// ============================================
// Bisher verschickte der Teilen-Knopf eine Textwand: Titel, Datum, Block,
// Signaturart, Pruefsumme. Korrekt, aber niemand postet so etwas.
//
// Diese Karte hat eine FESTE Groesse (kShareCardSize) und haengt an keiner
// Bildschirmbreite. Das ist Absicht: Sie wird nicht angesehen, sondern
// abgemalt — mit RepaintBoundary.toImage(pixelRatio: 3) entsteht daraus ein
// PNG von 1080 x 1440. Waere die Groesse vom Geraet abhaengig, saehe das
// geteilte Bild auf jedem Handy anders aus.
//
// Der Aufbau folgt bewusst der Karte in der Badge-Wallet — dieselbe
// generative Grafik, dasselbe Wappen, dieselbe Handschrift. Wer das Bild
// sieht und spaeter die App oeffnet, erkennt sein Badge wieder.
// ============================================

import 'package:flutter/material.dart';

import '../models/badge.dart';
import '../screens/badge_wallet.dart' show BadgeArtPainter;
import '../theme.dart';
import 'meetup_crest_watermark.dart';

/// Groesse der Karte in logischen Pixeln. Seitenverhaeltnis 3:4 — hochkant,
/// wie es Messenger und soziale Netze am wenigsten beschneiden.
const Size kShareCardSize = Size(360, 480);

class BadgeShareCard extends StatelessWidget {
  final MeetupBadge badge;

  /// Anzeigename des Sammlers, falls vorhanden. Leer lassen heisst: Die
  /// Karte nennt keinen Namen — das Badge gehoert dann sichtbar niemandem,
  /// und genau das kann gewollt sein.
  final String collectorName;

  const BadgeShareCard({
    super.key,
    required this.badge,
    this.collectorName = '',
  });

  String get _dateLine =>
      '${badge.date.day.toString().padLeft(2, '0')}.'
      '${badge.date.month.toString().padLeft(2, '0')}.'
      '${badge.date.year}';

  String get _blockLine {
    if (badge.blockHeight <= 0) return '';
    final s = badge.blockHeight.toString();
    // Tausenderpunkte von hinten — eine Blockhoehe liest sich sonst wie
    // eine zufaellige Ziffernfolge.
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final hash = badge.getVerificationHash();

    return SizedBox(
      width: kShareCardSize.width,
      height: kShareCardSize.height,
      child: Container(
        color: cDark,
        child: Column(children: [
          // --- BILDTEIL ---
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              // Generative Grafik — EXAKT derselbe Startwert wie in der
              // Wallet ("Name:Blockhoehe"). Nur so traegt das geteilte Bild
              // dasselbe Muster wie das Badge in der App; ein anderer
              // Startwert ergaebe ein anderes Muster fuer dasselbe Badge.
              CustomPaint(
                  painter: BadgeArtPainter(
                      seed: '${badge.meetupName}:${badge.blockHeight}')),

              MeetupCrestWatermark(
                meetupName: badge.meetupName,
                imageUrl:
                    badge.coverUrl.isNotEmpty ? badge.coverUrl : null,
                opacity: 0.26,
              ),

              // Verlauf nach unten, damit die Schrift auf jedem Muster
              // lesbar bleibt — ohne ihn verschwindet heller Text auf
              // hellen Stellen der Grafik.
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      cDark.withValues(alpha: 0.65),
                      cDark,
                    ],
                    stops: const [0.35, 0.78, 1.0],
                  ),
                ),
              ),

              // Kopfzeile
              Positioned(
                top: 20,
                left: 22,
                right: 22,
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: cOrange.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: cOrange.withValues(alpha: 0.5), width: 0.5),
                    ),
                    child: Text(
                      badge.isEvent ? 'EVENT-BADGE' : 'MEETUP-BADGE',
                      style: const TextStyle(
                          color: cOrange,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2),
                    ),
                  ),
                  const Spacer(),
                  if (badge.isNostrSigned)
                    const Icon(Icons.verified_rounded,
                        color: cGreen, size: 18),
                ]),
              ),

              // Titelblock unten
              Positioned(
                left: 22,
                right: 22,
                bottom: 18,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge.meetupName.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: cText,
                            fontSize: 26,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _dateLine,
                        style: const TextStyle(
                            color: cOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8),
                      ),
                    ]),
              ),
            ]),
          ),

          // --- FUSSTEIL: die Belege ---
          Container(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
            color: cCard,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (collectorName.isNotEmpty) ...[
                    _footRow(Icons.person_rounded, 'Gesammelt von',
                        collectorName),
                    const SizedBox(height: 8),
                  ],
                  if (_blockLine.isNotEmpty) ...[
                    _footRow(Icons.link_rounded, 'Block', _blockLine,
                        mono: true, accent: true),
                    const SizedBox(height: 8),
                  ],
                  if (hash.isNotEmpty)
                    _footRow(Icons.fingerprint_rounded, 'Prüfsumme',
                        hash.length > 16 ? '${hash.substring(0, 16)}…' : hash,
                        mono: true),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.bolt_rounded, color: cOrange, size: 13),
                    const SizedBox(width: 5),
                    const Text('EINUNDZWANZIG',
                        style: TextStyle(
                            color: cTextSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4)),
                    const Spacer(),
                    Text('21meetup.space',
                        style: TextStyle(
                            color: cTextTertiary.withValues(alpha: 0.8),
                            fontSize: 9.5,
                            letterSpacing: 0.4)),
                  ]),
                ]),
          ),
        ]),
      ),
    );
  }

  Widget _footRow(IconData icon, String label, String value,
      {bool mono = false, bool accent = false}) {
    return Row(children: [
      Icon(icon, color: cTextTertiary, size: 13),
      const SizedBox(width: 7),
      Text('$label  ',
          style: const TextStyle(
              color: cTextTertiary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3)),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: TextStyle(
              color: accent ? cOrange : cText,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFamily: mono ? 'monospace' : null),
        ),
      ),
    ]);
  }
}
