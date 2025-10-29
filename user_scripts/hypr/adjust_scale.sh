#!/bin/bash

# Script to adjust monitor scale in Hyprland by stepping through a predefined list.
# This version preserves the current resolution and refresh rate.

# --- Configuration ---
# Set your primary monitor name here. Leave empty to auto-detect the focused one.
MONITOR_NAME=""

# add a delay for notification after the resolution is changed, recomanded is 0.5 seconds.
sleep_delay_for_notfication="1.0"

# Define known good scales.
readonly GOOD_SCALES=("1.000000" "1.200000" "1.250000" "1.333333" "1.500000" "1.600000" "1.666667" "2.000000" "2.400000" "2.500000" "3.000000")

# --- Functions ---
usage() {
    echo "Usage: $0 [+|-]"
    echo "Example: $0 +  (to increase)"
    echo "         $0 -  (to decrease)"
    exit 1
}

notify() {
    if command -v notify-send &> /dev/null; then
        notify-send "Hyprland Scale" "Set ${MONITOR_NAME} scale to ${1}"
    fi
}

# --- Main Script ---
# Check for required commands.
for cmd in hyprctl jq bc; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

# Validate input.
if [[ "$1" != "+" && "$1" != "-" ]]; then
    usage
fi
ADJUSTMENT_DIRECTION="$1"

# Get current monitor info in JSON format.
CURRENT_MONITOR_INFO_JSON=$(hyprctl -j monitors)

# Determine the target monitor if not specified.
if [[ -z "$MONITOR_NAME" ]]; then
    MONITOR_NAME=$(echo "$CURRENT_MONITOR_INFO_JSON" | jq -r '.[] | select(.focused == true) | .name')
fi

CURRENT_MONITOR_INFO=$(echo "$CURRENT_MONITOR_INFO_JSON" | jq -r --arg MONITOR_NAME "$MONITOR_NAME" '.[] | select(.name == $MONITOR_NAME)')

if [[ -z "$CURRENT_MONITOR_INFO" ]]; then
    echo "Error: Monitor '$MONITOR_NAME' not found." >&2
    exit 1
fi

# --- **FIX**: Read all current monitor settings ---
CURRENT_RES_X=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.width')
CURRENT_RES_Y=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.height')
CURRENT_REFRESH_FLOAT=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.refreshRate')
CURRENT_REFRESH=$(printf "%.0f" "$CURRENT_REFRESH_FLOAT") # Round to nearest integer
CURRENT_X=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.x')
CURRENT_Y=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.y')
CURRENT_SCALE=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.scale')
# --- End of fix section ---


# Find the index of the current scale in the GOOD_SCALES array.
current_idx=-1
for i in "${!GOOD_SCALES[@]}"; do
    # Use bc for floating point comparison with a tolerance
    if (( $(echo "($CURRENT_SCALE - ${GOOD_SCALES[$i]}) < 0.00001 && ($CURRENT_SCALE - ${GOOD_SCALES[$i]}) > -0.00001" | bc -l) )); then
        current_idx=$i
        break
    fi
done

# If the current scale is not in the list, find the closest one.
if (( current_idx == -1 )); then
    min_diff=1000
    for i in "${!GOOD_SCALES[@]}"; do
        diff=$(echo "scale=7; v = $CURRENT_SCALE - ${GOOD_SCALES[$i]}; if (v < 0) v = -v; v" | bc -l)
        if (( $(echo "$diff < $min_diff" | bc -l) )); then
            min_diff=$diff
            current_idx=$i
        fi
    done
fi

# Calculate the new index.
num_scales=${#GOOD_SCALES[@]}
if [[ "$ADJUSTMENT_DIRECTION" == "+" ]]; then
    new_idx=$((current_idx + 1))
else
    new_idx=$((current_idx - 1))
fi

# Check if the new index is within bounds.
if (( new_idx < 0 || new_idx >= num_scales )); then
    echo "Already at min/max scale."
    exit 0
fi

NEW_SCALE="${GOOD_SCALES[$new_idx]}"

# --- **FIX**: Construct the full, explicit monitor string ---
NEW_MONITOR_STRING="${MONITOR_NAME},${CURRENT_RES_X}x${CURRENT_RES_Y}@${CURRENT_REFRESH},${CURRENT_X}x${CURRENT_Y},${NEW_SCALE}"

# Apply the new setting.
hyprctl keyword monitor "$NEW_MONITOR_STRING"
echo "Set ${MONITOR_NAME} scale to ${NEW_SCALE}"

# --- Notification with Delay ---
# Pause for a fraction of a second to allow Hyprland to apply the change.
# You can adjust this value if notifications are still flickering.

# this delay is implemented for race condition situation
sleep ${sleep_delay_for_notfication}

# Now, send the notification.
notify-send "Hyprland Scale" "Set scale to ${NEW_SCALE}"
