# myScript/rSync/

This directory contains Bash scripts and configuration files for performing `rsync` operations, used for data synchronization and backup.

## Purpose:
- `rSync.sh`: This is the main rsync script, configured to synchronize or back up specific directories or files. It includes parameters for source, destination, and various rsync options.
- `rSync copy.sh`: This script is a variant of the main rsync script, designed for specific copy operations or testing.
- `exclude.txt`: This file lists patterns (e.g., file names, directory names, or wildcards) that `rsync` ignores during synchronization. This is crucial for excluding temporary files, caches, or sensitive data from backups.

## Guidelines:
- **Configuration**: Before running any rsync script, carefully review `rSync.sh` and `rSync copy.sh` to understand their source, destination, and rsync options. Incorrect configuration can lead to data loss.
- **Exclusions**: Maintain `exclude.txt` to ensure that unnecessary or sensitive files are not synchronized. Each pattern should be on a new line.
- **Permissions**: Ensure the rsync scripts have executable permissions (`chmod +x rSync.sh` and `chmod +x rSync copy.sh`).
- **Testing**: It is highly recommended to perform a dry run (`--dry-run` option in rsync) before executing actual synchronization to verify the intended changes.
- **Backup Strategy**: Integrate these scripts into a broader backup strategy, considering frequency, retention, and off-site storage if necessary.

This is a test 2