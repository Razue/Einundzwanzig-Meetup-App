// ============================================
// BUNKER VERBINDEN — Blatt für den Remote-Signer (NIP-46)
// ============================================
// Eigene Datei, weil der Ablauf drei Zustände hat und in profile_edit.dart
// nur ein Knopf plus die Auswertung des Ergebnisses stehen soll.
//
// Drei Schritte:
//   1. Auswahl — Signer-App (QR/Deep-Link) oder Adresse einfügen
//   2. Signer-App — QR-Code plus Adresse, wartet auf die Gegenseite
//   3. Einfügen — Textfeld für eine bunker://-Adresse
//
// Der Weg über „Adresse einfügen" steht bewusst gleichrangig daneben und nicht
// unter „Erweitert": auf iOS ist er der Hauptweg, denn dort ist nicht
// verlässlich, dass überhaupt eine App `nostrconnect://` beantwortet.
//
// WARTEZEIT: bis zu zwei Minuten, weil am anderen Ende ein Mensch bestätigen
// muss. Deshalb ein sichtbarer Wartezustand MIT Abbrechen und ein Riegel gegen
// mehrfaches Auslösen — ohne beides tippen Nutzer wiederholt, weil sich nichts
// zu bewegen scheint (dieselbe Lektion wie beim Backup, PR #32).
// ============================================

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/signing_service.dart';
import '../theme.dart';

enum _Step { choose, signerApp, paste }

class BunkerConnectSheet extends StatefulWidget {
  const BunkerConnectSheet({super.key});

  /// Öffnet das Blatt. Liefert bei Erfolg das Ergebnis, sonst null.
  static Future<Nip46ConnectSuccess?> show(BuildContext context) =>
      showModalBottomSheet<Nip46ConnectSuccess>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1A1A1A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => const BunkerConnectSheet(),
      );

  @override
  State<BunkerConnectSheet> createState() => _BunkerConnectSheetState();
}

class _BunkerConnectSheetState extends State<BunkerConnectSheet> {
  final _uriController = TextEditingController();

  _Step _step = _Step.choose;

  /// Riegel gegen mehrfaches Auslösen während der langen Wartezeit.
  bool _busy = false;
  String? _error;
  Nip46Pairing? _pairing;

  /// Vom Signer angeforderte Freigabe im Browser. Wird als KNOPF angezeigt —
  /// ein automatisch geöffnetes Fenster blockiert der Browser, weil dann keine
  /// Nutzer-Gestik vorliegt.
  String? _authUrl;

  /// Der App-weite Empfänger, den dieses Blatt nur vorübergehend ersetzt.
  ///
  /// Ihn beim Schließen auf `null` zu setzen wäre falsch: dann ginge jede
  /// spätere Freigabe-Aufforderung verloren, weil der globale Empfänger aus
  /// main.dart mit abgeräumt würde. Hier ist die Aufforderung im Blatt selbst
  /// besser platziert als in einem Balken — aber nur, solange es offen ist.
  void Function(String url)? _previousAuthUrlHandler;

  @override
  void initState() {
    super.initState();
    _previousAuthUrlHandler = SigningService.onNip46AuthUrl;
    SigningService.onNip46AuthUrl = (url) {
      if (mounted) setState(() => _authUrl = url);
    };
  }

  @override
  void dispose() {
    SigningService.onNip46AuthUrl = _previousAuthUrlHandler;
    _uriController.dispose();
    // Eine noch laufende Kopplung muss ihre Relay-Verbindungen freigeben.
    _pairing?.cancel();
    super.dispose();
  }

  // ---------- Abläufe ----------

  Future<void> _startSignerApp() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _authUrl = null;
      _step = _Step.signerApp;
    });

    try {
      final pairing = await SigningService.startNip46Pairing();
      if (!mounted) {
        await pairing.cancel();
        return;
      }
      setState(() => _pairing = pairing);

      final result = await SigningService.completeNip46Pairing(pairing);
      if (!mounted) return;
      _handle(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _connectPasted() async {
    if (_busy) return;
    final input = _uriController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
      _authUrl = null;
    });

    final result = await SigningService.connectNip46Bunker(input);
    if (!mounted) return;
    _handle(result);
  }

  void _handle(Nip46ConnectResult result) {
    final t = AppLocalizations.of(context);
    switch (result) {
      case Nip46ConnectSuccess():
        // _pairing MUSS hier auf null: bei Erfolg hat der SigningService
        // genau diesen Client als laufende Sitzung uebernommen. Wuerde dispose
        // gleich darauf pairing.cancel() rufen, schloss es die eben
        // aufgebaute, LEBENDE Sitzung — die Kopplung haette geklappt und
        // Signieren waere sofort danach unmoeglich gewesen.
        _pairing = null;
        Navigator.pop(context, result);
      case Nip46ConnectTimeout():
        setState(() {
          _busy = false;
          _error = t.bunkerTimeout;
        });
      case Nip46ConnectError(:final message):
        setState(() {
          _busy = false;
          _error = message;
        });
    }
  }

  Future<void> _cancel() async {
    final pairing = _pairing;
    _pairing = null;
    await pairing?.cancel();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _openSignerApp() async {
    final uri = _pairing?.uri;
    if (uri == null) return;
    final t = AppLocalizations.of(context);
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(uri),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    // Auf iOS beantwortet oft KEINE App `nostrconnect://`. Dann ist der
    // Hinweis auf den Einfüge-Weg die einzige brauchbare Auskunft.
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.bunkerNoSignerApp)));
    }
  }

  Future<void> _openAuthUrl() async {
    final url = _authUrl;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {/* nichts zu tun — der Knopf bleibt stehen */}
  }

  // ---------- Aufbau ----------

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      // Während der Wartezeit nicht versehentlich wegwischen: das würde die
      // Kopplung abbrechen, ohne dass es jemand merkt.
      canPop: !_busy,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: cCyan, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.bunkerTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(t.bunkerIntro,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              ...switch (_step) {
                _Step.choose => _chooseStep(t),
                _Step.signerApp => _signerAppStep(t),
                _Step.paste => _pasteStep(t),
              },
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style:
                          const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              ],
              if (_authUrl != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openAuthUrl,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(t.bunkerAuthOpen),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cOrange,
                      side: const BorderSide(color: cOrange),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Nennt Signer beim Namen, passend zur Plattform.
  ///
  /// Die Lage unterscheidet sich dort deutlich: auf Android ist Amber der
  /// eingeführte Weg (NIP-55 plus Bunker), auf iOS gibt es Clave, das sich per
  /// Push weckt, um im Hintergrund zu signieren. Alby gehört ausdrücklich NICHT
  /// dazu — dessen Erweiterung ist ein NIP-07-Signer und kein Bunker, und der
  /// Hub hält Geld, keine Nostr-Identität.
  String _signerRecommendation(AppLocalizations t) {
    if (kIsWeb) return t.bunkerRecommendWeb;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => t.bunkerRecommendAndroid,
      TargetPlatform.iOS => t.bunkerRecommendIos,
      _ => t.bunkerRecommendWeb,
    };
  }

  List<Widget> _chooseStep(AppLocalizations t) => [
        _optionTile(
          icon: Icons.qr_code_2,
          color: cCyan,
          title: t.bunkerModeSigner,
          subtitle: t.bunkerModeSignerDesc,
          onTap: _startSignerApp,
        ),
        const SizedBox(height: 10),
        _optionTile(
          icon: Icons.content_paste,
          color: cGreen,
          title: t.bunkerModePaste,
          subtitle: t.bunkerModePasteDesc,
          onTap: () => setState(() {
            _step = _Step.paste;
            _error = null;
          }),
        ),
        const SizedBox(height: 14),
        // Konkrete Namen statt „irgendeine Signer-App". Ohne sie bleibt die
        // Frage „und woher nehme ich einen?" offen — und dann ist der ganze
        // Verbinden-Weg wertlos, weil der Nutzer keinen Gegenpart hat.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cCyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: cCyan, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_signerRecommendation(t),
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.dialogCancel,
                style: const TextStyle(color: Colors.grey)),
          ),
        ),
      ];

  List<Widget> _signerAppStep(AppLocalizations t) {
    final uri = _pairing?.uri;
    return [
      if (uri == null)
        const Center(
            child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: cCyan),
        ))
      else ...[
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: uri,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(t.bunkerScanHint,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: uri));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.bunkerCopied)));
                  }
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(t.bunkerCopy,
                    style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openSignerApp,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(t.bunkerOpenSigner,
                    style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cCyan,
                  side: const BorderSide(color: cCyan),
                ),
              ),
            ),
          ],
        ),
      ],
      if (_busy) ...[
        const SizedBox(height: 16),
        _waitingRow(t),
      ],
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _cancel,
          child:
              Text(t.dialogCancel, style: const TextStyle(color: Colors.grey)),
        ),
      ),
    ];
  }

  List<Widget> _pasteStep(AppLocalizations t) => [
        TextField(
          controller: _uriController,
          enabled: !_busy,
          maxLines: 3,
          minLines: 1,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            labelText: t.bunkerPasteLabel,
            labelStyle: const TextStyle(color: Colors.grey),
            hintText: t.bunkerPasteHint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
            enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24)),
            focusedBorder:
                const OutlineInputBorder(borderSide: BorderSide(color: cGreen)),
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          _waitingRow(t),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _step = _Step.choose;
                        _error = null;
                      }),
              child: Text(t.bunkerBack,
                  style: const TextStyle(color: Colors.grey)),
            ),
            const Spacer(),
            ElevatedButton(
              // Wichtig: null solange _busy — sonst loest ein zweiter Tipp
              // eine zweite Kopplung aus und die erste bleibt als Zombie offen.
              onPressed: _busy ? null : _connectPasted,
              style: ElevatedButton.styleFrom(backgroundColor: cGreen),
              child: Text(t.bunkerConnect,
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ];

  Widget _waitingRow(AppLocalizations t) => Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: cCyan),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.bunkerWaiting,
                    style: const TextStyle(color: cCyan, fontSize: 12)),
                Text(t.bunkerWaitingHint,
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      );

  Widget _optionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: _busy ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
