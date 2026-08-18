// ============================================
// IDENTITY SETUP — Erststart „Neu“ / „Schon dabei“
// ============================================

import 'dart:ui' as ui;

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

/// Mindestlaenge fuer das Schluessel-Passwort.
///
/// Dieselbe Zahl wie BackupService.minPasswordLength, aber bewusst eigen:
/// Es sind zwei UNABHAENGIGE Geheimnisse — dieses verpackt den privaten
/// Schluessel (NIP-49 ncryptsec), jenes die Sicherungsdatei. Wer eines
/// aendert, soll nicht versehentlich das andere mitaendern.
const int kMinPasswordLength = 8;

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

  /// Nach dem Anlegen: Identitaet sichern.
  ///
  /// Der Moment ist bewusst gewaehlt. Wer sich von der App einen Schluessel
  /// erstellen laesst, bekommt ihn sonst NIE zu Gesicht — und erfaehrt auch
  /// nicht, dass er im Profil liegt. Bei einem Geheimnis ohne Zuruecksetzen
  /// ist das der falsche Zeitpunkt zum Schweigen.
  ///
  /// Zwei Wege, bewusst in dieser Reihenfolge: Die Backup-DATEI ist der
  /// sichere Weg — sie enthaelt Schluessel, Badges und Einstellungen und
  /// laesst sich verwahren. Der kopierte Schluessel ist der schnelle Weg
  /// fuer den Passwortmanager, geht aber ueber die Zwischenablage.
  Future<void> _offerBackupThenHome() async {
    if (!mounted) return;
    setState(() => _busy = false);
    final wrap = await LocalKeyVault.getPasswordWrap();
    if (wrap != null && wrap.isNotEmpty && mounted) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: cCard,
        // Nicht wegwischbar: Dieses eine Blatt soll man lesen. Der
        // "Spaeter"-Knopf bleibt der Ausweg.
        isDismissible: false,
        enableDrag: false,
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
                Row(children: [
                  const Icon(Icons.verified_user_rounded,
                      color: cOrange, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(t.idSetupSecureTitle,
                        style: const TextStyle(
                            color: cText,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(t.idSetupSecureBody,
                    style: const TextStyle(
                        color: cTextSecondary, height: 1.45, fontSize: 13.5)),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(ctx);
                    await BackupService.createBackup(context);
                    navigator.pop();
                  },
                  icon: const Icon(Icons.save_alt_rounded,
                      color: Colors.black, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  label: Text(t.idSetupSecureBackup,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: wrap));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.keyExportCopied)),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded,
                      color: cTextSecondary, size: 18),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: cTileBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  label: Text(t.idSetupSecureCopy,
                      style: const TextStyle(color: cTextSecondary)),
                ),
                const SizedBox(height: 14),
                // Der Satz, der bisher fehlte: WO die Schluessel spaeter
                // liegen. Ohne ihn sucht spaeter niemand im Profil.
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline_rounded,
                      color: cTextTertiary, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.idSetupSecureWhere,
                        style: const TextStyle(
                            color: cTextTertiary,
                            fontSize: 11.5,
                            height: 1.4)),
                  ),
                ]),
                const SizedBox(height: 6),
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

  /// Schritte, die den Hintergrund in voller Staerke tragen — dieselbe
  /// Bildsprache wie der IntroScreen davor.
  ///
  /// Das Kriterium ist, ob die Seite EINGABEFELDER hat, nicht wie sie
  /// heisst: Wo getippt wird, tritt das Bild als Wasserzeichen zurueck;
  /// wo nur ein Knopf steht, darf es wirken. Wer eine Seite verschiebt,
  /// aendert nur diese Menge.
  ///
  /// Mit Feldern (also NICHT hier): neu, resume, existingMore, nameOnly.
  static const _boldBackgroundSteps = <_SetupStep>{
    _SetupStep.choose,
    _SetupStep.passkey,
    _SetupStep.existing,
    _SetupStep.meetup,
  };

  bool get _boldBackground => _boldBackgroundSteps.contains(_step);

  /// Abdunklung ueber dem Hintergrundbild.
  ///
  /// Alle Zahlen hier sind am Bild GEMESSEN. Das Motiv ist von Haus aus
  /// sehr dunkel: Die hellsten Leiterbahnen liegen bei Helligkeit 36 von
  /// 255, die Flaeche dazwischen bei 0. Bei 0.52 — dem Wert des
  /// IntroScreens — bleiben davon 17 uebrig, und genau so sieht der
  /// Startbildschirm aus.
  ///
  /// Fuer das Wasserzeichen war MEHR Schwarz der falsche Hebel: Bei 0.68
  /// blieben 11 stehen, bei 0.86 nur 5 — beides ist auf dem Geraet nicht
  /// mehr von Schwarz zu unterscheiden. Deshalb wird das Bild fuer das
  /// Wasserzeichen stattdessen AUFGEHELLT (siehe _watermarkBoost) und dann
  /// normal abgedunkelt.
  static const double _veilBold = 0.52;
  static const double _veilSubtle = 0.55;

  /// Aufhellung des Wasserzeichens.
  ///
  /// Multipliziert die Helligkeit. Schwarz bleibt dabei schwarz (0 x 2.2 = 0),
  /// nur die Leiterbahnen werden heller — der Kontrast steigt also, statt
  /// dass alles grau wird. Nach Weichzeichnen und Abdunklung stehen die
  /// Linien bei rund 33 und damit etwa doppelt so hell wie auf den
  /// kraeftigen Seiten; die weiche Zeichnung haelt sie trotzdem im
  /// Hintergrund.
  static const double _watermarkBoost = 2.2;

  /// Weichzeichnung des Wasserzeichens. Sie kostet kaum Helligkeit
  /// (gemessen 36 auf 33), sorgt aber dafuer, dass die Leiterbahnen nicht
  /// mit den Eingabefeldern um Aufmerksamkeit konkurrieren.
  static const double _watermarkBlur = 4;

  /// Hintergrund fuer alle Schritte.
  ///
  /// Beide Fassungen liegen dauerhaft im Baum und werden ueberblendet,
  /// statt sie je nach Schritt neu aufzubauen: So gibt es beim Wechsel
  /// kein Aufblitzen, und das Bild wird nur einmal dekodiert.
  Widget _buildBackground() {
    final bold = _boldBackground;
    const asset = 'assets/images/intro_background_87.jpg';
    const fade = Duration(milliseconds: 450);

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Scharfe Fassung wie im IntroScreen.
            const Image(
              image: AssetImage(asset),
              fit: BoxFit.cover,
            ),

            // Weichgezeichnete UND aufgehellte Fassung, blendet auf den
            // Formularseiten ein.
            AnimatedOpacity(
              opacity: bold ? 0.0 : 1.0,
              duration: fade,
              curve: Curves.easeInOut,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                    sigmaX: _watermarkBlur, sigmaY: _watermarkBlur),
                child: ColorFiltered(
                  // Reine Helligkeitsmultiplikation: Die Diagonale skaliert
                  // R, G und B, die Alpha-Zeile bleibt unveraendert.
                  colorFilter: const ColorFilter.matrix(<double>[
                    _watermarkBoost, 0, 0, 0, 0, //
                    0, _watermarkBoost, 0, 0, 0, //
                    0, 0, _watermarkBoost, 0, 0, //
                    0, 0, 0, 1, 0, //
                  ]),
                  child: const Image(
                    image: AssetImage(asset),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Abdunklung — siehe _veilBold / _veilSubtle oben.
            AnimatedContainer(
              duration: fade,
              curve: Curves.easeInOut,
              color: Colors.black
                  .withValues(alpha: bold ? _veilBold : _veilSubtle),
            ),

            // Warmer Schein von oben, ebenfalls aus dem IntroScreen.
            Positioned(
              top: -80,
              left: 0,
              right: 0,
              height: 500,
              child: AnimatedOpacity(
                opacity: bold ? 1.0 : 0.7,
                duration: fade,
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.0,
                      colors: [
                        cOrange.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      // Der Hintergrund reicht bis unter die Titelleiste — sonst saesse
      // dort ein schwarzer Balken und das Bild begaenne mit einer Kante.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: AbsorbPointer(
            absorbing: _busy || _bootstrapping,
            child: ListView(
              // Oben kToolbarHeight zusaetzlich: Durch extendBodyBehindAppBar
              // beginnt der Body hinter der Titelleiste.
              padding: const EdgeInsets.fromLTRB(
                  24, 8 + kToolbarHeight, 24, 32),
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
        ],
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

  /// Dieselben Bedingungen wie beim Backup-Passwort, nur fuer ein anderes
  /// Geheimnis: Hier wird der PRIVATE SCHLUESSEL verpackt (NIP-49
  /// ncryptsec), beim Backup die ganze Sicherungsdatei. Zwei unabhaengige
  /// Passwoerter — man darf dasselbe nehmen, muss aber nicht.
  bool get _pwLongEnough => _passCtrl.text.length >= kMinPasswordLength;
  bool get _pwMatches =>
      _passCtrl.text.isNotEmpty && _passCtrl.text == _pass2Ctrl.text;
  bool get _pwOk => _pwLongEnough && _pwMatches;

  List<Widget> _buildNeu(AppLocalizations t) => [
        Text(t.idSetupNewHint,
            style: const TextStyle(color: cTextSecondary, height: 1.4)),
        const SizedBox(height: 20),
        _field(_nameCtrl, t.idSetupNameLabel, Icons.badge_outlined),
        const SizedBox(height: 12),
        _field(_passCtrl, t.idSetupPasswordLabel, Icons.lock_outline,
            obscure: true,
            borderColor:
                _pwBorder(_pwLongEnough, _passCtrl.text.isNotEmpty)),
        const SizedBox(height: 12),
        _field(_pass2Ctrl, t.idSetupPasswordConfirmLabel, Icons.lock_outline,
            obscure: true,
            borderColor: _pwBorder(_pwMatches, _pass2Ctrl.text.isNotEmpty)),
        const SizedBox(height: 4),
        _rule(_pwLongEnough, t.backupPwRuleLength(kMinPasswordLength)),
        _rule(_pwMatches, t.backupPwRuleMatch),
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
        // Gesperrt, solange die Bedingungen offen sind — zusammen mit der
        // Liste darueber ist damit sichtbar, WORAN es liegt.
        _primaryButton(t.idSetupCreate, _pwOk ? _register : null),
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
          // Kein Regelwerk: Hier wird ein BESTEHENDES Passwort eingegeben.
          // Eine Laengenpruefung wuerde nur aussperren, wer sein altes
          // Passwort kuerzer gewaehlt hat.
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
      const SizedBox(height: 12),
      // Frueher ein blosser Textknopf. Als Kachel wie auf der Startseite
      // sieht man erstens, DASS es ein zweiter Weg ist, und zweitens
      // wohin er fuehrt — "Anderer Weg" allein sagte beides nicht.
      _card(
        icon: Icons.alt_route_rounded,
        title: t.idSetupOtherWay,
        subtitle: t.idSetupOtherWaySub,
        onTap: () => setState(() {
          _error = null;
          _step = _SetupStep.existingMore;
        }),
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

  /// Welche Passwortfelder gerade offen liegen. Pro Feld, nicht global:
  /// Beim Bestaetigen will man oft nur EINES von beiden sehen.
  final Map<TextEditingController, bool> _revealed = {};

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    int maxLines = 1,
    /// Rahmenfarbe. null = neutral. Damit faerbt sich das Feld waehrend des
    /// Tippens rot oder gruen, statt erst beim Absenden zu meckern.
    Color? borderColor,
  }) {
    final revealed = _revealed[ctrl] ?? false;
    final border = borderColor ?? cTileBorder;

    return TextField(
      controller: ctrl,
      obscureText: obscure && !revealed,
      maxLines: obscure ? 1 : maxLines,
      style: const TextStyle(color: cText),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: cTextSecondary),
        prefixIcon: Icon(icon, color: cTextSecondary, size: 20),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                    revealed
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: cTextSecondary,
                    size: 20),
                onPressed: () =>
                    setState(() => _revealed[ctrl] = !revealed),
              )
            : null,
        filled: true,
        fillColor: cCard,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: border, width: borderColor != null ? 1.3 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor ?? cOrange, width: 1.6),
        ),
      ),
    );
  }

  /// Eine Zeile der Bedingungsliste.
  Widget _rule(bool ok, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(ok ? Icons.check_circle : Icons.circle_outlined,
              size: 15, color: ok ? cGreen : cTextTertiary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: ok ? cGreen : cTextSecondary,
                    fontSize: 12,
                    height: 1.35)),
          ),
        ]),
      );

  /// Rahmenfarbe fuer ein Passwortfeld: neutral solange leer, sonst rot
  /// oder gruen.
  Color? _pwBorder(bool ok, bool touched) =>
      touched ? (ok ? cGreen : cRed) : null;

  /// [onPressed] darf null sein — dann ist der Knopf gesperrt und der
  /// Farbverlauf weicht einer stumpfen Flaeche. Ohne diesen Unterschied
  /// saehe ein gesperrter Knopf aus wie ein bedienbarer, der nichts tut.
  Widget _primaryButton(String label, VoidCallback? onPressed) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? gradientOrange : null,
          color: enabled ? null : cSurface,
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
              style: TextStyle(
                  color: enabled ? Colors.black : cTextTertiary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ),
      ),
    );
  }
}
