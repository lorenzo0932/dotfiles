# myScript/ - Personal Scripts Overview

This directory contains a diverse and comprehensive set of personal scripts and automation tools for Linux system management, display configuration, media playback, local AI/ML service orchestration, and backups.

## Subdirectories and Core Components

### 1. [BackupJellfyfin](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/BackupJellfyfin/)
Manages Jellyfin media server configurations backups.
*   [backupJellyfin.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/BackupJellfyfin/backupJellyfin.sh): Automates the copying and compression of Jellyfin settings.

### 2. [Configurazione blocco schermo automatico](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Configurazione%20blocco%20schermo%20automatico/)
Automates the system lock screen operations.
*   [AvviaLockscreen.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Configurazione%20blocco%20schermo%20automatico/AvviaLockscreen.sh): Script that launches lock screen behavior.

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

### 6. [Script cambio output audio](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20output%20audio/)
Fast sink switching via PulseAudio (`pactl`).
*   [BackBeatPro2.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20output%20audio/BackBeatPro2.sh): Switches audio output to BackBeat Pro 2 Bluetooth headphones.
*   [Casse.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20output%20audio/Casse.sh): Switches audio to default speakers.
*   [Cuffie.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20output%20audio/Cuffie.sh): Switches audio to wired headphones.

### 7. [Script cambio schermo](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20schermo/)
Handles display profile shifts between standard PC Monitor and TV.
*   [ReturnToDesktop.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20schermo/ReturnToDesktop.sh) / [ReturnToDesktop60Hz.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20schermo/ReturnToDesktop60Hz.sh): Restores the monitor layout.
*   [ReturnToTV.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20schermo/ReturnToTV.sh) / [ReturnToTV_Delayed.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20schermo/ReturnToTV_Delayed.sh): Connects/scales output for TV.
*   See [DisplaySwitching_README.md](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20schermo/DisplaySwitching_README.md) for more details.

### 8. [mpv](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/mpv/)
Advanced configuration for the MPV media player.
*   Custom keybindings (`input.conf`), performance tweaks (`mpv.conf`), shaders (Anime4K, FSRCNNX), and lua scripts (such as `uosc` overlay and `thumbfast`).
*   See [MPV_Configuration_README.md](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/mpv/MPV_Configuration_README.md) for detailed descriptions.

### 9. [rSync](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/rSync/)
A suite of backup synchronization scripts integrated with LLMs to automatically generate Git commit messages based on file diffs.
*   Supports local AI model servers (LM Studio) and cloud LLMs (Gemini).
*   See [Rsync_Operations_README.md](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/rSync/Rsync_Operations_README.md) for usage and configuration.

### 10. [search&Convert](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/search&Convert/)
Automates searching for video files and converting them via FFmpeg.
*   [search&Convert.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/search&Convert/search&Convert.sh) and [Converti e verifica.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/search&Convert/Converti%20e%20verifica.sh).
*   See [VideoProcessing_README.md](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/search&Convert/VideoProcessing_README.md) for implementation details.

### 11. [Yuzu](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Yuzu/)
Hooks executed automatically before and after screen resolution changes for the Yuzu Emulator.
*   See [YuzuHooks_README.md](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Yuzu/YuzuHooks_README.md) for instructions.

---

## Root Level Utility Scripts

*   `AvviaHomeAssistant.sh`: Launches Home Assistant.
*   `HandleHomeAssistantFailure.sh`: Recovery procedures for when the HA instance is unresponsive.
*   `crea_test_video.sh` / `Create_corrupted_video.sh`: Generates test/corrupted dummy video streams for utility validation.
*   `OllamaServer.sh` / `StableDiffusionWebUI.sh` / `SwarmUI.sh`: Controls and starts local machine learning / generative AI services.
*   `PopupDownloadFiniti.sh`: Desktop pop-up alert for download triggers.
*   `PreCambioRisolzione.sh` / `PostCambioRisoluzione.sh`: System-wide display transition hooks.
*   `removeDKMS.sh`: Clears old and dangling DKMS drivers from Linux kernels.
*   `toggle_pano.sh`: Toggles panoramic visual setups.

## Guidelines:
- Each script should ideally be self-contained or clearly document its dependencies.
- Provide comments within scripts for clarity.
- Ensure scripts are executable (`chmod +x script_name.sh`).
