#!/usr/bin/env bash

# set_random_wallpaper.sh
# Selects a random wallpaper, sets it with swww, and updates matugen.
# Optimized for Arch Linux (Hyprland/UWSM) on NVIDIA/Intel hybrid hardware.

# --- BEGIN STRICT MODE ---
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error.
# -o pipefail: Return value of a pipeline is the value of the last (failed) command.
set -euo pipefail
# --- END STRICT MODE ---

# --- BEGIN USER CONFIGURATION ---

# 1. WALLPAPER_DIR: The absolute path to your wallpaper collection.
readonly WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# 2. SWWW_OPTS: Options for the swww transition.
readonly SWWW_OPTS="--transition-type grow --transition-duration 2 --transition-fps 60"

# 3. theme_mode: The theme mode for matugen.
#    External scripts (Waybar) modify this line via another the theme_switcher script. DO NOT ALTER FORMATTING.

readonly theme_mode="dark" # <-- SET THIS

# --- END USER CONFIGURATION ---

# 1. Prerequisite Validation
# utilizing a loop for cleaner dependency verification.
for cmd in swww matugen find shuf; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Fatal: Required binary '$cmd' is not in the system PATH." >&2
        exit 1
    fi
done

# 2. Directory Validation
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "Fatal: Directory '$WALLPAPER_DIR' does not exist or is inaccessible." >&2
    exit 1
fi

# 3. Daemon Initialization
# Idempotent check: if the socket is unresponsive, initialize the daemon.
if ! swww query &> /dev/null; then
    swww init &> /dev/null
    # Minimal latency buffer to ensure socket availability before IPC.
    sleep 0.5
fi

# 4. Stochastic Selection & Execution
# We use process substitution <(...) into 'read' to handle null-delimited streams safely.
# This prevents variable expansion issues and strictly handles filenames with exotic characters.
# We seek extensions case-insensitively (-iname).

target_wallpaper=""

# The '|| true' ensures that if find returns nothing, the script doesn't crash due to 'set -e',
# allowing us to handle the empty variable error manually below.
while IFS= read -r -d '' file; do
    target_wallpaper="$file"
done < <(find "$WALLPAPER_DIR" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) \
    -print0 | shuf -z -n 1 || true)

# 5. Final Execution
if [[ -n "$target_wallpaper" ]]; then
    # Execute wallpaper transition
    # We disable shellcheck for SWWW_OPTS word splitting as it is intentional.
    # shellcheck disable=SC2086
    swww img "$target_wallpaper" $SWWW_OPTS

    # Asynchronously generate the color scheme to return control to the shell immediately,
    # preventing input blocking on your Hyprland instance.
    matugen --mode "$theme_mode" image "$target_wallpaper"
else
    echo "Fatal: No valid image files detected in '$WALLPAPER_DIR'." >&2
    exit 1
fi

exit 0
