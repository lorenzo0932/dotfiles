#!/bin/bash
# Notifica via MQTT i download AniDownloader completati (solo se scaricati E
# convertiti: file episodio presente e stabile da 15 minuti). Nessuna notifica
# per download/conversioni fallite o in corso.
set -euo pipefail

JSON="$HOME/.config/AniDownloader/series_data.json"
STATE_DIR="$HOME/.local/state/anidownloader"
STATE_FILE="$STATE_DIR/last_notified.json"
MQTT_HOST="192.168.1.39"

[ -f "$HOME/.config/mqtt.env" ] && source "$HOME/.config/mqtt.env"
MQTT_USER="${MQTT_USER:-lorenzo}"
if [ -z "${MQTT_PASS:-}" ]; then
    echo "ERRORE: MQTT_PASS non impostato (~/.config/mqtt.env)" >&2
    exit 1
fi
mkdir -p "$STATE_DIR"

OUT=$(python3 - "$JSON" "$STATE_FILE" <<'PY'
import json
import os
import sys
import time
import xml.etree.ElementTree as ET

jf, sf = sys.argv[1], sys.argv[2]
try:
    with open(jf, encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    sys.exit(0)

state = {}
if os.path.exists(sf):
    try:
        with open(sf, encoding="utf-8") as f:
            state = json.load(f)
    except Exception:
        pass

now = time.time()
msgs = []
changed = False
for s in data:
    name = s.get("name") or ""
    lat = s.get("last_downloaded_at") or ""
    ep = s.get("last_downloaded_episode")
    base = s.get("path") or ""
    if not (name and lat and ep and base):
        continue
    try:
        ts = time.mktime(time.strptime(lat, "%Y-%m-%dT%H:%M:%SZ"))
    except Exception:
        continue
    if ts <= state.get(name, 0):
        continue
    found = False
    if os.path.isdir(base):
        epnum = str(ep).lstrip("0")
        for fn in sorted(os.listdir(base)):
            if not fn.lower().endswith((".mp4", ".mkv")):
                continue
            tags = [t.strip().lower().replace(" ", "") for t in fn.split("_")]
            nums = [t.lstrip("0") for t in tags
                    if t.isdigit() or (t.startswith("ep") and t[2:].isdigit())]
            if epnum not in nums:
                continue
            p = os.path.join(base, fn)
            try:
                stable = now - os.path.getmtime(p) > 900
                nonempty = os.path.getsize(p) > 0
            except OSError:
                stable, nonempty = False, False
            if stable and nonempty:
                found = True
            title = ""
            nfo = os.path.splitext(p)[0] + ".nfo"
            if os.path.isfile(nfo):
                try:
                    root = ET.parse(nfo).getroot()
                    for el in root.iter("title"):
                        if el.text and el.text.strip():
                            title = el.text.strip()
                            break
                except Exception:
                    pass
            break
    if found:
        if title:
            msgs.append(f"{name}: Ep {ep} - {title}")
        else:
            msgs.append(f"{name}: Ep {ep}")
        state[name] = ts
        changed = True

if changed:
    with open(sf, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)
if msgs:
    print(json.dumps({"message": "Scaricato e convertito: " + ", ".join(msgs)}))
PY
)

if [ -n "$OUT" ]; then
    mosquitto_pub -h "$MQTT_HOST" -u "$MQTT_USER" -P "$MQTT_PASS" \
        -t fedora/anidownloader/status -m "$OUT"
fi
