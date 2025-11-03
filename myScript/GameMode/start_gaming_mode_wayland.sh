#!/bin/bash

# ==============================================================================
# Inizializzazione Ambiente D-Bus

# Attendi un istante
sleep 4

# ==============================================================================
# SEZIONE TEMPORANEAMENTE DISATTIVATA PER DEBUGGING
# ==============================================================================
# echo "Switching to workspace ${TARGET_WORKSPACE}..."
# gdbus call --session \
#            --dest org.gnome.Shell \
#            --object-path /org/gnome/shell \
#            --method org.gnome.Shell.Eval "imports.ui.main.wm.actionMoveToWorkspace(global.workspace_manager.get_active_workspace(), global.workspace_manager.get_workspace_by_index(${TARGET_WORKSPACE}));"
#
# sleep 0.5
#
# echo "Closing applications..."
# RUNNING_APPS=$(gdbus call --session \
#                           --dest org.gnome.Shell \
#                           --object-path /org/gnome/shell \
#                           --method org.gnome.Shell.GetRunningApps)
#
# APP_IDS=$(echo "$RUNNING_APPS" | grep -oP "'[a-zA-Z0-9.-]+.desktop'")
#
# for app_id_quoted in $APP_IDS; do
#     app_id=$(sed "s/'//g" <<< "$app_id_quoted")
#     
#     should_ignore=0
#     for ignored in "${APPS_TO_IGNORE[@]}"; do
#         if [[ "$app_id" == "$ignored" ]]; then
#             should_ignore=1
#             break
#         fi
#     done
#
#     if [[ $should_ignore -eq 0 ]]; then
#         echo "Closing application: $app_id"
#         gdbus call --session \
#                    --dest org.gnome.Shell \
#                    --object-path /org/gnome/shell \
#                    --method org.gnome.Shell.AppSystem.get_default \
#                    | sed "s/^('(.*)',)/\1/" \
#                    | xargs -I {} gdbus call --session \
#                                             --dest org.gnome.Shell \
#                                             --object-path {} \
#                                             --method org.gnome.Shell.App.activateAction "quit" 0
#     else
#         echo "Ignoring application: $app_id"
#     fi
# done
#
# sleep 2
# ==============================================================================


# 3. Lancia Steam in modalità Big Picture
echo "Starting Steam in Big Picture mode (DEBUG)..."
steam -bigpicture &

echo "Gaming mode script finished (DEBUG)."
exit 0
