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
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_key_store.dart';
import 'app_logger.dart';
import 'nip07/nip07_bridge.dart';
import 'nip07/nip07_exception.dart';

// =============================================
// SIGNING MODE
// =============================================

enum SigningMode {
  local, // App besitzt den privaten Schlüssel (generiert oder importiert)
  amber, // Externer Signer via NIP-55 — nsec verlässt Amber nie
  nip07, // Externer Signer via NIP-07 (Browsererweiterung) — nur im Web
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

      final raw = await _channel.invokeMethod<String>('getPublicKey');
      if (raw == null || raw.trim().isEmpty) {
        return const AmberConnectCancelled();
      }

      // Amber kann den Schlüssel in verschiedenen Formaten zurückgeben:
      // - "npub1..."            (bech32)
      // - roher Hex-pubkey       (64 Hex-Zeichen)
      // - JSON wie {"result":"npub1..."} (manche Versionen/Sonderfälle)
      var value = raw.trim();

      // Falls JSON: das "result"/"npub"-Feld herausziehen.
      if (value.startsWith('{')) {
        try {
          final map = jsonDecode(value) as Map<String, dynamic>;
          value = (map['result'] ?? map['npub'] ?? map['pubkey'] ?? '')
              .toString()
              .trim();
        } catch (_) {/* unten weiter versuchen */}
      }

      try {
        String hex;
        String npub;
        if (value.startsWith('npub1')) {
          // bech32 -> hex
          hex = Nip19.decodePubkey(value);
          npub = value;
        } else if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value)) {
          // schon roher Hex-pubkey -> npub daraus bilden
          hex = value.toLowerCase();
          npub = Nip19.encodePubkey(hex);
        } else {
          return AmberConnectError('Unerwartetes Schlüsselformat von Amber.');
        }
        return AmberConnectSuccess(pubkeyHex: hex, npub: npub);
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
// NIP-07 SIGNER — Browsererweiterung (Alby, nos2x, Flamingo, …)
// =============================================
// Das Gegenstück zu Amber für den Browser: der private Schlüssel liegt in
// der Erweiterung und verlässt sie nie. Im Web ist das der einzige Weg,
// bei dem der nsec NICHT in localStorage landen muss.
//
// Aufbau bewusst parallel zu AmberNostrSigner, inklusive der Prüfung auf
// Kontowechsel: wer in der Erweiterung das Konto umstellt, würde sonst
// unbemerkt mit einem fremden Schlüssel signieren.
// =============================================

class Nip07NostrSigner implements NostrSigner {
  /// Der beim Verbinden gemerkte pubkey — gegen den wird geprüft.
  final String expectedPubkeyHex;

  /// NUR für Tests: ersetzt den Weg zur Erweiterung.
  ///
  /// Ohne diese Naht wären die drei Sicherheitsprüfungen in signEvent
  /// (Kontowechsel, veränderter Event-Typ, veränderter Inhalt) nicht
  /// automatisiert prüfbar: nip07SignEvent ist eine Top-Level-Funktion hinter
  /// einem bedingten Export und lässt sich nicht ersetzen. Genau diese drei
  /// Prüfungen sind der sicherheitsrelevante Teil des Signers — die sollten
  /// nicht ungetestet bleiben.
  @visibleForTesting
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)?
      debugSignFn;

  const Nip07NostrSigner({required this.expectedPubkeyHex, this.debugSignFn});

  /// Ist eine NIP-07-Erweiterung vorhanden? Ausserhalb des Browsers false.
  static Future<bool> isAvailable() => nip07Available();

  /// Verbindungs-Flow: holt den pubkey aus der Erweiterung.
  static Future<Nip07ConnectResult> connect() async {
    try {
      if (!await nip07Available()) return const Nip07ConnectMissing();
      final hex = await nip07GetPublicKey();
      final npub = Nip19.encodePubkey(hex);
      return Nip07ConnectSuccess(pubkeyHex: hex, npub: npub);
    } on Nip07RejectedException {
      return const Nip07ConnectRejected();
    } on Nip07Exception catch (e) {
      return Nip07ConnectError(e.message);
    } catch (e) {
      return Nip07ConnectError(e.toString());
    }
  }

  @override
  Future<String?> pubkeyHex() async => expectedPubkeyHex;

  @override
  Future<SignedEvent> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Ohne 'pubkey': NIP-07 schreibt vor, dass die Erweiterung ihn selbst
    // setzt. Manche Erweiterungen lehnen ein mitgeliefertes Feld ab, wenn es
    // vom aktiven Konto abweicht.
    final unsigned = <String, dynamic>{
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
    };

    final Map<String, dynamic> signed;
    try {
      signed = await (debugSignFn ?? nip07SignEvent)(unsigned);
    } on Nip07RejectedException {
      throw const SigningCancelledException();
    } on Nip07Exception catch (e) {
      throw SigningException(e.message);
    }

    final signedPubkey = (signed['pubkey'] ?? '').toString();
    // Schutz wie bei Amber: Kontowechsel in der Erweiterung darf keine
    // fremde Signatur durchlassen.
    if (signedPubkey.toLowerCase() != expectedPubkeyHex.toLowerCase()) {
      throw const WrongAccountException();
    }

    final sig = (signed['sig'] ?? '').toString();
    if (sig.isEmpty) {
      throw const SigningException(
          'Die Erweiterung hat kein signiertes Event geliefert.');
    }

    // kind und content dürfen sich NICHT ändern.
    //
    // Bei tags ist die Übernahme richtig: id und sig sind nach NIP-01 darüber
    // berechnet, und Normalisierung durch die Erweiterung (Sortierung,
    // Zusatzfelder) ist legitim — eine Caller-Kopie würde das Event ungültig
    // machen und Relays würden es verwerfen.
    //
    // Für kind und content gilt das nicht. Würden sie ungeprüft übernommen,
    // veröffentlichte die App Inhalte, die sie nicht verfasst hat, unter dem
    // Namen des Nutzers — und ihre eigene Logik (Reputations-Payload,
    // Badge-Proofs) rechnete danach mit verändertem Inhalt weiter. Eine
    // Erweiterung, die hier abweicht, ist defekt; das will man sehen, nicht
    // stillschweigend übernehmen.
    if (signed['kind'] is int && signed['kind'] as int != kind) {
      throw SigningException(
          'Die Erweiterung hat einen anderen Event-Typ signiert '
          '(${signed['kind']} statt $kind).');
    }
    if (signed.containsKey('content') &&
        (signed['content'] ?? '').toString() != content) {
      throw const SigningException(
          'Die Erweiterung hat den Inhalt des Events verändert.');
    }

    return SignedEvent(
      id: (signed['id'] ?? '').toString(),
      pubkey: signedPubkey,
      // created_at der Erweiterung gewinnt: id und sig sind darüber
      // berechnet, ein abweichender Wert würde das Event ungültig machen.
      createdAt: signed['created_at'] is int
          ? signed['created_at'] as int
          : createdAt,
      // kind und content stammen aus dem Aufruf, nicht aus der Antwort — die
      // Prüfung oben stellt sicher, dass beides übereinstimmt. So steht die
      // Invariante im Code, statt sie aus zwei Stellen erschliessen zu müssen.
      kind: kind,
      tags: _tagsFromSigned(signed['tags'], tags),
      content: content,
      sig: sig,
    );
  }

  /// Parst tags aus der Erweiterungs-Antwort; bei kaputtem Format Fallback.
  static List<List<String>> _tagsFromSigned(
    dynamic raw,
    List<List<String>> fallback,
  ) {
    if (raw is! List) return fallback;
    try {
      final out = <List<String>>[];
      for (final tag in raw) {
        if (tag is! List) return fallback;
        out.add([for (final e in tag) e.toString()]);
      }
      return out;
    } catch (_) {
      return fallback;
    }
  }
}

/// Ergebnis des NIP-07-Verbindungsversuchs.
sealed class Nip07ConnectResult {
  const Nip07ConnectResult();
}

class Nip07ConnectSuccess extends Nip07ConnectResult {
  final String pubkeyHex;
  final String npub;
  const Nip07ConnectSuccess({required this.pubkeyHex, required this.npub});
}

/// Keine Erweiterung im Browser (oder gar kein Browser).
class Nip07ConnectMissing extends Nip07ConnectResult {
  const Nip07ConnectMissing();
}

/// Nutzer hat in der Erweiterung abgelehnt — kein Fehler.
class Nip07ConnectRejected extends Nip07ConnectResult {
  const Nip07ConnectRejected();
}

class Nip07ConnectError extends Nip07ConnectResult {
  final String message;
  const Nip07ConnectError(this.message);
}

// =============================================
// SIGNING SERVICE — die Fassade für die ganze App
// =============================================

class SigningService {
  static const String _modeKey = 'signing_mode';
  static const String _amberPubkeyHexKey = 'amber_pubkey_hex';
  static const String _amberNpubKey = 'amber_npub';
  static const String _nip07PubkeyHexKey = 'nip07_pubkey_hex';
  static const String _nip07NpubKey = 'nip07_npub';

  // =============================================
  // MODUS
  // =============================================

  static Future<SigningMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    // default deckt null UND unbekannte Altwerte ab — bestehende
    // Installationen haben 'amber' oder 'local' gespeichert und bleiben
    // dadurch unveraendert.
    return switch (prefs.getString(_modeKey)) {
      'amber' => SigningMode.amber,
      'nip07' => SigningMode.nip07,
      _ => SigningMode.local,
    };
  }

  static Future<void> _setMode(SigningMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, switch (mode) {
      SigningMode.amber => 'amber',
      SigningMode.nip07 => 'nip07',
      SigningMode.local => 'local',
    });
  }

  static Future<bool> get isAmber async =>
      (await getMode()) == SigningMode.amber;

  static Future<bool> get isNip07 async =>
      (await getMode()) == SigningMode.nip07;

  /// Signiert ein EXTERNER Signer (Amber oder Browsererweiterung)?
  ///
  /// Fuer alles, wo es nur darauf ankommt, dass die App den privaten
  /// Schluessel NICHT besitzt: kein nsec im Backup, npub vom Service statt
  /// aus dem Keystore, und kein stilles Signieren beim App-Start — jede
  /// Signatur loest bei beiden ein Popup aus.
  static Future<bool> get isExternalSigner async {
    final mode = await getMode();
    return mode == SigningMode.amber || mode == SigningMode.nip07;
  }

  // =============================================
  // AKTIVEN SIGNER AUFLÖSEN
  // =============================================

  static Future<NostrSigner> _resolveSigner() async {
    switch (await getMode()) {
      case SigningMode.amber:
        final prefs = await SharedPreferences.getInstance();
        final hex = prefs.getString(_amberPubkeyHexKey);
        if (hex == null || hex.isEmpty) {
          throw const SigningException(
              'Amber-Modus aktiv, aber kein verbundener Schlüssel. '
              'Bitte Amber erneut verbinden.');
        }
        return AmberNostrSigner(expectedPubkeyHex: hex);
      case SigningMode.nip07:
        final prefs = await SharedPreferences.getInstance();
        final hex = prefs.getString(_nip07PubkeyHexKey);
        if (hex == null || hex.isEmpty) {
          throw const SigningException(
              'Erweiterungs-Modus aktiv, aber kein verbundener Schlüssel. '
              'Bitte die Browsererweiterung erneut verbinden.');
        }
        return Nip07NostrSigner(expectedPubkeyHex: hex);
      case SigningMode.local:
        return LocalNostrSigner();
    }
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

  /// npub der aktiven Identität — Amber-npub, Erweiterungs-npub oder
  /// lokaler npub.
  static Future<String?> npub() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (await getMode()) {
      SigningMode.amber => prefs.getString(_amberNpubKey),
      SigningMode.nip07 => prefs.getString(_nip07NpubKey),
      SigningMode.local => SecureKeyStore.getNpub(),
    };
  }

  /// Kann die App aktuell überhaupt signieren?
  static Future<bool> canSign() async {
    final prefs = await SharedPreferences.getInstance();
    switch (await getMode()) {
      case SigningMode.amber:
        final hex = prefs.getString(_amberPubkeyHexKey);
        return hex != null && hex.isNotEmpty;
      case SigningMode.nip07:
        final hex = prefs.getString(_nip07PubkeyHexKey);
        // Zusaetzlich pruefen, ob die Erweiterung ueberhaupt noch da ist:
        // sie kann seit dem Verbinden deinstalliert oder deaktiviert worden
        // sein, und ein gemerkter pubkey allein hilft dann nicht.
        if (hex == null || hex.isEmpty) return false;
        return nip07Available();
      case SigningMode.local:
        final priv = await SecureKeyStore.getPrivHex();
        return priv != null && priv.isNotEmpty;
    }
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

  // =============================================
  // BROWSERERWEITERUNG (NIP-07) VERBINDEN / TRENNEN
  // =============================================

  /// Ist eine NIP-07-Erweiterung vorhanden? Ausserhalb des Browsers false.
  static Future<bool> nip07ExtensionAvailable() =>
      Nip07NostrSigner.isAvailable();

  /// Startet den Verbindungs-Flow mit der Browsererweiterung und
  /// persistiert pubkey + Modus bei Erfolg.
  ///
  /// Ein vorhandener lokaler nsec wird BEWUSST NICHT gelöscht.
  ///
  /// Hier stand kurzzeitig ein `SecureKeyStore.deleteKeys()`, um den
  /// gemischten Zustand "lokaler Schlüssel plus Erweiterungs-Modus" zu
  /// vermeiden. Das war ein Datenverlust-Pfad: ein Tipp auf "Mit
  /// Browsererweiterung verbinden" plus Freigabe in der Erweiterung hätte den
  /// nsec unwiderruflich gelöscht — ohne Warnung, ohne Rückfrage, und wer
  /// kein Backup hatte, wäre seine Identität für immer los gewesen.
  /// connectAmber() löscht ebenfalls nicht, die beiden Knöpfe nebeneinander
  /// hätten sich also grundlegend verschieden verhalten.
  ///
  /// Der gemischte Zustand ist stattdessen dort entschärft, wo er wehtat: das
  /// Backup sichert Schlüssel nach ihrer tatsächlichen EXISTENZ statt nach dem
  /// Modus (siehe backup_service). Damit geht nichts verloren, egal in welcher
  /// Reihenfolge jemand Schlüssel anlegt und Signer verbindet.
  static Future<Nip07ConnectResult> connectNip07() async {
    final result = await Nip07NostrSigner.connect();
    if (result is Nip07ConnectSuccess) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nip07PubkeyHexKey, result.pubkeyHex);
      await prefs.setString(_nip07NpubKey, result.npub);
      await _setMode(SigningMode.nip07);
      AppLogger.security('SigningService',
          'Browsererweiterung verbunden: ${_short(result.npub)} — '
          'der Schlüssel bleibt in der Erweiterung.');
    }
    return result;
  }

  /// Stellt den Erweiterungs-Modus aus einem Backup wieder her.
  /// Im Backup liegt nur der npub — der Schlüssel bleibt in der Erweiterung.
  static Future<void> restoreNip07(String npub) async {
    final hex = Nip19.decodePubkey(npub.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nip07PubkeyHexKey, hex);
    await prefs.setString(_nip07NpubKey, npub.trim());
    await _setMode(SigningMode.nip07);
  }

  /// Trennt die Erweiterung und löscht den gemerkten pubkey.
  static Future<void> disconnectNip07() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nip07PubkeyHexKey);
    await prefs.remove(_nip07NpubKey);
    await _setMode(SigningMode.local);
  }

  static String _short(String npub) =>
      npub.length < 16 ? npub : '${npub.substring(0, 12)}…${npub.substring(npub.length - 4)}';
}
