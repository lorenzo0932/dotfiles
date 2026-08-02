#! /bin/bash
# Installa la configurazione MPV (specchiata da ~/.config/mpv in configs/mpv/ del repo)
# nella directory di config scelta (nativa o flatpak).
# Usa -u: non sovrascrive mai file live piu' recenti.

echo "Quale versione di mpv hai installato?"
select mpv_version in "Nativa" "Flatpak"; do
    case $mpv_version in
        Nativa )
            MPV_CONFIG_DIR="$HOME/.config/mpv"
            break
            ;;
        Flatpak )
            MPV_CONFIG_DIR="$HOME/.var/app/io.mpv.Mpv/config/mpv" #da verificare il path della versione flatpak
            break
            ;;
        * ) echo "Scelta non valida.";;
    esac
done

# Crea la directory di configurazione di mpv se non esiste
mkdir -p "$MPV_CONFIG_DIR"

# Copia il CONTENUTO di configs/mpv (la config sincronizzata con quella reale in uso)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -ru "$SCRIPT_DIR/../configs/mpv/." "$MPV_CONFIG_DIR"
