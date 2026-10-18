#!/bin/bash
# Watch logind for resume-from-suspend and re-apply the Sound Blaster volume
# (see ResumeVolume.sh). Runs as the user service soundblaster-volume-resume.
#
# Why a user service and not a /usr/lib/systemd/system-sleep/ hook: systemd
# freezes user.slice during the sleep transition and runs those hooks while it
# is still frozen (sleep.c: freeze -> pre -> suspend -> post -> thaw), so a hook
# cannot talk to the user's PipeWire. Here we listen on the system bus for
# logind's PrepareForSleep(false) (emitted on resume); the broadcast is delivered
# as soon as the session thaws.

set -u
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

apply="$HOME/.local/share/myScript/Audio/ResumeVolume.sh"

logger -t soundblaster-resume "watcher started (pid $$)" 2>/dev/null

# stdbuf -oL: gdbus block-buffers its stdout when writing to a pipe, which would
# delay (or swallow) the signal line.
stdbuf -oL gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1 2>/dev/null \
| grep --line-buffered 'PrepareForSleep' \
| while IFS= read -r line; do
    case "$line" in
        *'false'*)
            logger -t soundblaster-resume "resume detected, re-applying volume" 2>/dev/null
            "$apply"
            ;;
    esac
done
