#! /bin/bash

echo "Quale versione di mpv hai installato?"
select mpv_version in "Nativa" "Flatpak"; do
    case $mpv_version in
        Nativa )
            MPV_CONFIG_DIR="$HOME/.config/mpv"
            break
            ;;
        Flatpak )
            MPV_CONFIG_DIR="$HOME/.var/app/io.mpv.Mpv" #da verificare il path della versione flatpak
            break
            ;;
        * ) echo "Scelta non valida.";;
    esac
done

# Crea la directory di configurazione di mpv se non esiste
mkdir -p "$MPV_CONFIG_DIR"

cp -r ../myScript/mpv*  "$MPV_CONFIG_DIR"
