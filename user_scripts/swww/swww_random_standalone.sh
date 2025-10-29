#!/bin/bash
#
# switch_theme_wallpaper.sh
#
# Silently switches to a random wallpaper from the current theme's wallpaper
# directory, ensuring the new wallpaper is not the one currently set.
# Requires 'swww' and 'realpath'.

# --- 1. Silence all script output ---
# This script is intended to be run from a keybind, so no stdout or stderr
# should be produced under any circumstances.
exec >/dev/null 2>&1

# --- 2. Verify 'swww' is installed ---
# If 'swww' is not found in PATH, exit immediately.
command -v swww >/dev/null || exit 1

# --- 3. Define core paths ---
THEME_FILE="$HOME/.config/theming/user_set_theme.txt"

# --- 4. Read current theme name ---
# Exit if the theme file doesn't exist, is unreadable, or is empty.
[[ -f "$THEME_FILE" && -r "$THEME_FILE" ]] || exit 1
THEME_NAME=$(<"$THEME_FILE")
[[ -n "$THEME_NAME" ]] || exit 1

# --- 5. Construct and validate wallpaper directory ---
# Exit if the determined wallpaper directory does not exist.
WALLPAPER_DIR="$HOME/.config/theming/all_themes/$THEME_NAME/wallpaper"
[[ -d "$WALLPAPER_DIR" ]] || exit 1

# --- 6. Get the real path of the current wallpaper ---
# We query swww, find the first line reporting a displayed image,
# extract the path, and then find its canonical path using 'realpath'.
# This is crucial for correctly comparing against other potential wallpapers,
# which might be symlinks.
CURRENT_WALLPAPER_PATH=$(swww query | grep 'currently displaying: image:' | head -n 1 | sed 's/.*currently displaying: image: //')

CURRENT_WALLPAPER_REAL=""
if [[ -n "$CURRENT_WALLPAPER_PATH" && -f "$CURRENT_WALLPAPER_PATH" ]]; then
    # We only get the real path if a valid file path was found.
    CURRENT_WALLPAPER_REAL=$(realpath "$CURRENT_WALLPAPER_PATH")
fi

# --- 7. Find all valid, non-current wallpapers ---
# We build an array of all files in the wallpaper directory
# whose real path does not match the current wallpaper's real path.
CANDIDATES=()
while IFS= read -r -d '' file; do
    # Get the real path of the candidate file
    CANDIDATE_REAL=$(realpath "$file")

    # If its real path is different from the current one, add its
    # *original* path to our array of candidates.
    if [[ "$CANDIDATE_REAL" != "$CURRENT_WALLPAPER_REAL" ]]; then
        CANDIDATES+=("$file")
    fi
done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f -print0) # Safely handles all filenames

# --- 8. Select and apply a new wallpaper ---
NUM_CANDIDATES=${#CANDIDATES[@]}

if (( NUM_CANDIDATES > 0 )); then
    # If we have at least one valid candidate (i.e., the directory
    # contains more than just the currently set wallpaper).
    
    # Pick a random index from the candidates array
    RANDOM_INDEX=$((RANDOM % NUM_CANDIDATES))
    NEW_WALLPAPER="${CANDIDATES[$RANDOM_INDEX]}"

    # Apply the new wallpaper using the specified swww command
    swww img "$NEW_WALLPAPER" \
        --transition-type grow \
        --transition-duration 2 \
        --transition-fps 60
fi

# --- 9. Exit silently ---
# If NUM_CANDIDATES was 0, it means the only wallpaper(s) available
# was the one already set, so we do nothing and exit.
exit 0
