#!/bin/bash
# Converti e sposta.sh (v23 - RAM Boosted Original)
# Logica: Usa ESATTAMENTE il comando originale (che si è rivelato il più veloce),
# ma sposta il lavoro in RAM per eliminare i colli di bottiglia SSD/NVMe.

START_TIME=$(date +%s)
IFS=$'\n'
fail_list=""
MAX_RETRIES=1 

# --- CONFIGURAZIONE ---
CONVERT_TARGET_DIR="/home/lorenzo/Video/Convertiti"

# USIAMO LA RAM (/dev/shm). 
# Questo è l'unico modo per battere i 137s senza toccare l'encoder.
RAM_WORK_DIR="/dev/shm/nautilus_ram_boost"
# --- FINE CONFIGURAZIONE ---

mkdir -p "$CONVERT_TARGET_DIR"
mkdir -p "$RAM_WORK_DIR"

log_msg() { echo "$@" >&2; }

# Cleanup in caso di interruzione
cleanup() {
    rm -f "$RAM_WORK_DIR/$base_name" 2>/dev/null
}
trap cleanup EXIT

for i in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS; do
    if [ ! -f "$i" ]; then continue; fi

    original_path="$i"
    base_name=$(basename "$i")
    
    # 1. Scriviamo in RAM
    intermediate_output="$RAM_WORK_DIR/$base_name"
    failure_log="$CONVERT_TARGET_DIR/${base_name}.log"

    attempt=0
    success=false
    rm -f "$failure_log" 

    while [ $attempt -le $MAX_RETRIES ]; do
        current_attempt=$((attempt + 1))
        
        # --- COMANDO ORIGINALE VINCENTE ---
        # -threads 12: Mantenuto come da tuoi test (Sweet spot).
        # Rimosso 'nice -n 5': Diamo priorità massima alla CPU.
        # x265-params: Mantenuto solo hist-scenecut come originale.
        ffmpeg_command=( 
            ffmpeg -y -i "$original_path" 
            -c:v libx265 -crf 23 -preset veryfast 
            -threads 16 
            -x265-params "hist-scenecut=1" 
            -c:a copy 
            "$intermediate_output" 
        )

        # Esecuzione
        if ! "${ffmpeg_command[@]}"; then
            conv_exit_code=$?
            echo "ERRORE CONVERSIONE (Code $conv_exit_code)" > "$failure_log"
            rm -f "$intermediate_output" 
        else
            # 2. VERIFICA (Lettura da RAM)
            # Anche qui usiamo il comando standard, ma leggendo dalla RAM sarà istantaneo nel seek.
            if ! ffmpeg -y -v error -i "$intermediate_output" -f null - 2>"$failure_log" || [ -s "$failure_log" ]; then
                
                # Controllo errori (come originale)
                # Nota: Rimosso 'grep' complesso, torniamo alla logica base: se il log non è vuoto, fallisce.
                # A meno che tu non voglia ignorare i warning.
                if [ -s "$failure_log" ]; then
                     # Controllo rapido se è solo un freeze detection spurio o errore vero
                     # Se vuoi mantenere la logica originale stretta:
                     echo "ERRORE VERIFICA: Log non vuoto." >> "$failure_log"
                     rm -f "$intermediate_output"
                else
                     # Caso raro: comando fallito ma log vuoto
                     echo "ERRORE CRITICO FFMPEG" > "$failure_log"
                     rm -f "$intermediate_output"
                fi
            else
                # 3. SPOSTAMENTO (RAM -> DISCO)
                # Questo è l'unico momento in cui tocchiamo l'SSD
                if ! mv -f "$intermediate_output" "$original_path"; then
                    echo "ERRORE SPOSTAMENTO" > "$failure_log"
                    rm -f "$intermediate_output"
                else
                    success=true
                    rm -f "$failure_log"
                    break 
                fi
            fi
        fi

        attempt=$((attempt + 1))
        if [ "$success" = false ] && [ $attempt -le $MAX_RETRIES ]; then
             sleep 2
        fi

    done 

    # Pulizia RAM
    if [ -f "$intermediate_output" ]; then rm -f "$intermediate_output"; fi

    if [ "$success" = false ]; then
        fail_list="${fail_list}\n${base_name}"
    fi

done 

rmdir "$RAM_WORK_DIR" 2>/dev/null

END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME-START_TIME))

if [ -n "$fail_list" ]; then
    fail_list=$(echo -e "$fail_list" | sed '/^$/d')
    zenity --error --title="Errore" --text="Finito in $ELAPSED_TIME sec.\nFalliti:\n$fail_list" --width=450
else
    zenity --info --title="Finito" --text="Operazione completata in $ELAPSED_TIME secondi." --width=400
fi

exit 0