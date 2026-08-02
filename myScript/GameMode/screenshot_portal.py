#!/usr/bin/env python3
"""Screenshot via XDG Desktop Portal (GNOME Wayland). Stampa il percorso immagine."""
import sys
import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

OUT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/ambilight_shot.png"

loop = GLib.MainLoop()
result = {"uri": None}

bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)

def on_response(*args):
    params = args[5]
    if isinstance(params, GLib.Variant):
        params = params.unpack()
    code = params[0]
    if code == 0:
        uri = params[1].get("uri", "")
        if uri.startswith("file://"):
            result["uri"] = uri[len("file://"):]
    loop.quit()

def on_ready(conn, res):
    try:
        req = conn.call_finish(res).unpack()
        request_path = req[0]
        bus.signal_subscribe(
            "org.freedesktop.portal.Desktop", "org.freedesktop.portal.Request",
            "Response", request_path, None, Gio.DBusSignalFlags.NONE, on_response,
        )
    except GLib.Error as e:
        print(f"ERRORE: {e}", file=sys.stderr)
        loop.quit()

bus.call(
    "org.freedesktop.portal.Desktop",
    "/org/freedesktop/portal/desktop",
    "org.freedesktop.portal.Screenshot",
    "Screenshot",
    GLib.Variant("(sa{sv})", ("ambilight", {"interactive": GLib.Variant("b", False)})),
    None, Gio.DBusCallFlags.NONE, 10000, None, on_ready,
)

GLib.timeout_add_seconds(15, loop.quit)
loop.run()

uri = result["uri"]
if uri:
    import shutil
    shutil.copy2(uri, OUT)
    print(OUT)
else:
    print("ERRORE: nessuno screenshot", file=sys.stderr)
    sys.exit(1)
