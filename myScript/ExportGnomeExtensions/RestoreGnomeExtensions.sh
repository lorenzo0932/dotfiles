#!/bin/bash
# Ripristina le estensioni GNOME Shell partendo dall'export di ExportGnomeExtensions.sh:
# scarica da extensions.gnome.org (EGO) e installa nella cartella corretta
# (~/.local/share/gnome-shell/extensions/), poi ripristina l'elenco attivo e le impostazioni.
# Uso manuale, richiede conferma.

set -uo pipefail

SOURCE="$HOME/.local/share/myScript/ExportGnomeExtensions"
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
SHELL_VERSION=$(gnome-shell --version | grep -oP '\d+\.\d+')
TMPDIR_EGO=$(mktemp -d /tmp/ego-restore.XXXXXX)

trap 'rm -rf "$TMPDIR_EGO"' EXIT

if [ ! -f "$SOURCE/enabled-extensions.list" ]; then
    echo "Errore: $SOURCE/enabled-extensions.list non esiste. Esegui prima ExportGnomeExtensions.sh."
    exit 1
fi

echo "Ripristino estensioni GNOME Shell (GNOME $SHELL_VERSION) da: $SOURCE"
echo "Verranno installate su: $EXTENSIONS_DIR"
echo
read -r -p "Procedere? (s/N): " risposta
if [[ ! "$risposta" =~ ^[Ss]$ ]]; then
    echo "Annullato."
    exit 1
fi

# Estrae le UUID dalla lista (formato gsettings: ['uuid1', 'uuid2', ...])
mapfile -t UUID_LIST < <(tr -d "[]'" < "$SOURCE/enabled-extensions.list" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$')

echo "Trovate ${#UUID_LIST[@]} estensioni da installare/attivare."

installed=0
failed=0

for uuid in "${UUID_LIST[@]}"; do
    [ -z "$uuid" ] && continue
    echo
    echo "--- $uuid"

    info=$(curl -s --max-time 15 "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$SHELL_VERSION")
    download_url=$(echo "$info" | grep -oP '"download_url":\s*"\K[^"]+' | head -1)

    if [ -z "$download_url" ]; then
        echo "  ATTENZIONE: non trovata su EGO per GNOME $SHELL_VERSION (rimossa o incompatibile). Salto."
        failed=$((failed + 1))
        continue
    fi

    zip_file="$TMPDIR_EGO/$uuid.zip"
    if ! curl -sL --max-time 60 -o "$zip_file" "https://extensions.gnome.org$download_url"; then
        echo "  ATTENZIONE: download fallito. Salto."
        failed=$((failed + 1))
        continue
    fi

    # Verifica che lo zip contenga il metadata.json con la UUID attesa
    if ! unzip -l "$zip_file" | grep -q "metadata.json"; then
        echo "  ATTENZIONE: zip non valido (manca metadata.json). Salto."
        failed=$((failed + 1))
        continue
    fi
    zip_uuid=$(unzip -p "$zip_file" metadata.json 2>/dev/null | grep -oP '"uuid":\s*"\K[^"]+' | head -1)
    if [ -z "$zip_uuid" ]; then
        zip_uuid=$(unzip -p "$zip_file" "*/metadata.json" 2>/dev/null | grep -oP '"uuid":\s*"\K[^"]+' | head -1)
    fi
    if [ "$zip_uuid" != "$uuid" ]; then
        echo "  ATTENZIONE: uuid dello zip ($zip_uuid) diverso da $uuid. Salto."
        failed=$((failed + 1))
        continue
    fi

    if gnome-extensions install -f "$zip_file"; then
        gnome-extensions enable "$uuid" 2>/dev/null || true
        echo "  Installata e attivata."
        installed=$((installed + 1))
    else
        echo "  ATTENZIONE: installazione fallita. Salto."
        failed=$((failed + 1))
    fi
done

# Ripristina le impostazioni delle estensioni (se l'export le contiene)
if [ -f "$SOURCE/extensions-settings.conf" ]; then
    echo
    echo "Ripristino delle impostazioni delle estensioni (dconf)..."
    dconf load /org/gnome/shell/extensions/ < "$SOURCE/extensions-settings.conf"
fi

echo
echo "Riepilogo: $installed installate, $failed fallite/saltate."
echo "Per applicare le modifiche: logout e login (su Wayland la shell non si riavvia al volo)."
