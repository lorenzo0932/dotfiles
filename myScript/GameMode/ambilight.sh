#!/bin/bash
# Ambilight: la LED strip segue i colori dello schermo durante il gioco.
# Hook [custom] di gamemode: start -> loop background, end -> stop.
SELF="$(readlink -f "$0")"
DIR="$(dirname "$SELF")"
MQTT_HOST="192.168.1.39"
STOPFILE="/tmp/ambilight_stop"
SHOT="/tmp/ambilight_shot.png"
INTERVAL=8

if command -v magick >/dev/null 2>&1; then IMG="magick"; else IMG="convert"; fi

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

loop() {
    conf_load
    while [ ! -f "$STOPFILE" ]; do
        if python3 "$DIR/screenshot_portal.py" "$SHOT" >/dev/null 2>&1; then
            COLOR=$("$IMG" "$SHOT" -resize 1x1\! -alpha off txt:- 2>/dev/null \
                | sed -n '2p' | grep -oE '\([0-9]+,[0-9]+,[0-9]+\)' | head -1 \
                | tr -d '()')
            [ -n "$COLOR" ] && publish fedora/light/color "$COLOR"
        fi
        sleep "$INTERVAL"
    done
    rm -f "$STOPFILE"
    publish fedora/light/end 1
}

start() {
    conf_load
    rm -f "$STOPFILE"
    publish fedora/light/start 1
    nohup bash "$SELF" _loop >/dev/null 2>&1 &
}

end() {
    touch "$STOPFILE"
}

case "${1:-}" in
    start) start ;;
    end)   end ;;
    _loop) loop ;;
    *) echo "uso: ambilight.sh start|end" >&2; exit 1 ;;
esac
