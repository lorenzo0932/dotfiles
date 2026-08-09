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
*   [drevo_keyboard_sync.py](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/GameMode/drevo_keyboard_sync.py): Ambilight tastiera — la Drevo Tyrfing V2 segue i colori dello schermo come la strip. Daemon (unit `ambilight-keyboard.service`, venv `~/.local/venvs/dtv2`): si sottoscrive a `fedora/light/led/color` e applica il colore statico via `dtv2` (1 pacchetto HID da 32 byte, bri 1:1 della strip). Reassert ogni 2s: qualunque combo Fn premuta viene sovrascritta. Su `fedora/light/end` (e `fedora/light/start`) torna al **default della strip** (HS 29.081/88.976, arancione) ma resta **sempre accesa**: solo la luminosità cambia con la soglia giorno/notte comune a tutte le luci — giorno 100%, notte 25%, con la notte che inizia 30 minuti **prima** del tramonto (calcolo alba/tramonto NOAA in locale, coordinate = quelle di HA; stesso offset della condizione sun dell'automazione HA "Ambilight fine sessione"). Richiede la udev rule `myScript/udev/99-drevo-tyrfing.rules` (installata da `installationScripts/installDeps.sh`).
*   [udev/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/udev/): regole udev per dispositivi con permessi HID personalizzati. Contiene `99-drevo-tyrfing.rules` (tastiera Drevo Tyrfing V2, VID 0416 PID a0f8 → MODE 0666 su hidraw); installata su `/etc/udev/rules.d/` dall'installer `installDeps.sh`.

#### Ambilight: design rationale (v8.1)
Obiettivo: transizioni "cinematiche" — pochi cambi di colore, ognuno un fade lungo e fluido. Le luci hanno il fade hardware (strip LED: dp localtuya 26=150, ~700°/s misurato, 180° in 200-300ms; luce camera: fade nativo più veloce, conferma DP ~17ms e fluido fino a 200ms), quindi il daemon **non** deve mandare step intermedi.

Catena di filtri nel daemon (in ordine, costanti in cima a `screenshot_portal.py`):
1. **Estrazione**: istogramma HSV a 18 bin pesato per energia (sat×val); il colore è la **media gaussiana dei bin attorno al bin vincente** (σ=2 bin ≈ 40°): aree piccole ma sature (mani, oggetti in movimento) non spostano il colore. Scena quasi senza colore (<1.2% di energia) → nessun publish.
2. **Edge masking** (`EDGE_WEIGHT`, `EDGE_FLOOR=0.30`, `EDGE_POWER=2.0`): peso spostato dal centro ai bordi (effetto ambilight: le luci estendono la periferia dello schermo). Il gate "nessun colore" usa l'energia non mascherata.
3. **Soglia di dominanza** (`DOMINANCE=1.5`): se un cluster hue lontano (>4 bin ≈ 80°) ha energia ≥ vincente/1.5 la scena è **bimodale ambigua** (es. personaggio caldo + sfondo freddo, tipico anime): il bin vincente è bistabile e flipperebbe tra i poli a ogni frame. Il colore resta l'ultimo applicato, ma la **bri continua a seguire** la scena (deadband + holdoff come i cambi di sola luminosità). Misurato su contenuto anime: elimina il 70% delle anomalie A→B→A senza congelare la stanza.
4. **Persistenza direzionale** (`PERSIST_DEG=90`, `PERSIST_TICKS=2` ≈ 400ms): un salto grande (>90°) deve restare lontano dall'ultimo colore per 2 tick consecutivi prima di essere pubblicato. I battiti A-B-A non accumulano mai 2 tick; un vero cambio scena (energia 2.5-3.7x) passa in ~400ms.
5. **Color lock adattivo** (`LOCK_DEG=25`): i tick di conferma richiesti dipendono dalla distanza dall'ultimo pubblicato — 1 per salti >120° (200ms), 2 per >60°, 4 per il resto — e devono stare entro ±25°. I flash brevi restano bloccati, i salti di scena grandi arrivano subito.
6. **Cooldown** (`COOLDOWN=0.3s`) + **timing** (`INTERVAL=0.2s` = 5Hz): al limite del canale localtuya (20/20 publish senza perdite fino a 200ms, perdite a 100ms); il fade hardware arriva a destinazione prima del prossimo cambio.
7. **Deadband + bri dinamica**: publish solo se il target dista ≥30° di hue o ≥0.2 di saturazione dall'ultimo colore inviato. La bri segue la luminosità TOTALE del monitor (`scene_v`, media Value non mascherata) con curva gamma (`BRIGHT_MIN=25`, `BRIGHT_MAX=95`, `BRIGHT_GAMMA=1.5`) ma cambia solo con deadband (`PUB_BRI_DELTA=12%`) e holdoff (`BRIGHT_HOLD=3s`). Un cambio colore valido fa "cavalcare" la bri nello stesso publish.
8. **Immersive** (`--immersive`, unit `ambilight-immersive.service`): stesso hue sulla luce camera ma sat ×`CAM_SAT_SCALE` (0.7) e bri ×`CAM_BRI_SCALE` (0.25) — il soffitto è luce ambiente, non bias light (stato dell'arte Hue Sync: accent light attenuata). La camera segue 1:1 con lo stesso rate (nessuna decimazione). Un solo daemon per volta: guard sul pidfile `/tmp/ambilight_daemon.pid` (doppio start = no-op con messaggio nel log).

Stato dell'arte: con driver HA/ZigBee il massimo teorico di smoothing è 20-25Hz (HyperHDR non consiglia di superarlo); il nostro limite reale è il canale localtuya (latenza comando 90-140ms, perdite <200ms). I fade Tuya standard sono 400-1000ms fissi in MCU: il nostro è più veloce.

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
