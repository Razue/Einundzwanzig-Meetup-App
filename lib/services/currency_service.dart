// ============================================
// CURRENCY SERVICE — gewählte Fiat-Währung (Issue #66)
// ============================================
//
// Eine Einstellung für die ganze App: Umrechner, Kacheln auf der
// Startseite, Bitcoin-Dashboard und Android-Widget zeigen dieselbe
// Währung. Gespeichert auf dem Gerät, bleibt über Neustart und Update.
//
// Vorher stand alles fest auf Euro. Im Umrechner liess sich zwar CHF oder
// USD waehlen, aber nur fuer die Dauer des Bildschirms — beim naechsten
// Oeffnen stand wieder EUR da, und die Kacheln zeigten ohnehin nur €.
//
// Standard bleibt EUR, damit sich fuer bestehende Nutzer nichts aendert.
// ============================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mempool.dart';
import 'widget_service.dart';

class CurrencyService {
  static const String _key = 'fiat_currency';
  static const String fallback = 'EUR';

  /// Alle waehlbaren Waehrungen — genau die, fuer die mempool.space Kurse
  /// liefert.
  static List<String> get supported => MempoolService.supportedCurrencies;

  /// Aktuelle Auswahl. Bildschirme lauschen darauf und zeichnen neu,
  /// sobald jemand umstellt.
  static final ValueNotifier<String> current = ValueNotifier<String>(fallback);

  /// Beim App-Start die gespeicherte Waehrung laden.
  static Future<void> load() async {
    current.value = await read();
  }

  /// Gespeicherte Waehrung direkt aus dem Speicher — auch fuer
  /// Hintergrund-Aufrufe (Widget), in denen [load] nie lief.
  static Future<String> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && supported.contains(code)) return code;
    } catch (_) {}
    return fallback;
  }

  /// Waehrung setzen und speichern.
  static Future<void> set(String code) async {
    if (!supported.contains(code)) return;
    current.value = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {}
    // Das Homescreen-Widget sofort nachziehen, nicht erst beim naechsten
    // Abruf — sonst stuende dort noch eine Weile die alte Waehrung.
    final d = MempoolService.lastDashboard;
    if (d != null) unawaited(WidgetService.updateBitcoin(d));
  }

  /// Kurzzeichen fuer die Anzeige hinter dem Betrag.
  ///
  /// CAD und AUD bekommen ein Laenderkuerzel, damit sie nicht mit dem
  /// US-Dollar verwechselt werden. Der Franken hat kein eigenes Zeichen —
  /// "CHF" ist in der Schweiz die uebliche Schreibweise.
  static String symbol(String code) {
    switch (code) {
      case 'EUR':
        return '€';
      case 'USD':
        return r'$';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return r'CA$';
      case 'AUD':
        return r'A$';
      default:
        return code;
    }
  }

  /// Ganze Zahl mit Tausenderpunkten: 95000 → "95.000".
  static String groupInt(int v) {
    final neg = v < 0;
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return neg ? '-$buf' : buf.toString();
  }

  /// BTC-Kurs als Text, z. B. "95.000 €" oder "84.000 CHF".
  static String formatPrice(double price, [String? code]) {
    final c = code ?? current.value;
    return '${groupInt(price.round())} ${symbol(c)}';
  }
}
