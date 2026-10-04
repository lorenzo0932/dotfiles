#!/bin/bash
# Rollback Jellyfin all'ultimo snapshot pre-update (o backup) funzionante.
# Uso: ./rollback-jellyfin.sh [snapshot-dir]
# Senza argomenti usa lo snapshot pre-update più recente.
# Ripristina: immagine (digest pinnato), database, plugin. Poi verifica l'API.
set -e
cd "$HOME/docker/jellyfin"

SNAP="${1:-$(ls -dt /home/Data\&Games/JellyfinMigration/pre-update-* 2>/dev/null | head -n 1)}"
[ -n "$SNAP" ] && [ -d "$SNAP" ] || { echo "!!! Nessuno snapshot trovato."; exit 1; }
echo ">>> Rollback da: $SNAP"
grep -E "^(timestamp|version)=" "$SNAP/meta.txt" 2>/dev/null || true

read -r -p "Confermi il rollback? [s/N] " ANS
[[ "$ANS" =~ ^[sS]$ ]] || { echo "Annullato."; exit 0; }

# 1. Stop container corrente
docker compose stop jellyfin 2>/dev/null || true

# 2. Ripristina DB + plugin dallo snapshot
for db in data/jellyfin.db data/playback_reporting.db data/introskipper/introskipper.db data/introskipper/introskipper-cache.db; do
    if [ -f "$SNAP/volumes/$db" ]; then
        mkdir -p "config/$(dirname "$db")"
        cp -a "$SNAP/volumes/$db" "config/$db"
        rm -f "config/${db}-shm" "config/${db}-wal"
        echo "  ripristinato: $db"
    fi
done
rsync -a --delete --exclude "*-shm" --exclude "*-wal" "$SNAP/volumes/plugins/" "config/plugins/"

# 3. Ripinna l'immagine al digest precedente (se registrato e scaricabile)
PIN=""
if [ -s "$SNAP/repodigests.txt" ]; then
    PIN=$(head -n 1 "$SNAP/repodigests.txt")
fi
if [ -n "$PIN" ]; then
    echo ">>> Repo digest precedente: $PIN"
    cp -a compose.yml "compose.yml.pre-rollback-$(date +%Y%m%d-%H%M%S)"
    if docker pull "$PIN" >/dev/null 2>&1; then
        sed -i -E "s|^(\s*)image: jellyfin/jellyfin:.*|\1image: $PIN|" compose.yml
        echo "  compose.yml pinnato al digest precedente (backup .pre-rollback creato)"
    else
        echo "!!! Digest non più scaricabile: tengo :latest, ripristinati solo DB+plugin"
    fi
else
    echo "(digest precedente non registrato: ripristinati solo DB+plugin)"
fi

# 4. Avvia e verifica
docker compose up -d
echo ">>> Attendo l'avvio..."
sleep 30
if curl -s --max-time 15 http://localhost:8096/jellyfin/System/Info/Public | grep -q '"ServerName"'; then
    echo ">>> Rollback riuscito: API risponde."
    echo ">>> Per tornare a :latest: ripristina compose.yml dal backup .pre-rollback e fai up -d"
else
    echo "!!! API non risponde: controlla con: docker logs jellyfin"
    exit 1
fi
