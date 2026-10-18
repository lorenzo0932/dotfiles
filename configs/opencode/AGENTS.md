# AGENTS.md — regole GLOBALI

Regole globali per l'agent opencode, valide su TUTTE le macchine e TUTTI i
repo allo stesso modo. Le regole specifiche di un progetto vivono nel suo
AGENTS.md (repo-level, caricato in aggiunta quando si lavora in quel repo):
qui solo ciò che deve valere ovunque. Se un AGENTS.md di repo contraddice
questo file, il comportamento corretto è segnalare la contraddizione.

## Prima di modificare un file

- Prima di ogni modifica/creazione (`edit`, `write`, `apply_patch`): apri il file
  in VSCode con `code --goto <file>:<riga>` per mostrare il codice di riferimento
  SOLO se:
  - VSCode è aperto (`pgrep -x code` con esito positivo), E
  - opencode NON sta girando nel terminale integrato di VSCode (`$TERM_PROGRAM`
    è diverso da `vscode`).
  - Con opencode nel terminale integrato di VSCode i diff degli edit sono già
    visibili nel TUI a fianco dell'editor: il goto è ridondante e va saltato.
- Spiega in 1–2 righe il motivo della modifica e cosa cambierà, poi procedi.
- La conferma finale resta il prompt `edit: ask` (once / always / reject).

## Modelli — default e scelte esplicite

- Default: `opencode/deepseek-v4.1-flash-free`, unico modello in
  `opencode.jsonc` (usato anche dall'agente `title`). Nessun provider locale.
- Gli agenti primary `build` e `plan` NON hanno pin di modello: usano il modello
  scelto con `/models` nella sessione corrente.
- Effort/variant: si usa il default del modello. Nessun `max` sistematico;
  effort più alto solo per necessità concreta e su scelta dell'utente.
- I modelli premium (es. `openai/gpt-6.1-sol`) si usano SOLO su richiesta
  esplicita dell'utente: nessuna invocazione automatica, diretta o tramite
  comando ordinario. Criterio di scelta, limiti dei pool e cronologia degli
  esperimenti vivono nella nota locale `~/.opencode/notes/modelli-e-budget.md`
  (non caricata nelle istruzioni).
- Niente switch di modello a metà sessione: la cache prompt è legata al modello
  (sessioni lunghe = riprocessare tutto a prezzo pieno). Se serve un altro
  modello, apri una nuova sessione.

## Workflow — proporzionato al rischio

Pianificazione e review si commisurano al rischio, non sono rituali per ogni
modifica. Questo supera esplicitamente il vecchio obbligo universale di piano
per ogni feature/fix.

- **Ordinario**: obiettivo e criteri verificabili → esplorazione mirata →
  implementazione → controlli → conclusione breve. Piano formale e seconda
  opinione NON obbligatori.
- **Ambiguo o rischioso**: `Sol` (`openai/gpt-6.1-sol`) su richiesta esplicita
  dell'utente → decisione, invarianti e criteri di accettazione → `Flash` in una
  NUOVA sessione per implementare → controlli → ritorno a Sol se necessario.
- **Blocco**: dopo due tentativi falliti senza progresso sostanziale, fermarsi,
  riassumere fatti e ipotesi e proporre escalation. È un'euristica sperimentale,
  non un cambio automatico di modello.
- **Handoff (Sol o Flash)**: passa requisito, vincoli, riproduzione, diff/stato,
  errori, tentativi già fatti e punti `path:riga` pertinenti — NON l'intera
  cronologia. Un comando non garantisce una sessione separata: apri manualmente
  una NUOVA sessione, scegli lì il modello (Sol o Flash) e passa solo l'handoff.
  Sol deve poter ispezionare da sé il repository: non riceve solo le conclusioni
  di Flash. Non cambiare modello nello storico lungo (vedi "Modelli").
- **Supervisione ≠ review indipendente**: la sessione Sol che ha prodotto il
  piano può supervisionarne l'esito, ma non la si chiama review indipendente:
  conosce e può favorire il proprio piano. Per modifiche critiche si può proporre
  una terza sessione Sol pulita (requisiti, criteri, diff, test e accesso ai
  file) — non obbligatoria.

## Sessioni — economia di contesto

- File grandi (>400 righe, es. smoke.sh, WebServer.cpp): mai riletture integrali
  ripetute — grep mirato + `read` con offset/limit sulle sezioni necessarie.
  Riusare il contesto già letto nella sessione (non rileggere file non cambiati).
- Verifica mirata: `ctest --test-dir build -R <target>` e `bash -n` invece della
  suite completa a ogni passo; la verifica piena solo a fine feature.
- Nuovo task indipendente → nuova sessione; se serve continuità basta un
  handoff breve (vedi "Handoff"). La compaction serve a PROSEGUIRE una sessione
  lunga, non è un passo obbligatorio prima di abbandonarla.
- Monitoraggio: ogni settimana `opencode stats --days 7`; il consumo del pool è
  quello della console https://opencode.ai/auth (l'unico numero autorevole).

## Esplorazione, agenti e sottoagenti

- Due primary sono sufficienti: `plan` e `build`, entrambi senza pin del modello.
  Nessun agente coordinatore o gruppo fisso di specialisti.
- Default: nessuna delega. Flash esplora quanto serve per implementare; Sol legge
  quanto serve per decidere o verificare.
- `explore` e `scout` sono subagent di sola lettura IMPOSTA: `edit` e `shell`
  sono negati (`scout` non può nemmeno lanciare sottoagenti). Usarli solo su
  richiesta esplicita per ricerche circoscritte, con domanda, confini e output
  sintetico con riferimenti verificabili. Nessun routing automatico.
- I sottoagenti sono isolamento del contesto o parallelismo, non un risparmio di
  token garantito: evitarli per poche letture o quando il principale dovrebbe
  rifare tutta la ricerca.
- I permessi dichiarati in prosa non valgono come garanzia: prima di affermare
  che un agente è vincolato in sola lettura, verifica i permessi effettivi in
  config (`opencode debug agents`). Descrivere ≠ imporre.

## Piani — effimeri, per feature non banali

- Per feature/fix non banali si parte da `plan/<slug>.md` sul branch dedicato
  (obiettivi, passi, stato), creato con `/plan` (facoltativo e breve). NON viene
  mai committato né pushato: è il punto di rientro se la sessione non completa.
  Per task chiari può bastare un piano minimo o nessun file.
- A feature completa (test verdi, `/verify`, review utente) e merge su dev: il
  file piano viene eliminato insieme alla branch. Il diff e le commit raccontano
  quanto fatto.

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
  2. Piano: `plan/<slug>.md` sul branch (regole in "Piani").
  3. Implementazione: commit locali solo di codice (mai piano, `.opencode/`
     o artefatti AI).
  4. Verifica: a implementazione finita eseguire `/verify` e lasciare la
     review all'utente.
  5. **Push del branch e merge su dev SOLO su richiesta esplicita** (mai
     automatici); a merge riuscito chiudi branch e piano (vedi "Piani"). Mai
     branch locali orfani.
- `AGENTS.md` (repo-level) è documentazione di progetto e vive su dev/public.
- **Branch obbligatorio** per operazioni che toccano sorgenti o workflow in
  modo non banale (funzionalità, fix, performance, refactoring, CI multi-step
  con giri di verifica). Commit diretti su dev SOLO per micro-correzioni di
  housekeeping (una riga in un workflow, un commento, un path) o per
  modifiche docs un-file.

## Artefatti AI — MAI su GitHub (regola rigida, tutti i repo)

- Piani, resoconti, bundle di codice, prompt e tool AI: **mai committati/pushati
  su repo remoti pubblici o condivisi**. Vivono solo in locale: su una branch
  mai pushatta o in cartelle gitignored (es. `plan/`, `.opencode/`).
- Nota fattuale: `rSync.sh` sincronizza `~/.config/opencode/` in
  `dotfiles/configs/opencode/` e lo auto-pusha (repo pubblico) — scelta esplicita
  dell'utente. Conseguenza: NON mettere segreti o materiale sensibile in quella
  cartella. L'`AGENTS.md` di repo resta eccezione tracciabile su dev/public.

## Review grounded — anti-allucinazione (regola)

Vale per `/plan`, `/verify` e qualunque analisi del codice: la disciplina delle
prove è assorbita in `/verify`.

- Ogni affermazione fattuale sul codice cita `path:riga` esatti e verificati con
  `read`/`grep` nella sessione. Senza citazione, non si afferma.
- Se non è nei file letti: scrivere `NON VERIFICATO`, mai inventare path,
  funzioni o comportamenti. Distinguere citato (letto, con riga) vs dedotto
  (inferenza logica, marcata) vs non verificato.
