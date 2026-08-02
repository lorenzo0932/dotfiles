#! /bin/bash
# Installa la configurazione di Feral GameMode (specchiata da ~/.config/gamemode.ini
# in configs/gamemode.ini del repo, per riferimento/restore).
# Usa -u: non sovrascrive mai file live piu' recenti.
# Richiede: GameMode installato (gamemode, gamemoded) e gli hook ambilight
# in myScript/GameMode/ambilight.sh (installati da installScripts.sh).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$HOME/.config" ]; then
    mkdir -p "$HOME/.config"
fi

cp -u "$SCRIPT_DIR/../configs/gamemode.ini" "$HOME/.config/gamemode.ini"
echo "gamemode.ini installato in $HOME/.config/gamemode.ini"
