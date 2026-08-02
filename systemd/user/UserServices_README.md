# systemd/user/ - Systemd User Services

This directory contains systemd user-level unit files (`.service` and `.timer`) and targets directory symlinks. These files manage automated workflows, system utilities, and application lifecycle tasks within the user session (without root privileges).

## Services (`.service` files)

*   **[anidownloaderd.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/anidownloaderd.service)**: Headless AniDownloader daemon.
*   **[Shutdown.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/Shutdown.service)**: Implements automated system power shutdown routines.
*   **[flatpak-update.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/flatpak-update.service)**: Triggers auto-updates for installed Flatpaks.
*   **[invia-watt.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/invia-watt.service)**: Runs power consumption reporting to Home Assistant (reads `MQTT_PASS` from `~/.config/mqtt.env` via `EnvironmentFile`).
*   **[jellyfin-backup.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/jellyfin-backup.service)**: Triggers backups of Jellyfin configurations.
*   **[lmstudio.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/lmstudio.service)**: Serves local Large Language Models via LM Studio. Disabled by default.
*   **[rsync_sync.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/rsync_sync.service)**: Runs the rSync synchronization script for backing up dotfiles/settings.
*   **[sunshine.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/sunshine.service)**: Sunshine Game Streaming server host daemon.
*   **[xbox-monitor.service](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/xbox-monitor.service)**: Monitors system events related to Xbox gamepad connectivity.

> Nota: `protonvpn_reconnect.service` è installata e gestita automaticamente dall'app ProtonVPN, quindi è esclusa dal backup (`exclude.txt`). `ytdlp2strm.service` è stata rimossa (tool non più installato).

## Timers (`.timer` files)

*   **[anidownloader-check.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/anidownloader-check.timer)**: Checks AniDownloader periodically.
*   **[Shutdown.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/Shutdown.timer)**: Timer to trigger automatic machine shutdown.
*   **[flatpak-update.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/flatpak-update.timer)**: Schedules daily Flatpak package updates.
*   **[invia-watt.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/invia-watt.timer)**: Regularly runs the power usage reporter script.
*   **[jellyfin-backup.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/jellyfin-backup.timer)**: Periodically triggers the backup of Jellyfin configuration files.
*   **[lmstudio.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/lmstudio.timer)**: Triggers periodic LM Studio checks/tasks. Disabled by default.
*   **[rsync_sync.timer](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/rsync_sync.timer)**: Runs the repository dotfile syncing script at set intervals.

## Target Dependencies (`.target.wants/` folders)

*   **[default.target.wants/](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/default.target.wants/)**: Symlink to units launched at generic session startup:
    - `anidownloader-check.timer`
    - `anidownloaderd.service`
    - `onedriver@home-lorenzo-.OneDriveUnipi.service`
*   **[gnome-session.target.wants/](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/gnome-session.target.wants/)**: Services launched upon GNOME session initialization:
    - `gnome-remote-desktop.service`
*   **[graphical-session.target.wants/](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/graphical-session.target.wants/)**: Launch triggers when a GUI environment starts:
    - `sunshine.service`
    - `xbox-monitor.service`
*   **[timers.target.wants/](file:///home/lorenzo/Documenti/GitHub/dotfiles/systemd/user/timers.target.wants/)**: Auto-activated timers:
    - `flatpak-update.timer`
    - `invia-watt.timer`
    - `rsync_sync.timer`

---

## Guidelines:
- **Deployment**: These unit files are typically placed in `~/.config/systemd/user/` (or symlinked from this dotfiles repository to that location) for Systemd to manage them.
- **Reloading Systemd**: After modifying or adding new user unit files, reload the Systemd user daemon by running:
  ```bash
  systemctl --user daemon-reload
  ```
- **Controlling Units**:
  - Enable service/timer: `systemctl --user enable <unit_name>`
  - Disable: `systemctl --user disable <unit_name>`
  - Start immediately: `systemctl --user start <unit_name>`
  - Stop immediately: `systemctl --user stop <unit_name>`
- **Checking Status and Logs**:
  - Check status: `systemctl --user status <unit_name>`
  - View service logs: `journalctl --user -u <unit_name>`
