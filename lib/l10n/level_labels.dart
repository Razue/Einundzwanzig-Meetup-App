// ============================================================
// LEVEL LABELS
// Mappt INTERNE Trust-Level-Werte (bleiben unverändert für
// QR-Austausch, switch-cases und Score-Logik) auf das
// übersetzte Anzeige-Label.
//
// WICHTIG: Niemals den internen Wert (z.B. 'VETERAN') ersetzen —
// nur das, was dem Nutzer angezeigt wird, wird hier lokalisiert.
// ============================================================

import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Gibt das übersetzte Label für einen internen Level-Wert zurück.
/// Unbekannte Werte werden unverändert durchgereicht.
String localizedLevel(BuildContext context, String internalLevel) {
  final t = AppLocalizations.of(context);
  switch (internalLevel) {
    case 'NEU':
      return t.levelNew;
    case 'STARTER':
      return t.levelStarter;
    case 'AKTIV':
      return t.levelActive;
    case 'ETABLIERT':
      return t.levelEstablished;
    case 'VETERAN':
      return t.levelVeteran;
    default:
      return internalLevel;
  }
}
