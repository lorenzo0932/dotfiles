#! /bin/bash

#!/bin/bash

# Nome della cartella principale del progetto
PROJECT_DIR="AniDownloader"

# Controlla se la cartella esiste già per evitare di sovrascrivere
if [ -d "$PROJECT_DIR" ]; then
    echo "ERRORE: La cartella '$PROJECT_DIR' esiste già in questa posizione."
    echo "Rimuovila o spostati in un'altra directory prima di eseguire lo script."
    exit 1
fi

echo "Creazione della struttura del progetto in ./${PROJECT_DIR}/"

# 1. Crea la cartella principale e le sottocartelle
mkdir -p "${PROJECT_DIR}/gui"
mkdir -p "${PROJECT_DIR}/core"
mkdir -p "${PROJECT_DIR}/assets"
echo "- Cartelle create: gui/, core/, assets/"

# 2. Crea i file Python vuoti pronti per essere riempiti
touch "${PROJECT_DIR}/main.py"
touch "${PROJECT_DIR}/gui/__init__.py"
touch "${PROJECT_DIR}/gui/main_window.py"
touch "${PROJECT_DIR}/gui/series_manager.py"
touch "${PROJECT_DIR}/gui/widgets.py"
touch "${PROJECT_DIR}/core/__init__.py"
touch "${PROJECT_DIR}/core/download_worker.py"
echo "- File .py creati."

# 3. Crea un file logo.png vuoto come placeholder
touch "${PROJECT_DIR}/assets/logo.png"
echo "- Placeholder 'logo.png' creato in assets/."

# 4. Popola il file series_data.json con un array JSON vuoto
echo "[]" > "${PROJECT_DIR}/series_data.json"
echo "- File 'series_data.json' inizializzato."

# 5. Popola il file requirements.txt con le dipendenze necessarie
cat << EOF > "${PROJECT_DIR}/requirements.txt"
PyQt6
psutil
requests
EOF
echo "- File 'requirements.txt' popolato con le dipendenze."

# 6. Messaggio finale con le istruzioni successive
echo ""
echo "--------------------------------------------------"
echo "✅ Struttura del progetto creata con successo!"
echo "--------------------------------------------------"
echo ""
echo "Prossimi passi:"
echo "1. Copia il contenuto dei file Python che ti ho fornito nelle rispettive posizioni."
echo "2. Spostati nella cartella del progetto con il comando:"
echo "   cd ${PROJECT_DIR}"
echo "3. Installa le dipendenze necessarie con il comando:"
echo "   pip install -r requirements.txt"
echo "4. Esegui il programma con:"
echo "   python main.py"
echo ""