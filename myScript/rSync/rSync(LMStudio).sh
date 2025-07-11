#!/bin/bash

# --- Configuration ---
# Define your source directories (modify paths as needed)
MYSCRIPTS="/home/lorenzo/.local/share/myScript"
NAUTILUS_SCRIPTS="/home/lorenzo/.local/share/nautilus"
SYSTEMD_SERVICES="/home/lorenzo/.config/systemd"

# Define your destination directory (your dotfiles repo folder)
DEST="/home/lorenzo/Documenti/GitHub/dotfiles"

# LM Studio API endpoint (default for LM Studio)
LMSTUDIO_API_URL="http://localhost:1234/v1/chat/completions"

# --- Sync Files with rsync ---
echo "Sincronizzazione dei file dotfiles..."
rsync -au --delete --exclude-from='exclude.txt' "$MYSCRIPTS/" "$DEST/myScript/"
rsync -au --delete --exclude-from='exclude.txt' "$NAUTILUS_SCRIPTS/" "$DEST/nautilus/"
rsync -au --delete "$SYSTEMD_SERVICES/" "$DEST/systemd/"
echo "Sincronizzazione completata."

# --- Git Operations ---
cd "$DEST" || { echo "Errore: Impossibile cambiare directory in $DEST"; exit 1; }

# Verifica se ci sono modifiche da commitare
if [[ -n $(git status --porcelain) ]]; then
    echo "Modifiche rilevate. Preparazione del commit automatico..."
    
    # Ottengo le differenze di file da commitare 
    GIT_STATUS_OUTPUT=$(git diff)
    echo "$GIT_STATUS_OUTPUT"
    
    # Aggiungi tutti i file modificati al repository Git
    git add .


    # Prepara il payload per la richiesta LM Studio
    # Chiedi al LLM locale di generare un messaggio di commit conciso basato sulle modifiche.
    PROMPT="Genera un messaggio di commit conciso (max 100 caratteri) basato sulle seguenti modifiche ai file dotfiles. Inizia con 'Auto sync: '.
    Modifiche:
    $GIT_STATUS_OUTPUT"

    # Costruisci il payload JSON per l'API OpenAI-compatibile di LM Studio
    # Nota: Il parametro 'ttl' non è supportato qui per l'unload del modello.
    # Configura il TTL del modello direttamente in LM Studio (GUI o CLI).
    JSON_PAYLOAD=$(jq -n \
                    --arg prompt "$PROMPT" \
                    '{
                      model: "qwen2.5-coder-7b-instruct",
                      messages: [
                        {role: "system", content: "Sei un assistente utile che riassume le modifiche di git."},
                        {role: "user", content: $prompt}
                      ],
                      temperature: 0.8,
                    }')

    # Effettua la chiamata all'API LM Studio
    echo "Richiesta messaggio di commit a LM Studio..."
    LMSTUDIO_RESPONSE=$(curl -s -X POST \
                              -H "Content-Type: application/json" \
                              -d "$JSON_PAYLOAD" \
                              "$LMSTUDIO_API_URL")

    # Estrai il messaggio di commit dalla risposta di LM Studio
    COMMIT_MESSAGE=$(echo "$LMSTUDIO_RESPONSE" | jq -r '.choices[0].message.content')

    # Fallback message in case LM Studio fails or returns an empty message
    if [ -z "$COMMIT_MESSAGE" ] || [ "$COMMIT_MESSAGE" == "null" ]; then
        echo "Avviso: Impossibile generare un messaggio di commit con LM Studio. Utilizzo del messaggio di default."
        COMMIT_MESSAGE="Auto sync: aggiornamenti $(date '+%Y-%m-%d %H:%M:%S')"
    fi

    echo "Messaggio di commit generato: '$COMMIT_MESSAGE'"

    # Esegui il commit e il push
    git commit -m "$COMMIT_MESSAGE"
    git push origin main
    echo "Commit e push completati."
else
    echo "Nessuna modifica da commitare."
fi

echo "Script completato."