#! /usr/bin/python3
from pathlib import Path
import subprocess
import sys
import os

# Ottieni il percorso assoluto della directory dello script
script_dir = os.path.dirname(os.path.abspath(__file__))

# Imposta la directory di lavoro corrente alla directory dello script
os.chdir(script_dir)

# Directory di ricerca
SEARCH_DIR = Path("/home/lorenzo/Video")

# # Cerca i file .mp4 (non ricorsivo; per ricerca ricorsiva usa rglob("*.mp4"))
mp4_files = list(SEARCH_DIR.glob("*.mp4"))
if not mp4_files:
    print("Nessun file mp4 trovato")
    sys.exit(1)

# Cerca nell lista di mp4_files quelli pi recenti, quindi quelli con il timestamp con valore pi alto
most_recent_files = max(mp4_files, key=lambda f: f.stat().st_mtime)

# Crea una stringa con i percorsi completi di tutti i file mp4 trovati
# mp4_files_paths = "\n".join(str(file) for file in mp4_files)
mp4_files_paths = str(most_recent_files)
# Imposta la variabile di ambiente che si aspetta Nautilus
env = os.environ.copy()
env["NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"] = mp4_files_paths

# Specifica il path dello scritp Nautilus
script_path = "./Converti e verifica.sh"

#Verifico che lo script da eseguire esista e sia eseguibile
if not os.path.isfile(script_path):
    print(f"Lo script {script_path} non esiste")
    sys.exit(1)

if not os.access(script_path, os.X_OK):
    print(f"Lo script {script_path} non è eseguibile")
    sys.exit(1)
    
# Avvia lo script passando l'ambiente con la variabile di ambiente impostata in precedenza
result = subprocess.run([script_path], env = env)

