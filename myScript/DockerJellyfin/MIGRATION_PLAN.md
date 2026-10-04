# Migrazione Jellyfin Server: Flatpak → Docker (trasparente)

Data: 2026-09-30. Sorgente: `org.jellyfin.JellyfinServer 10.11.11` (Flatpak user).
Target: `jellyfin/jellyfin:10.11.11` (stessa versione → stessi plugin, stesso ffmpeg 7.1.x).

## 0. Vincoli di trasparenza (accordati)

- Stessi utenti (`Lorenzo`, `Guest`) e stessi "visti" (tabelle `UserData` nel DB).
- Stesse librerie senza re-scan: bind-mount **con path identici** (`/run/media/...`, `/home/lorenzo/Video`).
- Niente re-download artwork (si migra `metadata/` 670M) e niente re-analisi intro (si migra `data/introskipper/` 1012M).
- Tutti i 9 plugin funzionanti (stessa versione server → compatibili).
- Stessa porta `8096` + `BaseUrl=/jellyfin` → Caddy `:9856` e Tailscale invariati.
- HW-transcode VAAPI funzionante da subito (`/dev/dri` + `group_add 39/105`, come `ollama-compose.yml`).

## 1. Stato rilevato (verificato, non presunto)

| Voce | Valore |
|---|---|
| OS / HW | Fedora 43, Ryzen 5950X, RX 6700 (`renderD128`), 32 GB RAM |
| Docker | 29.8.1 attivo, Compose v5.5.1, utente nei gruppi `docker,video(39),render(105)` |
| Server ora | Flatpak user, autostart da `.desktop` (vive solo con sessione grafica), `8096` su `0.0.0.0` |
| DB | `jellyfin.db`, `PRAGMA integrity_check` = `ok` (2026-09-30) |
| Dati | `data` 1,9G (di cui introskipper 1012M) + `metadata` 670M + `cache` 432M (effimera, NON migrare) |
| Path assoluti Flatpak nei config | Solo 3: `CachePath`, `MetadataPath` (system.xml), `TranscodingTempPath` (encoding.xml) |
| Librerie (.mblink) | HardDisk1/Anime, SSD2/Anime, ~/Video/Anime Conclusi, ~/Video/Simulcast, SSD2+HardDisk1 Anime Film/Film, SSD2/Film da vedere, collections interne |
| Plugin | AniDB 11, AniList 13, AniSearch 6, FinTube 1.1, IntroSkipper 1.10.11.24, KodiSyncQueue 15, PlaybackReporting 17, SkinManager 2.0.2, WatchSync 1.0 |
| Errori preesistenti | AniList provider errors nei log (esterni, resteranno); NTFS `sdb`/`sdc1` con stale-inode → serve `chkdsk` da Windows |
| Backup esistente | Solo script+snapshot vecchi (latest 2026-02-26), timer `jellyfin-backup.timer` mai abilitato |

## 2. Fasi

### Fase 1 — Backup fresco + inventario (PRIMA di tutto)
- Destinazione: `/home/Data&Games/JellyfinMigration/backup-<timestamp>/` (btrfs interno, 39G liberi; NON SSD2 per gli errori NTFS).
- Snapshot sicuro DB: `sqlite3 jellyfin.db ".backup ..."` + rsync di `config/` e `data/` con `--exclude cache/`.
- Inventario: conteggi item per libreria, versioni plugin, utenti, verifica `integrity_check`.

### Fase 2 — Compose + immagine
- `~/docker/jellyfin/compose.yml` (definitivo, porta 8096, `restart: unless-stopped`) + `compose.test.yml` (override: porta 8097, niente restart) per il test parallelo.
- `user: "1000:1000"`, `devices: [/dev/dri]`, `group_add: ["39","105"]`.
- Bind media `:ro` con path identici (zero rewrite nel DB).
- Pull `jellyfin/jellyfin:10.11.11` (tag verificato esistente su Docker Hub, amd64) e ispezione layout interno (`JELLYFIN_*_DIR`) per il mapping.

### Fase 3 — Migrazione dati nei volumi
- `config/` ← `~/.var/.../config/jellyfin/`, `data/` ← `~/.var/.../data/jellyfin/` (DB via snapshot sqlite, esclusi `-shm/-wal/cache`).
- Rewrite dei soli 3 path assoluti verso `/config` e `/cache` del container.
- Nessun tocco al Flatpak (resta acceso e intatto = rollback immediato).

### Fase 4 — Test parallelo su 8097 (Flatpak acceso su 8096)
Checklist: avvio pulito nei log → login Lorenzo+Guest → conteggi librerie uguali → stati "visti" presenti → play con `hevc_vaapi` nei log ffmpeg → 9 plugin caricati → intro-skip disponibile → `BaseUrl /jellyfin` risponde.
Stop container di test a fine verifica.

### Fase 5 — Cutover (SOLO su via libera esplicito)
1. Stop Flatpak (`flatpak kill` + verifica porta 8096 libera).
2. `docker compose up -d` (stessi volumi del test, porta 8096).
3. Verifica: Caddy `:9856/jellyfin/`, Tailscale:8096, client (Desktop/Moonfin/mpv-shim), un transcode VAAPI reale.
4. Disabilita autostart Flatpak (sposta il `.desktop`, non cancellare).
5. Rollback (se serve): stop container, riavvia Flatpak — dati originali intatti.

### Fase 6 — Backup risistemato
- `backupJellyfin.sh`: `SOURCE_DIR` → volumi Docker, `--exclude cache/`, destinazione disco sano.
- `systemctl --user enable jellyfin-backup.timer` + aggiunta a `installServices.sh:21` (oggi manca: ecco perché non è mai partito).

### Fase 7 — Pulizia (dopo 2 settimane di esercizio)
- `flatpak uninstall org.jellyfin.JellyfinServer` (solo su conferma).

## 4. Esito test parallelo (2026-09-30, container `jellyfin-test` su 8097) — SUPERATO

- Avvio pulito (`Startup complete` in ~5s), `healthy`, versione 10.11.11, stesso ServerId.
- 9/9 plugin caricati, stesse versioni.
- DB: 247 serie, 6351 episodi, 33 film, 24376 "visti", utenti Lorenzo+Guest — identici al Flatpak.
- VAAPI su RX 6700 inizializzato nel container (stesso driver radeonsi).
- API su `/jellyfin` (BaseUrl) risponde, `StartupWizardCompleted=true`.
- Fix applicato: aggiunto bind `SSD Sata` (symlink `~/Video/Simulcast` ecc. lo richiedono).
- Unico errore residuo: `/run/media/lorenzo/HardDisk1/Film` inesistente — pre-esistente anche nel Flatpak (26 occorrenze oggi) → da pulire nelle librerie, non è un problema di migrazione.
- Memoria: baseline ~1GB in entrambi (stesso binario .NET, libreria grande). Aggiunto `mem_limit: 4g` al compose come rete anti-impallamento.
- Container di test STOPPATO il 2026-09-30; Flatpak in produzione intatto su 8096.
- Backup fresco: `/home/Data&Games/JellyfinMigration/backup-2026-09-30_11-51-29/` (1,9G, integrity ok).

## 5. Cutover ESEGUITO (2026-09-30 ~12:00)

1. `flatpak kill org.jellyfin.JellyfinServer` → porta 8096 libera (verificato).
2. Re-snapshot DB a server spento nei volumi (integrity ok, 24376 visti).
3. `docker compose up -d` → container `jellyfin`, `healthy`, `8096:8096`, `restart: unless-stopped`, `mem_limit: 4g`.
4. Verifiche: API diretta ok (stesso ServerId), Caddy `:9856/jellyfin/` → 302 web + Ping 200.
5. Autostart Flatpak disabilitato (`.desktop` spostato in `~/.config/autostart/disabled-by-migration/`, non cancellato).
6. Rollback: `docker compose stop` + `flatpak run org.jellyfin.JellyfinServer` (+ eventuale ripristino `.desktop`).

## 7. Fix post-cutover (2026-09-30): path assoluti nel DB — RISOLTO

Sintomo: UI senza librerie. Causa: il DB conteneva path assoluti Flatpak (non solo gli xml):
`BaseItems.Path/Data` (root folder), `BaseItemImageInfos.Path` (3299 righe),
`Chapters.ImagePath` (1414 righe). Fix: `REPLACE('.../data/jellyfin' → '/config')`
su 4 colonne, 0 residui, `integrity_check ok`. Verifica via API
`/Library/VirtualFolders`: 6/6 librerie con location corrette, zero errori di refresh.
Lezione: il test parallelo verificava i conteggi SQL ma non la risoluzione librerie via API.

## 8. Cambio 2026-09-30: media in lettura-scrittura (su richiesta)

Rimosso `:ro` dai bind media → eliminazione serie/film direttamente dal client
 come col Flatpak (verificato con touch/rm dentro il container su `~/Video` e SSD2).
 L'utente Lorenzo è admin → permesso di eliminazione attivo.

## 9. Backup integrato con rSync (2026-09-30) — FATTO

- `backupJellyfin.sh` riscritto per Docker: snapshot sqlite dei 4 DB + rsync volumi
  (escluse cache/shm/wal) + copia compose/test/plan in `host-config/`;
  destinazione `/home/Data&Games/JellyfinMigration` (btrfs sano, NON più SSD2 con NTFS corrotto).
- `jellyfin-backup.timer` abilitato e avviato (prossimo run dom 2026-10-04 00:00);
  aggiunto a `installServices.sh` (era l'omissione che lo teneva spento dal 2025).
- `rSync.sh` ora sincronizza anche `~/.config/systemd` → repo (variabile morta sistemata);
  propagato con `rSync_NoCommit.sh` (il commit+push avverrà col prossimo run settimanale).
- Nota: il primo backup col nuovo formato + retention ha rimosso gli snapshot Flatpak-era
  (ott-2025/feb-2026); rollback Flatpak resta possibile dai dati live in `~/.var` (intatti).

## 10. Watchtower + rollback (2026-10-02)

- Watchtower `nickfedor/watchtower` (`~/docker/watchtower/compose.yml`): ogni giorno 04:00,
  cleanup, solo container con label `watchtower.enable=true` (jellyfin + ollama).
- Snapshot pre-update 03:55 via timer `jellyfin-preupdate` (`pre-update-snapshot.sh`):
  4 DB sqlite + plugins/ + digest, retention 2, in `/home/Data&Games/JellyfinMigration/pre-update-*/`.
- Rollback con `rollback-jellyfin.sh` (stop → repin digest → restore DB/plugin → up → verifica API).

## 11. Lezione live (2026-10-02): :latest = 12.1.0, rollback collaudato sul campo

- Passaggio a `:latest` ha tirato su la **12.1.0** (due major avanti): **IntroSkipper disabilitato
  subito** per ABI incompatibile. Conferma empirica: mai :latest con questi plugin.
- Rollback eseguito davvero: DB+plugin ripristinati, digest ripinnato, API ok,
  10.11.11 + 6 librerie + IntroSkipper caricato. Zero perdite.
- Stato finale: tag `:10.11` (solo patch automatiche). Major solo manuale con audit plugin.
- Aggiornamento 2026-10-02 sera: migrato a **12.1.0 su richiesta** (plugin auto-aggiornati:
  IntroSkipper 12.0.4.0, KodiSync 16, AniDB 13, AniList 15, Playback 19). Nota: al primo
  boot 12.x il DB si è trovato corrotto (causa non determinata) e si è ripristinato
  dallo snapshot pre-update; da lì stabile, 9/9 plugin caricati.

## 12. Client Desktop 2.0.0: crash navigazione (2026-10-02, solo diagnosi)

SIGSEGV deterministico in Qt WebEngine su history-navigation dopo cambio dropdown
(stack identico ×4, anche senza GPU/sandbox e con profilo pulito). Esclusi: server,
dati, artwork, CSS, override Flatpak, profilo. Firefox ok = bug del wrapper 2.0.0
(pre-release Qt6). Report upstream preparato. Workaround utente: solo tasto Home,
niente pulsanti serie. branding.xml ripristinato dopo test diagnostico.

## 6. Rischi e note (da "Stato rilevato" invariati)

- **NTFS sdb/sdc1 corrotti** (stale inode, kernel: "Run chkdsk"): fare `chkdsk` da Windows prima possibile; i media su SSD2 restano leggibili in ro ma è a rischio.
- **Mount `/run/media` al boot**: sono automount di sessione (udisks) — su boot senza login non esistono e il container vedrebbe cartelle vuote. Follow-up proposto: mount stabili via fstab/systemd prima di considerare il server "always-on" reale.
- **DLNA/autodiscovery**: oggi il server espone solo 8096 (verificato via `ss`), quindi bridge+porte bastano; se un giorno serve DLNA → `network_mode: host`.
- **Doppio server durante il test**: autodiscovery annuncerà due istanze; test breve, poi stop. Nessun rischio dati (media in ro, DB copiato).
