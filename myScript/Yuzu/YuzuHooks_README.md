# myScript/Yuzu/

This directory contains Bash scripts designed to execute specific actions before and after a resolution change, primarily in the context of the Yuzu Nintendo Switch emulator. These scripts are useful for automating display adjustments or other system configurations when launching or exiting Yuzu.

## Purpose:
- `PreCambioRisolzione.sh`: This script executes before a resolution change occurs. It is used to prepare the system for a new display resolution, which might include disabling certain services, adjusting display settings, or performing other pre-launch tasks for Yuzu.
- `PostCambioRisoluzione.sh`: This script executes after a resolution change has been applied. It is used to revert system settings, re-enable services, or perform any post-exit cleanup or configuration adjustments once Yuzu has finished running or the display mode is no longer needed.

## Guidelines:
- **Integration**: These scripts are intended to be integrated with Yuzu's launch or exit procedures, or with a broader display management system. Ensure they are called at the appropriate times.
- **Configuration**: Review the contents of both scripts (`.sh` files) to ensure that the commands and settings (e.g., `xrandr` commands, service management) are correctly configured for your system and Yuzu setup.
- **Permissions**: Ensure both scripts have executable permissions (`chmod +x PreCambioRisolzione.sh` and `chmod +x PostCambioRisoluzione.sh`).
- **Testing**: Thoroughly test the scripts to confirm they execute correctly and do not cause unintended side effects on your display or system.
- **Error Handling**: Implement robust error handling within the scripts to manage unexpected issues during resolution changes.
