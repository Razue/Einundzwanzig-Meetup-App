// ============================================
// IDENTITY SETUP — Erststart „Neu“ / „Schon dabei“
// ============================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/meetup.dart';
import '../models/user.dart';
import '../services/backup_service.dart';
import '../services/local_easy_auth.dart';
import '../services/local_key_vault.dart';
import '../services/meetup_service.dart';
import '../services/nostr_service.dart';
import '../services/passkey_prf_service.dart';
import '../services/secure_key_store.dart';
import '../services/signing_service.dart';
import '../theme.dart';
import '../widgets/meetup_search_sheet.dart';
import 'app_shell.dart';
import 'bunker_connect_sheet.dart';

enum _SetupStep {
  choose,
  neu,
  resume,
  passkey,
  existing,
  existingMore,
  nameOnly,
  meetup,
}

class IdentitySetupScreen extends StatefulWidget {
  const IdentitySetupScreen({super.key});

  @override
  State<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends State<IdentitySetupScreen> {
  _SetupStep _step = _SetupStep.choose;
  bool _busy = false;
  /// true bis Key/Wrap/Path geladen — sonst kann „Neu" vor der Erkennung tippen
  /// und eine ueberlebende Identitaet ueberschreiben.
  bool _bootstrapping = true;
  String? _error;
  bool _passkeySupported = false;
  RecommendedExistingPath _path = RecommendedExistingPath.bunker;

  // Was liegt auf diesem Geraet schon herum? Der Setup-Screen erscheint, wenn
  // das PROFIL fehlt — das Profil liegt in SharedPreferences, der Schluessel im
  // Keychain. Nach einer Neuinstallation auf iOS ist genau das der Fall: Profil
  // weg, Schluessel noch da. Ohne diese Abfrage bietet der Screen dort „Neu
  // hier" an und `register()` ueberschreibt den ueberlebenden Schluessel — die
  // Identitaet waere weg, obwohl sie noch dalag.
  bool _hasLocalKey = false;
  bool _hasPasswordWrap = false;
  bool _hasPasskeyWrap = false;
  bool _resumeUsePassword = false;

  List<Meetup> _meetups = [];
  List<String> _selectedMeetupCities = [];
  bool _meetupsLoading = false;

  bool get _canResume => _hasLocalKey || _hasPasswordWrap || _hasPasskeyWrap;

  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  final _importCtrl = TextEditingController();
  final _importPassCtrl = TextEditingController();
  final _resumePassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final path = await SigningService.recommendedExistingPath();
    final pk = await PasskeyPrfService.isSupported();
    final hasKey = await SecureKeyStore.hasKey();
    final pwWrap = await LocalKeyVault.getPasswordWrap();
    final pkWrap = await LocalKeyVault.hasPasskeyWrap();
    if (!mounted) return;
    setState(() {
      _path = path;
      _passkeySupported = pk;
      _hasLocalKey = hasKey;
      _hasPasswordWrap = pwWrap != null && pwWrap.isNotEmpty;
      _hasPasskeyWrap = pkWrap;
      _bootstrapping = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    _importCtrl.dispose();
    _importPassCtrl.dispose();
    _resumePassCtrl.dispose();
    super.dispose();
  }

  Future<void> _goHome() async {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShell()),
      (_) => false,
    );
  }

  /// Home nur mit echtem Anzeigenamen — `isOnboarded` reicht nicht, weil
  /// `isNostrVerified` allein true sein kann (Key da, Nickname noch Anon).
  /// Home schickt Anon wieder hierher → Loop ohne Namensfeld.
  ///
  /// Danach: Meetup wählen, falls noch keines gesetzt — sonst direkt Home.
  Future<void> _finishIfOnboarded() async {
    final user = await UserProfile.load();
    if (!user.hasCustomNickname) {
      if (mounted) setState(() => _step = _SetupStep.nameOnly);
      return;
    }
    await _continueAfterIdentity(user);
  }

  Future<void> _continueAfterIdentity([UserProfile? loaded]) async {
    final user = loaded ?? await UserProfile.load();
    final hasMeetup =
        user.homeMeetupId.trim().isNotEmpty || user.favoriteMeetupIds.isNotEmpty;
    if (hasMeetup) {
      await _goHome();
      return;
    }
    await _enterMeetupStep();
  }

  Future<void> _enterMeetupStep() async {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = null;
      _step = _SetupStep.meetup;
      _meetupsLoading = true;
      _selectedMeetupCities = [];
    });
    try {
      final list = await MeetupService.fetchMeetups();
      if (!mounted) return;
      setState(() {
        _meetups = list;
        _meetupsLoading = false;
        if (list.isEmpty) {
          _error = AppLocalizations.of(context).idSetupMeetupLoadError;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _meetupsLoading = false;
        _error = AppLocalizations.of(context).idSetupMeetupLoadError;
      });
    }
  }

  Future<void> _openMeetupPicker() async {
    if (_meetups.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return MeetupSearchSheet(
          meetups: _meetups,
          initialSelected: _selectedMeetupCities,
          onDone: (favs) {
            setState(() => _selectedMeetupCities = favs);
          },
        );
      },
    );
  }

  Future<void> _saveMeetupAndHome() async {
    if (_selectedMeetupCities.isEmpty) return;
    setState(() => _busy = true);
    final user = await UserProfile.load();
    user.favoriteMeetupIds = List<String>.from(_selectedMeetupCities);
    user.homeMeetupId = _selectedMeetupCities.first;
    await user.save();
    await _goHome();
  }

  Future<void> _register() async {
    final t = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    final pass = _passCtrl.text;
    final pass2 = _pass2Ctrl.text;
    if (name.isEmpty || name == 'Anon') {
      setState(() => _error = t.idSetupNameRequired);
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = t.idSetupPasswordShort);
      return;
    }
    if (pass != pass2) {
      setState(() => _error = t.keyExportMismatch);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await LocalEasyAuth.register(nickname: name, password: pass);
      if (!mounted) return;
      if (_passkeySupported) {
        setState(() {
          _busy = false;
          _step = _SetupStep.passkey;
        });
      } else {
        await _offerBackupThenHome();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  /// Weitermachen mit dem, was schon auf dem Geraet liegt.
  ///
  /// Drei Faelle, absichtlich in dieser Reihenfolge: liegt der Schluessel selbst
  /// noch im Keychain, ist ueberhaupt nichts zu entschluesseln — dann waere ein
  /// Passwortdialog reine Schikane. Erst wenn er fehlt, kommen die Wraps dran.
  Future<void> _resume({bool usePasskey = false}) async {
    final t = AppLocalizations.of(context);
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_hasLocalKey) {
        await SigningService.useLocalMode();
      } else if (usePasskey) {
        await LocalEasyAuth.unlockWithPasskey();
      } else {
        final pass = _resumePassCtrl.text;
        if (pass.isEmpty) {
          setState(() {
            _busy = false;
            _error = t.idSetupResumeNeedPassword;
          });
          return;
        }
        await LocalEasyAuth.unlockWithPassword(pass);
      }
      if (!mounted) return;
      _resumePassCtrl.clear();
      await _finishIfOnboarded();
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        // Ein falsches Passwort scheitert im MAC-Vergleich von NIP-49 und
        // liefert eine technische Meldung. Die hier zu zeigen hilft niemandem.
        _error = usePasskey ? tPasskeyError(e) : t.idSetupResumeWrongPassword;
      });
    }
  }

  Future<void> _addPasskey() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await LocalEasyAuth.addPasskeyWrap(displayName: _nameCtrl.text.trim());
      if (!mounted) return;
      await _offerBackupThenHome();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = tPasskeyError(e);
      });
    }
  }

  String tPasskeyError(Object e) {
    final s = e.toString();
    // Technisch verschiedene Gruende, fuer den Nutzer dieselbe Lage:
    // Passkey geht hier nicht, Passwort/„Spaeter" geht weiter.
    if (s.contains('PRF_UNSUPPORTED') ||
        s.contains('DomainNotAssociated') ||
        s.contains('RP_ID_NOT_ALLOWED') ||
        s.contains('TYPE_NOT_SUPPORTED_ERROR') ||
        s.contains('algorithms are supported') ||
        s.contains('NoCreateOption') ||
        s.contains('android-no-create-option') ||
        s.contains('android-unhandled')) {
      return AppLocalizations.of(context).idSetupPasskeyUnavailable;
    }
    return s;
  }

  Future<void> _skipPasskey() async {
    await _offerBackupThenHome();
  }

  Future<void> _offerBackupThenHome() async {
    if (!mounted) return;
    setState(() => _busy = false);
    final wrap = await LocalKeyVault.getPasswordWrap();
    if (wrap != null && wrap.isNotEmpty && mounted) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: cCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          final t = AppLocalizations.of(ctx);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.idSetupBackupTitle,
                    style: const TextStyle(
                        color: cText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(t.idSetupBackupBody,
                    style: const TextStyle(color: cTextSecondary, height: 1.4)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: wrap));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.keyExportCopied)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cOrange,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(t.idSetupBackupCopy),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t.idSetupBackupLater,
                      style: const TextStyle(color: cTextSecondary)),
                ),
              ],
            ),
          );
        },
      );
    }
    await _continueAfterIdentity();
  }

  Future<void> _connectPrimary() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      switch (_path) {
        case RecommendedExistingPath.nip07:
          final r = await SigningService.connectNip07();
          if (!mounted) return;
          if (r is! Nip07ConnectSuccess) {
            throw Exception(AppLocalizations.of(context).idSetupConnectFailed);
          }
        case RecommendedExistingPath.amber:
          final r = await SigningService.connectAmber();
          if (!mounted) return;
          if (r is! AmberConnectSuccess) {
            throw Exception(AppLocalizations.of(context).idSetupConnectFailed);
          }
        case RecommendedExistingPath.bunker:
          final r = await BunkerConnectSheet.show(context);
          if (r == null) {
            if (!mounted) return;
            setState(() => _busy = false);
            return;
          }
      }
      if (!mounted) return;
      setState(() => _busy = false);
      await _finishIfOnboarded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _saveNameOnly() async {
    final t = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name == 'Anon') {
      setState(() => _error = t.idSetupNameRequired);
      return;
    }
    setState(() => _busy = true);
    final user = await UserProfile.load();
    user.nickname = name;
    await user.save();
    await _continueAfterIdentity(user);
  }

  Future<void> _importKey() async {
    final t = AppLocalizations.of(context);
    final raw = _importCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = t.idSetupImportEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (raw.startsWith('ncryptsec1')) {
        final pass = _importPassCtrl.text;
        if (pass.isEmpty) {
          throw Exception(t.idSetupImportNeedPassword);
        }
        await NostrService.importNcryptsec(raw, pass);
      } else {
        await NostrService.importNsec(raw);
      }
      // Import ersetzt die Identitaet — alte EasyAuth-Wraps gehoeren nicht mehr.
      await LocalKeyVault.clearAll();
      await SigningService.useLocalMode();
      if (!mounted) return;
      setState(() => _busy = false);
      await _finishIfOnboarded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _restoreBackup() async {
    final ok = await BackupService.restoreBackup(context);
    if (ok && mounted) await _goHome();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        foregroundColor: cText,
        elevation: 0,
        title: Text(_title(t),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        leading: _step == _SetupStep.choose
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _busy
                    ? null
                    : () {
                        if (_step == _SetupStep.meetup) {
                          // Identitaet steht schon — zurueck = Home, nicht neu waehlen.
                          _goHome();
                          return;
                        }
                        setState(() {
                          _error = null;
                          _resumeUsePassword = false;
                          _resumePassCtrl.clear();
                          _step = switch (_step) {
                            _SetupStep.passkey => _SetupStep.neu,
                            _SetupStep.existingMore ||
                            _SetupStep.nameOnly =>
                              _SetupStep.existing,
                            _ => _SetupStep.choose,
                          };
                        });
                      },
              ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy || _bootstrapping,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: cRed, height: 1.3)),
                ),
                const SizedBox(height: 16),
              ],
              if (_busy || _bootstrapping)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(
                    color: cOrange,
                    backgroundColor: cBorder,
                  ),
                ),
              if (_bootstrapping)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Text(t.idSetupSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: cTextSecondary)),
                )
              else
                ...switch (_step) {
                  _SetupStep.choose => _buildChoose(t),
                  _SetupStep.neu => _buildNeu(t),
                  _SetupStep.resume => _buildResume(t),
                  _SetupStep.passkey => _buildPasskey(t),
                  _SetupStep.existing => _buildExisting(t),
                  _SetupStep.existingMore => _buildExistingMore(t),
                  _SetupStep.nameOnly => _buildNameOnly(t),
                  _SetupStep.meetup => _buildMeetup(t),
                },
            ],
          ),
        ),
      ),
    );
  }

  String _title(AppLocalizations t) => switch (_step) {
        _SetupStep.choose => t.idSetupTitle,
        _SetupStep.neu => t.idSetupNewTitle,
        _SetupStep.resume => t.idSetupResumeTitle,
        _SetupStep.passkey => t.idSetupPasskeyTitle,
        _SetupStep.existing ||
        _SetupStep.existingMore =>
          t.idSetupExistingTitle,
        _SetupStep.nameOnly => t.idSetupNameTitle,
        _SetupStep.meetup => t.idSetupMeetupTitle,
      };

  List<Widget> _buildChoose(AppLocalizations t) => [
        Text(t.idSetupSubtitle,
            style: const TextStyle(color: cTextSecondary, height: 1.4)),
        const SizedBox(height: 24),
        // Wenn hier schon etwas liegt, ist Weitermachen die richtige erste Wahl
        // — „Neu hier" wuerde es ueberschreiben.
        if (_canResume) ...[
          _card(
            icon: Icons.restore_rounded,
            title: t.idSetupResumeCard,
            subtitle: t.idSetupResumeCardSub,
            primary: true,
            onTap: () => setState(() {
              _error = null;
              _step = _SetupStep.resume;
            }),
          ),
          const SizedBox(height: 12),
        ],
        _card(
          icon: Icons.person_add_alt_1_rounded,
          title: t.idSetupNewCard,
          subtitle: t.idSetupNewCardSub,
          primary: !_canResume,
          onTap: () => setState(() {
            _error = null;
            _step = _SetupStep.neu;
          }),
        ),
        const SizedBox(height: 12),
        _card(
          icon: Icons.link_rounded,
          title: t.idSetupExistingCard,
          subtitle: t.idSetupExistingCardSub,
          onTap: () => setState(() {
            _error = null;
            _step = _SetupStep.existing;
          }),
        ),
      ];

  List<Widget> _buildNeu(AppLocalizations t) => [
        Text(t.idSetupNewHint,
            style: const TextStyle(color: cTextSecondary, height: 1.4)),
        const SizedBox(height: 20),
        _field(_nameCtrl, t.idSetupNameLabel, Icons.badge_outlined),
        const SizedBox(height: 12),
        _field(_passCtrl, t.idSetupPasswordLabel, Icons.lock_outline,
            obscure: true),
        const SizedBox(height: 12),
        _field(_pass2Ctrl, t.idSetupPasswordConfirmLabel, Icons.lock_outline,
            obscure: true),
        const SizedBox(height: 10),
        // Das Passwort ist keine App-Sperre, sondern der einzige Weg zurueck an
        // den Schluessel. Wer das erst beim Geraetewechsel erfaehrt, erfaehrt
        // es zu spaet — deshalb steht es unter dem Feld und nicht in einem
        // Dialog, den man wegtippt.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.key_outlined, color: cOrange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(t.idSetupPasswordWarn,
                  style: const TextStyle(
                      color: cTextSecondary, fontSize: 12, height: 1.4)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _primaryButton(t.idSetupCreate, _register),
      ];

  List<Widget> _buildResume(AppLocalizations t) => [
        Text(
          _hasLocalKey
              ? t.idSetupResumeHasKey
              : (_hasPasskeyWrap && !_resumeUsePassword
                  ? t.idSetupResumePasskeyHint
                  : t.idSetupResumePasswordHint),
          style: const TextStyle(color: cTextSecondary, height: 1.4),
        ),
        const SizedBox(height: 24),
        if (_hasLocalKey)
          _primaryButton(t.idSetupResumeContinue, () => _resume())
        else if (_hasPasskeyWrap && !_resumeUsePassword) ...[
          _primaryButton(
              t.idSetupResumePasskey, () => _resume(usePasskey: true)),
          if (_hasPasswordWrap) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _error = null;
                        _resumeUsePassword = true;
                      }),
              child: Text(t.idSetupResumePassword,
                  style: const TextStyle(color: cTextSecondary)),
            ),
          ],
        ] else ...[
          _field(_resumePassCtrl, t.idSetupPasswordLabel, Icons.lock_outline,
              obscure: true),
          const SizedBox(height: 16),
          _primaryButton(t.idSetupResumeContinue, () => _resume()),
        ],
      ];

  List<Widget> _buildPasskey(AppLocalizations t) => [
        Text(t.idSetupPasskeyBody,
            style: const TextStyle(color: cTextSecondary, height: 1.4)),
        const SizedBox(height: 24),
        _primaryButton(t.idSetupPasskeyAction, _addPasskey),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _skipPasskey,
          child: Text(t.idSetupPasskeyLater,
              style: const TextStyle(color: cTextSecondary)),
        ),
      ];

  List<Widget> _buildExisting(AppLocalizations t) {
    final (icon, title, sub) = switch (_path) {
      RecommendedExistingPath.nip07 => (
          Icons.extension_rounded,
          t.idSetupPrimaryNip07,
          t.idSetupPrimaryNip07Sub,
        ),
      RecommendedExistingPath.amber => (
          Icons.phone_android_rounded,
          t.idSetupPrimaryAmber,
          t.idSetupPrimaryAmberSub,
        ),
      RecommendedExistingPath.bunker => (
          Icons.vpn_key_rounded,
          t.idSetupPrimaryBunker,
          t.idSetupPrimaryBunkerSub,
        ),
    };
    return [
      _card(
        icon: icon,
        title: title,
        subtitle: sub,
        primary: true,
        onTap: _connectPrimary,
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => setState(() {
          _error = null;
          _step = _SetupStep.existingMore;
        }),
        child: Text(t.idSetupOtherWay,
            style: const TextStyle(color: cOrange, fontWeight: FontWeight.w700)),
      ),
    ];
  }

  List<Widget> _buildExistingMore(AppLocalizations t) => [
        Text(t.idSetupImportHint,
            style: const TextStyle(color: cTextSecondary, height: 1.4)),
        const SizedBox(height: 12),
        _field(_importCtrl, t.idSetupImportLabel, Icons.key_outlined,
            maxLines: 3),
        const SizedBox(height: 12),
        _field(_importPassCtrl, t.idSetupImportPasswordLabel, Icons.lock_outline,
            obscure: true),
        const SizedBox(height: 16),
        _primaryButton(t.idSetupImportAction, _importKey),
        const SizedBox(height: 20),
        if (_path != RecommendedExistingPath.bunker) ...[
          _card(
            icon: Icons.vpn_key_rounded,
            title: t.idSetupPrimaryBunker,
            subtitle: t.idSetupPrimaryBunkerSub,
            onTap: () async {
              final r = await BunkerConnectSheet.show(context);
              if (r != null) await _finishIfOnboarded();
            },
          ),
          const SizedBox(height: 12),
        ],
        if (kIsWeb && _path != RecommendedExistingPath.nip07) ...[
          _card(
            icon: Icons.extension_rounded,
            title: t.idSetupPrimaryNip07,
            subtitle: t.idSetupPrimaryNip07Sub,
            onTap: () async {
              setState(() => _path = RecommendedExistingPath.nip07);
              await _connectPrimary();
            },
          ),
          const SizedBox(height: 12),
        ],
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            _path != RecommendedExistingPath.amber) ...[
          _card(
            icon: Icons.phone_android_rounded,
            title: t.idSetupPrimaryAmber,
            subtitle: t.idSetupPrimaryAmberSub,
            onTap: () async {
              setState(() => _path = RecommendedExistingPath.amber);
              await _connectPrimary();
            },
          ),
          const SizedBox(height: 12),
        ],
        TextButton.icon(
          onPressed: _restoreBackup,
          icon: const Icon(Icons.restore_rounded, color: cOrange, size: 18),
          label: Text(t.introLoadBackup,
              style: const TextStyle(
                  color: cOrange, fontWeight: FontWeight.w700)),
        ),
      ];

  List<Widget> _buildNameOnly(AppLocalizations t) => [
        Text(t.idSetupNameOnlyHint,
            style: const TextStyle(color: cTextSecondary, height: 1.4)),
        const SizedBox(height: 20),
        _field(_nameCtrl, t.idSetupNameLabel, Icons.badge_outlined),
        const SizedBox(height: 24),
        _primaryButton(t.idSetupContinue, _saveNameOnly),
      ];

  List<Widget> _buildMeetup(AppLocalizations t) => [
        Text(t.idSetupMeetupHint,
            style: const TextStyle(color: cTextSecondary, height: 1.4)),
        const SizedBox(height: 20),
        if (_meetupsLoading)
          Text(t.idSetupMeetupLoading,
              style: const TextStyle(color: cTextSecondary))
        else if (_meetups.isEmpty) ...[
          TextButton(
            onPressed: _goHome,
            child: Text(t.idSetupMeetupLater,
                style: const TextStyle(color: cTextSecondary)),
          ),
        ] else ...[
          _card(
            icon: Icons.place_outlined,
            title: t.idSetupMeetupPick,
            subtitle: _selectedMeetupCities.isEmpty
                ? t.homeMeetupChooseSub
                : _selectedMeetupCities.join(', '),
            primary: true,
            onTap: _openMeetupPicker,
          ),
          const SizedBox(height: 24),
          if (_selectedMeetupCities.isNotEmpty)
            _primaryButton(t.idSetupMeetupContinue, _saveMeetupAndHome),
          TextButton(
            onPressed: _goHome,
            child: Text(t.idSetupMeetupLater,
                style: const TextStyle(color: cTextSecondary)),
          ),
        ],
      ];

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Material(
      color: primary ? cOrange.withValues(alpha: 0.12) : cCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primary ? cOrange.withValues(alpha: 0.5) : cTileBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: primary ? cOrange : cCyan, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          color: cText,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        )),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: cTextSecondary, height: 1.3, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: cTextTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      style: const TextStyle(color: cText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: cTextSecondary),
        prefixIcon: Icon(icon, color: cTextSecondary, size: 20),
        filled: true,
        fillColor: cCard,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cTileBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cOrange),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradientOrange,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}
