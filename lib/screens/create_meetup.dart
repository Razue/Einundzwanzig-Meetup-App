import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart'; // Zugriff auf unsere Farben (cOrange, cCard etc.)

class CreateMeetupScreen extends StatelessWidget {
  const CreateMeetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).cmNewMeetup)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).cmFoundBase, style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 20),

            _brutalInput(AppLocalizations.of(context).cmCityName, AppLocalizations.of(context).cmCityExample),
            const SizedBox(height: 20),
            _brutalInput(AppLocalizations.of(context).cmLocation, AppLocalizations.of(context).cmLocationExample),
            const SizedBox(height: 20),
            _brutalInput(AppLocalizations.of(context).cmDateTime, AppLocalizations.of(context).cmDateExample),
            const SizedBox(height: 20),
            _brutalInput(AppLocalizations.of(context).cmTelegramGroup, "t.me/..."),

            const SizedBox(height: 40),
            
            // Der Speicher-Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Hier würde später das Speichern passieren
                  Navigator.pop(context); // Geht zurück zur Liste
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).cmRequestSent)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(), // Eckig
                  elevation: 0,
                ),
                icon: const Icon(Icons.send, color: Colors.white),
                label: Text(AppLocalizations.of(context).apStartMeetup, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ein eigenes Widget für brutalistische Eingabefelder
  Widget _brutalInput(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          cursorColor: cOrange,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: cCard, // Dunkelgrauer Hintergrund
            // Harter Rahmen, kein Radius
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: cOrange, width: 2), // Orange bei Fokus
              borderRadius: BorderRadius.zero,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}


