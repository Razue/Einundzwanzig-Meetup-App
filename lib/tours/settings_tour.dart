import 'package:flutter/material.dart';
import '../services/guide_service.dart';

/// Tour durch das Einstellungs-Sheet.
///
/// Laeuft INNERHALB des Sheets: Die Ziele liegen auf dessen eigener
/// Route, die waehrend der Tour obenauf liegt — genau deshalb findet
/// das Overlay sie und blendet sich nicht aus.
///
/// Erster und wichtigster Schritt ist das Backup. Ohne gesicherten
/// Schluessel ist bei Geraeteverlust alles weg: Reputation, Badges,
/// Vertrauensnetzwerk. Deshalb steht es vorn und nicht irgendwo
/// zwischen Sprache und Haptik.
class SettingsTour {
  SettingsTour._();

  static final backupKey = GlobalKey(debugLabel: 'guide_set_backup');
  static final relaysKey = GlobalKey(debugLabel: 'guide_set_relays');
  static final languageKey = GlobalKey(debugLabel: 'guide_set_language');
  static final hapticKey = GlobalKey(debugLabel: 'guide_set_haptic');
  static final resetKey = GlobalKey(debugLabel: 'guide_set_reset');

  /// Reihenfolge folgt dem Sheet von oben nach unten.
  static List<GuideStep> steps() => [
        // 1 — Backup. Der Grund, warum es diese Tour gibt.
        GuideStep(
          targetKey: backupKey,
          titleKey: 'guideSettingsBackupTitle',
          bodyKey: 'guideSettingsBackupBody',
          hintKey: 'guideHintBackup',
        ),

        // 2 — Relays
        GuideStep(
          targetKey: relaysKey,
          titleKey: 'guideSettingsRelaysTitle',
          bodyKey: 'guideSettingsRelaysBody',
        ),

        // 3 — Sprache
        GuideStep(
          targetKey: languageKey,
          titleKey: 'guideSettingsLanguageTitle',
          bodyKey: 'guideSettingsLanguageBody',
        ),

        // 4 — Haptik. Das Loch bleibt bedienbar, damit der Schalter
        //     gleich ausprobiert werden kann.
        GuideStep(
          targetKey: hapticKey,
          titleKey: 'guideSettingsHapticTitle',
          bodyKey: 'guideSettingsHapticBody',
        ),

        // 5 — Tour wiederholen
        GuideStep(
          targetKey: resetKey,
          titleKey: 'guideSettingsResetTitle',
          bodyKey: 'guideSettingsResetBody',
        ),
      ];
}
