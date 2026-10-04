#!/bin/bash
# Ricopia i file live di ~/docker/jellyfin in questa cartella versionata.
# ESCLUSI volumi, cache, backup e snapshot (GB di dati: restano fuori da git).
# Eseguire a mano dopo ogni modifica ai file live, poi parte il sync rSync.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HOME/docker/jellyfin"
for f in compose.yml compose.test.yml pre-update-snapshot.sh rollback-jellyfin.sh MIGRATION_PLAN.md; do
    cp -a "$SRC/$f" "$SCRIPT_DIR/$f"
done
chmod +x "$SCRIPT_DIR/"*.sh
echo "Sincronizzato da $SRC (solo config, niente dati)."
