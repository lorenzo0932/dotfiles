#!/bin/bash
# Installa e configura input-remapper con il preset versionato in questa cartella.
# Uso: ripristino da zero (dotfiles) oppure reinstallazione pulita.
# Il preset rimappa i tasti laterali del mouse in Alt+Freccia (workaround per il
# doppio-step di navigazione di Jellyfin Desktop 2.0.0, che gestisce due volte
# l'evento grezzo del pulsante).
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Pacchetto + demone di sistema (gira come root, intercetta gli eventi evdev)
if ! rpm -q input-remapper >/dev/null 2>&1; then
    sudo dnf install -y input-remapper
fi
sudo systemctl enable --now input-remapper.service

# 2. Preset + config (con autoload) dalla copia versionata
mkdir -p "$HOME/.config/input-remapper-2/presets"
cp -r "$SCRIPT_DIR/presets/." "$HOME/.config/input-remapper-2/presets/"
cp -a "$SCRIPT_DIR/config.json" "$HOME/.config/input-remapper-2/config.json"

# 3. Avvia l'iniezione (il preset deve esistere prima di questo passo)
input-remapper-control --config-dir "$HOME/.config/input-remapper-2" \
    --command start --device "Logitech G305" --preset jellyfin-back-fix

echo "OK: iniezione avviata. Verifica con i tasti laterali del mouse."
