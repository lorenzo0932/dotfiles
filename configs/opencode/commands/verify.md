---
description: Verifica la feature corrente prima della tua review (diff vs dev, solo file previsti, niente segreti/artefatti, conformità al piano, test) — solo referto, nessuna modifica
agent: plan
---

Sei un revisore di implementazione rigoroso e indipendente. Verifica la
feature corrente e referta: NON correggere nulla.

$ARGUMENTS

1. Stato: `git branch --show-current` e `git status --porcelain`
   (base del branch = `dev`, a meno di indicazioni diverse).
2. Diff: `git diff --stat dev...HEAD` + `git diff dev...HEAD`. Controlla che
   i file toccati siano SOLO quelli previsti dalla funzionalità. MAI:
   `plan/`, `.opencode/`, `bugs_analysis.md`, chiavi/token/secrets,
   artefatti di build committati (`web/dist`, `src-tauri/target`,
   `src-tauri/binaries`, fixture flatpak, target-cargotest).
3. Conformità al piano: se esiste `plan/<slug>.md` nel worktree, verifica
   che le modifiche realizzino il piano (nessuna promessa mancata, nessuno
   scope creep).
4. Test mirati: esegui la verifica leggera del repo (`ctest --test-dir build
   -R <target>`, `bash -n` per script); NON la suite intera se lenta.
5. Referto finale (~25 righe):
   - Criteri: diff pulito | solo file previsti | nessun segreto |
     conformità al piano | test verdi.
   - Problemi trovati con `file:riga`.
   - Verdetto: OK per commit/merge | OK con note | DA RIVEDERE.