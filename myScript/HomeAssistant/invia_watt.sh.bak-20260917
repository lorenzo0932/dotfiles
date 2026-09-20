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

# 2. Leggi il Package Power (PPT) reale via ryzen_smu/ryzen_monitor
#    Nota: va eseguito come root per accedere a /sys/kernel/ryzen_smu_drv/pm_table
if [ -x "$RYZEN_MONITOR" ]; then
    PPT_RAW=$(timeout 2 sudo -n "$RYZEN_MONITOR" 2>/dev/null | grep -m1 "PPT")
    CPU_WATTS=$(echo "$PPT_RAW" | awk -F'|' '{print $1}' | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if [ -n "$CPU_WATTS" ]; then
        mosquitto_pub -h "$MQTT_HOST" -u "$MQTT_USER" -P "$MQTT_PASS" -t "fedora/cpu/power" -m "$CPU_WATTS"
    fi
fi

# 3. Leggi e calcola i Watt della GPU (invariato)
if [ -n "$AMD_HWMON" ]; then
    GPU_UW=$(cat "$AMD_HWMON/power1_average" 2>/dev/null || echo 0)
    GPU_WATTS=$(echo "scale=1; $GPU_UW / 1000000" | bc)
    mosquitto_pub -h "$MQTT_HOST" -u "$MQTT_USER" -P "$MQTT_PASS" -t "fedora/gpu/power" -m "$GPU_WATTS"
fi
