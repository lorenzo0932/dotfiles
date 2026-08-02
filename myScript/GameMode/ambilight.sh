#!/bin/bash
# Ambilight: la LED strip segue i colori dello schermo durante il gioco.
# Hook [custom] di gamemode: start -> daemon screenshot (ScreenCast stealth),
# end -> SIGTERM al daemon che pubblica fedora/light/end e chiude la sessione.
SELF="$(readlink -f "$0")"
DIR="$(dirname "$SELF")"
MQTT_HOST="192.168.1.39"
PIDFILE="/tmp/ambilight_daemon.pid"

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
    conf_load
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        echo "ambilight già attivo (pid $(cat "$PIDFILE"))"
        return 0
    fi
    publish fedora/light/start 1
    nohup python3 "$DIR/screenshot_portal.py" daemon >/dev/null 2>&1 &
    echo "daemon ambilight avviato (pid $!)"
}

end() {
    if [ -f "$PIDFILE" ]; then
        kill -TERM "$(cat "$PIDFILE")" 2>/dev/null
        rm -f "$PIDFILE"
        echo "daemon ambilight terminato"
    else
        # fallback: pubblica direttamente se il daemon non c'e'
        conf_load
        publish fedora/light/end 1
    fi
}

case "${1:-}" in
    start) start ;;
    end)   end ;;
    *) echo "uso: ambilight.sh start|end" >&2; exit 1 ;;
esac
