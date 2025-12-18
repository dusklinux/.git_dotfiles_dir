#!/usr/bin/env bash
# waybar-net: prints tiny JSON for Waybar

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar-net"
STATE_FILE="$STATE_DIR/state"
HEARTBEAT_FILE="$STATE_DIR/heartbeat"

# Default values
UNIT="KB"
UP="0"
DOWN="0"
CLASS="network-kb"

# 1. READ STATE
if [[ -r "$STATE_FILE" ]]; then
    read -r UNIT UP DOWN CLASS < "$STATE_FILE"
fi

# 2. SIGNAL DAEMON
mkdir -p "$STATE_DIR"
touch "$HEARTBEAT_FILE"

# FIX APPLIED: Always signal the daemon.
# The previous logic prevented signaling when "disconnected", assuming the daemon 
# was on a short 3s loop. However, if the daemon entered the 600s "Deep Sleep" 
# (due to inactivity) while disconnected, it would NEVER wake up because 
# this script refused to send the signal.
# We use -f to match the script name regardless of path.
pkill -USR1 -f "network_meter_daemon.sh" || true

# 3. FORMATTING (Strict 3 chars)
fmt_fixed() {
    local s="${1:-0}"
    local len=${#s}
    if (( len == 1 )); then
        printf ' %s ' "$s"
    elif (( len == 2 )); then
        printf ' %s' "$s"
    else
        printf '%s' "${s:0:3}"
    fi
}

D_UNIT=$(fmt_fixed "$UNIT")
D_UP=$(fmt_fixed "$UP")
D_DOWN=$(fmt_fixed "$DOWN")

# 4. PREPARE TOOLTIP
if [[ "$CLASS" == "network-disconnected" ]]; then
    TOOLTIP="Disconnected"
else
    # Safe tooltip for all modes
    TOOLTIP="Interface: ${CLASS}\nUpload: ${UP} ${UNIT}/s\nDownload: ${DOWN} ${UNIT}/s"
fi

# 5. OUTPUT SELECTION
case "${1:-}" in
  vertical)
    TEXT="$D_UP\n$D_UNIT\n$D_DOWN"
    ;;
  unit)
    TEXT="$D_UNIT"
    ;;
  up|upload)
    TEXT="$D_UP"
    ;;
  down|download)
    TEXT="$D_DOWN"
    ;;
  *)
    echo "{}"
    exit 0
    ;;
esac

# 6. PRINT JSON
printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$TEXT" "$CLASS" "$TOOLTIP"
