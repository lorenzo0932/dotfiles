---
description: Genera o aggiorna AGENTS.md del progetto con la sezione standard di economia di contesto
---

Analizza questo progetto (struttura, build system, test, convenzioni) e crea o
rigenera il file AGENTS.md:

1. Le informazioni di base del progetto: comandi di build/test/lint, struttura
   delle cartelle, convenzioni di stile, cosa fare e non fare.
2. In fondo, la sezione standard "Sessioni opencode — economia di contesto"
   con queste regole:
   - file >400 righe: mai riletture integrali ripetute — grep mirato e
     letture con offset/limit sulle sezioni necessarie
   - verifica mirata del target specifico (es. ctest -R <target>) invece
     della suite completa a ogni passo
   - riuso del contesto già letto nella sessione (non rileggere file invariati)
   - 1 feature = 1 sessione, compact prima di iniziare un nuovo task lungo
   - niente switch di modello a metà sessione (invalida la cache prompt)
   - modelli: default deepseek-v4-flash; Plan su glm-5.2 solo per sessioni
     lean e importanti

Se AGENTS.md esiste già, non sovrascriverlo: aggiorna solo le sezioni superate
e assicurati che la sezione standard sia presente in fondo.
