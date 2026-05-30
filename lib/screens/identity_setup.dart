// ============================================
// IDENTITY SETUP — Drei Wege zur Nostr-Identität
// ============================================
//
// Niemand wird gezwungen, seinen nsec in der App einzugeben.
//
//   1. Schlüssel generieren — App erzeugt ein neues Keypair.
//   2. nsec importieren     — für bestehende Nostr-Nutzer.
//   3. Mit Amber verbinden  — nsec bleibt in Amber (NIP-55).
//
// Gibt bei Erfolg `true` an den Aufrufer zurück (Navigator.pop).
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/user.dart';
import '../services/nostr_service.dart';
import '../services/signing_service.dart';
import '../services/app_logger.dart';

class IdentitySetupScreen extends StatefulWidget {
  const IdentitySetupScreen({super.key});

  @override
  State<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends State<IdentitySetupScreen> {
  bool _busy = false;
  String? _amberStatus;

  // =============================================
  // 1) SCHLÜSSEL GENERIEREN
  // =============================================
  Future<void> _generateKey() async {
    setState(() => _busy = true);
    try {
      final keys = await NostrService.generateKeyPair();
      await SigningService.useLocalMode();
      await _persistNpub(keys['npub']!);
      if (!mounted) return;
      await _showNsecBackupDialog(keys['nsec']!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('Fehler beim Erstellen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // =============================================
  // 2) NSEC IMPORTIEREN
  // =============================================
  Future<void> _importNsec() async {
    final controller = TextEditingController();
    final nsec = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: const Text('nsec importieren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gib deinen privaten Schlüssel ein (beginnt mit nsec1…).',
              style: TextStyle(color: cTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              style: const TextStyle(color: cText, fontSize: 13),
              decoration: const InputDecoration(hintText: 'nsec1…'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 14, color: cTextTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Dein nsec wird hardware-verschlüsselt gespeichert und '
                    'verlässt dein Gerät nicht.',
                    style: TextStyle(color: cTextTertiary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Importieren'),
          ),
        ],
      ),
    );

    if (nsec == null || nsec.isEmpty) return;
    if (!NostrService.isValidNsec(nsec)) {
      _snack('Ungültiger nsec. Muss mit "nsec1" beginnen.');
      return;
    }

    setState(() => _busy = true);
    try {
      final keys = await NostrService.importNsec(nsec);
      await SigningService.useLocalMode();
      await _persistNpub(keys['npub']!);
      if (!mounted) return;
      _snack('Schlüssel importiert ✓');
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Import fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // =============================================
  // 3) MIT AMBER VERBINDEN
  // =============================================
  Future<void> _connectAmber() async {
    setState(() {
      _busy = true;
      _amberStatus = 'Verbinde mit Amber…';
    });
    try {
      final result = await SigningService.connectAmber();
      if (!mounted) return;

      switch (result) {
        case AmberConnectSuccess(:final npub):
          await _persistNpub(npub, hasLocalKey: false);
          _snack('Mit Amber verbunden ✓  Dein nsec bleibt in Amber.');
          Navigator.pop(context, true);
        case AmberConnectMissing():
          setState(() => _amberStatus = null);
          _showAmberMissingDialog();
        case AmberConnectCancelled():
          setState(() => _amberStatus = null);
          _snack('Verbindung in Amber abgebrochen.');
        case AmberConnectError(:final message):
          setState(() => _amberStatus = null);
          _snack('Amber-Fehler: $message');
      }
    } catch (e) {
      _snack('Unerwarteter Fehler: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // =============================================
  // HELPERS
  // =============================================
  Future<void> _persistNpub(String npub, {bool hasLocalKey = true}) async {
    final user = await UserProfile.load();
    user.nostrNpub = npub;
    user.hasNostrKey = hasLocalKey; // Amber: kein lokaler Key, aber Identität da
    user.isNostrVerified = true;
    await user.save();
    AppLogger.debug('IdentitySetup',
        'Identität gesetzt (${hasLocalKey ? "lokal" : "Amber"}): '
        '${NostrService.shortenNpub(npub)}');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: cCard),
    );
  }

  Future<void> _showNsecBackupDialog(String nsec) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: const Text('Sichere deinen Schlüssel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Das ist dein privater Schlüssel (nsec). Bewahre ihn sicher auf — '
              'er ist dein einziger Zugang. Wer ihn hat, ist du.',
              style: TextStyle(color: cTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(kTileRadius),
                border: Border.all(color: cTileBorder, width: 0.5),
              ),
              child: SelectableText(
                nsec,
                style: TextStyle(
                    color: cOrange, fontSize: 12, fontFamily: fontMono),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: nsec));
              _snack('nsec kopiert — jetzt sicher abspeichern!');
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Kopieren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Gesichert'),
          ),
        ],
      ),
    );
  }

  void _showAmberMissingDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: const Text('Amber nicht gefunden'),
        content: const Text(
          'Amber ist ein separater Signer für Android, der deinen privaten '
          'Schlüssel sicher verwahrt. Installiere Amber (z.B. über F-Droid oder '
          'den Zapstore) und versuche es erneut.',
          style: TextStyle(color: cTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  // =============================================
  // UI
  // =============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text('Identität einrichten')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Wie möchtest du dich anmelden?',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Deine Identität basiert auf einem Nostr-Schlüsselpaar. '
              'Du entscheidest, wo dein privater Schlüssel liegt.',
              style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),

            _OptionCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Neuen Schlüssel erstellen',
              subtitle:
                  'Empfohlen, wenn du noch keinen Nostr-Account hast. Die App '
                  'erzeugt ein neues Schlüsselpaar für dich.',
              accent: cOrange,
              onTap: _busy ? null : _generateKey,
            ),
            const SizedBox(height: 12),

            _OptionCard(
              icon: Icons.shield_rounded,
              title: 'Mit Amber verbinden',
              subtitle:
                  'Maximale Sicherheit: Dein privater Schlüssel bleibt in Amber '
                  'und verlässt diese App niemals. Jede Signatur bestätigst du '
                  'in Amber.',
              accent: cNostr,
              badge: 'EMPFOHLEN',
              onTap: _busy ? null : _connectAmber,
              trailing: _amberStatus,
            ),
            const SizedBox(height: 12),

            _OptionCard(
              icon: Icons.vpn_key_rounded,
              title: 'Bestehenden nsec importieren',
              subtitle:
                  'Du hast schon einen Nostr-Schlüssel? Gib deinen nsec ein. '
                  'Er wird hardware-verschlüsselt auf dem Gerät gespeichert.',
              accent: cTextSecondary,
              onTap: _busy ? null : _importNsec,
            ),

            if (_busy) ...[
              const SizedBox(height: 28),
              const Center(
                child: CircularProgressIndicator(color: cOrange, strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================
// OPTION CARD
// =============================================
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String? badge;
  final String? trailing;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.badge,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius + 2),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                              color: cText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                                color: accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                        color: cTextSecondary, fontSize: 12, height: 1.45),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      trailing!,
                      style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
