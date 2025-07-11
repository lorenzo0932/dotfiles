#!/bin/bash

echo "Scegli l'operazione:"
echo "1) Esporta configurazioni"
echo "2) Carica configurazioni"
read -p "Inserisci 1 o 2: " scelta

case "$scelta" in
    1)
        echo "Esportazione delle configurazioni..."
        dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ > ./custom-keybindings.conf
        gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings > ./custom-keybindings-string.txt
        if [ $? -eq 0 ]; then
            echo "Configurazioni esportate in $(pwd)/custom-keybindings.conf e in $(pwd)/custom-keybindings-string.txt" 
        else
            echo "Si è verificato un errore durante l'esportazione."
        fi
        ;;
    2)
        read -p "Inserisci il path del file di configurazione da caricare (default: ./custom-keybindings.conf): " file_config
        # Se l'utente non inserisce nulla, usa il file di default
        if [ -z "$file_config" ]; then
            file_config="./custom-keybindings.conf"
            file_config2=$(<custom-keybindings-string.txt)

        fi

        if [ -f "$file_config" ]; then
            echo "Caricamento delle configurazioni da $file_config..."
            dconf load /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ < "$file_config"
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$file_config2"
            if [ $? -eq 0 ]; then
                echo "Configurazioni caricate correttamente."
            else
                echo "Si è verificato un errore durante il caricamento."
            fi
        else
            echo "Il file $file_config non esiste. Operazione annullata."
            exit 1
        fi
        ;;
    *)
        echo "Opzione non valida. Uscita."
        exit 1
        ;;
esac
