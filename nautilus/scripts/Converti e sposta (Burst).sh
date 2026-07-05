#!/bin/bash
# AniEngine Burst - (v18.5 - Ultra-Adaptive)

# Abilita il Job Control (monitor mode) per far funzionare correttamente il comando 'jobs'
# all'interno dell'ambiente non interattivo di Nautilus
set -m

# Forza lo standard internazionale per evitare il bug dei decimali (virgola vs punto)
export LC_NUMERIC=C
START_TIME=$(date +%s)
export IFS=$'\n'
SESSION_ID="$$"
FAIL_TICKET="/tmp/burst_failed_$SESSION_ID"

SELECTED_FILES=()
for f in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS; do [ -f "$f" ] && SELECTED_FILES+=("$f"); done
TOTAL_FILES=${#SELECTED_FILES[@]}

# --- LOGICA ADATTIVA AVANZATA (C++ v5.0 Porting) ---
TOTAL_CORES=$(nproc)
TARGET_THREADS=$(awk "BEGIN {print int($TOTAL_CORES * 0.85)}")
[ "$TARGET_THREADS" -lt 1 ] && TARGET_THREADS=1

if [ "$TARGET_THREADS" -lt 6 ]; then
    # Salvagente Low-End (PC piccoli)
    MAX_CONCURRENT=1
    NUM_CHUNKS=1
    THREADS_PER_CHUNK=$TARGET_THREADS
else
    # Limitatore di concorrenza per coerenza della cache (CCD) e I/O
    if [ "$TOTAL_CORES" -gt 128 ]; then
        MAX_ALLOWED_CONCURRENT=12 # Server giganti
    elif [ "$TOTAL_CORES" -gt 64 ]; then
        MAX_ALLOWED_CONCURRENT=6  # Workstation
    elif [ "$TOTAL_CORES" -gt 32 ]; then
        MAX_ALLOWED_CONCURRENT=4  # CPU Desktop high-end
    else
        MAX_ALLOWED_CONCURRENT=2  # PC standard
    fi

    if [ "$TOTAL_FILES" -le 1 ]; then
        # Un solo video in coda: concentriamo tutto lo splitting
        MAX_CONCURRENT=1
        NUM_CHUNKS=$(awk "BEGIN {c=int($TARGET_THREADS / 6); if(c<1)c=1; if(c>8)c=8; print c}")
    else
        # Più video in coda: calcolo curvo con radice quadrata
        IDEAL_CONCURRENT=$(awk "BEGIN {c=int(sqrt($TARGET_THREADS)); if(c<1)c=1; print c}")
        [ "$IDEAL_CONCURRENT" -gt "$MAX_ALLOWED_CONCURRENT" ] && IDEAL_CONCURRENT=$MAX_ALLOWED_CONCURRENT
        [ "$IDEAL_CONCURRENT" -gt "$TOTAL_FILES" ] && IDEAL_CONCURRENT=$TOTAL_FILES
        
        MAX_CONCURRENT=$IDEAL_CONCURRENT
        THREADS_PER_FILE=$(awk "BEGIN {print int($TARGET_THREADS / $MAX_CONCURRENT)}")
        NUM_CHUNKS=$(awk "BEGIN {c=int($THREADS_PER_FILE / 6); if(c<1)c=1; if(c>4)c=4; print c}")
    fi

    # Calcolo finale dei thread effettivi per chunk
    TOTAL_PROCESSES=$(( MAX_CONCURRENT * NUM_CHUNKS ))
    THREADS_PER_CHUNK=$(awk "BEGIN {t=int($TARGET_THREADS / $TOTAL_PROCESSES); if(t<1)t=1; print t}")
fi

# Protezione contro il blocco di x265 (Limite a 16 thread fisici per comando, eccedenti in pools)
FFMPEG_THREADS=$THREADS_PER_CHUNK
[ "$FFMPEG_THREADS" -gt 16 ] && FFMPEG_THREADS=16
# --------------------------------------------------

CONVERT_TARGET_DIR="/home/lorenzo/Video/Convertiti"
mkdir -p "$CONVERT_TARGET_DIR"

cleanup_burst() {
    pkill -P $$ ffmpeg 2>/dev/null
    rm -rf /dev/shm/burst_job_*_$SESSION_ID 2>/dev/null
    rm -rf /var/tmp/burst_job_*_$SESSION_ID 2>/dev/null
    rm -f "$FAIL_TICKET"
}
trap cleanup_burst EXIT

process_file() {
    local i="$1"
    local base_name=$(basename "$i")
    local failure_log="$CONVERT_TARGET_DIR/${base_name}.log"
    local success=false

    # Gestione RAM/Disk protetta contro sovraccarichi concorrenti
    file_size_kb=$(du -k "$i" | cut -f1)
    ram_free_kb=$(df -k /dev/shm | awk 'NR==2 {print $4}')
    
    # Dividiamo la RAM libera per la concorrenza massima per evitare sforamenti
    local safe_ram_limit=$(( (ram_free_kb / MAX_CONCURRENT) * 60 / 100 ))
    
    WORK_ROOT=$([ "$file_size_kb" -lt "$safe_ram_limit" ] && echo "/dev/shm/burst_job_${RANDOM}_$SESSION_ID" || echo "/var/tmp/burst_job_${RANDOM}_$SESSION_ID")
    mkdir -p "$WORK_ROOT"
    
    (
        duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$i")
        [ -z "$duration" ] && exit 1
        seg_time=$(awk "BEGIN {print $duration / $NUM_CHUNKS}")
        
        # FIX: Aggiunto -nostdin
        ffmpeg -nostdin -y -i "$i" -c copy -map 0 -f segment -segment_time "$seg_time" -reset_timestamps 1 "$WORK_ROOT/s%03d.mp4" >/dev/null 2>&1 || exit 1
        
        pids=()
        for part in "$WORK_ROOT"/s[0-9]*.mp4; do
            # FIX: Aggiunto -nostdin e configurati i thread sicuri e pools
            nice -n 19 ffmpeg -nostdin -y -i "$part" -c:v libx265 -crf 23 -preset veryfast \
                -threads "$FFMPEG_THREADS" -x265-params "hist-scenecut=1:pools=$THREADS_PER_CHUNK" \
                -c:a copy "${part%.*}.enc.mp4" >/dev/null 2>&1 &
            pids+=($!)
        done
        for pid in "${pids[@]}"; do wait $pid || exit 1; done
        
        cd "$WORK_ROOT" && for f in s*.enc.mp4; do echo "file '$f'"; done > list.txt
        # FIX: Aggiunto -nostdin
        ffmpeg -nostdin -y -f concat -safe 0 -i list.txt -c copy "merged.mp4" >/dev/null 2>&1
    )

    # Verifica integrità finale prima di sovrascrivere
    if [ $? -eq 0 ] && ffmpeg -nostdin -v error -i "$WORK_ROOT/merged.mp4" -c copy -f null - 2>"$failure_log"; then
        if mv -f "$WORK_ROOT/merged.mp4" "$i"; then
            success=true; rm -f "$failure_log"
        fi
    fi
    rm -rf "$WORK_ROOT"
    [ "$success" = false ] && echo " - $base_name" >> "$FAIL_TICKET"
}

for file in "${SELECTED_FILES[@]}"; do
    # Monitoraggio della coda di processi in background (Corretto e funzionante con set -m)
    while [ $(jobs -rp | wc -l) -ge $MAX_CONCURRENT ]; do 
        sleep 1
    done
    process_file "$file" &
done
wait

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

if [ -f "$FAIL_TICKET" ]; then
    zenity --error --title="Burst" --text="Errori:\n$(cat $FAIL_TICKET)" --width=500
else
    zenity --info --title="Burst" --text="Completato in $ELAPSED secondi con $THREADS_PER_CHUNK threads per chunk.\n\nConfigurazione usata: $MAX_CONCURRENT file paralleli con $NUM_CHUNKS chunk ciascuno."
fi