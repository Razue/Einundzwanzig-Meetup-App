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
  // Zweiter Ort für dieselbe Datei: der Blob liegt zusätzlich im sicheren
  // Speicher, neben seinem Schlüssel. SharedPreferences bleibt der erste
  // Ort und wird deswegen nie geräumt. Auf iOS überlebt der Schlüsselbund
  // eine Neuinstallation, SharedPreferences nicht; bei einem Nutzer waren
  // nsec und Badge-Schlüssel danach noch da, die Badges weg. Wie sich
  // andere Geräte bei Updates und Resets verhalten, weiß niemand für alle.
  // Beim Laden zählt jede Fassung, die sich öffnen lässt.
  static const String _secureBadgeEncrypted = 'badges_encrypted';
  static const String _prefsLegacyBadges = 'badges'; // Altes Klartext-Feld
  /// Erste Fassung der verschlüsselten Datei. Wird nicht überschrieben,
  /// damit ein fehlgeschlagenes Update die Sammlung nicht auslöscht.
  static const String _prefsBadgePreserved = 'badges_encrypted_preserved';
  /// Zweite, ältere Fassung. Belegt ein erneutes Ersetzen den Sicherungs-
  /// slot, wandert der bisherige Inhalt hierher, statt still verworfen zu
  /// werden. Zwei Stufen genügen; ältere Fassungen sind auf den Relays oder
  /// im Backup.
  static const String _prefsBadgeOlder = 'badges_encrypted_preserved_older';
  /// Ein Wert unter dem Schlüssel-Alias, der kein Hex-Schlüssel ist. Er wird
  /// beim bewussten Ersetzen hierher beiseitegeschoben statt überschrieben —
  /// er könnte noch wichtig sein.
  static const String _suspectKeyAlias = 'badge_encryption_key_suspect';
  /// Scans, die ankamen, während die alte Datei nicht lesbar war. Sie liegen
  /// verschlüsselt mit einem eigenen Schlüssel, weil der Badge-Schlüssel in
  /// dem Moment gerade fehlt oder nicht lesbar ist.
  static const String _prefsBadgePending = 'badges_pending_encrypted';
  static const String _pendingKeyAlias = 'badge_pending_key';
  static const String _pendingSuspectAlias = 'badge_pending_key_suspect';
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
  /// unter dem Namen noch nichts Brauchbares liegt. Ein Lese-Fehler
  /// überschreibt den alten Eintrag nie. Ein Wert mit falschem Format
  /// blockiert das Neuanlegen nicht für immer: beim bewussten Ersetzen wird
  /// er unter [_suspectKeyAlias] beiseitegeschoben statt überschrieben.
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
      if (!create) {
        AppLogger.warn('Badge',
            'Badge-Schlüssel hat unerwartetes Format (${existing.trim().length} Zeichen), er bleibt liegen');
        return null;
      }
      try {
        await _secureStorage.write(key: _suspectKeyAlias, value: existing);
      } catch (e) {
        AppLogger.warn('Badge',
            'Verdächtiger Badge-Schlüssel nicht beiseite zu schieben: $e');
        return null;
      }
      AppLogger.warn('Badge',
          'Badge-Schlüssel unerwartetes Format (${existing.trim().length} Zeichen), beiseitegeschoben unter $_suspectKeyAlias');
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

  /// Öffnet alle Fassungen und vereinigt die Badges nach Id.
  /// [anchor] ist der Inhalt der Fassung, die als Primärdatei liegt oder
  /// zur Primärdatei befördert wird. [openedCount] zählt, wie viele
  /// Fassungen aufgingen. Weicht die Vereinigung von diesem Anker ab,
  /// schreibt [loadBadges] sie in die Primärdatei. Die übrigen Fassungen
  /// bleiben als Sicherung liegen. Öffnet der Primäre ([primaryBlob])
  /// nicht, wird der erste geöffnete Blob der neue Primäre.
  static Future<
      ({
        List<MeetupBadge> badges,
        List<MeetupBadge> anchor,
        int openedCount,
        String? primary,
        String blob,
        enc.Key key
      })?> _openAll(String? primaryBlob, List<String> blobs) async {
    final keys =
        await _candidateKeys(await _getBadgeKey(create: false));
    String? openedPrimary;
    enc.Key? openedPrimaryKey;
    String? firstBlob;
    enc.Key? firstKey;
    List<MeetupBadge> anchor = const [];
    var openedCount = 0;
    final byId = <String, MeetupBadge>{};
    for (final blob in blobs) {
      for (final key in keys) {
        final badges = _decryptBlob(blob, key);
        if (badges == null) continue;
        openedCount++;
        if (firstBlob == null) {
          firstBlob = blob;
          firstKey = key;
          anchor = badges;
        }
        if (blob == primaryBlob) {
          openedPrimary = blob;
          openedPrimaryKey = key;
          anchor = badges;
        }
        for (final badge in badges) {
          final existing = byId[badge.id];
          byId[badge.id] =
              existing == null ? badge : _preferVariant(existing, badge);
        }
        break; // diese Fassung ist offen, die nächste kommt dran
      }
    }
    if (firstBlob == null) return null;
    return (
      // Über alle Fassungen nach Id gesammelt, dann je Veranstaltung
      // vereinigt: Doppelscans aus einer Sicherung kommen nicht zurück.
      badges: unionByIdentity(byId.values.toList(), const []),
      anchor: anchor,
      openedCount: openedCount,
      primary: openedPrimary,
      blob: openedPrimary ?? firstBlob,
      key: openedPrimaryKey ?? firstKey!,
    );
  }

  /// Puffer für einen Identitätswechsel. [loadBadges] liest ihn nicht.
  /// Die aktive Datei bleibt, bis [promoteIncoming] sie ersetzt.
  static const String incomingPrefsKey = 'badges_encrypted_incoming';

  /// Verschlüsselt [badges] in den Puffer. Die aktive Datei bleibt liegen.
  /// false: kein Schlüssel und keiner anlegbar. Fehlt der Schlüssel, wird
  /// einer angelegt: der Nutzer ersetzt die Identität ausdrücklich, und eine
  /// Datei ohne Schlüssel lässt sich ohnehin nicht öffnen. Sie wandert bei
  /// der Übernahme roh ins Archiv.
  static Future<bool> stageIncoming(List<MeetupBadge> badges) async {
    if (badges.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getBadgeKey(create: true);
    if (key == null) return false;
    try {
      final iv = enc.IV.fromSecureRandom(12);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final jsonStr = jsonEncode(badges.map((b) => b.toJson()).toList());
      final encrypted = encrypter.encrypt(jsonStr, iv: iv);
      await prefs.setString(
          incomingPrefsKey, '${iv.base64}:${encrypted.base64}');
      return true;
    } catch (e) {
      AppLogger.warn('Badge', 'Puffer für den Identitätswechsel nicht geschrieben: $e');
      return false;
    }
  }

  /// Macht den Puffer zur aktiven Datei. Alles, was das Gerät von der alten
  /// Sammlung noch hat, liegt danach als ein Eintrag im Archiv. false: kein
  /// Puffer, oder das Archiv hat die alte Sammlung nicht angenommen. Dann
  /// bleibt die aktive Datei liegen.
  static Future<bool> promoteIncoming({String formerNpub = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final incoming = prefs.getString(incomingPrefsKey);
    if (incoming == null || !incoming.contains(':')) return false;
    // Ein Abbruch zwischen Primärdatei und Puffer-Abräumen: die Übernahme
    // ist schon geschehen. Noch einmal archivieren hieße, die neue Sammlung
    // als die alte zu etikettieren.
    if (prefs.getString(_prefsBadgeEncrypted) != incoming) {
      final retained =
          await _retainCurrent(prefs, 'replaced', npub: formerNpub);
      if (!retained.ok) return false;
      await _deleteSecureCopy();
      await prefs.remove(_prefsBadgePreserved);
      await prefs.remove(_prefsBadgeOlder);
      await _releasePending(keepKey: retained.keepPendingKey);
      await prefs.setString(_prefsBadgeEncrypted, incoming);
    }
    await _writeSecureCopy(incoming);
    await prefs.remove(incomingPrefsKey);
    badgesUnreadable = false;
    onBadgesSaved?.call();
    return true;
  }

  /// Was ersetzt, verdrängt oder geleert wird, liegt hier: eine Fassung pro
  /// Vorgang, verschlüsselt mit dem Geräte-Schlüssel. [loadBadges] liest das
  /// nie, sonst käme eine andere Identität in die Sammlung. Zurück holt nur
  /// [mergeFormer]. Es bleiben die letzten [_formerMax] Einträge.
  static const String formerPrefsKey = 'badges_former';
  // Zweitkopie des Archivs im sicheren Speicher, wie bei der aktiven Datei:
  // auf iOS überlebt sie die Neuinstallation. Prefs bleiben der erste Ort.
  static const String _secureFormer = 'badges_former';
  static const int _formerMax = 10;
  // Grenze für das Ganze, damit ein Schlüsselbund-Eintrag handlich bleibt.
  static const int _formerMaxChars = 500 * 1024;

  static List<Map<String, dynamic>> _parseFormer(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return [
          for (final e in list)
            if (e is Map) Map<String, dynamic>.from(e),
        ];
      }
    } catch (_) {}
    return [];
  }

  /// Prefs und Zweitkopie vereinigt, nach Blob. Eine neuere Zweitkopie wird
  /// nicht von einer älteren Prefs-Fassung verdeckt. Fehlen die Prefs, kommt
  /// die Zweitkopie dorthin zurück.
  static Future<List<Map<String, dynamic>>> _loadFormer(
      SharedPreferences prefs) async {
    final fromPrefs = _parseFormer(prefs.getString(formerPrefsKey));
    String? secure;
    try {
      secure = await _secureStorage.read(key: _secureFormer);
    } catch (e) {
      AppLogger.warn('Badge', 'Archiv-Zweitkopie nicht lesbar: $e');
    }
    final merged = _unionFormer(fromPrefs, _parseFormer(secure));
    if (merged.length != fromPrefs.length) {
      try {
        await prefs.setString(formerPrefsKey, jsonEncode(merged));
      } catch (_) {}
    }
    return merged;
  }

  static List<Map<String, dynamic>> _unionFormer(
      List<Map<String, dynamic>> first, List<Map<String, dynamic>> second) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final entry in [...first, ...second]) {
      final blob = (entry['blob'] ?? '').toString();
      if (blob.isEmpty || !seen.add(blob)) continue;
      out.add(entry);
    }
    // Nach Zeit, damit ein Eintrag, der nur im Schlüsselbund lag, nicht
    // als neuester erscheint. Gleiche Zeit: Reihenfolge bleibt.
    int at(Map<String, dynamic> e) => (e['at'] as num?)?.toInt() ?? 0;
    final indexed = out.asMap().entries.toList()
      ..sort((x, y) {
        final byAt = at(x.value).compareTo(at(y.value));
        return byAt != 0 ? byAt : x.key.compareTo(y.key);
      });
    return [for (final e in indexed) e.value];
  }

  /// false: die Prefs haben die Liste nicht angenommen. Die Zweitkopie wird
  /// dann nicht angefasst, sie behält den letzten guten Stand.
  static Future<bool> _writeFormer(
      SharedPreferences prefs, List<Map<String, dynamic>> list) async {
    final encoded = jsonEncode(list);
    try {
      await prefs.setString(formerPrefsKey, encoded);
    } catch (e) {
      AppLogger.warn('Badge', 'Archiv nicht geschrieben: $e');
      return false;
    }
    try {
      await _secureStorage.write(key: _secureFormer, value: encoded);
    } catch (e) {
      AppLogger.warn('Badge', 'Archiv-Zweitkopie nicht geschrieben: $e');
    }
    return true;
  }

  /// Nur der Reset räumt das Archiv, an beiden Orten.
  static Future<void> _deleteFormer(SharedPreferences prefs) async {
    await prefs.remove(formerPrefsKey);
    try {
      await _secureStorage.delete(key: _secureFormer);
    } catch (e) {
      AppLogger.warn('Badge', 'Archiv-Zweitkopie nicht gelöscht: $e');
    }
  }

  /// Der Reset der App: alles weg, an beiden Orten, auch das Archiv und
  /// der Puffer. Der einzige Pfad, der wirklich löscht. Nicht für Restore
  /// oder Leeren, die archivieren.
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _prefsBadgeEncrypted,
      _prefsBadgePreserved,
      _prefsBadgeOlder,
      _prefsLegacyBadges,
      incomingPrefsKey,
    ]) {
      await prefs.remove(key);
    }
    await _writePending([]);
    await _deleteSecureCopy();
    await _deleteFormer(prefs);
    badgesUnreadable = false;
  }

  static Map<String, dynamic> _formerEntry(String reason, String npub, String blob) =>
      {
        'at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'reason': reason,
        'npub': npub,
        'blob': blob,
      };

  /// Hängt Einträge an. false: nichts Neues zu schreiben, das ist in Ordnung,
  /// oder die Prefs haben abgelehnt. Der neueste Eintrag bleibt, auch wenn
  /// die Grenze damit reißen würde.
  static Future<bool> _appendFormer(SharedPreferences prefs,
      List<Map<String, dynamic>> additions) async {
    if (additions.isEmpty) return true;
    final list = await _loadFormer(prefs);
    var added = false;
    for (final entry in additions) {
      final blob = (entry['blob'] ?? '').toString();
      if (!blob.contains(':')) continue;
      if (list.any((e) => e['blob'] == blob)) continue;
      list.add(entry);
      added = true;
    }
    if (!added) return true;
    while (list.length > 1 &&
        (list.length > _formerMax ||
            jsonEncode(list).length > _formerMaxChars)) {
      list.removeAt(0);
    }
    return _writeFormer(prefs, list);
  }

  /// Eine Fassung für alles, was sich öffnen lässt, plus jede Datei, die
  /// sich nicht öffnen lässt. [keepPendingKey]: die Vormerkung ließ sich
  /// nicht lesen, ihr Schlüssel bleibt, sonst ist der Archiv-Blob stumm.
  static Future<({bool ok, bool keepPendingKey})> _retainCurrent(
    SharedPreferences prefs,
    String reason, {
    String npub = '',
  }) async {
    final blobs = <String>[];
    void add(String? raw) {
      if (raw != null && raw.contains(':') && !blobs.contains(raw)) {
        blobs.add(raw);
      }
    }

    add(prefs.getString(_prefsBadgeEncrypted));
    add(await _readSecureCopy());
    add(prefs.getString(_prefsBadgePreserved));
    add(prefs.getString(_prefsBadgeOlder));
    final pendingBlob = prefs.getString(_prefsBadgePending);
    add(pendingBlob);
    if (blobs.isEmpty) return (ok: true, keepPendingKey: false);

    // Jeden Blob einmal öffnen; was aufgeht, wird je Veranstaltung
    // vereinigt und unter dem Geräte-Schlüssel als eine Fassung abgelegt.
    // Der Schlüssel der Vormerkung kann danach weg; mit ihm verschlüsselte
    // Blobs wären sonst stumm, sobald er gelöscht wird. Was nicht aufgeht,
    // kommt roh dazu und behält seine Chance auf einen späteren Schlüssel.
    final deviceKey = await _getBadgeKey(create: false);
    final keys = await _candidateKeys(deviceKey);
    final openedBlobs = <String>{};
    var union = <MeetupBadge>[];
    for (final blob in blobs) {
      for (final key in keys) {
        final badges = _decryptBlob(blob, key);
        if (badges == null) continue;
        openedBlobs.add(blob);
        union = unionByIdentity(union, badges);
        break;
      }
    }
    final entries = <Map<String, dynamic>>[];
    if (deviceKey != null && union.isNotEmpty) {
      try {
        entries.add(_formerEntry(reason, npub, _encryptBlob(union, deviceKey)));
      } catch (e) {
        AppLogger.warn('Badge', 'Archiv-Fassung nicht verschlüsselt: $e');
        return (ok: false, keepPendingKey: false);
      }
      for (final blob in blobs) {
        if (openedBlobs.contains(blob)) continue;
        entries.add(_formerEntry(reason, npub, blob));
      }
    } else {
      for (final blob in blobs) {
        entries.add(_formerEntry(reason, npub, blob));
      }
    }
    final pendingKept = deviceKey == null ||
        (pendingBlob != null &&
            pendingBlob.contains(':') &&
            !openedBlobs.contains(pendingBlob));
    final wrote = await _appendFormer(prefs, entries);
    return (ok: wrote, keepPendingKey: pendingKept);
  }

  /// Vormerkung aus dem Slot nehmen, damit sie nicht in die neue Sammlung
  /// vereinigt wird. [keepKey]: der Schlüssel öffnet noch einen Archiv-Blob.
  static Future<void> _releasePending({required bool keepKey}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsLegacyPending);
    await prefs.remove(_prefsBadgePending);
    if (keepKey) return;
    try {
      await _secureStorage.delete(key: _pendingKeyAlias);
    } catch (e) {
      AppLogger.warn('Badge', 'Schlüssel der Vormerkung nicht gelöscht: $e');
    }
  }

  static Future<List<MeetupBadge>?> _openFormer(String blob) async {
    final keys = await _candidateKeys(await _getBadgeKey(create: false));
    for (final key in keys) {
      final badges = _decryptBlob(blob, key);
      if (badges != null) return badges;
    }
    return null;
  }

  /// Frühere Sammlungen, neueste zuerst. `badges` ist null, wenn kein
  /// Schlüssel auf dem Gerät die Fassung öffnet.
  static Future<List<FormerCollection>> formerCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _loadFormer(prefs);
    final out = <FormerCollection>[];
    for (var i = entries.length - 1; i >= 0; i--) {
      final e = entries[i];
      out.add(FormerCollection(
        index: i,
        at: DateTime.fromMillisecondsSinceEpoch(
            ((e['at'] as num?)?.toInt() ?? 0) * 1000),
        reason: (e['reason'] ?? '').toString(),
        npub: (e['npub'] ?? '').toString(),
        badges: await _openFormer((e['blob'] ?? '').toString()),
      ));
    }
    return out;
  }

  /// Vereinigt eine frühere Sammlung mit der aktiven, nach derselben Regel
  /// wie überall. Die frühere bleibt im Archiv. false: nicht lesbar, die
  /// aktive Datei nicht lesbar, oder nicht gespeichert.
  static Future<bool> mergeFormer(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _loadFormer(prefs);
    if (index < 0 || index >= entries.length) return false;
    final former = await _openFormer((entries[index]['blob'] ?? '').toString());
    if (former == null) return false;
    final current = await loadBadges();
    if (badgesUnreadable) return false;
    return saveBadges(unionByIdentity(current, former));
  }

  static Future<void> discardIncoming() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(incomingPrefsKey);
  }

  // Die Zweitkopie darf das Speichern nie scheitern lassen und das Laden
  // nie blockieren: Fehler werden protokolliert, mehr nicht.
  static Future<void> _writeSecureCopy(String stored) async {
    try {
      await _secureStorage.write(key: _secureBadgeEncrypted, value: stored);
    } catch (e) {
      AppLogger.warn('Badge', 'Zweitkopie im sicheren Speicher nicht geschrieben: $e');
    }
  }

  static Future<String?> _readSecureCopy() async {
    try {
      return await _secureStorage.read(key: _secureBadgeEncrypted);
    } catch (e) {
      AppLogger.warn('Badge', 'Zweitkopie im sicheren Speicher nicht lesbar: $e');
      return null;
    }
  }

  static Future<void> _deleteSecureCopy() async {
    try {
      await _secureStorage.delete(key: _secureBadgeEncrypted);
    } catch (e) {
      AppLogger.warn('Badge', 'Zweitkopie im sicheren Speicher nicht gelöscht: $e');
    }
  }

  /// false: die älteste Sicherung ließ sich nicht archivieren. Dann bleibt
  /// die Kette, wie sie ist, und der Aufrufer überschreibt sie nicht.
  static Future<bool> _stashBlob(SharedPreferences prefs, String blob) async {
    final preserved = prefs.getString(_prefsBadgePreserved);
    if (preserved != null && preserved.isNotEmpty) {
      if (preserved == blob) return true;
      final older = prefs.getString(_prefsBadgeOlder);
      if (!await _appendFormer(
          prefs, [_formerEntry('rotated', '', older ?? '')])) {
        return false;
      }
      await prefs.setString(_prefsBadgeOlder, preserved);
    }
    await prefs.setString(_prefsBadgePreserved, blob);
    return true;
  }

  /// Eigener Schlüssel für vorgemerkte Scans, unabhängig vom Badge-Schlüssel.
  /// Er wird zusammen mit der Vormerkung wieder gelöscht.
  static Future<enc.Key?> _getPendingKey({required bool create}) async {
    try {
      final raw = await _secureStorage.read(key: _pendingKeyAlias);
      final parsed = _keyFromHex(raw);
      if (parsed != null || !create) return parsed;
      // Dasselbe Muster wie beim Badge-Schlüssel: ein unbrauchbarer Wert
      // wird beiseitegeschoben, statt das Anlegen für immer zu blockieren.
      if (raw != null && raw.trim().isNotEmpty) {
        try {
          await _secureStorage.write(key: _pendingSuspectAlias, value: raw);
        } catch (_) {
          return null;
        }
      }
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

  /// Welche von zwei Fassungen derselben Veranstaltung bleibt: die mit
  /// Claim, dann die mit bestätigter Anwesenheit, dann die ältere (der
  /// erste Scan ist das Original), bei Gleichstand [a].
  static MeetupBadge _preferVariant(MeetupBadge a, MeetupBadge b) {
    final aClaim = a.claimSig.isNotEmpty;
    final bClaim = b.claimSig.isNotEmpty;
    if (aClaim != bClaim) return aClaim ? a : b;
    if (a.presenceVerified != b.presenceVerified) {
      return a.presenceVerified ? a : b;
    }
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate < 0 ? a : b;
    if (a.claimTimestamp != b.claimTimestamp) {
      return a.claimTimestamp < b.claimTimestamp ? a : b;
    }
    final byId = a.id.compareTo(b.id);
    if (byId != 0) return byId < 0 ? a : b;
    return a;
  }

  /// Schlüssel der Vereinigung: die Veranstaltung ([identityKey]), nicht die
  /// Id. Zwei Scans desselben Abends mit rotierendem QR tragen zwei Ids und
  /// sind doch ein Badge. Organisator-Marker zählen getrennt: sie teilen die
  /// meetupEventId mit dem Teilnehmer-Badge, sind aber etwas anderes.
  static String unionKey(MeetupBadge b) =>
      b.isOrganizer ? 'org:${identityKey(b)}' : identityKey(b);

  /// Vereinigt zwei Sammlungen je Veranstaltung. Dieselbe Regel überall:
  /// Datei, Sync, Backup und die Bereinigung im Wallet. Dadurch ist die
  /// Vereinigung von sich aus frei von Doppelscans, auf jedem Gerät mit
  /// demselben Ergebnis, ohne dass irgendwo gelöscht werden muss. Bei
  /// Gleichstand gewinnt [base].
  static List<MeetupBadge> unionByIdentity(List<MeetupBadge> base, List<MeetupBadge> extra) {
    final byKey = <String, MeetupBadge>{};
    void add(MeetupBadge badge) {
      final key = unionKey(badge);
      final existing = byKey[key];
      byKey[key] = existing == null ? badge : _preferVariant(existing, badge);
    }
    for (final badge in base) {
      add(badge);
    }
    for (final badge in extra) {
      add(badge);
    }
    return byKey.values.toList();
  }

  /// Gleicher Bestand, unabhängig von der Reihenfolge in der Datei.
  static bool sameBadges(List<MeetupBadge> a, List<MeetupBadge> b) {
    String canon(MeetupBadge badge) => jsonEncode(badge.toJson());
    final left = a.map(canon).toList()..sort();
    final right = b.map(canon).toList()..sort();
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  /// Scan, während die alte Sammlung nicht lesbar ist. Das Badge bleibt
  /// daneben liegen und kommt beim nächsten erfolgreichen Lesen dazu.
  /// false: die Vormerkung selbst ist gerade nicht schreibbar — das Badge
  /// ist dann nirgends gesichert und der Aufrufer muss das melden.
  static Future<bool> keepAside(MeetupBadge badge) async {
    final pending = await _readPending();
    if (pending == null) {
      AppLogger.error('Badge', 'Badge nicht vorgemerkt, Vormerkung nicht lesbar');
      return false;
    }
    if (pending.any((b) => b.id == badge.id)) return true;
    pending.add(badge);
    if (!await _writePending(pending)) {
      AppLogger.error('Badge', 'Badge nicht vorgemerkt, kein Schlüssel verfügbar');
      return false;
    }
    AppLogger.warn('Badge', 'Badge vorgemerkt, Sammlung ist gerade nicht lesbar');
    return true;
  }

  static Future<List<MeetupBadge>> _finishReadable(List<MeetupBadge> badges) async {
    badgesUnreadable = false;
    final pending = await _readPending();
    if (pending == null || pending.isEmpty) return badges;
    final merged = unionByIdentity(badges, pending);
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
      // Leeren löscht nicht: eine Fassung ins Archiv, und erst dann weg.
      // Schlägt das Archiv fehl, bleibt alles liegen. Wirklich löschen tut
      // nur [resetAll].
      final retained = await _retainCurrent(prefs, 'cleared');
      if (!retained.ok) return false;
      await prefs.remove(_prefsBadgeEncrypted);
      await prefs.remove(_prefsBadgePreserved);
      await prefs.remove(_prefsBadgeOlder);
      await prefs.remove(_prefsLegacyBadges);
      await _releasePending(keepKey: retained.keepPendingKey);
      await _deleteSecureCopy();
      badgesUnreadable = false;
      onBadgesSaved?.call();
      return true;
    }

    if (badgesUnreadable && !replaceUnreadable) return false;

    final currentBlob = prefs.getString(_prefsBadgeEncrypted);
    final hasBlob = currentBlob != null && currentBlob.contains(':');
    if (replaceUnreadable && hasBlob) {
      if (!await _stashBlob(prefs, currentBlob)) return false;
    }

    // Fehlt der Schlüssel, entsteht ein neuer nur ohne vorhandene Datei
    // oder beim bewussten Ersetzen. Sonst bliebe die Datei für immer zu.
    final key = await _getBadgeKey(create: !hasBlob || replaceUnreadable);
    if (key == null) {
      AppLogger.warn('Badge', 'Speichern ausgesetzt, Schlüssel nicht verfügbar');
      return false;
    }

    final pending = await _readPending();
    final toStore = unionByIdentity(badges, pending ?? const []);
    final jsonStr = jsonEncode(toStore.map((b) => b.toJson()).toList());

    try {
      final iv = enc.IV.fromSecureRandom(12); // 96 Bit (NIST-empfohlen)
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encrypt(jsonStr, iv: iv);

      // Format: base64(IV):base64(ciphertext)
      final stored = '${iv.base64}:${encrypted.base64}';
      await prefs.setString(_prefsBadgeEncrypted, stored);
      await _writeSecureCopy(stored);

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
    final older = prefs.getString(_prefsBadgeOlder);
    final blobs = <String>[];
    void addBlob(String? raw) {
      if (raw != null && raw.contains(':') && !blobs.contains(raw)) {
        blobs.add(raw);
      }
    }
    addBlob(blob);
    // Gleich nach dem Primären: Ist er weg (Neuinstallation auf iOS), wird
    // die Zweitkopie zum neuen Primären und landet wieder in den Prefs.
    addBlob(await _readSecureCopy());
    addBlob(preserved);
    addBlob(older);

    if (blobs.isNotEmpty) {
      final opened = await _openAll(blob, blobs);
      if (opened != null) {
        // Öffnete der Primäre selbst, bleibt er die Datei. Sonst wird der
        // erste geöffnete Blob der neue Primäre; die übrigen Fassungen
        // bleiben als Sicherung liegen und kommen über die Vereinigung dazu.
        if (opened.primary == null) {
          // Erst die unlesbare Fassung parken. Gelingt das nicht, bleibt sie
          // Primärdatei; die lesbare Sicherung liegt weiterhin daneben.
          var parked = true;
          if (blob != null && blob.contains(':') && blob != opened.blob) {
            if (preserved == opened.blob) {
              // Die beförderte Fassung war die Sicherung: Der Slot nimmt
              // den unlesbaren Primären direkt. Nichts geht verloren, die
              // lesbare Fassung wird gleich zur Primärdatei, und die ältere
              // Sicherung muss nicht ins Archiv rotieren.
              await prefs.setString(_prefsBadgePreserved, blob);
            } else {
              parked = await _stashBlob(prefs, blob);
            }
          }
          if (parked) {
            await prefs.setString(_prefsBadgeEncrypted, opened.blob);
          }
        }
        await _rememberKey(opened.key);
        // Eine Löschfunktion gibt es noch nicht. Jede Fassung, die sich
        // öffnen lässt, gehört deshalb zur Sammlung: Die Vereinigung wird
        // in die Primärdatei geschrieben. Die Sicherungen bleiben liegen,
        // damit ein später wiedergefundener Schlüssel noch dazukommen kann.
        if (opened.openedCount > 1 &&
            !sameBadges(opened.anchor, opened.badges)) {
          badgesUnreadable = false;
          final pending = await _readPending();
          final wrote = await saveBadges(opened.badges);
          if (wrote) {
            if (pending == null || pending.isEmpty) return opened.badges;
            return unionByIdentity(opened.badges, pending);
          }
        }
        return _finishReadable(opened.badges);
      }
      // Nichts ging auf. Nur füllen, nichts verdrängen: Der Primäre bleibt
      // Primäre, ein belegter Sicherungs-Slot braucht ihn nicht zusätzlich,
      // und ein fehlgeschlagenes Lesen darf keine Fassung aus der Sicherung
      // schieben.
      if ((preserved == null || preserved.isEmpty) &&
          blob != null &&
          blob.contains(':')) {
        await prefs.setString(_prefsBadgePreserved, blob);
      }
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

/// Eine frühere Badge-Sammlung aus dem Archiv, siehe
/// [MeetupBadge.formerCollections].
class FormerCollection {
  final int index;
  final DateTime at;
  final String reason;
  final String npub;
  final List<MeetupBadge>? badges;

  const FormerCollection({
    required this.index,
    required this.at,
    required this.reason,
    required this.npub,
    required this.badges,
  });
}
