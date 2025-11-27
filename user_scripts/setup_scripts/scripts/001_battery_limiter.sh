#!/usr/bin/env bash
set -euo pipefail

# 1. Enforce Root/Sudo execution immediately
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root. Please run with sudo." 
   exit 1
fi

# 2. Configuration
LIMIT=60
THRESHOLD_FILE="charge_control_end_threshold"
SEARCH_PATH="/sys/class/power_supply"

# 3. Detect and Apply
# Enable nullglob so the loop doesn't execute if no BAT* files exist
shopt -s nullglob
batteries=("$SEARCH_PATH"/BAT*)

if [ ${#batteries[@]} -eq 0 ]; then
    echo "No batteries detected."
    exit 1
fi

for bat in "${batteries[@]}"; do
    target="$bat/$THRESHOLD_FILE"
    
    if [[ -f "$target" ]]; then
        echo "Detected $(basename "$bat"). Setting limit to $LIMIT..."
        # Direct write since we are already root
        echo "$LIMIT" > "$target"
    else
        echo "Skipping $(basename "$bat"): Standard threshold file not found."
    fi
done
