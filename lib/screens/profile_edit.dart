import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../services/meetup_service.dart';
import '../services/nostr_service.dart';
import '../services/signing_service.dart';
import '../services/nip49.dart';
import '../services/local_key_vault.dart';
import '../services/secure_key_store.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/nostr_avatar.dart';
import '../widgets/meetup_search_sheet.dart';
import 'app_shell.dart';
import 'bunker_connect_sheet.dart';
import 'platform_proof_screen.dart';
import 'humanity_proof_screen.dart';
import '../services/platform_proof_service.dart';
import '../services/humanity_proof_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nicknameController = TextEditingController();

  List<String> _selectedFavorites = [];
  String _selectedHomeMeetup = "";
  bool _homeMeetupMissing = false; // Pflichtfeld-Markierung Home-Meetup
  List<Meetup> _allMeetups = [];

  UserProfile? _user;
  bool _isLoading = true;
  bool _isEditing = false;

  // Nostr Key State
  bool _hasNostrKey = false;
  bool _isAmber = false; // Identität über Amber (kein lokaler nsec)
  bool _isNip07 = false; // Identität über Browsererweiterung (kein lokaler nsec)
  bool _isNip46 = false; // Identität über Remote-Signer/Bunker (kein lokaler nsec)

  /// Kann die App im aktuellen Modus ueberhaupt signieren?
  ///
  /// Entscheidet mit, ob der aktive Signer erneut angeboten wird. Ohne das
  /// entstand eine Sackgasse: nach einem Backup-Restore ist der Modus nip46,
  /// der Sitzungsschluessel fehlt aber (der reist nicht mit) — und weil der
  /// aktive Modus aus der Auswahl ausgeschlossen war, gab es auf iOS keinen
  /// einzigen Knopf mehr, um den Signer neu zu verbinden.
  bool _canSign = false;
  /// Ist ueberhaupt eine NIP-07-Erweiterung im Browser? Ausserhalb des
  /// Browsers immer false — dann wird der Knopf gar nicht angeboten, statt
  /// ihn anzuzeigen und beim Tippen "nicht gefunden" zu melden.
  bool _nip07Available = false;
  String _nostrNpub = "";
  bool _isGeneratingKey = false;

  // Amber ist aktuell nur über den nativen Android-MethodChannel angebunden.
  // Im Web bleibt der Button bis zur Implementierung von NIP-46 verborgen,
  // damit keine Verbindung angeboten wird, die dort noch nicht funktioniert.
  bool get _showAmberOption =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // Identity State
  int _platformProofCount = 0;
  bool _humanityVerified = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await UserProfile.load();
    final meetups = await MeetupService.fetchMeetups();
    meetups.sort((a, b) => a.city.compareTo(b.city));

    final hasKey = await NostrService.hasKey();
    final npub = await NostrService.getNpub();
    final isAmber = await SigningService.isAmber;
    final amberSupported = SigningService.isAmberSupported;
    final isNip07 = await SigningService.isNip07;
    final nip07Available = await SigningService.nip07ExtensionAvailable();
    final isNip46 = await SigningService.isNip46;
    final canSign = await SigningService.canSign();

    // Identity Layer Status
    int proofCount = 0;
    bool humanity = false;
    try {
      final proofs = await PlatformProofService.getSavedProofs();
      proofCount = proofs.length;
      final hStatus = await HumanityProofService.getStatus();
      humanity = hStatus.verified;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _user = user;
        _allMeetups = meetups;

        _nicknameController.text = user.nickname;
        _selectedHomeMeetup = user.homeMeetupId;
        _selectedFavorites = user.favoriteMeetupIds.isNotEmpty
            ? List<String>.from(user.favoriteMeetupIds)
            : (user.homeMeetupId.isNotEmpty ? [user.homeMeetupId] : <String>[]);

        _isAmber = isAmber && amberSupported;
        _isNip07 = isNip07;
        _nip07Available = nip07Available;
        _isNip46 = isNip46;
        _canSign = canSign;
        // Im Amber-Modus gibt es keinen lokalen nsec, aber eine gültige
        // Identität → als AppLocalizations.of(context).profileKeyActive anzeigen (npub vorhanden).
        _hasNostrKey =
            hasKey || (isAmber && amberSupported) || isNip07 || isNip46;
        _nostrNpub = npub ?? user.nostrNpub;

        _platformProofCount = proofCount;
        _humanityVerified = humanity;

        _isEditing = !user.isAdminVerified;
        _isLoading = false;
      });
    }
  }

  /// Aktualisiert NUR den Identity-Status (Platform Proofs, Humanity)
  /// OHNE die Formular-Felder (Nickname, Meetup) zu überschreiben.
  /// Wird aufgerufen wenn man von PlatformProofScreen/HumanityProofScreen zurückkehrt.
  Future<void> _refreshIdentityOnly() async {
    try {
      final proofs = await PlatformProofService.getSavedProofs();
      final hStatus = await HumanityProofService.getStatus();
      if (mounted) {
        setState(() {
          _platformProofCount = proofs.length;
          _humanityVerified = hStatus.verified;
        });
      }
    } catch (_) {}
  }

  // --- NOSTR KEY GENERIEREN ---
  /// Ausführlicher Erklär-Dialog (Onboarding) — erklärt Nostr-Neulingen,
  /// was npub/nsec sind, wofür die Identität nutzbar ist und wie man sie
  /// schützt. Gibt true zurück, wenn der Nutzer den Schlüssel erstellen will.
  Future<bool?> _showKeyEducationDialog() {
    final t = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cCard,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kopf
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.key_rounded, color: cOrange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(t.keyEduTitle,
                    style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800))),
              ]),
            ),
            // Scrollbarer Inhalt
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.keyEduIntro, style: const TextStyle(color: cTextSecondary, fontSize: 13.5, height: 1.55)),
                  const SizedBox(height: 18),
                  _eduSection(Icons.public_rounded, cCyan, t.keyEduWhatNostrH, t.keyEduWhatNostrB),
                  _eduSection(Icons.vpn_key_rounded, cOrange, t.keyEduPairH, t.keyEduPairB),
                  _eduSection(Icons.badge_outlined, cGreen, t.keyEduNpubH, t.keyEduNpubB),
                  // nsec = Warnung, rot hervorgehoben
                  _eduSection(Icons.warning_amber_rounded, cRed, t.keyEduNsecH, t.keyEduNsecB, highlight: true),
                  // Im Browser ist der Schluessel schwaecher geschuetzt als in
                  // den native Apps — das muss der Nutzer wissen, BEVOR er
                  // einen Schluessel anlegt. Siehe _webKeyWarning().
                  if (kIsWeb)
                    _eduSection(Icons.public_off_rounded, cRed, t.webKeyWarnH,
                        '${t.webKeyWarnB}\n\n${t.webKeyWarnAdvice}',
                        highlight: true),
                  _eduSection(Icons.hub_rounded, cCyan, t.keyEduIdentityH, t.keyEduIdentityB),
                  // Schutz-Checkliste
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.shield_rounded, color: cOrange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t.keyEduProtectH,
                        style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 10),
                  _eduCheck(t.keyEduProtect1),
                  _eduCheck(t.keyEduProtect2),
                  _eduCheck(t.keyEduProtect3),
                  _eduCheck(t.keyEduProtect4),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    label: Text(t.keyEduUnderstood, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(t.keyEduCancel, style: const TextStyle(color: cTextSecondary)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  /// Warnung für die Web-Version: dort landet der Schlüssel im localStorage
  /// des Browsers. flutter_secure_storage_web verschlüsselt ihn zwar, legt
  /// den dafür nötigen Schlüssel aber im gleichen localStorage ab — wer den
  /// Speicher lesen kann, kommt an den nsec. Auf iOS/Android greift dagegen
  /// Keychain bzw. Android Keystore.
  /// Kompakte Variante für Dialoge ohne _eduSection-Aufbau.
  Widget _webKeyWarning(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: cRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cRed.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.public_off_rounded, color: cRed, size: 16),
          const SizedBox(width: 7),
          Expanded(
              child: Text(t.webKeyWarnH,
                  style: const TextStyle(
                      color: cRed, fontSize: 13, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 6),
        Text(t.webKeyWarnB,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12, height: 1.45)),
        const SizedBox(height: 6),
        Text(t.webKeyWarnAdvice,
            style: const TextStyle(
                color: cRed, fontSize: 12, height: 1.45, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  /// Ein Abschnitt im Erklär-Dialog (Icon + Überschrift + Text).
  Widget _eduSection(IconData icon, Color color, String title, String body, {bool highlight = false}) {
    final content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: TextStyle(color: highlight ? color : cText, fontSize: 15, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 6),
      Text(body, style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.55)),
    ]);
    if (highlight) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
        ),
        child: content,
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: content);
  }

  Widget _eduCheck(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.only(top: 1, right: 8),
        child: Icon(Icons.check_circle_rounded, color: cGreen, size: 16),
      ),
      Expanded(child: Text(text, style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.45))),
    ]),
  );

  void _generateNostrKey() async {
    final confirm = await _showKeyEducationDialog();
    if (confirm != true) return;

    setState(() => _isGeneratingKey = true);

    try {
      final keys = await NostrService.generateKeyPair();
      await SigningService.useLocalMode(); // lokaler Modus aktiv
      // Neuer Key → alte EasyAuth-Wraps gehoeren zur vorherigen Identitaet.
      await LocalKeyVault.clearAll();

      setState(() {
        _hasNostrKey = true;
        // Alle externen Modi zurueckstellen: useLocalMode() hat den Modus
        // schon umgestellt, die Anzeige muss folgen. `_isNip07` fehlte hier
        // bisher — wer im Erweiterungs-Modus einen neuen Schluessel erzeugte,
        // sah danach weiterhin die Erweiterungs-Ansicht.
        _isAmber = false;
        _isNip07 = false;
        _isNip46 = false;
        _nostrNpub = keys['npub']!;
        _isGeneratingKey = false;
      });

      if (mounted) {
        _showNsecBackupDialog(keys['nsec']!);
      }
    } catch (e) {
      setState(() => _isGeneratingKey = false);
      if (mounted) {
        _showError(AppLocalizations.of(context).errorGeneric(e.toString()));
      }
    }
  }

  // --- MIT BROWSERERWEITERUNG VERBINDEN (NIP-07) ---
  // Das Gegenstueck zu Amber im Browser. Der Schluessel bleibt in der
  // Erweiterung — im Web der einzige Weg, bei dem der nsec NICHT in
  // localStorage liegen muss.
  void _connectNip07() async {
    if (!await _confirmSignerSwitch()) return;
    if (!mounted) return;
    final previousNpub = _nostrNpub;
    setState(() => _isGeneratingKey = true);
    try {
      final result = await SigningService.connectNip07();
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      switch (result) {
        case Nip07ConnectSuccess(:final npub):
          setState(() {
            _hasNostrKey = true;
            _isNip07 = true;
            _isAmber = false;
            _isNip46 = false;
            _canSign = true;
            _nostrNpub = npub;
            _isGeneratingKey = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t.profileExtensionConnected),
            backgroundColor: Colors.green,
          ));
          _warnIfIdentityChanged(previousNpub, npub);
        case Nip07ConnectMissing():
          setState(() {
            _isGeneratingKey = false;
            _nip07Available = false; // Knopf verschwindet
          });
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.profileExtensionNotFound)));
        case Nip07ConnectRejected():
          // Bewusste Entscheidung des Nutzers — kein roter Balken.
          setState(() => _isGeneratingKey = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.profileExtensionAborted)));
        case Nip07ConnectError(:final message):
          setState(() => _isGeneratingKey = false);
          _showError(t.errorGeneric(message));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingKey = false);
        _showError(AppLocalizations.of(context).errorGeneric(e.toString()));
      }
    }
  }

  /// Fehlermeldung anzeigen — EINE Regel statt sechsmal derselben Zeile.
  ///
  /// Zehn Sekunden statt der vier der Vorgabe, plus Schliessen-Symbol. Grund:
  /// diese Meldungen tragen den Grund einer Gegenstelle („Der Signer hat
  /// abgelehnt: Permission denied for sign_event kind:21003"), sind also lang
  /// und verlangen danach eine Handlung. In vier Sekunden sind sie weg, bevor
  /// sie gelesen sind — genau das ist beim Testen aufgefallen.
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 10),
      showCloseIcon: true,
    ));
  }

  bool _checkingBunker = false;

  /// Rueckfrage, bevor ein externer Signer eine BESTEHENDE Identitaet ersetzt.
  ///
  /// Der Signer bringt seinen eigenen Schluessel mit. Enthaelt er nicht denselben
  /// wie bisher, wechselt der sichtbare npub — und alle Badges gehoeren weiter
  /// zum alten Schluessel. Ohne Rueckfrage passierte das mit einem Tipp.
  ///
  /// Der bisherige Schluessel wird dabei NICHT geloescht: er bleibt im Keystore
  /// und im Backup, der Wechsel ist also umkehrbar.
  Future<bool> _confirmSignerSwitch() async {
    if (!_hasNostrKey) return true;
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: Text(t.profileSwitchSignerTitle,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(t.profileSwitchSignerBody,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.dialogCancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cCyan),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.profileSwitchSignerContinue,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// Trennt den aktiven externen Signer.
  ///
  /// Gab es bisher fuer KEINEN der drei Signer eine Oberflaeche —
  /// disconnectAmber() und disconnectNip07() existierten, waren aber von
  /// nirgends erreichbar. Wer einen Signer losbekommen wollte, musste die App
  /// zuruecksetzen und damit alles verlieren.
  Future<void> _disconnectSigner() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: Text(t.profileDisconnectTitle,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(t.profileDisconnectBody,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.dialogCancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.profileDisconnectSigner,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      if (_isNip46) {
        await SigningService.disconnectNip46();
      } else if (_isNip07) {
        await SigningService.disconnectNip07();
      } else if (_isAmber) {
        await SigningService.disconnectAmber();
      }
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context).errorGeneric(e.toString()));
      }
      return;
    }

    // Vollstaendig neu laden: der Modus ist jetzt local, und davon haengt ab,
    // ob ueberhaupt noch ein Schluessel da ist (dann bleibt die Identitaet)
    // oder nicht (dann erscheint der Zweig "kein Schluessel").
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).profileDisconnectDone),
      backgroundColor: Colors.green,
    ));
  }

  /// Warnt, wenn der neue Signer eine ANDERE Identitaet mitbringt.
  void _warnIfIdentityChanged(String previousNpub, String newNpub) {
    if (previousNpub.isEmpty || previousNpub == newNpub) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).profileIdentityChanged),
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 6),
    ));
  }

  /// Fragt den Signer mit einem ping, ob die Sitzung noch gilt.
  Future<void> _checkBunkerSession() async {
    setState(() => _checkingBunker = true);
    final alive = await SigningService.nip46SessionAlive();
    if (!mounted) return;
    setState(() => _checkingBunker = false);
    final t = AppLocalizations.of(context);
    // Der Fehlerfall bleibt laenger stehen: er verlangt eine Handlung
    // (Signer oeffnen oder neu verbinden), die Bestaetigung nicht.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(alive ? t.bunkerAlive : t.bunkerDead),
      backgroundColor: alive ? Colors.green : Colors.red,
      duration: Duration(seconds: alive ? 3 : 10),
      showCloseIcon: !alive,
    ));
  }

  // --- MIT REMOTE-SIGNER VERBINDEN (NIP-46 / Bunker) ---
  // Der einzige externe Signer, der auf JEDER Plattform funktioniert — und auf
  // iOS der einzige ueberhaupt. Der Ablauf steckt in BunkerConnectSheet, weil
  // er drei Zustaende und eine lange Wartezeit hat; hier bleibt nur die
  // Auswertung.
  void _connectBunker() async {
    if (!await _confirmSignerSwitch()) return;
    if (!mounted) return;
    final previousNpub = _nostrNpub;

    final result = await BunkerConnectSheet.show(context);
    if (result == null || !mounted) return;
    setState(() {
      _hasNostrKey = true;
      _isNip46 = true;
      _isAmber = false;
      _isNip07 = false;
      _canSign = true;
      _nostrNpub = result.npub;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).bunkerConnected),
      backgroundColor: Colors.green,
    ));
    _warnIfIdentityChanged(previousNpub, result.npub);
  }

  // --- NSEC IMPORTIEREN ---
  // --- MIT AMBER VERBINDEN (NIP-55, nsec bleibt in Amber) ---
  void _connectAmber() async {
    if (!await _confirmSignerSwitch()) return;
    if (!mounted) return;
    final previousNpub = _nostrNpub;
    setState(() => _isGeneratingKey = true);
    try {
      final result = await SigningService.connectAmber();
      if (!mounted) return;
      switch (result) {
        case AmberConnectSuccess(:final npub):
          setState(() {
            _hasNostrKey = true;
            _isAmber = true;
            _isNip07 = false;
            _isNip46 = false;
            _canSign = true;
            _nostrNpub = npub;
            _isGeneratingKey = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).profileAmberConnected),
              backgroundColor: Colors.green,
            ),
          );
          _warnIfIdentityChanged(previousNpub, npub);
        case AmberConnectMissing():
          setState(() => _isGeneratingKey = false);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: cCard,
              title: Text(AppLocalizations.of(context).profileAmberNotFound,
                  style: TextStyle(color: Colors.white)),
              content: Text(
                AppLocalizations.of(context).profileAmberDesc +
                AppLocalizations.of(context).profileAmberInstall +
                AppLocalizations.of(context).profileAmberRetry,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("OK", style: TextStyle(color: cOrange)),
                ),
              ],
            ),
          );
        case AmberConnectCancelled():
          setState(() => _isGeneratingKey = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).profileAmberAborted)),
          );
        case AmberConnectError(:final message):
          setState(() => _isGeneratingKey = false);
          _showError(AppLocalizations.of(context).errorAmber(message));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingKey = false);
        _showError(AppLocalizations.of(context).errorGeneric(e.toString()));
      }
    }
  }

  void _importNsec() {
    final nsecController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Text(AppLocalizations.of(context).profileImportNsecShort, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).profileEnterNsec,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            // Der Import ist der heiklere Pfad: hier traegt jemand einen
            // BESTEHENDEN Schluessel ein, oft den seiner echten Identitaet.
            // Deshalb steht die Warnung direkt ueber dem Eingabefeld.
            if (kIsWeb) ...[
              const SizedBox(height: 14),
              _webKeyWarning(context),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: nsecController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
              maxLines: 1,
              decoration: InputDecoration(
                hintText: "nsec1...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: cDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: cOrange),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).profileNsecNeverLeaves,
              style: const TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).dialogCancel, style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange),
            onPressed: () async {
              final nsec = nsecController.text.trim();
              if (nsec.isEmpty) return;

              try {
                final keys = await NostrService.importNsec(nsec);
                await SigningService.useLocalMode(); // lokaler Modus aktiv
                await LocalKeyVault.clearAll();
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _hasNostrKey = true;
                    _isAmber = false;
                    _isNip07 = false;
                    _isNip46 = false;
                    _nostrNpub = keys['npub']!;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context).profileKeyImported),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  _showError("$e");
                }
              }
            },
            child: Text(AppLocalizations.of(context).profileImport, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- NSEC BACKUP DIALOG ---
  void _showNsecBackupDialog(String nsec) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).profileSecureKey, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).profileSaveKeyDesc +
              AppLocalizations.of(context).profileWhoHasKey,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: SelectableText(
                nsec,
                style: const TextStyle(
                  color: Colors.orange,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).profileKeyNotShownAgain,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange),
            icon: const Icon(Icons.copy, color: Colors.white, size: 18),
            label: Text(AppLocalizations.of(context).profileCopy, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: nsec));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).profileNsecCopied), backgroundColor: cOrange),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).profileKeySecured, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  bool _exportingKey = false;

  // --- VERSCHLÜSSELTER SCHLÜSSEL-EXPORT (NIP-49 `ncryptsec`) ---
  //
  // Der fehlende Baustein für den Umzug in einen Signer: bisher konnte man den
  // Schlüssel nur als nackten nsec herausholen oder im app-eigenen Backup, das
  // keine andere App liest. `ncryptsec1…` ist passwortverschlüsselt und wird
  // von Amber, Clave, Signet, nsec.app und den üblichen Clients importiert.
  //
  // Die Ableitung (scrypt, 2^16 Runden) dauert: gemessen 0,4 s auf dem Gerät
  // und rund 38 s im Browser. Deshalb ein Riegel gegen Mehrfachauslösung, ein
  // sichtbarer Wartezustand am Knopf und ein Hinweis auf die Dauer im Dialog.
  //
  // Der Riegel greift SOFORT — nicht erst nach dem Passwort-Dialog. Sonst
  // oeffnen Mehrfach-Tipps mehrere Dialoge und starten parallele scrypt-Laeufe
  // (je ~64 MB bei log_n=16).
  Future<void> _exportNcryptsec({bool forceNewPassword = false}) async {
    if (_exportingKey) return;
    setState(() => _exportingKey = true);
    try {
      final t = AppLocalizations.of(context);

      final privHex = await SecureKeyStore.getPrivHex();
      if (!mounted) return;
      if (privHex == null || privHex.isEmpty) {
        _showError(t.keyExportNoKey);
        return;
      }

      // Kurzschluss nur wenn der Vault-Wrap ZU DIESEM Key gehoert.
      // Nach nsec-Import kann ein alter Wrap noch liegen — den herauszugeben
      // waere die falsche Identitaet.
      final existing =
          forceNewPassword ? null : await LocalKeyVault.getPasswordWrap();
      final npub = await SecureKeyStore.getNpub();
      if (!mounted) return;
      if (existing != null &&
          existing.isNotEmpty &&
          npub != null &&
          await LocalKeyVault.passwordWrapMatchesNpub(npub)) {
        setState(() => _exportingKey = false);
        _showNcryptsecSheet(t, existing, fromVault: true);
        return;
      }

      final password = await _promptExportPassword(t);
      if (password == null || !mounted) return;

      String? ncryptsec;
      String? error;
      try {
        // Kurz atmen lassen, damit der Wartezustand am Knopf wirklich gezeichnet
        // wird, bevor die Rechnung den Faden belegt.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        ncryptsec = await Nip49.encrypt(
          privHex,
          password,
          // Der Schlüssel lag in dieser App im Klartext vor und wird gerade
          // exportiert — „war nie unsicher unterwegs" wäre eine Lüge.
          keySecurity: KeySecurity.insecure,
        );
      } on Nip49Exception catch (e) {
        error = e.message;
      } catch (e) {
        error = e.toString();
      }
      if (!mounted) return;

      if (ncryptsec == null) {
        _showError(t.errorGeneric(error ?? '?'));
        return;
      }
      _showNcryptsecSheet(t, ncryptsec);
    } finally {
      if (mounted) {
        setState(() => _exportingKey = false);
      } else {
        _exportingKey = false;
      }
    }
  }

  /// Passwort mit Bestätigung — ein Tippfehler hier macht den Export
  /// unbrauchbar, und das fällt erst beim Wiederherstellen auf.
  Future<String?> _promptExportPassword(AppLocalizations t) {
    var password = '';
    var confirm = '';
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cCard,
          title: Text(t.keyExportTitle,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.keyExportDesc,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: t.backupPassword,
                  labelStyle: const TextStyle(color: Colors.grey),
                  errorText: errorText,
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                ),
                onChanged: (v) {
                  password = v;
                  setDialogState(() => errorText = null);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: t.backupPasswordConfirm,
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                ),
                onChanged: (v) => confirm = v,
              ),
              const SizedBox(height: 10),
              Text(t.keyExportDuration,
                  style: const TextStyle(color: cOrange, fontSize: 11)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(t.dialogCancel,
                  style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: cGreen),
              onPressed: () {
                if (password.isEmpty) {
                  setDialogState(() => errorText = t.backupPasswordEmpty);
                  return;
                }
                if (password != confirm) {
                  setDialogState(() => errorText = t.keyExportMismatch);
                  return;
                }
                Navigator.pop(ctx, password);
              },
              child: Text(t.keyExportAction,
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNcryptsecSheet(
    AppLocalizations t,
    String ncryptsec, {
    bool fromVault = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.lock_outline, color: cGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.keyExportReadyTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(t.keyExportReadyBody,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (fromVault) ...[
              const SizedBox(height: 8),
              Text(t.keyExportFromVault,
                  style: const TextStyle(color: cGreen, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                ncryptsec,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'monospace', fontSize: 11),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: cGreen),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: ncryptsec));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t.keyExportCopied),
                    backgroundColor: Colors.green,
                  ));
                },
                icon: const Icon(Icons.copy, size: 18, color: Colors.black),
                label: Text(t.keyExportCopy,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            if (fromVault)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _exportNcryptsec(forceNewPassword: true);
                  },
                  child: Text(t.keyExportOtherPassword,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- NSEC ANZEIGEN (für bestehende Keys) ---
  void _showExistingNsec() async {
    final keys = await NostrService.loadKeys();
    if (keys == null || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Text(AppLocalizations.of(context).profileShowNsecQ, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
          AppLocalizations.of(context).profileShowNsecWarn,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).dialogCancel, style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).profileShow, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _showNsecBackupDialog(keys['nsec']!);
    }
  }

  // --- MEETUP PICKER ---
  void _showMeetupPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return MeetupSearchSheet(
          meetups: _allMeetups,
          initialSelected: _selectedFavorites,
          onDone: (favs) {
            setState(() {
              _selectedFavorites = favs;
              // homeMeetupId = erster Favorit (Anker fuers Widget).
              _selectedHomeMeetup = favs.isNotEmpty ? favs.first : '';
              _homeMeetupMissing = favs.isEmpty;
            });
          },
        );
      },
    );
  }

  // --- SPEICHERN ---
  Future<void> _saveProfile() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final homeMeetupOk = _selectedHomeMeetup.trim().isNotEmpty;

    // Home-Meetup-Markierung aktualisieren
    setState(() => _homeMeetupMissing = !homeMeetupOk);

    if (!formOk || !homeMeetupOk) {
      // Klarer Hinweis statt stillem Nichts-Passieren
      final missing = <String>[];
      if (!formOk) missing.add(AppLocalizations.of(context).profileNickname);
      if (!homeMeetupOk) missing.add(AppLocalizations.of(context).profileHomeMeetupDash);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cRed,
            content: Text(AppLocalizations.of(context).profileFillIn(missing.join(' und '))),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final newUser = UserProfile(
      nickname: _nicknameController.text.trim(),
      fullName: _user?.fullName ?? '', // Behalten falls vorhanden
      homeMeetupId: _selectedHomeMeetup,
      // WICHTIG: ohne diese Zeile wuerde JEDES Profil-Speichern die
      // Favoritenliste auf [] zuruecksetzen (neues UserProfile-Objekt!).
      favoriteMeetupIds: _selectedFavorites.isNotEmpty
          ? _selectedFavorites
          : (_selectedHomeMeetup.isNotEmpty ? [_selectedHomeMeetup] : const []),
      nostrNpub: _nostrNpub,
      telegramHandle: _user?.telegramHandle ?? '', // Behalten falls vorhanden
      twitterHandle: _user?.twitterHandle ?? '',   // Behalten falls vorhanden
      isAdminVerified: false,
      isAdmin: _user?.isAdmin ?? false,
      isNostrVerified: _hasNostrKey,
      hasNostrKey: _hasNostrKey,
    );

    await newUser.save();

    setState(() {
      _user = newUser;
      _isLoading = false;
    });

    if (!mounted) return;

    // Zum Dashboard
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AppShell()),
      (route) => false,
    );
  }

  void _unlockEditMode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Text(AppLocalizations.of(context).profileWarning, style: TextStyle(color: Colors.white)),
        content: Text(
          AppLocalizations.of(context).profileEditWarnDesc,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).dialogCancelMixed)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cRed),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isEditing = true);
            },
            child: Text(AppLocalizations.of(context).profileEdit, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Scaffold(backgroundColor: cDark, body: Center(child: CircularProgressIndicator(color: cOrange)));
    }

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(_isEditing ? AppLocalizations.of(context).profileEditTitle : AppLocalizations.of(context).profileTitle),
        backgroundColor: cDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: _isEditing ? _buildEditForm() : _buildReadOnlyView(),
      ),
    );
  }

  // =============================================
  // READ-ONLY ANSICHT (verifiziertes Profil)
  // =============================================
  Widget _buildReadOnlyView() {
    return Column(
      children: [
        const SizedBox(height: 20),
        NostrAvatar(
          fallbackText: _user!.nickname,
          backgroundColor: cGreen,
          radius: 44,
        ),
        const SizedBox(height: 10),
        Text(AppLocalizations.of(context).profileVerified, style: TextStyle(color: cGreen, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 30),
        _buildInfoTile(AppLocalizations.of(context).profileNickname, _user!.nickname, Icons.person),
        _buildInfoTile(AppLocalizations.of(context).profileHomeMeetup, _user!.homeMeetupId.isEmpty ? "-" : _user!.homeMeetupId, Icons.home),
        if (_hasNostrKey)
          _buildInfoTile("Nostr", NostrService.shortenNpub(_nostrNpub), Icons.key),

        // Signer-Verwaltung auch hier: sie aendert keine Profildaten und darf
        // deshalb nicht hinter „BEARBEITEN (Status verlieren)" liegen.
        if (_hasNostrKey) ..._signerManagementSection(),
        const SizedBox(height: 24),

        // Identity Layer — auch in read-only verfügbar
        Text(AppLocalizations.of(context).profileStrengthen, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 12),

        _buildIdentityAction(
          icon: Icons.link,
          title: AppLocalizations.of(context).profileLinkPlatforms,
          subtitle: _platformProofCount > 0
              ? "$_platformProofCount Plattform${_platformProofCount > 1 ? 'en' : ''} aktiv"
              : AppLocalizations.of(context).profilePlatformsSub,
          color: Colors.green,
          done: _platformProofCount > 0,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlatformProofScreen()),
            );
            _loadData();
          },
        ),
        const SizedBox(height: 10),

        _buildIdentityAction(
          icon: Icons.bolt,
          title: AppLocalizations.of(context).profileProofHumanity,
          subtitle: _humanityVerified
              ? AppLocalizations.of(context).profileLightningActive
              : AppLocalizations.of(context).profileZapCheck,
          color: Colors.amber,
          done: _humanityVerified,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HumanityProofScreen()),
            );
            _loadData();
          },
        ),

        const SizedBox(height: 30),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: cRed, side: const BorderSide(color: cRed)),
          icon: const Icon(Icons.edit),
          label: Text(AppLocalizations.of(context).profileEditLoseStatus),
          onPressed: _unlockEditMode,
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: cOrange, size: 20),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ]),
      ]),
    );
  }

  // =============================================
  // EDIT-FORMULAR
  // =============================================
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- IDENTITÄT ---
          Text(AppLocalizations.of(context).profileIdentity, style: TextStyle(color: cOrange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).profileIntro,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 14),

          _buildTextField(_nicknameController, AppLocalizations.of(context).profileNickname, Icons.person, required: true),
          const SizedBox(height: 12),

          InkWell(
            onTap: () {
              _showMeetupPicker();
              if (_homeMeetupMissing) setState(() => _homeMeetupMissing = false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _homeMeetupMissing ? cRed : cBorder,
                  width: _homeMeetupMissing ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.home,
                      color: _homeMeetupMissing ? cRed : cOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedHomeMeetup.isEmpty ? AppLocalizations.of(context).profileChooseMeetup : _selectedHomeMeetup,
                      style: TextStyle(color: _selectedHomeMeetup.isEmpty ? Colors.grey : Colors.white, fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          if (_homeMeetupMissing)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                AppLocalizations.of(context).profileMeetupReq,
                style: TextStyle(color: cRed, fontSize: 12),
              ),
            ),

          const SizedBox(height: 30),

          // =============================================
          // NOSTR IDENTITÄT
          // =============================================
          Text(AppLocalizations.of(context).profileNostrKey, style: TextStyle(color: cPurple, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).profileKeyDesc,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 12),

          if (_hasNostrKey) ...[
            // KEY VORHANDEN → Anzeigen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).profileKeyActiveCaps, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _nostrNpub,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _nostrNpub));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context).profileNpubCopied), backgroundColor: cOrange, duration: const Duration(seconds: 1)),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text("NPUB", style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cCyan,
                            side: const BorderSide(color: cCyan),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      // Kein lokaler nsec bei Amber, Browsererweiterung
                      // UND Remote-Signer — dort gibt es keinen zu zeigen.
                      if (!_isAmber && !_isNip07 && !_isNip46) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showExistingNsec,
                          icon: const Icon(Icons.key, size: 16),
                          label: const Text("NSEC", style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      ],
                    ],
                  ),
                  // Verschluesselter Export — nur wenn ueberhaupt ein lokaler
                  // Schluessel da ist. Das ist der Weg, den nsec in einen
                  // Signer wie Amber oder Clave zu bekommen, ohne ihn im
                  // Klartext durch die Gegend zu kopieren; er gehoert damit
                  // VOR die Signer-Verwaltung, denn er ist die Voraussetzung
                  // fuer den Wechsel, den die anbietet.
                  if (!_isAmber && !_isNip07 && !_isNip46) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _exportingKey ? null : _exportNcryptsec,
                        icon: _exportingKey
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: cGreen))
                            : const Icon(Icons.lock_outline, size: 16),
                        label: Text(
                            AppLocalizations.of(context).keyExportEncrypted,
                            style: const TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cGreen,
                          side: const BorderSide(color: cGreen),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                  ..._signerManagementSection(),
                ],
              ),
            ),
          ] else ...[
            // KEIN KEY → Generieren oder Importieren
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.key_off, color: Colors.grey, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).profileNoKey,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // GENERIEREN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingKey ? null : _generateNostrKey,
                      icon: _isGeneratingKey
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: Text(
                        _isGeneratingKey ? AppLocalizations.of(context).profileCreating : AppLocalizations.of(context).profileCreateNewKey,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // MIT AMBER VERBINDEN (nur native Android-App)
                  if (_showAmberOption) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isGeneratingKey ? null : _connectAmber,
                        icon: const Icon(Icons.shield_outlined, size: 18),
                        label: Text(AppLocalizations.of(context).profileConnectAmber),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cCyan,
                          side: const BorderSide(color: cCyan),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // MIT REMOTE-SIGNER VERBINDEN (NIP-46 / Bunker)
                  //
                  // OHNE Plattform-Bedingung: das ist der einzige externe
                  // Signer, der ueberall geht — und auf iOS der einzige, den es
                  // gibt. Ob eine Signer-App auf `nostrconnect://` antwortet,
                  // klaert das Blatt selbst; deshalb kann der Knopf hier
                  // bedingungslos stehen.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isGeneratingKey ? null : _connectBunker,
                      icon: const Icon(Icons.lock_outline, size: 18),
                      label: Text(
                          AppLocalizations.of(context).profileConnectBunker),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cCyan,
                        side: const BorderSide(color: cCyan),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // MIT BROWSERERWEITERUNG VERBINDEN (NIP-07)
                  //
                  // Nur wenn tatsaechlich eine Erweiterung antwortet. Einen
                  // Knopf anzuzeigen, der beim Tippen "nicht gefunden" meldet,
                  // waere schlechter als keiner — und ausserhalb des Browsers
                  // gibt es NIP-07 ohnehin nicht.
                  if (_nip07Available) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isGeneratingKey ? null : _connectNip07,
                        icon: const Icon(Icons.extension_outlined, size: 18),
                        label: Text(AppLocalizations.of(context).profileConnectExtension),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cGreen,
                          side: const BorderSide(color: cGreen),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // IMPORTIEREN
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _importNsec,
                      icon: const Icon(Icons.download, size: 18),
                      label: Text(AppLocalizations.of(context).profileImportNsec),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cOrange,
                        side: const BorderSide(color: cOrange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).profileNoNostrNeeded,
                    style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // =============================================
          // IDENTITÄT STÄRKEN
          // =============================================
          Text(AppLocalizations.of(context).profileStrengthen, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).profileStrengthenDesc,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Plattformen verknüpfen
          _buildIdentityAction(
            icon: Icons.link,
            title: AppLocalizations.of(context).profileLinkPlatforms,
            subtitle: _platformProofCount > 0
                ? "$_platformProofCount Plattform${_platformProofCount > 1 ? 'en' : ''} aktiv"
                : AppLocalizations.of(context).profilePlatformsSub,
            color: Colors.green,
            done: _platformProofCount > 0,
            onTap: () async {
              // Fix: Aktuelle Eingaben merken bevor wir navigieren
              final savedNickname = _nicknameController.text;
              final savedMeetup = _selectedHomeMeetup;

              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlatformProofScreen()),
              );

              // Nur Identity-Status neu laden, NICHT die Formular-Werte überschreiben
              await _refreshIdentityOnly();

              // Formular-Werte wiederherstellen
              _nicknameController.text = savedNickname;
              _selectedHomeMeetup = savedMeetup;
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 10),

          // Proof of Humanity
          _buildIdentityAction(
            icon: Icons.bolt,
            title: AppLocalizations.of(context).profileProofHumanity,
            subtitle: _humanityVerified
                ? AppLocalizations.of(context).profileLightningActive
                : AppLocalizations.of(context).profileZapCheck,
            color: Colors.amber,
            done: _humanityVerified,
            onTap: () async {
              // Fix: Aktuelle Eingaben merken bevor wir navigieren
              final savedNickname = _nicknameController.text;
              final savedMeetup = _selectedHomeMeetup;

              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HumanityProofScreen()),
              );

              // Nur Identity-Status neu laden, NICHT die Formular-Werte überschreiben
              await _refreshIdentityOnly();

              // Formular-Werte wiederherstellen
              _nicknameController.text = savedNickname;
              _selectedHomeMeetup = savedMeetup;
              if (mounted) setState(() {});
            },
          ),

          const SizedBox(height: 30),

          // SPEICHERN
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveProfile,
              child: Text(AppLocalizations.of(context).profileSave),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- ANDEREN SIGNER VERBINDEN (bei vorhandenem Schluessel) ---
  //
  // Hier lag der eigentliche Mangel: die Verbinden-Knoepfe standen NUR im
  // Zweig "kein Schluessel". Wer schon einen hatte, kam an Amber, die
  // Browsererweiterung und den Bunker nicht heran — also genau die Nutzer, die
  // von ihrem lokalen Schluessel WEG wollen. Auf iOS betraf das jeden, der
  // seinen nsec nicht mehr in der App liegen haben will.
  //
  // Angeboten wird nur, was auf dieser Plattform ueberhaupt geht und was nicht
  // schon aktiv ist.
  /// Signer-Verwaltung: Verbindung pruefen, anderen Signer verbinden, trennen.
  ///
  /// Steht in BEIDEN Ansichten. Vorher lag das nur im Bearbeiten-Formular — und
  /// in das kommt ein verifiziertes Profil ausschliesslich ueber „BEARBEITEN
  /// (Status verlieren)". Ein verifizierter Organisator haette seinen Signer
  /// also weder pruefen noch wechseln noch trennen koennen, ohne seinen Status
  /// zu opfern. Keine dieser Handlungen aendert Profildaten; es gab keinen
  /// Grund, sie hinter dem Bearbeiten-Modus zu verstecken.
  List<Widget> _signerManagementSection() => [
        // Nur im Bunker-Modus. Eine im Signer widerrufene Sitzung sieht von
        // aussen genauso aus wie eine Zeitueberschreitung — erst eine
        // ausdrueckliche Pruefung unterscheidet beides. Absichtlich NICHT
        // automatisch beim Oeffnen: der Test kostet eine Relay-Runde.
        if (_isNip46) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _checkingBunker ? null : _checkBunkerSession,
              icon: _checkingBunker
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cCyan))
                  : const Icon(Icons.wifi_tethering, size: 16),
              label: Text(AppLocalizations.of(context).bunkerCheck,
                  style: const TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: cCyan,
                side: const BorderSide(color: cCyan),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
        ..._signerSwitchSection(),
      ];

  List<Widget> _signerSwitchSection() {
    final t = AppLocalizations.of(context);

    // Der aktive Modus wird nur ausgeschlossen, solange er auch BENUTZBAR ist.
    // Kann die App nicht signieren, ist "erneut verbinden" die einzig
    // sinnvolle Handlung — und muss angeboten werden, sonst sitzt der Nutzer
    // fest. Genau das passierte nach einem Backup-Restore im Bunker-Modus.
    final offerAgain = !_canSign;
    final options = <Widget>[
      if (!_isNip46 || offerAgain)
        _signerSwitchButton(
          icon: Icons.lock_outline,
          color: cCyan,
          label: t.profileConnectBunker,
          onPressed: _connectBunker,
        ),
      if (_showAmberOption && (!_isAmber || offerAgain))
        _signerSwitchButton(
          icon: Icons.shield_outlined,
          color: cCyan,
          label: t.profileConnectAmber,
          onPressed: _connectAmber,
        ),
      if (_nip07Available && (!_isNip07 || offerAgain))
        _signerSwitchButton(
          icon: Icons.extension_outlined,
          color: cGreen,
          label: t.profileConnectExtension,
          onPressed: _connectNip07,
        ),
    ];

    // Trennen nur, wenn ueberhaupt ein externer Signer aktiv ist.
    final canDisconnect = _isAmber || _isNip07 || _isNip46;
    if (options.isEmpty && !canDisconnect) return const [];

    return [
      const SizedBox(height: 16),
      const Divider(color: cBorder, height: 1),
      const SizedBox(height: 12),
      // Ueberschrift und Hinweis gehoeren zum VERBINDEN. Bleibt nur das
      // Trennen uebrig, wuerde „Anderen Signer verbinden" ueber einem
      // Trennen-Knopf stehen — dann lieber nur der Knopf.
      if (options.isNotEmpty) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: Text(t.profileSwitchSignerHeading,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          // Bei fehlender Signier-Faehigkeit steht hier der GRUND, sonst der
          // beruhigende Hinweis, dass der bisherige Schluessel bleibt.
          child: Text(
              offerAgain ? t.profileSignerUnusable : t.profileSwitchSignerHint,
              style: TextStyle(
                  color: offerAgain ? Colors.orange : Colors.grey,
                  fontSize: 11)),
        ),
        const SizedBox(height: 10),
      ],
      for (final option in options) ...[option, const SizedBox(height: 8)],
      if (canDisconnect)
        _signerSwitchButton(
          icon: Icons.link_off,
          color: Colors.orange,
          label: t.profileDisconnectSigner,
          onPressed: _disconnectSigner,
        ),
    ];
  }

  Widget _signerSwitchButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isGeneratingKey ? null : onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label, style: const TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: cCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required
          ? (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return AppLocalizations.of(context).profileNicknameReq;
              if (t.toLowerCase() == 'anon') {
                return AppLocalizations.of(context).profileNicknameAnon;
              }
              if (t.length < 2) return AppLocalizations.of(context).profileNicknameMin;
              return null;
            }
          : null,
    );
  }

  Widget _buildIdentityAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool done,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: done ? color.withValues(alpha: 0.3) : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: done ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: done ? color : Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(
                      color: done ? color.withValues(alpha: 0.8) : Colors.grey.shade500,
                      fontSize: 12,
                    )),
                  ],
                ),
              ),
              done
                  ? Icon(Icons.check_circle, color: color, size: 20)
                  : Icon(Icons.arrow_forward_ios, color: Colors.grey.shade700, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
