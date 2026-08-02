#! /bin/bash
# Copia tutti gli script del progetto in ~/.local/share/myScript.
# Usa -u: non sovrascrive mai file live piu' recenti (la macchina live e' la fonte di verita').
# NON modifica il PATH (i comandi usano path assoluti in keybinding/unit systemd).

SCRIPT_FOLDER="$HOME/.local/share/myScript"
mkdir -p "$SCRIPT_FOLDER"
cp -ru ../myScript/. "$SCRIPT_FOLDER"/

echo "Installazione degli script completata."
