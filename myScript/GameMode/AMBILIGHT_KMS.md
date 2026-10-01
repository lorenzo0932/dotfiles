# Ambilight KMS backend (no portal prompt)

`screenshot_portal.py daemon --backend=kms` captures the screen straight from
the kernel scanout buffer via DRM/KMS (same trick Sunshine uses), instead of
the XDG ScreenCast portal. Result: **no "Share screen" dialog ever**, even
with 2 monitors and fullscreen moving across them (the portal
`restore_token` is single-use and bound to one monitor, so it re-prompts).

## Files

- `kms_capture.py` — DRM output enumeration (`modetest`), GNOME↔DRM name
  mapping (`HDMI-1`→`HDMI-A-1`), target picking, persistent `ffmpeg-kmsgrab`
  reader (320x180@5fps via VAAPI `hwmap`/`scale_vaapi`/`hwdownload`).
- `screenshot_portal.py` — `--backend=portal|kms` (default portal),
  `--connector NAME`, `--crtc ID`, `--no-follow`. Analysis/MQTT
  (`dominant_hsv`, `publish_color`) is shared and untouched by the backend.
- `systemd/user/ambilight-kms.service` — user unit (triggered by the
  fullscreen-command extension instead of `ambilight.service`).

## Requirements

- `~/.local/bin/ffmpeg-kms` (copy of system ffmpeg) with
  `sudo setcap cap_sys_admin+ep ~/.local/bin/ffmpeg-kms`.
  Without it capture fails with "No handle set on framebuffer".
  Re-apply only if the copy is replaced (package updates don't touch it).
- GNOME fullscreen-command extension writes `/tmp/ambilight_monitor`
  (GNOME monitor index of the fullscreen window); the daemon maps it to a
  DRM connector via Mutter DisplayConfig and follows it (2s poll).
  NOTE: on Wayland extension code loads at login — a logout/login is needed
  after updating `extension.js`.
- Single active output needs no hint (auto-picked).

## Tuning (measured, 2026-10-01, branch test/latency)

| Constant | Value | Basis |
|---|---|---|
| `INTERVAL` 0.2s / capture 5fps | analyze 5Hz | localtuya channel: 20/20 ok at 200ms, losses at 100ms |
| `COOLDOWN` 0.2s | min publish spacing | == measured channel floor (was 0.3) |
| `PERSIST_TICKS` 1 | big-jump confirm | was 2; saves ~400ms on scene cuts, no flap on tested content |
| `PUB_HUE_DEG` 30, lock/dominance | unchanged | still the anti-flap guards |

Latency test (cycle video, ms-accurate MQTT tap): hard cuts publish in
~0.5-0.9s (was ~1s); stress test (0.3s flips) tracked at 200-400ms spacing
with zero spurious publishes. Architecture (sparse targets + device fade)
matches Hue Sync / HyperHDR practice; absolute rates stay conservative
because the Tuya channel can't take Hue-style 25-60Hz streams.

WATCH: bimodal anime content (warm subject on cold background) was the
reason persist was 2 — if hue flip-flops there, revert `PERSIST_TICKS` to 2.

## Operation

- Trigger: fullscreen-command `start/stop-command` →
  `systemctl --user start/stop ambilight-kms.service`.
- Topics: `fedora/light/led/color`, `.../start`, `.../end`
  (+ `fedora/light/cam/color` with `--immersive`).
- Check: `journalctl --user -u ambilight-kms.service`,
  `cat /tmp/ambilight_monitor`, `modetest -M amdgpu -c`.
- Display layouts stay managed by `myScript/Display/ReturnToTV.sh` /
  `ReturnToDesktop.sh` (single-output) or compositor extend; KMS re-picks
  the CRTC at startup and follows afterwards (CRTC ids change per modeset).
