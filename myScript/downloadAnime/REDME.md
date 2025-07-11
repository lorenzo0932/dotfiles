# AniDownloader: Sistema di Download e Conversione Anime

Questo repository contiene uno script Python e i relativi file di configurazione e utility per automatizzare il download e la conversione degli episodi di anime.

## 1. `downloadAnime.sh` (Script Principale)

Questo è lo script Python principale che gestisce l'intero processo di download e conversione degli episodi degli anime.

**Funzionalità principali:**
- **Caricamento configurazione**: Legge i dati delle serie dal file `series_data.json` per sapere quali anime scaricare e dove salvarli.
- **Determinazione prossimo episodio**: Identifica l'ultimo episodio scaricato in una cartella specifica e calcola il numero del prossimo episodio da scaricare.
- **Download parallelo**: Utilizza `aria2c` per scaricare gli episodi in parallelo, ottimizzando la velocità di download.
- **Gestione continuazione serie**: Supporta serie che si estendono su più stagioni, rinominando i file in base alla numerazione complessiva degli episodi.
- **Conversione video**: Richiama lo script `Converti e verifica.sh` per convertire gli episodi scaricati in formato H.265, riducendo le dimensioni del file.
- **Resoconto finale**: Al termine dell'esecuzione, fornisce un riepilogo dettagliato degli episodi scaricati, lo stato delle conversioni e i tempi impiegati per ogni operazione.

**Dipendenze:**
- `python3`: Necessario per l'esecuzione dello script.
- `aria2c`: Strumento da riga di comando per il download accelerato.
- `ffmpeg`: Utilizzato dallo script `Converti e verifica.sh` per la conversione e verifica video.

## 2. `series_data.json` (File di Configurazione)

Questo file JSON è fondamentale per configurare le serie che `downloadAnime.sh` deve scaricare. **Non modificare direttamente `series_data.json` se non sai cosa stai facendo.**

Per aggiungere nuove serie o modificare quelle esistenti, fai riferimento al template `series_data_template.json`.

### Struttura degli oggetti serie:

Ogni oggetto all'interno dell'array JSON rappresenta una serie e deve contenere le seguenti proprietà:

- **`name`**: Il nome completo della serie.
- **`path`**: Il percorso locale completo dove gli episodi della serie verranno salvati, seguito dal numero della stagione (es: `/home/lorenzo/Video/Simulcast/NomeSerie/1`).
- **`link_pattern`**: Il pattern del link di download della serie. È cruciale sostituire il numero dell'episodio con `{ep}`. Esempio: `https://srv16-suisen.sweetpixel.org/DDL/ANIME/SentaiDaishikkaku2/SentaiDaishikkaku2_Ep_{ep}_SUB_ITA.mp4`.
- **`continue`**: (Opzionale) Un valore booleano (`true` o `false`). Imposta a `true` se la serie è una continuazione di una stagione precedente e la numerazione degli episodi deve tenere conto degli episodi già passati.
- **`passed_episodes`**: (Obbligatorio se `continue` è `true`) Un numero intero che definisce il totale degli episodi delle stagioni precedenti già scaricate.

**Esempio di struttura:**

```json
[
    {
        "name": "Nome Serie",
        "path": "path_della_serie_locale/numero_stagione",
        "link_pattern": "link_download_della_serie",
        "continue": true,
        "passed_episodes": 12
    },
    {
        "name": "Nome Serie2",
        "path": "path_della_serie_locale/numero_stagione",
        "link_pattern": "link_download_della_serie"
    }
]
```

## 3. `series_data_template.json` (Template di Configurazione)

Questo file serve come modello per la creazione o la modifica del file `series_data.json`.

**Istruzioni per l'utilizzo:**
1.  Apri `series_data_template.json`.
2.  **Elimina tutti i commenti** presenti nel file (le righe che iniziano con `//`).
3.  Modifica il contenuto aggiungendo le informazioni relative alle tue serie, seguendo la "Struttura degli oggetti serie" descritta sopra.
4.  Salva il file finale con il nome `series_data.json` (senza `_template`) nella stessa directory.

## 4. `Converti e verifica.sh` (Script di Utility)

Questo script Bash è un'utility richiamata da `downloadAnime.sh` per la conversione e la verifica dei file video.

**Funzionalità principali:**
- **Conversione H.265**: Utilizza `ffmpeg` per convertire i file video in input nel codec H.265, ottimizzando le dimensioni del file mantenendo una buona qualità.
- **Verifica integrità**: Dopo la conversione, `ffmpeg` viene utilizzato per verificare che il file convertito non contenga errori o corruzioni.
- **Gestione errori**: Se la conversione o la verifica falliscono, il file originale non viene eliminato e il file convertito (se creato) viene rimosso.
- **Rinomina e Spostamento**: In caso di successo, il file originale viene eliminato e il file convertito viene spostato nella directory corretta.

## 5. `AniDownloader.desktop` (Lanciatore Desktop)

Questo file è un'applicazione desktop per sistemi Linux (compatibile con ambienti desktop come GNOME, KDE, ecc.) che fornisce un modo semplice per avviare lo script `downloadAnime.sh` con un doppio click.

**Dettagli:**
- **`Name=AniDownloader`**: Il nome visualizzato dell'applicazione nel menu o sul desktop.
- **`Comment=Scarica tutti gli anime in simulcast configurati`**: Una breve descrizione della sua funzione.
- **`Path=/home/lorenzo/.local/share/myScript/downloadAnime/`**: Specifica la directory di lavoro da cui lo script `downloadAnime.sh` verrà eseguito.
- **`Exec=sh -c './downloadAnime.sh'`**: Il comando effettivo che viene eseguito quando si avvia l'applicazione.
- **`Icon=/home/lorenzo/.local/share/myScript/downloadAnime/logo.png`**: Il percorso dell'icona visualizzata per l'applicazione.
- **`Terminal=true`**: Indica che l'applicazione deve essere eseguita all'interno di una finestra di terminale, permettendo di visualizzare l'output dello script.
