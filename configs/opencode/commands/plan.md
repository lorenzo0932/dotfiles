---
description: Genera un piano dettagliato per la feature richiesta (modifiche file-per-file, motivazioni, scelte di design, rischi, verifica) — solo analisi, nessuna modifica
agent: plan
---

Prepara un piano dettagliato e operativo per la feature/fix richiesta.

$ARGUMENTS

Analizza il codebase in modo mirato (struttura dei sorgenti, build system,
convenzioni, pattern esistenti, AGENTS.md di repo) e produci:

1. **Obiettivo e contorno**: cosa fa la feature e cosa NON fa (out of scope).
2. **Modifiche file-per-file**: per ogni file, cosa cambia e perché
   (`path:riga` dove sensato), inclusi test e docs se rilevanti.
3. **Scelte di design**: alternative valutate e perché scartate.
4. **Rischi e regressioni possibili**, con contromisure.
5. **Piano di verifica**: test mirati (`ctest --test-dir build -R <target>`,
   `bash -n`), criteri di done.
6. **Passi di implementazione in ordine**, con dipendenze.

Non modificare file e non fare commit: il piano è il punto di rientro se la
feature non viene completata in sessione. Quando l'implementazione parte, il
piano verrà salvato in `plan/<slug>.md` sulla branch dedicata.