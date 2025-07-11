# AniDownloader: Anime Download and Conversion System

This repository contains a Python script and its related configuration files and utilities to automate the download and conversion of anime episodes.

## 1. `downloadAnime.sh` (Main Script)

This is the main Python script that manages the entire process of downloading and converting anime episodes.

**Main Features:**
- **Configuration Loading**: Reads series data from the `series_data.json` file to know which anime to download and where to save them.
- **Next Episode Determination**: Identifies the last downloaded episode in a specific folder and calculates the number of the next episode to download.
- **Parallel Download**: Uses `aria2c` to download episodes in parallel, optimizing download speed.
- **Series Continuation Management**: Supports series that span multiple seasons, renaming files based on the overall episode numbering.
- **Video Conversion**: Calls the `Converti e verifica.sh` script to convert downloaded episodes to H.265 format, reducing file size.
- **Final Report**: At the end of execution, it provides a detailed summary of downloaded episodes, conversion status, and time taken for each operation.

**Dependencies:**
- `python3`: Required for script execution.
- `aria2c`: Command-line tool for accelerated downloading.
- `ffmpeg`: Used by the `Converti e verifica.sh` script for video conversion and verification.

## 2. `series_data.json` (Configuration File)

This JSON file is essential for configuring the series that `downloadAnime.sh` needs to download. **Do not directly modify `series_data.json` if you don't know what you are doing.**

To add new series or modify existing ones, refer to the `series_data_template.json` template.

### Series Object Structure:

Each object within the JSON array represents a series and must contain the following properties:

- **`name`**: The full name of the series.
- **`path`**: The full local path where the series episodes will be saved, followed by the season number (e.g., `/home/lorenzo/Video/Simulcast/SeriesName/1`).
- **`link_pattern`**: The download link pattern for the series. It is crucial to replace the episode number with `{ep}`. Example: `https://srv16-suisen.sweetpixel.org/DDL/ANIME/SentaiDaishikkaku2/SentaiDaishikkaku2_Ep_{ep}_SUB_ITA.mp4`.
- **`continue`**: (Optional) A boolean value (`true` or `false`). Set to `true` if the series is a continuation of a previous season and episode numbering should account for already passed episodes.
- **`passed_episodes`**: (Required if `continue` is `true`) An integer defining the total number of episodes from previous seasons already downloaded.

**Example Structure:**

```json
[
    {
        "name": "Series Name",
        "path": "local_series_path/season_number",
        "link_pattern": "series_download_link",
        "continue": true,
        "passed_episodes": 12
    },
    {
        "name": "Series Name2",
        "path": "local_series_path/season_number",
        "link_pattern": "series_download_link"
    }
]
```

## 3. `series_data_template.json` (Configuration Template)

This file serves as a template for creating or modifying the `series_data.json` file.

**Instructions for Use:**
1. Open `series_data_template.json`.
2. **Remove all comments** present in the file (lines starting with `//`).
3. Modify the content by adding information related to your series, following the "Series Object Structure" described above.
4. Save the final file with the name `series_data.json` (without `_template`) in the same directory.

## 4. `Converti e verifica.sh` (Utility Script)

This Bash script is a utility called by `downloadAnime.sh` for video conversion and verification.

**Main Features:**
- **H.265 Conversion**: Uses `ffmpeg` to convert input video files to H.265 codec, optimizing file size while maintaining good quality.
- **Integrity Check**: After conversion, `ffmpeg` is used to verify that the converted file does not contain errors or corruption.
- **Error Handling**: If conversion or verification fails, the original file is not deleted, and the converted file (if created) is removed.
- **Rename and Move**: Upon success, the original file is deleted, and the converted file is moved to the correct directory.

## 5. `AniDownloader.desktop` (Desktop Launcher)

This file is a desktop application for Linux systems (compatible with desktop environments like GNOME, KDE, etc.) that provides a simple way to launch the `downloadAnime.sh` script with a double click.

**Details:**
- **`Name=AniDownloader`**: The displayed name of the application in the menu or on the desktop.
- **`Comment=Scarica tutti gli anime in simulcast configurati`**: A brief description of its function.
- **`Path=/home/lorenzo/.local/share/myScript/downloadAnime/`**: Specifies the working directory from which the `downloadAnime.sh` script will be executed.
- **`Exec=sh -c './downloadAnime.sh'`**: The actual command executed when the application is launched.
- **`Icon=/home/lorenzo/.local/share/myScript/downloadAnime/logo.png`**: The path to the icon displayed for the application.
- **`Terminal=true`**: Indicates that the application should be run within a terminal window, allowing script output to be viewed.
