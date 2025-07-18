#! /bin/bash

#Questa installazione prende tutto il contenuto del progetto, lo copia in una specifica posizione e la aggiunge al PATH

SCRIPT_FOLDER=$HOME/.local/share/myScript
mkdir -p "$SCRIPT_FOLDER"
cp -r ../myScript "$SCRIPT_FOLDER"

# Aggiungi la cartella principale degli script al PATH se non è già presente
if ! grep -q "export PATH=\"$SCRIPT_FOLDER/myScript:\$PATH\"" "$HOME/.bashrc"; then
    echo "export PATH=\"$SCRIPT_FOLDER/myScript:\$PATH\"" >> "$HOME/.bashrc"
    echo "Aggiunto $SCRIPT_FOLDER/myScript al PATH."
fi

# Trova tutte le sottocartelle all'interno di myScript che contengono file .sh e aggiungile al PATH (da modificare aggiungendo solo gli script necessari)
find "$SCRIPT_FOLDER/myScript" -type f -name "*.sh" -print0 | while IFS= read -r -d $'\0' file; do
    dir=$(dirname "$file")
    if ! grep -q "export PATH=\"$dir:\$PATH\"" "$HOME/.bashrc"; then
        echo "export PATH=\"$dir:\$PATH\"" >> "$HOME/.bashrc"
        echo "Aggiunto $dir al PATH."
    fi
done

echo "Installazione degli script completata. Potrebbe essere necessario riavviare il terminale o eseguire 'source ~/.bashrc' per applicare le modifiche al PATH."
