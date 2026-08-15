# AGENTS.md

Repo personale di dotfiles/script: **backup periodico** di una macchina Linux (Fedora/CachyOS, GNOME). Niente CI, test o build step — solo Bash, qualche Python, e unit systemd user. Documentazione in `README.md`, `myScript/ScriptsOverview.md`, `systemd/user/UserServices_README.md`.

## Il repo è un mirror, non la fonte di verità

- `myScript/`, `nautilus/`, `systemd/`, `configs/mpv/` sono mirror rsync delle dir live: `~/.local/share/myScript`, `~/.local/share/nautilus`, `~/.config/systemd`, `~/.config/mpv`.
- `rSync.sh` (installato in `~/.local/share/myScript/rSync/rSync.sh`, avviato da `rsync_sync.timer`) sincronizza **live → repo con `--delete`**, poi auto-committa e fa push su `origin main`.
- **Modificare file direttamente nel repo è inutile o pericoloso**: al prossimo rSync vengono sovrascritti (rsync `-u` non copia solo se il dest è più nuovo). Per cambiare una config: modifica il file **live**, poi propaga con `rSync.sh` (o `rSync_NoCommit.sh` per sincronizzare senza committare).
- Eccezioni — file che vivono SOLO nel repo e non vengono sovrascritti: `installAll.sh`, `installationScripts/`, `README.md`, `.gitignore`, `tuned_config/`, `AGENTS.md`.
- `configs/mpv/` è sincronizzato da una regola dedicata da `~/.config/mpv` (la config reale, escluso `watch_later/` e `bak/cache/`). Non spostare manualmente quella cartella.
- `configs/opencode/` è sincronizzato da una regola dedicata da `~/.config/opencode` (config unica multi-macchina di opencode; esclusi `node_modules/`, `package-lock.json`, `README.md`, `.gitignore`).
- `protonvpn_reconnect.service` è gestita dall'app ProtonVPN ed è esclusa dal sync (`exclude.txt`): resta solo in live.
- `exclude.txt` (in `myScript/rSync/`) esclude dal sync: `*.log`, `__pycache__`, `.mypy_cache`, `dist`, `build`, `gemini.env`, `AniDownloader.*`, ecc. È sia in live che nel repo: modifica la copia live.
- `~/.config/autostart/` NON è sincronizzato (scelta dell'utente): gli `.desktop` di avvio automatico vivono solo in live.
- Le estensioni GNOME Shell NON vengono copiate tranne l'estensione custom `fullscreen-command@lorenzo0932`: `rsync_sync.service` esegue prima della sync `ExportGnomeExtensions.sh` (ExecStartPre) che salva la lista UUID attive + impostazioni dconf in `myScript/ExportGnomeExtensions/` e la copia dell'estensione custom (files + schemas) in `myScript/ExportGnomeExtensions/fullscreen-command@lorenzo0932/`. Il ripristino (manuale) scarica le estensioni da extensions.gnome.org con `RestoreGnomeExtensions.sh`, mentre la custom viene ripristinata dalla copia locale.

## Commit

- I messaggi sono generati da un LLM (Gemini, prompt "Auto sync: ...") e **possono non descrivere fedelmente le modifiche** — non fidarsi dello storico per capire le intenzioni.
- Il repo gira su `main` con push automatico; nessun processo PR.

## Verifica

- Nessun linter/test: per gli script Bash usare `bash -n <file>`. Mantenere `chmod +x`.
- `myScript/HomeAssistant/ryzen_monitor/` è un tool C venduto (progetto upstream con il suo Makefile): non refactorare.
- Le unit systemd user si provano con `systemctl --user start/status <unit>` e `journalctl --user -u <unit>`; dopo modifiche: `systemctl --user daemon-reload`.

## Installer (restore da clone)

- `installAll.sh` esegue tutti gli installer dalla cartella `installationScripts/` del repo (funziona da clone fresco; `chmod +x installAll.sh && ./installAll.sh`).
- Gli installer **copiano** repo → home (non creano symlink) e i path sono hardcoded su `/home/lorenzo`.
- `installScripts.sh` usa `cp -ru` (non sovrascrive mai file live più recenti).
- `installServices.sh` copia le unit in `~/.config/systemd/user/` e abilita: `anidownloader-check.timer`, `anidownloaderd.service`, `flatpak-update.timer`, `invia-watt.timer`, `rsync_sync.timer` (+ `sunshine.service`, `xbox-monitor.service` senza `--now`).
- `invia-watt.service` legge `MQTT_PASS` da `~/.config/mqtt.env` (fuori dalle aree syncate: mai nel repo).
- `systemd/user/*.target.wants/` contengono symlink reali, committati intenzionalmente.

## Convenzioni

- Molti nomi di file e commenti sono in **italiano** (es. `Converti e sposta (Burst).sh`, `AvviaLockscreen.sh`): cercare sia in inglese sia in italiano. Le **cartelle** di `myScript/` sono invece in inglese senza spazi (AI, Audio, BackupJellyfin, Display, Lockscreen, VideoTools...).
- Unit systemd e timer attivi da non rompere: `anidownloader-check.timer`, `flatpak-update.timer`, `invia-watt.timer` (ogni 30s), `rsync_sync.timer` (weekly), `sunshine.service`, `xbox-monitor.service`.
- `lmstudio.service`/`.timer` sono volutamente **disabilitati** (binario `~/.cache/lm-studio/bin/lms` assente finché LM Studio non viene reinstallato).
- `nautilus/scripts/old/` (versioni vecchie) e `Experimental/` (convertitori sperimentali AV1/Anime4K) sono mantenuti di proposito.
