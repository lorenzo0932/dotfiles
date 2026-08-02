#!/bin/bash

# --- Configuration ---
# Define your source directories (modify paths as needed)
MYSCRIPTS="/home/lorenzo/.local/share/myScript"
NAUTILUS_SCRIPTS="/home/lorenzo/.local/share/nautilus"
SYSTEMD_SERVICES="/home/lorenzo/.config/systemd"
MPV_CONFIG="$HOME/.config/mpv"

# Define your destination directory (your dotfiles repo folder)
DEST="/home/lorenzo/Documenti/GitHub/dotfiles"

# --- Sync Files with rsync ---
echo "Sincronizzazione dei file dotfiles (senza commit)..."
rsync -au --delete --exclude-from='exclude.txt' "$MYSCRIPTS/" "$DEST/myScript/"
rsync -au --delete --exclude-from='exclude.txt' "$NAUTILUS_SCRIPTS/" "$DEST/nautilus/"
rsync -au --delete --exclude-from='exclude.txt' "$SYSTEMD_SERVICES/" "$DEST/systemd/"
# Config MPV reale: ~/.config/mpv e' la fonte di verita' (watch_later e bak/cache sono transienti e vanno esclusi)
rsync -a --delete --exclude='watch_later/' --exclude='bak/cache/' "$MPV_CONFIG/" "$DEST/configs/mpv/"
echo "Sincronizzazione completata. Nessun commit eseguito (usa rSync.sh per committare e pushare)."
