#!/usr/bin/env bash

# Define the Waybar Signal (Must match the "signal" number in waybar config)
signal_module=9

if pgrep -x "hypridle" > /dev/null; then
    # --- TURN OFF ---
    # Kill the process
    killall hypridle
    
    # Wait loop: Ensure it is actually dead before updating UI
    # This prevents the UI from checking status while it's still shutting down
    while pgrep -x "hypridle" > /dev/null; do sleep 0.1; done

    notify-send -u low -t 2000 "Suspend Inhibited" "Automatic suspend is now OFF (Coffee Mode ☕)." -i "dialog-warning"
else
    # --- TURN ON ---
    # Start hypridle in the background, disowning it so it doesn't die when this script ends
    hypridle & disown

    notify-send -u low -t 2000 "Suspend Enabled" "Automatic suspend is now ON." -i "dialog-information"
fi

# Instant UI Update: Signal Waybar to reload the module immediately
pkill -RTMIN+${signal_module} waybar
