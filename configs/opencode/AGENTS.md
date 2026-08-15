# AGENTS.md

Repo personale di dotfiles/script: **backup periodico** di una macchina Linux (Fedora/CachyOS, GNOME). Niente CI, test o build step — solo Bash, qualche Python, e unit systemd user. Documentazione in `README.md`, `myScript/ScriptsOverview.md`, `systemd/user/UserServices_README.md`.

## Il repo è un mirror, non la fonte di verità

- `myScript/`, `nautilus/`, `systemd/`, `configs/mpv/`, `configs/opencode/` sono mirror rsync delle dir live: `~/.local/share/myScript`, `~/.local/share/nautilus`, `~/.config/systemd`, `~/.config/mpv`, `~/.config/opencode`.
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

## Prima di modificare un file

- Prima di ogni modifica/creazione (`edit`, `write`, `apply_patch`): apri il file in VSCode con `code --goto <file>:<riga>` per mostrare il codice di riferimento.
- Spiega in 1–2 righe il motivo della modifica e cosa cambierà, poi procedi.
- La conferma finale resta il prompt `edit: ask` (once / always / reject).

## Sessioni opencode — economia di contesto e budget (valida su TUTTE le macchine)

Config unica sincronizzata in `configs/opencode/` (regola dedicata in rSync.sh):
le regole sotto sono imposte dalla config (compaction automatica, pin dei
modelli, steps) o dal comportamento da tenere in sessione.

- **Modelli**: default `opencode-go/deepseek-v4-flash` ovunque, incluso `plan`
  (benchmark v2: flash batte i premium in agentico a 1/35 del costo). I
  premium SOLO a richiesta esplicita:
  - `/second-opinion-gemini` (comando dedicato): `google/gemini-3.7-flash`,
    single-shot. Vincitore dell'A/B test su `gemini-3.5-flash` (verdetto più
    netto, piano DTO più completo) e su Luna per l'insight di dominio (es.
    flussi video non esposti in schema.org).
  - `/second-opinion-gpt` (comando dedicato): `gpt-5.6-luna` single-shot
    economico (~$0.006/uso), piano operativo più dettagliato. **MAI sessioni
    lunghe su Luna**: la cache write costa $0.25/M ed esplode su contesto
    grande.
  - `glm-5.2` via /models: solo planning deterministico di problemi ambigui,
    sessione lean, max 1-2 al mese TOTALI tra tutte le macchine.
  - `qwen3.8-max` via /models: solo casi estremi (refactoring enormi, bug
    strani), max 1-2 sessioni al mese (pool $15).
  - **BANNATI anche via /models**: `qwen3.7-max`, `kimi-k3`/`kimi-k2.7-code`
    (input $3/M), `grok-4.5`, `glm-5.3`.
- **Niente switch di modello a metà sessione**: la cache prompt è legata al
  modello; cambiarlo ri-processa l'intero storico a prezzo pieno (sessioni
  grandi = $10+ per ogni switch). Se serve un modello diverso: nuova sessione.
- **File grandi (>400 righe, es. smoke.sh, WebServer.cpp)**: mai riletture
  integrali ripetute — grep mirato + `read` con offset/limit sulle sezioni
  necessarie. Riusare il contesto già letto nella sessione (non rileggere
  file non cambiati).
- **Verifica mirata**: `ctest --test-dir build -R <target>` e `bash -n`
  invece della suite completa a ogni passo; la verifica piena solo a fine
  feature.
- **1 feature = 1 sessione**: resoconto breve (commits + stato), compact, poi
  sessione nuova. La compaction automatica (config) tiene comunque basso il
  costo dei turni successivi.
- **Monitoraggio**: ogni settimana `opencode stats --days 7` (attribuzione
  per macchina) + console https://opencode.ai/auth (consumo pool Go — l'unico
  numero autorevole: il pool è condiviso tra TUTTE le macchine con la stessa
  chiave).

## RAM e tmpfs — REGOLA RIGIDA (violata 2 volte, mai più)

- **`/tmp` è tmpfs = RAM** (16G): MAI file grossi lì dentro senza controllare
  prima `free -h`. Worktree git, build, fixture: roba piccola ok, roba da GB
  assolutamente no (o monitora lo stato con `free -h`/`df -h /tmp` prima e
  durante).
- **`cmake --build -j$(nproc)` su macchina a 32 core = OOM sicuro** con link
  LTO (+ Jellyfin/Steam/Telegram/opencode aperti). Usare `-j8` o `-j16` max,
  mai `-j$(nproc)` senza controllo memoria. Se la macchina è sotto pressione:
  `-j4`.
- Prima di build pesanti: `free -h`. Dopo un OOM: verificare processi orfani
  (`ps aux --sort=-%mem`) e spazio `/tmp`.
