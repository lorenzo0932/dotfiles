#!/bin/bash
# Esporta l'elenco delle estensioni GNOME Shell attive, le loro impostazioni
# e l'estensione custom fullscreen-command@lorenzo0932 (non presente su EGO)
# in modo che possano essere ripristinate con RestoreGnomeExtensions.sh.
# Non interattivo: pensato per essere eseguito dal servizio rsync (ExecStartPre).

set -euo pipefail

DEST="$HOME/.local/share/myScript/ExportGnomeExtensions"
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
CUSTOM_EXT="fullscreen-command@lorenzo0932"

mkdir -p "$DEST"

# Elenco UUID delle estensioni attive (formato pronto per gsettings: ['uuid', ...])
gsettings get org.gnome.shell enabled-extensions > "$DEST/enabled-extensions.list"

# Impostazioni di tutte le estensioni (dconf)
dconf dump /org/gnome/shell/extensions/ > "$DEST/extensions-settings.conf"

# Copia dell'estensione custom (files + gschemas.compiled): le estensioni da
# EGO si reinstalano con RestoreGnomeExtensions.sh, questa solo da qui.
if [ -d "$EXTENSIONS_DIR/$CUSTOM_EXT" ]; then
    rsync -a --delete "$EXTENSIONS_DIR/$CUSTOM_EXT/" "$DEST/$CUSTOM_EXT/"
    echo "Estensione custom $CUSTOM_EXT esportata."
else
    echo "ATTENZIONE: estensione custom $CUSTOM_EXT non trovata in $EXTENSIONS_DIR"
fi

echo "Estensioni esportate in $DEST:"
echo "  - $(wc -l < "$DEST/enabled-extensions.list") righe di UUID attive"
echo "  - $(wc -l < "$DEST/extensions-settings.conf") righe di impostazioni"
