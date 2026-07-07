// ============================================
//  V4V — Value for Value (Lightning Address / LNURL-pay)
// ============================================
//  Holt aus einer Lightning-Adresse (user@domain) eine bezahlbare
//  bolt11-Invoice über den LNURL-pay-Standard (LUD-06/LUD-16):
//   1. GET https://<domain>/.well-known/lnurlp/<user>  -> callback + limits
//   2. GET <callback>?amount=<msat>                    -> {pr: "<bolt11>"}
//  Danach kann die Invoice per lightning:-URI in einer Wallet geöffnet
//  werden.
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/app_logger.dart';

/// Ziel-Lightning-Adresse für Spenden ans Projekt.
const String kV4VLightningAddress = 'wolpertinger1@breez.fun';

class V4VResult {
  final bool ok;
  final String? invoice; // bolt11
  final String? error;   // menschenlesbare Fehlermeldung (lokalisiert vom Aufrufer)
  const V4VResult.success(this.invoice) : ok = true, error = null;
  const V4VResult.failure(this.error) : ok = false, invoice = null;
}

class V4VService {
  static const Duration _timeout = Duration(seconds: 15);
  static const String _tag = 'V4VService';

  /// Erzeugt eine Invoice über die Lightning-Adresse für [amountSats].
  /// Optionaler [comment] wird mitgesendet, falls der Empfänger ihn erlaubt.
  static Future<V4VResult> createInvoice({
    required int amountSats,
    String address = kV4VLightningAddress,
    String? comment,
  }) async {
    if (amountSats <= 0) {
      return const V4VResult.failure('invalid_amount');
    }
    final parts = address.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return const V4VResult.failure('invalid_address');
    }
    final user = parts[0];
    final domain = parts[1];

    try {
      // Schritt 1: LNURL-pay-Metadaten holen
      final metaUrl = Uri.parse('https://$domain/.well-known/lnurlp/$user');
      final metaResp = await http.get(metaUrl).timeout(_timeout);
      if (metaResp.statusCode != 200) {
        AppLogger.debug(_tag, 'meta HTTP ${metaResp.statusCode}');
        return const V4VResult.failure('unreachable');
      }
      final meta = jsonDecode(metaResp.body) as Map<String, dynamic>;
      if ((meta['tag'] ?? '') != 'payRequest' || meta['callback'] == null) {
        return const V4VResult.failure('not_lnurlp');
      }

      final callback = meta['callback'].toString();
      final minSendable = (meta['minSendable'] as num?)?.toInt() ?? 1000; // msat
      final maxSendable = (meta['maxSendable'] as num?)?.toInt() ?? 100000000000;
      final commentAllowed = (meta['commentAllowed'] as num?)?.toInt() ?? 0;

      final amountMsat = amountSats * 1000;
      if (amountMsat < minSendable) {
        return const V4VResult.failure('below_min');
      }
      if (amountMsat > maxSendable) {
        return const V4VResult.failure('above_max');
      }

      // Schritt 2: Callback mit Betrag aufrufen -> Invoice
      final sep = callback.contains('?') ? '&' : '?';
      var callbackUrl = '$callback${sep}amount=$amountMsat';
      if (comment != null && comment.isNotEmpty && commentAllowed > 0) {
        final c = comment.length > commentAllowed
            ? comment.substring(0, commentAllowed)
            : comment;
        callbackUrl += '&comment=${Uri.encodeQueryComponent(c)}';
      }

      final invResp = await http.get(Uri.parse(callbackUrl)).timeout(_timeout);
      if (invResp.statusCode != 200) {
        AppLogger.debug(_tag, 'callback HTTP ${invResp.statusCode}');
        return const V4VResult.failure('invoice_failed');
      }
      final invJson = jsonDecode(invResp.body) as Map<String, dynamic>;
      if ((invJson['status'] ?? '').toString().toUpperCase() == 'ERROR') {
        return V4VResult.failure(invJson['reason']?.toString() ?? 'invoice_failed');
      }
      final pr = invJson['pr']?.toString();
      if (pr == null || pr.isEmpty) {
        return const V4VResult.failure('invoice_failed');
      }
      return V4VResult.success(pr);
    } catch (e) {
      AppLogger.debug(_tag, 'Fehler: $e');
      return const V4VResult.failure('unreachable');
    }
  }
}
