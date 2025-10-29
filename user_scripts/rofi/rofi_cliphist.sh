#!/usr/bin/env bash
# ~/.config/rofi/rofi-cliphist.sh

# This script integrates cliphist with Rofi.
# It is designed to be called as a Rofi "script mode".

# Check if an argument is passed.
# If no argument, it means Rofi is asking for the list of items.
if [ -z "$@" ]; then
    cliphist list
else
    # If an argument is passed, it means the user selected an item.
    # Rofi passes the selected item back to the script.
    # We decode it and copy it to the clipboard.
    echo "$@" | cliphist decode | wl-copy
fi
