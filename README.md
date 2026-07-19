# Dotfiles & Personal Scripts

This repository contains a comprehensive collection of personal dotfiles, shell scripts, and configuration files designed to automate various tasks, enhance system usability, and manage specific applications on a Linux environment. These configurations and scripts are tailored for personal use, covering areas such as media management, system automation, AI/ML server management, and desktop environment customization.

## Notes on Commit Messages

The commit messages in this repository are automatically generated using a Large Language Model (Gemini 2.5 Flash). Therefore, they may not always be fully reliable or perfectly consistent with the actual changes made in the commits. Please refer to the code itself for the most accurate understanding of modifications.

## Features

This project is structured into several key areas, each containing specialized scripts and configurations:

### 1. Installation Scripts ([installationScripts/](file:///home/lorenzo/Documenti/GitHub/dotfiles/installationScripts/))
A collection of scripts to facilitate the installation and setup of various components of this dotfiles repository.
*   [installAll.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/installAll.sh): The main script (located in the repository root) to install all components.
*   [installMPV.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/installationScripts/installMPV.sh): Installs MPV configurations and scripts.
*   [installNautilusScripts.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/installationScripts/installNautilusScripts.sh): Installs Nautilus context menu scripts.
*   [installScripts.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/installationScripts/installScripts.sh): Installs general utility scripts.
*   [installServices.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/installationScripts/installServices.sh): Installs systemd user services.

### 2. General Utility Scripts ([myScript/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/))
A diverse set of shell and Python scripts for automation, hardware monitoring, and media configuration:
*   **Home Assistant Management**: [AvviaHomeAssistant.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/AvviaHomeAssistant.sh), [HandleHomeAssistantFailure.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/HandleHomeAssistantFailure.sh) for starting and recovering Home Assistant. Also contains specialized scripts in [myScript/HomeAssistant/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/HomeAssistant/) like [invia_watt.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/HomeAssistant/invia_watt.sh) and the AMD CPU monitor [ryzen_monitor/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/HomeAssistant/ryzen_monitor/).
*   **Jellyfin Backup**: [myScript/BackupJellfyfin/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/BackupJellfyfin/) contains [backupJellyfin.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/BackupJellfyfin/backupJellyfin.sh) for automated configuration backups.
*   **Game Mode**: [myScript/GameMode/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/GameMode/) includes [openSteamAtConnection.py](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/GameMode/openSteamAtConnection.py) to launch Steam on connectivity detection.
*   **Video Utilities**: [crea_test_video.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/crea_test_video.sh), [Create_corrupted_video.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Create_corrupted_video.sh) for creating test and corrupted video files.
*   **AI/ML Server Management**: [OllamaServer.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/OllamaServer.sh), [StableDiffusionWebUI.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/StableDiffusionWebUI.sh), [SwarmUI.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/SwarmUI.sh) for managing local AI/ML servers.
*   **System Events**: [PopupDownloadFiniti.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/PopupDownloadFiniti.sh) for download notifications, [removeDKMS.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/removeDKMS.sh) for DKMS module removal.
*   **Display Management**: [PostCambioRisoluzione.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/PostCambioRisoluzione.sh), [PreCambioRisolzione.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/PreCambioRisolzione.sh), [toggle_pano.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/toggle_pano.sh) for handling resolution changes and panoramic display modes.
*   **Automatic Lockscreen ([myScript/Configurazione blocco schermo automatico/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Configurazione%20blocco%20schermo%20automatico/))**: Scripts for configuring and managing automatic screen locking.
*   **Keyboard Shortcut Management ([myScript/ExportKeyboardShortcut/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/ExportKeyboardShortcut/))**: Tools to export and load custom keyboard shortcuts.
*   **Audio Output Switching ([myScript/Script cambio output audio/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20output%20audio/))**: Scripts to switch PulseAudio default sinks to [Speakers](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20output%20audio/Casse.sh), [Headphones](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20output%20audio/Cuffie.sh), or [Bluetooth headset](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20output%20audio/BackBeatPro2.sh).
*   **MPV Player Configuration ([myScript/mpv/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/mpv/))**:
    *   Custom `input.conf` and `mpv.conf` for enhanced media playback.
    *   `fonts/`: Custom fonts for MPV UI.
    *   `script-opts/`: Configuration for MPV scripts like `osc.conf`, `thumbfast.conf`, `uosc.conf`.
    *   `scripts/`: MPV Lua scripts including `dynamic-crop.lua`, `thumbfast.lua`, and the `uosc` modern UI.
    *   `shaders/`: Anime4K and FSRCNNX shaders for superior video upscaling and processing.
*   **Rsync Operations ([myScript/rSync/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/rSync/))**: Scripts for efficient file backup and synchronization (`rSync.sh`, `rSync_dev.sh`, `rSync_NoCommit.sh`, and `rSync(LMStudio).sh`) including `exclude.txt`.
*   **Display Switching ([myScript/Script cambio schermo/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20schermo/))**: Scripts like [ReturnToDesktop.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20schermo/ReturnToDesktop.sh), [ReturnToDesktop60Hz.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20schermo/ReturnToDesktop60Hz.sh), [ReturnToTV.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20schermo/ReturnToTV.sh), and [ReturnToTV_Delayed.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Script%20cambio%20schermo/ReturnToTV_Delayed.sh) for managing display outputs.
*   **Video Search & Convert ([myScript/search&Convert/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/search&Convert/))**: Scripts for converting and verifying video files, including [Converti e verifica.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/search&Convert/Converti%20e%20verifica.sh) and [search&Convert.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/search&Convert/search&Convert.sh).
*   **Yuzu Hooks ([myScript/Yuzu/](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Yuzu/))**: Specific scripts ([PostCambioRisoluzione.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Yuzu/PostCambioRisoluzione.sh), [PreCambioRisolzione.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/myScript/Yuzu/PreCambioRisolzione.sh)) to handle display changes for the Yuzu emulator.

### 3. Nautilus Extensions ([nautilus/](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/))
Scripts integrated into the Nautilus file manager context menus for quick access to video processing and media information tools.
*   [scripts/](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/): Contains scripts for video conversion and movement (Silent, Burst), legacy subtitle burning, online class lecture conversion, video integrity validation (CPU/GPU), and experimental converters (AV1, Anime4K).

### 4. Systemd User Services ([systemd/user/](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/))
Automation of recurring tasks and application management through user-level systemd services and timers:
*   **Application Services**: [HomeAssistant.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/HomeAssistant.service), [lmstudio.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/lmstudio.service), [sunshine.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/sunshine.service), [ytdlp2strm.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/ytdlp2strm.service) for managing specific applications.
*   **Timers**: [flatpak-update.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/flatpak-update.timer), [HomeAssistant.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/HomeAssistant.timer), [invia-watt.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/invia-watt.timer), [jellyfin-backup.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/jellyfin-backup.timer), [lmstudio.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/lmstudio.timer), [rsync_sync.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/rsync_sync.timer), [Shutdown.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/Shutdown.timer) for scheduling tasks.
*   **Utility Services**: [flatpak-update.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/flatpak-update.service), [homeassistant-failure.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/homeassistant-failure.service), [invia-watt.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/invia-watt.service), [jellyfin-backup.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/jellyfin-backup.service), [protonvpn_reconnect.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/protonvpn_reconnect.service), [rsync_sync.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/rsync_sync.service), [Shutdown.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/Shutdown.service), [xbox-monitor.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/xbox-monitor.service) for system maintenance, gaming controller configuration, and automation.
*   `default.target.wants/`, `gnome-session.target.wants/`, `graphical-session.target.wants/`, `timers.target.wants/`: Directories containing symlinks to enabled services and timers.

### 5. Tuned Configuration ([tuned_config/](file:///home/lorenzo/Documenti/GitHub/dotfiles/tuned_config/))
Custom `tuned` profiles and configuration for system optimization:
*   [performance-aggressivo/tuned.conf](file:///home/lorenzo/Documenti/GitHub/dotfiles/tuned_config/performance-aggressivo/tuned.conf): An aggressive performance profile.
*   [Istruzioni.txt](file:///home/lorenzo/Documenti/GitHub/dotfiles/tuned_config/Istruzioni.txt): Instructions on installing the tuned profile.
*   [ppd.conf](file:///home/lorenzo/Documenti/GitHub/dotfiles/tuned_config/ppd.conf): Power Profiles Daemon compatibility configuration.

## Usage and Installation

This repository is a collection of personal dotfiles and scripts. Since this is a repo designed for personal use, the guide and particularly the paths described depend on your system or configuration of it. To use them, clone the repository and then symlink or copy (recommended) the relevant files to their respective locations in your home directory, (e.g., `~/.config/mpv/`, `~/.local/share/nautilus/scripts/`, `~/.config/systemd/user/`) or use the provided install scripts.

**General Steps:**

1.  **Clone the repository:**
    ```bash
    git clone git@github.com:lorenzo0932/dotfiles.git ~/Documenti/GitHub/dotfiles
    ```
2.  **Navigate to the cloned directory:**
    ```bash
    cd ~/Documenti/GitHub/dotfiles
    ```
3.  **Install:**
    ```bash
    chmod +x installAll.sh
    ./installAll.sh
    ```
    *   If you want, you can install only part of this project using the scripts found in the `installationScripts/` directory.

**Specific Configurations:**

*   **MPV Shaders**: Ensure your MPV installation supports GLSL shaders. The shaders are located in `myScript/mpv/shaders/`.
*   **Nautilus Scripts**: After symlinking, you might need to restart Nautilus (`nautilus -q` and then reopen) or log out/in for the scripts to appear in the context menu.
*   **Systemd Services**: After enabling services/timers, you can check their status with `systemctl --user status <service_name>`.

## Dependencies

Many scripts rely on common Linux utilities and applications. Ensure you have the following installed:

*   `python3` (for other Python-based scripts)
*   `aria2c` (for parallel downloads)
*   `ffmpeg` (for video conversion and verification)
*   `mpv` (for media playback with custom configurations)
*   `rsync` (for file synchronization)
*   `systemd` (for user services and timers)
*   `nautilus` (if using Nautilus scripts)
*   `mediainfo` (for `Apri in media info.sh`)
*   `xrandr` (for display management scripts)
*   `tuned` (for performance profiles)
*   `ollama`, `stable-diffusion-webui`, `swarm-ui` (if using AI/ML server management scripts)
*   `homeassistant` (if using Home Assistant management scripts)
*   `flatpak` (if using Flatpak update service)
*   `protonvpn-cli` (if using ProtonVPN reconnection service)
*   `yuzu` (if using Yuzu hooks)

This repository is continuously evolving with new scripts and configurations.
