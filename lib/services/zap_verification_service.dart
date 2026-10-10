// ============================================
// ZAP VERIFICATION SERVICE — Lightning-Beweis
// ============================================
// Analysiert Lightning-Aktivität über Nostr Zaps:
//
//   1. Zap-Receipts abrufen (Kind 9735, NIP-57)
//   2. Gesendete + empfangene Zaps zählen
//   3. Zap-Diversität messen (verschiedene Empfänger/Sender)
//   4. Zeitliche Verteilung prüfen (Aktivitätszeitraum)
//
// Anti-Bot-Wirkung:
//   - Zaps kosten echtes Geld (Sats)
//   - Bot müsste über Monate Geld verbrennen
//   - Zap-Diversität verhindert Self-Zapping
//   - Empfangene Zaps = externe Bestätigung
//
// Privacy:
//   - Nur Anzahlen werden publiziert
//   - KEINE Beträge, Empfänger, Sender
//   - Zeitraum nur als "seit Monat/Jahr"
//
// Zap-Struktur (NIP-57):
//   Kind 9735 = Zap Receipt (vom LNURL-Server erstellt)
//   Tags: ["p", recipient_pubkey], ["e", zapped_event_id]
//         ["bolt11", invoice], ["description", zap_request_json]
//   Die "description" enthält den Original Zap-Request (Kind 9734)
//   mit dem Sender-Pubkey.
// ============================================

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'relay_config.dart';
import 'nostr_service.dart';
import 'dart:math';
import 'app_logger.dart';
import 'relay_socket.dart';
import 'zap_receipt_validator.dart';

class ZapVerificationService {
  // Cache
  static const String _cacheKeyStats = 'zap_stats_cache';
  static const String _cacheKeyTimestamp = 'zap_cache_ts';
  static const Duration _cacheDuration = Duration(hours: 6);

  // Zeitfenster für Zap-Analyse (6 Monate)
  static const Duration _analysisWindow = Duration(days: 180);

  // =============================================
  // ZAP-AKTIVITÄT EINES NUTZERS ANALYSIEREN
  // =============================================

  static Future<ZapStats> analyzeZapActivity(
    String pubkeyHex, {
    bool useCache = true,
  }) async {
    // Cache prüfen (nur für eigenen pubkey)
    if (useCache) {
      final cached = await _loadCachedStats(pubkeyHex);
      if (cached != null) return cached;
    }

    final relays = await RelayConfig.getActiveRelays();

    // Parallel: Empfangene + gesendete Zaps abrufen
    final receivedFuture = _fetchZapReceipts(relays, pubkeyHex, isReceived: true);
    final sentFuture = _fetchZapReceipts(relays, pubkeyHex, isReceived: false);

    final received = await receivedFuture;
    final sent = await sentFuture;

    final stats = _computeStats(pubkeyHex, received, sent);

    // Cache speichern
    await _cacheStats(pubkeyHex, stats);
    return stats;
  }

  // =============================================
  // ZAP RECEIPTS VON RELAYS ABRUFEN
  // =============================================
  // isReceived=true:  Zaps die an pubkey gerichtet sind (#p Tag)
  // isReceived=false: Zaps die von pubkey gesendet wurden
  //                   (Sender steht im description/zap_request)
  // =============================================

  static Future<List<ZapReceipt>> _fetchZapReceipts(
    List<String> relays,
    String pubkeyHex, {
    required bool isReceived,
  }) async {
    final since = DateTime.now().subtract(_analysisWindow).millisecondsSinceEpoch ~/ 1000;
    List<ZapReceipt> allReceipts = [];

    for (final relayUrl in relays.take(3)) { // Max 3 Relays für Performance
      try {
        final receipts = await _fetchFromRelay(relayUrl, pubkeyHex, since);
        // Deduplizieren anhand der Event-ID. Die Relay-Anfrage ist für
        // beide Richtungen dieselbe; hier bleibt nur die gefragte Seite.
        for (final receipt in receipts) {
          final wanted = isReceived ? receipt.isReceived : receipt.isSent;
          if (!wanted) continue;
          if (!allReceipts.any((r) => r.eventId == receipt.eventId)) {
            allReceipts.add(receipt);
          }
        }
        if (allReceipts.length >= 50) break; // Genug Daten
      } catch (e) {
        // Naechstes Relay. debug, weil ausgefallene Relays Alltag sind —
        // aber ohne diese Zeile war nicht zu unterscheiden, ob jemand keine
        // Zaps hat oder ob alle drei Relays nicht geantwortet haben.
        AppLogger.debug('ZapVerification', 'Zap-Abruf von $relayUrl fehlgeschlagen: $e');
      }
    }

    return _onlyFromProviders(allReceipts);
  }

  /// Security Audit H3: Behält nur Quittungen, deren Aussteller der
  /// LNURL-Provider des jeweiligen Empfängers ist (gecacht, max. 15
  /// verschiedene Empfänger pro Lauf).
  static Future<List<ZapReceipt>> _onlyFromProviders(List<ZapReceipt> receipts) async {
    final byRecipient = <String, List<ZapReceipt>>{};
    for (final r in receipts) {
      byRecipient.putIfAbsent(r.recipientPubkey, () => []).add(r);
    }
    final kept = <ZapReceipt>[];
    var lookups = 0;
    for (final entry in byRecipient.entries) {
      if (lookups++ >= 15) break;
      final provider = await ZapReceiptValidator.providerPubkeyFor(entry.key);
      if (provider == null) continue;
      kept.addAll(entry.value.where((r) {
        final receipt = r.receiptPubkey.toLowerCase();
        if (receipt == provider) {
          // Aussteller darf nicht der Zahler oder der Empfänger selbst sein.
          if (receipt == r.senderPubkey.toLowerCase()) return false;
          if (receipt == r.recipientPubkey.toLowerCase()) return false;
          return true;
        }
        return false;
      }));
    }
    if (kept.length != receipts.length) {
      AppLogger.debug('ZapVerification',
          '${receipts.length - kept.length} von ${receipts.length} Quittungen ohne Provider-Nachweis verworfen');
    }
    return kept;
  }

  static Future<List<ZapReceipt>> _fetchFromRelay(
    String relayUrl,
    String pubkeyHex,
    int since,
  ) async {
    RelaySocket? ws;
    final tally = RelayParseTally('ZapVerification', 'Zap-Belege von $relayUrl');
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(RelayConfig.relayTimeout);
      final completer = Completer<List<ZapReceipt>>();
      // Security Audit M4: Kryptographisch sichere Subscription-ID
      final random = Random.secure();
      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subId = 'zaps-$subIdHex';
      List<ZapReceipt> receipts = [];
      // Kind 9735. Empfangen: p-Tag ist der Empfänger. Gesendet steht der
      // Absender im description-Tag; '#P' können nicht alle Relays, deshalb
      // dieselbe p-Anfrage. _parseZapReceipt ordnet danach zu.
      final filter = <String, dynamic>{
        'kinds': [9735],
        'since': since,
        'limit': 100,
        '#p': [pubkeyHex],
      };

      ws.listen(
        (data) {
          tally.message();
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;

            if (type == 'EVENT' && message.length >= 3) {
              final eventData = RelaySocket.verifiedEvent(message[2], tag: 'ZapVerification');
              if (eventData == null ||
                  !RelaySocket.answersFilter(eventData, filter)) {
                return;
              }
              final receipt = _parseZapReceipt(eventData, pubkeyHex);
              if (receipt != null) {
                receipts.add(receipt);
              }
            } else if (type == 'EOSE') {
              if (!completer.isCompleted) completer.complete(receipts);
            }
          } catch (e) { tally.failed(e); }
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete([]);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(receipts);
        },
      );

      ws.add(jsonEncode(['REQ', subId, filter]));

      return await completer.future.timeout(
        RelayConfig.relayTimeout,
        onTimeout: () => receipts,
      );
    } finally {
      tally.report();
      ws?.close();
    }
  }

  // =============================================
  // ZAP RECEIPT PARSEN
  // =============================================

  static ZapReceipt? _parseZapReceipt(
    Map<String, dynamic> eventData,
    String contextPubkey,
  ) {
    try {
      final eventId = eventData['id'] as String? ?? '';
      final createdAt = eventData['created_at'] as int? ?? 0;

      // Security Audit H3: Signaturen, Zap-Request und bolt11-Description-
      // Hash müssen zusammenpassen — sonst zählt die Quittung nicht.
      final check = ZapReceiptValidator.checkLocal(eventData);
      if (!check.ok) return null;
      final recipientPubkey = check.recipientPubkey;
      final senderPubkey = check.senderPubkey;

      final isSent = senderPubkey == contextPubkey;
      final isReceived = recipientPubkey == contextPubkey;

      if (!isSent && !isReceived) return null;

      return ZapReceipt(
        eventId: eventId,
        senderPubkey: senderPubkey,
        recipientPubkey: recipientPubkey,
        createdAt: createdAt,
        isSent: isSent,
        isReceived: isReceived,
        hasBolt11: true, // checkLocal verlangt eine passende bolt11
        receiptPubkey: check.receiptPubkey,
      );
    } catch (e) {
      return null;
    }
  }

  // =============================================
  // STATISTIKEN BERECHNEN
  // =============================================

  static ZapStats _computeStats(
    String pubkeyHex,
    List<ZapReceipt> received,
    List<ZapReceipt> sent,
  ) {
    // Alle Receipts zusammenführen und deduplizieren
    final Map<String, ZapReceipt> allMap = {};
    for (final r in [...received, ...sent]) {
      allMap[r.eventId] = r;
    }
    final all = allMap.values.toList();

    // Gesendete Zaps (wo pubkey = sender)
    final sentZaps = all.where((r) => r.isSent).toList();

    // Empfangene Zaps (wo pubkey = recipient)
    final receivedZaps = all.where((r) => r.isReceived).toList();

    // Diversität: verschiedene Empfänger/Sender
    final uniqueRecipients = sentZaps.map((r) => r.recipientPubkey).toSet();
    final uniqueSenders = receivedZaps.map((r) => r.senderPubkey).where((s) => s.isNotEmpty).toSet();

    // Zeitliche Verteilung
    int? firstZapTimestamp;
    int? lastZapTimestamp;
    for (final zap in all) {
      if (zap.createdAt > 0) {
        firstZapTimestamp = firstZapTimestamp == null
            ? zap.createdAt
            : (zap.createdAt < firstZapTimestamp ? zap.createdAt : firstZapTimestamp);
        lastZapTimestamp = lastZapTimestamp == null
            ? zap.createdAt
            : (zap.createdAt > lastZapTimestamp ? zap.createdAt : lastZapTimestamp);
      }
    }

    final activeMonths = (firstZapTimestamp != null && lastZapTimestamp != null)
        ? ((lastZapTimestamp - firstZapTimestamp) / (30 * 24 * 3600)).ceil().clamp(0, 24)
        : 0;

    // Hat mindestens eine echte Lightning-Zahlung (Bolt11 vorhanden)?
    final hasLightningProof = all.any((r) => r.hasBolt11);

    return ZapStats(
      sentCount: sentZaps.length,
      receivedCount: receivedZaps.length,
      uniqueRecipientCount: uniqueRecipients.length,
      uniqueSenderCount: uniqueSenders.length,
      activeMonths: activeMonths,
      hasLightningProof: hasLightningProof,
    );
  }

  // =============================================
  // EIGENE ZAP-STATS ABRUFEN
  // =============================================

  static Future<ZapStats> getMyStats() async {
    final pubkeyHex = await _getMyPubkeyHex();
    if (pubkeyHex == null) return ZapStats.empty();
    return analyzeZapActivity(pubkeyHex);
  }

  // =============================================
  // CACHE
  // =============================================

  static Future<ZapStats?> _loadCachedStats(String pubkey) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('${_cacheKeyTimestamp}_$pubkey') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - ts > _cacheDuration.inMilliseconds) return null;

    final json = prefs.getString('${_cacheKeyStats}_$pubkey');
    if (json == null) return null;

    try {
      return ZapStats.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _cacheStats(String pubkey, ZapStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_cacheKeyStats}_$pubkey', jsonEncode(stats.toJson()));
    await prefs.setInt('${_cacheKeyTimestamp}_$pubkey', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<String?> _getMyPubkeyHex() async {
    final npub = await NostrService.getNpub();
    if (npub == null || npub.isEmpty) return null;
    try {
      return Nip19.decodePubkey(npub);
    } catch (e) {
      // Eigener npub nicht dekodierbar -> alle Zap-Zahlen bleiben 0, ohne
      // dass irgendwo ein Fehler sichtbar wird.
      AppLogger.warn('ZapVerification', 'Eigener npub nicht dekodierbar: $e');
      return null;
    }
  }
}

// =============================================
// DATENMODELLE
// =============================================

class ZapReceipt {
  final String eventId;
  final String senderPubkey;
  final String recipientPubkey;
  final int createdAt;
  final bool isSent;
  final bool isReceived;
  final bool hasBolt11;
  /// Aussteller der Quittung (LNURL-Server des Empfängers).
  final String receiptPubkey;

  ZapReceipt({
    required this.eventId,
    required this.senderPubkey,
    required this.recipientPubkey,
    required this.createdAt,
    required this.isSent,
    required this.isReceived,
    required this.hasBolt11,
    this.receiptPubkey = '',
  });
}

class ZapStats {
  final int sentCount;
  final int receivedCount;
  final int uniqueRecipientCount;
  final int uniqueSenderCount;
  final int activeMonths;
  final bool hasLightningProof;

  ZapStats({
    required this.sentCount,
    required this.receivedCount,
    required this.uniqueRecipientCount,
    required this.uniqueSenderCount,
    required this.activeMonths,
    required this.hasLightningProof,
  });

  factory ZapStats.empty() => ZapStats(
    sentCount: 0,
    receivedCount: 0,
    uniqueRecipientCount: 0,
    uniqueSenderCount: 0,
    activeMonths: 0,
    hasLightningProof: false,
  );

  factory ZapStats.fromJson(Map<String, dynamic> json) => ZapStats(
    sentCount: json['sent'] as int? ?? 0,
    receivedCount: json['received'] as int? ?? 0,
    uniqueRecipientCount: json['unique_recipients'] as int? ?? 0,
    uniqueSenderCount: json['unique_senders'] as int? ?? 0,
    activeMonths: json['active_months'] as int? ?? 0,
    hasLightningProof: json['lightning_proof'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'sent': sentCount,
    'received': receivedCount,
    'unique_recipients': uniqueRecipientCount,
    'unique_senders': uniqueSenderCount,
    'active_months': activeMonths,
    'lightning_proof': hasLightningProof,
  };

  int get totalCount => sentCount + receivedCount;

  /// Lightning Score (0.0 - 2.5)
  double get lightningScore {
    double score = 0;

    // Lightning-Zahlung verifiziert (Bolt11 vorhanden)
    if (hasLightningProof) score += 0.5;

    // Zap-Aktivität (gesendet)
    if (sentCount > 0) score += (sentCount / (sentCount + 10)) * 0.75;

    // Zap-Aktivität (empfangen = externe Bestätigung)
    if (receivedCount > 0) score += (receivedCount / (receivedCount + 10)) * 0.75;

    // Diversität (verschiedene Empfänger)
    if (uniqueRecipientCount > 2) score += 0.25;

    // Zeitliche Konsistenz
    if (activeMonths >= 3) score += 0.25;

    return score.clamp(0.0, 2.5);
  }

  String get activityLabel {
    if (totalCount == 0) return 'Keine Zap-Aktivität';
    if (totalCount < 5) return 'Wenig Aktivität';
    if (totalCount < 20) return 'Regelmäßig aktiv';
    return 'Sehr aktiv';
  }
}


