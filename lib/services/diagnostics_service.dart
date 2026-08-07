// ============================================
// DIAGNOSTICS — Umgebungs-Steckbrief beim App-Start
// ============================================
//
// WARUM ES DAS GIBT (Feldtest Juli 2026):
// Ein Teilnehmer konnte auf einem Pixel mit GrapheneOS kein Badge sammeln,
// obwohl Standort aktiviert und freigegeben war — auf Xiaomi-Geraeten lief
// alles. Bis die Ursache (fehlende Netzwerkortung ohne Google Play Services)
// gefunden war, vergingen viele Runden, weil das Log nichts ueber das GERAET
// sagte. Ein Bugreport ohne Umgebungsangaben ist halb wertlos.
//
// Diese Zeilen stehen deshalb ab sofort ganz oben in jedem geteilten Log.
// Es werden bewusst KEINE personenbezogenen Daten erfasst: kein npub, keine
// Schluessel, keine Koordinaten, keine Namen — nur technische Rahmendaten.
// ============================================

import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/badge.dart';
import '../models/user.dart';
import 'app_logger.dart';
import 'signing_service.dart';

class DiagnosticsService {
  DiagnosticsService._();

  static const String _tag = 'System';

  /// Schreibt den Umgebungs-Steckbrief ins Diagnose-Log.
  /// Best effort: Jeder Einzelpunkt ist gekapselt, damit ein fehlender
  /// Wert nie den App-Start behindert.
  static Future<void> logEnvironment() async {
    AppLogger.section('APP-START');

    // ---- App-Version ----
    try {
      final info = await PackageInfo.fromPlatform();
      AppLogger.info(_tag, 'App ${info.version} (Build ${info.buildNumber})');
    } catch (e) {
      AppLogger.warn(_tag, 'App-Version nicht lesbar', e);
    }

    // ---- Plattform ----
    try {
      AppLogger.info(_tag,
          'System: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      final off = DateTime.now().timeZoneOffset;
      AppLogger.info(_tag,
          'Sprache ${Platform.localeName} · Zeitzone ${DateTime.now().timeZoneName} '
          '(UTC${off.isNegative ? "-" : "+"}${off.inHours.abs()})');
    } catch (e) {
      AppLogger.warn(_tag, 'Plattformdaten nicht lesbar', e);
    }

    // ---- Standort-Faehigkeit ----
    // Ohne Nutzerabfrage: beide Aufrufe loesen KEINEN Berechtigungsdialog aus.
    // Genau diese zwei Zeilen haetten den GrapheneOS-Fall sofort eingegrenzt.
    try {
      final service = await Geolocator.isLocationServiceEnabled();
      final perm = await Geolocator.checkPermission();
      AppLogger.info(_tag,
          'Standort: Dienst ${service ? "AN" : "AUS"} · Berechtigung ${perm.name}');
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) {
        // Starker Hinweis auf ein Geraet ohne Netzwerkortung: Dort gibt es
        // ohne echten Satellitenfix nie eine "letzte bekannte Position".
        AppLogger.warn(_tag,
            'Keine letzte bekannte Position vorhanden — auf Geraeten ohne '
            'Netzwerkortung (z.B. ohne Google Play Services) kann die Ortung '
            'in Gebaeuden fehlschlagen.');
      } else {
        final age = DateTime.now().difference(last.timestamp);
        AppLogger.info(_tag,
            'Letzte bekannte Position ist ${age.inMinutes} Min alt '
            '(Genauigkeit ${last.accuracy.toStringAsFixed(0)} m)');
      }
    } catch (e) {
      AppLogger.warn(_tag, 'Standort-Status nicht ermittelbar', e);
    }

    // ---- NFC ----
    try {
      final avail = await NfcManager.instance.checkAvailability();
      AppLogger.info(_tag, 'NFC: ${avail.name}');
    } catch (e) {
      AppLogger.warn(_tag, 'NFC-Status nicht ermittelbar', e);
    }

    // ---- Identitaet (ohne Schluessel!) ----
    try {
      final mode = await SigningService.getMode();
      AppLogger.info(_tag, 'Signatur-Modus: ${mode.name}');
    } catch (e) {
      AppLogger.warn(_tag, 'Signatur-Modus nicht lesbar', e);
    }

    // ---- Datenbestand ----
    try {
      final badges = await MeetupBadge.loadBadges();
      final user = await UserProfile.load();
      AppLogger.info(_tag,
          'Bestand: ${badges.length} Badge(s) · ${user.favoriteMeetupIds.length} Favorit(en)');
    } catch (e) {
      AppLogger.warn(_tag, 'Datenbestand nicht lesbar', e);
    }

    if (AppLogger.isVerbose) {
      AppLogger.info(_tag, 'Ausfuehrliches Log ist AKTIV.');
    }
  }
}
