#!/bin/bash

TEMP_FILE="/tmp/hyprsunset.temp"
DEFAULT_TEMP=4500
MIN_TEMP=1000
MAX_TEMP=5000

# Initialize the temp file if it doesn't exist
if [ ! -f "$TEMP_FILE" ]; then
    echo "$DEFAULT_TEMP" > "$TEMP_FILE"
fi

CURRENT_TEMP=$(cat "$TEMP_FILE")

# Show the yad slider and get the new value
# The title "hyprsunset" is important for the Hyprland window rule
NEW_TEMP=$(yad --scale --value="$CURRENT_TEMP" --min-value="$MIN_TEMP" --max-value="$MAX_TEMP" --step=100 --text="Set Color Temperature" --title="hyprsunset" --button="OK:0" --button="Cancel:1" --width=300 --height=80)

# Exit if the user pressed cancel or closed the window
if [ $? -ne 0 ]; then
    exit 0
fi

# Remove the decimal part if yad returns one
NEW_TEMP_INT=${NEW_TEMP%.*}

# Set the new temperature if the value is not empty
if [ -n "$NEW_TEMP_INT" ]; then
    hyprctl hyprsunset temperature "$NEW_TEMP_INT"
    echo "$NEW_TEMP_INT" > "$TEMP_FILE"
fi
