#!/bin/bash
# Re-apply the output volume after a resume from suspend.
#
# Why: the USB Sound Blaster resets its *hardware* volume register when it loses
# power during suspend. WirePlumber restores the value it knows, but the hardware
# stays lower until something writes it again -- the "after standby it is quieter,
# but nudging the volume gives a boost" symptom. Re-issuing the same value forces
# that hardware write.
#
# Started by WatchResume.sh (a user service), i.e. inside the user session, right
# after the session is thawed.

set -u

# Force the session runtime dir (works both under systemd --user and runuser).
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

sink_pattern='usb-Generic_Sound_Blaster_Play__4.*analog-stereo'

log() { logger -t soundblaster-resume "$*" 2>/dev/null; }

apply() {
    local sink vol
    sink=$(pactl list short sinks 2>/dev/null | awk -v p="$sink_pattern" '$2 ~ p { print $2 }' | sort | head -n1)
    [ -z "${sink:-}" ] && return 1
    vol=$(pactl get-sink-volume "$sink" 2>/dev/null | grep -oE '[0-9]+%' | head -n1)
    [ -z "${vol:-}" ] && return 1
    pactl set-sink-volume "$sink" "$vol" 2>/dev/null && log "re-applied $vol on $sink"
}

# Wait for the sink to come back (USB re-enumeration after resume is not instant).
for _ in $(seq 1 20); do
    apply && break
    sleep 0.5
done

# Apply once more once the graph has settled: the device can re-enumerate twice.
sleep 2
apply
