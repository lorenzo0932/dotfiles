#!/bin/bash
# Esporta l'elenco delle estensioni GNOME Shell attive e le loro impostazioni
# in modo che possano essere ripristinate con RestoreGnomeExtensions.sh.
# Non interattivo: pensato per essere eseguito dal servizio rsync (ExecStartPre).

set -euo pipefail

DEST="$HOME/.local/share/myScript/ExportGnomeExtensions"
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"

mkdir -p "$DEST"

# Elenco UUID delle estensioni attive (formato pronto per gsettings: ['uuid', ...])
gsettings get org.gnome.shell enabled-extensions > "$DEST/enabled-extensions.list"

# Impostazioni di tutte le estensioni (dconf)
dconf dump /org/gnome/shell/extensions/ > "$DEST/extensions-settings.conf"

echo "Estensioni esportate in $DEST:"
echo "  - $(wc -l < "$DEST/enabled-extensions.list") righe di UUID attive"
echo "  - $(wc -l < "$DEST/extensions-settings.conf") righe di impostazioni"
