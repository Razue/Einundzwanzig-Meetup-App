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

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ein einzelner Diagnose-Eintrag.
class LogEntry {
  final DateTime time;
  final String level; // DEBUG | INFO | SEC | WARN | ERROR
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
    final t = '${two(time.day)}.${two(time.month)} ${two(time.hour)}:'
        '${two(time.minute)}:${two(time.second)}';
    return '$t  ${level.padRight(5)} [$tag] $message';
  }
}

class AppLogger {
  // ── Persistenter Diagnose-Puffer ──
  static const String _prefsKey = 'diagnostic_log';
  static const String _prefsVerboseKey = 'diagnostic_verbose';
  // 800 statt 300: Mit eingeschaltetem Ausfuehrlich-Modus fuellt sich der
  // Puffer schnell — ein kompletter Meetup-Abend muss reinpassen.
  static const int _maxEntries = 800;
  static final List<LogEntry> _buffer = [];
  static bool _loaded = false;

  /// AUSFUEHRLICH-MODUS: Wenn an, landen auch debug()-Meldungen im Puffer.
  /// Standard aus, damit der Alltag nicht zugemuellt wird — vor dem
  /// Nachstellen eines Fehlers einschalten (Einstellungen -> Diagnose-Log).
  static bool _verbose = false;
  static bool get isVerbose => _verbose;

  static Future<void> setVerbose(bool on) async {
    _verbose = on;
    _record('INFO', 'Log', on
        ? 'Ausfuehrliches Log EINGESCHALTET — auch Detailmeldungen werden erfasst.'
        : 'Ausfuehrliches Log ausgeschaltet.');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsVerboseKey, on);
    } catch (_) {}
  }

  /// Beim App-Start einmal aufrufen, um gespeicherte Logs zu laden.
  static Future<void> init() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _verbose = prefs.getBool(_prefsVerboseKey) ?? false;
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

  static Timer? _persistTimer;

  /// Schreiben wird gebuendelt: Bei jedem Eintrag den ganzen Puffer zu
  /// serialisieren waere im Ausfuehrlich-Modus eine Bremse. Stattdessen
  /// wird 2 Sekunden nach der letzten Meldung EINMAL gespeichert.
  static void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 2), _persist);
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
    _schedulePersist();
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

  /// Detail-Meldung. Landet nur im Puffer, wenn der Ausfuehrlich-Modus an
  /// ist — sonst nur in der Debug-Konsole.
  /// (Vorher verschwanden diese Meldungen im Release SPURLOS; genau die
  /// Ketten, die man zur Fehlersuche braucht, fehlten deshalb im Log.)
  static void debug(String tag, String message) {
    if (kDebugMode) print('[$tag] $message');
    if (_verbose) _record('DEBUG', tag, message);
  }

  /// Normale Ablauf-Meldung — landet IMMER im Puffer.
  static void info(String tag, String message) {
    if (kDebugMode) print('[$tag] $message');
    _record('INFO', tag, message);
  }

  static void warn(String tag, String message) {
    if (kDebugMode) print('[WARN:$tag] $message');
    _record('WARN', tag, message);
  }

  static void error(String tag, String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      print('[ERROR:$tag] $message');
      if (error != null) print('[ERROR:$tag] $error');
      if (stack != null) print(stack.toString());
    }
    // Fehlertyp IMMER mitschreiben — "hat nicht geklappt" ohne Ursache
    // ist der Grund, warum Logs bisher nichts wert waren.
    final detail = error != null ? '$message — ${error.runtimeType}: $error' : message;
    _record('ERROR', tag, detail);
    // Erste Stack-Zeile hilft beim Einordnen, ohne das Log zu fluten.
    if (stack != null && _verbose) {
      final first = stack.toString().split('\n').take(3).join(' | ');
      _record('DEBUG', tag, 'Stack: $first');
    }
  }

  /// Sicherheitsrelevantes Ereignis — landet IMMER im Puffer.
  static void security(String tag, String message) {
    if (kDebugMode) print('[SEC:$tag] $message');
    _record('SEC', tag, message);
  }

  /// Trennlinie im Log — markiert den Beginn eines Ablaufs (App-Start,
  /// Scan, Session-Erstellung). Macht Fehlerketten im Log auffindbar.
  static void section(String title) {
    _record('INFO', 'ooo', '───── $title ─────');
  }

  /// Misst die Dauer eines Ablaufs und protokolliert Erfolg ODER Fehler
  /// mit Ursache. Ersetzt das Muster "try { ... } catch (_) {}", bei dem
  /// Fehler spurlos verschwinden.
  static Future<T?> measure<T>(
    String tag,
    String label,
    Future<T> Function() action, {
    bool rethrowError = false,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final result = await action();
      debug(tag, '$label ok (${sw.elapsedMilliseconds} ms)');
      return result;
    } catch (e, st) {
      error(tag, '$label FEHLGESCHLAGEN nach ${sw.elapsedMilliseconds} ms', e, st);
      if (rethrowError) rethrow;
      return null;
    }
  }

  /// Diagnose-Ereignis: landet IMMER (auch Release) im persistenten
  /// Puffer und ist im Log-Screen sichtbar. Für Portal/Admin/Widget-
  /// Abläufe zur Fehlersuche. WICHTIG: keine Secrets (nsec/Token).
  static void diag(String tag, String message) {
    if (kDebugMode) print('[DIAG:$tag] $message');
    _record('INFO', tag, message);
  }
}

/// Zaehlt nicht auswertbare Nachrichten EINER Relay-Subscription und meldet
/// sie einmal am Ende statt pro Nachricht.
///
/// Die Relay-Listener der App hatten bisher zwei Varianten, und beide waren
/// unbrauchbar:
///
///   - `catch (_) {}` — fehlerhafte Events verschwanden spurlos. Man sah eine
///     zu kurze Admin-Liste oder fehlende Buergschaften, ohne Hinweis darauf,
///     dass Events verworfen wurden.
///   - eine warn-Zeile pro Nachricht (admin_registry) — ein Relay mit
///     kaputten Events fuellte damit den 800er-Ringpuffer.
///
/// "3 von 47 nicht auswertbar" sagt mehr als beides und kostet eine Zeile.
/// Ist alles in Ordnung, schweigt der Zaehler vollstaendig.
class RelayParseTally {
  final String tag;
  final String label;
  int _seen = 0;
  int _failed = 0;
  Object? _firstError;
  bool _reported = false;

  RelayParseTally(this.tag, this.label);

  /// Pro eingehender Relay-Nachricht aufrufen.
  void message() => _seen++;

  /// Im catch der Nachrichtenverarbeitung aufrufen.
  /// [error] wird nur beim ersten Fehlschlag behalten und bei [report] auf
  /// debug ausgegeben — eine Stichprobe der Ursache ohne Log-Flut.
  void failed([Object? error]) {
    _failed++;
    _firstError ??= error;
  }

  int get seen => _seen;
  int get failures => _failed;

  /// Beim Abschluss der Subscription aufrufen — am besten im `finally`, damit
  /// auch Timeout und onDone erfasst sind, nicht nur EOSE.
  /// Mehrfach aufrufbar: weitere Aufrufe sind no-ops (z. B. finish + finally).
  void report() {
    if (_reported || _failed == 0) return;
    _reported = true;
    AppLogger.warn(
        tag, '$label: $_failed von $_seen Relay-Nachrichten nicht auswertbar');
    if (_firstError != null) {
      AppLogger.debug(tag, '$label — erster Parse-Fehler: $_firstError');
    }
  }
}
