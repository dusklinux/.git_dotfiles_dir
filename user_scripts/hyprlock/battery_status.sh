#!/usr/bin/env bash

# 1. Find the battery path. 
# We pick the first power_supply that starts with BAT or CW (Chromebooks).
# We ensure it is actually present (-e).
BAT_PATH=""
for bat in /sys/class/power_supply/BAT* /sys/class/power_supply/CW201*; do
    if [ -e "$bat/status" ]; then
        BAT_PATH="$bat"
        break
    fi
done

# If no battery is found (desktop PC), exit silently.
if [ -z "$BAT_PATH" ]; then
    echo ""
    exit 0
fi

# 2. Get the raw data from the specific battery found.
STATUS=$(cat "$BAT_PATH/status")
CAPACITY=$(cat "$BAT_PATH/capacity")

# 3. Logic for Icons and Output
# Using Nerd Fonts is highly recommended for Hyprlock.
# Icons: Charging=⚡, Discharging=Removed, Full=Filled

if [ "$STATUS" == "Charging" ]; then
    echo "⚡ $CAPACITY%"
elif [ "$STATUS" == "Discharging" ]; then
    echo "$CAPACITY%"
elif [ "$STATUS" == "Full" ]; then
    echo "Full"
elif [ "$STATUS" == "Not charging" ]; then
    # Plugged in but threshold limit reached (common on ThinkPads/Asus)
    echo " $CAPACITY%"
else
    # Fallback for unknown states
    echo "$CAPACITY%"
fi
