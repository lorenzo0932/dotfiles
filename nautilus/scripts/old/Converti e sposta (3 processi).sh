#!/bin/bash
# Converti e sposta.sh (v18 - Smart Segment Production)
# Motore: Smart Segmenter (Taglio su Keyframe = No frame duplicati)
# Logica: Struttura originale v5/v17 (Retries, Log, Zenity).

START_TIME=$(date +%s)
IFS=$'\n'
fail_list=""
MAX_RETRIES=1 

# --- CONFIGURAZIONE ---
CONVERT_TARGET_DIR="/home/lorenzo/Video/Convertiti"
NUM_CHUNKS=3
RAM_THRESHOLD=50 
# --- FINE CONFIGURAZIONE ---

mkdir -p "$CONVERT_TARGET_DIR"

if [ ! -d "$CONVERT_TARGET_DIR" ] || [ ! -w "$CONVERT_TARGET_DIR" ]; then
    zenity --error --text="Errore accesso directory output:\n$CONVERT_TARGET_DIR" --width=400
    exit 1
fi

log_msg() { echo "$@" >&2; }

get_ram_usage() {
    free | awk '/Mem/{printf("%.0f"), (($2-$7)/$2)*100}'
}

cleanup_trap() {
    rm -rf "/dev/shm/splitter_job_$$" 2>/dev/null
    rm -rf "/var/tmp/splitter_job_$$" 2>/dev/null
}
trap cleanup_trap EXIT

for i in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS; do
    if [ ! -f "$i" ]; then continue; fi

    original_path="$i"
    base_name=$(basename "$i")
    failure_log="$CONVERT_TARGET_DIR/${base_name}.log"

    attempt=0
    success=false
    rm -f "$failure_log" 

    while [ $attempt -le $MAX_RETRIES ]; do
        current_attempt=$((attempt + 1))
        
        ram_usage=$(get_ram_usage)
        if [ "$ram_usage" -lt "$RAM_THRESHOLD" ]; then
            WORK_ROOT="/dev/shm/splitter_job_$$"
            STORAGE_MODE="RAM"
        else
            WORK_ROOT="/var/tmp/splitter_job_$$"
            STORAGE_MODE="DISK"
        fi
        
        current_work_dir="$WORK_ROOT/$(date +%s%N)"
        mkdir -p "$current_work_dir"
        intermediate_output="$current_work_dir/merged.mp4"

        # --- MOTORE DI CONVERSIONE SMART SEGMENT ---
        (
            # A. Ottieni Durata
            duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$original_path")
            if [ -z "$duration" ]; then exit 1; fi
            
            # Calcolo durata teorica dei segmenti
            segment_time=$(awk "BEGIN {print $duration / $NUM_CHUNKS}")
            
            # B. Segmentazione Fisica (Copia senza ricodifica, taglia sui Keyframe)
            # Questo crea src_000.mp4, src_001.mp4, etc. senza duplicare frame
            ffmpeg -y -i "$original_path" -c copy -map 0 -f segment -segment_time "$segment_time" -reset_timestamps 1 "$current_work_dir/src_%03d.mp4" >/dev/null 2>&1 || exit 1

            # C. Encoding Parallelo dei segmenti generati
            source_segments=($(ls "$current_work_dir"/src_*.mp4))
            pids=()
            for (( j=0; j<${#source_segments[@]}; j++ )); do
                src_part="${source_segments[$j]}"
                out_part="$current_work_dir/enc_$j.mp4"
                
                (
                    ffmpeg -y -i "$src_part" \
                    -c:v libx265 -crf 23 -preset veryfast -x265-params "hist-scenecut=1" \
                    -c:a copy \
                    "$out_part" >/dev/null 2>&1
                ) &
                pids+=($!)
            done
            
            # Attesa fine processi
            for pid in "${pids[@]}"; do wait $pid || exit 1; done
            
            # D. Unione (Concat)
            concat_list="$current_work_dir/list.txt"
            for (( j=0; j<${#source_segments[@]}; j++ )); do
                echo "file '$current_work_dir/enc_$j.mp4'" >> "$concat_list"
            done
            
            ffmpeg -y -f concat -safe 0 -i "$concat_list" -c copy "$intermediate_output" >/dev/null 2>&1 || exit 1
        )
        
        conv_exit_code=$?
        
        if [ $conv_exit_code -ne 0 ]; then
            log_msg "ERROR: Conversione fallita '$base_name' (Tentativo $current_attempt)."
            echo "ERRORE CONVERSIONE (Tentativo $current_attempt): Fallito durante lo splitting o encoding." > "$failure_log"
            rm -rf "$current_work_dir"
        else
            # --- VERIFICA INTEGRITÀ ---
            if ! ffmpeg -v error -i "$intermediate_output" -f null - 2>"$failure_log" || [ -s "$failure_log" ]; then
                if grep -q -E "Error|Invalid|Corrupt" "$failure_log"; then
                    log_msg "ERROR: Verifica fallita '$base_name'."
                    rm -rf "$current_work_dir"
                else
                    # Se sono solo warning, procediamo
                    rm -f "$failure_log"
                    if ! mv -f "$intermediate_output" "$original_path"; then
                        echo "ERRORE SPOSTAMENTO" > "$failure_log"
                        rm -rf "$current_work_dir"
                    else
                        success=true
                        rm -rf "$current_work_dir"
                        break 
                    fi
                fi
            else
                 if ! mv -f "$intermediate_output" "$original_path"; then
                    echo "ERRORE SPOSTAMENTO" > "$failure_log"
                    rm -rf "$current_work_dir"
                 else
                    success=true
                    rm -f "$failure_log"
                    rm -rf "$current_work_dir"
                    break
                 fi
            fi
        fi

        attempt=$((attempt + 1))
        if [ "$success" = false ] && [ $attempt -le $MAX_RETRIES ]; then
             sleep 3
        fi
    done 

    if [ "$success" = false ]; then
        fail_list="${fail_list}\n${base_name}"
    fi
done 

cleanup_trap
END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME-START_TIME))

if [ -n "$fail_list" ]; then
    fail_list=$(echo -e "$fail_list" | sed '/^$/d')
    zenity --error --title="Errore" --text="Finito in $ELAPSED_TIME sec.\nFalliti:\n$fail_list" --width=450
else
    zenity --info --title="Completato" --text="Operazione completata in $ELAPSED_TIME secondi." --width=400
fi

exit 0