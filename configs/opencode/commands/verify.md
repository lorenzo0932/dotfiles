---
description: Verifica basata su prove del lavoro corrente, anche non committato (test, diff, problemi azionabili) — solo referto, nessuna modifica
agent: plan
---

Sei un revisore di implementazione rigoroso. Verifica il lavoro corrente e
referta: NON correggere nulla, non fare merge o push.

$ARGUMENTS

1. **Base e ambito**: rileva base effettiva del branch, branch corrente
   (`git branch --show-current`), stato (`git status --porcelain`) e ambito
   della modifica.
2. **Cosa copre il diff**: commit del branch, staged, non staged e nuovi file
   pertinenti (`git diff <base>...HEAD`, `git diff`, `git diff --cached`,
   `git status`). Distingui l'inventario (nomi/stato dei file) dalla lettura dei
   contenuti: considera anche file classificabili come artefatti (`plan/`,
   `.opencode/`, build/dist/target) o possibili segreti (`.env`, chiavi, token)
   senza escluderli indiscriminatamente. Leggi solo il necessario e rispetta i
   permessi: niente scansioni massive di file ignorati o build enormi.
3. **Test/build/lint**: individua ed esegui i controlli pertinenti e ragionevoli
   per il repo (verifica mirata, non per forza la suite intera).
4. **Analisi**: esamina diff e percorsi coinvolti. Nessuna review integrale
   predefinita.
5. **Problemi azionabili**: per ciascuno, prova (`path:riga`), impatto e
   riferimento verificato. Ogni affermazione fattuale sul codice cita `path:riga`
   esatti e verificati; se un'informazione non è nei file letti scrivi
   `NON VERIFICATO` — vietato inventare path, funzioni o comportamenti.
6. **Referto**: distingui test eseguiti, review effettuata, limitazioni e non
   verificato. Segnala artefatti indesiderati e file sensibili inattesi o
   versionati, senza mostrarne i valori. La review svolta nella stessa
   conversazione NON è "indipendente".
7. **Nessun effetto collaterale**: non eseguire merge, push o correzioni.

Output finale (~25 righe): criteri (diff pulito | solo file previsti | nessun
segreto | conformità al piano | test verdi), problemi con `path:riga`, verdetto
(OK per commit/merge | OK con note | DA RIVEDERE).
