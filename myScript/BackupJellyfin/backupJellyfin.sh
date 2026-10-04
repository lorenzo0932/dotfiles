#!/bin/bash

# ==============================================================================
# SCRIPT DI BACKUP INCREMENTALE DIRETTO PER JELLYFIN SERVER (DOCKER)
# Esegue un backup settimanale senza downtime, utilizzando uno snapshot del database.
# Mantiene le ultime N versioni del backup in modo efficiente (hardlink).
# Storico: prima puntava a ~/.var/app/org.jellyfin.JellyfinServer (Flatpak),
# migrato a Docker il 2026-09-30 (volumi in ~/docker/jellyfin).
# ==============================================================================

# --- CONFIGURAZIONE ---
VOL_DIR="$HOME/docker/jellyfin/config"
COMPOSE_DIR="$HOME/docker/jellyfin"
BACKUP_PARENT_DIR="/home/Data&Games/JellyfinMigration"
RETENTION_COUNT=4
# --- FINE CONFIGURAZIONE ---

# Controlla se sqlite3 è installato
if ! command -v sqlite3 &> /dev/null; then
    echo "!!! Errore: Il comando 'sqlite3' non è stato trovato. Installalo per procedere."
    exit 1
fi

# Controlla che i volumi esistano
if [ ! -d "$VOL_DIR/data" ]; then
    echo "!!! Errore: volumi Jellyfin non trovati in '$VOL_DIR'. Backup annullato."
    exit 1
fi

# Crea una cartella temporanea per gli snapshot dei database
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT # Pulizia automatica all'uscita

# Percorsi di backup
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
CURRENT_BACKUP_DIR="$BACKUP_PARENT_DIR/backup-$TIMESTAMP"
LATEST_LINK="$BACKUP_PARENT_DIR/latest"

echo ">>> Avvio backup 'live' di Jellyfin (Docker)..."

# Controlla se la cartella di destinazione esiste
if [ ! -d "$BACKUP_PARENT_DIR" ]; then
    echo "!!! Errore: La cartella di destinazione '$BACKUP_PARENT_DIR' non esiste. Creala e riprova."
    exit 1
fi

# 1. Snapshot sicuri dei database live (kodisyncqueue*.db sono LiteDB: basta rsync)
echo "--> 1/3: Creazione degli snapshot dei database..."
for db in data/jellyfin.db data/playback_reporting.db data/introskipper/introskipper.db data/introskipper/introskipper-cache.db; do
    name=$(basename "$db" .db)
    if [ -f "$VOL_DIR/$db" ]; then
        sqlite3 "$VOL_DIR/$db" ".backup '$TMP_DIR/$name.db'"
        if [ $? -ne 0 ]; then
            echo "!!! Errore: impossibile creare lo snapshot di $db. Backup annullato."
            exit 1
        fi
    fi
done

# 2. Backup incrementale dei volumi (esclusa cache effimera e WAL/SHM)
echo "--> 2/3: Esecuzione di rsync per i volumi..."
mkdir -p "$CURRENT_BACKUP_DIR/volumes" "$CURRENT_BACKUP_DIR/host-config"
RSYNC_OPTS="-a --delete --exclude *-shm --exclude *-wal"
if [ -L "$LATEST_LINK" ]; then
    # Se esiste un backup precedente, usa --link-dest per l'efficienza dello spazio
    rsync $RSYNC_OPTS --link-dest="$(readlink "$LATEST_LINK")" "$VOL_DIR/" "$CURRENT_BACKUP_DIR/volumes/"
else
    # Altrimenti, esegui un primo backup completo
    rsync $RSYNC_OPTS "$VOL_DIR/" "$CURRENT_BACKUP_DIR/volumes/"
fi

# Sovrascrivi i database nel nuovo backup con gli snapshot sicuri
cp -a "$TMP_DIR/jellyfin.db" "$CURRENT_BACKUP_DIR/volumes/data/jellyfin.db"
cp -a "$TMP_DIR/playback_reporting.db" "$CURRENT_BACKUP_DIR/volumes/data/playback_reporting.db" 2>/dev/null || true
cp -a "$TMP_DIR/introskipper.db" "$CURRENT_BACKUP_DIR/volumes/data/introskipper/introskipper.db" 2>/dev/null || true
cp -a "$TMP_DIR/introskipper-cache.db" "$CURRENT_BACKUP_DIR/volumes/data/introskipper/introskipper-cache.db" 2>/dev/null || true

# Salva anche compose + piano migrazione (ripristino completo in un colpo solo)
mkdir -p "$CURRENT_BACKUP_DIR/host-config"
cp -a "$COMPOSE_DIR/compose.yml" "$COMPOSE_DIR/compose.test.yml" "$COMPOSE_DIR/MIGRATION_PLAN.md" "$CURRENT_BACKUP_DIR/host-config/" 2>/dev/null || true
echo "--> Backup completato in '$CURRENT_BACKUP_DIR'"

# 3. Aggiornamento del link 'latest' e pulizia dei vecchi backup
echo "--> 3/3: Aggiornamento del link 'latest' e pulizia dei vecchi backup..."
rm -f "$LATEST_LINK"
ln -s "$CURRENT_BACKUP_DIR" "$LATEST_LINK"
find "$BACKUP_PARENT_DIR" -maxdepth 1 -type d -name "backup-*" | sort -r | tail -n +$((RETENTION_COUNT + 1)) | xargs -I {} rm -rf {}

echo ">>> Backup di Jellyfin completato con successo!"

exit 0
