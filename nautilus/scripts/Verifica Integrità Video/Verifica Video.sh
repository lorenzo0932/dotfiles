#!/bin/bash
# Verifica Turbo (v28 - Multi-Chunk Parallel)
# Logica: Divide il singolo file in N parti e le verifica contemporaneamente.
# Vantaggio: Satura I/O e CPU, riducendo drasticamente il tempo di verifica su file grandi.

START_TIME=$(date +%s)
IFS=$'\n'

# --- CONFIGURAZIONE ---
# 16 è il numero ideale per il 5950X (1 processo per Core Fisico)
NUM_CHUNKS=16
LOG_DIR="$HOME/Video/Verifica_Logs"
# Cartella temporanea in RAM per i log dei chunk
TEMP_BASE="/dev/shm/verify_chunks_$$"
# --- FINE CONFIGURAZIONE ---

mkdir -p "$LOG_DIR"

log_msg() { echo "$@"; }

# Funzione che pulisce la RAM alla fine
cleanup() {
    rm -rf "$TEMP_BASE" 2>/dev/null
}
trap cleanup EXIT

# Contatori globali
total_files=0
corrupt_files=0
corrupt_list=""

for i in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS; do
    if [ ! -f "$i" ]; then continue; fi
    
    total_files=$((total_files + 1))
    original_path="$i"
    base_name=$(basename "$i")
    
    # Creiamo cartella di lavoro per questo file specifico
    current_work_dir="$TEMP_BASE/$(date +%s%N)"
    mkdir -p "$current_work_dir"
    
    echo "Analisi: $base_name..."
    
    # 1. OTTENIAMO DURATA
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$original_path")
    
    if [ -z "$duration" ]; then
        echo "❌ Errore critico: Impossibile leggere il file (Header corrotto?)"
        corrupt_files=$((corrupt_files + 1))
        corrupt_list="${corrupt_list}\n${base_name} (Header illeggibile)"
        continue
    fi

    # Calcolo durata chunk (con awk per virgola mobile)
    chunk_len=$(awk "BEGIN {print $duration / $NUM_CHUNKS}")
    
    # 2. LANCIO VERIFICA PARALLELA
    pids=()
    for (( j=0; j<NUM_CHUNKS; j++ )); do
        start_time=$(awk "BEGIN {print $j * $chunk_len}")
        # Aggiungiamo 5 secondi di overlap per sicurezza (evitare buchi tra keyframe)
        duration_chunk=$(awk "BEGIN {print $chunk_len + 5}")
        
        chunk_log="$current_work_dir/chunk_$j.log"
        
        # Comando: Seek veloce (-ss prima di -i) -> Legge solo quel pezzo -> Scarta output
        # Modificato aggiungendo -nostdin per i processi in background e -xerror per isolare gli errori reali
        (
            ffmpeg -nostdin -ss "$start_time" -t "$duration_chunk" -v error -xerror -i "$original_path" -f null - >/dev/null 2>"$chunk_log"
        ) &
        
        pids+=($!)
    done
    
    # 3. ATTESA FINE PROCESSI E CONTROLLO ERRORI REALI
    # Analizziamo l'exit status reale di ciascuno dei 16 processi in background.
    # Se anche uno solo fallisce (ritorna diverso da 0), consideriamo il file danneggiato.
    file_is_bad=false
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            file_is_bad=true
        fi
    done
    
    # 4. AGGREGAZIONE RISULTATI E SALVATAGGIO DEI LOG
    if [ "$file_is_bad" = true ]; then
        corrupt_files=$((corrupt_files + 1))
        corrupt_list="${corrupt_list}\n${base_name}"
        
        # Concateniamo e salviamo i log d'errore solo in caso di fallimento effettivo
        full_error_log="$LOG_DIR/${base_name}.log"
        cat "$current_work_dir"/chunk_*.log > "$full_error_log"
        echo "❌ DANNEGGIATO"
    else
        echo "✅ SANO"
    fi

    # Pulizia RAM per questo file
    rm -rf "$current_work_dir"
done

cleanup

END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME-START_TIME))

# --- NOTIFICA FINALE ---
if [ "$corrupt_files" -gt 0 ]; then
    zenity --warning --title "Verifica Completata (con Errori)" \
    --text "Tempo: $ELAPSED_TIME sec.\n\n⚠️ $corrupt_files FILE CORROTTI:\n$corrupt_list\n\nControlla: $LOG_DIR" --width=450
else
    zenity --info --title "Verifica Completata" \
    --text "Tutti i file sono SANI!\n\nTempo totale: $ELAPSED_TIME sec." --width=300
fi

exit 0