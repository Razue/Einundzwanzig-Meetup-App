import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zentrales Haptik-Feedback mit einheitlichen Mustern.
///
/// Bisher standen `HapticFeedback.*`-Aufrufe verstreut im Code, mal
/// `mediumImpact`, mal `selectionClick` — ohne erkennbare Regel und ohne
/// Moeglichkeit, sie abzuschalten. Dieser Dienst legt fest, welches Muster
/// zu welcher Art von Ereignis gehoert, und respektiert eine Einstellung.
///
/// HINWEIS ZUR API: Flutter kennt KEIN `notificationFeedback`. Verfuegbar
/// sind ausschliesslich lightImpact, mediumImpact, heavyImpact,
/// selectionClick und vibrate. Erfolg und Fehler werden deshalb aus diesen
/// Bausteinen zusammengesetzt.
class HapticService {
  static const String _prefsKey = 'haptic_enabled';

  // Einmal gelesen und gemerkt: Bei jedem Tippen die Einstellungen von der
  // Platte zu lesen waere Verschwendung.
  static bool? _cached;

  static Future<bool> _isEnabled() async {
    if (_cached != null) return _cached!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cached = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {
      _cached = true;
    }
    return _cached!;
  }

  /// Schaltet die Haptik um und merkt sich die Wahl.
  static Future<void> setEnabled(bool on) async {
    _cached = on;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, on);
    } catch (_) {}
  }

  static Future<bool> isEnabled() => _isEnabled();

  /// Antippen von Kacheln, Knoepfen, Listeneintraegen.
  static Future<void> light() async {
    if (!await _isEnabled()) return;
    await HapticFeedback.selectionClick();
  }

  /// Zustandswechsel: angeheftet, umgeschaltet, ausgewaehlt.
  static Future<void> medium() async {
    if (!await _isEnabled()) return;
    await HapticFeedback.mediumImpact();
  }

  /// Gewichtige Aktion: Session gestartet, Tag beschrieben.
  static Future<void> heavy() async {
    if (!await _isEnabled()) return;
    await HapticFeedback.heavyImpact();
  }

  /// Erfolg — zwei kurze Stoesse. Fuehlt sich anders an als ein einzelner
  /// und markiert damit den Unterschied zwischen "getippt" und "geschafft".
  static Future<void> success() async {
    if (!await _isEnabled()) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.lightImpact();
  }

  /// Fehler — ein laengerer, unangenehmerer Impuls.
  static Future<void> error() async {
    if (!await _isEnabled()) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 110));
    await HapticFeedback.heavyImpact();
  }
}
