# Nostr-Profilbilder: Discovery, Cache und Fehlerverhalten

Der Bildabruf benötigt ausschließlich einen öffentlichen Schlüssel. Ein lokaler
privater Schlüssel, ein erreichbarer Signer oder eine NIP-05-Domain sind keine
Voraussetzung. Die Startseite verwendet den aktiven NPUB auch bei externen
Signern und bei einem erstmals eingetragenen öffentlichen Schlüssel.

## Ablauf

`NostrProfileService.fetchProfilePicture()` delegiert an `NostrProfileLookup`:

1. Einen gültigen, pro Public Key gespeicherten Profil-Cache bis zu zwölf Stunden
   verwenden. Gleichzeitige Abfragen für dieselbe Identität werden zusammengeführt.
2. Parallel die konfigurierten App-Relays und den Profil-Index
   `wss://purplepag.es` nach `kind:0` und `kind:10002` fragen. Insgesamt höchstens
   acht Relays, davon ein reservierter Platz für den Index.
3. Aus der neuesten gültig signierten NIP-65-Relay-Liste höchstens vier weitere
   Relays lesen: `r` ohne Marker oder mit `write`. Relays mit `read` sind für das
   Abrufen der vom Autor veröffentlichten Ereignisse nicht vorgesehen.
4. Das neueste gültig signierte `kind:0` aus allen Antworten und dem Cache wählen.
   Bei gleichem Zeitstempel gewinnt die lexikografisch kleinste Event-ID gemäß
   NIP-01. Ein neueres Profil ohne gültiges `picture` entfernt das bisherige Bild.

Die Discovery läuft in zwei Stufen und folgt Relay-Hinweisen nicht rekursiv.
Signierte Relay-Listen werden ebenfalls pro Public Key gespeichert, damit die
bekannten Autor-Relays auch bei einem späteren Ausfall des Index erreichbar bleiben.
Eine neuere leere Relay-Liste ersetzt ältere Hinweise.

## Sicherheit und Netzwerkgrenzen

- Event-ID und BIP-340-Signatur werden durch die vorhandene `nostr`-Bibliothek
  geprüft; Autor, Metadaten-Typ, JSON-Objekt und nicht zukünftiger Zeitstempel
  werden zusätzlich geprüft. Manipulierte oder fremde Ereignisse werden ignoriert.
- Bild-URLs müssen HTTP(S) verwenden und dürfen keine eingebetteten Zugangsdaten
  enthalten. Bilder werden durch die vorhandene Flutter-Bildanzeige geladen;
  bei einem Downloadfehler erscheint der Buchstaben-Fallback.
- Automatisch entdeckte Relays müssen WSS verwenden. Zugangsdaten, Fragmente,
  lokale Hostnamen und private IPv4-Literaladressen werden verworfen. IPv6-Literale
  werden bei Discovery konservativ ausgeschlossen. DNS-Rebinding wird dadurch
  nicht verhindert; es wird keine vollständige Netzwerkisolation behauptet.
- Pro Relay gilt ein Gesamtzeitlimit von sechs Sekunden inklusive Verbindung.
  Höchstens acht Ereignisse, 64 Nachrichten und 64 Ki Zeichen pro Nachricht werden
  verarbeitet. Nach Abschluss, Fehler oder Timeout wird die Verbindung geschlossen.
  Der Close-Handshake wird nicht abgewartet, damit ein unantwortendes Relay den
  Abschluss nicht blockiert. Beide parallelen Stufen brauchen höchstens ungefähr
  zwölf Sekunden Netzwerkwartezeit, zuzüglich lokaler Verarbeitung.
  Native Verbindungen besitzen einen eigenen HTTP-Client, der auch eine laufende
  Upgrade-Anfrage abbrechen kann. Im Browser wird der zugrunde liegende WebSocket
  direkt geschlossen. Andere Relay-Funktionen behalten ihren bisherigen Transport.
- Der Index und Autor-Relays erhalten nur Leseanfragen mit dem öffentlichen
  Schlüssel. Es werden keine Schlüssel oder App-Ereignisse dorthin veröffentlicht.
  Diese zusätzlichen Abfragen machen die gesuchte Identität und die übliche
  Netzwerkverbindung für die beteiligten Relays sichtbar. Sie ändern die
  konfigurierten Relays für andere App-Funktionen nicht.

## Cache und Anzeige

Der neue Cache speichert das signierte Profil samt Abrufzeit, statt nur einer
Bild-URL. Bei Ausfall aller Quellen bleibt das letzte bekannte Profil erhalten.
Ältere Antworten können es nicht überschreiben. Eine explizite Bildentfernung
bleibt auch bei späterem Ausfall wirksam. Fehlende Metadaten werden nicht dauerhaft
negativ gecacht; der nächste Abruf kann erneut suchen.

Bestehende URL-Caches werden bis zum bisherigen Ablauf verwendet und bei einem
Netzwerkausfall als Übergangs-Fallback behalten. Sobald ein signiertes Profil
vorliegt, wird der alte URL-Cache entfernt. `clearCache()` entfernt beide Formate
und Relay-Hinweise; laufende alte Anfragen dürfen den Cache nicht neu befüllen.

Ein gewähltes lokales Bild behält auf der Startseite seinen bisherigen Vorrang.
Bei einem Identitätswechsel werden alte Remote-Bilder verworfen. Verspätete
Antworten der vorigen Identität dürfen weder die Startseite noch `NostrAvatar`
überschreiben. Der Profilbildabruf wird beim Aktualisieren der Startseite erneut
angestoßen; ein noch frischer Cache wird dabei respektiert.

## Grenzen und Reproduktion

Discovery kann nur ein auf einem erreichbaren Kandidaten-Relay veröffentlichtes
Profil finden. Ein neues Schlüsselpaar ohne veröffentlichtes Bild erhält weiterhin
den Buchstaben-Fallback. Der Index ist eine zusätzliche Bootstrap-Quelle, keine
Garantie für vollständige Nostr-Daten. Ohne dort oder auf App-Relays verfügbare
Metadaten bzw. Relay-Hinweise können unbekannte Autor-Relays nicht erraten werden.
Die begrenzte Auswahl von Relays ist bewusst kein vollständiger Netzwerkscan.

Eine `.well-known/nostr.json`-Änderung erfordert für diesen Fix keine Anpassung:
NIP-05 ist eine Zuordnung von Namen zu öffentlichen Schlüsseln, keine Bildquelle.
Ein bereits bekannter NPUB erlaubt auch ohne Domain-Zuordnung den Profilabruf.

Die Regressionstests verwenden synthetische signierte Ereignisse und lokale
WebSocket-Server; sie enthalten keine persönlichen NPUBs oder Domains:

```sh
flutter test --no-pub test/nostr_profile_lookup_test.dart test/profile_relay_client_test.dart test/nostr_avatar_test.dart
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
flutter test --no-pub
```

Sie prüfen Erstabruf ohne Cache/privaten Schlüssel, NIP-65-Discovery,
Signaturprüfung, Ersetzungsreihenfolge, Bildentfernung, Migration, Ausfälle,
Cache-Isolation, parallele Abrufe, Netzwerkgrenzen, externe Signer und
Identitätswechsel während laufender Anfragen. Die Web-Prüfungen und der
Release-Webbuild entsprechen zusätzlich den Gates in `pr_checks.yml`.

### Verifizierter Stand am 6. Oktober 2026

- Analyzer: keine Fehler, Warnungen oder Hinweise.
- Gesamte native Testsuite: 336 Tests bestanden, ein plattformbedingter Skip.
- Gezielt ausgeführte Profil-, Socket-, Avatar- und User-Profile-Tests: 31 bestanden.
- Chrome: Profil-Discovery und die CI-Prüfungen für PBKDF2, NIP-44 und NIP-49 bestanden.
- Release-Webbuild erfolgreich.
- iOS-Debugbuild erfolgreich; die App wurde auf dem iPhone-18-Pro-Simulator gestartet.
- Visuelle Kontrolle im Simulator: Das Profilbild ist auf der Startseite sichtbar
  und wird auch nach abgeschlossener Aktualisierung korrekt angezeigt.

Die automatisierten Profiltests ersetzen keine Garantie für die Verfügbarkeit
öffentlicher Relays. Die Sichtprüfung bestätigt die Darstellung im bestehenden
Profil; ein frischer Cache kann dabei verwendet werden. Erstabruf ohne Cache,
Cache-Ablauf und Fehlerfälle wurden separat mit den Regressionstests geprüft.

Protokollreferenzen:
[NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md),
[NIP-65](https://github.com/nostr-protocol/nips/blob/master/65.md),
[Issue #70](https://github.com/louisthecat86/Einundzwanzig-Meetup-App/issues/70).
