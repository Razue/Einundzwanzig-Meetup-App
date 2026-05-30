// ============================================
// SIGNING SERVICE — Abstraktion über Key-Management
// ============================================
//
// Drei Identitäts-Quellen, EIN Signier-Interface.
//
//   1. LOCAL (generiert)  — App erzeugt das Keypair selbst.
//   2. LOCAL (importiert)  — User gibt seinen nsec ein.
//      Beide: nsec liegt im SecureKeyStore, wird ins
//      (verschlüsselte) Backup übernommen, Signatur via
//      Event.from(privkey: ...).
//
//   3. AMBER (NIP-55)     — Externer Signer. Die App sieht
//      den nsec NIEMALS. Jede Signatur geht über einen
//      Android-ContentResolver/Intent an die Amber-App.
//      Das Backup enthält KEINEN nsec, nur den npub + Modus.
//
// Alle Services die signieren rufen künftig NUR NOCH:
//
//     final signed = await SigningService.signEvent(
//       kind: 21000, tags: [...], content: '...');
//     signed.id / signed.sig / signed.pubkey / signed.createdAt
//
// statt direkt Event.from(kind: ..., privkey: ...).
//
// Die Architektur lehnt sich an die bewährte 21steps-Lösung an:
//   - abstraktes NostrSigner-Interface
//   - sealed Result-Klassen (kein null-Rätselraten)
//   - expectedPubkey-Check (erkennt "falsches Konto in Amber")
//   - Transport hinter dem Interface gekapselt → austauschbar
// ============================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_key_store.dart';
import 'app_logger.dart';

// =============================================
// SIGNING MODE
// =============================================

enum SigningMode {
  local, // App besitzt den privaten Schlüssel (generiert oder importiert)
  amber, // Externer Signer via NIP-55 — nsec verlässt Amber nie
}

// =============================================
// SIGNED EVENT — Ergebnis jeder Signatur
// =============================================
// Trägt exakt die Felder, die die Caller bisher von
// Event.from() gelesen haben: id, pubkey, createdAt, sig.
// =============================================

class SignedEvent {
  final String id;
  final String pubkey; // hex
  final int createdAt; // unix seconds
  final int kind;
  final List<List<String>> tags;
  final String content;
  final String sig;

  const SignedEvent({
    required this.id,
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    required this.tags,
    required this.content,
    required this.sig,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pubkey': pubkey,
        'created_at': createdAt,
        'kind': kind,
        'tags': tags,
        'content': content,
        'sig': sig,
      };

  /// WebSocket-kompatibler EVENT-Frame für Relay-Versand.
  String toEventMessage() => jsonEncode(['EVENT', toJson()]);
}

// =============================================
// FEHLER
// =============================================

class SigningException implements Exception {
  final String message;
  const SigningException(this.message);
  @override
  String toString() => message;
}

/// Wird geworfen, wenn der User die Signatur in Amber ablehnt
/// oder den Dialog wegklickt. Caller können das gezielt fangen,
/// um eine freundliche "Abgebrochen"-Meldung zu zeigen.
class SigningCancelledException extends SigningException {
  const SigningCancelledException()
      : super('Signatur in Amber abgebrochen.');
}

/// Amber ist nicht installiert.
class SignerMissingException extends SigningException {
  const SignerMissingException()
      : super('Amber (Nostr Signer) ist nicht installiert.');
}

/// In Amber ist ein anderes Konto aktiv als das, mit dem die
/// App verbunden wurde.
class WrongAccountException extends SigningException {
  const WrongAccountException()
      : super('Amber hat mit einem anderen Konto signiert als verbunden.');
}

// =============================================
// CONNECT-RESULT (sealed) — für den Verbindungs-Flow
// =============================================

sealed class AmberConnectResult {
  const AmberConnectResult();
}

class AmberConnectSuccess extends AmberConnectResult {
  final String pubkeyHex;
  final String npub;
  const AmberConnectSuccess({required this.pubkeyHex, required this.npub});
}

class AmberConnectMissing extends AmberConnectResult {
  const AmberConnectMissing();
}

class AmberConnectCancelled extends AmberConnectResult {
  const AmberConnectCancelled();
}

class AmberConnectError extends AmberConnectResult {
  final String message;
  const AmberConnectError(this.message);
}

// =============================================
// NOSTR SIGNER — abstraktes Interface
// =============================================
// Lässt uns Local/Amber/Mock tauschen, ohne dass ein
// einziger Service-Caller das mitbekommt.
// =============================================

abstract interface class NostrSigner {
  /// hex-pubkey der aktiven Identität (oder null).
  Future<String?> pubkeyHex();

  /// Signiert ein unsigniertes Event und liefert das vollständige
  /// signierte Event zurück.
  Future<SignedEvent> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  });
}

// =============================================
// LOCAL SIGNER — App besitzt den nsec
// =============================================

class LocalNostrSigner implements NostrSigner {
  @override
  Future<String?> pubkeyHex() async {
    final npub = await SecureKeyStore.getNpub();
    if (npub == null || npub.isEmpty) return null;
    try {
      return Nip19.decodePubkey(npub);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SignedEvent> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    final privHex = await SecureKeyStore.getPrivHex();
    if (privHex == null || privHex.isEmpty) {
      throw const SigningException('Kein privater Schlüssel vorhanden.');
    }

    final event = Event.from(
      kind: kind,
      tags: tags,
      content: content,
      privkey: privHex,
    );

    return SignedEvent(
      id: event.id,
      pubkey: event.pubkey,
      createdAt: event.createdAt,
      kind: kind,
      tags: tags,
      content: content,
      sig: event.sig,
    );
  }
}

// =============================================
// AMBER SIGNER — NIP-55 über eigenen Kotlin-Channel
// =============================================
// Der Kotlin-Layer versucht ZUERST den ContentResolver
// (Hintergrund, kein Popup wenn Permission gemerkt) und
// fällt nur dann auf einen Vordergrund-Intent zurück, wenn
// noch keine Berechtigung erteilt wurde. Das verhindert die
// Popup-Hölle bei den vielen Signier-Stellen der App.
// =============================================

class AmberNostrSigner implements NostrSigner {
  static const MethodChannel _channel =
      MethodChannel('einundzwanzig/amber_signer');

  /// Amber-Paketname (greenart7c3 = der offizielle Amber-Signer).
  static const String amberPackage = 'com.greenart7c3.nostrsigner';

  final String expectedPubkeyHex;
  const AmberNostrSigner({required this.expectedPubkeyHex});

  @override
  Future<String?> pubkeyHex() async => expectedPubkeyHex;

  /// Ist ein NIP-55 Signer (Amber) installiert?
  static Future<bool> isAvailable() async {
    try {
      final installed = await _channel.invokeMethod<bool>('isAppInstalled');
      return installed ?? false;
    } catch (e) {
      AppLogger.warn('AmberSigner', 'isAppInstalled fehlgeschlagen: $e');
      return false;
    }
  }

  /// Verbindungs-Flow: holt den pubkey aus Amber und bittet
  /// gleich um die Dauer-Berechtigung 'sign_event', damit
  /// spätere Signaturen ohne Popup laufen können.
  static Future<AmberConnectResult> connect() async {
    try {
      if (!await isAvailable()) return const AmberConnectMissing();

      final npub = await _channel.invokeMethod<String>('getPublicKey');
      if (npub == null || npub.trim().isEmpty) {
        return const AmberConnectCancelled();
      }

      try {
        final hex = Nip19.decodePubkey(npub.trim());
        return AmberConnectSuccess(pubkeyHex: hex, npub: npub.trim());
      } on Exception catch (e) {
        return AmberConnectError('Ungültiger pubkey von Amber: $e');
      }
    } on PlatformException catch (e) {
      if (e.code == 'cancelled') return const AmberConnectCancelled();
      if (e.code == 'signer_missing') return const AmberConnectMissing();
      return AmberConnectError(e.message ?? e.code);
    } catch (e) {
      return AmberConnectError(e.toString());
    }
  }

  @override
  Future<SignedEvent> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Unsigniertes Event so bauen, wie Amber es signieren soll.
    // pubkey + created_at + kind + tags + content müssen exakt
    // dem entsprechen, worüber Amber die id/sig berechnet.
    // WICHTIG: Im Event-Feld 'pubkey' steht HEX (NIP-01),
    // als 'current_user' erwartet NIP-55 aber den npub (bech32).
    final unsigned = <String, dynamic>{
      'pubkey': expectedPubkeyHex,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
    };

    String currentUserNpub;
    try {
      currentUserNpub = Nip19.encodePubkey(expectedPubkeyHex);
    } catch (_) {
      currentUserNpub = expectedPubkeyHex; // Fallback
    }

    final Map<dynamic, dynamic> result;
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'signEvent',
        {
          'package': amberPackage,
          'npub': currentUserNpub,
          'event': jsonEncode(unsigned),
        },
      );
      if (res == null) throw const SigningCancelledException();
      result = res;
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'cancelled':
        case 'rejected':
          throw const SigningCancelledException();
        case 'signer_missing':
          throw const SignerMissingException();
        default:
          throw SigningException('Amber-Fehler: ${e.message ?? e.code}');
      }
    }

    // Amber liefert das vollständige signierte Event als JSON
    // in der Spalte/Extra "event" zurück.
    final signedJsonRaw = result['event'];
    if (signedJsonRaw is! String || signedJsonRaw.isEmpty) {
      throw const SigningException('Amber hat kein signiertes Event geliefert.');
    }

    final Map<String, dynamic> signed;
    try {
      signed = jsonDecode(signedJsonRaw) as Map<String, dynamic>;
    } catch (e) {
      throw SigningException('Amber-Antwort nicht lesbar: $e');
    }

    final signedPubkey = (signed['pubkey'] ?? '') as String;
    // Schutz: Falls der User in Amber zwischenzeitlich das Konto
    // gewechselt hat, würde sonst eine fremde Signatur akzeptiert.
    if (signedPubkey.toLowerCase() != expectedPubkeyHex.toLowerCase()) {
      throw const WrongAccountException();
    }

    return SignedEvent(
      id: (signed['id'] ?? '') as String,
      pubkey: signedPubkey,
      createdAt: (signed['created_at'] ?? createdAt) as int,
      kind: kind,
      tags: tags,
      content: content,
      sig: (signed['sig'] ?? '') as String,
    );
  }
}

// =============================================
// SIGNING SERVICE — die Fassade für die ganze App
// =============================================

class SigningService {
  static const String _modeKey = 'signing_mode';
  static const String _amberPubkeyHexKey = 'amber_pubkey_hex';
  static const String _amberNpubKey = 'amber_npub';

  // =============================================
  // MODUS
  // =============================================

  static Future<SigningMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modeKey) == 'amber'
        ? SigningMode.amber
        : SigningMode.local;
  }

  static Future<void> _setMode(SigningMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _modeKey, mode == SigningMode.amber ? 'amber' : 'local');
  }

  static Future<bool> get isAmber async =>
      (await getMode()) == SigningMode.amber;

  // =============================================
  // AKTIVEN SIGNER AUFLÖSEN
  // =============================================

  static Future<NostrSigner> _resolveSigner() async {
    if (await isAmber) {
      final prefs = await SharedPreferences.getInstance();
      final hex = prefs.getString(_amberPubkeyHexKey);
      if (hex == null || hex.isEmpty) {
        throw const SigningException(
            'Amber-Modus aktiv, aber kein verbundener Schlüssel. '
            'Bitte Amber erneut verbinden.');
      }
      return AmberNostrSigner(expectedPubkeyHex: hex);
    }
    return LocalNostrSigner();
  }

  // =============================================
  // ZENTRALE SIGNIER-FUNKTION
  // =============================================
  // Der EINZIGE Weg, auf dem die App künftig signiert.
  // =============================================

  static Future<SignedEvent> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    final signer = await _resolveSigner();
    return signer.signEvent(kind: kind, tags: tags, content: content);
  }

  /// pubkey (hex) der aktiven Identität — unabhängig vom Modus.
  static Future<String?> pubkeyHex() async {
    final signer = await _resolveSigner();
    return signer.pubkeyHex();
  }

  /// npub der aktiven Identität — Amber-npub oder lokaler npub.
  static Future<String?> npub() async {
    if (await isAmber) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_amberNpubKey);
    }
    return SecureKeyStore.getNpub();
  }

  /// Kann die App aktuell überhaupt signieren?
  static Future<bool> canSign() async {
    if (await isAmber) {
      final prefs = await SharedPreferences.getInstance();
      final hex = prefs.getString(_amberPubkeyHexKey);
      return hex != null && hex.isNotEmpty;
    }
    final priv = await SecureKeyStore.getPrivHex();
    return priv != null && priv.isNotEmpty;
  }

  // =============================================
  // AMBER VERBINDEN / TRENNEN
  // =============================================

  /// Startet den Amber-Verbindungs-Flow und persistiert den
  /// pubkey + Modus bei Erfolg.
  static Future<AmberConnectResult> connectAmber() async {
    final result = await AmberNostrSigner.connect();
    if (result is AmberConnectSuccess) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_amberPubkeyHexKey, result.pubkeyHex);
      await prefs.setString(_amberNpubKey, result.npub);
      await _setMode(SigningMode.amber);
      AppLogger.security('SigningService',
          'Amber verbunden: ${_short(result.npub)} — nsec bleibt in Amber.');
    }
    return result;
  }

  /// Aktiviert den lokalen Modus (nach Key-Generierung/Import).
  static Future<void> useLocalMode() async {
    await _setMode(SigningMode.local);
  }

  /// Stellt den Amber-Modus aus einem Backup wieder her.
  /// Im Backup liegt nur der npub (kein nsec — der bleibt in Amber).
  static Future<void> restoreAmber(String npub) async {
    final hex = Nip19.decodePubkey(npub.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_amberPubkeyHexKey, hex);
    await prefs.setString(_amberNpubKey, npub.trim());
    await _setMode(SigningMode.amber);
  }

  /// Trennt Amber und löscht den gemerkten pubkey.
  static Future<void> disconnectAmber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_amberPubkeyHexKey);
    await prefs.remove(_amberNpubKey);
    await _setMode(SigningMode.local);
  }

  static String _short(String npub) =>
      npub.length < 16 ? npub : '${npub.substring(0, 12)}…${npub.substring(npub.length - 4)}';
}
