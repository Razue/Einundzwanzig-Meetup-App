import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/app_logger.dart';
import '../services/haptic_service.dart';

/// Zeigt einen npub verkürzt an — aber **immer mit Anfang UND Ende**, und
/// macht ihn benutzbar.
///
/// Warum das nötig war: An mehreren Stellen stand nur der Anfang
/// ("npub1dzu6ceug…"). Damit lässt sich niemand identifizieren und nichts
/// nachschlagen — der npub war reine Dekoration. Zwei npubs derselben
/// Community unterscheiden sich oft erst weiter hinten.
///
/// Antippen öffnet das Profil auf njump.me, langes Drücken kopiert den
/// **vollständigen** npub in die Zwischenablage.
class NpubChip extends StatelessWidget {
  final String npub;

  /// Zeichen am Anfang bzw. Ende. Der Rest wird durch … ersetzt.
  final int head;
  final int tail;

  final TextStyle? style;

  /// Zeigt ein kleines Symbol als Hinweis auf die Antippbarkeit.
  final bool showIcon;

  const NpubChip(
    this.npub, {
    super.key,
    this.head = 10,
    this.tail = 8,
    this.style,
    this.showIcon = true,
  });

  /// Kürzt so, dass Anfang UND Ende sichtbar bleiben.
  static String shorten(String npub, {int head = 10, int tail = 8}) {
    final v = npub.trim();
    if (v.length <= head + tail + 1) return v;
    return '${v.substring(0, head)}…${v.substring(v.length - tail)}';
  }

  Future<void> _openProfile(BuildContext context) async {
    final v = npub.trim();
    if (v.isEmpty) return;
    await HapticService.light();
    // njump.me leitet je nach installierter App weiter und funktioniert
    // auch im Browser — verlässlicher als ein nostr:-Schema, das ohne
    // passende App ins Leere läuft.
    final uri = Uri.parse('https://njump.me/$v');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launchUrl lieferte false');
    } catch (e) {
      AppLogger.warn('Npub', 'Profil konnte nicht geöffnet werden: ${e.runtimeType}');
      if (context.mounted) _copy(context);
    }
  }

  Future<void> _copy(BuildContext context) async {
    final v = npub.trim();
    if (v.isEmpty) return;
    await HapticService.medium();
    await Clipboard.setData(ClipboardData(text: v));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).npubCopied),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final v = npub.trim();
    if (v.isEmpty) return const SizedBox.shrink();

    final text = Text(
      shorten(v, head: head, tail: tail),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (style ?? const TextStyle(color: cTextSecondary, fontSize: 12))
          .copyWith(fontFamily: fontMono),
    );

    return GestureDetector(
      onTap: () => _openProfile(context),
      onLongPress: () => _copy(context),
      behavior: HitTestBehavior.opaque,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(child: text),
        if (showIcon) ...[
          const SizedBox(width: 5),
          Icon(Icons.open_in_new_rounded,
              size: 12, color: (style?.color ?? cTextSecondary).withValues(alpha: 0.8)),
        ],
      ]),
    );
  }
}
