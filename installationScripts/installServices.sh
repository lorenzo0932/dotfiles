#! /bin/bash
# Installa le unit systemd user nel path corretto e abilita quelle in uso.
# Funziona da qualsiasi directory di lancio (path risolti rispetto allo script).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Gli script devono essere installati prima (i servizi li referenziano)
"$SCRIPT_DIR/installScripts.sh"

USER_SERVICES_LOCATION="$HOME/.config/systemd/user"
mkdir -p "$USER_SERVICES_LOCATION"

# Copio le unit (service e timer) nella location corretta
cp -r "$SCRIPT_DIR/../systemd/user/"*.service "$SCRIPT_DIR/../systemd/user/"*.timer "$USER_SERVICES_LOCATION"/

systemctl --user daemon-reload

# Abilito i servizi e i timer effettivamente in uso
systemctl --user enable --now anidownloader-check.timer anidownloaderd.service flatpak-update.timer invia-watt.timer rsync_sync.timer
systemctl --user enable sunshine.service xbox-monitor.service

echo "Installazione dei servizi completata."
