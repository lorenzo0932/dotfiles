#!/bin/bash
# Converti e sposta.sh (v5 - Compatta)

START_TIME=$(date +%s)
IFS=$'\n'
fail_list=""
MAX_RETRIES=1 # Tentativi aggiuntivi (1 = max 2 totali)

# --- CONFIGURAZIONE ---
CONVERT_TARGET_DIR="/home/lorenzo/Video/Convertiti"
# --- FINE CONFIGURAZIONE ---

mkdir -p "$CONVERT_TARGET_DIR"
if [ ! -d "$CONVERT_TARGET_DIR" ] || [ ! -w "$CONVERT_TARGET_DIR" ]; then
    zenity --error --text="Errore accesso directory intermedia:\n$CONVERT_TARGET_DIR" --width=400
    exit 1
fi

log_msg() { echo "$@" >&2; } # Funzione helper per messaggi di errore

for i in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS; do
    if [ ! -f "$i" ]; then continue; fi

    original_path="$i"
    base_name=$(basename "$i")
    intermediate_output="$CONVERT_TARGET_DIR/$base_name"
    failure_log="${intermediate_output}.log"

    attempt=0
    success=false
    rm -f "$failure_log" # Pulisce log vecchio PRIMA di iniziare i tentativi

    while [ $attempt -le $MAX_RETRIES ]; do
        current_attempt=$((attempt + 1))
        failed_this_attempt=false # Flag per l'attesa prima del retry

        ffmpeg_command=( ffmpeg -y -i "$original_path" -c:v libx265 -crf 23 -preset veryfast -threads 12 -x265-params hist-scenecut=1 -c:a copy "$intermediate_output" )

        # 1. Conversione
        if ! nice -n 5 "${ffmpeg_command[@]}"; then
            conv_exit_code=$?
            log_msg "ERROR: Conversione fallita '$base_name' (Tentativo $current_attempt, Code $conv_exit_code)."
            echo "ERRORE CONVERSIONE (Tentativo $current_attempt, Code $conv_exit_code): Impossibile processare '$original_path'." > "$failure_log"
            rm -f "$intermediate_output" # Pulisce output parziale
            failed_this_attempt=true
        else
            # 2. Verifica (solo se conversione OK)
            # Redirige stderr a log, fallisce se comando fallisce O se log non è vuoto
            if ! nice -n 5 ffmpeg -y -v error -i "$intermediate_output" -f null - 2>"$failure_log" || [ -s "$failure_log" ]; then
                verify_exit_code=$? # Approssimativo, cattura codice ffmpeg prima di ||
                log_msg "ERROR: Verifica fallita '$base_name' (Tentativo $current_attempt)."
                if [ ! -s "$failure_log" ]; then # Se log è vuoto ma comando fallito
                     echo "ERRORE VERIFICA (Tentativo $current_attempt, Code $verify_exit_code): Nessun output nel log." >> "$failure_log" # Aggiunge al log vuoto
                fi
                rm -f "$intermediate_output" # Pulisce output fallito
                failed_this_attempt=true
            else
                # 3. Spostamento/Sovrascrittura (solo se conversione e verifica OK)
                if ! mv -f "$intermediate_output" "$original_path"; then
                    mv_exit_code=$?
                    log_msg "ERROR: Spostamento fallito '$base_name' (Tentativo $current_attempt, Code $mv_exit_code)."
                    echo "ERRORE SPOSTAMENTO (Tentativo $current_attempt, Code $mv_exit_code): Impossibile sovrascrivere '$original_path'." > "$failure_log"
                    rm -f "$intermediate_output" # Pulisce intermedio che non si è potuto spostare
                    failed_this_attempt=true
                else
                    # SUCCESSO!
                    success=true
                    rm -f "$failure_log" # Pulisce log vuoto da verifica ok
                    break # Esce dal ciclo while (tentativi) per questo file
                fi
            fi
        fi

        # Logica Retry
        attempt=$((attempt + 1))
        if [ "$success" = false ] && [ $attempt -le $MAX_RETRIES ]; then
             sleep 3
        fi

    done # Fine ciclo while (tentativi)

    # Gestione Fallimento Finale (dopo tutti i tentativi)
    if [ "$success" = false ]; then
        fail_list="${fail_list}\n${base_name}"
        log_msg "FAIL: Operazione fallita definitivamente per '$base_name'."
        # Il log ($failure_log) dovrebbe essere già presente dall'ultimo tentativo fallito
        if [ ! -f "$failure_log" ]; then # Fallback se log manca inspiegabilmente
             echo "ERRORE FINALE: Fallimento per '$base_name' senza file di log." > "$failure_log"
             log_msg "WARN: Log di fallimento finale mancante per '$base_name', creato placeholder."
        fi
    fi

done # Fine ciclo for (files)

END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME-START_TIME))
log_msg "Script terminato in $ELAPSED_TIME secondi."

# --- Notifica Finale ---
if [ -n "$fail_list" ]; then
    fail_list=$(echo -e "$fail_list" | sed '/^$/d')
    zenity --error --title="Errore Conversione" --text="Operazione completata in $ELAPSED_TIME sec.\n\nFalliti (${fail_list//$'\n'/, }):\n\nControllare i file .log in '$CONVERT_TARGET_DIR'" --width=450 --height=250
else
    zenity --info --title="Conversione Completata" --text="Operazione completata in $ELAPSED_TIME secondi senza errori." --width=400
fi

exit 0