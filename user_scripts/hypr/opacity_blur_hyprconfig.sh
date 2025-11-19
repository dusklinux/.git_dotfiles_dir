#!/usr/bin/env bash

#==============================================================================
# Hyprland Blur & Opacity Toggle Script (Optimized)
#
# FUNCTION:
# 1. Detects current blur state from config.
# 2. Atomically updates the config file (for persistence after reboot).
# 3. Instantly applies settings via hyprctl (no reload/flicker required).
#==============================================================================

# --- Configuration ---
readonly CONFIG_FILE="${HOME}/.config/hypr/source/appearance.conf"

# Opacity Constants
readonly OP_ACTIVE_ON="0.8"
readonly OP_INACTIVE_ON="0.6"

readonly OP_ACTIVE_OFF="1.0"
readonly OP_INACTIVE_OFF="1.0"

# --- Pre-flight Checks ---
if [ ! -f "$CONFIG_FILE" ]; then
    notify-send "Hyprland Error" "Config file not found at $CONFIG_FILE" -u critical
    exit 1
fi

# --- Logic ---

# Check state: Look for 'enabled = true' specifically inside the blur block.
# We use grep -q for a silent boolean check.
IS_BLUR_ENABLED=false
if sed -n '/blur[[:space:]]*{/,/}/ { /enabled[[:space:]]*=[[:space:]]*true/p }' "$CONFIG_FILE" | grep -q 'true'; then
    IS_BLUR_ENABLED=true
fi

if [ "$IS_BLUR_ENABLED" = true ]; then
    # --- TRIGGER: DISABLE BLUR & TRANSPARENCY ---
    NEW_BLUR="false"
    NEW_ACTIVE="$OP_ACTIVE_OFF"
    NEW_INACTIVE="$OP_INACTIVE_OFF"
    STATE_MSG="Blur & Transparency: OFF"
else
    # --- TRIGGER: ENABLE BLUR & TRANSPARENCY ---
    NEW_BLUR="true"
    NEW_ACTIVE="$OP_ACTIVE_ON"
    NEW_INACTIVE="$OP_INACTIVE_ON"
    STATE_MSG="Blur & Transparency: ON"
fi

# --- Execution Phase ---

# 1. Update the file (Persistence)
# We combine all substitutions into ONE sed command for atomicity.
# Regex explanation:
# 's/^\s*key\s*=.*/' allows for any amount of indentation or spacing.
sed -i \
    -e "/blur[[:space:]]*{/,/}/ s/enabled[[:space:]]*=[[:space:]]*true/enabled = $NEW_BLUR/" \
    -e "/blur[[:space:]]*{/,/}/ s/enabled[[:space:]]*=[[:space:]]*false/enabled = $NEW_BLUR/" \
    -e "s/^\([[:space:]]*active_opacity[[:space:]]*=[[:space:]]*\).*/\1$NEW_ACTIVE/" \
    -e "s/^\([[:space:]]*inactive_opacity[[:space:]]*=[[:space:]]*\).*/\1$NEW_INACTIVE/" \
    "$CONFIG_FILE"

# 2. Update Runtime (Instant Visuals)
# Using 'hyprctl keyword' applies changes immediately without a full config reload.
hyprctl keyword decoration:blur:enabled "$NEW_BLUR" > /dev/null
hyprctl keyword decoration:active_opacity "$NEW_ACTIVE" > /dev/null
hyprctl keyword decoration:inactive_opacity "$NEW_INACTIVE" > /dev/null

# 3. User Feedback
# Sends a notification if 'notify-send' is installed.
if command -v notify-send >/dev/null 2>&1; then
    notify-send -h string:x-canonical-private-synchronous:hypr-toggle \
                -t 1000 \
                "Hyprland" "$STATE_MSG"
fi

exit 0
