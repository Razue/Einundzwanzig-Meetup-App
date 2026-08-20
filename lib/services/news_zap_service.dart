// ARTIKEL-ZAPS — Sats an den Autor (NIP-57)
// ============================================
// Ablauf eines Zaps:
//   1. Profil des Autors (kind 0) holen -> lud16 (Lightning-Adresse)
//   2. https://<domain>/.well-known/lnurlp/<name>  -> callback + Grenzen
//   3. kind 9734 (Zap-Anfrage) bauen und SIGNIEREN
//   4. <callback>?amount=<msat>&nostr=<zap-anfrage>  -> {pr: "<bolt11>"}
//   5. bolt11 per lightning:-URI an eine Wallet uebergeben
//
// Schritt 3 ist der ganze Unterschied zu einer gewoehnlichen LNURL-Zahlung
// (V4VService): Erst die signierte Zap-Anfrage macht daraus einen Zap, den
// das Netzwerk dem Artikel zuordnen kann — der LNURL-Server veroeffentlicht
// danach einen Zap-Beleg (kind 9735) mit ebendieser Anfrage darin.
//
// Bewusst NUR lud16 (die Adressform wie markus@einundzwanzig.space).
// lud06 waere eine bech32-kodierte LNURL und braeuchte einen eigenen
// Dekodierer; wer sie hinterlegt hat, bekommt eine klare Meldung statt
// eines stillen Fehlschlags.
// ============================================

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_logger.dart';
import 'news_reactions_service.dart';
import 'relay_socket.dart';
import 'signing_service.dart';

const String _tag = 'NewsZap';

/// Warum ein Zap nicht zustande kam. Ein eigener Typ statt einer Textmeldung,
/// damit die Oberflaeche uebersetzen kann, statt englische Serverantworten
/// durchzureichen.
enum ZapError {
  noLightningAddress,
  unsupportedAddress,
  lnurlUnreachable,
  amountOutOfRange,
  signingFailed,
  invoiceFailed,
}

class ZapResult {
  final String? invoice; // bolt11
  final ZapError? error;

  const ZapResult.success(this.invoice) : error = null;
  const ZapResult.failure(this.error) : invoice = null;

  bool get ok => invoice != null;
}

class NewsZapService {
  NewsZapService._();

  static const Duration _httpTimeout = Duration(seconds: 12);
  static const Duration _relayTimeout = Duration(seconds: 6);

  /// Holt die Lightning-Adresse (lud16) des Autors aus seinem Profil.
  ///
  /// Gibt null zurueck, wenn keine hinterlegt ist — dann kann man den
  /// Autor schlicht nicht zappen, und der Knopf bleibt ausgegraut.
  static Future<String?> fetchLightningAddress(String pubkeyHex) async {
    if (pubkeyHex.isEmpty) return null;

    final targets = await NewsReactionsService.readTargets();
    String? found;
    final sockets = <RelaySocket>[];
    final done = Completer<void>();
    var settled = false;

    void finish() {
      if (settled) return;
      settled = true;
      for (final ws in sockets) {
        try {
          ws.close();
        } catch (_) {}
      }
      if (!done.isCompleted) done.complete();
    }

    Timer(_relayTimeout, finish);

    for (final url in targets) {
      () async {
        try {
          final ws = await RelaySocket.connect(url)
              .timeout(const Duration(seconds: 4));
          if (settled) {
            try {
              ws.close();
            } catch (_) {}
            return;
          }
          sockets.add(ws);
          ws.add(jsonEncode([
            'REQ',
            'zapmeta',
            {
              'kinds': [0],
              'authors': [pubkeyHex],
              'limit': 1,
            }
          ]));
          ws.listen((data) {
            try {
              final msg = jsonDecode(data as String) as List<dynamic>;
              if (msg.length < 3 || msg[0] != 'EVENT') return;
              final event = msg[2] as Map<String, dynamic>;
              final profile =
                  jsonDecode((event['content'] ?? '{}').toString())
                      as Map<String, dynamic>;
              final lud16 = (profile['lud16'] ?? '').toString().trim();
              if (lud16.contains('@')) {
                found = lud16;
                finish();
              } else if ((profile['lud06'] ?? '').toString().isNotEmpty &&
                  found == null) {
                // Merken, damit die Oberflaeche "nicht unterstuetzt" statt
                // "keine Adresse" melden kann.
                found = 'lud06:';
              }
            } catch (_) {}
          }, onError: (_) {}, onDone: () {});
        } catch (_) {
          // Relay nicht erreichbar — die anderen laufen weiter.
        }
      }();
    }

    await done.future;
    AppLogger.debug(_tag,
        'Lightning-Adresse fuer ${pubkeyHex.substring(0, 8)}…: ${found ?? "keine"}');
    return found;
  }

  /// Baut eine Zap-Rechnung fuer einen Artikel.
  static Future<ZapResult> createZapInvoice({
    required String authorPubkey,
    required String articleAddress,
    required int amountSats,
    String? comment,
  }) async {
    if (amountSats <= 0) return const ZapResult.failure(ZapError.amountOutOfRange);

    final address = await fetchLightningAddress(authorPubkey);
    if (address == null) {
      return const ZapResult.failure(ZapError.noLightningAddress);
    }
    if (!address.contains('@')) {
      return const ZapResult.failure(ZapError.unsupportedAddress);
    }

    final parts = address.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return const ZapResult.failure(ZapError.unsupportedAddress);
    }
    final user = parts[0];
    final domain = parts[1];

    // --- Schritt 2: LNURL-pay-Metadaten ---
    final Map<String, dynamic> meta;
    try {
      final resp = await http
          .get(Uri.parse('https://$domain/.well-known/lnurlp/$user'))
          .timeout(_httpTimeout);
      if (resp.statusCode != 200) {
        AppLogger.debug(_tag, 'lnurlp HTTP ${resp.statusCode}');
        return const ZapResult.failure(ZapError.lnurlUnreachable);
      }
      meta = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.warn(_tag, 'lnurlp nicht erreichbar', e);
      return const ZapResult.failure(ZapError.lnurlUnreachable);
    }

    if ((meta['tag'] ?? '') != 'payRequest' || meta['callback'] == null) {
      return const ZapResult.failure(ZapError.lnurlUnreachable);
    }

    final amountMsat = amountSats * 1000;
    final min = (meta['minSendable'] as num?)?.toInt() ?? 1000;
    final max = (meta['maxSendable'] as num?)?.toInt() ?? 100000000000;
    if (amountMsat < min || amountMsat > max) {
      AppLogger.debug(_tag,
          'Betrag $amountMsat msat ausserhalb von $min..$max');
      return const ZapResult.failure(ZapError.amountOutOfRange);
    }

    // Unterstuetzt der Server ueberhaupt Zaps? Wenn nicht, waere es eine
    // gewoehnliche Zahlung ohne Beleg — das sagen wir lieber offen.
    final allowsNostr = meta['allowsNostr'] == true;

    // --- Schritt 3: Zap-Anfrage signieren ---
    String? zapRequestJson;
    if (allowsNostr) {
      try {
        final signed = await SigningService.signEvent(
          kind: 9734,
          content: comment ?? '',
          tags: [
            ['relays', ...NewsReactionsService.newsRelays],
            ['amount', '$amountMsat'],
            ['p', authorPubkey],
            ['a', articleAddress],
          ],
        );
        zapRequestJson = jsonEncode(signed.toJson());
      } catch (e) {
        AppLogger.warn(_tag, 'Zap-Anfrage konnte nicht signiert werden', e);
        return const ZapResult.failure(ZapError.signingFailed);
      }
    }

    // --- Schritt 4: Rechnung abrufen ---
    try {
      final callback = meta['callback'].toString();
      final sep = callback.contains('?') ? '&' : '?';
      var url = '$callback${sep}amount=$amountMsat';
      if (zapRequestJson != null) {
        url += '&nostr=${Uri.encodeQueryComponent(zapRequestJson)}';
      } else if (comment != null && comment.isNotEmpty) {
        // Ohne Zap-Unterstuetzung wenigstens den Kommentar mitgeben, sofern
        // der Server ihn annimmt.
        final maxComment = (meta['commentAllowed'] as num?)?.toInt() ?? 0;
        if (maxComment > 0) {
          final c = comment.length > maxComment
              ? comment.substring(0, maxComment)
              : comment;
          url += '&comment=${Uri.encodeQueryComponent(c)}';
        }
      }

      final resp = await http.get(Uri.parse(url)).timeout(_httpTimeout);
      if (resp.statusCode != 200) {
        AppLogger.debug(_tag, 'callback HTTP ${resp.statusCode}');
        return const ZapResult.failure(ZapError.invoiceFailed);
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final pr = (json['pr'] ?? '').toString();
      if (pr.isEmpty) {
        AppLogger.debug(_tag, 'callback ohne pr: ${json['reason'] ?? json}');
        return const ZapResult.failure(ZapError.invoiceFailed);
      }
      AppLogger.debug(_tag,
          'Zap-Rechnung ueber $amountSats sat erstellt (Zaps unterstuetzt: $allowsNostr)');
      return ZapResult.success(pr);
    } catch (e) {
      AppLogger.warn(_tag, 'Rechnung konnte nicht abgerufen werden', e);
      return const ZapResult.failure(ZapError.invoiceFailed);
    }
  }
}
