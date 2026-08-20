import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import 'nfc_writer.dart';
import 'rolling_qr_screen.dart';

/// Fuehrt durch den NFC-Schritt beim Start einer Session.
///
/// Wird nur noch geoeffnet, wenn [kNfcEnabled] true ist. Ohne NFC springt
/// der Organisator-Bereich direkt zum Rolling QR — dieser Bildschirm bliebe
/// sonst als Seite uebrig, die nur einen "Ueberspringen"-Knopf traegt.
class MeetupSessionWizard extends StatelessWidget {
  const MeetupSessionWizard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).mwStartMeetup),
        backgroundColor: cDark,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: cTextSecondary),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Schritt-Indikator
            Row(children: [
              _step(1, 'NFC', true),
              Expanded(child: Container(height: 0.5, color: cTileBorder)),
              _step(2, 'QR', false),
            ]),
            const SizedBox(height: 32),

            // Icon
            const Icon(Icons.nfc_rounded, size: 40, color: cOrange),
            const SizedBox(height: 16),

            // Titel
            Text(AppLocalizations.of(context).mwStep1Nfc,
              style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 10),

            // Beschreibung
            Text(
              AppLocalizations.of(context).mwNfcIntro1 +
              AppLocalizations.of(context).mwNfcIntro2,
              style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.6)),

            const Spacer(),

            // NFC schreiben Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius))),
                onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const NFCWriterScreen())),
                icon: const Icon(Icons.nfc_rounded, size: 18),
                label: Text(AppLocalizations.of(context).mwWriteNfcTag,
                  style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 10),

            // Überspringen
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RollingQRScreen()),
                  (route) => route.isFirst),
                child: Text(AppLocalizations.of(context).mwSkipQrOnly,
                  style: const TextStyle(color: cTextTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(int number, String label, bool isActive) {
    return Column(children: [
      Container(
        width: 28, height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? cOrange : cCard,
          shape: BoxShape.circle,
          border: Border.all(color: isActive ? cOrange : cTileBorder, width: 0.5)),
        child: Text('$number', style: TextStyle(
          color: isActive ? Colors.black : cTextTertiary,
          fontSize: 12, fontWeight: FontWeight.w800))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
        color: isActive ? cOrange : cTextTertiary,
        fontSize: 10, fontWeight: FontWeight.w700)),
    ]);
  }
}



