#!/usr/bin/env bash
# waybar-net: prints tiny JSON for Waybar

# 1. Define paths
STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar-net"
STATE_FILE="$STATE_DIR/state"
HEARTBEAT_FILE="$STATE_DIR/heartbeat"

# 2. SAFETY: Create dir if it doesn't exist
mkdir -p "$STATE_DIR"

# 3. WAKE UP DAEMON: 
# Update heartbeat timestamp
touch "$HEARTBEAT_FILE"
# Send signal to wake daemon from its long sleep IMMEDIATELY
pkill -USR1 -f "network_meter_daemon.sh" || true

set -euo pipefail

# 4. Default values
UNIT="KB"
UP="0"
DOWN="0"
CLASS="network-kb"

# 5. Atomic Read
if [[ -r "$STATE_FILE" ]]; then
    read -r UNIT UP DOWN CLASS < "$STATE_FILE"
fi

# --- NEW: FORMATTING LOGIC ---
# Enforce strictly 3 characters to keep Waybar narrow and steady.
# 1 char  -> " X " (Centered)
# 2 chars -> " XX" (Right-aligned / "Centered" in 3-slot)
# 3 chars -> "XXX" (As is)
fmt_fixed() {
    local s="${1:-}"
    local len=${#s}
    if [[ $len -eq 1 ]]; then
        echo " $s "
    elif [[ $len -eq 2 ]]; then
        echo " $s"
    else
        echo "${s:0:3}"
    fi
}

# Create Display variables (formatted) vs keeping Originals for tooltips
D_UNIT=$(fmt_fixed "$UNIT")
D_UP=$(fmt_fixed "$UP")
D_DOWN=$(fmt_fixed "$DOWN")
# -----------------------------

# 6. Define output based on argument
case "${1:-}" in
  vertical)
    # Use Display variables for fixed width
    TEXT="$D_UP\n$D_UNIT\n$D_DOWN"
    # Use Original variables for accurate tooltip
    TOOLTIP="Interface: $CLASS\nUpload: $UP $UNIT/s\nDownload: $DOWN $UNIT/s"
    ;;
    
  unit)
    TEXT="$D_UNIT"
    TOOLTIP="Unit: $UNIT/s"
    ;;
  up|upload)
    TEXT="$D_UP"
    TOOLTIP="Upload: $UP $UNIT/s\nDownload: $DOWN $UNIT/s"
    ;;
  down|download)
    TEXT="$D_DOWN"
    TOOLTIP="Download: $DOWN $UNIT/s\nUpload: $UP $UNIT/s"
    ;;
  *)
    echo "{}"
    exit 0
    ;;
esac

# 7. Print JSON
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$TEXT" "$CLASS" "$TOOLTIP"
