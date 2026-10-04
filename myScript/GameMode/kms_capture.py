#!/usr/bin/env python3
"""Backend KMS per l'ambilight: cattura senza prompt portal (stile Sunshine).

Legge lo scanout-buffer direttamente dal kernel via DRM/KMS usando
``ffmpeg -f kmsgrab`` (che richiede ``cap_sys_admin`` sul binario, come
Sunshine): nessun dialogo "Condividi schermo", nessuna dipendenza dal
compositor. Funziona con N monitor: ogni output ha il suo CRTC e il target
viene scelto esplicitamente (--connector/--crtc), dal file scritto
dall'estensione fullscreen-command (/tmp/ambilight_monitor) o, se un solo
output e' attivo, automaticamente.

Il portale XDG resta il fallback (backend "portal" in screenshot_portal.py):
il token restore e' single-use e legato al singolo monitor, quindi con 2
monitor e fullscreen che cambia schermo ripropone il dialogo ogni volta.
"""

import glob
import os
import re
import subprocess
import threading
import time

import numpy as np

# Fotogramma a dimensione fissa (stretch): niente barre nere -> niente bias
# sulla luminosita' di scena. Le statistiche colore non risentono dello stretch.
FRAME_W = 320
FRAME_H = 180
FRAME_BYTES = FRAME_W * FRAME_H * 3

MONITOR_FILE = "/tmp/ambilight_monitor"

KMS_DEVICE = os.environ.get("KMS_DEVICE", "/dev/dri/card1")
KMS_DRIVER = os.environ.get("KMS_DRIVER", "amdgpu")
RENDER_NODE = os.environ.get("KMS_RENDER", "/dev/dri/renderD128")
FFMPEG_CANDIDATES = [
    os.path.expanduser("~/.local/bin/ffmpeg-kms"),
    "/usr/bin/ffmpeg",
]


def _ffmpeg_bin(explicit=None):
    if explicit and os.path.isfile(explicit) and os.access(explicit, os.X_OK):
        return explicit
    for cand in FFMPEG_CANDIDATES:
        if os.path.isfile(cand) and os.access(cand, os.X_OK):
            return cand
    return None


def check_capable(ffmpeg=None):
    """Ritorna (ok, messaggio): il binario deve avere cap_sys_admin."""
    binpath = _ffmpeg_bin(ffmpeg)
    if not binpath:
        return False, "ffmpeg-kms non trovato (~/bin/ffmpeg-kms o /usr/bin/ffmpeg)"
    try:
        out = subprocess.run(["getcap", binpath], capture_output=True,
                             text=True, timeout=5).stdout
    except (OSError, subprocess.TimeoutExpired):
        return False, "getcap non eseguibile"
    if "cap_sys_admin" in out:
        return True, f"{binpath}: {out.strip()}"
    return False, (
        f"{binpath} senza cap_sys_admin: "
        f"esegui sudo setcap cap_sys_admin+ep {binpath}")


def _run_modetest(args, timeout=8):
    try:
        out = subprocess.run(["modetest", "-M", KMS_DRIVER] + args,
                             capture_output=True, text=True,
                             timeout=timeout).stdout
        return out
    except (OSError, subprocess.TimeoutExpired):
        return ""


def list_outputs():
    """Ritorna [{name, conn_id, enc_id, crtc_id, connected, active}]."""
    conns = _run_modetest(["-c"])
    encs = _run_modetest(["-e"])
    enc_crtc = {}
    for line in encs.splitlines():
        m = re.match(r"^(\d+)\s+(\d+)\s+\S+", line.strip())
        if m:
            enc_crtc[int(m.group(1))] = int(m.group(2))
    outputs = []
    for line in conns.splitlines():
        m = re.match(r"^(\d+)\s+(\d+)\s+(connected|disconnected)\s+(\S+)",
                     line.strip())
        if not m:
            continue
        conn_id, enc_id = int(m.group(1)), int(m.group(2))
        crtc = enc_crtc.get(enc_id, 0)
        outputs.append({
            "name": m.group(4),
            "conn_id": conn_id,
            "enc_id": enc_id,
            "crtc_id": crtc,
            "connected": m.group(3) == "connected",
            "active": m.group(3) == "connected" and crtc != 0,
        })
    return outputs


def active_outputs():
    return [o for o in list_outputs() if o["active"]]


def normalize_connector(name):
    """Mappa nomi GNOME -> nomi DRM (HDMI-1 -> HDMI-A-1, resto identita')."""
    name = (name or "").strip()
    m = re.match(r"^HDMI-(\d+)$", name, re.IGNORECASE)
    if m:
        return f"HDMI-A-{m.group(1)}"
    m = re.match(r"^(DP|DisplayPort)-?(\d+)$", name, re.IGNORECASE)
    if m:
        return f"DP-{m.group(2)}"
    return name


def read_monitor_file():
    """Monitor scritto dall'estensione (nome DRM, nome GNOME o indice)."""
    try:
        with open(MONITOR_FILE) as f:
            return f.read().strip()
    except OSError:
        return None


_gnome_map_cache = {"t": 0.0, "map": {}}


def gnome_monitor_connectors(ttl=30.0):
    """Indice monitor GNOME -> nome connettore via Mutter DisplayConfig.

    Risolve la correlazione KMS-su-Wayland senza euristiche sull'ordine:
    l'indice e' quello di Meta.Display (win.get_monitor()), il connettore
    e' quello del compositor (DP-1, HDMI-1, ...).
    """
    now = time.time()
    if now - _gnome_map_cache["t"] < ttl and _gnome_map_cache["map"]:
        return _gnome_map_cache["map"]
    try:
        out = subprocess.run(
            ["gdbus", "call", "--session",
             "--dest", "org.gnome.Mutter.DisplayConfig",
             "--object-path", "/org/gnome/Mutter/DisplayConfig",
             "--method", "org.gnome.Mutter.DisplayConfig.GetCurrentState"],
            capture_output=True, text=True, timeout=8).stdout
    except (OSError, subprocess.TimeoutExpired):
        return {}
    # Formato: (serial, [((conn, vendor, prod, ser), modes, props), ...],
    #           logical_monitors, props). L'indice del monitor e' la posizione
    # nell'array: estrae i nomi connettore in ordine con regex sui tuple
    # "(('DP-1', 'GSM', ..." che aprono ogni voce monitor.
    names = re.findall(r"\(\('([A-Za-z0-9-]+)', '", out)
    mapping = {i: n for i, n in enumerate(names)}
    if mapping:
        _gnome_map_cache["t"] = now
        _gnome_map_cache["map"] = mapping
    return mapping


def pick_target(connector=None, crtc=None, log=None):
    """Sceglie (output_dict). Solleva RuntimeError se niente e' attivo.

    --connector/--crtc espliciti sono vincoli rigidi (pin voluto).
    L'hint da /tmp/ambilight_monitor e' invece SOFT: se punta a un output
    spento (file stale dopo un cambio layout, es. desktop->TV) si ignora
    e si ripiega sull'auto-pick invece di far morire il daemon (bug
    2026-10-04: luci morte sulla TV con hint "0" residuo del desktop).
    """
    act = active_outputs()
    if not act:
        raise RuntimeError("nessun output DRM attivo (schermi spenti?)")
    if crtc:
        for o in act:
            if o["crtc_id"] == int(crtc):
                return o
        raise RuntimeError(f"CRTC {crtc} non attivo "
                           f"(attivi: {[o['crtc_id'] for o in act]})")
    if connector:
        want = normalize_connector(connector)
        for o in act:
            if o["name"] == want:
                return o
        raise RuntimeError(f"connettore {want} non attivo "
                           f"(attivi: {[o['name'] for o in act]})")
    hint = read_monitor_file()
    if hint:
        want = None
        if hint.isdigit():
            mapping = gnome_monitor_connectors()
            conn = mapping.get(int(hint))
            if conn:
                want = normalize_connector(conn)
            else:
                idx = int(hint)
                if 0 <= idx < len(act):
                    return act[idx]
        else:
            want = normalize_connector(hint)
        if want:
            for o in act:
                if o["name"] == want:
                    return o
            if log:
                log(f"kms: hint '{hint}' stale (attivi: "
                    f"{[o['name'] for o in act]}), uso auto-pick")
    if len(act) == 1:
        return act[0]
    # Piu' output attivi senza hint: fallback deterministico + log esplicito
    # (l'estensione puo' scrivere /tmp/ambilight_monitor per seguire il
    # fullscreen; in alternativa passare --connector).
    return sorted(act, key=lambda o: o["name"])[0]


class KMSReader:
    """Subprocess ffmpeg-kmsgrab persistente -> ultimo frame numpy RGB."""

    def __init__(self, crtc_id, device=None, render=None, ffmpeg=None,
                 fps=5, log=None):
        self.crtc_id = int(crtc_id)
        self.device = device or KMS_DEVICE
        self.render = render or RENDER_NODE
        self.ffmpeg = _ffmpeg_bin(ffmpeg)
        self.fps = int(fps)
        self.log = log or (lambda msg: print(msg, flush=True))
        self._stop = threading.Event()
        self._lock = threading.Lock()
        self._frame = None
        self._seq = 0
        self._proc = None
        self._thread = None

    def _cmd(self):
        vf = (f"hwmap=derive_device=vaapi,"
              f"scale_vaapi={FRAME_W}:{FRAME_H}:format=nv12,"
              f"hwdownload,format=bgr0")
        return [self.ffmpeg, "-hide_banner", "-loglevel", "warning",
                "-init_hw_device", f"vaapi=va:{self.render}",
                "-f", "kmsgrab", "-device", self.device,
                "-crtc_id", str(self.crtc_id),
                "-framerate", str(self.fps), "-i", "-",
                "-vf", vf,
                "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]

    def start(self):
        if not self.ffmpeg:
            raise RuntimeError("binario ffmpeg non trovato")
        self._stop.clear()
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def _spawn(self):
        return subprocess.Popen(self._cmd(), stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, bufsize=0)

    def _loop(self):
        backoff = 1.0
        while not self._stop.is_set():
            try:
                self._proc = self._spawn()
            except OSError as e:
                self.log(f"kms: avvio ffmpeg fallito: {e}")
                self._stop.wait(min(backoff, 5.0))
                backoff = min(backoff * 2, 5.0)
                continue
            self.log(f"kms: cattura CRTC {self.crtc_id} "
                     f"({FRAME_W}x{FRAME_H}@{self.fps}fps)")
            backoff = 1.0
            buf = bytearray()
            while not self._stop.is_set():
                try:
                    chunk = self._proc.stdout.read(FRAME_BYTES - len(buf))
                except (OSError, ValueError):
                    break
                if not chunk:
                    break
                buf += chunk
                if len(buf) == FRAME_BYTES:
                    arr = np.frombuffer(bytes(buf), dtype=np.uint8)
                    with self._lock:
                        self._frame = arr.reshape(FRAME_H, FRAME_W, 3).copy()
                        self._seq += 1
                    buf = bytearray()
            try:
                self._proc.terminate()
                self._proc.wait(timeout=3)
            except (OSError, subprocess.TimeoutExpired):
                try:
                    self._proc.kill()
                except OSError:
                    pass
            self._proc = None
            if not self._stop.is_set():
                self.log("kms: ffmpeg terminato, riavvio tra 2s")
                self._stop.wait(2.0)

    def get_frame(self):
        with self._lock:
            return None if self._frame is None else self._frame.copy()

    @property
    def seq(self):
        with self._lock:
            return self._seq

    def stop(self):
        self._stop.set()
        proc = self._proc
        if proc is not None:
            try:
                proc.terminate()
            except OSError:
                pass
