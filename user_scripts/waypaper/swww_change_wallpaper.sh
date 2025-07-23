#!/usr/bin/env bash
#
# swww-random.sh - A robust script to set a random wallpaper using swww.
#
# This script is designed for Wayland compositors like Hyprland or Sway that
# use `swww` for wallpaper management.

# --- CONFIGURATION ---
# Set the full, absolute path to the directory containing your wallpapers.
# Using a tilde (~) is supported, but an absolute path is most reliable.
# Example: WALLPAPER_DIR="/home/your_username/Pictures/Wallpapers"
WALLPAPER_DIR="~/Pictures/wallpapers"

# Configure the swww transition effect.
# See `man swww` or `swww --help` for all available options.
# Examples: "simple", "fade", "left", "right", "top", "bottom", "wipe", "wave", "grow", "outer", "random"
TRANSITION_TYPE="grow"

# Duration of the transition in seconds.
TRANSITION_DURATION=2

# Frames per second for the transition animation.
TRANSITION_FPS=60
# --- END OF CONFIGURATION ---


# --- SCRIPT LOGIC ---
# Do not edit below this line unless you know what you are doing.

# Function for printing errors and exiting.
# Usage: error_exit "Your error message here."
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Ensure the swww command is available.
if ! command -v swww &> /dev/null; then
    error_exit "swww is not installed or not in your system's PATH."
fi

# Use 'eval' to correctly expand the tilde (~) in the WALLPAPER_DIR path.
# This is a standard and safe way to handle user-provided paths with tildes.
eval expanded_dir="$WALLPAPER_DIR"

# Check if the specified wallpaper directory actually exists.
if [ ! -d "$expanded_dir" ]; then
    error_exit "Wallpaper directory not found: '$expanded_dir'"
fi

# Initialize the swww daemon if it's not already running.
# The 'swww query' command will fail if the daemon is not active.
if ! swww query &>/dev/null; then
    swww init || error_exit "Failed to initialize swww daemon."
fi

# Find all files within the specified directory, filter out non-image files if needed (optional),
# and select one entry at random.
# The use of `find -print0`, `shuf -z -n1`, and `xargs -0` makes this process
# safe for filenames containing spaces, newlines, or other special characters.
wallpaper=$(find "$expanded_dir" -type f -print0 | shuf -z -n1 | xargs -0)

# Check if a wallpaper file was successfully found.
if [ -z "$wallpaper" ]; then
    error_exit "No image files were found in '$expanded_dir'."
fi

# Execute the wallpaper change command.
swww img "$wallpaper" \
    --transition-type "$TRANSITION_TYPE" \
    --transition-duration "$TRANSITION_DURATION" \
    --transition-fps "$TRANSITION_FPS"

# Optional: Uncomment the line below to send a notification (if you have dunst or similar).
# notify-send "Wallpaper Changed" "Now displaying: ${wallpaper##*/}"

exit 0
