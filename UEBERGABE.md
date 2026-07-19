# Übergabe & Entwickler-Handbuch

Dieses Dokument fasst die praktischen Dinge zusammen, die man beim Weiterentwickeln der App wissen muss — Arbeitsweise, Architektur der jüngeren Features, bekannte Fallstricke und der offene Stand. Es ergänzt die `README.md` (Was & Warum) um das Wie & Vorsicht.

Stand: v1.4.0+7 (Basis-Commit `436d16a`).

---

## Arbeitsumgebung & Build

- Entwicklung in **GitHub Codespaces** — dort ist **kein Android SDK** installiert. `flutter build apk` schlägt lokal fehl (das ist normal, kein Fehler).
- **APKs werden von der GitHub Action gebaut**, ausgelöst durch einen Versions-Tag (`vX.Y.Z`). Die Action signiert die APK und hängt sie an den Release.
- Lokal möglich und vor jedem Commit empfohlen:
  ```bash
  flutter pub get && flutter gen-l10n && flutter analyze
  ```
  Es gibt ~200 kosmetische `info`/`warning`-Meldungen (ungenutzte Importe, `use_build_context_synchronously` etc.) — die sind bekannt und unkritisch. Achte nur auf **`error`**-Zeilen.

### Release-Prozess

1. `pubspec.yaml` → `version: X.Y.Z+N` setzen. **N (versionCode) muss streng steigen**, sonst lehnt Android das Update ab.
2. `flutter analyze` (0 errors).
3. Commit → `git push origin main`.
4. `git tag vX.Y.Z && git push origin vX.Y.Z` → Action baut die signierte APK.
5. Optional Zapstore: Version in `zapstore.yaml` angleichen, dann
   `SIGN_WITH="bunker://..." zsp publish zapstore.yaml`.

App-ID: `space.einundzwanzig.meetup`.

---

## Konventionen (unbedingt einhalten)

- **Sprache:** Deutsch (UI, Kommentare, Commits).
- **Theme** (`theme.dart`): Farbkonstanten `cOrange`, `cDark`, `cCard`, `cSurface`, `cText`, `cTextSecondary`, `cTextTertiary`, `cGreen`, `cRed`, `cPurple`, `cTileBorder`, Radius `kTileRadius`. Immer diese nutzen, keine Hex-Literale streuen.
- **Monospace-Schrift:** `fontMono` **niemals** in einem `const TextStyle` verwenden — immer `.copyWith(fontFamily: fontMono)`. `const` + `fontMono` bricht den Build.
- **Lokalisierung** (`lib/l10n/`): Template ist `app_de.arb`, dazu `app_en.arb`, `app_es.arb`. **Die generierten `app_localizations*.dart` sind im Repo eingecheckt** — bei neuen Keys müssen sie mitgeliefert / per `flutter gen-l10n` neu erzeugt werden. Alle drei Sprachen konsistent halten.
- **Dateien liefern statt patchen:** Bei größeren Änderungen ganze Dateien austauschen ist robuster als Zeilen-Patches.

---

## Architektur der jüngeren Features

### Identität & Signatur (`signing_service.dart`)

Zentrale Stelle für alles Kryptographische. Zwei Modi (`SigningMode`): **lokaler Schlüssel** (nsec im Secure Storage) oder **Amber** (NIP-55, nsec verlässt die Signer-App nie).

- **Immer `SigningService.npub()` / `SigningService.getMode()` nutzen**, nie direkt `SecureKeyStore.getNpub()` — letzteres kennt nur den lokalen Schlüssel und liefert im Amber-Modus `null`. Genau dieser Fehler hat früher den Organisator-Button für alle Amber-Nutzer zerstört (siehe Fallstricke).
- Im UI: nsec-Anzeige/Export nur hinter `if (!_isAmber)` — im Amber-Modus existiert kein lokaler nsec.

### Portal-Anbindung (`portal_api_service.dart`)

Basis-URL `https://portal.einundzwanzig.space/api`.

- **Login:** `POST /mobile/token` mit einem per Nostr signierten Payload. Der Token wird lokal an den aktuellen npub **gebunden** (`storeToken`). Die Bindung nutzt `SigningService.npub()` (Amber-fähig).
- **Token-Prüfung** (`tokenMatchesCurrentKey`): bei fehlender/abweichender lokaler Bindung fragt die App `GET /user` (liefert das `nostr`-Feld = npub des Token-Inhabers) und **heilt** die Bindung, statt den Token vorschnell zu löschen. `false` (→ löschen) nur bei belegtem Fremd-Token (401 oder anderer npub).
- **Termine:** `GET /meetup-events/{datum}` (öffentliche Liste) und `GET /my-meetup-events` (Organisator-Sicht). **Achtung: unterschiedliche Zeitformate** — siehe Fallstricke „Zeitzonen".
- **RSVP:** `POST /meetup-events/{id}/rsvp`.

### Meetup-Termine & Zeit (`meetup_calendar_service.dart`)

Zentrale Lade-Methode `fetchMeetupsPortalFirst()`: **Portal zuerst**, iCal-Feed als Fallback. Alle Screens sollen diese Methode nutzen.

- **`portalStart(raw)`** — parst Zeiten von `/meetup-events/{datum}`. Die Live-Instanz liefert Zeiten **als UTC ohne Zonenkennung** → ohne Zone wird als UTC interpretiert und mit `.toLocal()` in Gerätezeit umgerechnet; mit `Z`/Offset normal.
- **`portalStartUtc(raw)`** — für `/my-meetup-events` (rohe DB-Zeit, ebenfalls UTC ohne Kennung).
- **`absoluteImageUrl(url)`** — macht relative Portal-Bildpfade absolut (Wappen); `Image.network` scheitert an relativen Pfaden still.
- Der ICS-Parser (`calendar_event.dart`) ist ebenfalls zonenbewusst: rohen DTSTART-String prüfen, mit `Z` → UTC→lokal, ohne → bereits lokal. Der `RecurrenceExpander` erbt die Startzeit vom Basis-Event, deshalb greift der Fix auch für Serien.

### Dashboard-Kacheln (`home_screen.dart`)

Konfigurierbares Kachel-System (`_TileDef`, sortier- und ausblendbar via Long-Press). Sichtbarkeit über `_defaultOrder` / `_defaultHidden` + einmalige Migrations-Flags (`mig_hide_*`), damit neue Kacheln bei Bestandsnutzern nicht ungefragt auftauchen.

- **Home-Meetup / Favoriten:** `favoriteMeetupIds: List<String>` (Stadtnamen) in `user.dart`. Die Kachel ist ein `PageView` — je Favorit eine Karte mit deren nächstem Event, chronologisch sortiert (nächstes vorne, Städte ohne Termin hinten), 3-Punkte-Indikator.
- **Matching Event→Stadt** (`matchesCity`): nur Titel + Ort (nicht Beschreibung!), **Wortgrenzen** statt `contains` (sonst matcht „Frankfurter Str." den Favoriten „Frankfurt"), generische Stoppwörter (`einundzwanzig`, `bitcoin`, `meetup`, `stammtisch`) ausgeschlossen.
- **Homescreen-Widget** (`widget_service.dart`) bekommt immer die **vorderste** Karte (global nächstes Meetup).
- Diagnose-Log-Zeilen (`AppLogger.diag`) sind bewusst drin (`HomeMeetup:`, `Portal:`, `Calendar: QUELLE=…`) — sie machen Zeit-/Matching-Fragen am Gerät beweisbar.

### SatoshiDuell (`satoshiduell_service.dart`)

Liest die **öffentliche Supabase-REST-API** von satoshiduell.de mit dem publishable Key (per Design öffentlich, RLS-begrenzt — identisch im WebApp-Bundle). Kachel öffnet `https://satoshiduell.de/?npub=<npub>` → Auto-Login. `fetchStatus()` zählt dran/wartet/Lobby (Logik 1:1 aus der WebApp; Lobby clientseitig gefiltert wegen PostgREST-Quoting-Eigenheiten).

### PlebRap-Player (`plebrap_audio.dart` + `plebrap_player_screen.dart`)

App-weiter Player-Zustand (ein `AudioPlayer`, `ValueNotifier` für Index/Loading). 41 Songs fest eingebettet (Stream direkt von plebrap.de). Dashboard-Kachel ist Mini-Player (Play/Pause/Next + Bibliotheks-Button), Screen zeigt Now-Playing mit Cover + Titelliste. V4V-Button öffnet die plebrap.de-Value-Seite. Braucht `just_audio` in der pubspec.

---

## Bekannte Fallstricke (teuer gelernt)

### 1. Amber vs. lokaler Schlüssel
`SecureKeyStore.getNpub()` liefert bei Amber `null`. **Immer `SigningService.npub()`** verwenden. Dieser eine Punkt hat den Orga-Button, die Cache-Räumung und die Token-Bindung betroffen.

### 2. NFC-Konflikt mit Audio-Hintergrunddienst
Der Versuch, für eine Media-Notification (`just_audio_background`) die `MainActivity` von `AudioServiceActivity` erben zu lassen, **crasht den App-Start**: Die gecachte FlutterEngine hängt die Plugins neu an, dabei wirft `NfcManagerPlugin.onAttachedToActivity` (nfc_manager 4.1.1) einen NullPointer in `registerReceiver`. **NFC ist Kern-Feature und gewinnt** — die MainActivity bleibt bei `FlutterActivity`. Media-Notification (Stufe 2) ist zurückgestellt; ein erneuter Versuch braucht zuerst **nfc_manager ≥ 4.2.x** und einen Gegentest.

### 3. Zeitzonen (mehrfach gelöst)
Die Live-Portal-Instanz liefert Zeiten **als UTC ohne Kennung**. Wer das als lokale Zeit nimmt, zeigt −2h (MESZ). Es gibt **mehrere Datenpfade** (Portal-Liste, Organisator-Sicht, ICS-Kalender/Serien) — alle müssen zonenbewusst parsen. Bei neuen Zeit-Anzeigen immer `portalStart` / `portalStartUtc` / den ICS-Parser nutzen, nie `DateTime.parse(...).toLocal()` roh. Die Diagnose-Logs zeigen das Rohformat.

### 4. Termin-Editor (offen)
Die Organisator-Bearbeitung (`portal_meetups_screen.dart`) zeigt beim Bearbeiten teils die Rohzeit. **Bewusst nicht umgerechnet**, weil dort ein Speichern-Roundtrip dranhängt — würde man die Anzeige umrechnen ohne beim Senden exakt zurückzurechnen, verschiebt jedes Bearbeiten den Termin um 2 Stunden. Muss als Paket (Anzeige umrechnen **und** Senden zurückrechnen, mit Log-Beweis) gemacht werden.

### 5. Dart-Strings mit Sonderzeichen
Beim maschinellen Generieren von Song-/URL-Listen: rohe Apostrophe in URLs (`SHA 'o' lin`) müssen `%27` sein, sonst bricht der Dart-String. Immer die Quote-Parität jeder Zeile prüfen.

---

## Offene Punkte / Ideen

- **Termin-Editor** zeitzonensicher machen (Anzeige + Sende-Roundtrip).
- **Media-Notification (Stufe 2)** erst nach nfc_manager-Update erneut versuchen.
- **PlebRap V4V:** echte Lightning-Adresse der Künstler einbauen (aktuell öffnet der Button die V4V-Seite).
- **Teilnehmernamen bei RSVP:** Portal liefert aktuell nur Zähler; ein kleiner Portal-Patch (`attendee_names` im `rsvpPayload`, respektiert `attendeesVisibleTo`) würde Namen bereitstellen. Die App liest das Feld bereits tolerant — muss serverseitig deployed werden.
- **Wappen Darmstadt/Wiesbaden:** falls weiter leer, liefert `/api/meetups` für diese Meetups kein Logo (Portal-Seite) — dann Fall für den Portal-Betreiber.
- ~200 kosmetische Analyzer-Warnungen könnten bei Gelegenheit aufgeräumt werden.

---

## Diagnose-Log

Unter **Einstellungen → Diagnose-Log** landen strukturierte Meldungen (`AppLogger.diag/warn`). Bei Zeit-, Matching-, Portal- oder Audio-Problemen ist das die erste Anlaufstelle — die Logs sind bewusst so gebaut, dass sie die Ursache zeigen statt raten zu lassen (z. B. `Portal: start-Rohformat "…" -> angezeigt HH:MM`).
