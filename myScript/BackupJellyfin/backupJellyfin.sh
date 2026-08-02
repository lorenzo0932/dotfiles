#!/bin/bash

# ==============================================================================
# SCRIPT DI BACKUP INCREMENTALE DIRETTO PER JELLYFIN SERVER (FLATPAK)
# Esegue un backup settimanale senza downtime, utilizzando uno snapshot del database.
# Mantiene le ultime due versioni del backup in modo efficiente.
# ==============================================================================

# --- CONFIGURAZIONE ---
SOURCE_DIR="$HOME/.var/app/org.jellyfin.JellyfinServer/"
DB_FILE_PATH="$SOURCE_DIR/data/jellyfin/data/jellyfin.db"
BACKUP_PARENT_DIR="/run/media/lorenzo/SSD2/JellyfinUserBackup"
RETENTION_COUNT=4
# --- FINE CONFIGURAZIONE ---

# Controlla se sqlite3 è installato
if ! command -v sqlite3 &> /dev/null; then
    echo "!!! Errore: Il comando 'sqlite3' non è stato trovato. Installalo per procedere."
    exit 1
fi

# Crea una cartella temporanea per lo snapshot del database
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT # Pulizia automatica all'uscita

# Percorsi di backup
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
CURRENT_BACKUP_DIR="$BACKUP_PARENT_DIR/backup-$TIMESTAMP"
LATEST_LINK="$BACKUP_PARENT_DIR/latest"
DB_SNAPSHOT_PATH="$TMP_DIR/jellyfin.db.snapshot"

echo ">>> Avvio backup 'live' di Jellyfin..."

# Controlla se la cartella di destinazione esiste
if [ ! -d "$BACKUP_PARENT_DIR" ]; then
    echo "!!! Errore: La cartella di destinazione '$BACKUP_PARENT_DIR' non esiste. Creala e riprova."
    exit 1
fi

# 1. Crea uno snapshot sicuro del database live
echo "--> 1/3: Creazione dello snapshot del database..."
sqlite3 "$DB_FILE_PATH" ".backup '$DB_SNAPSHOT_PATH'"
if [ $? -ne 0 ]; then
    echo "!!! Errore: Impossibile creare lo snapshot del database. Backup annullato."
    exit 1
fi

# 2. Esegui il backup incrementale
echo "--> 2/3: Esecuzione di rsync per i file di configurazione..."
if [ -L "$LATEST_LINK" ]; then
    # Se esiste un backup precedente, usa --link-dest per l'efficienza dello spazio
    rsync -a --delete --link-dest="$(readlink "$LATEST_LINK")" "$SOURCE_DIR" "$CURRENT_BACKUP_DIR"
else
    # Altrimenti, esegui un primo backup completo
    rsync -a --delete "$SOURCE_DIR" "$CURRENT_BACKUP_DIR"
fi

# Sovrascrivi il database nel nuovo backup con lo snapshot sicuro
rsync -a "$DB_SNAPSHOT_PATH" "$CURRENT_BACKUP_DIR/data/jellyfin/data/jellyfin.db"
echo "--> Backup completato in '$CURRENT_BACKUP_DIR'"

# 3. Aggiornamento del link 'latest' e pulizia dei vecchi backup
echo "--> 3/3: Aggiornamento del link 'latest' e pulizia dei vecchi backup..."
rm -f "$LATEST_LINK"
ln -s "$CURRENT_BACKUP_DIR" "$LATEST_LINK"
find "$BACKUP_PARENT_DIR" -maxdepth 1 -type d -name "backup-*" | sort -r | tail -n +$((RETENTION_COUNT + 1)) | xargs -I {} rm -rf {}

echo ">>> Backup di Jellyfin completato con successo!"

exit 0