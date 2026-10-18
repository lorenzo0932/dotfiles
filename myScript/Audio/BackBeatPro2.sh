#!/bin/bash
# Switch the default audio sink to the Plantronics BackBeat Pro 2 (Bluetooth).
#
# The MAC is matched loosely because PipeWire may expose it with '_' or ':'
# separators (bluez_output.BC_F2_92_7E_A5_50.1 vs bluez_output.BC:F2:92:7E:A5:50).
# See Cuffie.sh for why the sink name is resolved at runtime.

set -u

pattern='bluez_output.BC.F2.92.7E.A5.50'

sink=$(pactl list short sinks | awk -v p="$pattern" '$2 ~ p { print $2 }' | sort | head -n1)

if [ -z "${sink:-}" ]; then
    msg="BackBeat Pro 2: cuffie Bluetooth non collegate"
    printf '%s\n' "$msg" >&2
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Switch audio" "$msg"
    exit 1
fi

if ! pactl set-default-sink "$sink"; then
    msg="BackBeat Pro 2: impossibile impostare '$sink'"
    printf '%s\n' "$msg" >&2
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Switch audio" "$msg"
    exit 1
fi
