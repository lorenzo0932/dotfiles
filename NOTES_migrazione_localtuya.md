# Migrazione luci Tuya: cloud → localtuya (HA)

Data: 2026-08-02. Stato: COMPLETATA.

## Obiettivo
Spostare `light.led` e `light.luce_camera` dalla integrazione Tuya **cloud**
a **localtuya** (HACS, già installato v5.2.x) per controllo locale immediato
(latenza ambilight senza cloud).

## Dati device (da API Tuya IoT)

| Nome | device_id | local_key | modello | prodotto |
|---|---|---|---|---|
| LED (strip) | `5480608010521c4ca14e` | `I(ezzkf]iQBZFj_}` | BT01-T-NEW | LED Strip Lights |
| Luce camera | `33882720600194e76ae8` | `HnBXIc9k5rnL4+}/` | TB85 RGBCW | Smart Bulb |

- Gli IP restituiti dall'API (`2.38.94.220`, `2.35.173.125`) sono **pubblici**, inutilizzabili.
- `sub: false`, entrambi `is_online: true`, time_zone +01:00.

## Mapping IP LAN (scan nmap porta 6668 dal box HA)

| IP LAN | MAC | Device dedotto (correlazione device_id ↔ MAC) |
|---|---|---|
| 192.168.1.30 | 10:52:1C:4C:A1:4E | **LED** (id termina `...10521c4ca14e` ↔ MAC) |
| 192.168.1.24 | 60:01:94:E7:6A:E8 | **Luce camera** (id `...600194e76ae8` ↔ MAC) |
| 192.168.1.26 | D8:BF:C0:DA:D6:37 | terzo device Espressif (da ignorare, non nostro) |

Correlazione verificata: la coda del `device_id` contiene i byte del MAC.

## Cosa va re-indirizzato (referenze esistenti)
- `automations.yaml` sul box `/config/`:
  - Ambilight `007` salva stato, `008` colore, `009` fine sessione → `light.led`, `light.luce_camera`
  - Automazioni "Esci di casa" / "Entra a casa" → `device_id` cloud
    `1ea2c2bdf5032f2409b8c9b6bf1af0e5` (LED) e `fb18ccb2cd1ec92eefb05a4f3904a137` (Luce camera)
- Nessuno script nel repo tocca `light.led` (verificato con grep).

## Procedure
1. ✅ Creare config entry localtuya (host + device_id + local_key + protocol version 3.5/3.4/3.3). → **fatto**, v. "ESITO".
2. ✅ Far comparire le entity `light` locali; verificare DPs (power, brightness, color, color_temp). → **fatto**.
3. ✅ Disabilitare (o eliminare) le entity cloud dei 2 device. → **fatto** (rinominate `_cloud` e disabilitate).
4. ✅ Aggiornare `automations.yaml` (ambilight + esci/entra casa) con le nuove entity. → **fatto**.
5. ✅ `automation.reload` + test E2E ambilight (start→color→end) + test colori/temperature. → **fatto**.
6. Lease DHCP fisso per i 2 MAC. → **da fare (opzionale)**.
7. rSync + push (se si toccano script del repo; le automazioni vivono solo sul box).

## Problematiche note
- `local_key` contiene caratteri speciali `(`, `[`, `]`, `}`: in YAML usare quote o `secrets.yaml`.
- Protocollo: provare 3.5 → 3.4 → 3.3; discovery UDP 6660 può fallire → config manuale con host.
- Range temp: cloud 2000–6500K; localtuya usa mired (color_temp) — verificare mapping soglie.
- Tenere entry cloud `tuya` per eventuali altri device; disabilitare SOLO le entity dei 2 light.
- Il terzo device Espressif (.26) non va toccato.

## ESITO (2026-08-02)

### Config entry creata (scrittura diretta in `.storage/core.config_entries` + restart)
- Una entry `localtuya` (entry_id `CAE7FC8D4E744171839D74C61`), `no_cloud: true`,
  con 2 device in `data.devices` (la vecchia forma "entry per device" è migrata/merge in v2):
  - `5480608010521c4ca14e` host 192.168.1.30, protocollo `3.3`, friendly "LED"
  - `33882720600194e76ae8` host 192.168.1.24, protocollo `3.3`, friendly "Luce camera"
- Il backup pre-modifica è in `.storage/core.config_entries.bak-localtuya`.

### Mapping DP definitivo (verificato con tinytuya 1.20.0, protocollo 3.3 SOLO; 3.4/3.5 → Err 914)

| Device | power | mode | brightness | color_temp | color |
|---|---|---|---|---|---|
| LED (BT01) | DP1 | DP2 (`colour`/`white`) | DP3 (0–255) | DP4 (0–255: 2000K→0, 6500K→255) | DP5 (extended 14hex: `RRGGBB hue sat bri`, bri=ultimo byte: 27@10%, 128@50%, 255@100%) |
| Luce camera (TB85) | DP20 | DP21 (`colour`/`white`) | DP22 (0–1000) | DP23 (0–1000: 2000K→0, 6500K→1000) | DP24 (HSV 12hex: `hue(16bit BE) sat(0-1000) bri(0-1000)`, es. `000003e8012a` = rosso 30%) |

- Entrambi i formati colore sono nativi di localtuya: `len>12` → extended (LED), `len==12` → HSV short (TB85).
- `color_temp_reverse: true` per entrambi (dp alto = kelvin alto).
- Config light: LED `{id:1, brightness:3, color_temp:4, color:5, color_mode:2, brightness_lower:0, upper:255}`;
  Luce camera `{id:20, brightness:22, color_temp:23, color:24, color_mode:21, brightness_lower:0, upper:1000}`.
- min/max kelvin 2000/6500 per entrambe.

### Rinomine entity (in `.storage/core.entity_registry`, dopo restart)
- `light.led` (tuya cloud) → `light.led_cloud`, **disabilitata**
- `light.luce_camera` (tuya cloud) → `light.luce_camera_cloud`, **disabilitata**
- `light.led_2` (localtuya) → `light.led`
- `light.luce_camera_2` (localtuya) → `light.luce_camera`
- Entry cloud tuya tenute (hanno anche `light.ciccio`, `light.stanza_dome`).

### Automazioni aggiornate (`/config/automations.yaml`)
- "Esci di casa": `light.turn_off` con `target.entity_id: light.led` + `light.luce_camera`
  (sostituiti i `device_id`/`entity_id` cloud).
- "Entra a casa": `light.turn_on` → `target.entity_id: light.led`.
- 007/008/009 ambilight già puntavano a `light.led`/`light.luce_camera` per nome: nessuna modifica.

### Test E2E superati
- LED 2700K/30% → start → 008 rosso hs[0,100] bri 140 (55%) → end → restore esatto 2700K/2695K bri 76.
- Luce camera 4000K/40% + LED 2700K/30% → sessione → restore esatti (cam 3999K/102, LED 2695K/76).
- Luce camera OFF prima della sessione → si accende in sessione → torna OFF dopo end.
- I device non accettano connessione tinytuya concorrente con localtuya (socket unico): verificare i DP
  solo a integrazione ferma o usare lo stato HA.

### Note per il futuro
- Il cloud (entry `01KXNVNT`, account lorenzo0932@gmail.com) controlla ancora fisicamente i device:
  i DP scritti da localtuya sono gli stessi visti dal cloud (verificato: `2=white`, `3=140`, ecc.).
- Lease DHCP fisso per .30/.24 ancora da fare (opzionale).
