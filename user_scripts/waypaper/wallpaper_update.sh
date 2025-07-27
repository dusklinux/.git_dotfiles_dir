#!/bin/bash

# This script runs in the background to automatically update pywal colors
# and run a predefined list of custom scripts OR commands whenever the swww wallpaper changes.

# --- 💡 CONFIGURATION: ADD YOUR SCRIPTS OR COMMANDS HERE 💡 ---
CUSTOM_COMMANDS=(
  # rofi
  "cat ~/.cache/wal/colors-rofi-dark.rasi ~/.config/wal/templates/rofi_template.rasi > ~/.config/rofi/config.rasi"
  # firefox
  "pywalfox update"
  # kitty
  "kitty @ set-colors --all --configured ~/.cache/wal/colors-kitty.conf"
  # swaync
  "systemctl --user restart swaync.service"
  #asus keyboard
  "~/user_scripts/asus/asus_keyboard_color_pywal16.sh"
)
# ----------------------------------------------------

# --- Environment Setup for Daemons ---
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
# -------------------------------------------

# Find the directory swww stores its cache in.
SWWW_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/swww"

# Wait for the directory to exist before starting to watch.
while [ ! -d "$SWWW_CACHE_DIR" ]; do
  echo "Waiting for swww cache directory to be created at $SWWW_CACHE_DIR..."
  sleep 5
done

echo "Theme Updater is running, watching for wallpaper changes..."

# Main loop using inotifywait
inotifywait -m -e create,modify --format '%w%f' "$SWWW_CACHE_DIR" | while read -r event; do
    # --- DEBOUNCE LOGIC ---
    # When a wallpaper change occurs, swww may trigger multiple events in quick
    # succession. We only want to run our script once per change.
    # The 'read -t 0.5' command waits for half a second to see if any more
    # events are fired. This effectively groups all events from a single
    # wallpaper change into one, preventing the script from looping rapidly.
    read -t 0.5 -r

    echo "Detected wallpaper change. Updating theme..."

    # It's slightly more reliable to get the wallpaper from the 'event' variable itself
    # in case 'swww query' is slow, but querying is also fine.
    CURRENT_WALLPAPER=$(swww query | awk -F 'image: ' '{print $2}')

    if [ -n "$CURRENT_WALLPAPER" ] && [ -f "$CURRENT_WALLPAPER" ]; then
        # --- CORE ACTIONS ---
        # The '-n' flag skips setting the wallpaper, which swww already did.
        # The '-q' flag makes it quiet.
        wal -i "$CURRENT_WALLPAPER" -n -q

        # --- CUSTOM COMMAND EXECUTION ---
        if [ ${#CUSTOM_COMMANDS[@]} -gt 0 ]; then
            echo "Executing custom commands from the list..."
            for command_string in "${CUSTOM_COMMANDS[@]}"; do
                echo "-> Executing: $command_string"
                # Use 'eval' to execute the string as a command.
                # The '&' at the end runs it in the background to prevent blocking.
                eval "$command_string" &
            done
        else
            echo "-> Custom command list is empty."
        fi

        echo "Theme update complete."
    else
        echo "Could not get current wallpaper or file does not exist. Skipping."
    fi
done
