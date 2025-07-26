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
rsync -au --delete --exclude-from='exclude.txt' "$SYSTEMD_SERVICES/" "$DEST/systemd/"
echo "Sincronizzazione completata."
