#!/bin/bash
# --- AniEngine Burst v22 (Synced with User mpv.conf) ---

# Recupero automatico del percorso shader di MPV
SHADERS_DIR="$HOME/.config/mpv/shaders"

# La tua "Modalità B HQ" attiva nel mpv.conf:
S1="$SHADERS_DIR/Anime4K_Clamp_Highlights.glsl"
S2="$SHADERS_DIR/Anime4K_Restore_CNN_Soft_VL.glsl"
S3="$SHADERS_DIR/Anime4K_Upscale_CNN_x2_VL.glsl"
S4="$SHADERS_DIR/Anime4K_AutoDownscalePre_x2.glsl"
S5="$SHADERS_DIR/Anime4K_AutoDownscalePre_x4.glsl"
S6="$SHADERS_DIR/Anime4K_Upscale_CNN_x2_M.glsl"

SHADERS_JOINED="$S1:$S2:$S3:$S4:$S5:$S6"

# Verifica esistenza file critici
if [ ! -f "$S2" ]; then
    zenity --error --text="Shader non trovati in $SHADERS_DIR\nControlla i nomi dei file!"
    exit 1
fi

START_TIME=$(date +%s)
export IFS=$'\n'
SESSION_ID="$$"
CONVERT_TARGET_DIR="/home/lorenzo/Video/Convertiti"
mkdir -p "$CONVERT_TARGET_DIR"

SELECTED_FILES=()
[ -n "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" ] && for f in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS; do [ -f "$f" ] && SELECTED_FILES+=("$f"); done || SELECTED_FILES=("$@")

TOTAL_FILES=${#SELECTED_FILES[@]}

# Logica Chunks (Ottimizzata per 5950X + RX 6700)
if [ "$TOTAL_FILES" -gt 1 ]; then
    MAX_CONCURRENT=2
    NUM_CHUNKS=2
else
    MAX_CONCURRENT=1
    NUM_CHUNKS=4
fi

TOTAL_CORES=$(nproc)
THREADS_PER_CHUNK=$(awk "BEGIN {t=int(($TOTAL_CORES * 0.85) / ($MAX_CONCURRENT * $NUM_CHUNKS)); if(t<1)t=1; print t}")

cleanup_burst() {
    pkill -P $$ mpv 2>/dev/null
    rm -rf /dev/shm/burst_job_*_$SESSION_ID 2>/dev/null
    rm -rf /var/tmp/burst_job_*_$SESSION_ID 2>/dev/null
}
trap cleanup_burst EXIT

process_file() {
    local input_file="$1"
    local base_name=$(basename "$input_file")
    local output_final="$CONVERT_TARGET_DIR/${base_name%.*}.upscaled.mp4"
    
    # Utilizzo /dev/shm per file piccoli, altrimenti /var/tmp
    file_size_kb=$(du -k "$input_file" | cut -f1)
    ram_free_kb=$(df -k /dev/shm | awk 'NR==2 {print $4}')
    WORK_ROOT=$([ "$file_size_kb" -lt $((ram_free_kb * 50 / 100)) ] && echo "/dev/shm/burst_job_${RANDOM}_$SESSION_ID" || echo "/var/tmp/burst_job_${RANDOM}_$SESSION_ID")
    mkdir -p "$WORK_ROOT"

    # 1. Split rapido
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
    seg_time=$(awk "BEGIN {print $duration / $NUM_CHUNKS}")
    ffmpeg -y -i "$input_file" -c copy -f segment -segment_time "$seg_time" -reset_timestamps 1 "$WORK_ROOT/part%03d.mp4" >/dev/null 2>&1

    # 2. Rendering GPU + Encoding CPU
    pids=()
    for part in "$WORK_ROOT"/part[0-9]*.mp4; do
        mpv "$part" \
            --o="${part%.*}.enc.mp4" \
            --ovc=libx265 \
            --ovcopts="crf=27,preset=veryfast,threads=$THREADS_PER_CHUNK,x265-params=hist-scenecut=1" \
            --oacopts="acodec=copy" \
            --vf=gpu=api=vulkan \
            --gpu-api=vulkan \
            --glsl-shaders="$SHADERS_JOINED" \
            --msg-level=all=status >/dev/null 2>&1 &
        pids+=($!)
    done
    for pid in "${pids[@]}"; do wait $pid; done

    # 3. Merge
    (
        cd "$WORK_ROOT"
        for f in part*.enc.mp4; do echo "file '$f'"; done > list.txt
        ffmpeg -y -f concat -safe 0 -i list.txt -c copy "$output_final" >/dev/null 2>&1
    )
    rm -rf "$WORK_ROOT"
}

for file in "${SELECTED_FILES[@]}"; do
    while [ $(jobs -rp | wc -l) -ge $MAX_CONCURRENT ]; do sleep 1; done
    process_file "$file" &
done
wait

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
zenity --info --title="AniEngine Burst" --text="Finito in $ELAPSED sec.\nUsata 'Modalità B HQ' su RX 6700." --width=350