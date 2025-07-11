#! /usr/bin/python3

import os
import re
import requests
import subprocess
import sys
from pathlib import Path
import shutil
import time
# Cambiamo l'importazione
import threading
import concurrent.futures # Preferibile a threading.Thread direttamente per un pool

# Definizione delle serie: per ciascuna fornisci nome, path locale e pattern del link
# ... (mantieni la lista delle serie identica) ...
series_list = [

    {
        "name": "Aru Majo ga Shinu Made",
        "path": "/home/lorenzo/Video/Simulcast/Aru Majo ga Shinu Made/1",
        "link_pattern": "https://srv12-terebi.sweetpixel.org/DDL/ANIME/AruMajoGaShinuMade/AruMajoGaShinuMade_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Danjoru",
        "path": "/home/lorenzo/Video/Simulcast/Danjoru/1",
        "link_pattern": "https://srv26-terebi.sweetpixel.org/DDL/ANIME/DanjoNoYuujouWaSeiritsuSuru/DanjoNoYuujouWaSeiritsuSuru_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Fire Force",
        "path": "/home/lorenzo/Video/Simulcast/Fire Force/3",
        "link_pattern": "https://srv16-suisen.sweetpixel.org/DDL/ANIME/FireForce3/FireForce3_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Haite Kudasai, Takamine-san",
        "path": "/home/lorenzo/Video/Simulcast/Haite Kudasai, Takamine-san/1",
        "link_pattern": "https://srv16-suisen.sweetpixel.org/DDL/ANIME/HaiteKudasaiTakamine-san/HaiteKudasaiTakamine-san_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "I Left My A-Rank Party to Help My Former Students Reach the Dungeon Depths!",
        "path": "/home/lorenzo/Video/Simulcast/I Left My A-Rank Party to Help My Former Students Reach the Dungeon Depths!/1",
        "link_pattern": "https://srv18-tsurukusa.sweetpixel.org/DDL/ANIME/Aparida/Aparida_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Kanchigai no Atelier Meister",
        "path": "/home/lorenzo/Video/Simulcast/Kanchigai no Atelier Meister/1",
        "link_pattern": "https://srv18-tsurukusa.sweetpixel.org/DDL/ANIME/KanchigaiNoAtelierMeister/KanchigaiNoAtelierMeister_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Katainaka no Ossan, Kensei ni Naru",
        "path": "/home/lorenzo/Video/Simulcast/Katainaka no Ossan, Kensei ni Naru/1",
        "link_pattern": "https://srv18-tsurukusa.sweetpixel.org/DDL/ANIME/KatainakaNoOssan/KatainakaNoOssan_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Kijin Gentoushou",
        "path": "/home/lorenzo/Video/Simulcast/Kijin Gentoushou/1",
        "link_pattern": "https://srv16-suisen.sweetpixel.org/DDL/ANIME/KijinGentoushou/KijinGentoushou_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Kusuriya no Hitorigoto",
        "path": "/home/lorenzo/Video/Simulcast/Kusuriya no Hitorigoto/1",
        "link_pattern": "https://srv18-tsurukusa.sweetpixel.org/DDL/ANIME/KusuriyaNoHitorigoto2/KusuriyaNoHitorigoto2_Ep_{ep}_SUB_ITA.mp4",
        "continue": True,
        "passed_episodes": 24
    },

    {
        "name": "My Happy Marriage 2",
        "path": "/home/lorenzo/Video/Simulcast/My Happy Marriage/2",
        "link_pattern": "https://srv21-airbus.sweetpixel.org/DDL/ANIME/WatashiNoShiawaseNaKekkon2/WatashiNoShiawaseNaKekkon2_Ep_{ep}_SUB_ITA.mp4"
    },


    {
        "name": "Saikyou no Ousama, Nidome no Jinsei wa Nani wo Suru?",
        "path": "/home/lorenzo/Video/Simulcast/Saikyou no Ousama, Nidome no Jinsei wa Nani wo Suru?/1",
        "link_pattern": "https://srv18-tsurukusa.sweetpixel.org/DDL/ANIME/SaikyouNoOusama/SaikyouNoOusama_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Slime Taoshite 300-nen, Shiranai Uchi ni Level Max ni Nattemashita",
        "path": "/home/lorenzo/Video/Simulcast/Slime Taoshite 300-nen, Shiranai Uchi ni Level Max ni Nattemashita/2",
        "link_pattern": "https://srv18-tsurukusa.sweetpixel.org/DDL/ANIME/SlimeTaoshite300-nen2/SlimeTaoshite300-nen2_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Witch Watch",
        "path": "/home/lorenzo/Video/Simulcast/Witch Watch/1",
        "link_pattern": "https://srv21-airbus.sweetpixel.org/DDL/ANIME/WitchWatch/WitchWatch_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Yami Healer",
        "path": "/home/lorenzo/Video/Simulcast/Yami Healer/1",
        "link_pattern": "https://srv16-suisen.sweetpixel.org/DDL/ANIME/YamiHealer/YamiHealer_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Your Forma",
        "path": "/home/lorenzo/Video/Simulcast/Your Forma/1",
        "link_pattern": "https://srv15-kobe.sweetpixel.org/DDL/ANIME/YourForma/YourForma_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Gorilla no Kami kara Kago sareta Reijou wa Ouritsu Kishidan de Kawaigarareru",
        "path": "/home/lorenzo/Video/Simulcast/Gorilla no Kami kara Kago sareta Reijou wa Ouritsu Kishidan de Kawaigarareru/1",
        "link_pattern": "https://srv16-suisen.sweetpixel.org/DDL/ANIME/GorillaLady/GorillaLady_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Kowloon Generic Romance",
        "path": "/home/lorenzo/Video/Simulcast/Kowloon Generic Romance/1",
        "link_pattern": "https://srv21-airbus.sweetpixel.org/DDL/ANIME/KowloonGenericRomance/KowloonGenericRomance_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Summer Pockets",
        "path": "/home/lorenzo/Video/Simulcast/Summer Pockets/1",
        "link_pattern": "https://srv30-emiko.sweetpixel.org/DDL/ANIME/SummerPockets/SummerPockets_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Shiunji-ke no Kodomotachi",
        "path": "/home/lorenzo/Video/Simulcast/Shiunji-ke no Kodomotachi/1",
        "link_pattern": "https://srv14-yuzu.sweetpixel.org/DDL/ANIME/Shiunji-keNoKodomotachi/Shiunji-keNoKodomotachi_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Kanpeki Sugite Kawai-ge ga Nai to Konyaku Haki Sareta Seijo wa Ringoku ni Urareru",
        "path": "/home/lorenzo/Video/Simulcast/Kanpeki Sugite Kawai-ge ga Nai to Konyaku Haki Sareta Seijo wa Ringoku ni Urareru/1",
        "link_pattern": "https://srv26-terebi.sweetpixel.org/DDL/ANIME/Kanpekiseijo/Kanpekiseijo_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Shin Samurai-den YAIBA",
        "path": "/home/lorenzo/Video/Simulcast/Shin Samurai-den YAIBA/1",
        "link_pattern": "https://srv14-yuzu.sweetpixel.org/DDL/ANIME/ShinSamurai-denYaiba/ShinSamurai-denYaiba_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Sentai Daishikkaku",
        "path": "/home/lorenzo/Video/Simulcast/Sentai Daishikkaku/1",
        "link_pattern": "https://srv16-suisen.sweetpixel.org/DDL/ANIME/SentaiDaishikkaku2/SentaiDaishikkaku2_Ep_{ep}_SUB_ITA.mp4",
        "continue": True,
        "passed_episodes": 12
    },

    # Aggiungi ulteriori serie se necessario
]


def get_next_episode(series_path):
    """
        Cerca nella cartella indicata (non ricorsivamente) tutti i file .mp4 e restituisce il numero
        dell'episodio successivo da scaricare (max trovato + 1). Se non vengono trovati file, restituisce 1.
        """
    files = os.listdir(series_path)
    max_ep = 0
    for file in files:
        if file.endswith('.mp4'):
            # Estrae il numero dell'episodio cercando la stringa "Ep_" seguita da uno o più numeri
            match = re.search(r'Ep_(\d+)', file)
            if match:
                ep_num = int(match.group(1))
                if ep_num > max_ep:
                    max_ep = ep_num
    return max_ep + 1 if max_ep > 0 else 1


def format_episode_number(ep):
    """
        Formatta il numero dell'episodio:
        - Se è inferiore a 10, restituisce una stringa con padding (es. "01")
        - Altrimenti restituisce la stringa senza padding (es. "10")
        """
    return f"{ep:02d}" if ep < 10 else str(ep)


def download_episode_with_aria2(series):
    """
        Costruisce l'URL di download sostituendo il placeholder {ep} nel pattern, quindi
        utilizza aria2c per scaricare il file in parallelo.
        Gestisce anche il rinomino dei file in caso di 'continue' attivo.
        """
    name = series["name"]
    path = series["path"]
    link_pattern = series["link_pattern"]
    is_continuation = series.get("continue", False)  # Default to False if not present
    passed_episodes = series.get("passed_episodes", 0)  # Default to 0 if not present

    # Calcola il prossimo episodio da scaricare (numerazione interna alla stagione) e se è una continuazione il numero finale è calcolato in base al numero di episodi passati
    if is_continuation:
        final_ep_number = get_next_episode(path)
        # Se il prossimo episodio finale è 1 (cartella vuota) ma è una continuazione, significa che non
        # dovremmo iniziare da 1, ma dal primo episodio *della nuova stagione*.
        # Dobbiamo determinare il *primo* episodio da scaricare nella nuova stagione.
        # Questo è l'episodio passato + 1. La numerazione interna per il download DEVE iniziare da 1
        # per corrispondere al pattern del link, ma il numero finale del file sarà ep_passati + ep_scaricati_della_nuova_stagione.
        # Se final_ep_number è 1, significa che nessun episodio della NUOVA stagione è presente.
        # Il numero da usare nel link pattern (che inizia da 1 per ogni stagione) sarà 1.
        # Il numero finale del file sarà passed_episodes + 1.

        # Calcola il prossimo numero di episodio *nella directory locale*
        next_ep_local = get_next_episode(path)

        # Se la directory è vuota (next_ep_local è 1), il primo episodio da scaricare per questa
        # stagione (dal link pattern) sarà 1. Il numero finale del file sarà passed_episodes + 1.
        # Se la directory non è vuota (next_ep_local > 1), l'episodio successivo da scaricare
        # dal link pattern sarà next_ep_local. Il numero finale del file sarà passed_episodes + next_ep_local.

        next_ep_download = next_ep_local # Il numero da usare nel link pattern parte sempre da 1 per ogni stagione

        # Il numero finale per il nome del file locale sarà passed_episodes + il numero scaricato nella nuova stagione
        final_ep_number = passed_episodes + next_ep_local

        print(f"[{name}] Continuazione attiva. Prossimo ep locale: {next_ep_local}, Prossimo ep download (link): {next_ep_download}, Numero finale file: {final_ep_number}")

    else :
        next_ep_download = get_next_episode(path)
        final_ep_number = next_ep_download # Se non è una continuazione, i numeri coincidono


    ep_str_download = format_episode_number(next_ep_download)
    download_url = link_pattern.format(ep=ep_str_download)
    print(f"[{name}] Tentativo di download episodio {next_ep_download} (numerazione link) -> URL: {download_url}")

    # Estrae il nome del file dalla URL
    # Usiamo il numero dell'episodio *dal link pattern* per costruire il nome del file scaricato inizialmente
    # perché è quello che aria2c userà di default se non specifichiamo diversamente nel nome di output
    downloaded_file_name = download_url.split("/")[-1]
    output_file_path_download = os.path.join(path, downloaded_file_name)

    # Costruisce il comando aria2c; -x e -s definiscono il numero di connessioni parallelle
    # Specifichiamo il nome del file di output ESPLICITAMENTE per controllare il nome iniziale prima del rinomino
    cmd = ["aria2c", "-x", "16", "-s", "16", "-o", downloaded_file_name, download_url]
    # print(f"[{name}] Avvio aria2c per il download: {' '.join(cmd)}") # Commentato per pulizia log

    # Imposta la directory corrente per il comando in modo che il file venga salvato in 'path'
    start_time = time.time()
    # Utilizziamo capture_output=True e text=True per catturare stdout/stderr per debug se necessario
    # ma per semplicità e per mantenere il comportamento originale che stampa output direttamente
    # useremo solo `subprocess.run` senza cattura, affidandoci all'output di aria2c.
    try:
        result = subprocess.run(cmd, cwd=path, check=True) # check=True solleva eccezione in caso di errore
        print(f"[{name}] Episodio {next_ep_download} (numerazione link) scaricato con successo!")

        # Ora gestiamo il rinomino se necessario
        final_file_path = output_file_path_download # Percorso iniziale del file scaricato

        if is_continuation:
            # Calcola il nome del file finale basato sul numero di episodio finale corretto
            ep_str_final = format_episode_number(final_ep_number)

            # Costruisci il nome file finale basato sul nome originale scaricato e il numero episodio finale
            # Cerchiamo e sostituiamo specificamente la parte _Ep_XX_SUB_ITA
            # Esempio: "Serie_Ep_01_SUB_ITA.mp4" -> Sostituisco "Ep_01" con "Ep_25" per ottenere "Serie_Ep_25_SUB_ITA.mp4"
            # Questo è più robusto di una semplice sostituzione di stringa se il numero scaricato appare altrove
            base_filename = downloaded_file_name
            # Trova il pattern Ep_XX
            match_ep_download = re.search(r'_Ep_\d+', base_filename)
            if match_ep_download:
                 # Sostituisci il pattern trovato con il pattern del numero finale
                base_filename = base_filename.replace(match_ep_download.group(0), f'_Ep_{ep_str_final}')
            else:
                 # Fallback meno sicuro se il pattern Ep_XX non viene trovato
                 print(f"[{name}] Attenzione: pattern 'Ep_\\d+' non trovato nel nome file scaricato '{downloaded_file_name}'. Tentativo di rinomino parziale.")
                 # Potrebbe essere necessario un pattern più sofisticato o una logica diversa
                 # Per ora, usiamo una sostituzione semplice come fallback (meno sicuro)
                 base_filename = downloaded_file_name.replace(f"_Ep_{ep_str_download}", f"_Ep_{ep_str_final}")


            final_file_path = os.path.join(path, base_filename)

            # Rinomina il file se il nome è diverso
            if output_file_path_download != final_file_path:
                try:
                    os.rename(output_file_path_download, final_file_path)
                    print(f"[{name}] File rinominato in: {final_file_path}")
                except OSError as e:
                    print(f"[{name}] Errore durante il rinomino del file '{output_file_path_download}' a '{final_file_path}': {e}")
                    return None, None # Ritorna None per indicare fallimento

        end_time = time.time()
        download_time = end_time - start_time

        return final_file_path, download_time

    except FileNotFoundError:
        print(f"[{name}] Errore: 'aria2c' non trovato. Assicurati che sia installato e nel PATH.")
        return None, None
    except subprocess.CalledProcessError as e:
        print(f"[{name}] Download fallito con aria2c (return code: {e.returncode}). URL: {download_url}")
        # Puoi stampare e.stdout e e.stderr se hai usato capture_output=True
        return None, None
    except Exception as e:
        print(f"[{name}] Errore generico durante il download con aria2c: {e}")
        return None, None


def convertToH265(episode_path):
    """
    Converte un file video in H.265 utilizzando uno script esterno e gestisce lo spostamento.
    """
    # Salvo il nome del file
    file_basename = os.path.basename(episode_path)
    file_dir = os.path.dirname(episode_path) # Directory originale del file

    # Imposta la variabile di ambiente che si aspetta Nautilus
    env = os.environ.copy()
    env["NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"] = episode_path

    # Specifica il path dello scritp Nautilus. Lo script converte il file, verifica la conversione ed elimina l'originale.
    # Assumiamo che lo script sia nella stessa directory dello script Python corrente
    script_dir = Path(__file__).parent # Directory dello script Python corrente
    script_path = script_dir / "Converti e verifica.sh"
    script_path_str = str(script_path.resolve()) # Ottieni il path assoluto risolto

    # Verifico che lo script da eseguire esista e sia eseguibile
    if not os.path.isfile(script_path_str):
        print(f"Errore: Lo script di conversione {script_path_str} non esiste.")
        return False, 0 # Ritorna False e tempo 0 per indicare fallimento

    if not os.access(script_path_str, os.X_OK):
        print(f"Errore: Lo script di conversione {script_path_str} non è eseguibile.")
        return False, 0 # Ritorna False e tempo 0 per indicare fallimento

    # Definisci la directory di destinazione temporanea dello script di conversione
    # Dallo script originale, sembra che sposti il file convertito qui temporaneamente.
    converted_temp_dir = "/run/media/lorenzo/SSD Sata/Convertiti/"
    # Costruisci il path temporaneo previsto per il file convertito
    converted_temp_path = os.path.join(converted_temp_dir, file_basename)


    success = False
    count = 1
    start_time = time.time()
    while not success and count <= 3: # Tentiamo fino a 3 volte
        print(f"Avvio conversione (Tentativo {count}/3) per {file_basename}")
        try:
            # Avvia lo script passando l'ambiente con la variabile di ambiente impostata in precedenza
            # check=True solleva eccezione in caso di errore del script
            result = subprocess.run([script_path_str], env=env, check=True)
            print(f"Script di conversione eseguito con codice {result.returncode}")

            # Lo script Converti e Verifica.sh dovrebbe ELIMINARE l'originale
            # e posizionare il convertito in /run/media/lorenzo/SSD Sata/Convertiti/
            # Quindi, se l'originale NON esiste più, la conversione è avvenuta con successo
            # E dobbiamo spostare il file convertito dalla temp dir alla sua posizione originale

            if not os.path.exists(episode_path):
                 # L'originale è stato eliminato dallo script, conversione riuscita
                 success = True
                 print(f"Conversione H265 riuscita per {file_basename}. Originale eliminato.")
                 break # Esci dal ciclo while

            else:
                 # L'originale ESISTE ancora, significa che lo script non lo ha eliminato.
                 # Questo può accadere se la conversione interna (ffmpeg) fallisce o se lo script ha un errore.
                 # Verifichiamo se il file convertito *esiste* nella temp dir. Se sì, potrebbe essere solo
                 # lo spostamento finale o l'eliminazione dell'originale ad essere falliti nello script esterno.
                 # In questo caso, proviamo a pulire e riprovare, o segnaliamo un problema.
                 if os.path.exists(converted_temp_path):
                      print(f"[{file_basename}] Trovato file convertito temporaneo in {converted_temp_path} ma l'originale esiste ancora. Possibile errore nello script esterno. Rimuovo temporaneo e riprovo.")
                      try:
                          os.remove(converted_temp_path) # Pulisci il file convertito parziale/fallito
                      except OSError as e:
                          print(f"Errore durante la rimozione del file temporaneo {converted_temp_path}: {e}")

                 print(f"[{file_basename}] Conversione fallita o script esterno incompleto (Originale esiste ancora), riprova.")
                 count += 1
                 time.sleep(2) # Breve pausa prima di riprovare


        except FileNotFoundError:
            print(f"Errore: Lo script di conversione {script_path_str} non trovato durante l'esecuzione.")
            break # Esci dal ciclo, non ha senso riprovare se lo script non c'è
        except subprocess.CalledProcessError as e:
            print(f"Errore: Lo script di conversione ha fallito con codice {e.returncode} per {file_basename}.")
            # Puoi stampare e.stdout e e.stderr se usi capture_output=True nello script esterno
            count += 1
            time.sleep(2) # Breve pausa prima di riprovare
        except Exception as e:
             print(f"Errore inatteso durante l'esecuzione dello script di conversione per {file_basename}: {e}")
             count += 1
             time.sleep(2) # Breve pausa prima di riprovare


    end_time = time.time()
    conversion_time = end_time - start_time

    if success:
        # Se la conversione è avvenuta con successo (originale eliminato), sposta il file convertito
        # dalla directory temporanea alla sua posizione originale.
        try:
            if os.path.exists(converted_temp_path):
                 shutil.move(converted_temp_path, episode_path)
                 print(f"[{file_basename}] File convertito spostato da {converted_temp_path} a {episode_path}")
                 return True, conversion_time
            else:
                 print(f"[{file_basename}] ERRORE GRAVE: Conversione riportata come successo (originale eliminato) ma il file convertito {converted_temp_path} non trovato nella directory temporanea!")
                 return False, conversion_time # Segnala fallimento se il file convertito non c'è
        except FileNotFoundError:
             print(f"[{file_basename}] ERRORE GRAVE: Il file convertito temporaneo {converted_temp_path} non esiste durante lo spostamento!")
             return False, conversion_time
        except Exception as e:
             print(f"[{file_basename}] ERRORE durante lo spostamento del file convertito: {e}")
             # Potresti voler provare a rimuovere il file temporaneo qui se lo spostamento fallisce
             if os.path.exists(converted_temp_path):
                  try:
                       os.remove(converted_temp_path)
                       print(f"[{file_basename}] Rimosso file temporaneo {converted_temp_path} dopo errore spostamento.")
                  except OSError as err_rm:
                       print(f"Errore ulteriore rimuovendo temporaneo {converted_temp_path}: {err_rm}")
             return False, conversion_time
    else:
        print(f"[{file_basename}] Conversione non riuscita dopo {count-1} tentativi.")
        # Se la conversione non è riuscita dopo i tentativi, e l'originale esiste ancora,
        # potresti voler spostare l'originale da qualche altra parte per ispezione,
        # o lasciarlo lì (come fa attualmente il codice originale).
        # Se lo script esterno ha lasciato un file nella temp dir, potresti volerlo rimuovere.
        if os.path.exists(converted_temp_path):
             print(f"[{file_basename}] Rimuovendo file temporaneo {converted_temp_path} di conversione fallita.")
             try:
                  os.remove(converted_temp_path)
             except OSError as e:
                   print(f"Errore durante la rimozione del file temporaneo {converted_temp_path}: {e}")

        return False, conversion_time


def process_series(series):
    """
    Processa una singola serie: download e conversione.
    Restituisce un dizionario con i risultati.
    """
    name = series["name"]
    print(f"Inizio processo per la serie: {name}")
    try:
        # Scarica un episodio se necessario
        episode_path, download_time = download_episode_with_aria2(series)

        if episode_path:
            # Converte in h265
            conversion_result, conversion_time = convertToH265(episode_path)
            return {
                "name": name,
                "episode_path": episode_path, # Restituiamo il percorso finale del file
                "download_time": download_time,
                "conversion_result": conversion_result,
                "conversion_time": conversion_time,
                "status": "processed" # Stato per indicare che il download è avvenuto e la conversione è stata tentata
            }
        else:
             # Download fallito
             return {
                "name": name,
                "episode_path": None,
                "download_time": 0,
                "conversion_result": False, # Nessuna conversione tentata
                "conversion_time": 0,
                "status": "download_failed" # Stato per indicare che il download è fallito
            }
    except Exception as e:
        print(f"Errore critico durante il processamento della serie {name}: {e}")
        return {
            "name": name,
            "episode_path": None,
            "download_time": 0,
            "conversion_result": False,
            "conversion_time": 0,
            "status": "critical_error", # Stato per indicare un errore inatteso
            "error_message": str(e)
        }


if __name__ == '__main__':
    # Inizializzazione delle variabili per il resoconto
    # Usiamo liste separate per tenere traccia dei successi/fallimenti per il resoconto finale
    processed_episodes_results = []
    download_times = {} # Dictionary: episode_path -> time
    conversion_times = {} # Dictionary: episode_path -> time
    total_conversion_time = 0
    total_download_time = 0
    script_start_time = time.time()

    # Utilizza ThreadPoolExecutor per eseguire le funzioni in parallelo con i thread
    # Puoi regolare il numero max_workers. Per operazioni I/O-bound (attesa di rete/processi esterni)
    # un numero maggiore dei core CPU è spesso vantaggioso.
    # Usiamo un valore ragionevole, ad esempio 10 thread al massimo, o il numero di serie se sono meno.
    max_threads = min(16, len(series_list)) # Scegli un numero massimo di thread sensato
    print(f"Avvio ThreadPoolExecutor con {max_threads} thread...")

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_threads) as executor:
        # Sottomette le funzioni process_series per ciascuna serie
        # executor.map invia i task e restituisce un iteratore che produce i risultati
        # nell'ordine in cui i task sono stati inviati.
        futures = [executor.submit(process_series, series) for series in series_list]

        # Elabora i risultati man mano che sono pronti (o nell'ordine di sottomissione con map)
        # Usiamo as_completed per elaborare i risultati appena sono pronti, indipendentemente dall'ordine di sottomissione.
        # Se l'ordine è importante, si può usare map. Manteniamo map per coerenza con la versione multiprocessing.
        # results = executor.map(process_series, series_list) # Questo blocca e ritorna in ordine
        # Usiamo as_completed per un feedback più rapido quando un task finisce
        for future in concurrent.futures.as_completed(futures):
             try:
                 result = future.result() # Ottiene il risultato (o solleva l'eccezione)
                 processed_episodes_results.append(result)
             except Exception as exc:
                 # Gestisci eccezioni che non sono state catturate all'interno di process_series
                 print(f'Un task ha generato un\'eccezione: {exc}')
                 # Aggiungi un risultato di errore alla lista
                 processed_episodes_results.append({"name": "Errore Sconosciuto", "episode_path": None, "status": "executor_exception", "error_message": str(exc), "download_time": 0, "conversion_time": 0, "conversion_result": False})


    # Elabora i risultati raccolti
    downloaded_episodes_paths = []
    conversion_successes_paths = [] # Per tenere traccia dei path convertiti con successo
    failed_downloads = []
    critical_errors = []
    executor_exceptions = []


    for result in processed_episodes_results:
        if result["status"] == "processed":
            downloaded_episodes_paths.append(result["episode_path"])
            download_times[result["episode_path"]] = result["download_time"]
            total_download_time += result["download_time"]

            if result["conversion_result"]:
                conversion_successes_paths.append(result["episode_path"])
                conversion_times[result["episode_path"]] = result["conversion_time"]
                total_conversion_time += result["conversion_time"]
            # else: La conversione ha fallito, non aggiungiamo a conversion_successes_paths

        elif result["status"] == "download_failed":
             print(f"Download fallito per serie: {result['name']}")
             failed_downloads.append(result["name"])

        elif result["status"] == "critical_error":
             print(f"Errore critico per serie {result['name']}: {result['error_message']}")
             critical_errors.append(result)

        elif result["status"] == "executor_exception":
             print(f"Eccezione dall'executor per task: {result['error_message']}")
             executor_exceptions.append(result)


    script_end_time = time.time()
    script_total_time = script_end_time - script_start_time

    # Calcola la velocità media di download (se ci sono episodi scaricati)
    average_download_speed_mbps = 0
    if downloaded_episodes_paths:
        # Ottieni la dimensione totale dei file scaricati
        total_size = sum([os.path.getsize(ep) for ep in downloaded_episodes_paths if os.path.exists(ep)]) # Assicurati che il file esista ancora
        average_download_speed = total_size / total_download_time if total_download_time > 0 else 0
        # Converto da byte/secondo a MB/secondo
        average_download_speed_mbps = average_download_speed / (1024 * 1024)


    # Stampa il resoconto
    print("\n--- Resoconto ---")

    print(f"\nEpisodi processati con download riuscito ({len(downloaded_episodes_paths)}):")
    if downloaded_episodes_paths:
        for episode_path in downloaded_episodes_paths:
            print(f"- {episode_path}")
    else:
        print("Nessun episodio scaricato con successo.")

    print(f"\nStato conversioni ({len(downloaded_episodes_paths)} tentate):")
    if downloaded_episodes_paths:
        for episode_path in downloaded_episodes_paths:
            status = "Successo" if episode_path in conversion_successes_paths else "Fallimento"
            print(f"- {episode_path}: {status}")
    else:
         print("Nessuna conversione tentata.")


    if failed_downloads:
         print(f"\nDownload falliti ({len(failed_downloads)}):")
         for name in failed_downloads:
              print(f"- {name}")

    if critical_errors:
         print(f"\nErrori critici ({len(critical_errors)}):")
         for error_info in critical_errors:
              print(f"- Serie {error_info['name']}: {error_info['error_message']}")

    if executor_exceptions:
        print(f"\nEccezioni nell'executor ({len(executor_exceptions)}):")
        for error_info in executor_exceptions:
             print(f"- {error_info['error_message']}")


    print(f"\nVelocità media di download (basata sui file scaricati con successo): {average_download_speed_mbps:.2f} MB/s")
    print(f"Tempo totale di esecuzione dello script: {script_total_time:.2f} secondi")

    print("\nDettagli tempi per episodi scaricati con successo:")
    if downloaded_episodes_paths:
        print("- Tempi download per episodio:")
        for episode_path in downloaded_episodes_paths:
            time_taken = download_times.get(episode_path, 0) # Usa .get per sicurezza
            print(f"  - {os.path.basename(episode_path)}: {time_taken:.2f} secondi")

        print("- Tempi conversione per episodio (riusciti):")
        if conversion_successes_paths:
             for episode_path in conversion_successes_paths:
                  time_taken = conversion_times.get(episode_path, 0) # Usa .get per sicurezza
                  print(f"  - {os.path.basename(episode_path)}: {time_taken:.2f} secondi")
        else:
            print("  Nessuna conversione riuscita con dettaglio tempo disponibile.")

        print(f"- Tempo totale solo conversioni riuscite: {total_conversion_time:.2f} secondi")
        print(f"- Tempo totale solo download riusciti: {total_download_time:.2f} secondi")
    else:
        print("Nessun dettaglio tempi disponibile in quanto nessun episodio è stato scaricato con successo.")