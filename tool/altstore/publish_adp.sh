#!/usr/bin/env bash
# Veroeffentlicht ein von Apple notarisiertes Alternative Distribution Package
# (ADP) fuer AltStore PAL:
#
#   1. ADP ueber die AltStore-API holen (oder ein lokales Zip verwenden)
#   2. Paket pruefen (Bundle-ID, Version, Manifest)
#   3. Dateien als GitHub-Release-Assets hochladen
#   4. web/altstore/source.json um die neue Version ergaenzen
#
# Das Ergebnis (source.json) wird NICHT committet – das machst du selbst.
# Danach: in den Pages-Branch mergen, damit die Source live geht.
#
# Aufruf:
#   tool/altstore/publish_adp.sh <ADP-ID> [--notes "Was ist neu"] [--dry-run]
#   tool/altstore/publish_adp.sh --zip pfad/zum/adp.zip [--notes "..."] [--dry-run]
#
# Die ADP-ID steht in App Store Connect unter
#   App -> Distribution -> History -> "Alternative Distribution Package ID".
#
# Details: docs/ALTSTORE_PAL.md

set -euo pipefail

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------
GITHUB_REPO="Razue/Einundzwanzig-Meetup-App"   # hier liegen Releases + Pages
BUNDLE_ID="dev.einundzwanzig.einundzwanzigMeetupApp"
ALTSTORE_API="https://api.altstore.io"
POLL_SECONDS=30
POLL_MAX_MINUTES=20

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEMPLATE="$REPO_ROOT/tool/altstore/source.template.json"
SOURCE_JSON="$REPO_ROOT/web/altstore/source.json"
INFO_PLIST="$REPO_ROOT/ios/Runner/Info.plist"
ENTITLEMENTS="$REPO_ROOT/ios/Runner/Runner.entitlements"
WORK_ROOT="$REPO_ROOT/.buildlog/adp"          # gitignored

# ---------------------------------------------------------------------------
# Argumente
# ---------------------------------------------------------------------------
ADP_ID=""
ZIP_FILE=""
NOTES=""
DRY_RUN=0

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --zip)     ZIP_FILE="${2:-}"; shift 2 ;;
    --notes)   NOTES="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage ;;
    -*)        echo "Unbekannte Option: $1"; usage ;;
    *)         ADP_ID="$1"; shift ;;
  esac
done
[ -n "$ADP_ID" ] || [ -n "$ZIP_FILE" ] || usage

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[31m==> FEHLER:\033[0m %s\n' "$*" >&2; exit 1; }

for tool in curl jq unzip gh plutil; do
  command -v "$tool" >/dev/null || die "'$tool' fehlt."
done
[ -f "$INFO_PLIST" ] || die "Info.plist nicht gefunden: $INFO_PLIST"

# ---------------------------------------------------------------------------
# 1. ADP beschaffen
# ---------------------------------------------------------------------------
mkdir -p "$WORK_ROOT"

if [ -z "$ZIP_FILE" ]; then
  WORK_DIR="$WORK_ROOT/$ADP_ID"
  ZIP_FILE="$WORK_DIR/adp.zip"
  mkdir -p "$WORK_DIR"

  say "Frage AltStore nach ADP $ADP_ID ..."
  response="$(curl -sS "$ALTSTORE_API/adps/$ADP_ID")"
  download_url="$(printf '%s' "$response" | jq -r '.downloadURL // empty')"

  if [ -z "$download_url" ]; then
    warn "Noch keine downloadURL. Status: $(printf '%s' "$response" | jq -c '.status // .')"
    say "Stosse Verarbeitung bei AltStore an ..."
    curl -sS -H "Content-Type: application/json" -X POST \
      --data "{\"adpID\": \"$ADP_ID\"}" "$ALTSTORE_API/adps" >/dev/null || true

    waited=0
    while [ -z "$download_url" ]; do
      [ "$waited" -lt $((POLL_MAX_MINUTES * 60)) ] \
        || die "Nach $POLL_MAX_MINUTES Minuten immer noch keine downloadURL. Spaeter erneut versuchen."
      sleep "$POLL_SECONDS"; waited=$((waited + POLL_SECONDS))
      response="$(curl -sS "$ALTSTORE_API/adps/$ADP_ID")"
      download_url="$(printf '%s' "$response" | jq -r '.downloadURL // empty')"
      say "  warte ... (${waited}s, Status: $(printf '%s' "$response" | jq -r '.status // "?"'))"
    done
  fi

  say "Lade ADP herunter ..."
  curl -sSL -o "$ZIP_FILE" "$download_url"
else
  [ -f "$ZIP_FILE" ] || die "Zip nicht gefunden: $ZIP_FILE"
  WORK_DIR="$WORK_ROOT/$(basename "$ZIP_FILE" .zip)"
  mkdir -p "$WORK_DIR"
fi
ok "ADP-Zip: $ZIP_FILE ($(du -h "$ZIP_FILE" | cut -f1 | tr -d " "))"

# ---------------------------------------------------------------------------
# 2. Entpacken und pruefen
# ---------------------------------------------------------------------------
EXTRACT_DIR="$WORK_DIR/extracted"
rm -rf "$EXTRACT_DIR"; mkdir -p "$EXTRACT_DIR"
unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR"

MANIFEST="$(find "$EXTRACT_DIR" -name manifest.json -not -path '*/__MACOSX/*' | head -1)"
[ -n "$MANIFEST" ] || die "Kein manifest.json im Zip."
ADP_ROOT="$(dirname "$MANIFEST")"

m_bundle="$(jq -r '.bundleId' "$MANIFEST")"
[ "$m_bundle" = "$BUNDLE_ID" ] || die "Manifest gehoert zu '$m_bundle', erwartet '$BUNDLE_ID'."

VERSION="$(jq -r '.shortVersionString' "$MANIFEST")"
BUILD="$(jq -r '.bundleVersion' "$MANIFEST")"
MIN_OS="$(jq -r '.minimumSystemVersions.ios // empty' "$MANIFEST")"
APPLE_ITEM_ID="$(jq -r '.appleItemId' "$MANIFEST")"
[ -n "$BUILD" ] && [ "$BUILD" != "null" ] || die "Manifest ohne bundleVersion – AltStore lehnt Eintraege ohne buildVersion ab."

# Frueh pruefen, bevor etwas hochgeladen wird
if [ -f "$SOURCE_JSON" ]; then
  existing_mid="$(jq -r --arg b "$BUNDLE_ID" '.apps[] | select(.bundleIdentifier==$b) | .marketplaceID' "$SOURCE_JSON")"
  if [ -n "$existing_mid" ] && [ "$existing_mid" != "$APPLE_ITEM_ID" ]; then
    die "marketplaceID in source.json ($existing_mid) passt nicht zur Apple-ID im Manifest ($APPLE_ITEM_ID)."
  fi
fi

# Dateien, die AltStore braucht: manifest.json, signature, alle .ipa
FILES="$MANIFEST"
if [ -f "$ADP_ROOT/signature" ]; then
  FILES="$FILES
$ADP_ROOT/signature"
else
  warn "Keine 'signature'-Datei im ADP gefunden – pruefen, ob das Paket vollstaendig ist."
fi
IPAS="$(find "$ADP_ROOT" -name '*.ipa' | sort)"
[ -n "$IPAS" ] || die "Keine .ipa-Varianten im ADP."
FILES="$FILES
$IPAS"

# Groesse: groesste Variante (AltStore: "pick any of the variants")
SIZE="$(find "$ADP_ROOT/variant" -name '*.ipa' -exec stat -f %z {} \; 2>/dev/null | sort -n | tail -1)"
[ -n "$SIZE" ] || SIZE="$(printf '%s\n' "$IPAS" | head -1 | xargs stat -f %z)"

ok "Version $VERSION ($BUILD), minOS ${MIN_OS:-?}, Apple-ID $APPLE_ITEM_ID, $(printf '%s\n' "$IPAS" | wc -l | tr -d ' ') IPA-Datei(en), Groesse $SIZE Bytes"

# ---------------------------------------------------------------------------
# 3. GitHub Release
# ---------------------------------------------------------------------------
TAG="ios-${VERSION}-${BUILD}"          # kein '+' im Tag (URL-Probleme)
RELEASE_BASE="https://github.com/$GITHUB_REPO/releases/download/$TAG"
RELEASE_TITLE="iOS $VERSION ($BUILD) – AltStore PAL"
RELEASE_BODY="Notarisiertes Alternative Distribution Package fuer AltStore PAL.
Nicht direkt installierbar – Installation ueber die AltStore-Source:
https://razue.github.io/Einundzwanzig-Meetup-App/altstore/source.json"

if [ "$DRY_RUN" -eq 1 ]; then
  warn "--dry-run: kein Release-Upload. Wuerde hochladen nach $RELEASE_BASE/:"
  printf '%s\n' "$FILES" | sed 's#^#    #'
else
  if gh release view "$TAG" --repo "$GITHUB_REPO" >/dev/null 2>&1; then
    say "Release $TAG existiert, Assets werden ersetzt ..."
    printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 gh release upload "$TAG" --repo "$GITHUB_REPO" --clobber
  else
    say "Erstelle Release $TAG ..."
    printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 gh release create "$TAG" --repo "$GITHUB_REPO" \
      --title "$RELEASE_TITLE" --notes "$RELEASE_BODY"
  fi
  ok "Assets liegen unter $RELEASE_BASE/"
fi

# assetURLs: Dateiname ohne Endung -> URL (erlaubt Hosting ohne Verzeichnisstruktur)
ASSET_URLS="$(printf '%s\n' "$FILES" | while IFS= read -r f; do
  name="$(basename "$f")"
  printf '{"key":"%s","url":"%s/%s"}\n' "${name%.*}" "$RELEASE_BASE" "$name"
done | jq -s 'map({(.key): .url}) | add')"

# ---------------------------------------------------------------------------
# 4. source.json aktualisieren
# ---------------------------------------------------------------------------
SOURCE_INPUT="$SOURCE_JSON"
if [ ! -f "$SOURCE_JSON" ]; then
  say "web/altstore/source.json existiert noch nicht – wird aus dem Template erzeugt."
  SOURCE_INPUT="$TEMPLATE"
fi

PRIVACY="$(plutil -convert json -o - "$INFO_PLIST" \
  | jq 'to_entries | map(select(.key | test("UsageDescription$"))) | from_entries')"
if [ -f "$ENTITLEMENTS" ]; then
  ENTITLEMENT_KEYS="$(plutil -convert json -o - "$ENTITLEMENTS" | jq 'keys')"
else
  ENTITLEMENT_KEYS='[]'
fi

[ -n "$NOTES" ] || NOTES="Version $VERSION"
# UTC-Instant, nicht nur YYYY-MM-DD: AltStore wertet ein Datum ohne Uhrzeit
# als 00:00 UTC aus. Nach Mitternacht Ortszeit waere das sonst in der Zukunft
# und der Install-Knopf zaehlt runter statt zu installieren.
TODAY="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

NEW_SOURCE="$(jq \
  --arg bundle "$BUNDLE_ID" \
  --arg mid "$APPLE_ITEM_ID" \
  --arg version "$VERSION" \
  --arg build "$BUILD" \
  --arg date "$TODAY" \
  --arg notes "$NOTES" \
  --arg dl "$RELEASE_BASE/manifest.json" \
  --argjson size "$SIZE" \
  --arg minos "$MIN_OS" \
  --argjson assets "$ASSET_URLS" \
  --argjson privacy "$PRIVACY" \
  --argjson ents "$ENTITLEMENT_KEYS" '
  ( {version: $version, buildVersion: $build, marketingVersion: ($version + " (" + $build + ")"),
     date: $date, localizedDescription: $notes, downloadURL: $dl, size: $size, assetURLs: $assets}
    + (if $minos != "" then {minOSVersion: $minos} else {} end) ) as $entry
  | .apps |= map(
      if .bundleIdentifier == $bundle then
        (if .marketplaceID == "" then .marketplaceID = $mid
         elif .marketplaceID != $mid then error("marketplaceID " + .marketplaceID + " passt nicht zum Manifest (" + $mid + ")")
         else . end)
        | .appPermissions = {entitlements: $ents, privacy: $privacy}
        | .versions = ([$entry] + (.versions | map(select(.version != $version or .buildVersion != $build))))
      else . end)
' "$SOURCE_INPUT")"

if [ "$DRY_RUN" -eq 1 ]; then
  warn "--dry-run: source.json wird nicht geschrieben. Neuer Versions-Eintrag:"
  printf '%s' "$NEW_SOURCE" | jq --arg b "$BUNDLE_ID" '.apps[] | select(.bundleIdentifier==$b) | .versions[0]'
  exit 0
fi

mkdir -p "$(dirname "$SOURCE_JSON")"
printf '%s\n' "$NEW_SOURCE" > "$SOURCE_JSON"
ok "web/altstore/source.json aktualisiert (Version $VERSION ($BUILD) steht jetzt vorne)."

cat <<EOF

Naechste Schritte:
  1. Aenderung pruefen:   git diff web/altstore/source.json
  2. Committen und in den Pages-Branch (integration/ios-complete) mergen –
     der Push deployt die PWA und damit die Source.
  3. Testen (iPhone mit AltStore PAL):
     altstore-pal://source?url=https://razue.github.io/Einundzwanzig-Meetup-App/altstore/source.json
  4. Freedom Store informieren (developers@freedomstore.io), siehe docs/ALTSTORE_PAL.md.

Lokale Kopie des ADP: $ADP_ROOT
EOF
