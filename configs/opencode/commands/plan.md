---
description: Piano breve e facoltativo per la feature richiesta (obiettivo, rischi, criteri di accettazione, verifica) — solo analisi, nessuna modifica
agent: plan
---

Prepara un piano BREVE e operativo per la feature/fix richiesta. Il piano è
facoltativo: per task chiari basta un piano minimo; non produrre un manuale
file-per-file se non riduce il rischio.

$ARGUMENTS

Produci al massimo:
1. **Obiettivo** e cosa resta fuori scope.
2. **Rischi** concreti (regressioni, dati, sicurezza) e contromisure.
3. **Criteri di accettazione** verificabili.
4. **Verifica**: come si controlla (test/comandi mirati, criteri di done).
5. **Passi essenziali** in ordine, con eventuali dipendenze.

Non modificare file e non fare commit. Per feature non banali il piano verrà
salvato in `plan/<slug>.md` sulla branch dedicata (mai committato né pushato).
