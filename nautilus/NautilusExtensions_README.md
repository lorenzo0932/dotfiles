# nautilus/ - Nautilus Extensions Overview

This directory contains custom context menu scripts for the Nautilus file manager (GNOME Files). They enable fast video conversion, file integrity verification, and media metadata inspection directly from the right-click menu.

## Scripts Directory Structure (`nautilus/scripts/`)

*   **[Apri in media info.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Apri%20in%20media%20info.sh)**: Opens target media file using the `mediainfo` GUI.
*   **[Converti e sposta (Burst).sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Converti%20e%20sposta%20%28Burst%29.sh)**: High-performance concurrent video conversion and file transfer script.
*   **[Converti e sposta (Silent).sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Converti%20e%20sposta%20%28Silent%29.sh)**: Runs video conversion and movement silently in the background.

### Subdirectories and Specialized Utilities

#### 1. [Conversione con sottotitoli (legacy)](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Conversione%20con%20sottotitoli%20%28legacy%29/)
Older versions of subtitle processing workflows.
*   Handles subtitle burning (`burn sottotitoli`) and general subtitle embedding during conversion, with options to suspend the PC after completion.

#### 2. [Converti Video Lezioni](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Converti%20Video%20Lezioni/)
Tailored scripts to convert online class lectures to space-saving formats.
*   [Converti Lezioni.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Converti%20Video%20Lezioni/Converti%20Lezioni.sh) / [Converti Lezioni e sospendi.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Converti%20Video%20Lezioni/Converti%20Lezioni%20e%20sospendi.sh).

#### 3. [Experimental](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Experimental/)
Work-in-progress and cutting edge video processing filters and codecs.
*   [ConversioneAnime4k.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Experimental/ConversioneAnime4k.sh): Applies Anime4K upscaling/processing to video files via script.
*   [Converti e verifica AV1.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Experimental/Converti%20e%20verifica%20AV1.sh): Video conversion leveraging AV1 codec encoders.

#### 4. [Verifica Integrità Video](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Verifica%20Integrità%20Video/)
Validates that media container streams are not corrupted.
*   [Verifica Video.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Verifica%20Integrità%20Video/Verifica%20Video.sh) (standard CPU check) / [Verifica Video GPU.sh](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/Verifica%20Integrità%20Video/Verifica%20Video%20GPU.sh) (leverages hardware decoding).

#### 5. [old](file:///home/lorenzo/Documenti/GitHub/dotfiles/nautilus/scripts/old/)
Archived scripts for legacy multi-process conversions.

---

## Guidelines:
- Scripts placed in `nautilus/scripts/` are automatically accessible via the right-click context menu in Nautilus (under "Scripts").
- Ensure all scripts have executable permissions (`chmod +x script_name.sh`).
- Test new scripts thoroughly in a safe environment before relying on them for critical tasks.
- Be mindful of the commands executed by these scripts, as they run with your user's permissions.
