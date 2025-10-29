#!/usr/bin/env bash

# ============================================================================
# THEME RELOAD SCRIPT
# ============================================================================
# Reloads applications after theme changes. Runs silently with no logging.
# Designed to be called by a master theme-switching script.
# ============================================================================

# Suppress all output for silent operation
exec &>/dev/null

# Enable error handling but don't exit on errors (continue through all commands)
set +e

# ============================================================================
# USER CONFIGURATION - EDIT THIS SECTION TO ADD/MODIFY COMMANDS
# ============================================================================

# Path to file containing current theme name
THEME_FILE="$HOME/.config/theming/user_set_theme.txt"

# Add your reload commands below (one per line)
# The variable $THEME is available if needed in your commands
# ============================================================================

reload_applications() {
    # Restart SwayNC notification daemon
    systemctl --user restart swaync.service
    
    # Kill waybar (will be restarted below)
    killall -q waybar
    
    # Reload Hyprland configuration
    hyprctl reload

    # Refresh kitty by reloading it
    pkill -USR1 kitty

    # ========================================================================
    # ADD MORE COMMANDS HERE
    # ========================================================================
    # Examples:
    # systemctl --user restart some-service.service
    # pkill -USR1 some-daemon
    # custom-reload-command
    # ========================================================================
}

# ============================================================================
# SCRIPT EXECUTION - NO NEED TO EDIT BELOW THIS LINE
# ============================================================================

# Read current theme name from file (strips whitespace)
if [[ -f "$THEME_FILE" ]]; then
    THEME=$(tr -d '[:space:]' < "$THEME_FILE")
else
    THEME=""
fi

# Execute all reload commands
reload_applications

# Restart waybar in detached background process
# This ensures waybar stays running after script exits
if command -v waybar &>/dev/null; then
    setsid -f waybar &>/dev/null
fi

# Clean exit
exit 0
