# Dotfiles & Personal Scripts

This repository contains a collection of personal dotfiles, shell scripts, and configuration files designed to automate various tasks, enhance system usability, and manage specific applications on a Linux environment. These configurations and scripts are tailored for personal use, covering areas such as media management, system automation, AI/ML server management, and desktop environment customization.

## Notes on Commit Messages

The commit messages in this repository are automatically generated using a Large Language Model (Gemini 2.5 Flash). Therefore, they may not always be fully reliable or perfectly consistent with the actual changes made in the commits. Please refer to the code itself for the most accurate understanding of modifications.

## Features

*   **Automated Anime Downloads & Conversion**: A comprehensive system for downloading anime episodes in parallel and converting them to H.265, with integrity verification.
*   **MPV Player Enhancements**: Custom configurations for MPV, including advanced input bindings, UI scripts (uosc, thumbfast), and a wide array of Anime4K and FSRCNNX shaders for superior video playback.
*   **Nautilus Context Menu Scripts**: Integration of various video conversion, verification, and media information scripts directly into the Nautilus file manager context menus for quick access.
*   **Systemd User Services**: Automation of recurring tasks and application management through user-level systemd services and timers (e.g., anime downloads, Flatpak updates, rsync synchronization, LM Studio, Sunshine streaming).
*   **Display Management**: Scripts for switching display outputs (e.g., to TV, back to desktop) and handling resolution changes for specific applications like Yuzu.
*   **Keyboard Shortcut Management**: Tools to export and load custom keyboard shortcuts.
*   **General Utility Scripts**: A collection of miscellaneous shell scripts for tasks like starting Home Assistant, creating test/corrupted videos, managing AI/ML servers (Ollama, Stable Diffusion WebUI, SwarmUI), and more.
*   **File Synchronization**: rsync scripts for efficient file backup and synchronization with exclusion lists.

## Usage and Installation

This repository is a collection of personal dotfiles and scripts. Since this is a repo designed for personal use, the guide and particularly the paths described depend on your system or configuration of it. To use them, clone the repository and then symlink or copy (raccomanded) the relevant files to their respective locations in your home directory, (e.g., `~/.config/mpv/`, `~/.local/share/nautilus/scripts/`, `~/.config/systemd/user/`) or use the vary install scripts. 

**General Steps:**

1.  **Clone the repository:**
    ```bash
    git clone git@github.com:lorenzo0932/dotfiles.git ~/Documenti/GitHub/dotfiles
    ```
2.  **Navigate to the cloned directory:**
    ```bash
    cd ~/Documenti/GitHub/dotfiles
    ```
3.  **Install**
    ```bash
    chmod +x installAll.sh
    ./InstallAll.sh
    ```
    * If you want you can install only part of this project using the scripts that you can find in [installationScripts](https://github.com/lorenzo0932/dotfiles/tree/main/installationScripts)

**Specific Configurations:**

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
