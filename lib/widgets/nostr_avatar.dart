// ============================================
// NOSTR AVATAR
// Zeigt das Profilbild aus kind:0 Metadata, mit
// Buchstaben-Fallback (erster Buchstabe des Nicknames).
// Funktioniert modus-unabhängig (lokal & Amber), da der
// pubkey über NostrService.getNpub() aufgelöst wird.
// ============================================

import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';
import '../theme.dart';
import '../services/nostr_service.dart';
import '../services/nostr_profile_service.dart';

class NostrAvatar extends StatefulWidget {
  /// Buchstabe-Fallback (i.d.R. der Nickname).
  final String fallbackText;

  /// Hintergrundfarbe für den Fallback-Kreis.
  final Color backgroundColor;

  /// Radius des Avatars.
  final double radius;

  /// Optional: konkreter pubkey (hex). Wenn null, wird der
  /// pubkey der aktiven Identität verwendet (lokal oder Amber).
  final String? pubkeyHex;

  const NostrAvatar({
    super.key,
    required this.fallbackText,
    this.backgroundColor = cOrange,
    this.radius = 20,
    this.pubkeyHex,
  });

  @override
  State<NostrAvatar> createState() => _NostrAvatarState();
}

class _NostrAvatarState extends State<NostrAvatar> {
  String? _pictureUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(NostrAvatar old) {
    super.didUpdateWidget(old);
    // Identität gewechselt? Neu laden.
    if (old.pubkeyHex != widget.pubkeyHex ||
        old.fallbackText != widget.fallbackText) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      String? hex = widget.pubkeyHex;
      if (hex == null || hex.isEmpty) {
        final npub = await NostrService.getNpub();
        if (npub != null && npub.isNotEmpty) {
          try {
            hex = Nip19.decodePubkey(npub);
          } catch (_) {
            hex = null;
          }
        }
      }
      if (hex == null || hex.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final url = await NostrProfileService.fetchProfilePicture(hex);
      if (mounted) {
        setState(() {
          _pictureUrl = url;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.fallbackText.isNotEmpty
        ? widget.fallbackText[0].toUpperCase()
        : '?';

    final fallback = CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: widget.radius * 0.8,
        ),
      ),
    );

    if (_pictureUrl == null || _pictureUrl!.isEmpty) {
      return fallback;
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: NetworkImage(_pictureUrl!),
      // Wenn das Bild nicht lädt, bleibt der farbige Kreis als Hintergrund.
      onBackgroundImageError: (_, _) {
        if (mounted) setState(() => _pictureUrl = null);
      },
    );
  }
}
