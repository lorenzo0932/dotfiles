# systemd/user/

This directory contains Systemd user unit files, which are configuration files for services, timers, and targets that run under a specific user's session rather than as system-wide services. These units allow for automation of personal tasks, background processes, and scheduled operations without requiring root privileges.

## Purpose:
This directory houses a variety of user-specific Systemd units:
- **Services (`.service` files)**:
    - `downloadAnime.service`: Manages the `downloadAnime` process, likely for automated anime episode downloads.
    - `flatpak-update.service`: Handles Flatpak application updates.
    - `lmstudio.service`: Manages the LM Studio application, possibly for AI model serving.
    - `protonvpn_reconnect.service`: Ensures ProtonVPN connection stability by attempting reconnections.
    - `rsync_sync.service`: Manages rsync synchronization tasks, likely for personal backups or data mirroring.
    - `sunshine.service`: Manages the Sunshine game streaming host service.
    - `ytdlp2strm.service`: Manages the `ytdlp2strm` process, converting downloaded media to streamable formats.
- **Timers (`.timer` files)**:
    - `downloadAnime.timer`: Schedules the `downloadAnime.service` to run at specific intervals.
    - `flatpak-update.timer`: Schedules the `flatpak-update.service` for regular Flatpak updates.
    - `rsync_sync.timer`: Schedules the `rsync_sync.service` for periodic data synchronization.
- **Target Dependencies (`.target.wants/` directories)**:
    - `default.target.wants/`: Contains symlinks to services that should be started when the user's `default.target` is reached (e.g., `lmstudio.service`, `onedriver@home-lorenzo-.OneDriveUnipi.service`).
    - `graphical-session.target.wants/`: Contains symlinks to services that should be started when a graphical session is active (e.g., `sunshine.service`).
    - `timers.target.wants/`: Contains symlinks to timers that should be activated when the `timers.target` is reached.

## Guidelines:
- **Deployment**: These unit files are typically placed in `~/.config/systemd/user/` (or symlinked from this dotfiles repository to that location) for Systemd to manage them.
- **Permissions**: Ensure unit files have appropriate read permissions for the user.
- **Reloading Systemd**: After modifying or adding new user unit files, reload the Systemd user daemon by running `systemctl --user daemon-reload`.
- **Controlling Units**:
    - To enable a service/timer to start automatically: `systemctl --user enable <unit_name>`
    - To disable: `systemctl --user disable <unit_name>`
    - To start immediately: `systemctl --user start <unit_name>`
    - To stop immediately: `systemctl --user stop <unit_name>`
- **Checking Status and Logs**:
    - To check the status of a unit: `systemctl --user status <unit_name>`
    - To view logs for a unit: `journalctl --user -u <unit_name>`
- **Dependencies**: Be aware of any external dependencies (e.g., specific applications, network connectivity) that a service or timer might require to function correctly.
