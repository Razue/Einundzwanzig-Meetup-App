// ============================================
// BADGE MODEL v4 — MIT CLAIM-BINDING
// ============================================
// Jedes Badge hat jetzt ZWEI Signaturen:
//   1. Organisator-Signatur → "Dieses Meetup fand statt"
//   2. Claim-Signatur (NEU) → "Ich war dabei"
//
// Ohne Claim-Signatur zählt ein Badge NICHT
// für die Reputation. Die Claim-Signatur bindet
// das Badge kryptographisch an den Sammler.
//
// Die Kette:
//   Organisator signiert Tag → Schnorr-Signatur (unfälschbar)
//   Teilnehmer scannt Tag → Claim-Signatur (bindet an Sammler)
//   Reputation → Nur gebundene Badges zählen
//   Verifizierer prüft → Beide Signaturen + Proof-Hash
// ============================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../services/app_logger.dart';

class MeetupBadge {
  final String id;
  final String meetupName;
  final DateTime date;
  final String iconPath;
  final String coverUrl;
  final int blockHeight;
  final String signerNpub;      // Wer hat den Tag erstellt? (npub1...)
  final String meetupEventId;   // Eindeutige Event-ID (meetup-datum)
  final String delivery;        // 'nfc' oder 'rolling_qr'

  // =============================================
  // KRYPTOGRAPHISCHER BEWEIS (Organisator)
  // =============================================
  final String sig;             // Schnorr-Signatur des Organisators (128 hex chars)
  final String sigId;           // Nostr Event-ID (SHA-256 Hash, 64 hex chars)
  final String adminPubkey;     // Hex-Pubkey des Organisators (64 hex chars)
  final int sigVersion;         // 1 = Legacy (HMAC), 2 = Nostr (Schnorr)
  final String sigContent;      // Der signierte Content (für Re-Verifikation)

  // =============================================
  // CLAIM-BINDING (NEU in v4)
  // Bindet das Badge kryptographisch an den Sammler.
  // Ohne Claim → Badge zählt nicht für Reputation.
  // =============================================
  final String claimSig;        // Schnorr-Signatur des Sammlers
  final String claimEventId;    // Nostr Event-ID des Claim-Events
  final String claimPubkey;     // Hex-Pubkey des Sammlers
  final int claimTimestamp;     // Unix-Timestamp des Claims
  final bool isRetroactive;     // true = nachträglich geclaimed (reduzierter Vertrauenswert)
  final bool isOrganizer;       // true = Organisator-Marker-Badge (zählt NICHT zum Trust Score)
  /// PRAESENZ-PRUEFUNG beim Sammeln:
  /// true  = Standort war ermittelbar und lag im erlaubten Umkreis
  /// false = Standort war NICHT ermittelbar (z.B. Geraet ohne
  ///         Netzwerkortung, drinnen kein Satellitenfix). Das Badge ist
  ///         gueltig, sein Praesenz-Nachweis aber ungeprueft.
  /// Aeltere Badges (vor dieser Version) gelten als geprueft, weil damals
  /// ohne Standort gar kein Badge vergeben wurde.
  final bool presenceVerified;
  /// EVENT-BADGE statt Meetup-Badge.
  ///
  /// Wirkt an zwei Stellen unterschiedlich, und das ist Absicht:
  ///   - Trust Score: zaehlt als Badge und fuer die Vielfalt der Aussteller,
  ///     aber NICHT als besuchtes Meetup. Drei Grossevents duerfen nicht
  ///     dieselbe Aussage tragen wie drei lokale Meetups.
  ///   - Vertrauensnetzwerk: eigene Kategorie. Auf einem Event mit 500
  ///     Leuten hat man sich eben NICHT alle getroffen.
  final bool isEvent;

  final double lat;             // GPS-Breitengrad des Erstellungsorts (0 = unbekannt)
  final double lng;             // GPS-Längengrad des Erstellungsorts (0 = unbekannt)

  MeetupBadge({
    required this.id,
    required this.meetupName,
    required this.date,
    required this.iconPath,
    this.coverUrl = '',
    this.blockHeight = 0,
    this.signerNpub = '',
    this.meetupEventId = '',
    this.delivery = 'nfc',
    // Organisator-Beweis
    this.sig = '',
    this.sigId = '',
    this.adminPubkey = '',
    this.sigVersion = 0,
    this.sigContent = '',
    // Claim-Binding
    this.claimSig = '',
    this.claimEventId = '',
    this.claimPubkey = '',
    this.claimTimestamp = 0,
    this.isRetroactive = false,
    this.presenceVerified = true,
    this.isOrganizer = false,
    this.isEvent = false,
    this.lat = 0,
    this.lng = 0,
  });

  /// Hat dieses Badge einen kryptographischen Beweis (Organisator)?
  bool get hasCryptoProof => sig.isNotEmpty && sigVersion > 0;

  /// Ist dieses Badge Nostr-signiert (v2)?
  bool get isNostrSigned {
  final hex128 = RegExp(r'^[0-9a-fA-F]{128}$');
  final hex64 = RegExp(r'^[0-9a-fA-F]{64}$');

  if (sigVersion != 2) return false;

  if (!hex128.hasMatch(sig)) return false;
  if (!hex64.hasMatch(adminPubkey)) return false;

  // zusätzliche Sicherheitsprüfung:
  // keine reine Null- oder Dummy-Signatur akzeptieren
  if (BigInt.parse(sig, radix: 16) == BigInt.zero) return false;

  return true;
}

  /// Hat dieses Badge ein Claim-Binding?
  bool get isClaimed => claimSig.isNotEmpty && claimPubkey.isNotEmpty;

  /// Vollständig verifizierbar: Organisator-Signatur UND Claim-Binding
  bool get isFullyBound => hasCryptoProof && isClaimed;

  /// Badge-ID für den Proof-Hash (eindeutig pro Badge)
  String get proofId {
    if (sigId.isNotEmpty) return sigId;
    if (sig.isNotEmpty) return sig.substring(0, 64);
    // Fallback: Hash über Badge-Daten
    final data = '$id-$meetupName-${date.toIso8601String()}-$blockHeight';
    return sha256.convert(utf8.encode(data)).toString().substring(0, 64);
  }

  /// Claim-Proof-ID: Kombination aus Organisator-Sig + Claim-Sig + Claim-Pubkey
  /// Für den datenschutzkonformen badge_proof_hash
  String get claimProofId {
    if (!isClaimed) return '';
    final data = '$sig|$claimSig|$claimPubkey';
    return sha256.convert(utf8.encode(data)).toString();
  }

  // =============================================
  // SERIALISIERUNG
  // =============================================

  /// EINDEUTIGKEIT eines Badges — zentraler Schluessel fuer Duplikat-Erkennung.
  ///
  /// Wird an ZWEI Stellen gebraucht und muss dort identisch sein:
  ///  1. beim Hinzufuegen zur Wallet (verhindert Mehrfach-Sammeln),
  ///  2. im Trust Score (Duplikate duerfen die Reputation nicht erhoehen).
  ///
  /// Reihenfolge bewusst: meetupEventId (= Meetup + Datum) ist die fachliche
  /// Identitaet einer Veranstaltung und ueberlebt auch rotierende QR-Codes,
  /// bei denen sich die Signatur-ID zwischen zwei Scans aendert.
  static String identityKey(MeetupBadge b) {
    if (b.meetupEventId.isNotEmpty) return 'evt:${b.meetupEventId}';
    if (b.sigId.isNotEmpty) return 'sig:${b.sigId}';
    // Fallback fuer alte/unsignierte Badges: Meetup + Kalendertag.
    final d = b.date;
    final day = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return 'nd:${b.meetupName.trim().toLowerCase()}|$day';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meetupName': meetupName,
      'date': date.toIso8601String(),
      'iconPath': iconPath,
      'coverUrl': coverUrl,
      'blockHeight': blockHeight,
      'signerNpub': signerNpub,
      'meetupEventId': meetupEventId,
      'delivery': delivery,
      // Organisator-Beweis
      'sig': sig,
      'sigId': sigId,
      'adminPubkey': adminPubkey,
      'sigVersion': sigVersion,
      'sigContent': sigContent,
      // Claim-Binding
      'claimSig': claimSig,
      'claimEventId': claimEventId,
      'claimPubkey': claimPubkey,
      'claimTimestamp': claimTimestamp,
      'isRetroactive': isRetroactive,
      'presenceVerified': presenceVerified,
      'isOrganizer': isOrganizer,
      'isEvent': isEvent,
      'lat': lat,
      'lng': lng,
    };
  }

  factory MeetupBadge.fromJson(Map<String, dynamic> json) {
    return MeetupBadge(
      id: json['id'] as String,
      meetupName: json['meetupName'] as String,
      date: DateTime.parse(json['date'] as String),
      iconPath: json['iconPath'] as String,
      coverUrl: json['coverUrl'] as String? ?? '',
      blockHeight: json['blockHeight'] as int? ?? 0,
      signerNpub: json['signerNpub'] as String? ?? '',
      meetupEventId: json['meetupEventId'] as String? ?? '',
      delivery: json['delivery'] as String? ?? 'nfc',
      // Organisator-Beweis (backward-compatible)
      sig: json['sig'] as String? ?? '',
      sigId: json['sigId'] as String? ?? '',
      adminPubkey: json['adminPubkey'] as String? ?? '',
      sigVersion: json['sigVersion'] as int? ?? 0,
      sigContent: json['sigContent'] as String? ?? '',
      // Claim-Binding (backward-compatible: alte Badges ohne Claim laden auch)
      claimSig: json['claimSig'] as String? ?? '',
      claimEventId: json['claimEventId'] as String? ?? '',
      claimPubkey: json['claimPubkey'] as String? ?? '',
      claimTimestamp: json['claimTimestamp'] as int? ?? 0,
      isRetroactive: json['isRetroactive'] as bool? ?? false,
      presenceVerified: json['presenceVerified'] as bool? ?? true,
      isOrganizer: json['isOrganizer'] as bool? ?? false,
      isEvent: json['isEvent'] as bool? ?? false,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Erstellt eine Kopie des Badges MIT Claim-Daten
  MeetupBadge withClaim({
    required String claimSig,
    required String claimEventId,
    required String claimPubkey,
    required int claimTimestamp,
    bool isRetroactive = false,
    bool? isOrganizer,
    double? lat,
    double? lng,
    bool presenceVerified = true,
  }) {
    return MeetupBadge(
      id: id,
      meetupName: meetupName,
      date: date,
      iconPath: iconPath,
      coverUrl: coverUrl,
      blockHeight: blockHeight,
      signerNpub: signerNpub,
      meetupEventId: meetupEventId,
      delivery: delivery,
      sig: sig,
      sigId: sigId,
      adminPubkey: adminPubkey,
      sigVersion: sigVersion,
      sigContent: sigContent,
      // Claim-Daten
      claimSig: claimSig,
      claimEventId: claimEventId,
      claimPubkey: claimPubkey,
      claimTimestamp: claimTimestamp,
      isRetroactive: isRetroactive,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      isEvent: isEvent,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      presenceVerified: presenceVerified,
    );
  }

  /// Vollständige Kopie mit optionalen Überschreibungen.
  /// Erhält ALLE Felder (inkl. aller Signatur-/Claim-Daten) unverändert,
  /// sofern nicht explizit überschrieben. Wichtig: sig, sigId, adminPubkey,
  /// sigVersion, sigContent, claimSig etc. bleiben kryptografisch intakt.
  MeetupBadge copyWith({
    String? id,
    String? meetupName,
    DateTime? date,
    String? iconPath,
    String? coverUrl,
    int? blockHeight,
    String? signerNpub,
    String? meetupEventId,
    String? delivery,
    String? sig,
    String? sigId,
    String? adminPubkey,
    int? sigVersion,
    String? sigContent,
    String? claimSig,
    String? claimEventId,
    String? claimPubkey,
    int? claimTimestamp,
    bool? isRetroactive,
    bool? presenceVerified,
    bool? isOrganizer,
    double? lat,
    double? lng,
  }) {
    return MeetupBadge(
      id: id ?? this.id,
      meetupName: meetupName ?? this.meetupName,
      date: date ?? this.date,
      iconPath: iconPath ?? this.iconPath,
      coverUrl: coverUrl ?? this.coverUrl,
      blockHeight: blockHeight ?? this.blockHeight,
      signerNpub: signerNpub ?? this.signerNpub,
      meetupEventId: meetupEventId ?? this.meetupEventId,
      delivery: delivery ?? this.delivery,
      sig: sig ?? this.sig,
      sigId: sigId ?? this.sigId,
      adminPubkey: adminPubkey ?? this.adminPubkey,
      sigVersion: sigVersion ?? this.sigVersion,
      sigContent: sigContent ?? this.sigContent,
      claimSig: claimSig ?? this.claimSig,
      claimEventId: claimEventId ?? this.claimEventId,
      claimPubkey: claimPubkey ?? this.claimPubkey,
      claimTimestamp: claimTimestamp ?? this.claimTimestamp,
      isRetroactive: isRetroactive ?? this.isRetroactive,
      presenceVerified: presenceVerified ?? this.presenceVerified,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      isEvent: isEvent,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  // =============================================
  // PERSISTENZ — Verschlüsselt (Security Audit M7)
  // =============================================
  // Badge-Daten werden mit AES-256-GCM verschlüsselt,
  // bevor sie in SharedPreferences geschrieben werden.
  // Der Schlüssel liegt in flutter_secure_storage
  // (Android Keystore / iOS Keychain geschützt).
  //
  // Migration: Beim ersten Laden werden unverschlüsselte
  // Legacy-Badges automatisch verschlüsselt gespeichert.
  // =============================================

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: false,
      migrateOnAlgorithmChange: true,
      migrateWithBackup: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const String _badgeKeyAlias = 'badge_encryption_key';
  static const String _prefsBadgeEncrypted = 'badges_encrypted';
  static const String _prefsLegacyBadges = 'badges'; // Altes Klartext-Feld
  /// Erste Fassung der verschlüsselten Datei. Wird nicht überschrieben,
  /// damit ein fehlgeschlagenes Update die Sammlung nicht auslöscht.
  static const String _prefsBadgePreserved = 'badges_encrypted_preserved';
  /// Scans, die ankamen, während die alte Datei nicht lesbar war. Sie liegen
  /// verschlüsselt mit einem eigenen Schlüssel, weil der Badge-Schlüssel in
  /// dem Moment gerade fehlt oder nicht lesbar ist.
  static const String _prefsBadgePending = 'badges_pending_encrypted';
  static const String _pendingKeyAlias = 'badge_pending_key';
  /// Klartext-Vormerkung aus Testbuilds von PR 84. Wird gelesen und beim
  /// nächsten Schreiben verschlüsselt übernommen.
  static const String _prefsLegacyPending = 'badges_pending';

  /// Eine Badge-Datei liegt da, lässt sich aber nicht öffnen. Die leere
  /// Liste aus [loadBadges] ist dann kein leerer Bestand.
  static bool badgesUnreadable = false;

  static final RegExp _hex64 = RegExp(r'^[0-9a-fA-F]{64}$');

  static enc.Key? _keyFromHex(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (!_hex64.hasMatch(trimmed)) return null;
    return enc.Key(Uint8List.fromList(List.generate(
        32, (i) => int.parse(trimmed.substring(i * 2, i * 2 + 2), radix: 16))));
  }

  static String _hexFromKey(enc.Key key) =>
      key.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Liest den Schlüssel. Ein neuer entsteht nur mit [create], und nur wenn
  /// unter dem Namen noch nichts liegt. Ein Lese-Fehler oder ein Wert mit
  /// der falschen Länge überschreibt den alten Eintrag nicht.
  static Future<enc.Key?> _getBadgeKey({required bool create}) async {
    String? existing;
    try {
      existing = await _secureStorage.read(key: _badgeKeyAlias);
    } catch (e) {
      AppLogger.warn('Badge', 'Badge-Schlüssel nicht lesbar: $e');
      return null;
    }
    final parsed = _keyFromHex(existing);
    if (parsed != null) return parsed;
    if (existing != null && existing.trim().isNotEmpty) {
      AppLogger.warn('Badge',
          'Badge-Schlüssel hat unerwartetes Format (${existing.trim().length} Zeichen), er bleibt liegen');
      return null;
    }
    if (!create) return null;
    final key = enc.Key.fromSecureRandom(32);
    try {
      await _secureStorage.write(key: _badgeKeyAlias, value: _hexFromKey(key));
    } catch (e) {
      AppLogger.warn('Badge', 'Neuer Badge-Schlüssel nicht schreibbar: $e');
      return null;
    }
    AppLogger.debug('Badge', 'Neuer Badge-Encryption-Key generiert');
    return key;
  }

  static Future<void> _rememberKey(enc.Key key) async {
    final hex = _hexFromKey(key);
    try {
      final current = await _secureStorage.read(key: _badgeKeyAlias);
      if (current?.trim().toLowerCase() == hex) return;
      await _secureStorage.write(key: _badgeKeyAlias, value: hex);
    } catch (e) {
      AppLogger.warn('Badge', 'Funktionierender Schlüssel nicht zurückgeschrieben: $e');
    }
  }

  /// Weitere 32-Byte-Werte im sicheren Speicher, inklusive der
  /// Migrationskopie mit dem Suffix `_BACKUP`.
  static Future<List<enc.Key>> _candidateKeys(enc.Key? primary) async {
    final out = <enc.Key>[];
    final seen = <String>{};
    void add(String? raw) {
      final key = _keyFromHex(raw);
      if (key == null) return;
      if (!seen.add(_hexFromKey(key))) return;
      out.add(key);
    }

    if (primary != null) add(_hexFromKey(primary));
    try {
      add(await _secureStorage.read(key: '${_badgeKeyAlias}_BACKUP'));
    } catch (_) {}
    try {
      final all = await _secureStorage.readAll();
      for (final value in all.values) {
        add(value);
      }
    } catch (e) {
      AppLogger.debug('Badge', 'Schlüsselsuche unvollständig: $e');
    }
    return out;
  }

  static List<MeetupBadge>? _decryptBlob(String blob, enc.Key key) {
    try {
      final parts = blob.split(':');
      if (parts.length != 2) return null;
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final decrypted = encrypter.decrypt64(parts[1], iv: iv);
      final decoded = jsonDecode(decrypted) as List<dynamic>;
      return decoded
          .map((json) => MeetupBadge.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<({List<MeetupBadge> badges, String blob, enc.Key key})?> _openFirst(
    List<String> blobs,
  ) async {
    final primary = await _getBadgeKey(create: false);
    if (primary != null) {
      for (final blob in blobs) {
        final badges = _decryptBlob(blob, primary);
        if (badges != null) {
          return (badges: badges, blob: blob, key: primary);
        }
      }
    }
    // Der eingetragene Schlüssel öffnet die Datei nicht. Andere Werte im
    // Speicher können der alte Schlüssel sein, den ein Update beiseite
    // geschoben hat.
    final keys = await _candidateKeys(primary);
    for (final key in keys) {
      for (final blob in blobs) {
        final badges = _decryptBlob(blob, key);
        if (badges != null) {
          return (badges: badges, blob: blob, key: key);
        }
      }
    }
    return null;
  }

  static Future<void> _stashBlob(SharedPreferences prefs, String blob) async {
    final preserved = prefs.getString(_prefsBadgePreserved);
    if (preserved != null && preserved.isNotEmpty) return;
    await prefs.setString(_prefsBadgePreserved, blob);
  }

  /// Eigener Schlüssel für vorgemerkte Scans, unabhängig vom Badge-Schlüssel.
  /// Er wird zusammen mit der Vormerkung wieder gelöscht.
  static Future<enc.Key?> _getPendingKey({required bool create}) async {
    try {
      final parsed = _keyFromHex(await _secureStorage.read(key: _pendingKeyAlias));
      if (parsed != null || !create) return parsed;
      final key = enc.Key.fromSecureRandom(32);
      await _secureStorage.write(key: _pendingKeyAlias, value: _hexFromKey(key));
      return key;
    } catch (e) {
      AppLogger.warn('Badge', 'Schlüssel für vorgemerkte Badges nicht verfügbar: $e');
      return null;
    }
  }

  static String _encryptBlob(List<MeetupBadge> badges, enc.Key key) {
    final iv = enc.IV.fromSecureRandom(12);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(
        jsonEncode(badges.map((b) => b.toJson()).toList()),
        iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// null: eine Vormerkung liegt da, lässt sich aber gerade nicht öffnen.
  /// Sie darf dann weder überschrieben noch abgeräumt werden.
  static Future<List<MeetupBadge>?> _readPending() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <MeetupBadge>[];
    final blob = prefs.getString(_prefsBadgePending);
    if (blob != null && blob.isNotEmpty) {
      final key = await _getPendingKey(create: false);
      final badges = key == null ? null : _decryptBlob(blob, key);
      if (badges == null) {
        AppLogger.warn('Badge', 'Vorgemerkte Badges gerade nicht lesbar');
        return null;
      }
      out.addAll(badges);
    }
    for (final item in prefs.getStringList(_prefsLegacyPending) ?? const <String>[]) {
      try {
        out.add(MeetupBadge.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {}
    }
    return out;
  }

  /// false: nichts geschrieben, Klartext gibt es als Ausweg nicht.
  static Future<bool> _writePending(List<MeetupBadge> badges) async {
    final prefs = await SharedPreferences.getInstance();
    if (badges.isEmpty) {
      await prefs.remove(_prefsLegacyPending);
      if (!prefs.containsKey(_prefsBadgePending)) return true;
      await prefs.remove(_prefsBadgePending);
      try {
        await _secureStorage.delete(key: _pendingKeyAlias);
      } catch (_) {}
      return true;
    }
    final key = await _getPendingKey(create: true);
    if (key == null) return false;
    try {
      await prefs.setString(_prefsBadgePending, _encryptBlob(badges, key));
    } catch (e) {
      AppLogger.warn('Badge', 'Vormerkung nicht verschlüsselbar: $e');
      return false;
    }
    await prefs.remove(_prefsLegacyPending);
    return true;
  }

  static List<MeetupBadge> _unionById(List<MeetupBadge> base, List<MeetupBadge> extra) {
    final out = List<MeetupBadge>.from(base);
    final ids = base.map((b) => b.id).toSet();
    for (final badge in extra) {
      if (ids.add(badge.id)) out.add(badge);
    }
    return out;
  }

  /// Scan, während die alte Sammlung nicht lesbar ist. Das Badge bleibt
  /// daneben liegen und kommt beim nächsten erfolgreichen Lesen dazu.
  static Future<void> keepAside(MeetupBadge badge) async {
    final pending = await _readPending();
    if (pending == null) {
      AppLogger.error('Badge', 'Badge nicht vorgemerkt, Vormerkung nicht lesbar');
      return;
    }
    if (pending.any((b) => b.id == badge.id)) return;
    pending.add(badge);
    if (!await _writePending(pending)) {
      AppLogger.error('Badge', 'Badge nicht vorgemerkt, kein Schlüssel verfügbar');
      return;
    }
    AppLogger.warn('Badge', 'Badge vorgemerkt, Sammlung ist gerade nicht lesbar');
  }

  static Future<List<MeetupBadge>> _finishReadable(List<MeetupBadge> badges) async {
    badgesUnreadable = false;
    final pending = await _readPending();
    if (pending == null || pending.isEmpty) return badges;
    final merged = _unionById(badges, pending);
    // saveBadges nimmt die Vormerkung mit und räumt sie samt Schlüssel erst
    // nach dem Schreiben ab. Schlägt es fehl, bleibt sie unverändert liegen.
    final wrote = await saveBadges(merged);
    return wrote ? merged : badges;
  }

  /// Wird vom BadgeSyncService gesetzt, damit saveBadges den Sync auslöst.
  /// Ohne den Haken müsste badge.dart den Dienst kennen — das wäre eine
  /// Kreis-Abhängigkeit, weil der Dienst selbst MeetupBadge lädt.
  static void Function()? onBadgesSaved;

  /// [replaceUnreadable]: eine nicht leere Liste darf die nicht lesbare
  /// Datei ersetzen. Die bisherige Datei bleibt als Sicherung liegen.
  /// [discardLocked]: explizites Zurücksetzen, räumt auch die Sicherung ab.
  static Future<bool> saveBadges(
    List<MeetupBadge> badges, {
    bool replaceUnreadable = false,
    bool discardLocked = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (badges.isEmpty) {
      // Leere Liste ist der Reset. Solange die Datei nicht lesbar ist,
      // löscht nur der ausdrückliche Reset sie.
      if (badgesUnreadable && !discardLocked) return false;
      await prefs.remove(_prefsBadgeEncrypted);
      await prefs.remove(_prefsBadgePreserved);
      await prefs.remove(_prefsLegacyBadges);
      await _writePending([]);
      badgesUnreadable = false;
      onBadgesSaved?.call();
      return true;
    }

    if (badgesUnreadable && !replaceUnreadable) return false;

    final currentBlob = prefs.getString(_prefsBadgeEncrypted);
    final hasBlob = currentBlob != null && currentBlob.contains(':');
    if (replaceUnreadable && hasBlob) {
      await _stashBlob(prefs, currentBlob);
    }

    // Fehlt der Schlüssel, entsteht ein neuer nur ohne vorhandene Datei
    // oder beim bewussten Ersetzen. Sonst bliebe die Datei für immer zu.
    final key = await _getBadgeKey(create: !hasBlob || replaceUnreadable);
    if (key == null) {
      AppLogger.warn('Badge', 'Speichern ausgesetzt, Schlüssel nicht verfügbar');
      return false;
    }

    final pending = await _readPending();
    final toStore = _unionById(badges, pending ?? const []);
    final jsonStr = jsonEncode(toStore.map((b) => b.toJson()).toList());

    try {
      final iv = enc.IV.fromSecureRandom(12); // 96 Bit (NIST-empfohlen)
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encrypt(jsonStr, iv: iv);

      // Format: base64(IV):base64(ciphertext)
      final stored = '${iv.base64}:${encrypted.base64}';
      await prefs.setString(_prefsBadgeEncrypted, stored);

      if (prefs.containsKey(_prefsLegacyBadges)) {
        await prefs.remove(_prefsLegacyBadges);
        AppLogger.debug('Badge', 'Legacy-Klartextbadges aus SharedPrefs entfernt');
      }
    } catch (e) {
      AppLogger.error('Badge', 'Verschlüsselung fehlgeschlagen, Klartext-Fallback: $e');
      // Neben einer vorhandenen Datei keinen zweiten Bestand anlegen.
      if (hasBlob) return false;
      final badgesJson = toStore.map((b) => jsonEncode(b.toJson())).toList();
      await prefs.setStringList(_prefsLegacyBadges, badgesJson);
    }

    // Eine Vormerkung, die gerade nicht aufging, bleibt für später liegen.
    if (pending != null) await _writePending([]);
    badgesUnreadable = false;
    onBadgesSaved?.call();
    return true;
  }

  static Future<List<MeetupBadge>> loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final blob = prefs.getString(_prefsBadgeEncrypted);
    final preserved = prefs.getString(_prefsBadgePreserved);
    final blobs = <String>[];
    if (blob != null && blob.contains(':')) blobs.add(blob);
    if (preserved != null && preserved.contains(':') && preserved != blob) {
      blobs.add(preserved);
    }

    if (blobs.isNotEmpty) {
      final opened = await _openFirst(blobs);
      if (opened != null) {
        if (blob != opened.blob) {
          await prefs.setString(_prefsBadgeEncrypted, opened.blob);
        }
        await _rememberKey(opened.key);
        return _finishReadable(opened.badges);
      }
      final toKeep = (blob != null && blob.contains(':')) ? blob : preserved!;
      await _stashBlob(prefs, toKeep);
      badgesUnreadable = true;
      AppLogger.warn('Badge',
          'Badge-Datei nicht entschlüsselbar, sie bleibt unverändert liegen');
      return [];
    }

    // Klartext nur, wenn noch gar keine verschlüsselte Datei existiert.
    final List<String>? legacyJson = prefs.getStringList(_prefsLegacyBadges);
    if (legacyJson != null && legacyJson.isNotEmpty) {
      AppLogger.debug('Badge', 'Migriere ${legacyJson.length} Badges von Klartext zu verschlüsselt');
      final badges = <MeetupBadge>[];
      for (final item in legacyJson) {
        try {
          badges.add(MeetupBadge.fromJson(jsonDecode(item) as Map<String, dynamic>));
        } catch (_) {}
      }
      if (badges.isNotEmpty) {
        badgesUnreadable = false;
        final wrote = await saveBadges(badges);
        if (wrote) return badges;
      }
    }

    badgesUnreadable = false;
    return [];
  }

  // =============================================
  // BADGE PROOF v2: Datenschutzkonform
  // =============================================
  // Erzeugt einen Hash der beweist:
  // "Genau DIESE Badges mit genau DIESEN Claims
  //  wurden für die Reputation verwendet."
  //
  // Verrät NICHT welche Meetups oder Orte.
  // =============================================

  /// Badge-Proof-Hash über ALLE gebundenen Badges (datenschutzkonform)
  /// Nur Badges mit Claim-Binding werden einbezogen.
  static String generateBadgeProofV2(List<MeetupBadge> badges) {
    // Nur gebundene Badges zählen
    final bound = badges.where((b) => b.isFullyBound).toList();
    if (bound.isEmpty) return '';
    
    // Sortieren nach Claim-Timestamp (deterministisch)
    bound.sort((a, b) => a.claimTimestamp.compareTo(b.claimTimestamp));
    
    // Claim-Proof-IDs verketten
    final proofChain = bound.map((b) => b.claimProofId).join('|');
    
    // SHA-256 über die gesamte Kette
    return sha256.convert(utf8.encode(proofChain)).toString();
  }

  /// Legacy Badge-Proof (v1) für Rückwärtskompatibilität
  static String generateBadgeProof(List<MeetupBadge> badges) {
    if (badges.isEmpty) return '';
    
    final sorted = List<MeetupBadge>.from(badges)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final proofChain = sorted.map((b) => b.proofId).join('|');
    return sha256.convert(utf8.encode(proofChain)).toString();
  }

  /// Prüft ob ein Badge-Proof zu einer Badge-Liste passt
  static bool verifyBadgeProof(List<MeetupBadge> badges, String expectedProof) {
    final actualProof = generateBadgeProof(badges);
    return actualProof == expectedProof;
  }

  /// Badge-Statistiken für Reputation
  static Map<String, int> getReputationStats(List<MeetupBadge> badges) {
    final bound = badges.where((b) => b.isFullyBound).toList();
    final retroactive = bound.where((b) => b.isRetroactive).length;
    return {
      'total': badges.length,
      'crypto_proof': badges.where((b) => b.hasCryptoProof).length,
      'claimed': bound.length,
      'retroactive': retroactive,
      'fully_trusted': bound.length - retroactive,
    };
  }

  /// Wie viele Badges haben einen echten kryptographischen Beweis?
  static int countVerifiedBadges(List<MeetupBadge> badges) {
    return badges.where((b) => b.hasCryptoProof).length;
  }

  /// Wie viele Badges sind vollständig gebunden?
  static int countBoundBadges(List<MeetupBadge> badges) {
    return badges.where((b) => b.isFullyBound).length;
  }

  // Badge-Reputation-String für Sharing
  String toReputationString() {
    return 'Badge #$id\n'
           'Meetup: $meetupName\n'
           'Datum: ${date.day}.${date.month}.${date.year}\n'
           'Block: $blockHeight\n'
           '${isNostrSigned ? "🔐 Nostr-verifiziert" : "Verifiziert"} bei Einundzwanzig'
           '${isClaimed ? "\n🔗 Gebunden" : ""}';
  }

  // Badge-Hash für Verifizierung (Legacy)
  String getVerificationHash() {
    final data = '$id-$meetupName-${date.toIso8601String()}-$blockHeight';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // =============================================
  // EXPORT: Vollständige Badge-Daten mit Beweisen
  // =============================================
  static String exportBadgesForReputation(
    List<MeetupBadge> badges,
    String userNpub, {
    String nickname = '',
    String telegram = '',
    String twitter = '',
  }) {
    final Map<String, dynamic> identity = {};
    if (nickname.isNotEmpty) identity['nickname'] = nickname;
    if (userNpub.isNotEmpty) identity['nostr_npub'] = userNpub;
    if (telegram.isNotEmpty) identity['telegram'] = telegram;
    if (twitter.isNotEmpty) identity['twitter'] = twitter;

    final stats = getReputationStats(badges);

    final data = {
      'version': '4.0',
      'identity': identity.isNotEmpty ? identity : {'status': 'anonymous'},
      'total_badges': badges.length,
      'verified_badges': countVerifiedBadges(badges),
      'bound_badges': countBoundBadges(badges),
      'meetups_visited': badges.map((b) => b.meetupName).toSet().length,
      'unique_signers': badges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet().length,
      'badge_proof': generateBadgeProof(badges),
      'badge_proof_v2': generateBadgeProofV2(badges),
      'stats': stats,
      'badges': badges.map((b) => {
        'meetup': b.meetupName,
        'date': b.date.toIso8601String(),
        'block': b.blockHeight,
        'signer_npub': b.signerNpub,
        'sig_version': b.sigVersion,
        'is_bound': b.isFullyBound,
        'is_retroactive': b.isRetroactive,
        'presence_verified': b.presenceVerified,
        if (b.hasCryptoProof) ...{
          'sig': b.sig,
          'sig_id': b.sigId,
          'admin_pubkey': b.adminPubkey,
        },
        if (b.isClaimed) ...{
          'claim_sig': b.claimSig,
          'claim_event_id': b.claimEventId,
          'claim_pubkey': b.claimPubkey,
        },
        'hash': b.getVerificationHash(),
      }).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(data);
    final checksum = sha256.convert(utf8.encode(jsonString)).toString().substring(0, 8);
    data['checksum'] = checksum;

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

// Globale Badge-Liste (wird beim App-Start geladen)
List<MeetupBadge> myBadges = [];


