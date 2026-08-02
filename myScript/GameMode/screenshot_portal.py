#!/usr/bin/env python3
"""Ambilight daemon: sessione ScreenCast XDG portal (v7) + GStreamer appsink.
Pipeline PERSISTENTE: pipewiresrc -> videoconvert -> videoscale -> appsink
gira in continuo (niente pngenc/filesink/magick per frame). Un thread
campiona l'ultimo frame; un timer GLib ogni INTERVAL calcola il colore
dominante (numpy vettorizzato) e pubblica "h,s,b" via MQTT.
Alla terminazione pubblica fedora/light/end e chiude la sessione.
Uso: screenshot_portal.py daemon
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

INTERVAL = 0.7        # secondi tra un'analisi colore e l'altra
# Transizioni "cinematiche" a pochi step: il daemon pubblica il target solo
# quando la scena si e' allontanata abbastanza dall'ultimo colore inviato e
# solo ogni COOLDOWN secondi; sono i device a fare le transizioni fluide
# (fade nativo della luce camera, fade hardware della strip LED regolato da
# dp26=150, ~35 gradi/s). Cooldown >= durata fade: ogni cambio e' un passaggio
# lungo e continuo che arriva a destinazione, senza interruzioni a meta'.
PUB_HUE_DEG = 30.0    # soglia minima di spostamento hue per pubblicare
PUB_SAT_DELTA = 0.2   # soglia minima di variazione saturazione
COOLDOWN = 6.0        # intervallo minimo (s) tra due publish
LOCK_DEG = 25.0       # color lock: i target hue degli ultimi ~4 tick devono
                      # stare dentro questa banda, altrimenti la scena e'
                      # instabile (flash brevi) e non si pubblica nulla
BRIGHT_FIXED = 80     # luminosita' pct fissa: il colore segue la scena, la bri no
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
     "pipeline": None, "last_frame": None, "frame_seq": 0, "running": True}
lock = threading.Lock()


def log(msg):
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


def gamemode_active():
    """True se esiste almeno una sessione GameMode attiva (gamemoderun)."""
    try:
        out = subprocess.run(
            ["gdbus", "call", "--session",
             "--dest", "com.feralinteractive.GameMode",
             "--object-path", "/com/feralinteractive/GameMode",
             "--method", "com.feralinteractive.GameMode.QueryStatus", "0"],
            capture_output=True, text=True, timeout=5)
        return "(" in out.stdout and not out.stdout.startswith("(0")
    except Exception:
        return False


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
    if not gamemode_active():
        log("nessuna sessione gamemoderun attiva: esco senza toccare le luci")
        sys.exit(0)
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
        log("nessun frame ancora")
        return True
    t0 = time.perf_counter()
    publish_color(frame)
    dt = (time.perf_counter() - t0) * 1000
    log(f"analisi: {dt:.0f}ms")
    return True


def dominant_hsv(rgb):
    """Colore dominante: hue calcolato come media gaussiana pesata dei bin
    attorno al bin con piu' energia (sigma = 2 bin, ~40°).

    I bin lontani dal vincente contribuiscono quasi zero: le aree piccole ma
    sature (mani, oggetti in movimento) non spostano il colore delle luci e
    non ci sono fluttuazioni tra colori quasi opposti. Sat/lum dalla media
    dei pixel del bin vincente (colore vivo). Ritorna (h, s, v) in [0,1),
    None se la scena e' quasi senza colore."""
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
    if energy.sum() < 0.012 * r.size:
        # scena quasi senza colore: nessun publish, si mantiene l'ultimo
        # colore gia' applicato alle luci
        return None
    nbins = 18
    bi = (hue * nbins).astype(np.int64).ravel() % nbins
    bsum = np.bincount(bi, weights=energy.ravel(), minlength=nbins)
    best = int(np.argmax(bsum))
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
    _, ts, tv = colorsys_hsv(r_m, g_m, b_m)
    return th, ts, tv, f"h{int(th * 360)}"


def colorsys_hsv(r, g, b):
    import colorsys
    return colorsys.rgb_to_hsv(max(0.0, min(1.0, r)),
                               max(0.0, min(1.0, g)),
                               max(0.0, min(1.0, b)))


def publish_color(frame):
    res = dominant_hsv(frame)
    if res is None:
        log("scena senza colore: nessun publish (ultimo colore mantenuto)")
        return
    th, ts, tv, hue_label = res
    ts = max(ts, 0.45)
    s["hhist"].append(th)
    # Cooldown: tra un publish e il successivo passa almeno COOLDOWN secondi,
    # cosi' il fade hardware arriva a destinazione prima del prossimo cambio.
    now = time.time()
    if now - s["last_pub_time"] < COOLDOWN:
        log(f"cooldown: prossimo publish tra {COOLDOWN - (now - s['last_pub_time']):.1f}s")
        return
    # Color lock: il colore viene applicato solo se la scena e' stabile
    # (gli ultimi ~4 tick entro LOCK_DEG l'uno dall'altro). Un flash breve
    # non fa cambiare le luci: il nuovo colore deve persistere ~3s.
    hh = list(s["hhist"])
    if len(hh) >= 2:
        spread = 0.0
        for i in range(len(hh)):
            for j in range(i + 1, len(hh)):
                d = abs((hh[i] - hh[j] + 0.5) % 1.0 - 0.5)
                if d > spread:
                    spread = d
        if spread > LOCK_DEG / 360.0:
            log(f"colore instabile (spread {spread * 360:.0f}°): nessun publish")
            return
    # Publish solo quando la scena si e' allontanata oltre la soglia.
    lp = s["last_pub"]
    if lp is not None:
        dh = abs((th * 360 - lp[0] * 360 + 180) % 360 - 180)
        if dh < PUB_HUE_DEG and abs(ts - lp[1]) < PUB_SAT_DELTA:
            log(f"colore invariato ({hue_label}): nessun publish")
            return
    s["last_pub"] = (th, ts, tv)
    s["last_pub_time"] = now
    h_deg = round(th * 360, 1)
    s_pct = round(ts * 100, 1)
    b_pct = BRIGHT_FIXED
    payload = f"{h_deg},{s_pct},{b_pct}"
    mqtt_pub("fedora/light/led/color", payload)
    mqtt_pub("fedora/light/cam/color", payload)
    log(f"pubblicato: {payload} [{hue_label}]")


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
        print("uso: screenshot_portal.py daemon", file=sys.stderr)
        sys.exit(1)
    try:
        with open("/tmp/ambilight_daemon.pid", "w") as f:
            f.write(str(os.getpid()))
    except OSError:
        pass
    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)
    setup_session()
    loop.run()
