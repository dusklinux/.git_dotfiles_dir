#!/usr/bin/env bash

# set_random_wallpaper.sh
# Selects a random wallpaper, sets it with swww, and updates matugen.

# --- BEGIN USER CONFIGURATION ---

# 1. WALLPAPER_DIR: The absolute path to your wallpaper collection.
#    N.B.: Do not include a trailing slash.
readonly WALLPAPER_DIR="$HOME/Pictures/wallpapers" # <-- SET THIS

# 2. SWWW_OPTS: Your preferred options for the swww command.
#    These are expanded via shell word-splitting.
readonly SWWW_OPTS="--transition-type grow --transition-duration 2 --transition-fps 60"

# 3. theme_mode: The theme mode for matugen.
#    Valid options are "light" or "dark".
#   DONT CHANGE THESE MANUALLY, THE WAYBAR SCRIPT WILL EDIT THIS . 
readonly theme_mode="dark" # <-- SET THIS

# --- END USER CONFIGURATION ---

# 1. Prerequisite Validation
# Ensure essential binaries are present in the $PATH.
if ! command -v swww &> /dev/null; then
    echo "Fatal: 'swww' command not found." >&2
    exit 1
fi

if ! command -v matugen &> /dev/null; then
    echo "Fatal: 'matugen' command not found." >&2
    exit 1
fi

# 2. Directory Validation
# Confirm the target directory is configured and accessible.
if [[ -z "$WALLPAPER_DIR" ]] || [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "Fatal: WALLPAPER_DIR is not set or is not a valid directory." >&2
    echo "Please edit this script and configure the WALLPAPER_DIR variable." >&2
    exit 1
fi

# 3. Daemon Initialization
# Ensure the swww daemon is operational before proceeding.
swww query &> /dev/null || swww init &> /dev/null

# 4. Random Image Selection
# This find/shuf pipeline is O(N) but O(1) in memory, and handles all
# possible filenames (spaces, newlines, etc.) by using null delimiters.
# We explicitly filter for common image file extensions.
readonly RANDOM_WALLPLAYER=$(find "$WALLPAPER_DIR" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    -print0 | shuf -z -n 1)

# 5. Execution
# Proceed only if a valid file was selected.
if [[ -z "$RANDOM_WALLPLAYER" ]]; then
    echo "Fatal: No compatible image files found in $WALLPAPER_DIR." >&2
    exit 1
else
    # A. Set the wallpaper using the configured options.
    swww img "$RANDOM_WALLPLAYER" $SWWW_OPTS

    # B. Execute the post-wallpaper command (matugen).
    matugen --mode "$theme_mode" image "$RANDOM_WALLPLAYER"
fi

exit 0
