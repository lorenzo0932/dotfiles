#!/bin/bash

gnome-monitor-config set -LpM  HDMI-1 -t normal -m 1920x1080@59.934 -s 1.73913
gnome-extensions disable Vitals@CoreCoding.com
gnome-extensions disable appindicatorsupport@rgcjonas.gmail.com
gnome-extensions disable tiling-assistant@leleat-on-github
gsettings set org.gnome.desktop.interface text-scaling-factor 1.00
# gsettings set org.gnome.desktop.interface text-scaling-factor 0.85            
# flatpak run com.github.iwalton3.jellyfin-media-player; 
