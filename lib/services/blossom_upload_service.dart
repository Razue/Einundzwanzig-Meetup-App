// BILD-UPLOAD — Blossom (BUD-02)
// ============================================
// Warum das noetig ist: Das Event-Badge-Bild steht als URL im Kalender-Event
// auf den Relays. Jeder, der das Badge sieht, muss das Bild laden koennen —
// ein Pfad aus der Handy-Galerie waere auf jedem anderen Geraet wertlos.
// (Das Profilbild der App darf lokal bleiben; es sieht ja nur der Besitzer.)
//
// Blossom passt hier besser als ein klassischer Bilderdienst:
//   - Anmeldung per Nostr-Signatur, kein Konto, kein Passwort
//   - Adressierung ueber den SHA-256 des Bildes -> dieselbe Datei hat auf
//     jedem Server dieselbe Kennung, ein Ausweichserver ist moeglich
//   - offene Spezifikation, mehrere unabhaengige Anbieter
//
// Ablauf (BUD-02):
//   1. SHA-256 der Datei berechnen
//   2. kind 24242 signieren: ['t','upload'], ['x','<sha256>'], ['expiration',…]
//   3. PUT /upload mit den Rohbytes, Header  Authorization: Nostr <base64>
//   4. Antwort enthaelt {url: "https://…/<sha256>.jpg"}
// ============================================

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'app_logger.dart';
import 'signing_service.dart';

const String _tag = 'Blossom';

class UploadResult {
  final String? url;
  final String? error;

  const UploadResult.success(this.url) : error = null;
  const UploadResult.failure(this.error) : url = null;

  bool get ok => url != null && url!.isNotEmpty;
}

class BlossomUploadService {
  BlossomUploadService._();

  /// Server werden der Reihe nach versucht. Der erste, der annimmt, gewinnt.
  ///
  /// Mehrere, weil ein einzelner Anbieter ausfallen, drosseln oder seine
  /// Bedingungen aendern kann — und ein Event ohne Bild ist aergerlicher als
  /// ein zweiter Versuch. Alle drei nehmen Uploads ohne Konto an; die
  /// kostenlose Obergrenze liegt bei rund 20 MiB, unsere Bilder sind Bruchteile
  /// davon.
  static const List<String> servers = [
    'https://blossom.band',
    'https://blossom.primal.net',
    'https://blossom.nostr.build',
  ];

  static const Duration _timeout = Duration(seconds: 45);

  /// Erlaubte Dateiendungen samt MIME-Typ. Bewusst knapp: Ein Badge-Bild ist
  /// ein Bild, und je weniger Typen ein Server annehmen muss, desto weniger
  /// geht schief.
  static const Map<String, String> _mimeByExt = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
  };

  static String _mimeFor(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return 'application/octet-stream';
    final ext = path.substring(dot + 1).toLowerCase();
    return _mimeByExt[ext] ?? 'application/octet-stream';
  }

  /// Laedt eine lokale Bilddatei hoch und gibt die oeffentliche URL zurueck.
  static Future<UploadResult> uploadImage(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      return const UploadResult.failure('Datei nicht gefunden');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return const UploadResult.failure('Datei ist leer');

    final digest = sha256.convert(bytes).toString();
    final mime = _mimeFor(localPath);
    AppLogger.debug(_tag,
        'Upload vorbereitet: ${bytes.length} Bytes, $mime, sha256 ${digest.substring(0, 12)}…');

    // Anmeldung EINMAL signieren und fuer alle Server wiederverwenden: Sie
    // haengt nur am Bild-Hash, nicht am Ziel. Bei Amber oder einem
    // entfernten Signierer waere jede weitere Signatur sonst eine weitere
    // Rueckfrage beim Nutzer.
    final String authHeader;
    try {
      final signed = await SigningService.signEvent(
        kind: 24242,
        content: 'Bild fuer ein Einundzwanzig-Event-Badge',
        tags: [
          ['t', 'upload'],
          ['x', digest],
          [
            'expiration',
            '${DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000}'
          ],
        ],
      );
      authHeader =
          'Nostr ${base64.encode(utf8.encode(jsonEncode(signed.toJson())))}';
    } catch (e) {
      AppLogger.warn(_tag, 'Anmeldung konnte nicht signiert werden', e);
      return const UploadResult.failure('Signieren fehlgeschlagen');
    }

    String? lastError;
    for (final server in servers) {
      try {
        final resp = await http
            .put(
              Uri.parse('$server/upload'),
              headers: {
                'Authorization': authHeader,
                'Content-Type': mime,
              },
              body: bytes,
            )
            .timeout(_timeout);

        if (resp.statusCode == 200 || resp.statusCode == 201) {
          final json = jsonDecode(resp.body) as Map<String, dynamic>;
          final url = (json['url'] ?? '').toString();
          if (url.isNotEmpty) {
            AppLogger.debug(_tag, 'Upload bei $server erfolgreich: $url');
            return UploadResult.success(url);
          }
          lastError = 'Antwort ohne URL';
        } else {
          // Die Fehlermeldung steckt bei Blossom im X-Reason-Header.
          lastError = resp.headers['x-reason'] ?? 'HTTP ${resp.statusCode}';
        }
        AppLogger.debug(_tag, '$server abgelehnt: $lastError');
      } catch (e) {
        lastError = e.toString();
        AppLogger.debug(_tag, '$server nicht erreichbar: $e');
      }
    }

    return UploadResult.failure(lastError ?? 'Kein Server erreichbar');
  }
}
