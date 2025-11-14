#!/bin/bash
#
# Theme Switcher for Hyprland
# 
# This script sets a specific theme (light or dark) for Hyprland components:
# 1. Sets GTK color scheme via gsettings (prefer-light or prefer-dark)
# 2. Terminates waypaper process and waits for it to fully exit
# 3. Updates post_command in waypaper/config.ini to use specified theme mode
# 4. Updates theme_mode variable in swww_random_standalone.sh
# 5. Extracts current wallpaper path from waypaper config
# 6. Verifies wallpaper file exists
# 7. Applies theme using matugen with the current wallpaper
#

# --- Configuration ---
readonly THEME_MODE="dark"
readonly WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
readonly SWWW_SCRIPT="$HOME/user_scripts/swww/swww_random_standalone.sh"

# --- Validate Theme Mode ---
if [[ "$THEME_MODE" != "light" && "$THEME_MODE" != "dark" ]]; then
    echo "Error: THEME_MODE must be either 'light' or 'dark', got '$THEME_MODE'" >&2
    exit 1
fi

# --- Check if required files exist ---
if [[ ! -f "$WAYPAPER_CONFIG" ]]; then
    echo "Error: waypaper config not found at $WAYPAPER_CONFIG" >&2
    exit 1
fi

if [[ ! -f "$SWWW_SCRIPT" ]]; then
    echo "Error: swww script not found at $SWWW_SCRIPT" >&2
    exit 1
fi

# --- Set GTK color scheme ---
if [[ "$THEME_MODE" == "light" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
fi

# --- Terminate waypaper and wait for it to fully exit ---
if pgrep -x waypaper > /dev/null; then
    echo "Terminating waypaper..."
    pkill -x waypaper
    # Wait for waypaper to fully terminate (max 2 seconds)
    for _ in {1..20}; do
        if ! pgrep -x waypaper > /dev/null; then
            break # It's gone, break the loop
        fi
        sleep 0.1
    done

    # If it's *still* running after 2 seconds, force kill it
    if pgrep -x waypaper > /dev/null; then
        echo "waypaper did not terminate gracefully, force killing." >&2
        pkill -9 -x waypaper
        sleep 0.5 # Give the OS time to process the SIGKILL
    fi
fi

# --- Update waypaper config ---
sed -i "s/post_command = matugen --mode \(light\|dark\) image \$wallpaper/post_command = matugen --mode $THEME_MODE image \$wallpaper/" "$WAYPAPER_CONFIG"

# --- Update swww script ---
sed -i "s/readonly theme_mode=\"\(light\|dark\)\" # <-- SET THIS/readonly theme_mode=\"$THEME_MODE\" # <-- SET THIS/" "$SWWW_SCRIPT"

# Ensure all file changes are written to disk
sync

# Brief pause to ensure filesystem operations complete
sleep 0.2

# --- Extract current wallpaper path ---
current_wallpaper_path=$(grep '^wallpaper = ' "$WAYPAPER_CONFIG" | awk -F' = ' '{print $2}')

if [[ -z "$current_wallpaper_path" ]]; then
    echo "Error: Could not find wallpaper path in $WAYPAPER_CONFIG" >&2
    exit 1
fi

# Expand tilde to full path
current_wallpaper_path="${current_wallpaper_path/#\~/$HOME}"

# Verify wallpaper file exists
if [[ ! -f "$current_wallpaper_path" ]]; then
    echo "Error: Wallpaper file does not exist: $current_wallpaper_path" >&2
    exit 1
fi

# --- Apply theme with matugen ---
echo "Setting theme to: $THEME_MODE"
echo "Using wallpaper: $current_wallpaper_path"

# We run matugen and intentionally ignore its exit code.
# '2>/dev/null' hides the minor, ignorable errors from the console.
# '|| true' ensures this line *always* returns a 0 (success) exit code,
# so the script will *never* exit here, even if matugen fails.
matugen --mode "$THEME_MODE" image "$current_wallpaper_path" 2>/dev/null || true

# As requested, wait 2 seconds. This gives any background processes
# that matugen may have started time to complete their theming
# before this script finishes and exits.
echo "Waiting 2 seconds for theming processes to complete..."
sleep 2

echo "Theme update triggered for $THEME_MODE. Script finished."
exit 0
