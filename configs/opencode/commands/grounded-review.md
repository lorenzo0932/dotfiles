---
description: Review/analisi grounded del codice: ogni affermazione fattuale citata file:riga, divieto di inventare, verdetto con prove (anti-allucinazione)
agent: plan
---

Esegui una review/analisi grounded del codice indicato.

$ARGUMENTS

Regole rigide (violazione = risposta da scartare):
1. Leggi i file veri con `read`/`grep` prima di affermare qualsiasi cosa sul codice.
2. Ogni affermazione fattuale cita `path:riga` esatti. Senza citazione, non si afferma.
3. Se un'informazione NON è nei file letti, scrivi esattamente `NON VERIFICATO` — mai inventare path, funzioni, comportamenti o "probabilmente".
4. Distingui sempre: CITATO (letto, con riga) vs DEDOTTO (inferenza logica, marcata) vs NON VERIFICATO.

Produci:
1. **Ambito**: file effettivamente letti (lista) + cosa NON hai letto.
2. **Osservazioni**: una per punto, ciascuna con citazione `path:riga` o marcata NON VERIFICATO.
3. **Problemi veri**: solo quelli con prova; per ciascuno, impatto e fix suggerito (file-per-file).
4. **Falsi sospetti scartati**: cose che sembravano problemi ma il codice smentisce (con citazione).
5. **Zone d'ombra**: cosa resterebbe da leggere per completare il quadro.
