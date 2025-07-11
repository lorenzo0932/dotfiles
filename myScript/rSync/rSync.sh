#!/bin/bash

# --- Configuration ---
# Define your source directories (modify paths as needed)
MYSCRIPTS="/home/lorenzo/.local/share/myScript"
NAUTILUS_SCRIPTS="/home/lorenzo/.local/share/nautilus"
SYSTEMD_SERVICES="/home/lorenzo/.config/systemd"

# Define your destination directory (your dotfiles repo folder)
DEST="/home/lorenzo/Documenti/GitHub/dotfiles"

# --- API Configuration ---
# Choose your preferred LLM API by uncommenting one of the sections below.

# --- Google AI (Gemini) API Configuration ---
# Per usare Google AI, assicurati di avere una chiave API valida e di aver abilitato
# l'API Gemini nel tuo progetto Google Cloud.
# È ALTAMENTE CONSIGLIATO caricare la chiave da una variabile d'ambiente o da un file.
# Esempio per variabile d'ambiente: GOOGLE_API_KEY="${GOOGLE_API_KEY}"
# Esempio per file: GOOGLE_API_KEY=$(cat ~/.config/google-ai-api-key.txt)
# Assicurati che il file ~/.config/google-ai-api-key.txt sia escluso dal tuo .gitignore.
GOOGLE_API_KEY="${GOOGLE_API_KEY}" # Sostituisci o carica da env

# Modello specifico di Gemini da utilizzare (ora aggiornato a gemini-2.5-flash)
LLM_MODEL="gemini-2.5-flash"
API_URL="https://generativelanguage.googleapis.com/v1beta/models/$LLM_MODEL:generateContent"
API_TYPE="google_ai"

# --- LM Studio API Configuration (Commented out by default) ---
# Per usare LM Studio, avvia LM Studio e carica un modello compatibile con l'API OpenAI.
# Il server API di default è su http://localhost:1234.
# LMSTUDIO_API_URL="http://localhost:1234/v1/chat/completions"
# LMSTUDIO_MODEL="qwen2.5-coder-7b-instruct" # Sostituisci con il nome del tuo modello LM Studio
# API_TYPE="lm_studio"

# --- Sync Files with rsync ---
echo "Sincronizzazione dei file dotfiles..."
rsync -au --delete --exclude-from='exclude.txt' "$MYSCRIPTS/" "$DEST/myScript/"
rsync -au --delete --exclude-from='exclude.txt' "$NAUTILUS_SCRIPTS/" "$DEST/nautilus/"
rsync -au --delete "$SYSTEMD_SERVICES/" "$DEST/systemd/"
echo "Sincronizzazione completata."

# --- Git Operations ---
cd "$DEST" || { echo "Errore: Impossibile cambiare directory in $DEST"; exit 1; }

GIT_STATUS=$(git status --porcelain)
# Verifica se ci sono modifiche da commitare
if [[ -n $GIT_STATUS ]]; then
    echo "Modifiche rilevate. Preparazione del commit automatico..."

    # Ottengo le differenze di file da commitare
    GIT_DIFF_OUTPUT=$(git diff)
    #echo "$GIT_DIFF_OUTPUT"

    #Caso in cui git diff non restituisce niente perché la modifica riguarda un file nuovo
    if [ -z "$GIT_DIFF_OUTPUT" ]|| [ "$GIT_DIFF_OUTPUT" == "null" ]; then
       GIT_DIFF_OUTPUT="$GIT_STATUS"
    fi

    # Aggiungi tutti i file modificati al repository Git
    git add .

    # Prepara il prompt per il LLM
    PROMPT="Genera un messaggio di commit conciso (massimo 100 caratteri) basato sulle seguenti modifiche ai file dotfiles. Sii breve e coinciso. Inizia con 'Auto sync: '.
Modifiche:
$GIT_DIFF_OUTPUT"

    JSON_PAYLOAD=""
    LLM_RESPONSE=""
    COMMIT_MESSAGE=""

    # --- Generazione del messaggio di commit tramite LLM ---
    if [ "$API_TYPE" == "google_ai" ]; then
        echo "Richiesta messaggio di commit a Google AI ($LLM_MODEL)..."
        JSON_PAYLOAD=$(jq -n \
                        --arg prompt "$PROMPT" \
                        '{
                          contents: [
                            {
                              parts: [
                                {text: $prompt}
                              ]
                            }
                          ],
                          generationConfig: {
                            temperature: 0.8
                          }
                        }')

        LLM_RESPONSE=$(curl -s -X POST \
                               -H "Content-Type: application/json" \
                               -H "X-goog-api-key: $GOOGLE_API_KEY" \
                               -d "$JSON_PAYLOAD" \
                               "$API_URL")

        # Estrai il messaggio di commit dalla risposta di Google AI
        COMMIT_MESSAGE=$(echo "$LLM_RESPONSE" | jq -r '.candidates[0].content.parts[0].text')

        # Pulisci e formatta il messaggio di commit di Gemini
        if [ -n "$COMMIT_MESSAGE" ] && [ "$COMMIT_MESSAGE" != "null" ]; then
            COMMIT_MESSAGE=$(echo "$COMMIT_MESSAGE" | sed 's/^"//;s/"$//;s/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\n')
            if [[ ! "$COMMIT_MESSAGE" =~ ^"Auto sync: " ]]; then
                COMMIT_MESSAGE="Auto sync: $COMMIT_MESSAGE"
            fi
            # if (( ${#COMMIT_MESSAGE} > 100 )); then
            #     COMMIT_MESSAGE="${COMMIT_MESSAGE:0:97}..."
            # fi
        fi

    elif [ "$API_TYPE" == "lm_studio" ]; then
        # Assicurati che le variabili LMSTUDIO_API_URL e LMSTUDIO_MODEL siano definite
        if [ -z "$LMSTUDIO_API_URL" ] || [ -z "$LMSTUDIO_MODEL" ]; then
            echo "Errore: LM Studio API URL o Model non definiti. Controlla la configurazione."
            exit 1
        fi

        echo "Richiesta messaggio di commit a LM Studio ($LMSTUDIO_MODEL)..."
        JSON_PAYLOAD=$(jq -n \
                        --arg prompt "$PROMPT" \
                        --arg model "$LMSTUDIO_MODEL" \
                        '{
                          model: $model,
                          messages: [
                            {role: "system", content: "Sei un assistente utile che riassume le modifiche di git."},
                            {role: "user", content: $prompt}
                          ],
                          temperature: 0.8,
                        }')

        LLM_RESPONSE=$(curl -s -X POST \
                              -H "Content-Type: application/json" \
                              -d "$JSON_PAYLOAD" \
                              "$LMSTUDIO_API_URL")

        # Estrai il messaggio di commit dalla risposta di LM Studio (compatibile OpenAI)
        COMMIT_MESSAGE=$(echo "$LLM_RESPONSE" | jq -r '.choices[0].message.content')
    fi

    # Fallback message in case LLM fails or returns an empty message
    if [ -z "$COMMIT_MESSAGE" ] || [ "$COMMIT_MESSAGE" == "null" ]; then
        echo "Avviso: Impossibile generare un messaggio di commit con l'LLM configurato. Utilizzo del messaggio di default."
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
