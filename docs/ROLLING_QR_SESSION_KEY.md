# Rolling QR: signierte Koordinaten und Sitzungsschlüssel (Security Audit H1)

Stand: 2026-10-09, Branch `security-fixes`. Dieses Dokument beschreibt das
Konzept; die Umsetzung steht noch aus (siehe „Offen“).

## Befund

`RollingQRService.generateQRString()` nimmt den **einmal** beim Sessionstart
signierten Kompakt-Payload (`{v,t,m,b,x}` + `c,p,s`, siehe
`BadgeSecurity.signCompact`) und hängt alle zehn Sekunden **unsignierte**
Felder an: `n` (HMAC-Nonce), `ts` (Zeitschritt), `d` (Delivery) sowie `la`/`lo`
(Organisator-Standort). Der Scanner (`meetup_verification.dart`) nutzt `la`/`lo`
als „gemessene“ Referenz für den 5-km-Präsenz-Check.

Folgen:

1. Wer einen gültigen QR abfotografiert, kann `la`/`lo` beliebig umschreiben
   und so den Präsenz-Check an einen anderen Ort verlegen (innerhalb der
   Session-Gültigkeit `x`, derzeit vier Stunden).
2. `n`/`ts` sind nur eine Zeitnähe-Prüfung; der Scanner kennt den Seed nicht und
   kann die Nonce nicht nachrechnen. Ein weitergereichter Payload bleibt eine
   Toleranz lang (`toleranceSteps`) gültig.

## Warum nicht einfach jeden Payload signieren?

Lokaler Modus: möglich, der Schlüssel liegt in der App. Amber (NIP-55) und
Bunker (NIP-46): jede Signatur ist eine Nutzerinteraktion bzw. ein Roundtrip.
Alle zehn Sekunden einen Signier-Dialog zu zeigen ist nicht praktikabel.

## Zielbild

### 1. Koordinaten in den signierten Teil

`signCompact` erhält optionale Felder `la`/`lo` (auf vier Nachkommastellen
gerundet, ca. 11 m) im **signierten** Content. `verifyCompact` nimmt die Keys
`{v,t,m,b,x,la,lo}` auf, sofern vorhanden. Alte Badges ohne `la`/`lo` bleiben
gültig. **Kompatibilität:** Scanner mit altem Verifier verwerfen `la`/`lo` beim
Nachrechnen und lehnen neue Badges ab. Deshalb nur mit Versionssprung
(`v: 3`) ausrollen und Scanner vorher aktualisieren. Dasselbe gilt für
`badge-verifier.html`.

### 2. Delegierter Sitzungsschlüssel (einmal pro Session)

Beim Sessionstart:

1. App erzeugt ein frisches Schlüsselpaar `S` (nur im Speicher und
   `flutter_secure_storage`, gelöscht beim Sessionende).
2. Hauptschlüssel `M` (lokal, Amber oder Bunker) signiert **einmal** eine
   Delegation nach NIP-26-Muster:
   `nostr:delegation:<S_pub>:kind=21000&created_at>=<start>&created_at<=<x>`
   plus Meetup-ID im Bedingungsstring (`m=<meetupId>`), damit `S` nur für
   dieses Meetup und nur bis `x` signieren darf.
3. Der Base-Payload enthält zusätzlich `dp` (Delegator = `M_pub`), `dc`
   (Bedingungen) und `ds` (Delegationssignatur).

Alle zehn Sekunden:

4. `S` signiert den vollständigen Payload inklusive `n`, `ts`, `la`, `lo`
   (Kind 21000, Content kanonisiert). Keine Nutzerinteraktion, da `S` lokal
   vorliegt.

Scanner:

5. Prüft die Delegation (Signatur von `M` über den Delegationsstring, Kind,
   Zeitfenster, Meetup-ID), dann die Payload-Signatur von `S`, dann wie bisher
   Ablauf, Zeitnähe und Admin-Status von `M` (Registry, Portal, Event-Kette).
6. `la`/`lo` gelten nur noch als „gemessen“, wenn sie signiert sind;
   unsignierte Koordinaten fallen auf die abgeleitete Referenz (50 km) zurück.

### 3. Übergang

- Neue Scanner akzeptieren altes Format (unsignierte `la`/`lo` nur als
  abgeleitete Referenz) und neues Format.
- Nach einer Übergangszeit (ein Release-Zyklus) akzeptieren Scanner nur noch
  das signierte Format.

## Offen

- Umsetzung in `BadgeSecurity` (Content-Keys, Delegationsprüfung),
  `RollingQRService` (Sitzungsschlüssel, Signatur pro Zeitschritt),
  `meetup_verification.dart` (Referenz nur bei signierten Koordinaten
  „gemessen“) und `badge-verifier.html`.
- Produktentscheidung: Versionssprung und Pflicht-Update der Scanner-Apps.
