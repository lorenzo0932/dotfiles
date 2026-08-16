# AGENTS.md — regole GLOBALI

Regole globali per l'agent opencode, valide su TUTTE le macchine e TUTTI i
repo allo stesso modo. Le regole specifiche di un progetto vivono nel suo
AGENTS.md (repo-level, caricato in aggiunta quando si lavora in quel repo):
qui solo ciò che deve valere ovunque. Se un AGENTS.md di repo contraddice
questo file, il comportamento corretto è segnalare la contraddizione.

## Prima di modificare un file

- Prima di ogni modifica/creazione (`edit`, `write`, `apply_patch`): apri il file in VSCode con `code --goto <file>:<riga>` per mostrare il codice di riferimento SOLO se:
  - VSCode è aperto (`pgrep -x code` con esito positivo), E
  - opencode NON sta girando nel terminale integrato di VSCode (`$TERM_PROGRAM` è diverso da `vscode`).
  - Con opencode nel terminale integrato di VSCode i diff degli edit sono già visibili nel TUI a fianco dell'editor: il goto è ridondante e va saltato.
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
  - `/review-codebase` (comando dedicato): `google/gemini-3.7-flash`,
    revisione one-shot dell'intera codebase (~380K token) via bundle.
    Prima: `scripts/bundle_codebase.sh` nel progetto (genera
    `.opencode/bundle/codebase_bundle.md`, gitignored, ed esclude gli
    artefatti generati, es. `embedded_web_data.cpp` — senza di esso il
    bundle non entrerebbe nel contesto di 1M).
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
- **1 feature = 1 sessione**: riassunto breve (commits + stato), compact, poi
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

## Git — operazioni remote MAI automatiche (regola rigida, tutti i repo)

- **Push, pull/merge da remote, delete di branch remoti, fetch, PR: solo su
  richiesta esplicita dell'utente.** Mai come parte di una routine, mai
  "tanto per aggiornare". In ogni sessione si lavora in fase locale
  (creazione branch → implementazione → commit → test) e ci si ferma lì
  finché l'utente non chiede le operazioni remote.
- Eccezione dichiarata: i timer/script che l'utente installa deliberatamente
  (es. l'auto-push di `rSync.sh` nel repo dotfiles) sono una sua scelta, non
  una violazione: la regola vincola l'AGENT, non i suoi strumenti.
- **Ciclo di vita di una feature/fix (workflow standard)**:
  1. Branch: `git checkout -b <tipo>/<slug>` da dev.
  2. Piano: `plan/<slug>.md` sul branch, **mai committato né pushato** — è il
     punto di rientro se la feature non viene completata. può essere generato
     con `/plan`.
  3. Implementazione: commit locali solo di codice (mai piano, `.opencode/`
     o artefatti AI).
  4. Verifica: a implementazione finita eseguire `/verify` e lasciare la
     review all'utente.
  5. **Push del branch e merge su dev SOLO su richiesta esplicita** (mai
     automatici). A merge riuscito: delete della branch + eliminazione del
     file piano. Mai branch locali orfani.
- `AGENTS.md` (repo-level) è documentazione di progetto e vive su dev/public.
- **Branch obbligatorio** per operazioni che toccano sorgenti o workflow in
  modo non banale (funzionalità, fix, performance, refactoring, CI multi-step
  con giri di verifica). Commit diretti su dev SOLO per micro-correzioni di
  housekeeping (una riga in un workflow, un commento, un path) o per
  modifiche docs un-file (es. aggiornamento dell'AGENTS.md di repo).

## Artefatti AI — MAI su GitHub (regola rigida, tutti i repo)

- Piani, resoconti, bundle di codice, prompt, tool AI e file di
  configurazione dell'agent: **mai committati/pushati su repo remoti
  pubblici o condivisi**. Vivono solo in locale: su una branch mai pushatta
  o in cartelle gitignored (es. `plan/`, `.opencode/`). L'`AGENTS.md` di repo
  è eccezione: essendo documentazione di progetto, può essere tracciato su
  dev/public.
- Niente "storico" permanente di piani: i piani sono effimeri per feature e
  muoiono col merge. Il pre-push hook, se presente, blocca solo il push dei
  branch riservati.

## Piani — effimeri, per feature (regola rigida)

- Ogni feature/fix parte dal file di piano `plan/<slug>.md` creato sul branch
  dedicato: obiettivi, passi, stato. **Non viene mai committato né pushato**:
  è solo il punto di rientro se la sessione non completa la feature.
- A feature completa (test verdi, `/verify`, review utente) e merge su dev:
  il file piano viene eliminato insieme alla branch. Il diff e le commit
  raccontano quanto fatto: nessun archivio storico di piani da gestire.
