#!/usr/bin/env bash

# set_random_wallpaper.sh
# Selects a random wallpaper, sets it with swww, and updates matugen.
# Optimized for Arch Linux (Hyprland/UWSM) on NVIDIA/Intel hybrid hardware.

# --- BEGIN STRICT MODE ---
set -euo pipefail
# --- END STRICT MODE ---

# --- BEGIN USER CONFIGURATION ---

# 1. WALLPAPER_DIR: The absolute path to your wallpaper collection.
readonly WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# 2. SWWW_OPTS: Options for the swww transition.
readonly SWWW_OPTS="--transition-type grow --transition-duration 2 --transition-fps 60"

# 3. theme_mode: The theme mode for matugen.
readonly theme_mode="dark" 

# --- END USER CONFIGURATION ---

# 1. Prerequisite Validation
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
if ! swww query &> /dev/null; then
    # Run init via uwsm so the daemon is properly scoped and persistent
    uwsm-app -- swww init &> /dev/null
    sleep 0.5
fi

# 4. Stochastic Selection
target_wallpaper=""
while IFS= read -r -d '' file; do
    target_wallpaper="$file"
done < <(find "$WALLPAPER_DIR" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) \
    -print0 | shuf -z -n 1 || true)

# 5. Final Execution
if [[ -n "$target_wallpaper" ]]; then
    # Execute wallpaper transition (Synchronous)
    # shellcheck disable=SC2086
    swww img "$target_wallpaper" $SWWW_OPTS

    # Asynchronously generate the color scheme.
    # FIX: Added '&' and 'disown' to ensure this runs in background and 
    # returns control to the shell immediately.
    setsid uwsm-app -- matugen --mode "$theme_mode" image "$target_wallpaper" >/dev/null 2>&1 &
else
    echo "Fatal: No valid image files detected in '$WALLPAPER_DIR'." >&2
    exit 1
fi

exit 0
