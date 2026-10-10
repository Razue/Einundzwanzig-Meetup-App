// ============================================
// SAFE URL LAUNCHER — Schema-Whitelist für externe Links (Security Audit M2)
// ============================================
// Links aus fremden Inhalten (Markdown, Kalender-Events, Chat, Portal-
// Daten) dürfen nur http(s) öffnen. javascript:, file:, intent:, tel:,
// sms: und beliebige App-Schemata werden abgelehnt — ein manipuliertes
// Kalender-Event kann so keine fremde App oder Systemfunktion aufrufen.
//
// Eigene, fest verdrahtete Schemata (nostr:, nostrsigner:, bunker://)
// laufen bewusst NICHT hier durch; sie stehen im Code als Konstanten.
// ============================================

import 'package:url_launcher/url_launcher.dart';

/// Öffnet [url] extern, falls es eine http(s)-Adresse mit Host ist.
/// Liefert false bei fremdem Schema, kaputter URL oder Fehlschlag.
Future<bool> launchHttpUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  return launchHttpUri(uri);
}

/// Wie [launchHttpUrl], für bereits geparste URIs.
Future<bool> launchHttpUri(Uri uri) async {
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;
  if (uri.host.isEmpty) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
