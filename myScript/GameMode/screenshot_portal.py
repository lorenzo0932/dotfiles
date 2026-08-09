#!/usr/bin/env python3
"""Ambilight daemon: sessione ScreenCast XDG portal (v7) + GStreamer appsink.
Pipeline PERSISTENTE: pipewiresrc -> videoconvert -> videoscale -> appsink
gira in continuo (niente pngenc/filesink/magick per frame). Un thread
campiona l'ultimo frame; un timer GLib ogni INTERVAL calcola il colore
dominante (numpy vettorizzato) e pubblica "h,s,b" via MQTT.
Alla terminazione pubblica fedora/light/end e chiude la sessione.
Uso: screenshot_portal.py daemon [--immersive]
(con --immersive pubblica lo stesso colore, attenuato, anche sulla luce
camera: fedora/light/cam/color — il soffitto fa da luce ambiente)
"""
import collections
import json
import os
import secrets
import signal
import subprocess
import sys
import threading
import time

import numpy as np

import gi
gi.require_version("Gio", "2.0")
gi.require_version("Gst", "1.0")
gi.require_version("GstApp", "1.0")
from gi.repository import Gio, GLib, Gst, GstApp

INTERVAL = 0.2        # secondi tra un'analisi colore e l'altra
# Transizioni "cinematiche" a pochi step: il daemon pubblica il target solo
# quando la scena si e' allontanata abbastanza dall'ultimo colore inviato e
# solo ogni COOLDOWN secondi; sono i device a fare le transizioni fluide
# (fade nativo della luce camera, fade hardware della strip LED regolato da
# dp26=150, ~700°/s misurato: 180° in 200-300ms). Cooldown > durata fade di
# un passo (30° a ~700°/s = ~40ms): ogni cambio e' un passaggio lungo e
# continuo che arriva a destinazione, senza interruzioni a meta'. Rate e
# cooldown al limite del canale localtuya: 20/20 publish senza perdite fino
# a 200ms, perdite a 100ms; INTERVAL 0.2s = 5Hz e' il massimo sicuro.
PUB_HUE_DEG = 30.0    # soglia minima di spostamento hue per pubblicare
PUB_SAT_DELTA = 0.2   # soglia minima di variazione saturazione
COOLDOWN = 0.3        # intervallo minimo (s) tra due publish
LOCK_DEG = 25.0       # color lock: i tick di conferma richiesti devono stare
                      # dentro questa banda. Il numero di tick richiesti e'
                      # adattivo: 1 per salti >120°, 2 per >60°, 4 per il resto
                      # (a INTERVAL 0.2: 200/400/800ms di reazione)
DOMINANCE = 1.5       # soglia di dominanza: se un cluster hue lontano (>4 bin,
                      # ~80°) ha energia >= vincente/DOMINANCE la scena e'
                      # bimodale ambigua (es. personaggio caldo + sfondo
                      # freddo, tipico anime): il bin vincente e' bistabile e
                      # flippa tra frame. Il colore resta l'ultimo applicato,
                      # ma la bri continua a seguire la scena. 1.0 = disattiva.
PERSIST_DEG = 90.0    # salti hue > PERSIST_DEG richiedono conferma di
                      # persistenza direzionale prima del publish
PERSIST_TICKS = 2     # tick consecutivi (INTERVAL 0.2 = 400ms) con il colore
                      # lontano dall'ultimo pubblicato per accettare il salto:
                      # i battiti A-B-A (alternanza tra poli di energia quasi
                      # uguale) non accumulano mai 2 tick, i cambi scena reali
                      # (energia 2.5-3.7x) passano in ~400ms
# --- LUMINOSITA' DINAMICA ---
# La bri segue la luce TOTALE del monitor (media del canale Value su tutto il
# frame, NON mascherata): stanza che scende nelle scene scure. Curva gamma per
# non far "gridare" le scene medie. La bri cambia con deadband PUB_BRI_DELTA e
# holdoff BRIGHT_HOLD; un cambio colore valido fa "cavalcare" la bri nello
# stesso publish (gratis per il controller).
BRIGHT_MIN = 25        # luminosita' pct minima (scena scurissima, stanza mai spenta)
BRIGHT_MAX = 95        # luminosita' pct massima (scena chiarissima)
BRIGHT_GAMMA = 1.5     # gamma: il buio percepito scende piu' veloce del valore
PUB_BRI_DELTA = 12.0  # variazione minima di bri (%) per il cambio di SOLA bri
BRIGHT_HOLD = 3.0     # attesa minima (s) tra due cambi di sola luminosita'
# Edge masking: il peso dell'analisi e' spostato dal centro verso i bordi del
# frame (effetto ambilight: le luci estendono la periferia dello schermo). Il
# centro mantiene EDGE_FLOOR di peso, la periferia ha il peso pieno quando c'e'
# colore uniforme, ma eventi iper-saturi al centro non svaniscono del tutto.
EDGE_WEIGHT = True    # True attiva la vignette spaziale sui bin hue
EDGE_FLOOR = 0.30     # peso al centro (0.30) vs bordi (1.0)
EDGE_POWER = 2.0      # curva quadratica: centro piu' isolato (1.0 = lineare)
# --- MODALITA' IMMERSIVA (--immersive) ---
# La strip LED e' la bias light (colore dominante pieno); la luce camera
# (soffitto) fa da luce ambiente: stesso hue ma intensita' fortemente
# attenuata (stato dell'arte: le accent lights non devono staccare dal
# contenuto ma nemmeno illuminare la stanza a pieno regime). La camera
# segue 1:1 con lo stesso rate: conferma DP a ~17ms e fade fluido fino a
# 200ms (piu' veloce della strip), quindi nessuna decimazione necessaria.
CAM_SAT_SCALE = 0.7   # saturazione del soffitto = sat della scena * 0.7
CAM_BRI_SCALE = 0.25  # luminosita' del soffitto = bri della scena * 0.25
# Stabilita' del colore: la tinta e' la media gaussiana pesata dei bin hue
# attorno al bin con piu' energia (sigma ~40°), quindi aree piccole ma sature
# (es. mani in movimento) non fanno cambiare colore alle luci.
MQTT_HOST = "192.168.1.39"
STATE_DIR = os.path.expanduser("~/.local/state/ambilight")
STATE_FILE = os.path.join(STATE_DIR, "screencast.json")
LOG = os.path.join(STATE_DIR, "ambilight.log")

Gst.init(None)
bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
loop = GLib.MainLoop()

s = {"session": None, "node": None, "fd": None, "restore_token": None,
     "cur_hsv": None, "last_pub": None, "last_pub_time": 0.0,
     "hhist": collections.deque(maxlen=4),
     "dir_hold": 0,
     "pipeline": None, "last_frame": None, "frame_seq": 0, "running": True,
     "edge_mask": None, "edge_mask_shape": (0, 0),
     "last_bri_time": 0.0}
lock = threading.Lock()


def log(msg, verbose=False):
    if verbose and not s.get("verbose"):
        return
    line = time.strftime("%H:%M:%S") + " " + str(msg)
    print(line, flush=True)
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(LOG, "a") as f:
            f.write(line + "\n")
    except OSError:
        pass


def conf_load():
    env = os.path.expanduser("~/.config/mqtt.env")
    if os.path.isfile(env):
        with open(env) as f:
            for row in f:
                row = row.strip()
                if "=" in row and not row.startswith("#"):
                    k, _, v = row.partition("=")
                    os.environ.setdefault(k.strip(), v.strip().strip('"'))
    return os.environ.get("MQTT_USER", "lorenzo"), os.environ.get("MQTT_PASS", "")


def mqtt_pub(topic, msg):
    user, pw = conf_load()
    if not pw:
        log("MQTT_PASS mancante, salto publish")
        return
    subprocess.run(["mosquitto_pub", "-h", MQTT_HOST, "-u", user, "-P", pw,
                    "-t", topic, "-m", msg], capture_output=True, timeout=5)


def vdict(d):
    return GLib.Variant("a{sv}", {k: v for k, v in d.items()})


def call(path, iface, method, payload, cb):
    bus.call("org.freedesktop.portal.Desktop", path, iface, method,
             payload, None, Gio.DBusCallFlags.NONE, 15000, None, cb)


def req_path(token):
    sender = bus.get_unique_name().replace(".", "_")
    return f"/org/freedesktop/portal/desktop/request/{sender[1:]}/{token}"


def pre_subscribe(token, cb):
    path = req_path(token)
    bus.signal_subscribe(None, "org.freedesktop.portal.Request", "Response",
                         path, None, Gio.DBusSignalFlags.NONE, cb)
    return path


def session_path(token):
    sender = bus.get_unique_name().replace(".", "_")
    return f"/org/freedesktop/portal/desktop/session/{sender[1:]}/{token}"


# ---------- fase ScreenCast ----------

def setup_session():
    tok = "sh_" + secrets.token_hex(8)
    s["session"] = session_path(tok)
    payload = vdict({"session_handle_token": GLib.Variant("s", tok)})
    call("/org/freedesktop/portal/desktop", "org.freedesktop.portal.ScreenCast",
         "CreateSession", GLib.Variant.new_tuple(payload), on_session_created)


def on_session_created(conn, res):
    try:
        conn.call_finish(res)
    except GLib.Error as e:
        log(f"CreateSession err: {e}")
        loop.quit()
        return
    log(f"sessione: {s['session']}")
    try:
        state = json.load(open(STATE_FILE))
        s["restore_token"] = state.get("restore_token")
    except Exception:
        pass
    select_sources()


def on_response_log(label):
    def cb(sub, sender, obj, iface, sig, params):
        code = params[0]
        results = params[1].unpack() if isinstance(params[1], GLib.Variant) else params[1]
        log(f"{label} response code={code} results={results}")
        handle_code(label, code, results)
    return cb


def select_sources():
    tok = "pw_" + secrets.token_hex(8)
    pre_subscribe(tok, on_response_log("SelectSources"))
    opts = {"handle_token": GLib.Variant("s", tok),
            "types": GLib.Variant("u", 1),
            "persist_mode": GLib.Variant("u", 2)}
    if s["restore_token"]:
        opts["restore_token"] = GLib.Variant("s", s["restore_token"])
    payload = GLib.Variant.new_tuple(GLib.Variant("o", s["session"]), vdict(opts))
    call("/org/freedesktop/portal/desktop", "org.freedesktop.portal.ScreenCast",
         "SelectSources", payload, on_select_call)


def on_select_call(conn, res):
    try:
        conn.call_finish(res)
    except GLib.Error as e:
        log(f"SelectSources err: {e}")
        loop.quit()


def handle_code(label, code, results):
    if label == "SelectSources":
        if code != 0:
            log("SelectSources rifiutata, esco")
            loop.quit()
        else:
            start_stream()
    elif label == "Start":
        if code != 0:
            log("Start fallita, esco")
            loop.quit()
            return
        try:
            st = results["streams"][0]
            s["node"] = st[0]
            log(f"stream: node={s['node']} props={st[1]}")
        except Exception as e:
            log(f"parse streams err: {e}")
            loop.quit()
            return
        if results.get("restore_token"):
            s["restore_token"] = results["restore_token"]
            try:
                json.dump({"restore_token": s["restore_token"]}, open(STATE_FILE, "w"))
            except OSError as e:
                log(f"salvataggio token err: {e}")
        log(f"stream pronto: node={s['node']}")
        open_pipewire()


def start_stream():
    tok = "st_" + secrets.token_hex(8)
    pre_subscribe(tok, on_response_log("Start"))
    opts = {"handle_token": GLib.Variant("s", tok)}
    payload = GLib.Variant.new_tuple(GLib.Variant("o", s["session"]),
                                     GLib.Variant("s", ""), vdict(opts))
    call("/org/freedesktop/portal/desktop", "org.freedesktop.portal.ScreenCast",
         "Start", payload, on_start_call)


def on_start_call(conn, res):
    try:
        conn.call_finish(res)
    except GLib.Error as e:
        log(f"Start err: {e}")
        loop.quit()


def open_pipewire():
    def on_fd(conn, res):
        try:
            _, fd_list = conn.call_with_unix_fd_list_finish(res)
        except GLib.Error as e:
            log(f"OpenPipeWireRemote err: {e}")
            loop.quit()
            return
        try:
            fds = fd_list.steal_fds()
            s["fd"] = fds[0]
            log(f"fd PipeWire: {s['fd']}")
        except Exception as e:
            log(f"parse fd err: {e}")
            loop.quit()
            return
        loop_ready()

    payload = GLib.Variant.new_tuple(GLib.Variant("o", s["session"]), vdict({}))
    bus.call_with_unix_fd_list(
        "org.freedesktop.portal.Desktop",
        "/org/freedesktop/portal/desktop",
        "org.freedesktop.portal.ScreenCast", "OpenPipeWireRemote",
        payload, None, Gio.DBusCallFlags.NONE, 15000,
        Gio.UnixFDList(), None, on_fd)


# ---------- fase pipeline persistente ----------

def loop_ready():
    log("loop avviato")
    mqtt_pub("fedora/light/start", "1")
    desc = (f"pipewiresrc fd={s['fd']} path={s['node']} "
            f"! videoconvert ! videoscale ! video/x-raw,width=240,format=RGB "
            f"! appsink name=sink emit-signals=True max-buffers=1 drop=True")
    pipeline = Gst.parse_launch(desc)
    s["pipeline"] = pipeline
    bus_msg = pipeline.get_bus()
    bus_msg.add_signal_watch()

    def on_bus_msg(bus_obj, msg):
        if msg.type == Gst.MessageType.ERROR:
            err, dbg = msg.parse_error()
            log(f"gstreamer err: {err.message} ({dbg})")
        elif msg.type == Gst.MessageType.EOS:
            log("gstreamer EOS")

    bus_msg.connect("message", on_bus_msg)
    sink = pipeline.get_by_name("sink")
    sink.connect("new-sample", on_new_sample)
    pipeline.set_state(Gst.State.PLAYING)
    GLib.timeout_add(int(INTERVAL * 1000), analyze)
    analyze()


def on_new_sample(sink):
    sample = sink.pull_sample()
    if sample is None:
        return Gst.FlowReturn.OK
    buf = sample.get_buffer()
    caps = sample.get_caps()
    if caps is None:
        return Gst.FlowReturn.OK
    info = caps.get_structure(0)
    ok_w, w = info.get_int("width")
    ok_h, h = info.get_int("height")
    if not (ok_w and ok_h):
        return Gst.FlowReturn.OK
    success, mapinfo = buf.map(Gst.MapFlags.READ)
    if not success:
        return Gst.FlowReturn.OK
    try:
        n = w * h * 3
        arr = np.frombuffer(mapinfo.data, dtype=np.uint8)
        if arr.size >= n:
            frame = arr[:n].reshape(h, w, 3).copy()
            with lock:
                s["frame_seq"] += 1
                s["last_frame"] = frame
    finally:
        buf.unmap(mapinfo)
    return Gst.FlowReturn.OK


def analyze():
    with lock:
        frame = s["last_frame"]
    if frame is None:
        log("nessun frame ancora", verbose=True)
        return True
    t0 = time.perf_counter()
    publish_color(frame)
    dt = (time.perf_counter() - t0) * 1000
    log(f"analisi: {dt:.0f}ms", verbose=True)
    return True


def dominant_hsv(rgb):
    """Colore dominante: hue calcolato come media gaussiana pesata dei bin
    attorno al bin con piu' energia (sigma = 2 bin, ~40°).

I bin lontani dal vincente contribuiscono quasi zero: le aree piccole ma
    sature (mani, oggetti in movimento) non spostano il colore delle luci e
    non ci sono fluttuazioni tra colori quasi opposti. Sat/lum dalla media
    dei pixel del bin vincente (colore vivo). Ritorna (h, s, v) in [0,1),
    None se la scena e' quasi senza colore.

    Il gate "scena senza colore" usa l'energia NON mascherata (stessa soglia
    del comportamento originale); la maschera EDGE_WEIGHT pesa solo la scelta
    del bin vincente, spostando il colore verso i bordi dello schermo."""
    f = rgb.astype(np.float64) / 255.0
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    d = mx - mn
    hue = np.zeros_like(r)
    sat = np.zeros_like(r)
    m = d > 0
    if m.any():
        denom = np.where(mx[m] == 0, 1.0, mx[m])
        sat[m] = d[m] / denom
        hr = np.zeros_like(r)
        hr[m] = ((g[m] - b[m]) / d[m]) % 6
        hg = np.zeros_like(r)
        hg[m] = ((b[m] - r[m]) / d[m] + 2)
        hb = np.zeros_like(r)
        hb[m] = ((r[m] - g[m]) / d[m] + 4)
        # dove mx==r -> hr; mx==g -> hg; altrimenti hb
        hue[m] = np.where(mx[m] == r[m], hr[m],
                          np.where(mx[m] == g[m], hg[m], hb[m])) / 6.0
    val = mx
    energy = sat * val
    scene_v = float(val.mean())
    if energy.sum() < 0.012 * r.size:
        # scena quasi senza colore: nessun publish, si mantiene l'ultimo
        # colore gia' applicato alle luci
        return None
    if EDGE_WEIGHT:
        h_frame, w_frame = r.shape
        if s["edge_mask_shape"] != (h_frame, w_frame):
            yy, xx = np.indices((h_frame, w_frame))
            dy = np.abs(yy - h_frame / 2.0) / (h_frame / 2.0)
            dx = np.abs(xx - w_frame / 2.0) / (w_frame / 2.0)
            dist = np.maximum(dx, dy)
            s["edge_mask"] = EDGE_FLOOR + (1.0 - EDGE_FLOOR) * (dist ** EDGE_POWER)
            s["edge_mask_shape"] = (h_frame, w_frame)
        energy = energy * s["edge_mask"]
    nbins = 18
    bi = (hue * nbins).astype(np.int64).ravel() % nbins
    bsum = np.bincount(bi, weights=energy.ravel(), minlength=nbins)
    best = int(np.argmax(bsum))
    # Soglia di dominanza: se il cluster hue lontano (>4 bin, ~80°) con piu'
    # energia rivaleggia col vincente, la scena e' bimodale ambigua (due poli
    # di energia paragonabile, es. soggetto caldo su sfondo freddo). In questo
    # caso il bin vincente e' bistabile e flipperebbe tra i due poli a ogni
    # frame: il colore resta l'ultimo applicato alle luci (il publish del
    # colore e' soppresso), ma la bri continua a seguire la scena (sentinella
    # (None, scene_v)). Il gate usa l'energia mascherata.
    if DOMINANCE > 1.0:
        ang = np.abs((np.arange(nbins) - best + nbins // 2) % nbins - nbins // 2)
        rival = bsum[ang >= 4]
        if rival.size and rival.max() > bsum[best] / DOMINANCE:
            return None, scene_v
    # peso gaussiano circolare attorno al bin vincente
    dist = np.abs((np.arange(nbins) - best + nbins // 2) % nbins - nbins // 2)
    w = np.exp(-(dist ** 2) / (2 * 2.0 ** 2))
    theta = (np.arange(nbins) + 0.5) / nbins * 2.0 * np.pi
    sin_s = float(np.sum(bsum * w * np.sin(theta)))
    cos_s = float(np.sum(bsum * w * np.cos(theta)))
    th = (np.arctan2(sin_s, cos_s) % (2.0 * np.pi)) / (2.0 * np.pi)
    # sat/lum dalla media dei pixel del bin vincente
    mbin = (hue * nbins).astype(np.int64).ravel() % nbins == best
    mbin = mbin.reshape(r.shape)
    r_m = float(r[mbin].mean())
    g_m = float(g[mbin].mean())
    b_m = float(b[mbin].mean())
    _, ts, _ = colorsys_hsv(r_m, g_m, b_m)
    return th, ts, scene_v, f"h{int(th * 360)}"


def colorsys_hsv(r, g, b):
    import colorsys
    return colorsys.rgb_to_hsv(max(0.0, min(1.0, r)),
                               max(0.0, min(1.0, g)),
                               max(0.0, min(1.0, b)))


def send_pub(th, ts, b_pct, hue_label):
    h_deg = round(th * 360, 1)
    s_pct = round(ts * 100, 1)
    payload = f"{h_deg},{s_pct},{b_pct}"
    mqtt_pub("fedora/light/led/color", payload)
    log(f"pubblicato: {payload} [{hue_label}]")
    if s.get("immersive"):
        cam_s = round(ts * CAM_SAT_SCALE * 100, 1)
        cam_b = round(b_pct * CAM_BRI_SCALE, 1)
        cam_payload = f"{h_deg},{cam_s},{cam_b}"
        mqtt_pub("fedora/light/cam/color", cam_payload)
        log(f"camera (immersive): {cam_payload}")


def publish_color(frame):
    res = dominant_hsv(frame)
    if res is None:
        log("scena senza colore: nessun publish (ultimo colore mantenuto)", verbose=True)
        return
    now = time.time()
    lp = s["last_pub"]
    if res[0] is None:
        # Scena bimodale ambigua: il colore e' bistabile, si tiene l'ultimo
        # applicato, ma la bri continua a seguire la scena (deadband +
        # holdoff come per i cambi di sola luminosita').
        _, scene_v = res
        gamma_v = scene_v ** BRIGHT_GAMMA
        b_pct = int(BRIGHT_MIN + (BRIGHT_MAX - BRIGHT_MIN) * gamma_v)
        b_pct = max(BRIGHT_MIN, min(BRIGHT_MAX, b_pct))
        s["dir_hold"] = 0
        if lp is None:
            return
        db = abs(b_pct - lp[2])
        if db >= PUB_BRI_DELTA and now - s["last_bri_time"] >= BRIGHT_HOLD \
                and now - s["last_pub_time"] >= COOLDOWN:
            s["last_pub"] = (lp[0], lp[1], b_pct)
            s["last_pub_time"] = now
            s["last_bri_time"] = now
            send_pub(lp[0], lp[1], b_pct, f"bri su scena ambigua ({db:.0f}%)")
        else:
            log(f"scena ambigua: colore fermo, bri invariata ({b_pct}%)", verbose=True)
        return
    th, ts, scene_v, hue_label = res
    ts = max(ts, 0.45)
    # Luminosita' dinamica: la bri segue la luce TOTALE del monitor (media di
    # val sull'intero frame) con curva gamma; floor BRIGHT_MIN per non spegnere
    # la stanza, tetto BRIGHT_MAX. Deadband PUB_BRI_DELTA + holdoff BRIGHT_HOLD
    # per non far "respirare" la luce su variazioni rapide della scena.
    gamma_v = scene_v ** BRIGHT_GAMMA
    b_pct = int(BRIGHT_MIN + (BRIGHT_MAX - BRIGHT_MIN) * gamma_v)
    b_pct = max(BRIGHT_MIN, min(BRIGHT_MAX, b_pct))
    s["hhist"].append(th)
    if lp is not None:
        dh = abs((th * 360 - lp[0] * 360 + 180) % 360 - 180)
        # Persistenza direzionale: un salto grande (dh > PERSIST_DEG) deve
        # restare lontano dall'ultimo colore pubblicato per PERSIST_TICKS tick
        # consecutivi (a INTERVAL 0.2: 400ms) prima di essere accettato. Le
        # scene bimodali fanno battere il colore tra due poli quasi opposti
        # (A-B-A): il contatore si resetta a ogni ritorno entro PERSIST_DEG,
        # quindi i battiti non superano mai la soglia. Un vero cambio scena e'
        # unidirezionale e arriva alla conferma in ~400ms (2.5-3.7x di energia
        # a favore, la soglia DOMINANCE non lo blocca).
        if dh > PERSIST_DEG:
            s["dir_hold"] += 1
            if s["dir_hold"] < PERSIST_TICKS:
                log(f"salto {dh:.0f}°: conferma {s['dir_hold']}/{PERSIST_TICKS}", verbose=True)
                return
        else:
            s["dir_hold"] = 0
    else:
        dh = 0.0
    # Cooldown: tra un publish e il successivo passa almeno COOLDOWN secondi,
    # cosi' il fade hardware arriva a destinazione prima del prossimo cambio.
    if now - s["last_pub_time"] < COOLDOWN:
        log(f"cooldown: prossimo publish tra {COOLDOWN - (now - s['last_pub_time']):.1f}s", verbose=True)
        return
    # Color lock adattivo: la stabilita' richiesta dipende da quanto il colore
    # attuale e' lontano dall'ultimo pubblicato. Cambi spettacolari (>120°)
    # richiedono solo 1 tick di conferma (200ms), cambi medi 2 tick, cambi
    # piccoli 4 tick: i flash brevi restano bloccati, i salti di scena grandi
    # arrivano subito. Un flash breve non fa cambiare le luci.
    if lp is not None:
        need = 1 if dh >= 120.0 else (2 if dh >= 60.0 else 4)
    else:
        need = 4
    hh = list(s["hhist"])[-need:]
    if len(hh) >= 2:
        spread = 0.0
        for i in range(len(hh)):
            for j in range(i + 1, len(hh)):
                d = abs((hh[i] - hh[j] + 0.5) % 1.0 - 0.5)
                if d > spread:
                    spread = d
        if spread > LOCK_DEG / 360.0:
            log(f"colore instabile (spread {spread * 360:.0f}°, need {need}): nessun publish", verbose=True)
            return
    # Gate di pubblicazione: cambio colore (deadband hue/sat) oppure cambio di
    # SOLA luminosita' (deadband PUB_BRI_DELTA + holdoff BRIGHT_HOLD). Un cambio
    # colore valido fa 'cavalcare' la bri nello stesso publish senza attese.
    if lp is not None:
        ds = abs(ts - lp[1])
        db = abs(b_pct - lp[2])
        color_changed = (dh >= PUB_HUE_DEG) or (ds >= PUB_SAT_DELTA)
        bri_changed = (db >= PUB_BRI_DELTA) and \
            (now - s["last_bri_time"] >= BRIGHT_HOLD)
        if not (color_changed or bri_changed):
            log(f"invariato ({hue_label} bri:{b_pct}%): nessun publish", verbose=True)
            return
    s["last_pub"] = (th, ts, b_pct)
    s["last_pub_time"] = now
    s["last_bri_time"] = now
    s["dir_hold"] = 0
    send_pub(th, ts, b_pct, hue_label)


# ---------- fine ----------

def shutdown(*_):
    log("terminazione: fine sessione ambilight")
    s["running"] = False
    mqtt_pub("fedora/light/end", "1")
    if s["pipeline"] is not None:
        s["pipeline"].set_state(Gst.State.NULL)
    if s["session"]:
        try:
            bus.call("org.freedesktop.portal.Desktop", s["session"],
                     "org.freedesktop.portal.Session", "Close",
                     GLib.Variant.new_tuple(), None,
                     Gio.DBusCallFlags.NONE, 3000, None, None)
        except GLib.Error:
            pass
    loop.quit()


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] != "daemon":
        print("uso: screenshot_portal.py daemon [--immersive] [--verbose]", file=sys.stderr)
        sys.exit(1)
    s["immersive"] = "--immersive" in sys.argv[2:]
    s["verbose"] = "--verbose" in sys.argv[2:]
    PID_FILE = "/tmp/ambilight_daemon.pid"
    if os.path.isfile(PID_FILE):
        try:
            old = int(open(PID_FILE).read().strip())
            if old != os.getpid() and os.path.exists(f"/proc/{old}"):
                log(f"un altro daemon ambilight e' gia' attivo (pid {old}): esco")
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
    setup_session()
    loop.run()
