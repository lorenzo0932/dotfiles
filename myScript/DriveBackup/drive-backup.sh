#!/bin/bash
# ==============================================================================
# drive-backup.sh — backup mensile file IMPORTANTI sui due Google Drive via rclone
# Dir: ~/.local/share/myScript/DriveBackup/ (autonoma: non usa rSync.sh/exclude.txt)
# Job definiti in drive-jobs.conf (REMOTE|LOCAL_SRC|REMOTE_DST).
# Solo COPIA (rclone copy): non cancella mai nulla sui Drive.
# ==============================================================================

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS="$SCRIPT_DIR/drive-jobs.conf"
LOGDIR="$SCRIPT_DIR/logs"
STAMP="$(date +%F_%H%M)"
LOG="$LOGDIR/drive-backup-$STAMP.log"
LOCK="/tmp/drive-backup.lock"
FAILED=0
TOTAL=0

notify() { command -v notify-send &>/dev/null && notify-send "DriveBackup" "$1"; }

# --- Lock anti-sovrapposizione ---
if [ -e "$LOCK" ]; then
    echo "!!! lock esistente ($LOCK): un altro giro e' in corso. Esco."
    exit 3
fi
trap 'rm -f "$LOCK"' EXIT
touch "$LOCK"
mkdir -p "$LOGDIR"

# --- Pre-check ---
if ! command -v rclone &>/dev/null; then
    echo "!!! rclone non installato. Vedi README.md (setup first-time)."
    notify "rclone mancante: backup annullato"
    exit 2
fi
for R in drive-personale drive-lavoro; do
    if ! rclone listremotes 2>/dev/null | grep -qx "${R}:"; then
        echo "!!! remote '$R' non configurato. Esegui 'rclone config' (vedi README.md)."
        notify "remote $R mancante: backup annullato"
        exit 2
    fi
done
if ! ping -c1 -W3 8.8.8.8 &>/dev/null; then
    echo "!!! rete assente. Backup rimandato."
    exit 2
fi
[ -f "$JOBS" ] || { echo "!!! manca $JOBS"; exit 2; }

echo "=== drive-backup $STAMP ===" | tee "$LOG"
while IFS='|' read -r REMOTE SRC DST; do
    # salta righe vuote e commenti
    [[ "$REMOTE" =~ ^#.*$ || -z "$REMOTE" ]] && continue
    SRC_EXPANDED="${SRC//\$HOME/$HOME}"
    TOTAL=$((TOTAL + 1))
    if [ ! -e "$SRC_EXPANDED" ]; then
        echo "[SKIP] sorgente assente: $SRC_EXPANDED" | tee -a "$LOG"
        FAILED=$((FAILED + 1))
        continue
    fi
    echo "[JOB] $SRC_EXPANDED -> ${REMOTE}:${DST}" | tee -a "$LOG"
    if rclone copy --update --checksum --transfers 4 \
        --log-file="$LOG" --log-level INFO \
        "$SRC_EXPANDED" "${REMOTE}:${DST}"; then
        rclone check "$SRC_EXPANDED" "${REMOTE}:${DST}" --one-way >>"$LOG" 2>&1 \
            && echo "[OK] $SRC_EXPANDED" | tee -a "$LOG" \
            || { echo "[CHECK-FAIL] $SRC_EXPANDED" | tee -a "$LOG"; FAILED=$((FAILED + 1)); }
    else
        echo "[COPY-FAIL] $SRC_EXPANDED" | tee -a "$LOG"
        FAILED=$((FAILED + 1))
    fi
done < "$JOBS"

echo "=== fine: $((TOTAL - FAILED))/$TOTAL ok ===" | tee -a "$LOG"
[ "$FAILED" -gt 0 ] && notify "completato con $FAILED errori (vedi $LOG)" && exit 1
echo "Backup Drive completato senza errori."
exit 0
