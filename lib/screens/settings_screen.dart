// ============================================
// SETTINGS — mit Sprachauswahl (de/en/es/System)
// ============================================
// Eigenständiger Screen. Von überall aus erreichbar, z.B.:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const SettingsScreen()));
// (z.B. am Zahnrad-Icon im Home-Header verlinken.)

import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/locale_controller.dart';
import '../l10n/app_localizations.dart';
import 'v4v_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- SPRACHE ---
          Text(
            t.settingsLanguage.toUpperCase(),
            style: const TextStyle(
                color: cOrange, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<Locale?>(
            valueListenable: LocaleController.locale,
            builder: (context, current, _) {
              return Column(
                children: [
                  _langTile(t.settingsLanguageSystem, null, current),
                  ...LocaleController.supported.map(
                    (loc) => _langTile(
                        LocaleController.displayName(loc), loc, current),
                  ),
                ],
              );
            },
          ),

          // --- V4V (Value for Value) ---
          const SizedBox(height: 28),
          Text(
            t.v4vSectionTitle.toUpperCase(),
            style: const TextStyle(
                color: cOrange, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cBorder, width: 0.5),
            ),
            child: ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: cOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: cOrange, size: 20),
              ),
              title: Text('V4V', style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
              subtitle: Text(t.v4vSectionSubtitle, style: const TextStyle(color: cTextSecondary, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: cTextTertiary),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const V4VScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _langTile(String label, Locale? value, Locale? current) {
    final selected = current?.languageCode == value?.languageCode;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? cOrange : cBorder,
          width: selected ? 1.5 : 0.5,
        ),
      ),
      child: ListTile(
        title: Text(label,
            style: TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        trailing: selected
            ? const Icon(Icons.check_circle, color: cOrange)
            : const Icon(Icons.circle_outlined, color: Colors.grey),
        onTap: () => LocaleController.setLocale(value),
      ),
    );
  }
}
