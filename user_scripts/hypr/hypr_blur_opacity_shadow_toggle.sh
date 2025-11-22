#!/usr/bin/env bash

#==============================================================================
# Hyprland Visuals Controller (Blur, Shadow, Opacity)
# 
# USAGE: 
#   ./script.sh        -> Toggles state based on current config
#   ./script.sh on     -> Forces visuals ON (Blur, Shadow, Transparency)
#   ./script.sh off    -> Forces visuals OFF (No Blur, No Shadow, Opaque)
#==============================================================================

# --- Configuration ---
# Adjust this path if your config structure changes
readonly CONFIG_FILE="${HOME}/.config/hypr/source/appearance.conf"

# Visual Constants
readonly OP_ACTIVE_ON="0.8"
readonly OP_INACTIVE_ON="0.6"
readonly OP_ACTIVE_OFF="1.0"
readonly OP_INACTIVE_OFF="1.0"

# --- Pre-flight Checks ---
if [ ! -f "$CONFIG_FILE" ]; then
    notify-send "Hyprland Error" "Config file not found at $CONFIG_FILE" -u critical
    exit 1
fi

# --- 1. Determine Desired State ---

# Helper function to detect current state from file
get_current_blur_state() {
    # precise check inside the blur { } block
    if sed -n '/blur[[:space:]]*{/,/}/ { /enabled[[:space:]]*=[[:space:]]*true/p }' "$CONFIG_FILE" | grep -q 'true'; then
        echo "on"
    else
        echo "off"
    fi
}

# Parse Input Flags
TARGET_STATE=""
case "$1" in
    on|ON|enable)
        TARGET_STATE="on"
        ;;
    off|OFF|disable)
        TARGET_STATE="off"
        ;;
    *)
        # No flag provided? Toggle based on current state.
        CURRENT=$(get_current_blur_state)
        if [ "$CURRENT" == "on" ]; then
            TARGET_STATE="off"
        else
            TARGET_STATE="on"
        fi
        ;;
esac

# --- 2. Define Values Based on Target ---

if [ "$TARGET_STATE" == "on" ]; then
    NEW_ENABLED="true"
    NEW_ACTIVE="$OP_ACTIVE_ON"
    NEW_INACTIVE="$OP_INACTIVE_ON"
    NOTIFY_MSG="Visuals: Max (Blur/Shadow ON)"
else
    NEW_ENABLED="false"
    NEW_ACTIVE="$OP_ACTIVE_OFF"
    NEW_INACTIVE="$OP_INACTIVE_OFF"
    NOTIFY_MSG="Visuals: Performance (Blur/Shadow OFF)"
fi

# --- 3. Execution: File Persistence (sed) ---

# We use sed with specific address ranges to differentiate 'shadow' enabled vs 'blur' enabled.
# strict strict regex ensures we don't mess up other lines.

sed -i \
    -e "/blur[[:space:]]*{/,/}/ s/enabled[[:space:]]*=[[:space:]]*[a-z]*/enabled = $NEW_ENABLED/" \
    -e "/shadow[[:space:]]*{/,/}/ s/enabled[[:space:]]*=[[:space:]]*[a-z]*/enabled = $NEW_ENABLED/" \
    -e "s/^\([[:space:]]*active_opacity[[:space:]]*=[[:space:]]*\).*/\1$NEW_ACTIVE/" \
    -e "s/^\([[:space:]]*inactive_opacity[[:space:]]*=[[:space:]]*\).*/\1$NEW_INACTIVE/" \
    "$CONFIG_FILE"

# --- 4. Execution: Runtime Application (hyprctl) ---

# Using 'keyword' allows instant updates without a full reload flicker.
# It syncs the running session with the file changes we just made.

hyprctl keyword decoration:blur:enabled "$NEW_ENABLED" > /dev/null
hyprctl keyword decoration:shadow:enabled "$NEW_ENABLED" > /dev/null
hyprctl keyword decoration:active_opacity "$NEW_ACTIVE" > /dev/null
hyprctl keyword decoration:inactive_opacity "$NEW_INACTIVE" > /dev/null

# --- 5. User Feedback ---

if command -v notify-send >/dev/null 2>&1; then
    # Using a synchronous ID prevents notification spam stacking
    notify-send -h string:x-canonical-private-synchronous:hypr-visuals \
                -t 1500 \
                "Hyprland" "$NOTIFY_MSG"
fi

exit 0
