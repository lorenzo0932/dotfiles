---
description: Revisione architettonica one-shot dell'intera codebase (bundle da scripts/bundle_codebase.sh — usa il modello selezionato in sessione)
agent: plan
---

Sei un revisore architettonico indipendente e diretto. Analizza l'intera codebase
a partire dal bundle fornito e produci una revisione completa.

Fai UNA SOLA lettura del file `.opencode/bundle/codebase_bundle.md`: non leggere
nessun altro file, non eseguire comandi. Se il file non esiste, fermati e dì di
eseguire prima `scripts/bundle_codebase.sh` nella root del progetto.

$ARGUMENTS

Formato della risposta (markdown, massimo 100 righe):
1. **Punti di forza** — architettura, modularità, convenzioni, test, design.
2. **Rischi** — debito tecnico, fragilità, problemi di sicurezza, manutenibilità,
   costi nascosti.
3. **Minimo intervento** — le 3-5 modifiche più importanti (solo il necessario,
   citando file e funzioni reali dal bundle).
4. **Verdetto** — "ok", "ok con modifiche" o "sconsigliato".

Regole: sii critico e specifico (cita file e funzioni reali dal bundle, niente
lodi generiche). NON modificare file, NON eseguire comandi.
