# myScript/mpv/

This directory contains a comprehensive set of configuration files, scripts, fonts, and shaders for the MPV media player. It aims to enhance the MPV experience with custom keybindings, advanced playback options, visual improvements, and additional functionalities.

## Purpose:
- `input.conf`: Defines custom keyboard shortcuts and mouse bindings for MPV, allowing for personalized control over playback and features.
- `mpv.conf`: The main configuration file for MPV, containing core settings related to video output, audio, caching, and general behavior.
- `bak/`: A backup directory for previous MPV configurations, useful for reverting changes or recovering settings.
- `fonts/`: Stores custom fonts used by MPV, potentially for subtitles or on-screen display elements (OSD).
- `script-opts/`: Contains configuration files for various MPV Lua scripts, such as `osc.conf` (On-Screen Controller), `thumbfast.conf`, and `uosc.conf` (User On-Screen Controller).
- `scripts/`: Houses Lua scripts that extend MPV's functionality, including `dynamic-crop.lua`, `thumbfast.lua`, and `uosc/` (a more advanced on-screen controller).
- `shaders/`: Contains GLSL shaders for real-time video processing, including a wide array of Anime4K shaders for upscaling and enhancing anime content, and FSRCNNX shaders for general video upscaling.

## Guidelines:
- **Customization**: Feel free to modify `input.conf` and `mpv.conf` to suit your preferences, but always back up your changes.
- **Script Management**: If adding new scripts, ensure they are placed in the `scripts/` directory and their options (if any) are configured in `script-opts/`.
- **Shader Usage**: Shaders in the `shaders/` directory can be loaded via `mpv.conf` or dynamically during playback. Experiment with different shaders to find the best visual enhancements for your content.
- **Dependencies**: Ensure MPV is installed and properly configured on your system for these files to take effect.
- **Updates**: When updating MPV, be aware that some configurations or scripts might require adjustments due to changes in MPV's API or behavior.
