#! /bin/bash
# Installa le dipendenze di sistema per l'ambilight e per il sync della
# tastiera Drevo Tyrfing V2. Idempotente: gira anche su sistema gia' pronto.
# Richiede sudo (dnf, udev rule). Funziona da clone fresco (path risolti
# rispetto allo script).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Pacchetti dnf (ambilight + tastiera)"
sudo dnf install -y python3-numpy python3-gobject-base gstreamer1 \
    gstreamer1-plugins-base pipewire-gstreamer mosquitto hidapi

echo "==> Venv dtv2 (~/.local/venvs/dtv2, riusa il modulo hid di sistema)"
VENV="$HOME/.local/venvs/dtv2"
python3 -m venv --system-site-packages "$VENV"
"$VENV/bin/pip" install --no-deps dtv2

echo "==> Udev rule tastiera Drevo Tyrfing V2"
RULE_SRC="$SCRIPT_DIR/../myScript/udev/99-drevo-tyrfing.rules"
if [ -f "$RULE_SRC" ]; then
    sudo cp "$RULE_SRC" /etc/udev/rules.d/99-drevo-tyrfing.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo "Regola installata: /etc/udev/rules.d/99-drevo-tyrfing.rules"
else
    echo "ATTENZIONE: $RULE_SRC non trovata, regola udev NON installata."
fi

echo "==> Verifica"
python3 -c "import numpy, gi; print('deps ambilight: ok')"
"$VENV/bin/python" -c "from dtv2 import dtv2; print('dtv2: ok')"

echo "Installazione dipendenze completata."
