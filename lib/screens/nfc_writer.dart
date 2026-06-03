// ============================================
// NFC WRITER — KOMPAKT-FORMAT (passt auf NTAG215)
// ============================================
// Payload: ~285 Bytes (vorher 583B → passt jetzt!)
//
// Format: {"v":2,"t":"B","m":"city-cc","b":875432,
//          "x":expiry,"c":created,"p":"pubkey","s":"sig"}
//
// Features:
//   • Kompakt-Signatur (Schnorr, unfälschbar)
//   • 6h Ablaufzeit → Überschreibbar für nächstes Meetup
//   • Payload-Größe wird VOR dem Schreiben angezeigt
//   • Funktioniert mit NTAG213 (137B), 215 (492B), 216 (872B)
//   • NFC-Simulation ENTFERNT — kein Fake-Schreiben mehr möglich.
// ============================================

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';            // NfcManager, NfcTag, NfcPollingOption, NfcAvailability
import 'package:nfc_manager/ndef_record.dart';              // NdefRecord, NdefMessage, TypeNameFormat
import 'package:nfc_manager/nfc_manager_android.dart';      // NdefFormatableAndroid
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';    // Ndef (cross-platform)
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../services/meetup_service.dart';
import '../services/badge_security.dart';
import '../services/rolling_qr_service.dart';
// NEU: Import für den QR-Screen, um nach Erfolg dorthin zu springen
import 'rolling_qr_screen.dart';
import '../services/app_logger.dart';

class NFCWriterScreen extends StatefulWidget {
  const NFCWriterScreen({super.key});

  @override
  State<NFCWriterScreen> createState() => _NFCWriterScreenState();
}

class _NFCWriterScreenState extends State<NFCWriterScreen> with SingleTickerProviderStateMixin {
  bool _success = false;
  String? _statusText;
  Meetup? _homeMeetup;
  String _meetupInfo = "";
  int _payloadSize = 0;
  
  // THE FIX: Sperre, damit das Handy nicht mehrfach schreibt/vibriert
  bool _isProcessingTag = false; 
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadHomeMeetup();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _statusText ??= AppLocalizations.of(context).writerReadyToWrite;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadHomeMeetup() async {
    final user = await UserProfile.load();
    
    if (user.homeMeetupId.isEmpty) {
      setState(() {
        _statusText = AppLocalizations.of(context).writerNoHomeMeetup;
        _meetupInfo = AppLocalizations.of(context).writerSelectHomeFirst;
      });
      return;
    }

    List<Meetup> meetups = await MeetupService.fetchMeetups();
    if (meetups.isEmpty) meetups = allMeetups;

    final meetup = meetups.where((m) => m.city == user.homeMeetupId).firstOrNull;
    
    if (meetup != null) {
      // Payload-Größe vorberechnen
      final compactId = '${meetup.city.toLowerCase().replaceAll(' ', '-')}-${meetup.country.toLowerCase()}';
      final estimatedPayload = '{"v":2,"t":"B","m":"$compactId","b":000000,"x":0000000000,"c":0000000000,"p":"${"0" * 64}","s":"${"0" * 128}"}';
      
      setState(() {
        _homeMeetup = meetup;
        _meetupInfo = "📍 ${meetup.city}, ${meetup.country}";
        _payloadSize = estimatedPayload.length + 10; // +10 für NFC Record Header
        _statusText = AppLocalizations.of(context).writerReadyToWrite;
      });
    } else {
      setState(() {
        _statusText = AppLocalizations.of(context).writerHomeMeetupNotFound;
        _meetupInfo = "Meetup: ${user.homeMeetupId}";
      });
    }
  }

  // =============================================
  // NFC TAG SCHREIBEN
  // =============================================
  // FIX: Bei fehlendem/deaktiviertem NFC wird jetzt ein
  // Dialog angezeigt statt einen Erfolg zu simulieren.
  // =============================================

  void _writeTag() async {
    if (_homeMeetup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).nwSelectHomeMeetup), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _statusText = AppLocalizations.of(context).writerLoadingSession;
      _success = false;
      _isProcessingTag = false; // Reset lock
    });

    // Zentraler Payload Abruf
    final tagData = await RollingQRService.getBasePayload();
    
    if (tagData == null) {
       setState(() => _statusText = AppLocalizations.of(context).writerNoActiveSession);
       return;
    }

    // NFC verfügbar?
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      // ── NFC nicht verfügbar → Dialog ──
      if (!mounted) return;

      // NFC könnte deaktiviert oder nicht unterstützt sein
      final bool isNotSupported = availability.toString().toLowerCase().contains('not');

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(
            Icons.nfc_rounded,
            size: 48,
            color: isNotSupported ? Colors.red : cOrange,
          ),
          title: Text(
            isNotSupported ? AppLocalizations.of(context).nfcUnavailable : AppLocalizations.of(context).nfcDisabled,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            isNotSupported
                ? AppLocalizations.of(context).verifyNoNfcLong +
                  AppLocalizations.of(context).writerUseRollingQr +
                  AppLocalizations.of(context).writerForYourMeetup
                : AppLocalizations.of(context).nfcEnableHint +
                  AppLocalizations.of(context).writerToWriteTag +
                  AppLocalizations.of(context).nfcSettingsAndroid,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
          actions: [
            if (!isNotSupported)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context).nfcOpenSettings,
                    style: TextStyle(color: Colors.grey)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: cOrange)),
            ),
          ],
        ),
      );

      setState(() {
        _statusText = isNotSupported
            ? AppLocalizations.of(context).writerNoNfcDevice
            : AppLocalizations.of(context).nfcDisabledHint;
      });
      return;
    }

    setState(() => _statusText = AppLocalizations.of(context).writerHoldTag);

    String jsonData = jsonEncode(tagData);
    final payload = Uint8List.fromList([0x02, 0x65, 0x6e, ...utf8.encode(jsonData)]);

    final message = NdefMessage(records: [
      NdefRecord(
        typeNameFormat: TypeNameFormat.wellKnown,
        type: Uint8List.fromList([0x54]),
        identifier: Uint8List(0),
        payload: payload,
      ),
    ]);

    final actualSize = jsonData.length + 7; // 3 prefix + ~4 NDEF header

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          // Verhindert, dass der Scanner während dem Schreibvorgang neu triggert
          if (_isProcessingTag) return;
          _isProcessingTag = true;

          try {
            var ndef = Ndef.from(tag);
            
            if (ndef == null) {
              var formatable = NdefFormatableAndroid.from(tag);
              if (formatable != null) {
                try {
                  setState(() => _statusText = AppLocalizations.of(context).writerFormatting);
                  await formatable.format(message);
                  await NfcManager.instance.stopSession();
                  _handleSuccessInUI(jsonData.length);
                  return;
                } catch (e) {
                  await NfcManager.instance.stopSession();
                  _handleErrorInUI(AppLocalizations.of(context).writerFormatFailed);
                  _isProcessingTag = false;
                  return;
                }
              }
              await NfcManager.instance.stopSession();
              _handleErrorInUI(AppLocalizations.of(context).writerNoNdef);
              _isProcessingTag = false;
              return;
            }

            if (!ndef.isWritable) {
              await NfcManager.instance.stopSession();
              _handleErrorInUI(AppLocalizations.of(context).writerTagReadOnly);
              _isProcessingTag = false;
              return;
            }

            // Payload-Größe prüfen
            final maxSize = ndef.maxSize;
            if (actualSize > maxSize) {
              await NfcManager.instance.stopSession();
              _handleErrorInUI(
                AppLocalizations.of(context).writerTagTooSmall(actualSize, maxSize) +
                AppLocalizations.of(context).writerUseNtag215
              );
              _isProcessingTag = false;
              return;
            }

            await ndef.write(message: message);
            await NfcManager.instance.stopSession();
            _handleSuccessInUI(jsonData.length);

          } catch (e) {
            AppLogger.debug('App', "[ERROR] Write Error: $e");
            await NfcManager.instance.stopSession();
            final errorMsg = e.toString();
            if (errorMsg.contains('IOException')) {
              _handleErrorInUI(AppLocalizations.of(context).writerTagRemovedEarly);
            } else if (errorMsg.contains('TagLost')) {
              _handleErrorInUI(AppLocalizations.of(context).writerTagLost);
            } else {
              _handleErrorInUI(errorMsg);
            }
            _isProcessingTag = false;
          }
        },
      );
    } catch (e) {
      setState(() {
        _statusText = AppLocalizations.of(context).writerStartError(e.toString());
        _isProcessingTag = false;
      });
    }
  }

  void _handleSuccessInUI(int dataSize) {
    if (!mounted) return;
    final expiresIn = BadgeSecurity.badgeValidityHours;
    setState(() {
      _success = true;
      _statusText = AppLocalizations.of(context).writerTagWritten +
          AppLocalizations.of(context).writerCompactSize(dataSize) +
          AppLocalizations.of(context).writerValidHours(expiresIn) +
          AppLocalizations.of(context).writerJumpToQr;
    });
    
    // Automatischer Sprung zum QR-Code Screen
    // pushAndRemoveUntil: Entfernt Wizard + AdminPanel vom Stack
    // → Zurück-Button im RollingQR führt direkt zum Dashboard
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RollingQRScreen()),
          (route) => route.isFirst, // Nur Dashboard behalten
        );
      }
    });
  }

  void _handleErrorInUI(String error) {
    if (!mounted) return;
    setState(() => _statusText = "❌ $error");
  }

  // =============================================
  // _simulateWriteTag() ENTFERNT — Sicherheitslücke geschlossen
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: Text(AppLocalizations.of(context).writerCreateMeetupTag), backgroundColor: cOrange),
      body: Center(
        child: _success
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 100, color: Colors.green),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context).writerSuccess, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text(_statusText ?? AppLocalizations.of(context).writerReadyToWrite, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14, height: 1.6)),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    ScaleTransition(
                      scale: _animation,
                      child: Container(
                        width: 200, height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cOrange, width: 4),
                          boxShadow: [BoxShadow(color: cOrange.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10)],
                        ),
                        child: const Center(child: Icon(Icons.nfc, size: 80, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(AppLocalizations.of(context).writerMeetupTag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white, letterSpacing: 2)),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        AppLocalizations.of(context).writerHoldTagInstruction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Home-Meetup Anzeige
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cOrange.withValues(alpha: 0.3)),
                      ),
                      child: Column(children: [
                        Text(AppLocalizations.of(context).writerYourHomeMeetup, style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(_meetupInfo.isNotEmpty ? _meetupInfo : "...", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // Payload-Info
                    if (_payloadSize > 0)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context).writerFitsNtag215(_payloadSize),
                            style: const TextStyle(color: Colors.green, fontSize: 12)),
                        ]),
                      ),
                    const SizedBox(height: 8),

                    // Ablauf + Überschreibbar Info
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cCyan.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.timer, color: cCyan, size: 16),
                            const SizedBox(width: 6),
                            Text(AppLocalizations.of(context).writerValid6h, style: const TextStyle(color: cCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.refresh, color: cCyan, size: 16),
                            const SizedBox(width: 6),
                            Text(AppLocalizations.of(context).writerCanOverwrite, style: const TextStyle(color: cCyan, fontSize: 12)),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Schreib-Button
                    SizedBox(
                      width: 250, height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _writeTag,
                        icon: const Icon(Icons.nfc, color: Colors.white),
                        label: Text(AppLocalizations.of(context).writerCreateTag, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: cOrange),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(_statusText ?? AppLocalizations.of(context).writerReadyToWrite, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}


