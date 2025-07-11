#! /usr/bin/python3

import os
import re
import requests
import subprocess
import sys
from pathlib import Path
import shutil
import time

# Definizione delle serie: per ciascuna fornisci nome, path locale e pattern del link
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
        "continue" : True,
        "passed_episodes": 24
    },

    {
        "name": "My Happy Marriage 2",
        "path": "/home/lorenzo/Video/Simulcast/My Happy Marriage/2",
        "link_pattern": "https://srv21-airbus.sweetpixel.org/DDL/ANIME/WatashiNoShiawaseNaKekkon2/WatashiNoShiawaseNaKekkon2_Ep_{ep}_SUB_ITA.mp4"
    },


    {
        "name": "Saikyou no Ousama, Nidome no Jinsei wa Nani wo Suru?",
        "path": "/home/lorenzo/Video/Simulcast/Saikyou no Ousama, Nidome no Jinsei wa Nani wo Suru?/1",  # Inserisci il path corretto
        "link_pattern": "https://srv18-tsurukusa.sweetpixel.org/DDL/ANIME/SaikyouNoOusama/SaikyouNoOusama_Ep_{ep}_SUB_ITA.mp4"
    },

    {
        "name": "Slime Taoshite 300-nen, Shiranai Uchi ni Level Max ni Nattemashita",
        "path": "/home/lorenzo/Video/Simulcast/Slime Taoshite 300-nen, Shiranai Uchi ni Level Max ni Nattemashita/2",  # Inserisci il path corretto
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
        "link_pattern": "https://srv16-suisen.sweetpixel.org/DDL/ANIME/SentaiDaishikkaku2/SentaiDaishikkaku2_Ep_{ep}_SUB_ITA.mp4", # 
        "continue": True,
        "passed_episodes": 12 # Number of episodes in season 1
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
    Formattta il numero dell'episodio:
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
    is_continuation = series.get("continue", False) # Default to False if not present
    passed_episodes = series.get("passed_episodes", 0) # Default to 0 if not present

    # Calcola il prossimo episodio da scaricare (numerazione interna alla stagione) e se è una continuazione il numero finale è calcolato in base al numero di episodi passati
    if is_continuation:
        next_ep_download = get_next_episode(path) - passed_episodes
        final_ep_number = next_ep_download + passed_episodes
    else:
        next_ep_download = get_next_episode(path)
    ep_str_download = format_episode_number(next_ep_download)

    # Costruisce l'URL sostituendo il placeholder con la numerazione per il download
    download_url = link_pattern.format(ep=ep_str_download)
    print(f"[{name} Tentativo di download episodio {next_ep_download} (download num) -> URL: {download_url}")

    # Estrae il nome del file dalla URL
    downloaded_file_name = download_url.split("/")[-1]
    output_file_path_download = os.path.join(path, downloaded_file_name)


    # Costruisce il comando aria2c; -x e -s definiscono il numero di connessioni parallelle
    cmd = ["aria2c", "-x", "16", "-s", "16", "-o", downloaded_file_name, download_url]
    print(f"[{name}] Avvio aria2c per il download: {' '.join(cmd)}")

    # Imposta la directory corrente per il comando in modo che il file venga salvato in 'path'
    start_time = time.time()
    result = subprocess.run(cmd, cwd=path)
    end_time = time.time()
    download_time = end_time - start_time

    if result.returncode == 0:
        print(f"[{name}] Episodio {next_ep_download} (download num) scaricato con successo!")


        final_file_path = output_file_path_download # Initialize with download path

        if is_continuation:
            # Calcola il numero di episodio finale (considerando gli episodi precedenti)
            ep_str_final = format_episode_number(final_ep_number)

            # Costruisci il nome file finale basato sul pattern e il numero episodio finale
            base_filename = downloaded_file_name.replace(f"_Ep_{ep_str_download}", f"_Ep_{ep_str_final}") # Simple replace, might need more robust logic if filenames are very different

            final_file_path = os.path.join(path, base_filename)


            # Rinomina il file
            try:
                os.rename(output_file_path_download, final_file_path)
                print(f"[{name}] File rinominato in: {final_file_path}")
            except OSError as e:
                print(f"[{name}] Errore durante il rinomino del file: {e}")
                return None, None # Return None to indicate failure

        return final_file_path, download_time
    else:
        print(f"[{name}] Download fallito con aria2c (return code: {result.returncode}).")
        return None, None


def convertToH265(episode_path):
    # Salvo il nome del file
    file_basename = os.path.basename(episode_path)

    # Imposta la variabile di ambiente che si aspetta Nautilus
    env = os.environ.copy()
    env["NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"] = episode_path

    # Specifica il path dello scritp Nautilus. Lo script converte il file, verifica la conversione ed elimina l'originale.
    script_path = "./Converti e verifica.sh"

    #Verifico che lo script da eseguire esista e sia eseguibile
    if not os.path.isfile(script_path):
        print(f"Lo script {script_path} non esiste")
        sys.exit(1)

    if not os.access(script_path, os.X_OK):
        print(f"Lo script {script_path} non è eseguibile")
        sys.exit(1)

    success = 0
    count = 1
    start_time = time.time()
    while success == 0 and count <= 2:
        # Avvia lo script passando l'ambiente con la variabile di ambiente impostata in precedenza
        result = subprocess.run([script_path], env = env)
        # Se il file non è stato eliminato secondo le specifiche di Converti e Verifica.sh allora la conversione è fallita
        if os.path.exists(episode_path):
            print("Conversione fallita, riprova")
            count = count + 1
        else:
            success = 1
    end_time = time.time()
    conversion_time = end_time - start_time

    if success == 0:
        print("Errore: conversione non riuscita dopo 3 tentativi")
        return None, None

# Se la conversione è avvenuta con successo, sposta il file convertito nella directory corretta
    converted_file_path = f"/run/media/lorenzo/SSD Sata/Convertiti/{file_basename}"
    shutil.move(converted_file_path, episode_path)
    return True, conversion_time


# Inizializzazione delle variabili per il resoconto
downloaded_episodes = []
conversion_successes = []
download_times = {}
conversion_times = {}
total_conversion_time = 0
total_download_time = 0
script_start_time = time.time()

# Per ogni serie, esegue il controllo e tenta il download del nuovo episodio
for series in series_list:
    # Scarica un episodio se necessario e lo converte in h265
    Episode, download_time = download_episode_with_aria2(series)
    if (Episode != None):
        downloaded_episodes.append(Episode)
        download_times[Episode] = download_time
        total_download_time += download_time
        conversion_result, conversion_time = convertToH265(Episode)
        if (conversion_result == True):
            conversion_successes.append(Episode)
            conversion_times[Episode] = conversion_time
            total_conversion_time += conversion_time
        else:
            conversion_successes.append(False)


script_end_time = time.time()
script_total_time = script_end_time - script_start_time

# Calcola la velocità media di download (se ci sono episodi scaricati)
if downloaded_episodes:
    # Ottieni la dimensione totale dei file scaricati
    total_size = sum([os.path.getsize(ep) for ep in downloaded_episodes])
    average_download_speed = total_size / total_download_time if total_download_time > 0 else 0
    # Converto da byte/secondo a MB/secondo
    average_download_speed_mbps = average_download_speed / (1024 * 1024)
else:
    average_download_speed_mbps = 0

# Stampa il resoconto
print("\n--- Resoconto ---")
print("Episodi scaricati:")
for episode in downloaded_episodes:
    print(f"- {episode}")

print("\nStato conversioni:")
for episode in downloaded_episodes:
    if episode in conversion_successes:
        print(f"- {episode}: Successo")
    else:
        print(f"- {episode}: Fallimento")

print(f"\nVelocità media di download: {average_download_speed_mbps:.2f} MB/s")
print(f"Tempo totale di esecuzione dello script: {script_total_time:.2f} secondi")

print("\nDettagli tempi:")
print("- Tempi download per episodio:")
for episode, time in download_times.items():
    print(f"  - {episode}: {time:.2f} secondi")

print("- Tempi conversione per episodio:")
for episode, time in conversion_times.items():
    print(f"  - {episode}: {time:.2f} secondi")

print(f"- Tempo totale solo conversioni: {total_conversion_time:.2f} secondi")
print(f"- Tempo totale solo download: {total_download_time:.2f} secondi")
