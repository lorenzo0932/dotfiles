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

*   **`installMPV.sh`**: Installs an advanced MPV configuration, including custom scripts, shaders, and fonts, offering enhanced video playback capabilities. It prompts the user to choose between a native or Flatpak MPV installation.
*   **`installNautilusScripts.sh`**: Copies custom Nautilus scripts to the appropriate directory, making them available for use within the Nautilus file manager. These scripts provide additional functionalities for file management.
*   **`installScripts.sh`**: Copies all custom bash scripts from the `myScript` directory and its subfolders to a designated location, then adds these script directories to the system's PATH, allowing them to be executed from any terminal location.
*   **`installServices.sh`**: Installs and enables various user-level systemd services, such as timers for `downloadAnime`, `flatpak-update`, and `rsync`, automating background tasks.

### Important Notes:

*   **Permissions:** Ensure you have the necessary permissions to execute the scripts and for the operations they perform (e.g., package installation, modification of system configuration files). `sudo` password might be required.
*   **Backup:** It is always good practice to back up your existing configuration files before running scripts that modify them.
*   **Review:** It is recommended to read the content of each script before executing it to understand exactly what changes will be made to your system.
