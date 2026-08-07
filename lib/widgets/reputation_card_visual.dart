import 'package:flutter/material.dart';
import '../theme.dart';

/// Die Reputationskarte als teilbares Objekt.
///
/// Bisher war sie ein weisser Kasten mit einem QR-Code darin — funktional,
/// aber nichts, das jemand freiwillig weiterschickt. Das ist eine verpasste
/// Gelegenheit: Wer seine Karte teilt, macht Werbung fuer die App und fuer
/// das Meetup dahinter.
///
/// Deshalb hier: dunkler Grund wie in der App, die Vertrauensstufe als
/// farbgebendes Element, der Wert gross, die Zahlen dahinter kompakt — und
/// der QR-Code als das, was er ist: ein Detail, kein Hauptdarsteller.
///
/// Der QR-Block bleibt bewusst WEISS. Dunkle QR-Codes werden von vielen
/// Kameras schlechter erkannt, und Lesbarkeit geht hier vor Optik.
class ReputationCardVisual extends StatelessWidget {
  final String nickname;
  final double score;
  final String level;
  final int badgeCount;
  final int meetupCount;
  final int signerCount;
  final Widget qrCode;
  final bool isSigned;
  final Color levelColor;
  final IconData levelIcon;
  final String signedLabel;
  final String unsignedLabel;
  final String scoreLabel;
  final String badgesLabel;
  final String meetupsLabel;
  final String signersLabel;

  const ReputationCardVisual({
    super.key,
    required this.nickname,
    required this.score,
    required this.level,
    required this.badgeCount,
    required this.meetupCount,
    required this.signerCount,
    required this.qrCode,
    required this.isSigned,
    required this.levelColor,
    required this.levelIcon,
    required this.signedLabel,
    required this.unsignedLabel,
    required this.scoreLabel,
    required this.badgesLabel,
    required this.meetupsLabel,
    required this.signersLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1D), Color(0xFF0C0C0E)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: levelColor.withValues(alpha: 0.40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: levelColor.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ---- Kopf: Stufe und Name ----
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: levelColor.withValues(alpha: 0.40), width: 1.5),
            ),
            child: Icon(levelIcon, color: levelColor, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                nickname.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: cText, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                level,
                style: TextStyle(
                    color: levelColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
            ]),
          ),
        ]),

        const SizedBox(height: 18),

        // ---- Der Wert ----
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: levelColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: levelColor.withValues(alpha: 0.20), width: 1),
          ),
          child: Column(children: [
            Text(
              scoreLabel.toUpperCase(),
              style: TextStyle(
                  color: levelColor.withValues(alpha: 0.75),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                      color: levelColor, fontSize: 40, fontWeight: FontWeight.w900, height: 1.0)
                  .copyWith(fontFamily: fontMono),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ---- Die Zahlen dahinter ----
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _stat('$badgeCount', badgesLabel, cOrange),
          _divider(),
          _stat('$meetupCount', meetupsLabel, cCyan),
          _divider(),
          _stat('$signerCount', signersLabel, cPurpleLight),
        ]),

        const SizedBox(height: 18),
        Container(height: 1, color: cTileBorder),
        const SizedBox(height: 16),

        // ---- QR: weiss, damit Kameras ihn sicher lesen ----
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: qrCode,
        ),

        const SizedBox(height: 12),

        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isSigned ? Icons.verified_user_rounded : Icons.lock_outline_rounded,
              color: isSigned ? cGreen : cTextTertiary, size: 14),
          const SizedBox(width: 6),
          Text(
            (isSigned ? signedLabel : unsignedLabel).toUpperCase(),
            style: TextStyle(
                color: isSigned ? cGreen : cTextTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4),
          ),
        ]),

        const SizedBox(height: 10),
        Text(
          'EINUNDZWANZIG · PROOF OF ATTENDANCE',
          style: TextStyle(
              color: cTextTertiary.withValues(alpha: 0.65),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4),
        ),
      ]),
    );
  }

  Widget _stat(String value, String label, Color color) => Column(children: [
        Text(value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: cTextSecondary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
      ]);

  Widget _divider() => Container(width: 1, height: 24, color: cTileBorder);
}
