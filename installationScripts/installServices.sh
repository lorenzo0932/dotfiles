#! /bin/bash
# Installa le unit systemd user nel path corretto e abilita quelle in uso.

set -e

# Gli script devono essere installati prima (i servizi li referenziano)
./installScripts.sh

USER_SERVICES_LOCATION="$HOME/.config/systemd/user"
mkdir -p "$USER_SERVICES_LOCATION"

# Copio le unit (service e timer) nella location corretta
cp -r ../systemd/user/*.service ../systemd/user/*.timer "$USER_SERVICES_LOCATION"/

systemctl --user daemon-reload

# Abilito i servizi e i timer effettivamente in uso
systemctl --user enable --now anidownloader-check.timer anidownloaderd.service flatpak-update.timer invia-watt.timer rsync_sync.timer
systemctl --user enable sunshine.service xbox-monitor.service

echo "Installazione dei servizi completata."
