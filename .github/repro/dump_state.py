#!/usr/bin/env python3
"""Liest das App-Log und die Eintragsnamen des sicheren Speichers aus den
vom Emulator geholten XML-Dateien. Werte des sicheren Speichers werden nie
ausgegeben, nur Namen.

Aufruf: dump_state.py <FlutterSharedPreferences.xml> <FlutterSecureStorage.xml>
"""
import datetime
import json
import os
import sys
import xml.etree.ElementTree as ET

SECURE_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg_"


def entries(path):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return {}
    return {e.get("name"): (e.text or "") for e in ET.parse(path).getroot()}


prefs = entries(sys.argv[1])
log = json.loads(prefs.get("flutter.diagnostic_log") or "[]")
# Nur der letzte Start zählt für die Prüfungen.
start = max((i for i, e in enumerate(log) if "APP-START" in e.get("m", "")), default=0)
print("--- App-Log, letzter Start ---")
for e in log[start:]:
    t = datetime.datetime.fromtimestamp(e["t"] / 1000).strftime("%H:%M:%S")
    print(f'{t}  {e["l"]:5}  {e["g"]}: {e["m"]}')

print("--- Sicherer Speicher: Eintragsnamen ---")
names = entries(sys.argv[2])
if not names:
    print("(Datei fehlt oder ist leer)")
for name in sorted(names):
    if name.startswith(SECURE_PREFIX):
        print("  neu (Plugin 10):", name[len(SECURE_PREFIX):])
    elif name.startswith("__androidx_security_crypto"):
        print("  alt (Keyset):   ", name)
    else:
        print("  alt (Name verschlüsselt):", name[:16] + "…")
