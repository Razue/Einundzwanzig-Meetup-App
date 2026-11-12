#!/usr/bin/env bash
# Spielt am Emulator die Update-Kette 1.6.8 -> 1.7.3 -> Fix durch und prüft
# nach jedem Schritt das App-Log.
#
# Aufruf: esp_migration.sh <apk-verzeichnis> <fixture.xml> <ausgabe-verzeichnis>
set -uo pipefail

APKS=$1
FIXTURE=$2
OUT=$3
HERE=$(cd "$(dirname "$0")" && pwd)
PKG=space.einundzwanzig.meetup
PREFS=/data/data/$PKG/shared_prefs
RAW=$(mktemp -d) # Rohdateien mit Schlüsselmaterial bleiben außerhalb des Artefakts
mkdir -p "$OUT"
FAILED=0

# Startet die App, lässt sie laufen und holt danach Log und Speicherzustand.
# 45 s: der Start ist durch und das Log (2 s Verzögerung) geschrieben.
run_app() {
  local label=$1
  adb logcat -c
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null
  sleep 45
  adb shell am force-stop "$PKG"
  sleep 3
  adb shell "cat $PREFS/FlutterSharedPreferences.xml" > "$RAW/prefs.xml"
  adb shell "cat $PREFS/FlutterSecureStorage.xml 2>/dev/null" > "$RAW/secure.xml"
  adb logcat -d -s FlutterSecureStorage > "$OUT/$label-logcat.txt"
  echo "===== $label ====="
  python3 "$HERE/dump_state.py" "$RAW/prefs.xml" "$RAW/secure.xml" | tee "$OUT/$label.txt"
}

# Erwartet einen Text im Log des letzten Starts.
expect() {
  local label=$1 text=$2
  if grep -qF -- "$text" "$OUT/$label.txt"; then
    echo "OK     [$label] $text" | tee -a "$OUT/ergebnis.txt"
  else
    echo "FEHLT  [$label] $text" | tee -a "$OUT/ergebnis.txt"
    FAILED=1
  fi
}

adb root
adb wait-for-device
sleep 3

# --- 1.6.8 mit Altdaten ---
adb install "$APKS/v168.apk" || exit 1
APP_UID=$(adb shell stat -c %u "/data/data/$PKG" | tr -d '\r')
adb push "$FIXTURE" /data/local/tmp/fixture.xml > /dev/null
adb shell "mkdir -p $PREFS && cp /data/local/tmp/fixture.xml $PREFS/FlutterSharedPreferences.xml"
adb shell "chown -R $APP_UID:$APP_UID $PREFS && chmod 771 $PREFS && chmod 660 $PREFS/*.xml"
adb shell "restorecon -R /data/data/$PKG"

run_app 1-v168-erster-start
# Zweiter Start: zeigt, dass 1.6.8 die verschlüsselte Datei selbst wieder
# öffnet, der Ausgangszustand also stimmt.
run_app 2-v168-zweiter-start
expect 2-v168-zweiter-start "Bestand: 3 Badge(s)"

# --- Update auf 1.7.3: hier soll der Fehler auftreten ---
adb install -r "$APKS/v173.apk" || exit 1
run_app 3-v173-nach-update
expect 3-v173-nach-update "Badge-Datei nicht entschlüsselbar"
expect 3-v173-nach-update "Bestand: 0 Badge(s)"

# --- Update auf den Fix ---
adb install -r "$APKS/fix.apk" || exit 1
run_app 4-fix-erster-start
expect 4-fix-erster-start "Aus dem alten sicheren Speicher übernommen"
expect 4-fix-erster-start "badge_encryption_key"
expect 4-fix-erster-start "nostr_nsec_key"
# Beim ersten Start kann die Bestandszeile noch vor der Übernahme ins Log
# gekommen sein; der zweite Start ist eindeutig.
run_app 5-fix-zweiter-start
expect 5-fix-zweiter-start "Bestand: 3 Badge(s)"

echo
echo "===== Ergebnis ====="
cat "$OUT/ergebnis.txt"
exit $FAILED
