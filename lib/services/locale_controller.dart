// ============================================
// LOCALE CONTROLLER
// Verwaltet die gewählte App-Sprache (de/en/es) und
// persistiert sie. null = Systemsprache folgen.
// ============================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  static const String _key = 'app_locale';

  /// Aktuelle Auswahl als ValueNotifier — MaterialApp lauscht darauf.
  /// null bedeutet: der Systemsprache folgen.
  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  /// Unterstützte Sprachen (Reihenfolge = Anzeige im Picker).
  static const List<Locale> supported = [
    Locale('de'),
    Locale('en'),
    Locale('es'),
  ];

  /// Beim App-Start die gespeicherte Sprache laden.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && code.isNotEmpty) {
      locale.value = Locale(code);
    } else {
      locale.value = null; // System
    }
  }

  /// Sprache setzen (null = System) und persistieren.
  static Future<void> setLocale(Locale? value) async {
    locale.value = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, value.languageCode);
    }
  }

  /// Anzeigename einer Sprache (für den Picker).
  static String displayName(Locale? value) {
    switch (value?.languageCode) {
      case 'de':
        return 'Deutsch';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return 'System';
    }
  }
}
