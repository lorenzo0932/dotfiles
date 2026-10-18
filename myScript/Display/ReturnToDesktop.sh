#!/bin/bash
# Switch back to desktop monitor (DP-1). Keep GNOME extensions enabled:
# toggling them during display changes causes teardown races.
exec 9>/tmp/display-switch.lock
flock -n 9 || exit 0

GMC=/home/lorenzo/.local/bin/gnome-monitor-config

#killall jellyfinmediaplayer;
#killall kodi;
"$GMC" set -LpM DP-1 -t normal -m 2560x1080@74.991+vrr -s 1
gsettings set org.gnome.desktop.interface text-scaling-factor 0.90
