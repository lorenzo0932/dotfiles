#!/bin/bash

echo "Scegli l'operazione:"
echo "1) Esporta configurazioni"
echo "2) Carica configurazioni"
read -p "Inserisci 1 o 2: " scelta

case "$scelta" in
    1) # Esporta configurazioni
        echo "Scegli cosa esportare:"
        echo "1) Tutte le scorciatoie (Custom, Media e Window Manager)"
        echo "2) Solo scorciatoie Custom"
        echo "3) Solo scorciatoie Media (Non Custom)"
        echo "4) Solo scorciatoie Window Manager (Non Custom)"
        read -p "Inserisci 1, 2, 3 o 4: " export_choice

        case "$export_choice" in
            1) # Esporta Tutte
                echo "Esportazione di tutte le configurazioni..."
                dconf dump /org/gnome/settings-daemon/plugins/media-keys/ > ./custom-and-media-keybindings.conf
                dconf dump /org/gnome/desktop/wm/keybindings/ > ./gnome-shell-keybindings.conf
                if [ $? -eq 0 ]; then
                    echo "Configurazioni Media e Custom esportate in $(pwd)/custom-and-media-keybindings.conf"
                    echo "Configurazioni Window Manager esportate in $(pwd)/gnome-shell-keybindings.conf"
                else
                    echo "Si è verificato un errore durante l'esportazione di tutte le configurazioni."
                fi
                ;;
            2) # Esporta solo Custom
                echo "Esportazione delle configurazioni Custom..."
                dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ > ./custom-keybindings.conf
                gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings > ./custom-keybindings-string.txt
                if [ $? -eq 0 ]; then
                    echo "Configurazioni Custom esportate in $(pwd)/custom-keybindings.conf e in $(pwd)/custom-keybindings-string.txt"
                else
                    echo "Si è verificato un errore durante l'esportazione delle configurazioni Custom."
                fi
                ;;
            3) # Esporta solo Media (Non Custom)
                echo "Esportazione delle configurazioni Media (Non Custom)..."
                dconf dump /org/gnome/settings-daemon/plugins/media-keys/ | grep -v "custom-keybindings" > ./media-keybindings.conf
                if [ $? -eq 0 ]; then
                    echo "Configurazioni Media (Non Custom) esportate in $(pwd)/media-keybindings.conf"
                else
                    echo "Si è verificato un errore durante l'esportazione delle configurazioni Media (Non Custom)."
                fi
                ;;
            4) # Esporta solo Window Manager (Non Custom)
                echo "Esportazione delle configurazioni Window Manager (Non Custom)..."
                dconf dump /org/gnome/desktop/wm/keybindings/ > ./gnome-shell-keybindings.conf
                if [ $? -eq 0 ]; then
                    echo "Configurazioni Window Manager (Non Custom) esportate in $(pwd)/gnome-shell-keybindings.conf"
                else
                    echo "Si è verificato un errore durante l'esportazione delle configurazioni Window Manager (Non Custom)."
                fi
                ;;
            *)
                echo "Opzione non valida. Uscita."
                exit 1
                ;;
        esac
        ;;
    2) # Carica configurazioni
        echo "Scegli cosa caricare:"
        echo "1) Tutte le scorciatoie (da custom-and-media-keybindings.conf e gnome-shell-keybindings.conf)"
        echo "2) Solo scorciatoie Custom (da custom-keybindings.conf)"
        echo "3) Solo scorciatoie Media (Non Custom) (da media-keybindings.conf)"
        echo "4) Solo scorciatoie Window Manager (Non Custom) (da gnome-shell-keybindings.conf)"
        read -p "Inserisci 1, 2, 3 o 4: " import_choice

        case "$import_choice" in
            1) # Carica Tutte
                file_media_custom="./custom-and-media-keybindings.conf"
                file_wm="./gnome-shell-keybindings.conf"
                if [ -f "$file_media_custom" ] && [ -f "$file_wm" ]; then
                    echo "Caricamento di tutte le configurazioni..."
                    dconf load /org/gnome/settings-daemon/plugins/media-keys/ < "$file_media_custom"
                    dconf load /org/gnome/desktop/wm/keybindings/ < "$file_wm"
                    if [ $? -eq 0 ]; then
                        echo "Tutte le configurazioni caricate correttamente."
                    else
                        echo "Si è verificato un errore durante il caricamento di tutte le configurazioni."
                    fi
                else
                    echo "Uno o entrambi i file di configurazione non esistono. Operazione annullata."
                    exit 1
                fi
                ;;
            2) # Carica solo Custom
                file_config="./custom-keybindings.conf"
                file_config2=$(<custom-keybindings-string.txt)
                if [ -f "$file_config" ]; then
                    echo "Caricamento delle configurazioni Custom da $file_config..."
                    dconf load /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ < "$file_config"
                    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$file_config2"
                    if [ $? -eq 0 ]; then
                        echo "Configurazioni Custom caricate correttamente."
                    else
                        echo "Si è verificato un errore durante il caricamento delle configurazioni Custom."
                    fi
                else
                    echo "Il file $file_config non esiste. Operazione annullata."
                    exit 1
                fi
                ;;
            3) # Carica solo Media (Non Custom)
                file_config="./media-keybindings.conf"
                if [ -f "$file_config" ]; then
                    echo "Caricamento delle configurazioni Media (Non Custom) da $file_config..."
                    dconf load /org/gnome/settings-daemon/plugins/media-keys/ < "$file_config"
                    if [ $? -eq 0 ]; then
                        echo "Configurazioni Media (Non Custom) caricate correttamente."
                    else
                        echo "Si è verificato un errore durante il caricamento delle configurazioni Media (Non Custom)."
                    fi
                else
                    echo "Il file $file_config non esiste. Operazione annullata."
                    exit 1
                fi
                ;;
            4) # Carica solo Window Manager (Non Custom)
                file_config="./gnome-shell-keybindings.conf"
                if [ -f "$file_config" ]; then
                    echo "Caricamento delle configurazioni Window Manager (Non Custom) da $file_config..."
                    dconf load /org/gnome/desktop/wm/keybindings/ < "$file_config"
                    if [ $? -eq 0 ]; then
                        echo "Configurazioni Window Manager (Non Custom) caricate correttamente."
                    else
                        echo "Si è verificato un errore durante il caricamento delle configurazioni Window Manager (Non Custom)."
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
        ;;
    *)
        echo "Opzione non valida. Uscita."
        exit 1
        ;;
esac
