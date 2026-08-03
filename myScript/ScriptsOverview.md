# myScript/ - Personal Scripts Overview

This directory contains a diverse and comprehensive set of personal scripts and automation tools for Linux system management, display configuration, media playback, local AI/ML service orchestration, and backups.

## Subdirectories and Core Components

### 1. [BackupJellyfin](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/BackupJellyfin/)
Manages Jellyfin media server configurations backups.
*   [backupJellyfin.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/BackupJellyfin/backupJellyfin.sh): Automates the copying and compression of Jellyfin settings.

### 2. [Lockscreen](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Lockscreen/)
Automates the system lock screen operations.
*   [AvviaLockscreen.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Lockscreen/AvviaLockscreen.sh): Script that launches lock screen behavior.

### 3. [ExportKeyboardShortcut](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/ExportKeyboardShortcut/)
Utilities to dump and reload custom desktop keybindings.
*   [Export|Load_Keybindings.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/ExportKeyboardShortcut/Export%7CLoad_Keybindings.sh): Uses `dconf` and `gsettings` to export or import custom GNOME keys, WM bindings, and media hotkeys.
*   See [Keybindings_README.md](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/ExportKeyboardShortcut/Keybindings_README.md) for usage instructions.

### 4. [GameMode](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/GameMode/)
Custom game-related scripts.
*   [openSteamAtConnection.py](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/GameMode/openSteamAtConnection.py): Python utility to trigger Steam startup upon detecting a connection.
*   [screenshot_portal.py](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/GameMode/screenshot_portal.py): Ambilight daemon (XDG ScreenCast portal + GStreamer). Trigger: estensione GNOME **fullscreen-command** (quando una finestra va fullscreen esegue `systemctl --user start ambilight.service` — o `ambilight-immersive.service`); si avvia anche manualmente. Pubblica il colore dominante su MQTT (`fedora/light/led/color`); HA applica hue/sat/bri alla strip LED. Con `daemon --immersive` pubblica lo stesso colore attenuato (sat ×0.7, bri ×0.25) anche su `fedora/light/cam/color`: la luce camera (soffitto) fa da luce ambiente insieme alla strip.

#### Ambilight: design rationale (v8.0)
Obiettivo: transizioni "cinematiche" — pochi cambi di colore, ognuno un fade lungo e fluido. Le luci hanno il fade hardware (strip LED: dp localtuya 26=150, ~35°/s; luce camera: fade nativo), quindi il daemon **non** deve mandare step intermedi (persi comunque, limite 500ms di polling localtuya).

Catena di filtri nel daemon (in ordine, costanti in cima a `screenshot_portal.py`):
1. **Estrazione**: istogramma HSV a 18 bin pesato per energia (sat×val); il colore è la **media gaussiana dei bin attorno al bin vincente** (σ=2 bin ≈ 40°): aree piccole ma sature (mani, oggetti in movimento) non spostano il colore. Scena quasi senza colore (<1.2% di energia) → nessun publish.
2. **Edge masking** (`EDGE_WEIGHT`, `EDGE_FLOOR=0.30`, `EDGE_POWER=2.0`): peso spostato dal centro ai bordi (effetto ambilight: le luci estendono la periferia dello schermo). Il gate "nessun colore" usa l'energia non mascherata.
3. **Color lock** (`LOCK_DEG=25`, finestra 4 tick ≈ 2.8s): si pubblica solo se gli ultimi 4 hue rilevati stanno entro ±25° — i flash brevi (<2s, esplosioni, lampi) non vengono mai pubblicati (replica il "lock" di Philips Hue Sync).
4. **Cooldown** (`COOLDOWN=1.0s`): al massimo 1 publish al secondo, così il fade hardware arriva SEMPRE a destinazione prima del prossimo cambio (mai fade interrotti → niente scatti).
5. **Deadband + bri dinamica**: publish solo se il target dista ≥30° di hue o ≥0.2 di saturazione dall'ultimo colore inviato. La bri segue la luminosità TOTALE del monitor (`scene_v`, media Value non mascherata) con curva gamma (`BRIGHT_MIN=25`, `BRIGHT_MAX=95`, `BRIGHT_GAMMA=1.5`) ma cambia solo con deadband larga (`PUB_BRI_DELTA=20%`) e holdoff (`BRIGHT_HOLD=10s`): il controller Tuya si incastra con troppi comandi di sola bri. Un cambio colore valido fa "cavalcare" la bri nello stesso publish.
6. **Timing**: `INTERVAL=0.7s` tra le analisi (misurato: a 500ms i comandi localtuya si perdono, a 700ms 100% affidabile).
7. **Immersive** (`--immersive`, unit `ambilight-immersive.service`): stesso hue sulla luce camera ma sat ×`CAM_SAT_SCALE` (0.7) e bri ×`CAM_BRI_SCALE` (0.25) — il soffitto è luce ambiente, non bias light (stato dell'arte Hue Sync). Un solo daemon per volta: guard sul pidfile `/tmp/ambilight_daemon.pid` (doppio start = no-op con messaggio nel log).

Da NON rifare senza motivo: misurare di nuovo i limiti localtuya, ridurre cooldown/lock (si torna ai fade interrotti), o inseguire il colore a ogni tick (flip + scatti). Limite noto accettato: il percorso del fade lo decide il firmware della strip (interpolazione RGB, non percettiva).

### 5. [HomeAssistant](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/HomeAssistant/)
Integrations and statistics tracking for Home Assistant (HA).
*   [invia_watt.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/HomeAssistant/invia_watt.sh): Transmits GPU/system power draw statistics to a Home Assistant API endpoint.
*   [ryzen_monitor/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/HomeAssistant/ryzen_monitor/): C utility designed to monitor AMD Ryzen CPU sensors.

### 6. [Audio](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Audio/)
Fast sink switching via PulseAudio (`pactl`).
*   [BackBeatPro2.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Audio/BackBeatPro2.sh): Switches audio output to BackBeat Pro 2 Bluetooth headphones.
*   [Casse.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Audio/Casse.sh): Switches audio to default speakers.
*   [Cuffie.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Audio/Cuffie.sh): Switches audio to wired headphones.

### 7. [Display](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Display/)
Handles display profile shifts between standard PC Monitor and TV.
*   [ReturnToDesktop.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Display/ReturnToDesktop.sh) / [ReturnToDesktop60Hz.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Display/ReturnToDesktop60Hz.sh): Restores the monitor layout.
*   [ReturnToTV.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Display/ReturnToTV.sh) / [ReturnToTV_Delayed.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Display/ReturnToTV_Delayed.sh): Connects/scales output for TV.
*   [PreCambioRisolzione.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Display/PreCambioRisolzione.sh) / [PostCambioRisoluzione.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Display/PostCambioRisoluzione.sh): System-wide display transition hooks (pre/post resolution change).
*   See [DisplaySwitching_README.md](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Display/DisplaySwitching_README.md) for more details.

### 8. [mpv](file:///home/lorenzo/Documenti/GitHub/dotfiles/configs/mpv/)
Advanced configuration for the MPV media player. This directory is synced from the real config in use (`~/.config/mpv`) by `rSync.sh` (excluding the transient `watch_later/`).
*   Custom keybindings (`input.conf`), performance tweaks (`mpv.conf`), shaders (Anime4K, FSRCNNX), and lua scripts (such as `uosc` overlay and `thumbfast`).
*   See [MPV_Configuration_README.md](file:///home/lorenzo/Documenti/GitHub/dotfiles/configs/mpv/MPV_Configuration_README.md) for detailed descriptions.

### 9. [rSync](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/rSync/)
A suite of backup synchronization scripts integrated with LLMs to automatically generate Git commit messages based on file diffs.
*   Supports local AI model servers (LM Studio) and cloud LLMs (Gemini).
*   See [Rsync_Operations_README.md](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/rSync/Rsync_Operations_README.md) for usage and configuration.

### 10. [VideoTools](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/VideoTools/)
Automates searching for video files and converting them via FFmpeg.
*   [VideoTools.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/VideoTools/VideoTools.sh) and [Converti e verifica.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/VideoTools/Converti%20e%20verifica.sh).
*   [crea_test_video.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/VideoTools/crea_test_video.sh) / [Create_corrupted_video.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/VideoTools/Create_corrupted_video.sh): Generates test/corrupted dummy video streams for utility validation.
*   See [VideoProcessing_README.md](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/VideoTools/VideoProcessing_README.md) for implementation details.

### 11. [AI](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/AI/)
Controls and starts local machine learning / generative AI services.
*   [OllamaServer.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/AI/OllamaServer.sh): Restarts the Ollama (and watchtower) Docker containers.
*   [StableDiffusionWebUI.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/AI/StableDiffusionWebUI.sh): Starts the local Stable Diffusion web UI.
*   [SwarmUI.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/AI/SwarmUI.sh): Starts the SwarmUI image generation frontend.

### 12. [ExportGnomeExtensions](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/ExportGnomeExtensions/)
Backs up the enabled GNOME Shell extensions as a lightweight list (no extension files are copied).
*   [ExportGnomeExtensions.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/ExportGnomeExtensions/ExportGnomeExtensions.sh): Non-interactive; writes the enabled UUID list (`enabled-extensions.list`) and the per-extension dconf settings (`extensions-settings.conf`). Run automatically by `rsync_sync.service` (`ExecStartPre`) before every sync.
*   [RestoreGnomeExtensions.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/ExportGnomeExtensions/RestoreGnomeExtensions.sh): Manual; downloads each extension from extensions.gnome.org, installs it in `~/.local/share/gnome-shell/extensions/`, enables it, and restores the dconf settings. Skips extensions missing/incompatible on EGO (reports them at the end).

---

## Guidelines:
- Each script should ideally be self-contained or clearly document its dependencies.
- Provide comments within scripts for clarity.
- Ensure scripts are executable (`chmod +x script_name.sh`).
