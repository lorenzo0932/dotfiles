#!/bin/bash
# Ambilight: la LED strip segue i colori dello schermo durante il gioco.
# Hook [custom] di gamemode: start -> avvia ambilight.service (systemd user),
# end -> stop (SIGTERM al daemon che pubblica fedora/light/end e chiude la sessione).
SELF="$(readlink -f "$0")"
DIR="$(dirname "$SELF")"
MQTT_HOST="192.168.1.39"
SERVICE="ambilight.service"

conf_load() {
    if [ -f "$HOME/.config/mqtt.env" ]; then
        # shellcheck disable=SC1091
        source "$HOME/.config/mqtt.env"
    fi
    MQTT_USER="${MQTT_USER:-lorenzo}"
    if [ -z "${MQTT_PASS:-}" ]; then
        echo "ERRORE: MQTT_PASS non impostato (~/.config/mqtt.env)" >&2
        exit 1
    fi
}

publish() {
    mosquitto_pub -h "$MQTT_HOST" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$1" -m "$2" 2>/dev/null
}

start() {
    if systemctl --user is-active --quiet "$SERVICE"; then
        echo "ambilight gia' attivo ($SERVICE)"
        return 0
    fi
    systemctl --user start "$SERVICE"
    echo "ambilight avviato ($SERVICE)"
}

end() {
    if systemctl --user is-active --quiet "$SERVICE"; then
        systemctl --user stop "$SERVICE"
        echo "ambilight terminato ($SERVICE)"
    else
        # fallback: pubblica direttamente se il servizio non e' attivo
        conf_load
        publish fedora/light/end 1
    fi
}

case "${1:-}" in
    start) start ;;
    end)   end ;;
    *) echo "uso: ambilight.sh start|end" >&2; exit 1 ;;
esac
