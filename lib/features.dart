// FUNKTIONSSCHALTER
// ============================================
// Ein Ort fuer Funktionen, die abgeschaltet, aber nicht geloescht sind.
//
// Warum abschalten statt loeschen: Der NFC-Code ist ueber Jahre gewachsen —
// Tag-Format, Groessenpruefung, Fehlerbehandlung fuer halb beschriebene
// Tags. Wer ihn entfernt und spaeter zurueckwill, schreibt ihn neu. Ein
// Schalter kostet dagegen nichts und macht die Rueckkehr zu einer Zeile.
//
// Die Schalter sind `const`. Der Uebersetzer erkennt unerreichbare Zweige
// und wirft sie beim Bauen ohnehin heraus — die abgeschaltete Funktion
// landet also nicht im fertigen Programm.
// ============================================

/// NFC — Tags beschreiben und lesen.
///
/// Abgeschaltet seit August 2026. Gruende:
///   - Der Rolling QR funktioniert zuverlaessiger und geraeteuebergreifend.
///   - Unter iOS ist NFC an Einschraenkungen gebunden, die den Ablauf
///     zusaetzlich verkomplizieren.
///   - Zwei Wege zum selben Ziel bedeuten doppelten Testaufwand bei jedem
///     Umbau am Badge-Format.
///
/// Beim Wiedereinschalten pruefen: NFC-Berechtigungen im Android-Manifest,
/// `Runner.entitlements` (NDEF/TAG) und `NFCReaderUsageDescription` in
/// der Info.plist, und ob das Badge-Payload noch auf ein NTAG215 passt —
/// Event-Badges tragen inzwischen einen Event-Verweis von rund 110 Zeichen.
const bool kNfcEnabled = false;

/// Lokaler nsec im Browser — Anlegen oder Importieren eines Schluessels,
/// der dann (verschluesselt, aber im selben Origin wie jedes geladene
/// Skript) im Browser-Speicher liegt.
///
/// Abgeschaltet seit Oktober 2026 (Security Audit H4): Im Web ist der
/// Schluessel schwaecher geschuetzt als in den nativen Apps — ein einziges
/// XSS reicht, um ihn abzugreifen. Web-Nutzer werden auf NIP-07
/// (Browsererweiterung) oder Bunker (NIP-46) gelenkt; dort verlaesst der
/// nsec die Erweiterung bzw. den Signer nie.
///
/// Beim Wiedereinschalten pruefen: Speicherung ausschliesslich als
/// ncryptsec (NIP-49) mit Passwort, kein Klartext-Aequivalent im
/// localStorage, CSP in web/index.html aktuell.
const bool kWebLocalNsecLoginEnabled = false;
