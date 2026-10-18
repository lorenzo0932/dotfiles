#!/bin/bash
# Switch the default audio sink to the speakers/TV on HDMI (Navi 21/23, HDMI 4).
# See Cuffie.sh for why the sink name is resolved at runtime instead of hardcoded.

set -u

pattern='pci-0000_29_00.1.hdmi-stereo-extra3'

sink=$(pactl list short sinks | awk -v p="$pattern" '$2 ~ p { print $2 }' | sort | head -n1)

if [ -z "${sink:-}" ]; then
    msg="Casse (HDMI): sink non trovato"
    printf '%s\n' "$msg" >&2
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Switch audio" "$msg"
    exit 1
fi

if ! pactl set-default-sink "$sink"; then
    msg="Casse: impossibile impostare '$sink'"
    printf '%s\n' "$msg" >&2
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Switch audio" "$msg"
    exit 1
fi
