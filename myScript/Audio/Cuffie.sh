#!/bin/bash
# Switch the default audio sink to the wired headphones on the USB Sound Blaster.
#
# The sink name is resolved at runtime: PipeWire appends a numeric suffix to node
# names after suspend/reconnect (e.g. ...analog-stereo.2), so hardcoding it makes
# the switch fail silently.
#
# EasyEffects must keep "Use Default Output" enabled (PipeWire tab): EE then
# follows the system default sink and this script controls the output device.

set -u

pattern='usb-Generic_Sound_Blaster_Play__4.*analog-stereo'

sink=$(pactl list short sinks | awk -v p="$pattern" '$2 ~ p { print $2 }' | sort | head -n1)

if [ -z "${sink:-}" ]; then
    msg="Cuffie (Sound Blaster): sink non trovato"
    printf '%s\n' "$msg" >&2
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Switch audio" "$msg"
    exit 1
fi

if ! pactl set-default-sink "$sink"; then
    msg="Cuffie: impossibile impostare '$sink'"
    printf '%s\n' "$msg" >&2
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Switch audio" "$msg"
    exit 1
fi
