#!/bin/bash
# Verifica Turbo GPU (v28 - VAAPI Hardware Accelerated)
# Logica: Elaborazione sequenziale ad altissima velocità sfruttando i sensori della GPU.
# Ottimizzato per evitare la saturazione dei decoder hardware di RDNA 2.

START_TIME=$(date +%s)
IFS=$'\n'

LOG_DIR="$HOME/Video/Verifica_Logs"
mkdir -p "$LOG_DIR"

# Contatori globali
total_files=0
corrupt_files=0
corrupt_list=""

for i in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS; do
    if [ ! -f "$i" ]; then continue; fi
    
    total_files=$((total_files + 1))
    base_name=$(basename "$i")
    temp_log="/tmp/vaapi_verify_${RANDOM}_$$.log"
    
    echo "Sto verificando l'integrità di $base_name con accelerazione GPU..."
    
    # Eseguiamo la verifica con accelerazione hardware totale (frame in memoria GPU)
    # Aggiunti -nostdin e -xerror per una gestione impeccabile dei codici di errore ed evitare blocchi
    nice -n 5 ffmpeg -nostdin -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -hwaccel_output_format vaapi -v error -xerror -i "$i" -f null - >/dev/null 2>"$temp_log"
    
    if [ $? -ne 0 ]; then
        corrupt_files=$((corrupt_files + 1))
        corrupt_list="${corrupt_list}\n${base_name}"
        
        # Salviamo il log d'errore sul disco fisso SOLO se il file è realmente corrotto
        mv "$temp_log" "$LOG_DIR/${base_name}.log"
        echo "❌ DANNEGGIATO"
    else
        # Se il file è sano, eliminiamo il log temporaneo per tenere pulito il sistema
        rm -f "$temp_log"
        echo "✅ SANO"
    fi
done

END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME-START_TIME))

# --- NOTIFICA FINALE ---
if [ "$corrupt_files" -gt 0 ]; then
    zenity --warning --title "Verifica GPU Completata (con Errori)" \
    --text "Tempo: $ELAPSED_TIME sec.\n\n⚠️ $corrupt_files FILE CORROTTI:\n$corrupt_list\n\nControlla i log in: $LOG_DIR" --width=450
else
    zenity --info --title "Verifica GPU Completata" \
    --text "Tutti i file sono SANI!\n\nTempo totale: $ELAPSED_TIME sec." --width=300
fi

exit 0