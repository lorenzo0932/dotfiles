# Dotfiles & Personal Scripts

This repository contains a collection of personal dotfiles, shell scripts, and configuration files designed to automate various tasks, enhance system usability, and manage specific applications on a Linux environment. These configurations and scripts are tailored for personal use, covering areas such as media management, system automation, AI/ML server management, and desktop environment customization.

## Notes on Commit Messages

The commit messages in this repository are automatically generated using a local Large Language Model (LLM). Therefore, they may not always be fully reliable or perfectly consistent with the actual changes made in the commits. Please refer to the code itself for the most accurate understanding of modifications.

## Features

*   **Automated Anime Downloads & Conversion**: A comprehensive system for downloading anime episodes in parallel and converting them to H.265, with integrity verification.
*   **MPV Player Enhancements**: Custom configurations for MPV, including advanced input bindings, UI scripts (uosc, thumbfast), and a wide array of Anime4K and FSRCNNX shaders for superior video playback.
*   **Nautilus Context Menu Scripts**: Integration of various video conversion, verification, and media information scripts directly into the Nautilus file manager context menus for quick access.
*   **Systemd User Services**: Automation of recurring tasks and application management through user-level systemd services and timers (e.g., anime downloads, Flatpak updates, rsync synchronization, LM Studio, Sunshine streaming).
*   **Display Management**: Scripts for switching display outputs (e.g., to TV, back to desktop) and handling resolution changes for specific applications like Yuzu.
*   **Keyboard Shortcut Management**: Tools to export and load custom keyboard shortcuts.
*   **General Utility Scripts**: A collection of miscellaneous shell scripts for tasks like starting Home Assistant, creating test/corrupted videos, managing AI/ML servers (Ollama, Stable Diffusion WebUI, SwarmUI), and more.
*   **File Synchronization**: rsync scripts for efficient file backup and synchronization with exclusion lists.

## Project Structure

Here's an overview of the main directories and their contents:

*   `myScript/`: Contains a variety of general-purpose shell scripts.
    *   `AvviaHomeAssistant.sh`: Script to start Home Assistant.
    *   `crea_test_video.sh`, `Create_corrupted_video.sh`: Scripts for video testing.
    *   `OllamaServer.sh`, `StableDiffusionWebUI.sh`, `SwarmUI.sh`: Scripts to manage AI/ML related servers.
    *   `PopupDownloadFiniti.sh`: Script for download completion notifications.
    *   `PostCambioRisoluzione.sh`, `PreCambioRisolzione.sh`: Scripts executed before/after display resolution changes.
    *   `removeDKMS.sh`: Script to remove DKMS modules.
    *   `toggle_pano.sh`: Script to toggle panorama mode.
    *   `downloadAnime/`: **AniDownloader** - A dedicated system for automated anime downloads and video conversion. Refer to `myScript/downloadAnime/REDME.md` for detailed information on its setup and usage.
    *   `ExportKeyboardShortcut/`: Scripts and configuration files for exporting and loading custom keyboard shortcuts.
    *   `mpv/`: MPV media player configuration files, custom fonts, Lua scripts (uosc, thumbfast, dynamic-crop), and a comprehensive collection of Anime4K and FSRCNNX video shaders.
    *   `rSync/`: rsync scripts for file synchronization and backups, including an `exclude.txt` for specifying files/directories to ignore.
    *   `Script cambio schermo/`: Scripts to switch between different display outputs (e.g., `ReturnToDesktop.sh`, `ReturnToTV.sh`).
    *   `search&Convert/`: Scripts for searching and converting video files.
    *   `Yuzu/`: Scripts specifically designed to handle display resolution changes for the Yuzu emulator.
*   `nautilus/`: Contains custom scripts integrated with the Nautilus file manager.
    *   `scripts/`: Various shell scripts for video conversion (H.265, AV1, with/without subtitles, burn subtitles), video integrity verification, and opening files with MediaInfo, accessible via Nautilus context menus.
*   `systemd/`: Systemd service and timer units for user-level automation.
    *   `user/`: User-specific systemd units, including services and timers for:
        *   `downloadAnime.service`/`downloadAnime.timer`: Automating anime downloads.
        *   `flatpak-update.service`/`flatpak-update.timer`: Scheduled Flatpak updates.
        *   `lmstudio.service`: Managing the LM Studio server.
        *   `protonvpn_reconnect.service`: Ensuring ProtonVPN reconnection.
        *   `rsync_sync.service`/`rsync_sync.timer`: Scheduled rsync synchronization.
        *   `sunshine.service`: Managing the Sunshine streaming service.
        *   `ytdlp2strm.service`: Service for youtube-dlp streaming.

## Usage and Installation

This repository is a collection of personal dotfiles and scripts. To use them, you typically clone the repository and then symlink or copy the relevant files to their respective locations in your home directory (e.g., `~/.config/mpv/`, `~/.local/share/nautilus/scripts/`, `~/.config/systemd/user/`).

**General Steps:**

1.  **Clone the repository:**
    ```bash
    git clone git@github.com:lorenzo0932/dotfiles.git ~/Documenti/GitHub/dotfiles
    ```
2.  **Navigate to the cloned directory:**
    ```bash
    cd ~/Documenti/GitHub/dotfiles
    ```
3.  **Symlink or Copy Files:**
    *   For `mpv` configurations:
        ```bash
        ln -sfn ~/Documenti/GitHub/dotfiles/myScript/mpv ~/.config/mpv
        ```
    *   For `nautilus` scripts:
        ```bash
        ln -sfn ~/Documenti/GitHub/dotfiles/nautilus/scripts ~/.local/share/nautilus/scripts
        ```
    *   For `systemd` user units:
        ```bash
        ln -sfn ~/Documenti/GitHub/dotfiles/systemd/user ~/.config/systemd/user
        systemctl --user daemon-reload
        systemctl --user enable --now downloadAnime.timer rsync_sync.timer flatpak-update.timer
        # Enable other services as needed, e.g., lmstudio.service, sunshine.service
        ```
    *   For other scripts in `myScript/`, you can either add `~/Documenti/GitHub/dotfiles/myScript/` to your `PATH` environment variable or create symlinks to individual scripts in a directory already in your `PATH` (e.g., `~/.local/bin/`).

**Specific Configurations:**

*   **AniDownloader**: Refer to `myScript/downloadAnime/AniDownloader_README.md` for detailed setup, dependencies, and configuration of `series_data.json`.
*   **MPV Shaders**: Ensure your MPV installation supports GLSL shaders. The shaders are located in `myScript/mpv/shaders/`.
*   **Nautilus Scripts**: After symlinking, you might need to restart Nautilus (`nautilus -q` and then reopen) or log out/in for the scripts to appear in the context menu.
*   **Systemd Services**: After enabling services/timers, you can check their status with `systemctl --user status <service_name>`.

## Dependencies

Many scripts rely on common Linux utilities and applications. Ensure you have the following installed:

*   `python3` (for AniDownloader)
*   `aria2c` (for AniDownloader)
*   `ffmpeg` (for video conversion and verification)
*   `mpv` (for media playback with custom configurations)
*   `rsync` (for file synchronization)
*   `systemd` (for user services and timers)
*   `nautilus` (if using Nautilus scripts)
*   `mediainfo` (for `Apri in media info.sh`)
*   `xrandr` (for display management scripts)

This repository is continuously evolving with new scripts and configurations.

This is a test 2