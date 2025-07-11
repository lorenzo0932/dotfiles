#!/bin/bash

#killall jellyfinmediaplayer;
#killall kodi;
gnome-monitor-config set -LpM  DP-1 -t normal -m 2560x1080@74.991+vrr -s 1
gnome-extensions enable Vitals@CoreCoding.com
gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
gnome-extensions enable tiling-assistant@leleat-on-github
gsettings set org.gnome.desktop.interface text-scaling-factor 0.90   
