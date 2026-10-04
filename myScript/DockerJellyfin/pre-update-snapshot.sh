#!/bin/bash
# Snapshot pre-update di Jellyfin (Docker) per rollback sicuro.
# Eseguito dal timer jellyfin-preupdate (03:55, prima di Watchtower delle 04:00)
# oppure a mano prima di un update. Usa snapshot sqlite (sicuri a server acceso).
set -e

VOL_DIR="$HOME/docker/jellyfin/config"
SNAP_PARENT="/home/Data&Games/JellyfinMigration"
RETENTION_COUNT=2

command -v sqlite3 >/dev/null || { echo "manca sqlite3"; exit 1; }
[ -d "$VOL_DIR/data" ] || { echo "volumi non trovati"; exit 1; }

TS=$(date +"%Y-%m-%d_%H-%M-%S")
DST="$SNAP_PARENT/pre-update-$TS"
mkdir -p "$DST/volumes/data" "$DST/volumes/plugins"
TMP_SNAP=$(mktemp)
trap 'rm -f "$TMP_SNAP"' EXIT

echo ">>> Snapshot pre-update in $DST"

# Database via snapshot sqlite (consistenti anche a server acceso)
for db in data/jellyfin.db data/playback_reporting.db data/introskipper/introskipper.db data/introskipper/introskipper-cache.db; do
    name=$(basename "$db" .db)
    dest="$DST/volumes/$db"
    mkdir -p "$(dirname "$dest")"
    if [ -f "$VOL_DIR/$db" ]; then
        sqlite3 "$VOL_DIR/$db" ".backup '$TMP_SNAP'" 2>/dev/null || true
        # fallback: copia rsync se .backup fallisce (es. file LiteDB)
        if [ -f "$TMP_SNAP" ]; then
            mv "$TMP_SNAP" "$dest"
        else
            cp -a "$VOL_DIR/$db" "$dest"
        fi
        echo "  db ok: $db"
    fi
done

# Plugin (si auto-aggiornano: vanno ripristinati insieme al DB in caso di rollback)
rsync -a --delete --exclude "*-shm" --exclude "*-wal" "$VOL_DIR/plugins/" "$DST/volumes/plugins/"

# Digest + versione immagine corrente (per ripinnare in rollback)
DIGEST=$(docker inspect jellyfin --format '{{.Image}}' 2>/dev/null || true)
docker inspect "$DIGEST" --format '{{range .RepoDigests}}{{.}}{{"\n"}}{{end}}' 2>/dev/null | head -n 3 > "$DST/repodigests.txt" || true
{
    echo "timestamp=$TS"
    echo "image_id=$DIGEST"
    echo -n "version="; curl -s --max-time 10 http://localhost:8096/jellyfin/System/Info/Public 2>/dev/null | grep -o '"Version":"[^"]*"' || echo "version=sconosciuta"
} > "$DST/meta.txt"
cat "$DST/meta.txt"

# Retention: tieni gli ultimi N snapshot pre-update
# shellcheck disable=SC2012
ls -dt "$SNAP_PARENT"/pre-update-* 2>/dev/null | tail -n +$((RETENTION_COUNT + 1)) | xargs -r rm -rf
echo ">>> Snapshot completato."
