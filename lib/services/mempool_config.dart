// ============================================
// MEMPOOL CONFIG — Konfigurierbare Datenquelle
// ============================================
// Bestimmt, von welcher Mempool-Instanz die Bitcoin-Daten geholt werden.
//
// Drei Modi:
//   1. Clearnet (Default)  -> https://mempool.space
//   2. Tor / Onion         -> offizielle .onion von mempool.space
//   3. Eigene Instanz      -> frei eingetragene URL (eigener Node, Umbrel, ...)
//
// HINTERGRUND (wichtig):
// mempool.space liegt hinter Cloudflare. Anfragen von Tor-Exit-Knoten werden
// dort regelmäßig mit 403/429 abgewiesen oder mit einer HTML-Challenge
// beantwortet — die App bekommt dann kein JSON und zeigte bisher stumm
// Nullen an. Über die Onion-Adresse entfällt der Cloudflare-Filter komplett,
// weil die Verbindung nicht über einen Exit-Knoten läuft.
//
// Die Onion-Adresse ist die offizielle, von mempool.space selbst per
// "onion-location"-HTTP-Header veröffentlichte Adresse.
//
// Voraussetzung für den Tor-Modus: Orbot läuft im VPN-Modus (dort löst
// Orbot .onion-Namen selbst auf). Ohne Orbot ist eine .onion nicht erreichbar.
// ============================================

import 'package:shared_preferences/shared_preferences.dart';

enum MempoolMode { clearnet, tor, custom }

class MempoolConfig {
  // =============================================
  // FESTE ADRESSEN
  // =============================================
  static const String clearnetHost = 'https://mempool.space';

  /// Offizielle Onion-Adresse von mempool.space (onion-location-Header).
  static const String torHost =
      'http://mempoolhqx4isw62xs7abwphsq7ldayuidyx2v2oethdhhj6mlo2r6ad.onion';

  // Prefs-Keys
  static const String _kHost = 'mempool_host';

  // =============================================
  // ZUSTAND (einmal geladen, dann im Speicher)
  // =============================================
  static String _host = clearnetHost;
  static bool _loaded = false;

  /// Muss vor dem ersten Netzzugriff einmal gelaufen sein. Idempotent —
  /// jeder Aufrufer kann das gefahrlos awaiten (MempoolService tut das).
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kHost);
      if (saved != null && saved.trim().isNotEmpty) {
        _host = normalize(saved);
      }
    } catch (_) {
      // Prefs nicht lesbar -> Default bleibt stehen. Kein harter Fehler.
    }
    _loaded = true;
  }

  /// Aktueller Host OHNE `/api` und ohne Slash am Ende.
  static String get host => _host;

  /// Basis-URL für API-Aufrufe, z.B. `https://mempool.space/api`.
  static String get apiBase => '$_host/api';

  static bool get isOnion => _host.contains('.onion');

  /// Tor ist deutlich langsamer als Clearnet — großzügigeres Zeitlimit,
  /// sonst laufen die Requests in einen Timeout, obwohl sie noch unterwegs sind.
  static Duration get timeout =>
      isOnion ? const Duration(seconds: 45) : const Duration(seconds: 20);

  static MempoolMode get mode {
    if (_host == clearnetHost) return MempoolMode.clearnet;
    if (_host == torHost) return MempoolMode.tor;
    return MempoolMode.custom;
  }

  // =============================================
  // SETZEN
  // =============================================
  static Future<void> setHost(String raw) async {
    _host = normalize(raw);
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kHost, _host);
    } catch (_) {
      // Speichern fehlgeschlagen -> gilt zumindest für diese Sitzung.
    }
  }

  static Future<void> setMode(MempoolMode m, {String custom = ''}) async {
    switch (m) {
      case MempoolMode.clearnet:
        await setHost(clearnetHost);
        break;
      case MempoolMode.tor:
        await setHost(torHost);
        break;
      case MempoolMode.custom:
        await setHost(custom);
        break;
    }
  }

  // =============================================
  // NORMALISIEREN
  // Nutzer tippen alles Mögliche: mit/ohne Schema, mit /api hinten,
  // mit Slash am Ende. Hier wird daraus eine saubere Basis.
  // =============================================
  static String normalize(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return clearnetHost;

    // Schema ergänzen, falls es fehlt: .onion -> http, sonst https.
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = s.contains('.onion') ? 'http://$s' : 'https://$s';
    }

    // Slashes und ein evtl. mitgetipptes /api am Ende entfernen.
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.toLowerCase().endsWith('/api')) {
      s = s.substring(0, s.length - 4);
    }
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Grobe Plausibilitätsprüfung für die freie Eingabe.
  static bool looksValid(String raw) {
    final s = normalize(raw);
    final uri = Uri.tryParse(s);
    return uri != null && uri.host.isNotEmpty && uri.host.contains('.');
  }
}
