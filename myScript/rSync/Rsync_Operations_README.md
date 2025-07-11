# rSync Dotfiles with LLM-Generated Commits

This directory contains Bash scripts and configuration files for automating `rsync` operations and Git commits, leveraging a Large Language Model (LLM) for concise commit messages.

## Project Overview

-   `rSync.sh`: Main script for dotfile synchronization and automated Git commits.
-   `rSync_dev.sh`: A development version of `rSync.sh`, useful for testing.
-   `rSync copy.sh`: An additional copy of the script, for backup or specific purposes.
-   `exclude.txt`: Defines file/directory patterns to be excluded during `rsync` synchronization.
-   `gemini.env`: (Used for API key configuration, but excluded from documentation).

## Features

-   **Automated Synchronization**: Uses `rsync` to keep dotfiles updated from source directories to a specified destination.
-   **Intelligent Git Commits**: Automatically detects file changes and prepares a Git commit.
-   **LLM-Powered Commit Messages**: Integrates a Large Language Model (LLM) (configurable for Google AI/Gemini or LM Studio) to generate meaningful commit messages based on file differences.
-   **Flexible API Support**: Choose between Google AI (Gemini) API or a local LM Studio API server.
-   **Custom Exclusions**: Configure ignored files/directories via `exclude.txt`.

## Configuration

Before running, edit `rSync.sh` (or `rSync_dev.sh`) to set up:

1.  **Source & Destination Paths**:
    Modify the `--- Configuration ---` section:
    ```bash
    MYSCRIPTS="/home/lorenzo/.local/share/myScript"
    NAUTILUS_SCRIPTS="/home/lorenzo/.local/share/nautilus"
    SYSTEMD_SERVICES="/home/lorenzo/.config/systemd"
    DEST="/home/lorenzo/Documenti/GitHub/dotfiles" # Your dotfiles repository folder
    ```

2.  **LLM API**:
    Choose and configure your preferred LLM API in the `--- API Configuration ---` section:
    -   **Google AI (Gemini)**: Set `GOOGLE_API_KEY` (recommended via environment variable or a file, e.g., `~/.config/google-ai-api-key.txt`) and `LLM_MODEL` (default `gemini-2.5-flash`).
    -   **LM Studio**: Uncomment and configure `LMSTUDIO_API_URL` (e.g., `http://localhost:1234/v1/chat/completions`) and `LMSTUDIO_MODEL` (your LM Studio model name).

3.  **`exclude.txt`**:
    This file specifies `rsync` exclusions. Current content:
    ```
    tags
    tracker2-migration-complete
    series_data.json
    gemini.env
    ```
    Modify this file to add or remove items you do not want to synchronize.

## Usage

1.  **Make Executable**:
    ```bash
    chmod +x rSync.sh
    ```

2.  **Run the Script**:
    ```bash
    ./rSync.sh
    ```
    The script will perform the following operations:
    -   Synchronize files from source directories to the destination using `rsync`.
    -   Check for any changes to commit in the Git repository.
    -   If changes are detected, it will generate a commit message using the configured LLM.
    -   Commit the changes and push them to the `main` branch of your remote repository.

## Prerequisites

Ensure you have `rsync`, `git`, `curl`, and `jq` installed on your system. The Git repository must be initialized and configured with a remote named `origin` and a `main` branch.
