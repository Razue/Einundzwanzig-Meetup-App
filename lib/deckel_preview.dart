// Der Bierdeckel allein, als Selbstläufer: der Demo-Tisch spielt den ganzen
// Abend durch, ohne dass jemand tippt. Für einen Bildschirm am Stand und zum
// Nachsehen im Simulator.
//
//   flutter run -t lib/deckel_preview.dart

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'screens/deckel_screen.dart';
import 'theme.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DeckelScreen(
        demo: true,
        demoAutoplay: true,
        demoPace: Duration(seconds: 3),
      ),
    ),
  );
}
