#!/bin/bash
# --- CONFIGURAZIONE MQTT ---
MQTT_HOST="192.168.1.39"
MQTT_USER="${MQTT_USER:-lorenzo}"
MQTT_PASS="${MQTT_PASS:?MQTT_PASS not set. Export it before running this script.}"
# Percorso del binario ryzen_monitor compilato
RYZEN_MONITOR="/home/lorenzo/.local/share/myScript/HomeAssistant/ryzen_monitor/src/ryzen_monitor"
# ---------------------------

# 1. Trova dinamicamente la cartella hwmon di AMDGPU (GPU)
AMD_HWMON=""
for d in /sys/class/hwmon/hwmon*; do
    if [ -f "$d/name" ] && [ "$(cat "$d/name")" = "amdgpu" ]; then
        AMD_HWMON="$d"
        break
    fi
done

# 2. Leggi il Package Power CPU via RAPL (nessun driver/root richiesto).
#    Nota 2026-09-17: ramo ryzen_monitor dismesso (modulo ryzen_smu 0.1.2 non compila
#    su kernel cachyos >= 7.2: API cpuid_* rimosse). RAPL misura lo stesso package power.
#    Lo script gira ogni 30s via invia-watt.timer: media su finestra precedente.
RAPL_FILE="/sys/class/powercap/intel-rapl:0/energy_uj"
RAPL_RANGE="/sys/class/powercap/intel-rapl:0/max_energy_range_uj"
RAPL_STATE="${XDG_RUNTIME_DIR:-/tmp}/invia_watt_rapl.state"
if [ -r "$RAPL_FILE" ]; then
    E_NOW=$(cat "$RAPL_FILE"); T_NOW=$(date +%s%N)
    if [ -f "$RAPL_STATE" ]; then
        read -r E_PREV T_PREV < "$RAPL_STATE"
        if [ "$E_NOW" -ge "$E_PREV" ]; then DE=$((E_NOW - E_PREV));
        else DE=$(( $(cat "$RAPL_RANGE" 2>/dev/null || echo 0) - E_PREV + E_NOW )); fi
        DT_NS=$((T_NOW - T_PREV))
        if [ "$DT_NS" -gt 0 ] && [ "$DE" -ge 0 ]; then
            CPU_WATTS=$(awk "BEGIN {printf \"%.1f\", $DE / ($DT_NS / 1000000000) / 1000000}")
            mosquitto_pub -h "$MQTT_HOST" -u "$MQTT_USER" -P "$MQTT_PASS" -t "fedora/cpu/power" -m "$CPU_WATTS"
        fi
    fi
    echo "$E_NOW $T_NOW" > "$RAPL_STATE"
fi

# 3. Leggi e calcola i Watt della GPU (invariato)
if [ -n "$AMD_HWMON" ]; then
    GPU_UW=$(cat "$AMD_HWMON/power1_average" 2>/dev/null || echo 0)
    GPU_WATTS=$(echo "scale=1; $GPU_UW / 1000000" | bc)
    mosquitto_pub -h "$MQTT_HOST" -u "$MQTT_USER" -P "$MQTT_PASS" -t "fedora/gpu/power" -m "$GPU_WATTS"
fi
