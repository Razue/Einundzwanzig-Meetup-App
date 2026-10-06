# iOS-Verteilung über AltStore PAL (und Freedom Store)

Stand: September 2026. Technische Anleitung, wie die Meetup-App zusätzlich zum
App Store über den alternativen EU-Marktplatz **AltStore PAL** verteilt wird,
und wie sie in die kuratierte **Freedom Store**-Liste der Vexl Foundation kommt.

## 1. Wie das System zusammenhängt

```
App Store Connect ──Notarization──▶ ADP (manifest.json, signature, variant/*.ipa)
        │                                   │
        │ Marketplace-Token                  │ tool/altstore/publish_adp.sh
        ▼                                   ▼
   AltStore PAL  ◀── source.json ◀── GitHub Pages   +   GitHub Release (Binärdateien)
        ▲
        │ "Add Source"
   Nutzer (iOS 17.4+, EU-Apple-ID)   ◀── Freedom Store verlinkt nur unsere Dateien
```

- **AltStore PAL** ist der von Apple zugelassene Marktplatz (EU, Japan, Brasilien).
  Für Nutzer kostenlos.
- **ADP** (Alternative Distribution Package) ist das von Apple notarisierte und
  verschlüsselte Installationspaket. Wir hosten es selbst.
- **Source** ist eine JSON-Datei mit App-Metadaten und Download-Links. Jeder
  kann sie in AltStore PAL hinzufügen.
- **Freedom Store** (`source.freedomstore.io`) ist selbst nur so eine Source.
  Die Vexl Foundation trägt dort Apps ein, die Binärdateien bleiben beim Entwickler.

Unsere Source-URL nach dem ersten Release:

```
https://razue.github.io/Einundzwanzig-Meetup-App/altstore/source.json
```

Direktlink für Nutzer, öffnet AltStore PAL mit der Source:

```
altstore-pal://source?url=https://razue.github.io/Einundzwanzig-Meetup-App/altstore/source.json
```

## 2. Voraussetzungen (einmalig, organisatorisch)

1. **Apple Developer Program** des Vereins (Organization-Account, siehe
   `.buildlog/APPLE_ACCOUNT_VEREIN.md`). Für die reine Verteilung über einen
   fremden Marktplatz verlangt Apple weder EU-Sitz noch Mindestmitgliedschaft
   noch Install-Zahlen. Diese Hürden gelten nur für Marktplatz-Betreiber und
   Web Distribution.
   **Übergangslösung (Stand 16.09.2026, vom Verein abgesegnet):** Bis der
   Vereins-Account steht, läuft die App über Ralphs Firmen-Account. Apple
   unterstützt den späteren App-Transfer auch für Apps auf alternativen
   Marktplätzen. Damit der Transfer später klappt, jetzt schon beachten:
   - Die App braucht **mindestens eine im App Store veröffentlichte Version**.
     Eine reine AltStore-App ist nicht transferierbar. Also neben der
     Notarization auch ein App-Store-Release einplanen.
   - Der Verein muss **vor** dem Transfer die EU-Terms akzeptiert und AltStore
     PAL als Marktplatz in seinem eigenen Account eingetragen haben, sonst
     verschwindet die App dort.
   - Die **Team-ID ändert sich** beim Transfer. Die im iOS-Keychain liegenden
     Nostr-Schlüssel (`flutter_secure_storage`) sind danach für die App nicht
     mehr lesbar. Vor dem Transfer ein Update ausliefern, das die Schlüssel
     zusätzlich im App-Sandbox-Speicher ablegt (überlebt den Transfer, weil
     die Bundle-ID gleich bleibt), und nach dem Transfer zurückmigrieren.
   - Passkeys hängen an der Domain (RP-ID), nicht an der Team-ID. Nach dem
     Transfer muss nur die `apple-app-site-association` auf einundzwanzig.space
     die neue Team-ID zusätzlich auflisten. Bis dahin besser keine
     Associated-Domains-Funktionen unter der Übergangs-Team-ID ausliefern.
   - Zum Transferzeitpunkt: TestFlight aus, keine Version in Review.
2. **EU-Terms akzeptieren.** Der Account Holder muss im Developer-Account die
   aktualisierte Lizenzvereinbarung (Attachment 14, verfügbar seit 18.08.2026,
   verpflichtend ab 01.10.2026) annehmen. Für eine kostenlose App ohne
   In-App-Verkäufe fallen 0 € an. Die alte Per-Install-Gebühr entfällt.
3. **App in App Store Connect angelegt** mit Bundle-ID
   `dev.einundzwanzig.einundzwanzigMeetupApp`. Die dort vergebene „Apple ID"
   der App (App Information) ist später die `marketplaceID`.

## 3. Einmalige Einrichtung in App Store Connect

### 3.1 Developer-ID bei AltStore registrieren

Die Developer-ID steht in App Store Connect oben rechts unter „Edit Profile".

```bash
curl --header "Content-Type: application/json" -X POST \
  --data '{ "developerID": "<Developer-ID>", "email": "<Vereins-E-Mail>" }' \
  https://api.altstore.io/register
```

Antwort ist ein `token` mit Ablaufdatum. Den Token zeitnah verwenden.

### 3.2 AltStore PAL als Marktplatz eintragen

1. App Store Connect → **Users and Access → Integrations → Marketplace** → „+"
2. Token einfügen.
3. Die Meetup-App auswählen (jederzeit änderbar).
4. **„Yes, send notifications"** wählen. Dann verarbeitet AltStore jedes
   notarisierte Build automatisch, ohne dass wir etwas anstoßen müssen.

### 3.3 Review-Typ

- Läuft die App parallel im App Store, ist nichts zu tun: Eine bestandene
  App-Store-Review notarisiert automatisch mit.
- Soll ein Build **nur** über AltStore laufen: App → App Review → „Review Type"
  → **Notarization** → Save → Build einreichen. Notarization prüft Malware,
  Betrug, Datenschutz und Funktionsfähigkeit, aber keine Inhalte oder
  Geschäftsmodelle.

## 4. Hosting: GitHub reicht

Wir brauchen keinen eigenen Server. Aufteilung:

| Was | Wo | Warum |
|---|---|---|
| `source.json`, Icon, Screenshots | GitHub Pages (bestehende PWA-Site aus `web/`) | klein, textbasiert, versioniert |
| `manifest.json`, `signature`, `*.ipa` | GitHub Releases des Forks, Tag `ios-<version>-<build>` | keine Repo-Aufblähung, bis 2 GB pro Datei, kein 1-GB-Site-Limit |

AltStore erlaubt für genau diesen Fall das Feld `assetURLs` in der Source: Jede
Datei des ADP wird einzeln verlinkt, die Verzeichnisstruktur muss dann nicht
erhalten bleiben. Das ist dokumentiert („This allows you to host ADPs using
GitHub Releases!") und wird von AltStores eigener App Delta so genutzt.

Limits von GitHub Pages zur Einordnung: 1 GB Site, weiche Grenze 100 GB
Traffic pro Monat. Da die Binärdateien auf Releases liegen, ist beides irrelevant.

Flutter kopiert alles aus `web/` nach `build/web`. Damit liegt
`web/altstore/source.json` nach dem nächsten Pages-Deploy automatisch unter der
Source-URL oben. Der Deploy läuft aus dem Branch `integration/ios-complete`
(siehe `.github/workflows/deploy_web.yml`).

## 5. Ablauf pro Release

Voraussetzung: Das Build ist hochgeladen und die Notarization (oder
App-Store-Review) ist bestanden.

1. **ADP-ID holen.** App Store Connect → App → **Distribution → History** →
   „Alternative Distribution Package ID" kopieren.
2. **Skript ausführen** (auf dem Mac, braucht `curl`, `jq`, `unzip`, `gh`, `plutil`;
   `gh` muss am Fork-Account angemeldet sein):

   ```bash
   tool/altstore/publish_adp.sh <ADP-ID> --notes "Was ist neu in dieser Version"
   ```

   Das Skript
   - fragt `https://api.altstore.io/adps/<ADP-ID>` ab, stößt bei Bedarf die
     Verarbeitung an und wartet auf die `downloadURL`,
   - entpackt das ADP nach `.buildlog/adp/<ADP-ID>/` und prüft Bundle-ID,
     Version, Build und `bundleVersion`,
   - lädt `manifest.json`, `signature` und alle `.ipa` als Assets in ein
     GitHub Release `ios-<version>-<build>` hoch,
   - legt `web/altstore/source.json` beim ersten Lauf aus
     `tool/altstore/source.template.json` an, trägt die `marketplaceID` aus
     dem Manifest ein, aktualisiert `appPermissions` aus `Info.plist` und
     `Runner.entitlements` und stellt die neue Version an den Anfang von
     `versions`.

   Mit `--dry-run` passiert kein Upload und keine Änderung, das Skript zeigt
   nur den geplanten Versions-Eintrag. Mit `--zip datei.zip` lässt sich ein
   manuell (z. B. im Browser) geladenes ADP verwenden.
3. **Diff prüfen und committen:** `git diff web/altstore/source.json`.
4. **In `integration/ios-complete` mergen und pushen.** Der Push deployt die
   PWA und damit die Source. Achtung: Sobald die Datei online ist, ist das
   Update für alle Nutzer live. Zum Vorabtest die Datei zuerst unter einem
   anderen Namen (z. B. `source-staging.json`) deployen und mit dem
   `altstore-pal://source?url=…`-Link auf einem Testgerät hinzufügen.
5. **Freedom Store informieren** (nur beim ersten Mal nötig, danach lesen sie
   unsere Source oder wir schicken die neuen Werte, siehe Abschnitt 7).

## 6. Was in der Source steht und warum

`tool/altstore/source.template.json` ist die Vorlage, `web/altstore/source.json`
die generierte, live ausgelieferte Datei. Handarbeit ist nur in der Vorlage nötig,
bevor die erste Version erzeugt wird:

- `developerName`: aktuell „Einundzwanzig". Ggf. an den Vereinsnamen anpassen.
- `screenshots`: noch leer. AltStore nimmt ohne Größenangabe iPhone-Hochformat
  (393 × 852 pt) an. PNG-URLs eintragen, z. B. unter `web/altstore/screenshots/`.
- `localizedDescription`, `subtitle`: Store-Texte, frei änderbar.

Vom Skript gepflegt, nicht anfassen:

- `marketplaceID`: Apple-ID der App, aus `appleItemId` im Manifest.
- `appPermissions`: AltStore verweigert die Installation, wenn Entitlements oder
  Privacy-Strings nicht zur App passen. Deshalb werden sie bei jedem Lauf aus
  `ios/Runner/Info.plist` (alle `*UsageDescription`) und
  `ios/Runner/Runner.entitlements` gelesen. Sobald Passkeys aktiv sind, taucht
  `com.apple.developer.associated-domains` dort automatisch auf.
- `versions[]`: neueste zuerst. AltStore erkennt Updates am ersten Eintrag,
  nicht am Datum. Jeder PAL-Eintrag braucht zwingend `buildVersion`, sonst
  verwirft AltStore die ganze Source.
- `downloadURL` zeigt auf `manifest.json` im Release, `assetURLs` auf jede Datei
  einzeln (Schlüssel = Dateiname ohne Endung, bei IPAs also die Varianten-UUID).
- `size`: Größe der größten Variante in Bytes.
- `minOSVersion`: aus dem Manifest. Unabhängig davon braucht AltStore PAL
  selbst iOS 17.4.

## 7. Aufnahme in den Freedom Store

Es gibt kein Formular. Kontakt: **developers@freedomstore.io**. Kriterien sind
nicht öffentlich („vetted for privacy, security and censorship resistance"),
alle gelisteten Apps sind Open Source und aus dem Bitcoin-Umfeld.

Vorlage, sobald die erste Version live ist:

```
Betreff: Submission – Einundzwanzig Meetup App (open source, Nostr web of trust)

Hi Freedom Store team,

we would like to submit the Einundzwanzig Meetup App for the Freedom Store.

What it does: records attendance at Bitcoin meetups via rolling QR codes,
seals every badge with the organizer's Schnorr signature (BIP-340) and builds
a decentralised, locally stored trust score that users can show at P2P trades.
No server, no account, no KYC. MIT licensed.

Source code:   https://github.com/louisthecat86/Einundzwanzig-Meetup-App
AltStore source (notarized ADP, self-hosted):
               https://razue.github.io/Einundzwanzig-Meetup-App/altstore/source.json
Bundle ID:     dev.einundzwanzig.einundzwanzigMeetupApp
Marketplace ID: <marketplaceID aus source.json>
Developer:     Einundzwanzig e.V.
Contact:       <Vereins-E-Mail>

Everything you need for your source.json (icon, screenshots, versions,
appPermissions, download URLs) is in our source file above.

Thanks!
```

Der Freedom Store übernimmt unsere Einträge in seine eigene JSON. Die
Download-Links zeigen weiterhin auf unsere GitHub Releases.

## 8. Nutzeranleitung (für Website oder README)

Nur EU-Apple-ID, physisch in der EU, iOS 17.4 oder neuer.

1. AltStore PAL installieren: https://altstore.io/download
2. Diesen Link auf dem iPhone öffnen:
   `altstore-pal://source?url=https://razue.github.io/Einundzwanzig-Meetup-App/altstore/source.json`
   (oder in AltStore PAL unter Sources → „+" die URL eintragen)
3. „Einundzwanzig Meetup App" antippen und installieren. Updates meldet
   AltStore PAL selbst.

Sobald die App im Freedom Store gelistet ist, reicht alternativ dessen Source
(`https://source.freedomstore.io/`).

## 9. Fehlersuche

- **„Invalid License" / „No Valid License" bei der Installation:** Das Paket ist
  in Ordnung — Apples Lizenzserver verweigert die Installationslizenz. Das ist
  ein Zustand am ENTWICKLER-ACCOUNT, nicht an den Release-Dateien. Geprüft am
  04.10.2026 für 1.6.6 (29): frisch von Apple via AltStore-API gezogenes ADP ist
  byte-identisch mit dem veröffentlichten (`POST https://api.altstore.io/adps`
  mit `{"adpID": "…"}` anstoßen, dann `GET /adps/<id>` bis `downloadURL` kommt).
  Übliche Ursachen, in dieser Reihenfolge prüfen:
  1. **Ausstehende Lizenzvereinbarung** im Developer-Account
     (developer.apple.com/account → Agreements, bzw. Banner in App Store
     Connect). Die EU-Zusatzvereinbarung (Attachment 14) ist verpflichtend seit
     01.10.2026 — ohne Annahme stellt Apple ab dem Stichtag keine
     Installationslizenzen mehr aus, für ALLE Versionen.
  2. **Marktplatz-Verknüpfung weg:** App Store Connect → Users and Access →
     Integrations → Marketplace — AltStore PAL muss eingetragen und die App
     ausgewählt sein.
  3. **Mitgliedschaft abgelaufen:** developer.apple.com/account → Membership.
  Nach dem Beheben (Vereinbarung annehmen) sofort erneut auf dem Gerät
  probieren — die Assets müssen nicht neu veröffentlicht werden.
- **Keine `downloadURL` von api.altstore.io:** Notarization noch nicht bestanden,
  oder AltStore PAL ist in App Store Connect nicht als Marktplatz für diese App
  ausgewählt. Das Skript stößt die Verarbeitung per `POST /adps` an und wartet
  bis zu 20 Minuten.
- **„Manifest gehört zu … erwartet …":** Falsche ADP-ID (andere App).
- **AltStore zeigt die App, Installation schlägt fehl:** Meist passen
  `appPermissions` nicht. Skript erneut laufen lassen, damit Info.plist und
  Entitlements frisch eingelesen werden. Oder eine Asset-URL liefert 404:
  `gh release view ios-<version>-<build> --repo Razue/Einundzwanzig-Meetup-App`.
- **Update wird nicht angezeigt:** Neuer Eintrag muss an Position 0 in
  `versions` stehen und sich in `version` oder `buildVersion` unterscheiden.
- **Source lädt nicht:** JSON validieren (`jq . web/altstore/source.json`) und
  prüfen, ob der Pages-Deploy aus `integration/ios-complete` gelaufen ist.

## 10. Alternative ohne AltStore-API

Falls `api.altstore.io` nicht liefert, lässt sich das ADP direkt über die
App Store Connect API holen (API-Key nötig): `GET
/v1/appStoreVersions/{id}/alternativeDistributionPackage?include=versions`
liefert pro Version eine `url` (Zip mit `manifest.json` und `signature`),
`GET /v1/alternativeDistributionPackageVersions/{id}/variants` die
Download-URLs der einzelnen IPAs. Zusammengesetzt als Verzeichnis
`manifest.json`, `signature`, `variant/<uuid>.ipa` und gezippt kann es dem
Skript mit `--zip` übergeben werden. Öffentliche Referenzen:
[stellar-mls/publish-to-altstore.py](https://github.com/rinat-enikeev/stellar-mls/blob/main/scripts/publish-to-altstore.py),
[JSTorrent/fetch-adp.py](https://github.com/kzahel/JSTorrent/blob/main/ios/scripts/fetch-adp.py).

## Quellen

- AltStore: [Distribute with AltStore PAL](https://faq.altstore.io/developers/distribute-with-altstore-pal),
  [REST API](https://faq.altstore.io/developers/rest-api),
  [Make a Source](https://faq.altstore.io/developers/make-a-source),
  [Updating Apps](https://faq.altstore.io/developers/updating-apps),
  [App Guidelines](https://faq.altstore.io/developers/app-guidelines)
- Apple: [Changes for apps in the EU](https://developer.apple.com/support/dma-and-apps-in-the-eu/),
  [Payment options in the EU](https://developer.apple.com/support/payment-options-on-the-app-store-in-the-eu/),
  [Get an ADP ID](https://developer.apple.com/help/app-store-connect/managing-alternative-distribution/get-an-alternative-distribution-package-id)
- Freedom Store: [freedomstore.io](https://freedomstore.io/), [Source-JSON](https://source.freedomstore.io/)
- GitHub: [Pages-Limits](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits)
