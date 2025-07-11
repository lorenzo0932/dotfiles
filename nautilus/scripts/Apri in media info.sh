#!/bin/bash
IFS=$'\n'

flatpak run net.mediaarea.MediaInfo $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS

