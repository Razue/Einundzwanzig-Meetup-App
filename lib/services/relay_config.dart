// ============================================
// RELAY CONFIG — Konfigurierbare Nostr-Relays
// ============================================
// Verwaltet Default-Relays und benutzerdefinierte Relays.
// Alle Services die Relays nutzen (AdminRegistry,
// PromotionClaimService, ReputationPublisher) sollten
// diese zentrale Konfiguration verwenden.
//
// Default-Relays sind bewährte, zuverlässige Relays.
// Der Nutzer kann in den Einstellungen eigene Relays
// hinzufügen oder Default-Relays deaktivieren.
// ============================================

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Ergebnis des Hinzufuegens eines Relays.
///
/// Bewusst ein eigener Typ statt geworfener Ausnahmen: Der Aufrufer muss
/// die Faelle unterscheiden koennen, um den passenden UEBERSETZTEN Text zu
/// zeigen. Der frueher geworfene ArgumentError trug einen fest verdrahteten
/// deutschen Text — weder uebersetzbar noch unterscheidbar.
enum RelayAddResult { added, invalidUrl, unreachable, alreadyPresent }

class RelayConfig {
  // =============================================
  // DEFAULT-RELAYS
  // =============================================
  static const List<String> defaultRelays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.nostr.band',
    'wss://nostr.einundzwanzig.space',
  ];

  // Cache Keys
  static const String _customRelaysKey = 'custom_relays';
  static const String _disabledDefaultsKey = 'disabled_default_relays';

  // Timeout
  static const Duration relayTimeout = Duration(seconds: 8);
  static const Duration publishTimeout = Duration(seconds: 5);

  // =============================================
  // AKTIVE RELAYS ABRUFEN
  // Gibt alle aktiven Relays zurück:
  // Default-Relays (sofern nicht deaktiviert) + Custom-Relays
  // =============================================
  static Future<List<String>> getActiveRelays() async {
    final prefs = await SharedPreferences.getInstance();

    // Deaktivierte Default-Relays laden
    final disabledJson = prefs.getStringList(_disabledDefaultsKey) ?? [];

    // Aktive Default-Relays
    final activeDefaults = defaultRelays
        .where((r) => !disabledJson.contains(r))
        .toList();

    // Custom-Relays laden
    final customRelays = prefs.getStringList(_customRelaysKey) ?? [];

    // Zusammenführen und Duplikate entfernen
    final all = <String>{...activeDefaults, ...customRelays};
    return all.toList();
  }

  // =============================================
  // CUSTOM-RELAYS VERWALTEN
  // =============================================
  static Future<List<String>> getCustomRelays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_customRelaysKey) ?? [];
  }

  /// Prueft die Schreibweise einer Relay-Adresse.
  ///
  /// Die alte Pruefung sah nur das Praefix. `wss://Test.nostr.band` kam
  /// damit durch — syntaktisch tadellos, nur existiert der Host nicht.
  /// Deshalb prueft diese Methode nur das Offensichtliche; ob wirklich
  /// jemand antwortet, klaert [probeRelay].
  static bool isWellFormedRelayUrl(String url) {
    final trimmed = url.trim();
    if (!trimmed.startsWith('wss://')) return false;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme != 'wss') return false;

    final host = uri.host;
    if (host.isEmpty) return false;
    // Ein Punkt mit etwas davor und dahinter; keine Leerzeichen.
    if (!host.contains('.')) return false;
    if (host.startsWith('.') || host.endsWith('.')) return false;
    if (host.contains(' ')) return false;
    // Pfad, Abfrage oder Fragment gehoeren nicht in eine Relay-Adresse.
    if (uri.path.isNotEmpty && uri.path != '/') return false;
    if (uri.hasQuery || uri.hasFragment) return false;
    return true;
  }

  /// Baut testweise eine Verbindung auf und gibt zurueck, ob das Relay
  /// antwortet. Ohne diesen Schritt landen Tippfehler dauerhaft in der
  /// Liste und zaehlen dort als "aktives Relay" mit.
  static Future<bool> probeRelay(
    String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    WebSocketChannel? channel;
    try {
      channel = WebSocketChannel.connect(Uri.parse(url.trim()));
      await channel.ready.timeout(timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      // Verbindung in jedem Fall wieder schliessen — auch im Erfolgsfall,
      // die Pruefung soll keine offene Leitung hinterlassen.
      try {
        await channel?.sink.close();
      } catch (_) {}
    }
  }

  /// Fuegt ein eigenes Relay hinzu — nur, wenn die Adresse stimmt UND das
  /// Relay antwortet.
  static Future<RelayAddResult> addCustomRelay(String url) async {
    final trimmed = url.trim();
    if (!isWellFormedRelayUrl(trimmed)) return RelayAddResult.invalidUrl;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customRelaysKey) ?? [];
    if (current.contains(trimmed) || defaultRelays.contains(trimmed)) {
      return RelayAddResult.alreadyPresent;
    }

    if (!await probeRelay(trimmed)) return RelayAddResult.unreachable;

    current.add(trimmed);
    await prefs.setStringList(_customRelaysKey, current);
    return RelayAddResult.added;
  }

  static Future<void> removeCustomRelay(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customRelaysKey) ?? [];
    current.remove(url);
    await prefs.setStringList(_customRelaysKey, current);
  }

  // =============================================
  // DEFAULT-RELAYS AKTIVIEREN/DEAKTIVIEREN
  // =============================================
  static Future<List<String>> getDisabledDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_disabledDefaultsKey) ?? [];
  }

  static Future<void> setDefaultRelayEnabled(String url, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final disabled = prefs.getStringList(_disabledDefaultsKey) ?? [];
    if (enabled) {
      disabled.remove(url);
    } else {
      if (!disabled.contains(url)) disabled.add(url);
    }
    await prefs.setStringList(_disabledDefaultsKey, disabled);
  }

  // =============================================
  // RELAY-STATUS (für UI)
  // =============================================
  static Future<Map<String, bool>> getRelayStatus() async {
    final disabled = await getDisabledDefaults();
    final custom = await getCustomRelays();

    final status = <String, bool>{};
    for (final r in defaultRelays) {
      status[r] = !disabled.contains(r);
    }
    for (final r in custom) {
      status[r] = true; // Custom Relays sind immer aktiv
    }
    return status;
  }
}