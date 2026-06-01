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

  String _selectedHomeMeetup = "";
  bool _homeMeetupMissing = false; // Pflichtfeld-Markierung Home-Meetup
  List<Meetup> _allMeetups = [];

  UserProfile? _user;
  bool _isLoading = true;
  bool _isEditing = false;

  // Nostr Key State
  bool _hasNostrKey = false;
  bool _isAmber = false; // Identität über Amber (kein lokaler nsec)
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

        _isAmber = isAmber;
        // Im Amber-Modus gibt es keinen lokalen nsec, aber eine gültige
        // Identität → als AppLocalizations.of(context).profileKeyActive anzeigen (npub vorhanden).
        _hasNostrKey = hasKey || isAmber;
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
  void _generateNostrKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Text(AppLocalizations.of(context).profileCreateKey, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          AppLocalizations.of(context).profileNewKeypairDesc +
          AppLocalizations.of(context).profileBackupNsec,
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).dialogCancel, style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).dialogCreate, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

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
          children: const [
            Icon(Icons.warning_amber, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(AppLocalizations.of(context).profileSecureKey, style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
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
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
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
          onSelect: (cityName) {
            setState(() {
              _selectedHomeMeetup = cityName;
              _homeMeetupMissing = false; // Markierung weg sobald gewählt
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
                border: Border.all(color: Colors.green.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context).profileKeyActiveCaps, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
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
                      if (!_isAmber) ...[
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
              color: done ? color.withOpacity(0.3) : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(done ? 0.15 : 0.08),
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
                      color: done ? color.withOpacity(0.8) : Colors.grey.shade500,
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
  final Function(String) onSelect;

  const MeetupSearchSheet({super.key, required this.meetups, required this.onSelect});

  @override
  State<MeetupSearchSheet> createState() => _MeetupSearchSheetState();
}

class _MeetupSearchSheetState extends State<MeetupSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Meetup> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.meetups;
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
                  return ListTile(
                    title: Text(meetup.city, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      widget.onSelect(meetup.city);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}


