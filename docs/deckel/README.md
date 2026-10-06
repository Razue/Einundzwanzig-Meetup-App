# Deckel — anschreiben, Kassensturz, nur die Differenz zahlen

Idee 3 aus dem bitcoin++-Hackathon, gebaut auf 1.6.6 mit Sprach Wallet (`feat/voice-cashu-iphone`, Commit `1edad4d`).
Zweig `feat/deckel`, Arbeitsverzeichnis `.worktrees/deckel166`. Nichts ist committet. Enthält seit 2026-10-02 auch den uncommitteten Stand aus `voice166` (siehe unten).

## In einem Satz

Am Tisch zahlt mal der eine, mal die andere; der Deckel merkt sich die Runden, und beim Kassensturz bleibt für jeden nur die Differenz — als eine Zahlung, die genau einmal rausgeht.

Drei Runden unter drei Leuten: **6 Schulden über 18.400 Sats werden 2 Zahlungen über 3.400 Sats.**

## In zwei Minuten zeigen

1. Kachel **Deckel** auf dem Startbildschirm, dann **Demo-Tisch**. Anna und Ben setzen sich und geben Bier und Pizza aus. Oben steht: „7.200 schuldest du".
2. Mikrofon antippen: **„Runde 6000 für Taxi"**. Die Seite fragt nach, **„Ja"**. Jetzt: „3.200 schuldest du".
3. **„Kassensturz"**, **„Ja"**. Durchgestrichen „6 Schulden · 18.400 Sats", darunter „2 Zahlungen · 3.400 Sats". Ben zahlt Anna von selbst.
4. **Zahlen** antippen: der Token als QR. Anna „scannt", der Haken erscheint, „Alles beglichen".
5. Der Satz dazu: *Zweimal auf Zahlen tippen zeigt denselben Code. Es geht kein zweites Mal Geld raus.*

Der Demo-Tisch läuft auf einem Handy, mit Spielgeld, ohne Netz und ohne die echte Wallet. Für einen Bildschirm, den niemand bedient: `flutter run -t lib/deckel_preview.dart` spielt den Abend von selbst durch.

Mit echten Handys: **Neuer Deckel** zeigt den QR-Code, die anderen scannen ihn (Scanner der App oder **Deckel scannen**) und nehmen Platz. `docs/deckel/bierdeckel.html` ist ein A4-Bogen mit vier Bierdeckeln zum Ausdrucken (Tisch 1 bis 4).

## Sprachbefehle

Deutsch und englisch, dieselbe Erkennung auf dem Gerät wie in der Sprach Wallet.

| Sagen | Passiert |
|---|---|
| „Runde 12600 für Bier" | Runde für alle am Tisch, nach „Ja" |
| „4200 pro Kopf für Pizza" | Betrag mal Köpfe am Tisch |
| „Deckel" | mein Stand |
| „Kassensturz" | abrechnen, nach „Ja" |
| „Zahlen" | meinen Rest als Token zeigen, nach „Ja" |
| „Einlösen" | Token scannen und quittieren |
| „Wette 2000 auf Ja" | auf die Frage des Orakels wetten, nach „Ja" |

Alles geht auch mit Tippen: **Runde**, **Kassensturz**, **Zahlen**, **Einlösen**. Lange auf **Einlösen** drücken quittiert eine Zahlung, die auf anderem Weg kam (bar, andere Wallet).

## Wetten am Tisch (seit 2026-10-02, 11:30)

Die Kachel zeigt die Frage, auf die sich das Kickstr-Orakel zuletzt festgelegt hat, und was der Glimpse-Markt dazu sagt: „Bitcoin um 13:00 bei oder über 86.000 USD? Markt: Ja 55 %".

- **Wetten:** „Wette 2000 auf Ja" sagen oder **Ja** / **Nein** antippen. Die Wette gilt, sobald jemand anderes am Tisch denselben Betrag dagegen hält.
- **Auflösung:** Die App prüft das Geheimnis des Orakels gegen seine Festlegung. Danach steht die Wette als Zeile auf dem Blatt: Der Verlierer schuldet dem Gewinner den Betrag, und beim Kassensturz wird sie mit allem anderen verrechnet.
- **Das ist ein Handschlag, kein gesperrter Topf.** Die Wette mit gesperrtem Topf auf dasselbe Orakel läuft im Terminal (`btcpp_hack/handschlag`).
- **Demo-Tisch:** Ein gespieltes Orakel stellt eine Frage; Ben hält gegen deine Wette, kurz darauf löst es mit Ja auf.
- **Geprüft:** 15 Tests für Orakel und Wetten, der Ablauf per Stimme in der Oberfläche, und das echte Orakel über das Netz (11 Fragen, 10 geprüfte Auflösungen). **Nicht geprüft:** zwei echte Handys.

## Was gebaut ist

| Teil | Datei |
|---|---|
| Verrechnung (reine Rechnung) | `lib/services/deckel/deckel_netting.dart` |
| Ereignisse, Regeln, QR-Code | `lib/services/deckel/deckel_events.dart` |
| Signieren, Relays, Tisch im Speicher | `lib/services/deckel/deckel_backend.dart` |
| Genau einmal zahlen | `lib/services/deckel/deckel_ledger.dart` |
| Ein Tisch aus Sicht eines Teilnehmers | `lib/services/deckel/deckel_table.dart` |
| Sprachbefehle | `lib/services/deckel/deckel_command.dart` |
| Demo-Tisch | `lib/services/deckel/deckel_demo.dart` |
| Seite | `lib/screens/deckel_screen.dart` |
| Selbstläufer | `lib/deckel_preview.dart` |

In vorhandenen Dateien geändert: eine Kachel in `home_screen.dart`, der Code `21d:` in `qr_scanner.dart`, 73 Texte in den drei Sprachdateien. Die Sprach Wallet selbst ist unberührt; der Deckel zahlt aus ihrem Guthaben.

Das Protokoll steht in [`SPEC.md`](SPEC.md) (englisch, für die Einreichung).

## Geprüft

| Was | Wie | Ergebnis |
|---|---|---|
| Analyse | `flutter analyze` | ohne Befund |
| Tests der App | `flutter test` | 368 grün, davon 72 neu für den Deckel |
| Verrechnung | 200 zufällige Abende: Salden ergeben null, Zahlungen gleichen genau aus | grün |
| Ganzer Abend mit drei Schlüsseln über echte Relays | `dart run tool/deckel/relay_check.dart` | siehe unten |
| Ganzer Abend gegen einen echten Mint mit Spiel-Sats | `flutter test test_network/deckel_testnut_test.dart` | grün: Clara 4.095 → 894, Ben 511 → 310, Anna 0 → 3.398 |
| Seite im iPhone-Simulator | Selbstläufer, Bildschirmfotos in `img/` | läuft |
| Gedruckte QR-Codes | im Browser entschlüsselt | alle vier richtig |

**Relays am 2026-10-02:** Von den vier Standard-Relays der App nahm nur `nos.lol` Ereignisse von einem unbekannten Schlüssel an. `relay.damus.io` antwortete mit 503, `relay.nostr.band` gar nicht, `nostr.einundzwanzig.space` verlangt eine NIP-05-Adresse. Der Deckel nimmt deshalb zusätzlich `relay.primal.net` und `nostr.mom`; beide bestanden den ganzen Abend, ebenso `relay.snort.social` und `offchain.pub`.

## Nicht geprüft

- **Zwei echte Handys an einem Tisch.** Der Weg über Relays ist mit dem Prüfwerkzeug gelaufen, die Seite nur mit dem Demo-Tisch und in Tests.
- **Mikrofon und Kamera auf einem echten Gerät.** Im Test spricht ein Stellvertreter; der Simulator hat beides nicht.
- **Echte Sats.** Gelaufen sind Spiel-Sats auf einem echten Mint.
- **Die Kachel auf dem Startbildschirm** habe ich nicht gesehen, nur gebaut und analysiert.
- **Android und Amber.** Jede Runde löst dort eine Freigabe in Amber aus.

## Was es nicht löst

- Niemand wird gezwungen zu zahlen. Der Hebel ist der Ruf: ein offener Deckel ist öffentlich.
- Wer wem was schuldet, ist auf dem Relay lesbar.
- Wer zahlt, kann eine Runde behaupten, die es nicht gab. Alle am Tisch sehen sie sofort.
- Der Empfänger muss dem Mint des Zahlers trauen.
- Stürzt die App ab, nachdem die Wallet den Token erzeugt hat und bevor er gemerkt ist, ist dieser Betrag weg.

## Wo es außer am Stammtisch passt

Überall, wo eine Gruppe in Runden zahlt und später ausgleicht. Dieselben vier Ereignisse, nichts Neues zu bauen:

| Wo | Was eine Runde ist |
|---|---|
| Rechnung im Restaurant, WG, Urlaub | einer zahlt, alle teilen |
| Skat, Schafkopf, Poker, Darts | jedes Spiel; der Abend endet mit einer Zahlung pro Kopf |
| Tipprunde (auch mit Kickstr) | jeder Spieltag; die Saison endet mit einer Zahlung pro Kopf |
| Strichliste im Hackerspace, Vereinsheim, Büro | jeder Strich; einmal im Monat Kassensturz |
| Veranstalter eines Meetups | Raum, Pizza, Aufkleber, von drei Leuten ausgelegt |
| Händler, die voneinander kaufen | jede Lieferung; wer so viel bekommt, wie er schuldet, zahlt nichts und braucht kein Guthaben |

Der letzte Fall ist der größte: In einem Kreislauf mit wenig Guthaben in den Wallets spart Verrechnen nicht nur Zahlungen, sondern macht sie erst möglich.

## Zusammengeführt mit dem Sprach-Wallet-Zweig

Seit 2026-10-02 09:35 enthält dieses Verzeichnis auch die uncommitteten Änderungen aus `.worktrees/voice166` (Stand dort: 03:03): Bark in der Sprach Wallet und der Kickstr-Tipp per QR (`21k:`). Elf Dateien ließen sich unverändert übernehmen, acht neue wurden kopiert, darunter die lokale `bark_local.dart` mit dem Zugriff auf dein barkd (bleibt außerhalb von git). `lib/screens/qr_scanner.dart` ist von Hand zusammengeführt: der Scanner kennt jetzt beide Codes, `21d:` für den Deckel und `21k:` für Kickstr. Die Sprachdateien sind mit `flutter gen-l10n` neu erzeugt.

Stand danach: 348 Tests grün. Die Analyse meldet eine Warnung in `test/bark_client_test.dart:97` (überflüssiger Cast); sie stammt aus `voice166` und steht dort genauso.

`voice166` selbst ist unverändert. Ändert sich dort noch etwas, kommt es nicht von selbst hierher.

## Nächste Schritte, nach Nutzen

1. „Deckel" als Befehl in der Sprach Wallet, der diese Seite öffnet.
2. Token, die an den Schlüssel des Empfängers gebunden sind (NUT-11): zahlen ohne Scannen.
3. Der Trust Score als Grenze, wie viel jemand anschreiben darf.
4. Verschlüsselte Deckel.
