#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
APP_NAME="volume-slider"       # Used for Hyprland Window Rules (class)
TITLE="Volume"                 # Window Title & Text Label
LOCK_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${APP_NAME}.lock"

# --- SINGLE INSTANCE GUARD (FLOCK) ---
# We use file descriptor 200. If locked, focus existing window and exit.
# This prevents multiple sliders from piling up if you spam the keybind.
exec 200>"$LOCK_FILE"

_focus_existing() {
    # 1. Hyprland Specific Focus (Best Method)
    if command -v hyprctl >/dev/null 2>&1; then
        # Try to find address by class (most robust method using JSON)
        if command -v jq >/dev/null 2>&1; then
            ADDR=$(hyprctl clients -j 2>/dev/null | jq -r --arg c "$APP_NAME" '.[] | select(.class == $c) | .address' | head -n1)
            if [ -n "$ADDR" ] && [ "$ADDR" != "null" ]; then
                hyprctl dispatch focuswindow "address:$ADDR" >/dev/null 2>&1
                return
            fi
        fi
        # Fallback to title regex if jq fails or address not found
        hyprctl dispatch focuswindow "title:^${TITLE}$" >/dev/null 2>&1
    fi

    # 2. Generic X11/Wayland Fallback (wmctrl)
    if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -a "$TITLE" 2>/dev/null || true
    fi
}

# Try to lock the file. If it fails (already locked), focus the existing instance and exit.
if ! flock -n 200; then
    _focus_existing
    exit 0
fi

# --- ARGUMENT PARSING ---
# Allows passing a specific sink ID (e.g., -s 45). Defaults to @DEFAULT_AUDIO_SINK@
SINK="@DEFAULT_AUDIO_SINK@"

while getopts ":s:h" opt; do
    case "$opt" in
        s) SINK="$OPTARG" ;;
        h) echo "Usage: $0 [-s SINK_ID]"; exit 0 ;;
        *) echo "Invalid option"; exit 1 ;;
    esac
done

# --- SAFETY CHECKS ---
if ! command -v yad >/dev/null 2>&1; then echo "Error: yad is missing. Install it."; exit 1; fi
if ! command -v wpctl >/dev/null 2>&1; then echo "Error: wpctl (wireplumber) is missing."; exit 1; fi

# --- BACKEND FUNCTIONS ---

# Get current volume as an integer (0-100)
# wpctl returns "Volume: 0.45 [MUTED]" or "Volume: 0.45"
# We use awk to strip text and multiply the float by 100 to get an integer.
get_current_volume() {
    wpctl get-volume "$SINK" | awk '{print int($2 * 100)}'
}

# Set volume and ensure unmuted
set_volume() {
    local vol="$1"
    # 1. Set the volume (wpctl accepts percentages like 50%)
    wpctl set-volume "$SINK" "${vol}%" >/dev/null 2>&1
    
    # 2. If volume is > 0, ensure we are unmuted.
    # This improves UX: dragging the slider should reactivate sound.
    if [ "$vol" -gt 0 ]; then
        wpctl set-mute "$SINK" 0 >/dev/null 2>&1
    fi
}

CURRENT_PCT=$(get_current_volume)

# --- YAD UI ---
# We use exact dimensions and options to match the brightness slider for consistency.
YAD_ARGS=(
    --scale
    --title="$TITLE"
    --window-icon="audio-volume-medium" # Adds a nice icon if your theme supports it
    --text="$TITLE"
    --class="$APP_NAME"         # CRITICAL: Matches Hyprland window rule
    --min-value=0               # Volume allows 0 (Silence)
    --max-value=100             # Cap at 100% to prevent distortion
    --value="$CURRENT_PCT"
    --step=1
    --show-value
    --print-partial             # Output value while dragging
    --width=420
    --height=90
    --buttons-layout=center
    --button="OK:0"
    --fixed                     # Prevent resizing
)

# --- THE EVENT LOOP ---
# 1. Apply initial sync to ensure state is consistent
set_volume "$CURRENT_PCT"

# 2. Run YAD and pipe output to loop
# We read line by line. When the slider moves, YAD prints the number.
# We update the audio backend immediately.
yad "${YAD_ARGS[@]}" | while IFS= read -r NEW_PCT; do
    # Strip any potential decimal points (yad usually sends integers with --step=1 but safety first)
    NEW_PCT_INT=${NEW_PCT%.*}
    
    if [ -n "$NEW_PCT_INT" ] && [ "$NEW_PCT_INT" != "$CURRENT_PCT" ]; then
        set_volume "$NEW_PCT_INT"
        CURRENT_PCT="$NEW_PCT_INT"
    fi
done
