#!/bin/bash

# Script to adjust monitor scale in Hyprland by stepping through a predefined list.

# Configuration: Set your primary monitor name here
MONITOR_NAME="eDP-1"

# Define known good scales. The script will step through this list.
# Using 6 decimal places for consistency with Hyprland's suggestions.
# Verified for 1080x1920 or 1920x1080 resolutions.
GOOD_SCALES=("1.000000" "1.200000" "1.250000" "1.333333" "1.500000" "1.600000" "1.666667" "2.000000" "2.400000" "2.500000" "3.000000")
# You can add, remove, or modify scales in this list as needed,
# but ensure they result in integer logical pixels for your resolution.

# Read the adjustment direction (+ or - any value, e.g., +0.1 or -anything)
ADJUSTMENT_INPUT="$1"

if [[ -z "$ADJUSTMENT_INPUT" ]]; then
    echo "Usage: $0 [+|-]value"
    echo "Example: $0 +0.1  (to increase)"
    echo "         $0 -0.1  (to decrease)"
    exit 1
fi

# Get current monitor info in JSON format
CURRENT_MONITOR_INFO_JSON=$(hyprctl -j monitors)
CURRENT_MONITOR_INFO=$(echo "$CURRENT_MONITOR_INFO_JSON" | jq -r --arg MONITOR_NAME "$MONITOR_NAME" '.[] | select(.name == $MONITOR_NAME)')

if [[ -z "$CURRENT_MONITOR_INFO" ]]; then
    echo "Warning: Monitor $MONITOR_NAME not found directly. Trying to find first active/focused monitor."
    CURRENT_MONITOR_INFO=$(echo "$CURRENT_MONITOR_INFO_JSON" | jq -r '.[] | select(.focused == true or .active == true) | head -n 1')
    if [[ -z "$CURRENT_MONITOR_INFO" ]]; then
        echo "Error: No active or focused monitor found."
        exit 1
    fi
    MONITOR_NAME=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.name') # Update monitor name to the one found
    echo "Using monitor: $MONITOR_NAME"
fi

# Extract current settings
CURRENT_RES_X=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.width')
CURRENT_RES_Y=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.height')
CURRENT_REFRESH_FLOAT=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.refreshRate')
CURRENT_REFRESH=$(printf "%.0f" "$CURRENT_REFRESH_FLOAT") # Round to nearest integer
CURRENT_X=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.x')
CURRENT_Y=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.y')
CURRENT_SCALE_STR=$(echo "$CURRENT_MONITOR_INFO" | jq -r '.scale')

# --- Logic: Step through GOOD_SCALES list ---

# 1. Find the index of the current scale (or the closest one) in GOOD_SCALES
current_idx=0 # Default to the first scale if not found or on error
# Initialize min_diff_to_current_scale with the difference to the first scale in the list
min_diff_to_current_scale=$(bc -l <<< "scale=7; v = $CURRENT_SCALE_STR - ${GOOD_SCALES[0]}; if (v < 0) v = -v; v")

# Iterate through the GOOD_SCALES to find the index of the one closest to CURRENT_SCALE_STR
for i in "${!GOOD_SCALES[@]}"; do
    scale_candidate="${GOOD_SCALES[$i]}"
    # Calculate absolute difference between current scale and candidate scale
    diff=$(bc -l <<< "scale=7; v = $CURRENT_SCALE_STR - $scale_candidate; if (v < 0) v = -v; v")
    
    # If this candidate is closer than the previous closest (or equally close, favoring later elements in case of exact match with earlier default), update
    # A small tolerance (0.0000001) is added to handle potential floating point inaccuracies if CURRENT_SCALE_STR
    # is slightly off from a GOOD_SCALES value (e.g. 1.199999 vs 1.200000)
    if (( $(echo "$diff <= $min_diff_to_current_scale + 0.0000001" | bc -l) )); then
        min_diff_to_current_scale="$diff"
        current_idx="$i"
    fi
done
echo "Current scale $CURRENT_SCALE_STR is closest to ${GOOD_SCALES[$current_idx]} (index $current_idx) in the list."

# 2. Determine direction of adjustment (increment or decrement)
IS_INCREMENTING=false
if [[ "$ADJUSTMENT_INPUT" == \+* ]]; then
    IS_INCREMENTING=true
fi

# 3. Calculate new index based on adjustment direction
new_idx=$current_idx
num_scales=${#GOOD_SCALES[@]}

if "$IS_INCREMENTING"; then
    if (( current_idx < num_scales - 1 )); then # Check if not already at the maximum scale
        new_idx=$((current_idx + 1))
    else
        echo "Already at maximum scale: ${GOOD_SCALES[$current_idx]}"
    fi
else # Decrementing
    if (( current_idx > 0 )); then # Check if not already at the minimum scale
        new_idx=$((current_idx - 1))
    else
        echo "Already at minimum scale: ${GOOD_SCALES[$current_idx]}"
    fi
fi

NEW_SCALE="${GOOD_SCALES[$new_idx]}"

# --- End of Logic ---

# Construct the new monitor string for hyprctl
NEW_MONITOR_STRING="${MONITOR_NAME},${CURRENT_RES_X}x${CURRENT_RES_Y}@${CURRENT_REFRESH},${CURRENT_X}x${CURRENT_Y},${NEW_SCALE}"

# Apply the new setting if the scale has changed or if "force" is in the input
# Comparing string representations; Hyprland handles slight format variations (e.g. 2.4 vs 2.400000)
if [[ "$CURRENT_SCALE_STR" != "$NEW_SCALE" ]] || [[ "$ADJUSTMENT_INPUT" == *"force"* ]]; then
    hyprctl keyword monitor "$NEW_MONITOR_STRING"
    echo "Set ${MONITOR_NAME} scale to ${NEW_SCALE}"
    # Optional: send a notification (requires a notification daemon like dunst)
    # notify-send "Hyprland Scale" "Set ${MONITOR_NAME} scale to ${NEW_SCALE}"
else
    echo "Scale for ${MONITOR_NAME} is already effectively ${NEW_SCALE}. No change applied."
fi
