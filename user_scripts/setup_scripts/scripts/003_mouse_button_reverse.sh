#!/usr/bin/env bash
# ==============================================================================
# Script: 003_mouse_button_reverse.sh
# Purpose: Toggles mouse handedness in Hyprland (Clean/No Logs/No Backups)
# ==============================================================================

set -euo pipefail

# --- Configuration ---
readonly CONFIG_FILE="${HOME}/.config/hypr/source/input.conf"

# --- Cleanup Trap ---
cleanup() {
    # FIX: We add "|| true" to ensure the function returns 0 even if the file is gone.
    [[ -f "${TEMP_FILE:-}" ]] && rm -f "$TEMP_FILE" || true
}
trap cleanup EXIT

# --- Main ---
main() {
    # Ensure file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        printf "input {\n}\n" > "$CONFIG_FILE"
    fi

    # Prompt User
    # Using /dev/tty ensures we read from the user even if stdin is redirected elsewhere
    printf "Reverse mouse buttons (Left-Handed)? [y/N]: "
    read -r -n 1 user_input < /dev/tty
    printf "\n"

    local target_val="false"
    if [[ "$user_input" =~ ^[Yy]$ ]]; then
        target_val="true"
    fi

    # Atomic Parse & Write
    TEMP_FILE=$(mktemp)
    
    awk -v target_val="$target_val" '
    BEGIN { inside_input = 0; modified = 0 }
    
    # Detect start of input block
    /^input[[:space:]]*\{/ { 
        inside_input = 1
        print $0
        next 
    }
    
    # Detect end of input block
    inside_input && /^\}/ {
        if (modified == 0) {
            print "    left_handed = " target_val
            modified = 1
        }
        inside_input = 0
        print $0
        next
    }
    
    # Detect existing key inside input block
    inside_input && /^[[:space:]]*left_handed[[:space:]]*=/ {
        sub(/=.*/, "= " target_val)
        modified = 1
        print $0
        next
    }
    
    { print }
    ' "$CONFIG_FILE" > "$TEMP_FILE"

    # Move new config into place (Atomic)
    mv "$TEMP_FILE" "$CONFIG_FILE"

    # Silent Reload if Hyprland is active
    if pgrep -x "Hyprland" > /dev/null; then
        command -v hyprctl >/dev/null && hyprctl reload > /dev/null 2>&1 || true
    fi

    # Output Success Message
    printf "Success: Mouse configuration updated (left_handed = %s).\n" "$target_val"
}

main
