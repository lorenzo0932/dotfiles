#! /bin/bash
# Installa la configurazione opencode (config unica multi-macchina, specchiata
# da ~/.config/opencode in configs/opencode/ del repo) in ~/.config/opencode.
# Usa -u: non sovrascrive mai file live piu' recenti.
# NB: opencode va riavviato dopo l'installazione per caricare la nuova config.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/.config/opencode"
mkdir -p "$DEST_DIR" "$DEST_DIR/commands"
cp -ru "$SCRIPT_DIR/../configs/opencode/." "$DEST_DIR"
echo "Config opencode installata in $DEST_DIR (riavvia opencode per applicarla)."
