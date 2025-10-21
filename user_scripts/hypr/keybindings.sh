#!/bin/bash
#
# A script to display Hyprland keybindings defined in your configuration
# using rofi for an interactive search menu.
#

# --- CONFIGURATION ---
# Set the path to your keybindings file.
# The script will first check for 'keybindings.conf' and then fall back to 'hyprland.conf'.
KEYBINDINGS_CONF="$HOME/.config/hypr/source/keybinds.conf"
HYPRLAND_CONF="$HOME/.config/hypr/hyprland.conf"

# --- SCRIPT LOGIC ---

# Determine which configuration file to use
if [ -f "$KEYBINDINGS_CONF" ]; then
  CONFIG_FILE="$KEYBINDINGS_CONF"
elif [ -f "$HYPRLAND_CONF" ]; then
  CONFIG_FILE="$HYPRLAND_CONF"
else
  # If no config file is found, show an error using rofi's error mode and exit.
  rofi -e "Error: Hyprland configuration file not found."
  exit 1
fi

# Process the configuration file to extract and format keybindings
# 1. `grep` finds all lines starting with 'bind' (allowing for leading spaces).
# 2. The first `sed` removes comments (anything after a '#').
# 3. `awk` does the heavy lifting of formatting the output.
#    - It sets the field separator to a comma ','.
#    - It removes the 'bind... =' part from the beginning of the line.
#    - It joins the key combination (e.g., "SUPER + Q").
#    - It joins the command that the key executes.
#    - It prints everything in a nicely aligned format.
# 4. The final `sed` cleans up any leftover commas from the end of lines.
# 5. The result is piped into rofi.
#    - `-dmenu`: Enables dynamic menu mode, reading from stdin.
#    - `-i`: Enables case-insensitive searching.
#    - `-p`: Sets the prompt text.
#    - `-theme-str`: Allows overriding specific theme properties. Here, we set the window size.
#    - `flock`: Prevents multiple instances of this rofi menu from running simultaneously.
grep '^[[:space:]]*bind' "$CONFIG_FILE" |
  sed 's/\#.*//' |
  awk -F, '{
        # Remove the "bind... =" part and any surrounding whitespace
        sub(/^[[:space:]]*bind[^=]*=[[:space:]]*/, "", $1);

        # Combine the modifier and key (first two fields)
        key_combo = $1 " + " $2;
        gsub(/^[ \t]+|[ \t]+$/, "", key_combo); # Trim whitespace

        # Reconstruct the command from the remaining fields
        action = "";
        for (i = 3; i <= NF; i++) {
            action = action $i (i < NF ? "," : "");
        }
        gsub(/^[ \t]+|[ \t]+$/, "", action); # Trim whitespace

        # Print only if an action exists
        if (action != "") {
            printf "%-35s → %s\n", key_combo, action;
        }
    }' |
  sed 's/,$//' |
  flock --nonblock /tmp/.rofi_hyprland_binds.lock -c "rofi -dmenu -i -p 'Hyprland Keybindings' -theme-str 'window {width: 60%; height: 70%;}'"
