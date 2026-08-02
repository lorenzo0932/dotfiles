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

import gi
gi.require_version("Gio", "2.0")
gi.require_version("Gst", "1.0")
from gi.repository import Gio, GLib, Gst

INTERVAL = 5
MQTT_HOST = "192.168.1.39"
STATE_DIR = os.path.expanduser("~/.local/state/ambilight")
STATE_FILE = os.path.join(STATE_DIR, "screencast.json")
SHOT = "/tmp/ambilight_shot.png"
LOG = os.path.join(STATE_DIR, "ambilight.log")

Gst.init(None)
bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
loop = GLib.MainLoop()

s = {"session": None, "node": None, "fd": None, "restore_token": None,
     "grab_in_progress": False, "cur_color": None}


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


def _clamp(v):
    return max(0, min(255, v))


def publish_color():
    # Media dei pixel piu' luminosi (top 40%) invece della media totale:
    # zone nere (letterbox/sfondi) non soffocano il colore della scena.
    try:
        out = subprocess.run(
            ["magick", SHOT, "-resize", "40x25!", "-alpha", "off", "-depth", "8",
             "rgb:-"],
            capture_output=True, timeout=10)
        raw = out.stdout
        px = [(max(raw[i], raw[i + 1], raw[i + 2]), raw[i], raw[i + 1], raw[i + 2])
              for i in range(0, len(raw) - 2, 3)]
        if len(px) < 10:
            return
        px.sort(reverse=True)
        cut = max(8, int(len(px) * 0.4))
        top = px[:cut]
        r = sum(p[1] for p in top) // cut
        g = sum(p[2] for p in top) // cut
        b = sum(p[3] for p in top) // cut
        # boost saturazione: allarga lo scarto dalla media grigia
        gray = (r + g + b) // 3
        r = _clamp(gray + int((r - gray) * 1.3))
        g = _clamp(gray + int((g - gray) * 1.3))
        b = _clamp(gray + int((b - gray) * 1.3))
        # luminosita' minima per una LED visibile (senza alterare la tinta)
        lum = max(r, g, b)
        if lum < 90:
            lift = 90 - lum
            r, g, b = _clamp(r + lift), _clamp(g + lift), _clamp(b + lift)
        # smoothing: scorre verso il nuovo colore invece di saltarci
        cur = s["cur_color"]
        if cur:
            r = int(r * 0.5 + cur[0] * 0.5)
            g = int(g * 0.5 + cur[1] * 0.5)
            b = int(b * 0.5 + cur[2] * 0.5)
        s["cur_color"] = (r, g, b)
        color = f"{r},{g},{b}"
        mqtt_pub("fedora/light/color", color)
        log(f"colore pubblicato: {color}")
    except Exception as e:
        log(f"colore err: {e}")


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
