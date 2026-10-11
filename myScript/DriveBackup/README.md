# DriveBackup — backup mensile file importanti sui due Google Drive

Autonomo da `rSync.sh`: usa solo `drive-jobs.conf` + `rclone copy` (mai delete sul Drive).

## Setup first-time (una volta)

1. `rclone config` → `n` (new remote) → nome `drive-personale` → storage `drive` → client_id/secret vuoti (INVIO) → scope `drive` → root_folder_id vuoto → `n` (no advanced) → `y` (auto config apre il browser) → login `lorenzo0932@gmail.com` → `y`. Ripeti per `drive-lavoro` con `ammatuna97@gmail.com`.
2. Verifica: `rclone lsd drive-personale:` e `rclone lsd drive-lavoro:`.
3. Dry-run: `~/.local/share/myScript/DriveBackup/drive-backup.sh` (fallisce pulito senza remote), poi con remote ok gira davvero.

## Uso

- Manuale: `systemctl --user start drive-backup.service` oppure script diretto.
- Automatico: `drive-backup.timer` (mensile, `Persistent=true`).
- Log in `logs/` (esclusi dal mirror dotfiles via regola `*.log`).

## File nativi Google (non passano da rclone tra account diversi)

- Foglio "ti sto fornendo un documento di una prestazione…" (personale → lavoro): aprilo nel Drive personale → Condividi con `ammatuna97@gmail.com` (Editor) → dall'account lavoro: File → Crea una copia → sposta la copia dove serve → elimina originale/condivisione.
- `Spese` (da classificare): aprilo e decidi casa/lavoro, poi come sopra se va spostato.

## Pulizie Drive in sospeso (da fare con rclone o web UI)

- `rclone delete "drive-personale:tbo-ztok-qxm - 5 lug 2022"` (cestino approvato; gvfs non supporta trash su Drive).
- `Archivio-pre-GitHub/` (Script Conversione, Programmazione, Anime 4k, Stupid Benchmark): confronta col repo poi elimina.
