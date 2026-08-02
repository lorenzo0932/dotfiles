#!/usr/bin/env python3
"""Ambilight daemon: sessione ScreenCast XDG portal (v6) + GStreamer.
Cattura un frame ogni INTERVAL secondi, calcola il colore dominante e lo
pubblica via MQTT (fedora/light/color). Niente flash/suono/grab input.
Alla terminazione pubblica fedora/light/end e chiude la sessione.
Uso: screenshot_portal.py daemon   (start/end restano in ambilight.sh)
"""
import json
import os
import secrets
import signal
import subprocess
import sys
import time
import colorsys

import gi
gi.require_version("Gio", "2.0")
gi.require_version("Gst", "1.0")
from gi.repository import Gio, GLib, Gst

INTERVAL = 2
ALPHA = 0.35
# Smoothing adattivo per intervalli di delta hue (circolare):
# drift -> fast -> bypass, come i filtri SOTA sui cut.
HUE_SMOOTH_MAX = 50     # <= 50° : drift lento
HUE_FAST_MAX = 120      # 50-120°: fast chase (1-2 grab)
HUE_SNAP_DEG = 120      # > 120° : bypass (target immediato)
HUE_HYSTERESIS = 12     # niente oscillazioni entro 12°
MQTT_HOST = "192.168.1.39"
STATE_DIR = os.path.expanduser("~/.local/state/ambilight")
STATE_FILE = os.path.join(STATE_DIR, "screencast.json")
SHOT = "/tmp/ambilight_shot.png"
LOG = os.path.join(STATE_DIR, "ambilight.log")

Gst.init(None)
bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
loop = GLib.MainLoop()

s = {"session": None, "node": None, "fd": None, "restore_token": None,
     "grab_in_progress": False, "cur_hsv": None}


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


# ---------- fase grab ----------

def loop_ready():
    log("loop avviato")
    GLib.timeout_add_seconds(INTERVAL, grab)
    grab()


def grab():
    if s["grab_in_progress"]:
        return True
    s["grab_in_progress"] = True
    run_pipeline()
    return True


def run_pipeline():
    node, fd = s["node"], s["fd"]
    desc = (f"pipewiresrc fd={fd} path={node} num-buffers=1 "
            f"! videoconvert ! videoscale ! video/x-raw,width=240 "
            f"! pngenc ! filesink location={SHOT}")
    pipeline = Gst.parse_launch(desc)
    done = {"ok": False}
    grab_loop = GLib.MainLoop()
    timer_id = {"id": None}

    def guard():
        log("grab: timeout 4s")
        grab_loop.quit()

    def on_bus_msg(bus_obj, msg):
        t = msg.type
        if t == Gst.MessageType.EOS:
            done["ok"] = os.path.isfile(SHOT) and os.path.getsize(SHOT) > 0
            grab_loop.quit()
        elif t == Gst.MessageType.ERROR:
            err, dbg = msg.parse_error()
            log(f"gstreamer err: {err.message} ({dbg})")
            grab_loop.quit()

    bus_msg = pipeline.get_bus()
    bus_msg.add_signal_watch()
    bus_msg.connect("message", on_bus_msg)
    pipeline.set_state(Gst.State.PLAYING)
    timer_id["id"] = GLib.timeout_add_seconds(4, guard)
    grab_loop.run()
    if timer_id["id"] is not None:
        GLib.source_remove(timer_id["id"])
    pipeline.set_state(Gst.State.NULL)
    bus_msg.remove_signal_watch()
    s["grab_in_progress"] = False
    if done["ok"]:
        publish_color()
        log("grab ok")
    else:
        log("grab fallito")


def publish_color():
    # Colore "energia" dominante: la tinta con piu' energia cumulativa nel
    # frame (saturazione x luminosita' x copertura). Uscita SEMPRE satura
    # (s>=0.45): la striscia Tuya e' HS-mode e rende male i grigi/pastello,
    # quindi si pubblica la tinta piena invece della media che sbiadisce.
    try:
        out = subprocess.run(
            ["magick", SHOT, "-resize", "12x6!", "-alpha", "off", "-depth", "8",
             "rgb:-"],
            capture_output=True, timeout=10)
        raw = out.stdout
        px = []
        for i in range(0, len(raw) - 2, 3):
            rr, gg, bb = raw[i], raw[i + 1], raw[i + 2]
            h, sa, v = colorsys.rgb_to_hsv(rr / 255, gg / 255, bb / 255)
            px.append((rr, gg, bb, h, sa, v))
        if len(px) < 6:
            return
        n = len(px)
        total_e = sum(sa * v for _, _, _, _, sa, v in px)
        hue_label = "fallback"
        if total_e < 0.012 * n:
            # scena quasi senza colore: niente grigio "strano", ambra soffusa
            th, ts, tv = colorsys.rgb_to_hsv(200 / 255, 150 / 255, 60 / 255)
        else:
            nbins = 18
            bsum = [0.0] * nbins
            bpx = [[] for _ in range(nbins)]
            for k, (rr, gg, bb, h, sa, v) in enumerate(px):
                bi = int(h * nbins) % nbins
                bsum[bi] += sa * v
                bpx[bi].append(k)
            best = max(range(nbins), key=lambda k: bsum[k])
            grp = bpx[best]
            cnt = len(grp)
            r = sum(px[k][0] for k in grp) // cnt
            g = sum(px[k][1] for k in grp) // cnt
            b = sum(px[k][2] for k in grp) // cnt
            th, ts, tv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            hue_label = f"h{int(th * 360)}"
        ts = max(ts, 0.45)
        tv = max(tv, 0.5)
        # smoothing adattivo in HSV (hue circolare). Il fattore alpha dipende
        # dalla distanza circolare: drift per cambi piccoli, bypass per i
        # cambi di scena (niente attraversamento di colori intermedi).
        a = ALPHA
        cur = s["cur_hsv"]
        if cur:
            dv = (th - cur[0] + 0.5) % 1.0 - 0.5
            d_h = abs(dv) * 360
            if d_h < HUE_HYSTERESIS:
                dv = 0.0
            if d_h <= HUE_SMOOTH_MAX:
                a = ALPHA
            elif d_h <= HUE_FAST_MAX:
                a = 0.9
            else:
                a = 1.0
            th = (cur[0] + dv * a) % 1.0
            ts = cur[1] * (1 - ALPHA) + ts * ALPHA
            tv = cur[2] * (1 - ALPHA) + tv * ALPHA
        s["cur_hsv"] = (th, ts, tv)
        r, g, b = (round(c * 255) for c in colorsys.hsv_to_rgb(th, ts, tv))
        color = f"{r},{g},{b}"
        mqtt_pub("fedora/light/color", color)
        log(f"colore pubblicato: {color} [{hue_label} s={ts:.2f} a={a:.2f}]")
    except Exception as e:
        import traceback
        log(f"colore err: {e}\n{traceback.format_exc()}")


# ---------- fine ----------

def shutdown(*_):
    log("terminazione: fine sessione ambilight")
    mqtt_pub("fedora/light/end", "1")
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
