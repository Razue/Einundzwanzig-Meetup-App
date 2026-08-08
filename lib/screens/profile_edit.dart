import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../services/meetup_service.dart';
import '../services/nostr_service.dart';
import '../services/signing_service.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/nostr_avatar.dart';
import 'app_shell.dart';
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
  /// Ist ueberhaupt eine NIP-07-Erweiterung im Browser? Ausserhalb des
  /// Browsers immer false — dann wird der Knopf gar nicht angeboten, statt
  /// ihn anzuzeigen und beim Tippen "nicht gefunden" zu melden.
  bool _nip07Available = false;
  String _nostrNpub = "";
  bool _isGeneratingKey = false;

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
    final isNip07 = await SigningService.isNip07;
    final nip07Available = await SigningService.nip07Extensionavailable();

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

        _isAmber = isAmber;
        _isNip07 = isNip07;
        _nip07Available = nip07Available;
        // Im Amber-Modus gibt es keinen lokalen nsec, aber eine gültige
        // Identität → als AppLocalizations.of(context).profileKeyActive anzeigen (npub vorhanden).
        _hasNostrKey = hasKey || isAmber || isNip07;
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

      setState(() {
        _hasNostrKey = true;
        _isAmber = false;
        _nostrNpub = keys['npub']!;
        _isGeneratingKey = false;
      });

      if (mounted) {
        _showNsecBackupDialog(keys['nsec']!);
      }
    } catch (e) {
      setState(() => _isGeneratingKey = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorGeneric(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- MIT BROWSERERWEITERUNG VERBINDEN (NIP-07) ---
  // Das Gegenstueck zu Amber im Browser. Der Schluessel bleibt in der
  // Erweiterung — im Web der einzige Weg, bei dem der nsec NICHT in
  // localStorage liegen muss.
  void _connectNip07() async {
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
            _nostrNpub = npub;
            _isGeneratingKey = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t.profileExtensionConnected),
            backgroundColor: Colors.green,
          ));
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t.errorGeneric(message)),
            backgroundColor: Colors.red,
          ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingKey = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).errorGeneric(e.toString())),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // --- NSEC IMPORTIEREN ---
  // --- MIT AMBER VERBINDEN (NIP-55, nsec bleibt in Amber) ---
  void _connectAmber() async {
    setState(() => _isGeneratingKey = true);
    try {
      final result = await SigningService.connectAmber();
      if (!mounted) return;
      switch (result) {
        case AmberConnectSuccess(:final npub):
          setState(() {
            _hasNostrKey = true;
            _isAmber = true;
            _nostrNpub = npub;
            _isGeneratingKey = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).profileAmberConnected),
              backgroundColor: Colors.green,
            ),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).errorAmber(message)),
                backgroundColor: Colors.red),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingKey = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorGeneric(e.toString())), backgroundColor: Colors.red),
        );
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
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _hasNostrKey = true;
                    _isAmber = false;
                    _isNip07 = false;
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$e"), backgroundColor: Colors.red),
                  );
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
                      // Kein lokaler nsec bei Amber UND bei Browsererweiterung.
                      if (!_isAmber && !_isNip07) ...[
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

                  // MIT AMBER VERBINDEN (empfohlen)
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

// --- MEETUP SUCHE (unverändert) ---
class MeetupSearchSheet extends StatefulWidget {
  final List<Meetup> meetups;
  /// Bereits gewaehlte Favoriten (Sterne vorbelegt).
  final List<String> initialSelected;
  /// Liefert beim Schliessen die KOMPLETTE Favoritenliste.
  final Function(List<String>) onDone;

  const MeetupSearchSheet({super.key, required this.meetups, this.initialSelected = const [], required this.onDone});

  @override
  State<MeetupSearchSheet> createState() => _MeetupSearchSheetState();
}

class _MeetupSearchSheetState extends State<MeetupSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Meetup> _filtered = [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _filtered = widget.meetups;
    _selected.addAll(widget.initialSelected);
  }

  void _filter(String query) {
    if (mounted) {
      setState(() {
        _filtered = widget.meetups.where((m) => m.city.toLowerCase().contains(query.toLowerCase())).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).profileSearchCity,
                  prefixIcon: const Icon(Icons.search, color: cOrange),
                  filled: true,
                  fillColor: cDark,
                ),
                onChanged: _filter,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final meetup = _filtered[index];
                  final active = _selected.contains(meetup.city);
                  return ListTile(
                    title: Text(meetup.city, style: TextStyle(color: active ? cOrange : Colors.white, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
                    // Gruppenname als Unterzeile: In groesseren Staedten gibt
                    // es mehrere Meetups — ohne ihn sind sie nicht zu trennen.
                    subtitle: (meetup.name.isNotEmpty &&
                            meetup.name.toLowerCase() != meetup.city.toLowerCase())
                        ? Text(meetup.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: cTextTertiary, fontSize: 11.5))
                        : null,
                    // STERN: mehrere Meetups als Favoriten anwaehlbar.
                    trailing: Icon(active ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: active ? cOrange : cTextTertiary, size: 26),
                    onTap: () {
                      setState(() {
                        if (active) { _selected.remove(meetup.city); } else { _selected.add(meetup.city); }
                      });
                    },
                  );
                },
              ),
            ),
            // Fertig-Button: uebergibt die Liste und schliesst.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () { widget.onDone(_selected.toList()); Navigator.pop(context); },
                    style: ElevatedButton.styleFrom(backgroundColor: cOrange, padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: Text('${_selected.length} ★',
                        style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
