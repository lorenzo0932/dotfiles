#!/usr/bin/env python3
"""Sync tastiera Drevo Tyrfing V2 con l'ambilight (daemon, event-driven).

Modello identico ai LED strip: scrive SOLO su eventi, mai a riposo.

- fedora/light/led/color: colore schermo durante la sessione -> applica
- fedora/light/start:     inizio sessione -> colore default
- fedora/light/end:       ambilight spento -> colore default (una volta),
                          poi silenzio totale finché il prossimo evento

Il vecchio reassert ogni REASSERT_SEC (riscrittura continua per coprire le
combo Fn) è stato RIMOSSO: le scritture periodiche open/close HID mandano
in reset-loop il controller Winbond della tastiera (2026-08: flap USB ogni
~2s per ore, risolto fermando il daemon).

Al suo posto:
- Restore periodico SOFT (IDLE_CHECK_SEC = 10 min): fuori sessione calcola
  il target giorno/notte e scrive SOLO se divergente dall'ultimo applicato
  (recupera combo Fn premute e transizione notte/giorno). Se tutto è
  allineato: NESSUNA scrittura.
- Watchdog retry: se una scrittura fallisce il colore desiderato resta
  "pending" e viene ritentato al ritorno del device, con backoff (5s dopo
  i primi fallimenti, 60s oltre soglia). Successo = pending azzerato.
- Gate presenza: prima di ogni scrittura il device viene enumerato via
  hid; assente = nessun spawn del helper (niente scritture in cieco
  durante una re-enumeration).
- STARTUP_DELAY all'avvio: a boot/wake l'USB può ancora risettare.

Il default e' lo stesso della strip LED (automazione HA "Ambilight fine
sessione" in automations.yaml: hs_color 29.081, 88.976) ma, a differenza
della strip che di giorno si spegne, la tastiera resta SEMPRE accesa:
cambia solo la luminosita' in base alla soglia giorno/notte comune a tutte
le luci (notte = da tramonto - SUNSET_OFFSET_MIN a alba, lo stesso offset
della condizione sun dell'automazione HA).
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

try:
    import hid
except ImportError:  # il venv dtv2 ce l'ha; senza modulo non blocchiamo nulla
    hid = None

MQTT_HOST = "192.168.1.39"
TOPIC_COLOR = "fedora/light/led/color"
TOPIC_START = "fedora/light/start"
TOPIC_END = "fedora/light/end"

VENDOR_ID = 0x0416      # Drevo Tyrfing V2 (Winbond), iface 1 / usage 0
PRODUCT_ID = 0xA0F8     # stesso criterio di device_accessible() in dtv2

STARTUP_DELAY = 10.0    # prima scrittura ritardata (settle USB a boot/wake)
IDLE_CHECK_SEC = 600.0  # restore periodico soft: verifica default ogni 10
                        # min ma scrive SOLO se divergente (zero scritture a
                        # regime stazionario)
SESSION_QUIET_SEC = 20.0  # margine dopo l'ultimo messaggio MQTT: dentro
                          # questa finestra il check pigro non tocca nulla
FAIL_FAST_COOLDOWN = 5.0   # backoff nei primi fallimenti consecutivi
FAIL_MAX_COOLDOWN = 60.0   # backoff oltre soglia fallimenti
FAIL_THRESHOLD = 3         # fallimenti prima di passare al cooldown lungo
ERR_LOG_INTERVAL = 60.0    # rate-limit errore nel journal
KBD_APPLY_TIMEOUT = 5.0    # il colore lo applica un subprocess: se il
                           # device e' incastrato (transfer libusb che
                           # blocca per sempre) il figlio viene ucciso e il
                           # daemon non si blocca

HELPER = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                      "kbd_apply_one.py")

# Colore di default = default della strip (automazione HA "Ambilight fine
# sessione": hs_color 29.081, 88.976). La tastiera resta sempre accesa.
DEFAULT_HS = (29.081, 88.976)   # hue, sat % (da automations.yaml di HA)
BRI_DAY = 100                   # pct diurno (come la strip)
BRI_NIGHT = 83                  # pct notturno: la tastiera resta sempre sugli
                                # step 5-6, mai sotto

# Floor luminosita' in modalita' dinamica (mqtt): la Drevo ha solo 6 step
# hardware (dtv2: round(bri/100*6)) e con scene scure il daemon pubblica
# ~30% = step 2, quasi invisibile. Floor a 83% -> sempre >= step 5 di 6
# (round(83/100*6)=5; step 5 e 6, mai sotto). Vale SOLO quando il
# servizio ambilight e' attivo; il default giorno/notte resta invariato.
KBD_BRI_MIN = 83

# Soglia giorno/notte: la notte inizia SUNSET_OFFSET_MIN minuti prima del
# tramonto (stesso offset usato da HA nella condizione sun). Coordinate
# uguali a quelle di Home Assistant (core.config).
LAT = 43.7225701
LON = 10.4128592
SUNSET_OFFSET_MIN = 30

CONF = os.path.expanduser("~/.config/mqtt.env")

# --verbose: logga anche le applicazioni di colore ("tastiera: ..."); di
# default il journal resta pulito (le transizioni le logga il daemon).
VERBOSE = "--verbose" in sys.argv[1:]

state = {"last": None, "has": False, "last_err_log": 0.0, "err_active": False,
         "in_session": False, "last_mqtt": 0.0, "fails": 0,
         "cool_until": 0.0, "pending": None}
stop = threading.Event()


def log(msg, verbose=False):
    if verbose and not VERBOSE:
        return
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


def device_present():
    """True se l'interfaccia HID di controllo è enumerata e apribile."""
    if hid is None:
        return True
    try:
        for itf in hid.enumerate(VENDOR_ID, PRODUCT_ID):
            if itf.get("interface_number") == 1 and itf.get("usage") == 0:
                return True
    except Exception:
        return True  # enumerazione fallita: meglio tentare che bloccare
    return False


def kbd_apply(rgb, bri_pct, reason, silent=False):
    now = time.time()
    desired = ((int(rgb[0]), int(rgb[1]), int(rgb[2])), int(bri_pct))
    state["pending"] = desired
    if now < state["cool_until"]:
        return
    if not device_present():
        state["err_active"] = True
        if now - state["last_err_log"] >= ERR_LOG_INTERVAL:
            state["last_err_log"] = now
            log("tastiera assente (re-enumeration?), salto la scrittura")
        state["cool_until"] = now + FAIL_FAST_COOLDOWN
        return
    try:
        proc = subprocess.run(
            [sys.executable, HELPER,
             str(desired[0][0]), str(desired[0][1]), str(desired[0][2]),
             str(desired[1])],
            timeout=KBD_APPLY_TIMEOUT,
            stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
        err = proc.stderr.strip() if proc.returncode != 0 else None
    except subprocess.TimeoutExpired:
        err = "timeout: il device non risponde"
    if err is None:
        state["last"] = desired
        state["has"] = True
        state["fails"] = 0
        state["cool_until"] = 0.0
        state["pending"] = None
        if state["err_active"]:
            state["err_active"] = False
            log("tastiera ripristinata")
        if not silent:
            log(f"tastiera: rgb={desired[0]} bri={desired[1]}% [{reason}]",
                verbose=True)
    else:
        state["err_active"] = True
        state["fails"] += 1
        cool = FAIL_FAST_COOLDOWN if state["fails"] < FAIL_THRESHOLD \
            else FAIL_MAX_COOLDOWN
        state["cool_until"] = time.time() + cool
        if now - state["last_err_log"] >= ERR_LOG_INTERVAL:
            state["last_err_log"] = now
            log(f"tastiera non raggiungibile ({state['fails']} falliti, "
                f"riprovo tra {cool:.0f}s): {err}")


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
            - 0.014615 * math.cos(2 * gamma) + 0.000907 * math.sin(2 * gamma)
            - 0.002697 * math.cos(3 * gamma))
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


def default_target():
    """Colore/bri di default atteso (giorno/notte) come ((r,g,b), bri)."""
    bri = BRI_NIGHT if is_night() else BRI_DAY
    h, s = DEFAULT_HS
    r, g, b = colorsys.hsv_to_rgb(h / 360.0, s / 100.0, bri / 100.0)
    return (int(round(r * 255)), int(round(g * 255)), int(round(b * 255))), \
        int(bri)


def apply_default(reason, silent=False):
    rgb, bri = default_target()
    kbd_apply(rgb, bri, reason, silent=silent)


def watchdog():
    """Ritenta il colore pendente finché non va a buon fine (con backoff).

    In regime stazionario pending e' None: questo thread non fa NULLA.
    """
    while not stop.wait(2.0):
        p = state["pending"]
        if p is not None and time.time() >= state["cool_until"]:
            kbd_apply(p[0], p[1], "retry", silent=True)


def idle_restore():
    """Restore periodico soft fuori sessione: scrive solo se divergente."""
    while not stop.wait(IDLE_CHECK_SEC):
        if state["in_session"]:
            continue
        if time.time() - state["last_mqtt"] < SESSION_QUIET_SEC:
            continue
        target = default_target()
        if state["has"] and tuple(state["last"]) == target:
            continue  # già allineata: nessuna scrittura
        rgb, bri = target
        kbd_apply(rgb, bri, "restore periodico")


def sub_loop():
    while not stop.is_set():
        user, pw = conf_load()
        if not pw:
            log("MQTT_PASS mancante, riprovo")
            stop.wait(3.0)
            continue
        cmd = ["mosquitto_sub", "-h", MQTT_HOST, "-u", user, "-P", pw,
               "-t", TOPIC_COLOR, "-t", TOPIC_START, "-t", TOPIC_END, "-v"]
        try:
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True,
                                    bufsize=1)
        except OSError as e:
            log(f"mosquitto_sub non avviabile: {e}")
            stop.wait(3.0)
            continue
        for line in proc.stdout:
            line = line.strip()
            if not line:
                continue
            parts = line.split(" ", 1)
            if len(parts) != 2:
                continue
            state["last_mqtt"] = time.time()
            topic_r, payload = parts
            if topic_r == TOPIC_COLOR:
                hsv = parse_color(payload)
                if hsv is None:
                    log(f"payload non valido: {payload}")
                    continue
                state["in_session"] = True
                apply_color(*hsv, "mqtt")
            elif topic_r == TOPIC_START:
                state["in_session"] = True
                apply_default("inizio sessione")
            elif topic_r == TOPIC_END:
                state["in_session"] = False
                apply_default("ambilight spento")
        proc.wait()
        if not stop.is_set():
            log("connessione MQTT persa, riconnessione")
            stop.wait(3.0)


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
    log(f"avvio event-driven: prima scrittura tra {int(STARTUP_DELAY)}s "
        "(settle USB)")
    if stop.wait(STARTUP_DELAY):
        return
    apply_default("avvio")
    threading.Thread(target=watchdog, daemon=True).start()
    threading.Thread(target=idle_restore, daemon=True).start()
    threading.Thread(target=sub_loop, daemon=True).start()
    while not stop.wait(1):
        pass


if __name__ == "__main__":
    main()
