# myScript/ExportKeyboardShortcut/

This directory contains scripts and configuration files for managing custom and default keyboard shortcuts, specifically designed for a Linux desktop environment (likely GNOME or a similar XDG-compliant system).

## Purpose:
- `Export|Load_Keybindings.sh`: This Bash script is designed to automate the process of exporting current keyboard shortcuts to files and loading them from files. It now supports exporting/importing:
    - **All Keybindings**: Includes Custom, Media (Non-Custom), and Window Manager (Non-Custom) keybindings.
    - **Custom Keybindings Only**: User-defined shortcuts.
    - **Media Keybindings Only**: Default multimedia and system-related shortcuts.
    - **Window Manager Keybindings Only**: Shortcuts related to window management (e.g., switching workspaces).

- `custom-and-media-keybindings.conf`: Exported snapshot of `/org/gnome/settings-daemon/plugins/media-keys/` (custom + media keybindings). Refreshed with `dconf dump` (see note below).
- `gnome-shell-keybindings.conf`: Exported snapshot of `/org/gnome/desktop/wm/keybindings/` (window manager keybindings). Refreshed with `dconf dump` (see note below).
- *Dynamically generated files (not committed by default, created when running the export options 2/3)*:
  - `custom-keybindings.conf`: Stores user-defined custom keybinding configurations when exporting option 2.
  - `custom-keybindings-string.txt`: Contains a raw string representation of the custom keybindings when exporting option 2.
  - `media-keybindings.conf`: Stores only default media-related keybindings when exporting option 3.

## Note on the committed snapshots:
The two committed `.conf` files are refreshed from the live system from time to time (manually or during a restore). To regenerate them from the current dconf:
```bash
dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > custom-and-media-keybindings.conf
dconf dump /org/gnome/desktop/wm/keybindings/ > gnome-shell-keybindings.conf
```

## Usage:
To run the script, navigate to this directory in your terminal and execute:
```bash
./Export|Load_Keybindings.sh
```
The script will present a menu with options to "Esporta configurazioni" (Export configurations) or "Carica configurazioni" (Load configurations).

### Export Options:
1.  **Tutte le scorciatoie (Custom, Media e Window Manager)**: Exports all keybindings into `custom-and-media-keybindings.conf` and `gnome-shell-keybindings.conf`.
2.  **Solo scorciatoie Custom**: Exports only custom keybindings into `custom-keybindings.conf` and `custom-keybindings-string.txt`.
3.  **Solo scorciatoie Media (Non Custom)**: Exports default media-related keybindings into `media-keybindings.conf`.
4.  **Solo scorciatoie Window Manager (Non Custom)**: Exports default window manager keybindings into `gnome-shell-keybindings.conf`.

### Load Options:
1.  **Tutte le scorciatoie (da custom-and-media-keybindings.conf e gnome-shell-keybindings.conf)**: Loads all keybindings from the respective files.
2.  **Solo scorciatoie Custom (da custom-keybindings.conf)**: Loads only custom keybindings.
3.  **Solo scorciatoie Media (Non Custom) (da media-keybindings.conf)**: Loads only default media-related keybindings.
4.  **Solo scorciatoie Window Manager (Non Custom) (da gnome-shell-keybindings.conf)**: Loads only default window manager keybindings.

## Guidelines:
- **Execution**: Ensure the `Export|Load_Keybindings.sh` script has executable permissions (`chmod +x Export|Load_Keybindings.sh`) before running it.
- **Backup**: Always back up your current system's keybindings before attempting to load new ones using the script to prevent accidental data loss.
- **Editing Configuration Files**: If you need to manually modify keybindings, understand the specific syntax and structure required by your desktop environment's keybinding system to avoid errors. Refer to your desktop environment's documentation for details.
- **Compatibility**: These scripts are tailored for specific system configurations (primarily GNOME/dconf). Verify compatibility if using them on a different Linux distribution or desktop environment.
