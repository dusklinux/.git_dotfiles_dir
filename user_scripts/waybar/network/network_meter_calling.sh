#!/usr/bin/env bash
# waybar-net: prints tiny JSON for Waybar
# Reads a single line: UNIT UP DOWN CLASS

set -euo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar-net/state"

# Default values if daemon isn't running
UNIT="KB"
UP="0"
DOWN="0"
CLASS="network-kb"

# Atomic Read: pure bash, no cat, no forks
if [[ -r "$STATE_FILE" ]]; then
    read -r UNIT UP DOWN CLASS < "$STATE_FILE"
fi

# Define output based on argument
case "${1:-}" in
  unit)
    TEXT="$UNIT"
    TOOLTIP="Unit: $UNIT/s"
    ;;
  up|upload)
    TEXT="$UP"
    # Dynamic tooltip showing full context
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

# Print JSON
# We manually construct JSON to avoid the overhead of jq or python
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$TEXT" "$CLASS" "$TOOLTIP"
