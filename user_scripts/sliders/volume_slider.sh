#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
APP_NAME="volume-slider"       # Used for Hyprland Window Rules (class)
TITLE="Volume"                 # Window Title & Text Label
LOCK_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${APP_NAME}.lock"

# --- SINGLE INSTANCE GUARD (FLOCK) ---
exec 200>"$LOCK_FILE"

_focus_existing() {
    if command -v hyprctl >/dev/null 2>&1; then
        if command -v jq >/dev/null 2>&1; then
            ADDR=$(hyprctl clients -j 2>/dev/null | jq -r --arg c "$APP_NAME" '.[] | select(.class == $c) | .address' | head -n1)
            if [ -n "$ADDR" ] && [ "$ADDR" != "null" ]; then
                hyprctl dispatch focuswindow "address:$ADDR" >/dev/null 2>&1
                return
            fi
        fi
        hyprctl dispatch focuswindow "title:^${TITLE}$" >/dev/null 2>&1
    fi

    if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -a "$TITLE" 2>/dev/null || true
    fi
}

if ! flock -n 200; then
    _focus_existing
    exit 0
fi

# --- ARGUMENT PARSING ---
SINK="@DEFAULT_AUDIO_SINK@"

while getopts ":s:h" opt; do
    case "$opt" in
        s) SINK="$OPTARG" ;;
        h) echo "Usage: $0 [-s SINK_ID]"; exit 0 ;;
        *) echo "Invalid option"; exit 1 ;;
    esac
done

# --- SAFETY CHECKS ---
if ! command -v yad >/dev/null 2>&1; then echo "Error: yad is missing."; exit 1; fi
if ! command -v wpctl >/dev/null 2>&1; then echo "Error: wpctl is missing."; exit 1; fi

# --- BACKEND FUNCTIONS ---
get_current_volume() {
    wpctl get-volume "$SINK" | awk '{print int($2 * 100)}'
}

set_volume() {
    local vol="$1"
    wpctl set-volume "$SINK" "${vol}%" >/dev/null 2>&1
    if [ "$vol" -gt 0 ]; then
        wpctl set-mute "$SINK" 0 >/dev/null 2>&1
    fi
}

CURRENT_PCT=$(get_current_volume)

# --- YAD UI ---
YAD_ARGS=(
    --scale
    --title="$TITLE"
    --window-icon="audio-volume-medium"
    --text="                      "
    --class="$APP_NAME"
    --min-value=0
    --max-value=100
    --value="$CURRENT_PCT"
    --step=1
    --show-value
    --print-partial
    --width=420                    # Uniform Width
    --height=90                    # Uniform Height
    --buttons-layout=center
    --button="Close":1             # Changed OK to Close for uniformity
    --fixed
)

# --- THE EVENT LOOP ---
set_volume "$CURRENT_PCT"

yad "${YAD_ARGS[@]}" | while IFS= read -r NEW_PCT; do
    NEW_PCT_INT=${NEW_PCT%.*}
    
    if [ -n "$NEW_PCT_INT" ] && [ "$NEW_PCT_INT" != "$CURRENT_PCT" ]; then
        set_volume "$NEW_PCT_INT"
        CURRENT_PCT="$NEW_PCT_INT"
    fi
done
