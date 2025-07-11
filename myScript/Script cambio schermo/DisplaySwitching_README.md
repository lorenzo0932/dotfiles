# myScript/Script cambio schermo/

This directory contains Bash scripts designed to manage display configurations, specifically for switching between different display outputs (e.g., a desktop monitor and a TV). These scripts are useful for users who frequently change their display setup.

## Purpose:
- `ReturnToDesktop.sh`: This script configures the display output to revert to a standard desktop monitor setup. It adjusts resolution, refresh rate, and primary display settings as defined within the script.
- `ReturnToTV.sh`: This script configures the display output to switch to a TV setup. It adjusts resolution, refresh rate, and primary display settings suitable for a television, often used for media consumption or gaming.

## Guidelines:
- **Configuration**: Before using, open each script (`.sh` files) and verify that the display names (e.g., `HDMI-1`, `DP-0`) and desired resolutions match your specific hardware setup. Incorrect display names or resolutions can lead to display issues.
- **Permissions**: Ensure both scripts have executable permissions (`chmod +x ReturnToDesktop.sh` and `chmod +x ReturnToTV.sh`).
- **Testing**: Test the scripts after any modifications to ensure they function as expected and correctly switch display modes without issues.
- **Xrandr**: These scripts likely utilize `xrandr` commands. Familiarity with `xrandr` can help in troubleshooting or further customization.
