import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/app_logger.dart';
import '../services/haptic_service.dart';
import '../services/nostr_profile_service.dart';
import 'package:nostr/nostr.dart';

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
class NpubChip extends StatefulWidget {
  final String npub;

  /// Zeichen am Anfang bzw. Ende. Der Rest wird durch … ersetzt.
  final int head;
  final int tail;

  final TextStyle? style;

  /// Zeigt ein kleines Symbol als Hinweis auf die Antippbarkeit.
  final bool showIcon;

  /// Anzeigenamen aus dem Nostr-Profil voranstellen.
  ///
  /// Standardmaessig AN: Ein npub allein sagt niemandem, mit wem er es zu
  /// tun hat. Gemeldet wurde es fuer das Vertrauensnetzwerk ("geht da auch
  /// Name?"), betroffen waren aber alle drei Stellen, die diesen Baustein
  /// nutzen — deshalb sitzt die Loesung hier und nicht in einem Bildschirm.
  final bool showName;

  const NpubChip(
    this.npub, {
    super.key,
    this.head = 10,
    this.tail = 8,
    this.style,
    this.showIcon = true,
    this.showName = true,
  });

  @override
  State<NpubChip> createState() => _NpubChipState();

  /// Kürzt so, dass Anfang UND Ende sichtbar bleiben.
  static String shorten(String npub, {int head = 10, int tail = 8}) {
    final v = npub.trim();
    if (v.length <= head + tail + 1) return v;
    return '${v.substring(0, head)}…${v.substring(v.length - tail)}';
  }

}

class _NpubChipState extends State<NpubChip> {
  /// Anzeigename aus dem Nostr-Profil, null solange unbekannt.
  String? _name;

  @override
  void initState() {
    super.initState();
    if (widget.showName) _loadName();
  }

  @override
  void didUpdateWidget(NpubChip old) {
    super.didUpdateWidget(old);
    if (old.npub != widget.npub) {
      _name = null;
      if (widget.showName) _loadName();
    }
  }

  /// Holt den Namen im Hintergrund.
  ///
  /// Der Chip zeigt sofort den gekuerzten npub und tauscht, sobald der Name
  /// da ist — die Liste soll nicht auf ein Relay warten muessen.
  Future<void> _loadName() async {
    final v = widget.npub.trim();
    if (v.isEmpty) return;
    String hex;
    try {
      hex = Nip19.decodePubkey(v);
    } catch (_) {
      return;
    }
    final name = await NostrProfileService.fetchDisplayName(hex);
    if (!mounted) return;
    if (name != null && name.trim().isNotEmpty) {
      setState(() => _name = name.trim());
    }
  }

  Future<void> _openProfile(BuildContext context) async {
    final v = widget.npub.trim();
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
      AppLogger.warn('Npub', 'Profil konnte nicht geöffnet werden', e);
      if (context.mounted) _copy(context);
    }
  }

  Future<void> _copy(BuildContext context) async {
    final v = widget.npub.trim();
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
    final v = widget.npub.trim();
    if (v.isEmpty) return const SizedBox.shrink();

    final base = widget.style ??
        const TextStyle(color: cTextSecondary, fontSize: 12);
    final short = NpubChip.shorten(v, head: widget.head, tail: widget.tail);
    final name = _name;

    // OHNE Namen: wie bisher der gekuerzte npub.
    if (name == null) {
      return GestureDetector(
        onTap: () => _openProfile(context),
        onLongPress: () => _copy(context),
        behavior: HitTestBehavior.opaque,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(short,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(fontFamily: fontMono)),
          ),
          if (widget.showIcon) ...[
            const SizedBox(width: 5),
            Icon(Icons.open_in_new_rounded,
                size: 12,
                color: (base.color ?? cTextSecondary).withValues(alpha: 0.8)),
          ],
        ]),
      );
    }

    // MIT Namen: Name vorn, dahinter klein "npub" mit Kopiersymbol.
    //
    // Der Name ist, was man kennt; der npub ist, was man braucht, um jemanden
    // eindeutig zu finden. Beides gehoert hin — aber nicht gleich gross.
    // Getrennte Tippziele: Der Name oeffnet das Profil, das Kopiersymbol
    // kopiert. Ein einziges Ziel fuer beides waere ein Ratespiel.
    final small = (base.fontSize ?? 12) * 0.78;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
        child: GestureDetector(
          onTap: () => _openProfile(context),
          behavior: HitTestBehavior.opaque,
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: base.copyWith(fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(width: 7),
      GestureDetector(
        onTap: () => _copy(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: cSurface,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: cTileBorder, width: 0.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('npub',
                style: TextStyle(
                    color: cTextTertiary,
                    fontSize: small,
                    fontFamily: fontMono)),
            const SizedBox(width: 4),
            Icon(Icons.copy_rounded, size: small + 1, color: cOrange),
          ]),
        ),
      ),
    ]);
  }
}
