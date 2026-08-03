#! /bin/bash
# Niente piu' hook gamemode per l'ambilight: il trigger e' l'estensione GNOME
# fullscreen-command (start/stop dei servizi ambilight.service /
# ambilight-immersive.service). Questo installer rimuove la vecchia
# configurazione gamemode.ini (che conteneva solo i [custom] start/end) per
# migrare installazioni precedenti.

if [ -f "$HOME/.config/gamemode.ini" ]; then
    rm -f "$HOME/.config/gamemode.ini"
    echo "Rimossa la vecchia ~/.config/gamemode.ini (hook ambilight non piu' usati)."
else
    echo "Nessuna ~/.config/gamemode.ini da rimuovere."
fi
