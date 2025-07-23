#!/bin/bash

# This script toggles the Hyprland idle daemon (hypridle)
# to prevent or allow the system from suspending.

if pgrep -x "hypridle" > /dev/null; then
    # If hypridle is running, kill it
    killall hypridle
    notify-send "Suspend Inhibited" "Automatic suspend is now OFF." -i "dialog-warning"
else
    # If hypridle is not running, start it in the background
    hypridle &
    notify-send "Suspend Enabled" "Automatic suspend is now ON." -i "dialog-information"
fi
