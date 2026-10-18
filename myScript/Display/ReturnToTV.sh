#!/bin/bash
# Switch to TV (HDMI-1). Keep GNOME extensions enabled: toggling them here
# causes teardown races (notably AppIndicator and Tiling Assistant).
exec 9>/tmp/display-switch.lock
flock -n 9 || exit 0

GMC=/home/lorenzo/.local/bin/gnome-monitor-config
"$GMC" set -LpM HDMI-1 -t normal -m 1920x1080@59.934 -s 1.73913
gsettings set org.gnome.desktop.interface text-scaling-factor 1.00
# gsettings set org.gnome.desktop.interface text-scaling-factor 0.85
# flatpak run com.github.iwalton3.jellyfin-media-player;
