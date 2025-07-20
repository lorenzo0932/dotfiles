#!/bin/bash

LOG_FILE="/tmp/homeassistant_failure_recovery.log"
echo "$(date): HomeAssistant VM failed to start. Attempting recovery." >> "$LOG_FILE"

# Check if zenity is available for graphical password prompt
if command -v zenity &> /dev/null; then
    # Prompt for sudo password using zenity
    PASSWORD=$(zenity --password --title="HomeAssistant VM Recovery" --text="HomeAssistant VM failed to start. Please enter your sudo password to run recovery commands.")

    if [ -n "$PASSWORD" ]; then
        echo "$PASSWORD" | sudo -S ntfsfix /dev/sdc1 --clear-dirty >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            echo "$(date): ntfsfix executed successfully." >> "$LOG_FILE"
            echo "$PASSWORD" | sudo -S mount -a >> "$LOG_FILE" 2>&1
            if [ $? -eq 0 ]; then
                echo "$(date): mount -a executed successfully. Attempting to restart HomeAssistant service." >> "$LOG_FILE"
                systemctl --user start HomeAssistant.service >> "$LOG_FILE" 2>&1
                zenity --info --title="HomeAssistant VM Recovery" --text="Recovery commands executed successfully. HomeAssistant VM restart attempted."
            else
                echo "$(date): Error executing mount -a." >> "$LOG_FILE"
                zenity --error --title="HomeAssistant VM Recovery" --text="Error executing 'sudo mount -a'. Check $LOG_FILE for details."
            fi
        else
            echo "$(date): Error executing ntfsfix." >> "$LOG_FILE"
            zenity --error --title="HomeAssistant VM Recovery" --text="Error executing 'sudo ntfsfix /dev/sdc1 --clear-dirty'. Check $LOG_FILE for details."
        fi
    else
        echo "$(date): Sudo password not provided. Recovery commands not executed." >> "$LOG_FILE"
        zenity --warning --title="HomeAssistant VM Recovery" --text="Sudo password not provided. Recovery commands not executed. Please run 'sudo ntfsfix /dev/sdc1 --clear-dirty' and 'sudo mount -a' manually."
    fi
else
    echo "$(date): zenity not found. Cannot prompt for password graphically." >> "$LOG_FILE"
    echo "$(date): Please run 'sudo ntfsfix /dev/sdc1 --clear-dirty' and 'sudo mount -a' manually to recover." >> "$LOG_FILE"
    # You might want to add a notification here for non-graphical environments, e.g., using 'notify-send' if available
    # notify-send "HomeAssistant VM Recovery" "zenity not found. Please run recovery commands manually."
fi

exit 0
