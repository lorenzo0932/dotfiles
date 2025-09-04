# Dotfiles & Personal Scripts

This repository contains a comprehensive collection of personal dotfiles, shell scripts, and configuration files designed to automate various tasks, enhance system usability, and manage specific applications on a Linux environment. These configurations and scripts are tailored for personal use, covering areas such as media management, system automation, AI/ML server management, and desktop environment customization.

## Notes on Commit Messages

The commit messages in this repository are automatically generated using a Large Language Model (Gemini 2.5 Flash). Therefore, they may not always be fully reliable or perfectly consistent with the actual changes made in the commits. Please refer to the code itself for the most accurate understanding of modifications.

## Features

This project is structured into several key areas, each containing specialized scripts and configurations:

### 1. Installation Scripts (`installationScripts/`)
A collection of scripts to facilitate the installation and setup of various components of this dotfiles repository.
*   `installAll.sh`: The main script to install all components.
*   `installMPV.sh`: Installs MPV configurations and scripts.
*   `installNautilusScripts.sh`: Installs Nautilus context menu scripts.
*   `installScripts.sh`: Installs general utility scripts.
*   `installServices.sh`: Installs systemd user services.

### 2. General Utility Scripts (`myScript/`)
A diverse set of shell scripts for various automation and management tasks.
*   **Home Assistant Management**: `AvviaHomeAssistant.sh`, `HandleHomeAssistantFailure.sh` for starting and managing Home Assistant.
*   **Video Utilities**: `crea_test_video.sh`, `Create_corrupted_video.sh` for creating test and corrupted video files.
*   **AI/ML Server Management**: `OllamaServer.sh`, `StableDiffusionWebUI.sh`, `SwarmUI.sh` for managing local AI/ML servers.
*   **System Events**: `PopupDownloadFiniti.sh` for download notifications, `removeDKMS.sh` for DKMS module removal.
*   **Display Management**: `PostCambioRisoluzione.sh`, `PreCambioRisolzione.sh`, `toggle_pano.sh` for handling resolution changes and panoramic display modes.
*   **Automatic Lockscreen (`myScript/Configurazione blocco schermo automatico/`)**: Scripts for configuring and managing automatic screen locking.
*   **Keyboard Shortcut Management (`myScript/ExportKeyboardShortcut/`)**: Tools to export and load custom keyboard shortcuts.
*   **MPV Player Configuration (`myScript/mpv/`)**:
    *   Custom `input.conf` and `mpv.conf` for enhanced media playback.
    *   `fonts/`: Custom fonts for MPV UI.
    *   `script-opts/`: Configuration for MPV scripts like `osc.conf`, `thumbfast.conf`, `uosc.conf`.
    *   `scripts/`: MPV Lua scripts including `dynamic-crop.lua`, `thumbfast.lua`, and the `uosc` modern UI.
    *   `shaders/`: A comprehensive collection of Anime4K and FSRCNNX shaders for superior video upscaling and processing.
*   **Rsync Operations (`myScript/rSync/`)**: Scripts for efficient file backup and synchronization, including an `exclude.txt` for selective syncing and specialized scripts for development and LM Studio.
*   **Display Switching (`myScript/Script cambio schermo/`)**: Scripts like `ReturnToDesktop.sh` and `ReturnToTV.sh` for managing display outputs.
*   **Video Search & Convert (`myScript/search&Convert/`)**: Scripts for converting and verifying video files, including `Converti e verifica.sh` and `search&Convert.sh`.
*   **Yuzu Hooks (`myScript/Yuzu/`)**: Specific scripts (`PostCambioRisoluzione.sh`, `PreCambioRisolzione.sh`) to handle display changes for the Yuzu emulator.

### 3. Nautilus Extensions (`nautilus/`)
Scripts integrated into the Nautilus file manager context menus for quick access to video processing and media information tools.
*   `scripts/`: Contains various scripts for video conversion, verification (with/without subtitles, AV1), and opening files in MediaInfo.

### 4. Systemd User Services (`systemd/user/`)
Automation of recurring tasks and application management through user-level systemd services and timers.
*   **Application Services**: `HomeAssistant.service`, `lmstudio.service`, `sunshine.service`, `ytdlp2strm.service` for managing specific applications.
*   **Timers**: `flatpak-update.timer`, `HomeAssistant.timer`, `lmstudio.timer`, `rsync_sync.timer`, `Shutdown.timer` for scheduling tasks.
*   **Utility Services**: `flatpak-update.service`, `homeassistant-failure.service`, `protonvpn_reconnect.service`, `rsync_sync.service`, `Shutdown.service` for system maintenance and automation.
*   `default.target.wants/`, `graphical-session.target.wants/`, `timers.target.wants/`: Directories containing symlinks to enabled services and timers.

### 5. Tuned Configuration (`tuned_config/`)
Custom `tuned` profiles for aggressive performance optimization.
*   `performance-aggressivo/tuned.conf`: An aggressive performance profile.

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
