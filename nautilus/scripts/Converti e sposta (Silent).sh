#!/bin/bash
# AniEngine Silent - (v23 + C++ Adaptive Logic)
START_TIME=$(date +%s)
export IFS=$'\n'
SESSION_ID="$$"
FAIL_TICKET="/tmp/silent_failed_$SESSION_ID"

SELECTED_FILES=()
for f in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS; do [ -f "$f" ] && SELECTED_FILES+=("$f"); done
TOTAL_FILES=${#SELECTED_FILES[@]}

# --- LOGICA ADATTIVA AppConfigManager.cpp ---
TOTAL_CORES=$(nproc)
TARGET_THREADS=$(awk "BEGIN {print int($TOTAL_CORES * 0.50)}")

MAX_CONCURRENT=1
if [ "$TOTAL_CORES" -gt 16 ]; then
    NUM_CHUNKS=2     # 1 video * 2 chunk = 2 processi FFmpeg
else
    NUM_CHUNKS=1
fi

THREADS_PER_CHUNK=$(awk "BEGIN {t=int($TARGET_THREADS / ($MAX_CONCURRENT * $NUM_CHUNKS)); if(t<1)t=1; if(t>12)t=12; print t}")
# --------------------------------------------

CONVERT_TARGET_DIR="/home/lorenzo/Video/Convertiti"
mkdir -p "$CONVERT_TARGET_DIR"

cleanup_silent() {
    pkill -P $$ ffmpeg 2>/dev/null
    rm -rf /dev/shm/silent_job_*_$SESSION_ID 2>/dev/null
    rm -rf /var/tmp/silent_job_*_$SESSION_ID 2>/dev/null
    rm -f "$FAIL_TICKET"
}
trap cleanup_silent EXIT

process_silent() {
    local i="$1"
    local base_name=$(basename "$i")
    local failure_log="$CONVERT_TARGET_DIR/${base_name}.log"
    local success=false

    file_size_kb=$(du -k "$i" | cut -f1)
    ram_free_kb=$(df -k /dev/shm | awk 'NR==2 {print $4}')
    WORK_ROOT=$([ "$file_size_kb" -lt $((ram_free_kb * 70 / 100)) ] && echo "/dev/shm/silent_job_${RANDOM}_$SESSION_ID" || echo "/var/tmp/silent_job_${RANDOM}_$SESSION_ID")
    mkdir -p "$WORK_ROOT"
    
    (
        if [ "$NUM_CHUNKS" -gt 1 ]; then
            duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$i")
            seg_time=$(awk "BEGIN {print $duration / $NUM_CHUNKS}")
            ffmpeg -y -i "$i" -c copy -map 0 -f segment -segment_time "$seg_time" -reset_timestamps 1 "$WORK_ROOT/s%03d.mp4" >/dev/null 2>&1 || exit 1
            
            pids=()
            for part in "$WORK_ROOT"/s[0-9]*.mp4; do
                nice -n 15 ffmpeg -y -i "$part" -c:v libx265 -crf 23 -preset veryfast -threads $THREADS_PER_CHUNK -x265-params "hist-scenecut=1" -c:a copy "${part%.*}.enc.mp4" >/dev/null 2>&1 &
                pids+=($!)
            done
            for pid in "${pids[@]}"; do wait $pid || exit 1; done
            
            cd "$WORK_ROOT" && for f in s*.enc.mp4; do echo "file '$f'"; done > list.txt
            ffmpeg -y -f concat -safe 0 -i list.txt -c copy "merged.mp4" >/dev/null 2>&1
        else
            nice -n 15 ffmpeg -y -i "$i" -c:v libx265 -crf 23 -preset veryfast -threads $THREADS_PER_CHUNK -x265-params "hist-scenecut=1" -c:a copy "$WORK_ROOT/merged.mp4" >/dev/null 2>&1
        fi
    )

    if [ $? -eq 0 ] && ffmpeg -nostdin -v error -i "$WORK_ROOT/merged.mp4" -c copy -f null - 2>"$failure_log"; then
        if mv -f "$WORK_ROOT/merged.mp4" "$i"; then
            success=true; rm -f "$failure_log"
        fi
    fi
    rm -rf "$WORK_ROOT"
    [ "$success" = false ] && echo " - $base_name" >> "$FAIL_TICKET"
}

for file in "${SELECTED_FILES[@]}"; do
    process_silent "$file"
done

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

if [ -f "$FAIL_TICKET" ]; then
    zenity --error --title="Silent" --text="Errori:\n$(cat $FAIL_TICKET)" --width=500
else
    zenity --info --title="Silent" --text="Completato in $ELAPSED secondi. Config: $NUM_CHUNKS chunk, $THREADS_PER_CHUNK threads."
fi