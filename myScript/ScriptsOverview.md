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
