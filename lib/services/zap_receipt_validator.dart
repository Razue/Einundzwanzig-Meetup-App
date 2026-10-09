// ============================================
// ZAP RECEIPT VALIDATOR — Echtheit von Zap-Quittungen (Security Audit H3)
// ============================================
//
// Eine Zap-Quittung (Kind 9735) wird vom LNURL-Server des EMPFÄNGERS
// erstellt, nicht vom Zahler. Bisher galt jede Quittung mit passendem
// p-Tag als Beweis — ein Angreifer konnte sich also mit einem beliebigen
// Schlüssel selbst "Quittungen" ausstellen und damit den Proof of
// Humanity und die Zap-Statistik füttern.
//
// Geprüft wird jetzt (NIP-57, Anhang F):
//   1. Signatur der Quittung selbst
//   2. description-Tag = gültig signierter Zap-Request (Kind 9734)
//   3. p-Tag der Quittung == p-Tag des Zap-Requests
//   4. bolt11: Description-Hash (Tag 'h') == sha256(description)
//      → die Rechnung gehört wirklich zu diesem Zap-Request
//   5. (Netz, gecacht) Pubkey der Quittung == nostrPubkey des
//      LNURL-Providers des Empfängers (lud16 → /.well-known/lnurlp)
//
// Schritt 1–4 laufen ohne Netz in [checkLocal], Schritt 5 in
// [isFromRecipientProvider].
// ============================================

import 'dart:convert';
import 'package:bech32/bech32.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';
import 'news_zap_service.dart';
import 'relay_socket.dart';

class ZapReceiptCheck {
  final bool ok;
  final String reason;
  final String recipientPubkey;
  final String senderPubkey;
  final String receiptPubkey;

  const ZapReceiptCheck._({
    required this.ok,
    required this.reason,
    this.recipientPubkey = '',
    this.senderPubkey = '',
    this.receiptPubkey = '',
  });

  factory ZapReceiptCheck.fail(String reason) =>
      ZapReceiptCheck._(ok: false, reason: reason);
}

class ZapReceiptValidator {
  static const String _tag = 'ZapReceipt';
  static const String _cachePrefix = 'zap_provider_pubkey_';
  static const Duration _cacheTtl = Duration(days: 7);
  static const Duration _httpTimeout = Duration(seconds: 6);
  static const int _maxBodyBytes = 64 * 1024;

  /// Speicher-Cache: Empfänger-Pubkey → Provider-Pubkey ('' = keiner).
  static final Map<String, String> _providerCache = {};

  // ===========================================================
  // LOKALE PRÜFUNG (ohne Netz)
  // ===========================================================

  static ZapReceiptCheck checkLocal(Map<String, dynamic> receipt) {
    if (receipt['kind'] != 9735) return ZapReceiptCheck.fail('kind');
    if (RelaySocket.verifiedEvent(receipt, tag: _tag) == null) {
      return ZapReceiptCheck.fail('receipt_sig');
    }

    String p = '';
    String bolt11 = '';
    String description = '';
    for (final tag in (receipt['tags'] as List<dynamic>? ?? const [])) {
      if (tag is! List || tag.length < 2) continue;
      final key = tag[0].toString();
      final val = tag[1].toString();
      if (key == 'p' && p.isEmpty) {
        p = val;
      } else if (key == 'bolt11' && bolt11.isEmpty) {
        bolt11 = val;
      } else if (key == 'description' && description.isEmpty) {
        description = val;
      }
    }
    if (p.isEmpty || bolt11.isEmpty || description.isEmpty) {
      return ZapReceiptCheck.fail('tags');
    }

    // 2. Zap-Request: signiert und Kind 9734
    Map<String, dynamic> zapReq;
    try {
      zapReq = jsonDecode(description) as Map<String, dynamic>;
    } catch (_) {
      return ZapReceiptCheck.fail('description_json');
    }
    if (zapReq['kind'] != 9734) return ZapReceiptCheck.fail('request_kind');
    if (RelaySocket.verifiedEvent(zapReq, tag: _tag) == null) {
      return ZapReceiptCheck.fail('request_sig');
    }

    // 3. Empfänger stimmt überein
    String reqP = '';
    for (final tag in (zapReq['tags'] as List<dynamic>? ?? const [])) {
      if (tag is List && tag.length >= 2 && tag[0] == 'p') {
        reqP = tag[1].toString();
        break;
      }
    }
    if (reqP.isEmpty || reqP != p) return ZapReceiptCheck.fail('recipient_mismatch');

    // 4. bolt11 gehört zu genau diesem Zap-Request
    final h = descriptionHashOf(bolt11);
    if (h == null) return ZapReceiptCheck.fail('bolt11');
    final expected = sha256.convert(utf8.encode(description)).toString();
    if (h != expected) return ZapReceiptCheck.fail('description_hash');

    return ZapReceiptCheck._(
      ok: true,
      reason: 'ok',
      recipientPubkey: p,
      senderPubkey: (zapReq['pubkey'] ?? '').toString(),
      receiptPubkey: (receipt['pubkey'] ?? '').toString(),
    );
  }

  /// Description-Hash (Tagged Field 'h', Typ 23) einer bolt11-Rechnung als
  /// Hex. null, wenn die Rechnung nicht dekodierbar ist oder kein 'h' trägt.
  static String? descriptionHashOf(String bolt11) {
    try {
      final decoded = Bech32Decoder().convert(bolt11.trim(), 4096);
      if (!decoded.hrp.toLowerCase().startsWith('ln')) return null;
      final data = decoded.data;
      // 7 Gruppen Timestamp + Tagged Fields + 104 Gruppen Signatur
      const sigWords = 104;
      if (data.length < 7 + sigWords) return null;
      var i = 7;
      final end = data.length - sigWords;
      while (i + 3 <= end) {
        final type = data[i];
        final len = (data[i + 1] << 5) | data[i + 2];
        i += 3;
        if (i + len > end) return null;
        if (type == 23 && len == 52) {
          final bytes = _convertBits(data.sublist(i, i + len), 5, 8);
          if (bytes.length < 32) return null;
          return bytes
              .sublist(0, 32)
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join();
        }
        i += len;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static List<int> _convertBits(List<int> input, int from, int to) {
    var acc = 0;
    var bits = 0;
    final out = <int>[];
    final maxv = (1 << to) - 1;
    for (final v in input) {
      acc = (acc << from) | v;
      bits += from;
      while (bits >= to) {
        bits -= to;
        out.add((acc >> bits) & maxv);
      }
    }
    return out;
  }

  // ===========================================================
  // PROVIDER-ABGLEICH (Netz, gecacht)
  // ===========================================================

  /// Stammt die Quittung vom LNURL-Provider des Empfängers?
  /// false auch dann, wenn der Provider nicht ermittelbar ist — eine
  /// Quittung ohne nachprüfbaren Aussteller zählt nicht.
  static Future<bool> isFromRecipientProvider({
    required String receiptPubkey,
    required String recipientPubkey,
  }) async {
    if (receiptPubkey.isEmpty || recipientPubkey.isEmpty) return false;
    final provider = await providerPubkeyFor(recipientPubkey);
    if (provider == null || provider.isEmpty) {
      AppLogger.debug(_tag,
          'Kein LNURL-Provider für ${recipientPubkey.substring(0, 8)}… ermittelbar — Quittung zählt nicht');
      return false;
    }
    return provider.toLowerCase() == receiptPubkey.toLowerCase();
  }

  /// nostrPubkey des LNURL-Providers hinter der lud16 des Empfängers.
  /// Ergebnis (auch "keiner") wird 7 Tage gecacht.
  static Future<String?> providerPubkeyFor(String recipientPubkey) async {
    final mem = _providerCache[recipientPubkey];
    if (mem != null) return mem.isEmpty ? null : mem;

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$recipientPubkey');
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        final ts = j['ts'] as int? ?? 0;
        if (DateTime.now().millisecondsSinceEpoch - ts < _cacheTtl.inMilliseconds) {
          final pk = (j['pk'] ?? '').toString();
          _providerCache[recipientPubkey] = pk;
          return pk.isEmpty ? null : pk;
        }
      }
    } catch (_) {}

    String pk = '';
    try {
      pk = await _resolveProvider(recipientPubkey) ?? '';
    } catch (e) {
      AppLogger.debug(_tag, 'Provider-Auflösung fehlgeschlagen: $e');
    }
    _providerCache[recipientPubkey] = pk;
    try {
      await prefs?.setString('$_cachePrefix$recipientPubkey',
          jsonEncode({'pk': pk, 'ts': DateTime.now().millisecondsSinceEpoch}));
    } catch (_) {}
    return pk.isEmpty ? null : pk;
  }

  static Future<String?> _resolveProvider(String recipientPubkey) async {
    final lud16 = await NewsZapService.fetchLightningAddress(recipientPubkey);
    if (lud16 == null || !lud16.contains('@')) return null;
    final parts = lud16.split('@');
    if (parts.length != 2) return null;
    final user = parts[0].trim();
    final domain = parts[1].trim().toLowerCase();
    if (user.isEmpty || domain.isEmpty || !RegExp(r'^[a-z0-9.-]+$').hasMatch(domain)) {
      return null;
    }
    return providerPubkeyFromLnurlp(
        Uri.parse('https://$domain/.well-known/lnurlp/$user'));
  }

  /// Liest nostrPubkey aus der LNURL-Pay-Metadatenantwort.
  static Future<String?> providerPubkeyFromLnurlp(Uri url) async {
    final resp = await http.get(url).timeout(_httpTimeout);
    if (resp.statusCode != 200) return null;
    if (resp.bodyBytes.length > _maxBodyBytes) return null;
    final meta = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    if (meta['allowsNostr'] != true) return null;
    final pk = (meta['nostrPubkey'] ?? '').toString().toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(pk)) return null;
    return pk;
  }
}
