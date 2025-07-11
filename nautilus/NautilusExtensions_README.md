# nautilus/

This directory contains custom scripts and configurations for the Nautilus file manager (also known as GNOME Files). These additions extend Nautilus's functionality by providing quick actions accessible directly from the file manager's context menu.

## Guidelines:
- Scripts placed in `nautilus/scripts/` are automatically accessible via the right-click context menu in Nautilus.
- Ensure all scripts have executable permissions (`chmod +x script_name.sh`).
- Test new scripts thoroughly in a safe environment before relying on them for critical tasks.
- Be mindful of the commands executed by these scripts, as they run with your user's permissions.
