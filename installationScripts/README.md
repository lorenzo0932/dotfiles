# Installation Scripts

This folder contains bash scripts designed to automate the installation and configuration of various components and utilities on your system.

## How to Install the Scripts

To use these scripts, follow the steps below:

1.  **Navigate to the `installationScripts` directory:**
    ```bash
    cd /home/lorenzo/Documenti/GitHub/dotfiles/installationScripts
    ```

2.  **Make the scripts executable:**
    Before running any script, ensure they have execution permissions:
    ```bash
    chmod +x *.sh
    ```

3.  **Execute the desired script:**
    You can run a specific script using `bash` or `./`:
    ```bash
    bash installMPV.sh
    # or
    ./installMPV.sh
    ```
    Replace `installMPV.sh` with the name of the script you wish to run (e.g., `installScripts.sh`, `installNautilusScripts.sh`, etc.).

    To install all main scripts, you can run `installAll.sh` from the main dotfiles directory:
    ```bash
    cd /home/lorenzo/Documenti/GitHub/dotfiles
    bash installAll.sh
    ```

### Script Descriptions:

*   **`installMPV.sh`**: Installs the MPV configuration (synced from `~/.config/mpv`) to the selected MPV config directory (native or Flatpak), including custom scripts, shaders, and fonts.
*   **`installNautilusScripts.sh`**: Copies the Nautilus context menu scripts (from `nautilus/scripts/`) to `~/.local/share/nautilus/scripts/`, making them available within the Nautilus file manager.
*   **`installScripts.sh`**: Copies the `myScript` directory to `~/.local/share/myScript` (without overwriting newer local files), then adds the script directories to the system's PATH, allowing them to be executed from any terminal location.
*   **`installServices.sh`**: Installs the systemd user units in `~/.config/systemd/user/` and enables the ones in use (AniDownloader, Flatpak updates, invia-watt, rsync sync, Sunshine, Xbox monitor).

### Important Notes:

*   **Permissions:** Ensure you have the necessary permissions to execute the scripts and for the operations they perform (e.g., package installation, modification of system configuration files). `sudo` password might be required.
*   **Backup:** It is always good practice to back up your existing configuration files before running scripts that modify them.
*   **Review:** It is recommended to read the content of each script before executing it to understand exactly what changes will be made to your system.
