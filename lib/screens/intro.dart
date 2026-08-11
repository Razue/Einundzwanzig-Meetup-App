import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_controller.dart';
import 'identity_setup_screen.dart';
import 'app_shell.dart';  // NEU: Statt dashboard.dart
import '../services/backup_service.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  bool _showLogo = false;
  bool _showSlogan = false;
  bool _showButton = false;
  bool _isLoading = false;

  // NEU: Sanftere Animation über Controller
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _startAnimation();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _showLogo = true);

    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _showSlogan = true);

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _showButton = true);
  }

  // --- BACKUP LOGIK (1:1 aus original) ---
  void _restoreAccount() async {
    bool success = await BackupService.restoreBackup(context);
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AppShell(),  // NEU
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  void _enterCommunity() async {
    setState(() => _isLoading = true);
    UserProfile user = await UserProfile.load();
    if (!mounted) return;

    if (!user.isOnboarded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).introSetIdentity),
          backgroundColor: cOrange,
          duration: const Duration(seconds: 3),
        ),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const IdentitySetupScreen()),
      );
      user = await UserProfile.load();
      if (!mounted) return;
      if (!user.isOnboarded) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (!mounted) return;

    // NEU: Route zu AppShell statt DashboardScreen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/intro_background_87.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.52),
            ),
          ),

          // Ambient Glow
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            height: 500,
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

          // Sprachauswahl oben rechts
          Positioned(
            top: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: ValueListenableBuilder<Locale?>(
                  valueListenable: LocaleController.locale,
                  builder: (_, current, __) => GestureDetector(
                    onTap: _showLanguagePopup,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cTileBorder, width: 0.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_flagFor(current), style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        const Icon(Icons.expand_more_rounded, color: cTextSecondary, size: 16),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutExpo,
                  opacity: _showLogo ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutExpo,
                    offset: _showLogo ? Offset.zero : const Offset(0, 0.3),
                    child: Image.asset(
                      'assets/images/intro_logo_86.png',
                      width: 340,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // SLOGAN
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: _showSlogan ? 1.0 : 0.0,
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context).introTagline,
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 3.5,
                          color: cTextSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: gradientOrange,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 56),

                // BUTTONS
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _showButton ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 500),
                    offset: _showButton ? Offset.zero : const Offset(0, 0.2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          // Hauptbutton mit Gradient
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _isLoading ? null : gradientOrange,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _isLoading ? [] : [
                                  BoxShadow(
                                    color: cOrange.withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _enterCommunity,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        AppLocalizations.of(context).introJoin,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: _isLoading ? null : _restoreAccount,
                            icon: Icon(Icons.restore_rounded,
                                color: cOrange.withValues(alpha: 0.7), size: 18),
                            label: Text(
                              AppLocalizations.of(context).introLoadBackup,
                              style: TextStyle(
                                color: cOrange.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Flaggen-Emoji je Sprache (System = Globus)
  String _flagFor(Locale? loc) {
    switch (loc?.languageCode) {
      case 'de': return '🇩🇪';
      case 'en': return '🇬🇧';
      case 'es': return '🇪🇸';
      default: return '🌐';
    }
  }

  // Popup-Dialog mit Sprachauswahl (Flagge + Name)
  void _showLanguagePopup() {
    showDialog(
      context: context,
      builder: (dialogCtx) => ValueListenableBuilder<Locale?>(
        valueListenable: LocaleController.locale,
        builder: (_, current, __) => Dialog(
          backgroundColor: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(children: [
                const Icon(Icons.language_rounded, color: cOrange, size: 20),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).settingsLanguageChoose,
                    style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
            ),
            const Divider(color: cBorder, height: 1),
            _langOption('🌐', 'System', null, current, dialogCtx),
            _langOption('🇩🇪', 'Deutsch', const Locale('de'), current, dialogCtx),
            _langOption('🇬🇧', 'English', const Locale('en'), current, dialogCtx),
            _langOption('🇪🇸', 'Español', const Locale('es'), current, dialogCtx),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _langOption(String flag, String label, Locale? value, Locale? current, BuildContext dialogCtx) {
    final selected = current?.languageCode == value?.languageCode;
    return InkWell(
      onTap: () async {
        await LocaleController.setLocale(value);
        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: selected ? cOrange.withValues(alpha: 0.08) : Colors.transparent,
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(
            color: selected ? cOrange : cText,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
          if (selected) const Icon(Icons.check_circle_rounded, color: cOrange, size: 20),
        ]),
      ),
    );
  }
}

