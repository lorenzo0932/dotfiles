#! /bin/bash
# Copia gli script Nautilus in ~/.local/share/nautilus/scripts/.
# Usa -u: non sovrascrive mai file live piu' recenti.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.local/share/nautilus/scripts"
cp -ru "$SCRIPT_DIR/../nautilus/scripts/." "$HOME/.local/share/nautilus/scripts/"
chmod -R +x "$HOME/.local/share/nautilus/scripts/"
