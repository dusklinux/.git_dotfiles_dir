#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
APP_NAME="brightness-slider"   # Used for Hyprland Window Rules (class)
TITLE="Brightness"             # Window Title & Text Label
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
get_real_pct() {
    local curr max
    curr=$("${BRIGHTNESSCTL[@]}" g)
    max=$("${BRIGHTNESSCTL[@]}" m)
    if [ "$max" -eq 0 ]; then echo 50; return; fi
    echo $(( (curr * 100 + max / 2) / max ))
}

CURRENT_PCT=$(get_real_pct)

# --- YAD UI ---
YAD_ARGS=(
    --scale
    --title="$TITLE"
    --text="$TITLE                             󰃠"
    --class="$APP_NAME"
    --window-icon="video-display"  # Added icon for uniformity
    --min-value=1
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

# The Loop
"${BRIGHTNESSCTL[@]}" set "${CURRENT_PCT}%" >/dev/null 2>&1

yad "${YAD_ARGS[@]}" | while IFS= read -r NEW_PCT; do
    NEW_PCT_INT=${NEW_PCT%.*}
    if [ -n "$NEW_PCT_INT" ] && [ "$NEW_PCT_INT" != "$CURRENT_PCT" ]; then
        "${BRIGHTNESSCTL[@]}" set "${NEW_PCT_INT}%" -q >/dev/null 2>&1
        CURRENT_PCT="$NEW_PCT_INT"
    fi
done
