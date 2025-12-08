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

# 6. Define output based on argument
case "${1:-}" in
  vertical)
    # OPTIMIZED: No Icon. Just 3 lines.
    # Structure: Up \n Unit \n Down
    TEXT="$UP\n$UNIT\n$DOWN"
    TOOLTIP="Interface: $CLASS\nUpload: $UP $UNIT/s\nDownload: $DOWN $UNIT/s"
    ;;
    
  unit)
    TEXT="$UNIT"
    TOOLTIP="Unit: $UNIT/s"
    ;;
  up|upload)
    TEXT="$UP"
    TOOLTIP="Upload: $UP $UNIT/s\nDownload: $DOWN $UNIT/s"
    ;;
  down|download)
    TEXT="$DOWN"
    TOOLTIP="Download: $DOWN $UNIT/s\nUpload: $UP $UNIT/s"
    ;;
  *)
    echo "{}"
    exit 0
    ;;
esac

# 7. Print JSON
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$TEXT" "$CLASS" "$TOOLTIP"
