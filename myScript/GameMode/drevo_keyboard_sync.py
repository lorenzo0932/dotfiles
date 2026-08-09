#!/usr/bin/env python3
"""Sync tastiera Drevo Tyrfing V2 con l'ambilight (daemon).

Si sottoscrive ai topic MQTT pubblicati da screenshot_portal.py e applica il
colore alla tastiera via dtv2 (un pacchetto HID da 32 byte per il colore
statico: ~ms, abbastanza veloce per il rate di publish dell'ambilight).

- fedora/light/led/color: "h,s,b" -> HSV->RGB -> dtv2.static() (bri 1:1 strip)
- fedora/light/start:     inizio sessione -> colore default (come la strip)
- fedora/light/end:       ambilight spento -> colore default (sempre acceso)
- Reassert periodico:     qualunque combo Fn premuta sulla tastiera viene
                          sovrascritta entro REASSERT_SEC (il colore resta
                          applicato anche senza nuovi publish).

Il default e' lo stesso della strip LED (automazione HA "Ambilight fine
sessione" in automations.yaml: hs_color 29.081, 88.976) ma, a differenza della
strip che di giorno si spegne, la tastiera resta SEMPRE accesa: cambia solo la
luminosita' in base alla soglia giorno/notte comune a tutte le luci (notte =
da tramonto - SUNSET_OFFSET_MIN a alba, lo stesso offset della condizione sun
dell'automazione HA).
"""
import colorsys
import math
import os
import signal
import subprocess
import sys
import threading
import time
from datetime import datetime, timedelta, timezone

from dtv2 import dtv2

MQTT_HOST = "192.168.1.39"
TOPIC_COLOR = "fedora/light/led/color"
TOPIC_START = "fedora/light/start"
TOPIC_END = "fedora/light/end"

REASSERT_SEC = 2.0      # riapplica l'ultimo colore (override combo Fn)
RECONNECT_DELAY = 3.0   # attesa tra le riconnessioni del sub MQTT

# Colore di default = default della strip (automazione HA "Ambilight fine
# sessione": hs_color 29.081, 88.976). La tastiera resta sempre accesa.
DEFAULT_HS = (29.081, 88.976)   # hue, sat % (da automations.yaml di HA)
BRI_DAY = 100                   # pct diurno (come la strip)
BRI_NIGHT = 25                  # pct notturno

# Floor luminosita' in modalita' dinamica (mqtt): la Drevo ha solo 6 step
# hardware (dtv2: round(bri/100*6)) e con scene scure il daemon pubblica
# ~30% = step 2, quasi invisibile. Floor a 59% -> sempre >= step 4 di 6
# (misurato 2026-08-09 con scene di riferimento). Vale SOLO quando il
# servizio ambilight e' attivo; il default giorno/notte resta invariato.
KBD_BRI_MIN = 59

# Soglia giorno/notte: la notte inizia SUNSET_OFFSET_MIN minuti prima del
# tramonto (stesso offset usato da HA nella condizione sun). Coordinate
# uguali a quelle di Home Assistant (core.config).
LAT = 43.7225701
LON = 10.4128592
SUNSET_OFFSET_MIN = 30

CONF = os.path.expanduser("~/.config/mqtt.env")

state = {"last": None, "has": False}
stop = threading.Event()


def log(msg):
    print(time.strftime("%H:%M:%S") + " " + str(msg), flush=True)


def conf_load():
    if os.path.isfile(CONF):
        with open(CONF) as f:
            for row in f:
                row = row.strip()
                if "=" in row and not row.startswith("#"):
                    k, _, v = row.partition("=")
                    os.environ.setdefault(k.strip(), v.strip().strip('"'))
    return os.environ.get("MQTT_USER", "lorenzo"), os.environ.get("MQTT_PASS", "")


def kbd_apply(rgb, bri_pct, reason, silent=False):
    try:
        kbd = dtv2()
        kbd.static(rgb, brightness=bri_pct)
        state["last"] = (rgb, bri_pct)
        state["has"] = True
        if not silent:
            log(f"tastiera: rgb={rgb} bri={bri_pct}% [{reason}]")
    except Exception as e:
        log(f"tastiera non raggiungibile: {e}")


def parse_color(payload):
    try:
        h, s, b = payload.strip().split(",")
        return float(h), float(s), float(b)
    except (ValueError, AttributeError):
        return None


def apply_color(h_deg, s_pct, b_pct, reason):
    b_pct = max(b_pct, KBD_BRI_MIN)
    r, g, b = colorsys.hsv_to_rgb(h_deg / 360.0, s_pct / 100.0, b_pct / 100.0)
    kbd_apply((int(round(r * 255)), int(round(g * 255)),
               int(round(b * 255))), b_pct, reason)


def sun_times_utc(day):
    """Alba/tramonto in minuti UTC dopo la mezzanotte della data (NOAA)."""
    lat_rad = math.radians(LAT)
    doy = day.timetuple().tm_yday
    n = doy + (0.5 - LON / 360.0)
    gamma = math.radians((360.0 / 365.0) * (n - 1))
    eqtime = 229.18 * (0.000075 + 0.001868 * math.cos(gamma)
                       - 0.032077 * math.sin(gamma)
                       - 0.014615 * math.cos(2 * gamma)
                       - 0.040849 * math.sin(2 * gamma))
    decl = (0.006918 - 0.399912 * math.cos(gamma) + 0.070257 * math.sin(gamma)
            - 0.006758 * math.cos(2 * gamma) + 0.000907 * math.sin(2 * gamma)
            - 0.002697 * math.cos(3 * gamma) + 0.00148 * math.sin(3 * gamma))
    cos_ha = (math.cos(math.radians(90.833))
              / (math.cos(lat_rad) * math.cos(decl))
              - math.tan(lat_rad) * math.tan(decl))
    cos_ha = max(-1.0, min(1.0, cos_ha))
    ha = math.degrees(math.acos(cos_ha))
    return 720 - 4 * (LON + ha) - eqtime, 720 - 4 * (LON - ha) - eqtime


def sun_times(day):
    """Alba/tramonto in ora locale (naive) per la data data."""
    sunrise_min, sunset_min = sun_times_utc(day)
    base = datetime(day.year, day.month, day.day, tzinfo=timezone.utc)
    tz = datetime.now().astimezone().tzinfo
    sunrise = (base + timedelta(minutes=sunrise_min)).astimezone(tz).replace(tzinfo=None)
    sunset = (base + timedelta(minutes=sunset_min)).astimezone(tz).replace(tzinfo=None)
    return sunrise, sunset


def is_night(now=None):
    """True se e' notte (da tramonto - SUNSET_OFFSET_MIN a alba)."""
    now = now or datetime.now()
    today = now.date()
    sunrise, sunset = sun_times(today)
    if now < sunrise:  # prima dell'alba: dipende dal tramonto di ieri
        _, prev_sunset = sun_times(today - timedelta(days=1))
        return now >= prev_sunset - timedelta(minutes=SUNSET_OFFSET_MIN)
    return now >= sunset - timedelta(minutes=SUNSET_OFFSET_MIN)


def apply_default(reason, silent=False):
    bri = BRI_NIGHT if is_night() else BRI_DAY
    h, s = DEFAULT_HS
    r, g, b = colorsys.hsv_to_rgb(h / 360.0, s / 100.0, bri / 100.0)
    kbd_apply((int(round(r * 255)), int(round(g * 255)),
               int(round(b * 255))), bri, reason, silent=silent)


def reassert():
    while not stop.wait(REASSERT_SEC):
        if state["has"]:
            rgb, bri = state["last"]
            kbd_apply(rgb, bri, "reassert", silent=True)
        else:
            apply_default("default", silent=True)


def sub_loop():
    while not stop.is_set():
        user, pw = conf_load()
        if not pw:
            log("MQTT_PASS mancante, riprovo")
            stop.wait(RECONNECT_DELAY)
            continue
        cmd = ["mosquitto_sub", "-h", MQTT_HOST, "-u", user, "-P", pw,
               "-t", TOPIC_COLOR, "-t", TOPIC_START, "-t", TOPIC_END, "-v"]
        try:
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True,
                                    bufsize=1)
        except OSError as e:
            log(f"mosquitto_sub non avviabile: {e}")
            stop.wait(RECONNECT_DELAY)
            continue
        for line in proc.stdout:
            line = line.strip()
            if not line:
                continue
            parts = line.split(" ", 1)
            if len(parts) != 2:
                continue
            topic_r, payload = parts
            if topic_r == TOPIC_COLOR:
                hsv = parse_color(payload)
                if hsv is None:
                    log(f"payload non valido: {payload}")
                    continue
                apply_color(*hsv, "mqtt")
            elif topic_r == TOPIC_START:
                apply_default("inizio sessione")
            elif topic_r == TOPIC_END:
                apply_default("ambilight spento")
        proc.wait()
        if not stop.is_set():
            log("connessione MQTT persa, riconnessione")
            stop.wait(RECONNECT_DELAY)


def shutdown(*_):
    log("terminazione")
    stop.set()


def main():
    PID_FILE = "/tmp/drevo_keyboard_sync.pid"
    if os.path.isfile(PID_FILE):
        try:
            old = int(open(PID_FILE).read().strip())
            if old != os.getpid() and os.path.exists(f"/proc/{old}"):
                log(f"un altro daemon e' gia' attivo (pid {old}): esco")
                sys.exit(0)
        except (ValueError, OSError):
            pass
    try:
        with open(PID_FILE, "w") as f:
            f.write(str(os.getpid()))
    except OSError:
        pass
    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)
    apply_default("avvio")
    threading.Thread(target=reassert, daemon=True).start()
    threading.Thread(target=sub_loop, daemon=True).start()
    while not stop.wait(1):
        pass


if __name__ == "__main__":
    main()
