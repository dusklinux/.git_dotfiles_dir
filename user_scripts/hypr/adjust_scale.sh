#!/usr/bin/env bash

# ==============================================================================
# Hyprland Monitor Scale Adjustment Script
# Precision-engineered for Arch Linux / Hyprland
# ==============================================================================

# Strict Mode: Exit on error, error on unset vars, error on pipe failure
set -euo pipefail

# Force standard locale to ensure '.' is used for decimals (prevents bugs in non-English regions)
export LC_ALL=C

# --- Configuration ---

# Set your primary monitor name here. Leave empty to auto-detect the focused one.
# You can find names via `hyprctl monitors` (e.g., "DP-1", "eDP-1")
TARGET_MONITOR=""

# Notification tag to prevent stacking/flickering
NOTIFY_TAG="hypr_scale_adjust"

# Define known good scales (Must be sorted ascending)
readonly GOOD_SCALES=("1.00" "1.20" "1.25" "1.333333" "1.50" "1.60" "1.666667" "2.00" "2.40" "2.50" "3.00")

# --- Functions ---

usage() {
    echo "Usage: $(basename "$0") [+|-]"
    echo "  +  Increase scale"
    echo "  -  Decrease scale"
    exit 1
}

send_notification() {
    local scale="$1"
    local monitor="$2"
    
    if command -v notify-send &> /dev/null; then
        # -h string:x-canonical-private-synchronous:... replaces the previous notification
        # immediately, eliminating the need for sleep/delays.
        notify-send \
            -h string:x-canonical-private-synchronous:"$NOTIFY_TAG" \
            -u low \
            -t 2000 \
            "Display Scale: ${scale}" \
            "Monitor: ${monitor}"
    fi
}

get_monitor_info() {
    # Fetch monitor data once
    hyprctl -j monitors
}

# --- Main Logic ---

# 1. Validate Dependencies
for cmd in hyprctl jq awk notify-send; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

# 2. Validate Input
if [[ $# -ne 1 ]] || [[ "$1" != "+" && "$1" != "-" ]]; then
    usage
fi
DIRECTION="$1"

# 3. Get Monitor Data
MONITORS_JSON=$(get_monitor_info)

# 4. Identify Target Monitor
if [[ -z "$TARGET_MONITOR" ]]; then
    TARGET_MONITOR=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.focused == true) | .name')
fi

# Extract data for the specific monitor
CURRENT_DATA=$(echo "$MONITORS_JSON" | jq -r --arg NAME "$TARGET_MONITOR" '.[] | select(.name == $NAME)')

if [[ -z "$CURRENT_DATA" ]]; then
    echo "Error: Monitor '$TARGET_MONITOR' not found." >&2
    exit 1
fi

# 5. Parse Current Settings
# We use awk to format the Refresh Rate to avoid floating point issues (e.g. 143.99 -> 144)
# while keeping the raw values for resolution and position.
read -r CUR_RES_X CUR_RES_Y CUR_REFRESH CUR_POS_X CUR_POS_Y CUR_SCALE <<< "$(echo "$CURRENT_DATA" | jq -r '.width, .height, .refreshRate, .x, .y, .scale' | tr '\n' ' ')"

# Round refresh rate to nearest integer for the config string (standard Hyprland practice)
CUR_REFRESH_INT=$(awk -v val="$CUR_REFRESH" 'BEGIN {printf "%.0f", val}')

# 6. Calculate New Scale using AWK
# We pass the Bash array string and current scale to awk for processing
NEW_SCALE=$(awk -v cur="$CUR_SCALE" -v dir="$DIRECTION" -v scales="${GOOD_SCALES[*]}" '
BEGIN {
    # Split the scales string into an array
    n = split(scales, arr, " ");
    
    # Find the index of the closest current scale
    best_idx = 1;
    min_diff = 1000;
    
    for (i = 1; i <= n; i++) {
        diff = cur - arr[i];
        if (diff < 0) diff = -diff;
        
        if (diff < min_diff) {
            min_diff = diff;
            best_idx = i;
        }
    }

    # Calculate target index
    if (dir == "+") {
        target_idx = best_idx + 1;
    } else {
        target_idx = best_idx - 1;
    }

    # Bounds checking
    if (target_idx < 1) target_idx = 1;
    if (target_idx > n) target_idx = n;

    # Print the new scale
    print arr[target_idx];
}')

# 7. Apply Changes
# Only apply if the scale actually changed
if (( $(awk 'BEGIN {print ("'"$NEW_SCALE"'" != "'"$CUR_SCALE"'")}') )); then
    
    # Construct the Hyprland monitor rule string
    # Format: monitor=NAME,RES@HZ,POS,SCALE
    NEW_RULE="${TARGET_MONITOR},${CUR_RES_X}x${CUR_RES_Y}@${CUR_REFRESH_INT},${CUR_POS_X}x${CUR_POS_Y},${NEW_SCALE}"
    
    # Apply immediately
    hyprctl keyword monitor "$NEW_RULE" > /dev/null
    
    # Send notification
    send_notification "$NEW_SCALE" "$TARGET_MONITOR"
else
    # Optional: Notify that we hit the limit (comment out if you prefer silence)
    send_notification "${NEW_SCALE} (Limit)" "$TARGET_MONITOR"
fi

exit 0
