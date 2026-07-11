// ============================================
// APP LOGGER — Sicheres Logging (Security Audit H1)
// ============================================
//
// Ersetzt alle print()-Aufrufe im Codebase.
// Sensible Daten (Keys, Seeds) werden NIEMALS geloggt.
//
// ERWEITERT: Zusätzlich zum Debug-Print hält der Logger einen
// PERSISTENTEN Ringpuffer diagnose-relevanter Ereignisse (Portal,
// Admin, Widget, Fehler/Warnungen). Diese werden — anders als die
// Debug-Prints — AUCH im Release-Build erfasst und in
// SharedPreferences gespeichert, damit der Log-Screen sie nach einem
// Neustart noch anzeigen und teilen kann. Ringpuffer-begrenzt.
// ============================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ein einzelner Diagnose-Eintrag.
class LogEntry {
  final DateTime time;
  final String level; // INFO | WARN | ERROR
  final String tag;
  final String message;

  LogEntry({required this.time, required this.level, required this.tag, required this.message});

  Map<String, dynamic> toJson() => {
        't': time.millisecondsSinceEpoch,
        'l': level,
        'g': tag,
        'm': message,
      };

  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(
        time: DateTime.fromMillisecondsSinceEpoch((j['t'] as num).toInt()),
        level: j['l'] as String? ?? 'INFO',
        tag: j['g'] as String? ?? '',
        message: j['m'] as String? ?? '',
      );

  String format() {
    String two(int n) => n.toString().padLeft(2, '0');
    final t = '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
    return '$t  $level  [$tag] $message';
  }
}

class AppLogger {
  // ── Persistenter Diagnose-Puffer ──
  static const String _prefsKey = 'diagnostic_log';
  static const int _maxEntries = 300;
  static final List<LogEntry> _buffer = [];
  static bool _loaded = false;

  /// Beim App-Start einmal aufrufen, um gespeicherte Logs zu laden.
  static Future<void> init() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _buffer
          ..clear()
          ..addAll(list.map((e) => LogEntry.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {/* korrupter Puffer -> leer starten */}
    _loaded = true;
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final slice = _buffer.length > _maxEntries
          ? _buffer.sublist(_buffer.length - _maxEntries)
          : _buffer;
      await prefs.setString(_prefsKey, jsonEncode(slice.map((e) => e.toJson()).toList()));
    } catch (_) {/* Persistenz best effort */}
  }

  static void _record(String level, String tag, String message) {
    _buffer.add(LogEntry(time: DateTime.now(), level: level, tag: tag, message: message));
    if (_buffer.length > _maxEntries) {
      _buffer.removeRange(0, _buffer.length - _maxEntries);
    }
    _persist();
  }

  /// Aktuelle Log-Einträge (neueste zuletzt).
  static List<LogEntry> get entries => List.unmodifiable(_buffer);

  /// Gesamter Log als Text (zum Teilen/Kopieren).
  static String exportText() => _buffer.map((e) => e.format()).join('\n');

  /// Log leeren.
  static Future<void> clear() async {
    _buffer.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  // ── Log-Level ──

  static void debug(String tag, String message) {
    if (kDebugMode) print('[$tag] $message');
  }

  static void info(String tag, String message) {
    if (kDebugMode) print('[$tag] $message');
  }

  static void warn(String tag, String message) {
    if (kDebugMode) print('[WARN:$tag] $message');
    _record('WARN', tag, message);
  }

  static void error(String tag, String message, [Object? error]) {
    if (kDebugMode) {
      print('[ERROR:$tag] $message');
      if (error != null) print('[ERROR:$tag] $error');
    }
    _record('ERROR', tag, error != null ? '$message ($error)' : message);
  }

  static void security(String tag, String message) {
    if (kDebugMode) print('[SEC:$tag] $message');
  }

  /// Diagnose-Ereignis: landet IMMER (auch Release) im persistenten
  /// Puffer und ist im Log-Screen sichtbar. Für Portal/Admin/Widget-
  /// Abläufe zur Fehlersuche. WICHTIG: keine Secrets (nsec/Token).
  static void diag(String tag, String message) {
    if (kDebugMode) print('[DIAG:$tag] $message');
    _record('INFO', tag, message);
  }
}
