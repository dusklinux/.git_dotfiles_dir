#!/usr/bin/env bash

# set_wallpaper.sh
#
# A robust, silent script to set a random wallpaper via swww based on a
# user-defined theme file.
#
# This script is designed for silent execution within a master script.
# It will exit with 0 on success and a non-zero status on any failure.
# No output will be printed to stdout or stderr.

# --- Configuration ---

# File containing the name of the current theme.
readonly THEME_FILE="$HOME/.config/theming/user_set_theme.txt"

# Base directory where all theme assets are stored.
readonly THEMES_BASE_DIR="$HOME/.config/theming/all_themes"

# Static options for the swww command.
readonly SWWW_OPTS="--transition-type grow --transition-duration 2 --transition-fps 60"

# --- Pre-flight Checks ---

# 1. Ensure swww daemon is operational.
# If the daemon is not running, 'swww init' is invoked.
# All output is suppressed.
if ! pgrep -x swww-daemon > /dev/null 2>&1; then
    swww init > /dev/null 2>&1 &
    # Provide a brief moment for the daemon to initialize.
    sleep 0.5
fi

# 2. Validate and read the theme configuration file.
if [ ! -f "$THEME_FILE" ] || [ ! -r "$THEME_FILE" ]; then
    # Exit silently if file not found or is not readable.
    exit 1
fi

# 3. Read the theme name.
# We read the first line and use 'tr' to remove any potential
# whitespace or newline characters that could corrupt the path.
THEME_NAME=$(head -n 1 "$THEME_FILE" | tr -d '[:space:]')

if [ -z "$THEME_NAME" ]; then
    # Exit silently if the theme name is empty.
    exit 1
fi

# --- Path Construction and Validation ---

# 4. Define the target wallpaper directory.
readonly WALLPAPER_DIR="$THEMES_BASE_DIR/$THEME_NAME/wallpaper"

if [ ! -d "$WALLPAPER_DIR" ]; then
    # Exit silently if the theme's wallpaper directory does not exist.
    exit 1
fi

# --- Wallpaper Selection ---

# 5. Select a random wallpaper from the directory.
# We use 'find' to locate all regular files (images), pipe the list to
# 'shuf' (shuffle), and select the top one ('-n 1').
# This is robust and handles any number of files (including just one).
# We search for common image file extensions, case-insensitively.
readonly WALLPAPER_TO_SET=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) \
    | shuf -n 1)

if [ -z "$WALLPAPER_TO_SET" ]; then
    # Exit silently if no files with valid extensions are found.
    exit 1
fi

# --- Execution ---

# 6. Apply the wallpaper using swww.
# All output is redirected to /dev/null.
# The 'if !' construct captures a failure exit code from swww itself.
if ! swww img "$WALLPAPER_TO_SET" $SWWW_OPTS > /dev/null 2>&1; then
    # Exit silently if the swww command fails.
    exit 1
fi

# 7. Success.
exit 0
