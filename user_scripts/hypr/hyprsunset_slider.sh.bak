#!/usr/bin/env bash
set -euo pipefail

# hyprsunset real-time slider for Hyprland (labeled)
# - updates hyprctl hyprsunset temperature as you move the slider (uses yad --print-partial)
# - keeps the last value in /tmp/hyprsunset.temp
# - title is exactly "hyprsunset" (useful for Hyprland window rules)
# Only change from original: added a top label (--text) to indicate purpose.

TEMP_FILE="/tmp/hyprsunset.temp"
DEFAULT_TEMP=4500
MIN_TEMP=1000
MAX_TEMP=5000

# check dependencies
if ! command -v yad >/dev/null 2>&1; then
    echo "This script requires 'yad'. Install it (e.g. sudo pacman -S yad)" >&2
    exit 1
fi
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "hyprctl not found in PATH. This script must run on a system with Hyprland." >&2
    exit 1
fi

# Initialize temp file if missing
if [ ! -f "$TEMP_FILE" ]; then
    echo "$DEFAULT_TEMP" > "$TEMP_FILE"
fi

# Read last value (fallback to default on failure)
if ! CURRENT_TEMP=$(cat "$TEMP_FILE" 2>/dev/null); then
    CURRENT_TEMP=$DEFAULT_TEMP
fi

# Construct yad command (title must be "hyprsunset" for Hyprland rules)
YAD_ARGS=(
    --scale
    --title="hyprsunset"
    --text="hyprsunset"
    --min-value="$MIN_TEMP"
    --max-value="$MAX_TEMP"
    --value="$CURRENT_TEMP"
    --step=1
    --show-value
    --print-partial
    --width=420
    --height=90
    --button=OK:0
    --buttons-layout=center
)

"yad" "${YAD_ARGS[@]}" | while IFS= read -r NEW_TEMP; do
    NEW_TEMP_INT=${NEW_TEMP%.*}

    if [ -n "$NEW_TEMP_INT" ] && [ "$NEW_TEMP_INT" != "$CURRENT_TEMP" ]; then
        hyprctl hyprsunset temperature "$NEW_TEMP_INT" || true
        echo "$NEW_TEMP_INT" > "$TEMP_FILE" || true
        CURRENT_TEMP="$NEW_TEMP_INT"
    fi
done

YAD_EXIT=${PIPESTATUS[0]:-1}

if [ "$YAD_EXIT" -ne 0 ]; then
    exit 0
fi

exit 0
