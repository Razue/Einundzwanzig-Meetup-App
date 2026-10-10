// ============================================
// PROMOTION CLAIM SERVICE — Proof of Reputation
// ============================================
//
// Löst das "Trust Score Paradoxon":
// Ein User der lokal zum Admin promotet wird,
// muss auch von ANDEREN Apps als Admin erkannt werden.
//
// KONZEPT:
//   1. User sammelt genug Badges → Trust Score erreicht
//   2. App publiziert einen "Admin Claim" auf Nostr (Kind 30021)
//      → Enthält die Badge-Beweise (Schnorr-Signaturen)
//   3. JEDE andere App kann diesen Claim verifizieren:
//      → Sind die Badge-Signaturen echt?
//      → Stammen sie von bekannten Admins?
//      → Reicht die Anzahl für den Schwellenwert?
//   4. Wenn ja → Claimer wird lokal als "organic" Admin akzeptiert
//
// SICHERHEIT:
//   - Schnorr-Signaturen sind unfälschbar
//   - Niemand kann Badges erfinden die er nicht hat
//   - Kein Super-Admin nötig → erlaubnisfreies Wachstum
//   - Jede App verifiziert selbst ("Don't trust, verify")
//
// GENERATIONEN:
//   Gen 0: Super-Admin (Genesis)
//   Gen 1: Badges von Gen 0 → werden selbst Admin
//   Gen 2: Badges von Gen 1 → werden selbst Admin
//   Das Netz wächst wie ein Pilzgeflecht.
//
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge.dart';
import 'signing_service.dart';
import 'nostr_service.dart';
import 'badge_security.dart';
import 'badge_claim_service.dart';
import 'admin_registry.dart';
import 'app_logger.dart';
import 'relay_socket.dart';

class PromotionClaimService {
  // Nostr Event Kind für Admin Claims
  static const int _claimKind = 30021;
  static const String _claimDTag = 'einundzwanzig-admin-claim';

  // Minimale Badge-Anforderungen für einen gültigen Claim
  // (Muss mit TrustConfig übereinstimmen)
  static const int minVerifiedBadges = 3;
  static const int minUniqueSigners = 1;

  // Relays (gleiche wie AdminRegistry)
  static const List<String> _relays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.nostr.band',
    'wss://nostr.einundzwanzig.space',
  ];

  static const Duration _relayTimeout = Duration(seconds: 8);

  // =============================================
  // CLAIM PUBLIZIEREN (Wenn User Threshold erreicht)
  // =============================================
  //
  // Wird aufgerufen wenn der Trust Score den
  // Schwellenwert überschreitet. Erstellt ein
  // signiertes Nostr Event mit den Badge-Beweisen.
  //
  static Future<bool> publishAdminClaim({
    required List<MeetupBadge> badges,
    required String meetupName,
  }) async {
    final npub = await SigningService.npub();
    if (npub == null || !await SigningService.canSign()) return false;
    String ownPubkey;
    try {
      ownPubkey = Nip19.decodePubkey(npub);
    } catch (_) {
      return false;
    }

    // Security Audit K1: Nur Badges, die der Claimer SELBST gebunden hat
    // (Claim-Signatur mit dem eigenen Schlüssel). Fremde oder ungebundene
    // Badges würden von den Prüfern ohnehin verworfen.
    final verifiedBadges = badges
        .where((b) => b.isFullyBound && b.claimPubkey == ownPubkey)
        .toList();
    if (verifiedBadges.length < minVerifiedBadges) return false;

    // Badge-Beweise kompakt verpacken
    final proofs = verifiedBadges.map((b) => {
      'meetup': b.meetupName,
      'date': b.date.toIso8601String(),
      'block': b.blockHeight,
      'sig': b.sig,
      'sig_id': b.sigId,
      'admin_pubkey': b.adminPubkey,
      'sig_version': b.sigVersion,
      'sig_content': b.sigContent,
      // Teilnehmer-Bindung (K1): beweist, dass der Claimer dieses Badge
      // selbst entgegengenommen hat.
      'claim_sig': b.claimSig,
      'claim_event_id': b.claimEventId,
      'claim_timestamp': b.claimTimestamp,
    }).toList();

    // Unique Signers zählen
    final uniqueSigners = verifiedBadges
        .map((b) => b.adminPubkey)
        .where((p) => p.isNotEmpty)
        .toSet()
        .length;

    final claimContent = jsonEncode({
      'type': 'admin_claim',
      'version': 1,
      'claimer_npub': npub,
      'meetup': meetupName,
      'verified_badges': verifiedBadges.length,
      'unique_signers': uniqueSigners,
      'proofs': proofs,
      'claimed_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    // Signiertes Nostr Event erstellen (lokal oder via Amber)
    final signed = await SigningService.signEvent(
      kind: _claimKind,
      tags: <List<String>>[
        ['d', _claimDTag],
        ['meetup', meetupName],
      ],
      content: claimContent,
    );

    // An Relays publishen
    int successCount = 0;
    final eventJson = jsonEncode([
      'EVENT',
      {
        'id': signed.id,
        'pubkey': signed.pubkey,
        'created_at': signed.createdAt,
        'kind': signed.kind,
        'tags': signed.tags,
        'content': signed.content,
        'sig': signed.sig,
      }
    ]);

    for (final relayUrl in _relays) {
      try {
        final ws = await RelaySocket.connect(relayUrl)
            .timeout(const Duration(seconds: 5));
        ws.add(eventJson);
        await Future.delayed(const Duration(seconds: 2));
        ws.close();
        successCount++;
        AppLogger.debug('PromotionClaim', 'Claim an $relayUrl gesendet ✓');

      } catch (e) {
        AppLogger.debug('PromotionClaim', '$relayUrl fehlgeschlagen: $e');
      }
    }

    AppLogger.debug('PromotionClaim', 'Claim publiziert an $successCount Relays');

    return successCount > 0;
  }

  // =============================================
  // CLAIMS VON RELAYS LADEN UND VERIFIZIEREN
  // =============================================
  //
  // Wird beim App-Start aufgerufen. Lädt alle
  // Admin Claims und verifiziert sie mathematisch.
  //
  // Security Audit K1: Gültige Claims landen NICHT mehr in der
  // Admin-Registry (dort zählten sie sofort als bekannte Signierer
  // und konnten weitere Claims "beglaubigen" — Selbst-Promotion in
  // Kette). Sie werden stattdessen in einer eigenen, sichtbar als
  // "organisch" markierten Liste gehalten, die für die Prüfung
  // weiterer Claims NICHT als bekannte Admins zählt.
  //
  static const String _organicKey = 'organic_admin_claims';

  static Future<List<VerifiedClaim>> syncOrganicAdmins() async {
    final List<VerifiedClaim> verifiedClaims = [];

    try {
      final claims = await _fetchClaimsFromRelays();
      if (claims == null || claims.isEmpty) return verifiedClaims;

      // Bekannte Admins laden (Genesis + Registry) — die organische
      // Liste gehört bewusst NICHT dazu.
      final knownAdmins = await AdminRegistry.getAdminList();
      final knownPubkeys = <String>{};

      // Super-Admin Pubkey
      try {
        knownPubkeys.add(Nip19.decodePubkey(AdminRegistry.superAdminNpub));
      } catch (_) {}

      // Alle bekannten Admin-Pubkeys sammeln
      for (final admin in knownAdmins) {
        try {
          knownPubkeys.add(Nip19.decodePubkey(admin.npub));
        } catch (_) {}
      }

      for (final claim in claims) {
        try {
          final result = verifyClaim(claim, knownPubkeys);
          if (result != null) {
            verifiedClaims.add(result);
            AppLogger.debug('PromotionClaim',
                'Organischer Claim akzeptiert: ${NostrService.shortenNpub(Nip19.encodePubkey(claim.pubkey))}');
          }
        } catch (e) {
          AppLogger.debug('PromotionClaim', 'Claim-Verifikation fehlgeschlagen: $e');

        }
      }

      await _saveOrganicClaims(verifiedClaims);
    } catch (e) {
      AppLogger.debug('PromotionClaim', 'Sync fehlgeschlagen: $e');

    }

    return verifiedClaims;
  }

  /// Zuletzt verifizierte organische Claims (nur Anzeige/Information,
  /// KEINE Admin-Rechte).
  static Future<List<VerifiedClaim>> getOrganicAdmins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_organicKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => VerifiedClaim.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveOrganicClaims(List<VerifiedClaim> claims) async {
    // Pro Claimer nur der neueste Claim.
    final byClaimer = <String, VerifiedClaim>{};
    for (final c in claims) {
      final cur = byClaimer[c.claimerPubkey];
      if (cur == null || c.claimedAt > cur.claimedAt) byClaimer[c.claimerPubkey] = c;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_organicKey,
        jsonEncode(byClaimer.values.map((c) => c.toJson()).toList()));
  }

  // =============================================
  // EINZELNEN CLAIM MATHEMATISCH VERIFIZIEREN
  // =============================================
  //
  // Das Herzstück: Prüft ob die Badge-Beweise
  // echt sind und von bekannten Admins stammen.
  //
  /// Öffentlich für Regressionstests. [knownAdminPubkeys] sind die
  /// Hex-Pubkeys der aktuell bekannten Admins (Genesis + Registry).
  static VerifiedClaim? verifyClaim(
    RawClaim claim,
    Set<String> knownAdminPubkeys,
  ) {
    // 1. Claim-Content parsen
    Map<String, dynamic> content;
    try {
      content = jsonDecode(claim.content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    if (content['type'] != 'admin_claim') return null;

    final proofs = content['proofs'] as List<dynamic>? ?? [];
    final meetup = content['meetup'] as String? ?? '';

    if (proofs.isEmpty || meetup.isEmpty) return null;

    // Security Audit 2, Fund #5: Claim-Alter prüfen (max 90 Tage).
    // Verhindert dass uralte Claims auf Basis längst suspendierter
    // Admins unbegrenzt gültig bleiben.
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const maxClaimAgeDays = 90;
    if (now - claim.createdAt > maxClaimAgeDays * 86400) {
      AppLogger.debug('PromotionClaim',
        'Claim abgelehnt: Zu alt (>$maxClaimAgeDays Tage)');
      return null;
    }

    // 2. Jeden Badge-Beweis einzeln verifizieren
    //
    // Security Audit K1 — ein Beweis zählt nur, wenn ALLE Punkte stimmen:
    //   a) Signatur noch nicht gesehen (keine Duplikate)
    //   b) Organisator-Signatur mathematisch gültig und der SIGNIERENDE
    //      Pubkey (nicht das unsignierte admin_pubkey-Feld) ist ein
    //      bekannter Admin
    //   c) Teilnehmer-Bindung: Der CLAIMER selbst hat das Badge mit seinem
    //      Schlüssel geclaimt (claim_sig über genau diese Organisator-
    //      Signatur)
    //   d) Mindestens drei verschiedene Sessions (Signierer + Meetup +
    //      signierter Tag)
    int validBadgeCount = 0;
    final verifiedSigners = <String>{};
    final seenSigs = <String>{};
    final sessions = <String>{};

    for (final proof in proofs) {
      try {
        final proofMap = proof as Map<String, dynamic>;
        final sig = proofMap['sig'] as String? ?? '';
        final adminPubkey = proofMap['admin_pubkey'] as String? ?? '';
        final sigVersion = proofMap['sig_version'] as int? ?? 0;
        final sigContent = proofMap['sig_content'] as String? ?? '';
        final sigId = proofMap['sig_id'] as String? ?? '';
        final block = proofMap['block'] as int? ?? 0;
        final claimSig = proofMap['claim_sig'] as String? ?? '';
        final claimEventId = proofMap['claim_event_id'] as String? ?? '';
        final claimTimestamp = proofMap['claim_timestamp'] as int? ?? 0;

        if (sig.isEmpty || adminPubkey.isEmpty) continue;

        // a) Duplikate verwerfen
        if (!seenSigs.add(sig)) continue;

        // Ist der Signer ein bekannter Admin?
        if (!knownAdminPubkeys.contains(adminPubkey)) {
          // Unbekannter Signer → Badge zählt nicht
          continue;
        }

        // b) Organisator-Signatur mathematisch prüfen
        if (sigVersion < 2 || sigContent.isEmpty) continue;
        Map<String, dynamic> data;
        VerifyResult verifyResult;
        try {
          data = jsonDecode(sigContent) as Map<String, dynamic>;
          // Ablauf ignorieren: Das Badge liegt naturgemäß Wochen zurück.
          verifyResult = BadgeSecurity.verify(data, checkExpiry: false);
        } catch (_) {
          continue;
        }
        if (!verifyResult.isValid) continue;
        // Der Pubkey, der tatsächlich signiert hat, muss der angegebene
        // bekannte Admin sein — und die Signatur im Beweis muss die
        // signierte sein.
        if (verifyResult.adminPubkey != adminPubkey) continue;
        final signedSig = (data['s'] ?? data['sig'] ?? '').toString();
        if (signedSig != sig) continue;

        // c) Teilnehmer-Bindung durch den Claimer
        if (claimSig.isEmpty || claimEventId.isEmpty || claimTimestamp == 0) continue;
        final binding = BadgeClaimService.verifyClaim(
          claimSig: claimSig,
          claimEventId: claimEventId,
          claimPubkey: claim.pubkey,
          claimTimestamp: claimTimestamp,
          orgSig: sig,
          orgEventId: sigId,
          orgPubkey: adminPubkey,
          blockHeight: block,
        );
        if (!binding.isValid) continue;

        // d) Session-Schlüssel aus SIGNIERTEN Feldern ableiten
        final normalized = BadgeSecurity.normalize(data);
        final signedAt = (data['c'] ?? data['created_at'] ?? 0) as int;
        final day = DateTime.fromMillisecondsSinceEpoch(signedAt * 1000, isUtc: true);
        final dayKey = '${day.year}-${day.month}-${day.day}';
        sessions.add('$adminPubkey|${normalized['meetup_id']}|$dayKey');

        validBadgeCount++;
        verifiedSigners.add(adminPubkey);
      } catch (_) {
        continue;
      }
    }

    // 3. Schwellenwert-Check
    if (validBadgeCount < minVerifiedBadges) return null;
    if (sessions.length < minVerifiedBadges) {
      AppLogger.debug('PromotionClaim',
        'Claim abgelehnt: Nur ${sessions.length} verschiedene Sessions');
      return null;
    }
    if (verifiedSigners.length < minUniqueSigners) return null;

    // Security Audit 2, Fund #5: Sicherstellen dass die Signer
    // AKTUELL noch Admins sind (nicht nur zum Zeitpunkt des Claims).
    // knownAdminPubkeys wird von syncOrganicAdmins() aus der aktuellen
    // AdminRegistry befüllt. Suspendierte Admins sind dort nicht mehr
    // enthalten → deren Badges werden oben bereits übersprungen.
    // Doppelter Check: verifiedSigners ∩ knownAdminPubkeys
    final currentlyActiveSigners = verifiedSigners
        .where((s) => knownAdminPubkeys.contains(s))
        .length;
    if (currentlyActiveSigners < minUniqueSigners) {
      AppLogger.debug('PromotionClaim',
        'Claim abgelehnt: Nur $currentlyActiveSigners von '
        '${verifiedSigners.length} Signern sind noch aktive Admins');
      return null;
    }

    return VerifiedClaim(
      claimerPubkey: claim.pubkey,
      meetup: meetup,
      verifiedBadgeCount: validBadgeCount,
      uniqueSignerCount: currentlyActiveSigners,
      claimedAt: claim.createdAt,
    );
  }

  // =============================================
  // CLAIMS VON RELAYS FETCHEN
  // =============================================
  static Future<List<RawClaim>?> _fetchClaimsFromRelays() async {
    for (final relayUrl in _relays) {
      try {
        final result = await _fetchFromSingleRelay(relayUrl);
        if (result != null && result.isNotEmpty) {
          AppLogger.debug('PromotionClaim', '${result.length} Claims von $relayUrl geladen');
          return result;
        }
      } catch (e) {
        AppLogger.debug('PromotionClaim', '$relayUrl fehlgeschlagen: $e');
        continue;
      }
    }
    return null;
  }

  static Future<List<RawClaim>?> _fetchFromSingleRelay(String relayUrl) async {
    RelaySocket? ws;
    final tally = RelayParseTally('PromotionClaim', 'Promotion-Claims von $relayUrl');

    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_relayTimeout);

      final completer = Completer<List<RawClaim>>();
      final claims = <RawClaim>[];
      // Security Audit M4: Kryptographisch sichere Subscription-ID
      final random = Random.secure();
      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subscriptionId = 'organic-claims-$subIdHex';

      ws.listen(
        (data) {
          tally.message();
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;

            if (type == 'EVENT' && message.length >= 3) {
              final eventData = message[2] as Map<String, dynamic>;

              // Event-Signatur prüfen
              // (verify: false — isValid() unten ist die einzige Prüfung;
              // der Konstruktor würde dieselbe Signatur doppelt prüfen.)
              final event = Event(
                eventData['id'] ?? '',
                eventData['pubkey'] ?? '',
                eventData['created_at'] ?? 0,
                eventData['kind'] ?? 0,
                (eventData['tags'] as List<dynamic>?)
                    ?.map((t) => (t as List<dynamic>).map((e) => e.toString()).toList())
                    .toList() ?? [],
                eventData['content'] ?? '',
                eventData['sig'] ?? '',
                verify: false,
              );

              if (event.isValid()) {
                claims.add(RawClaim(
                  pubkey: event.pubkey,
                  content: event.content,
                  createdAt: event.createdAt,
                ));
              } else {
                // Vorher warf der Konstruktor und der catch unten zählte das.
                tally.failed('Ungültige Signatur');
              }
            } else if (type == 'EOSE') {
              if (!completer.isCompleted) {
                completer.complete(claims);
              }
            }
          } catch (e) { tally.failed(e); }
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(<RawClaim>[]);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(claims);
        },
      );

      // Query: Alle Kind 30021 Events mit d-Tag "einundzwanzig-admin-claim"
      final request = jsonEncode([
        'REQ',
        subscriptionId,
        {
          'kinds': [_claimKind],
          '#d': [_claimDTag],
          'limit': 100, // Max 100 Claims
        }
      ]);

      ws.add(request);

      final result = await completer.future.timeout(
        _relayTimeout,
        onTimeout: () => <RawClaim>[],
      );

      ws.add(jsonEncode(['CLOSE', subscriptionId]));
      return result;

    } catch (e) {
      rethrow;
    } finally {
      tally.report();
      try { ws?.close(); } catch (_) {}
    }
  }
}

// =============================================
// DATENKLASSEN
// =============================================

class RawClaim {
  final String pubkey;
  final String content;
  final int createdAt;

  RawClaim({
    required this.pubkey,
    required this.content,
    required this.createdAt,
  });
}

class VerifiedClaim {
  final String claimerPubkey;
  final String meetup;
  final int verifiedBadgeCount;
  final int uniqueSignerCount;
  final int claimedAt;

  VerifiedClaim({
    required this.claimerPubkey,
    required this.meetup,
    required this.verifiedBadgeCount,
    required this.uniqueSignerCount,
    required this.claimedAt,
  });

  Map<String, dynamic> toJson() => {
        'claimer_pubkey': claimerPubkey,
        'meetup': meetup,
        'verified_badges': verifiedBadgeCount,
        'unique_signers': uniqueSignerCount,
        'claimed_at': claimedAt,
        'organic': true,
      };

  factory VerifiedClaim.fromJson(Map<String, dynamic> j) => VerifiedClaim(
        claimerPubkey: j['claimer_pubkey'] as String? ?? '',
        meetup: j['meetup'] as String? ?? '',
        verifiedBadgeCount: j['verified_badges'] as int? ?? 0,
        uniqueSignerCount: j['unique_signers'] as int? ?? 0,
        claimedAt: j['claimed_at'] as int? ?? 0,
      );
}


