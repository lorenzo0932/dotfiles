#!/usr/bin/env python3

import os
import re
import subprocess
import time
import shutil
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

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
        "link_pattern": "https://srv16-suisen.sweetpixel.org/DDL/ANIME/SentaiDaishikkaku2/SentaiDaishikkaku2_Ep_{ep}_SUB_ITA.mp4",  #
        "continue": True,
        "passed_episodes": 12  # Number of episodes in season 1
    },


    # Aggiungi ulteriori serie se necessario
]

def get_next_episode(series_path):
    files = os.listdir(series_path)
    max_ep = 0
    for file in files:
        if file.endswith('.mp4'):
            match = re.search(r'Ep_(\d+)', file)
            if match and (ep_num := int(match.group(1))) > max_ep:
                max_ep = ep_num
    return max_ep + 1 if max_ep > 0 else 1

def format_episode_number(ep):
    return f"{ep:02d}" if ep < 10 else str(ep)

def download_episode(series):
    name = series["name"]
    path = series["path"]
    link_pattern = series["link_pattern"]
    is_cont = series.get("continue", False)
    passed = series.get("passed_episodes", 0)

    raw_next = get_next_episode(path)
    final_ep = raw_next if not is_cont else raw_next
    dl_index = raw_next if not is_cont else raw_next - passed
    ep_str = format_episode_number(dl_index)
    url = link_pattern.format(ep=ep_str)

    out_name = url.split("/")[-1]
    start = time.time()
    res = subprocess.run(
        ["aria2c", "-x", "16", "-s", "16", "-o", out_name, url],
        cwd=path
    )
    dt = time.time() - start

    if res.returncode != 0:
        print(f"[{name}] Download fallito.")
        return None, None

    downloaded = os.path.join(path, out_name)
    if is_cont:
        ep_str_final = format_episode_number(final_ep)
        new_name = out_name.replace(f"_Ep_{ep_str}", f"_Ep_{ep_str_final}")
        final_path = os.path.join(path, new_name)
        try:
            os.rename(downloaded, final_path)
            downloaded = final_path
        except OSError as e:
            print(f"[{name}] Rinomina fallita: {e}")
            return None, None

    print(f"[{name}] Episodio scaricato: {downloaded}")
    return downloaded, dt

def convert_to_h265(ep_path):
    env = os.environ.copy()
    env["NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"] = ep_path
    script = "./Converti e verifica.sh"
    if not (os.path.isfile(script) and os.access(script, os.X_OK)):
        print(f"Script di conversione non disponibile o non eseguibile.")
        return False, 0

    attempts, success = 0, False
    start = time.time()
    while attempts < 2 and not success:
        res = subprocess.run([script], env=env)
        if not os.path.exists(ep_path):
            success = True
        else:
            print("Conversione fallita, riprovo...")
        attempts += 1
    conv_time = time.time() - start

    if not success:
        print("Errore: conversione non riuscita.")
        return False, conv_time

    dest = f"/run/media/lorenzo/SSD Sata/Convertiti/{os.path.basename(ep_path)}"
    shutil.move(dest, ep_path)
    return True, conv_time

def process_series(series):
    print(f"Inizio: {series['name']}")
    ep_path, dl_time = download_episode(series)
    if not ep_path:
        return {"name": series["name"], "download_time": 0, "converted": False, "conversion_time": 0}
    conv_res, conv_time = convert_to_h265(ep_path)
    return {"name": series["name"], "download_time": dl_time, "converted": conv_res, "conversion_time": conv_time}

if __name__ == '__main__':
    start_all = time.time()
    results = []

    # Sostituiamo il pool di processi con un pool di thread
    with ThreadPoolExecutor(max_workers=os.cpu_count() * 2) as executor:
        future_to_series = {executor.submit(process_series, s): s for s in series_list}
        for future in as_completed(future_to_series):
            res = future.result()
            results.append(res)

    total_time = time.time() - start_all

    # Resoconto
    print("\n--- Resoconto Finale ---")
    for r in results:
        print(f"{r['name']}: download {r['download_time']:.2f}s, conversione [{ 'OK' if r['converted'] else 'FAIL' }] in {r['conversion_time']:.2f}s")
    print(f"Tempo totale script: {total_time:.2f} secondi")
