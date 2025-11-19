#!/usr/bin/env bash

# Get the CapsLock status of the MAIN keyboard specifically using JSON parsing.
# This is much more robust than grep/awk pipelines.
IS_CAPS=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .capsLock')

if [ "$IS_CAPS" == "true" ]; then
    # You can change this text to an icon like "󰪛" if you have Nerd Fonts
    echo "CAPS LOCK"
else
    echo ""
fi
