#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
APP_NAME="brightness-slider"   # Used for Hyprland Window Rules (class)
TITLE="Brightness"             # Window Title & Text Label
LOCK_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${APP_NAME}.lock"

# --- SINGLE INSTANCE GUARD (FLOCK) ---
# We use file descriptor 200. If locked, focus existing window and exit.
exec 200>"$LOCK_FILE"

_focus_existing() {
    # 1. Hyprland Specific Focus (Best Method)
    if command -v hyprctl >/dev/null 2>&1; then
        # Try to find address by class (most robust)
        if command -v jq >/dev/null 2>&1; then
            ADDR=$(hyprctl clients -j 2>/dev/null | jq -r --arg c "$APP_NAME" '.[] | select(.class == $c) | .address' | head -n1)
            if [ -n "$ADDR" ] && [ "$ADDR" != "null" ]; then
                hyprctl dispatch focuswindow "address:$ADDR" >/dev/null 2>&1
                return
            fi
        fi
        # Fallback to title regex if jq fails
        hyprctl dispatch focuswindow "title:^${TITLE}$" >/dev/null 2>&1
    fi

    # 2. Generic X11/Wayland Fallback
    if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -a "$TITLE" 2>/dev/null || true
    fi
}

if ! flock -n 200; then
    _focus_existing
    exit 0
fi

# --- ARGUMENT PARSING ---
DEVICE=""
CLASS=""

while getopts ":d:c:h" opt; do
    case "$opt" in
        d) DEVICE="$OPTARG" ;;
        c) CLASS="$OPTARG" ;;
        h) echo "Usage: $0 [-d DEVICE] [-c CLASS]"; exit 0 ;;
        *) echo "Invalid option"; exit 1 ;;
    esac
done

BRIGHTNESSCTL=(brightnessctl)
[ -n "$DEVICE" ] && BRIGHTNESSCTL+=(--device="$DEVICE")
[ -n "$CLASS" ] && BRIGHTNESSCTL+=(--class="$CLASS")

# --- SAFETY CHECKS ---
if ! command -v yad >/dev/null 2>&1; then echo "yad missing"; exit 1; fi
if ! command -v brightnessctl >/dev/null 2>&1; then echo "brightnessctl missing"; exit 1; fi

# --- CALCULATE INITIAL PERCENTAGE ---
# We read from hardware to ensure the slider matches reality (prevents jumping)
get_real_pct() {
    local curr max
    curr=$("${BRIGHTNESSCTL[@]}" g)
    max=$("${BRIGHTNESSCTL[@]}" m)
    if [ "$max" -eq 0 ]; then echo 50; return; fi
    # Formula: (Current * 100 + Max / 2) / Max (Standard rounding)
    echo $(( (curr * 100 + max / 2) / max ))
}

CURRENT_PCT=$(get_real_pct)

# --- YAD UI ---
YAD_ARGS=(
    --scale
    --title="$TITLE"            # Window Title
    --text="$TITLE"             # Top Label (Restored)
    --class="$APP_NAME"         # For Hyprland Rules
    --min-value=1
    --max-value=100
    --value="$CURRENT_PCT"
    --step=1
    --show-value
    --print-partial
    --width=420
    --height=90
    --buttons-layout=center
    --button="OK:0"             # Restored OK button
    --fixed                     # Prevent resizing
)

# The Loop
# We read the slider output and apply it.
"${BRIGHTNESSCTL[@]}" set "${CURRENT_PCT}%" >/dev/null 2>&1 # Initial sync

# Note: We intentionally do NOT use background (&) here to ensure 
# commands are executed in order, preventing "stutter" if you drag wildly.
yad "${YAD_ARGS[@]}" | while IFS= read -r NEW_PCT; do
    NEW_PCT_INT=${NEW_PCT%.*}
    if [ -n "$NEW_PCT_INT" ] && [ "$NEW_PCT_INT" != "$CURRENT_PCT" ]; then
        "${BRIGHTNESSCTL[@]}" set "${NEW_PCT_INT}%" -q >/dev/null 2>&1
        CURRENT_PCT="$NEW_PCT_INT"
    fi
done
