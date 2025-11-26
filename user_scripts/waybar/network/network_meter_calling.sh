#!/usr/bin/env bash
# waybar-net: Signal generator and JSON formatter

# FLAGS: unit, up, down

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar-net"
STATE_FILE="$STATE_DIR/state"
PID_FILE="$STATE_DIR/pid"

# 1. SIGNALING
# Send Wake-Up Signal to Daemon (Fastest method)
if [[ -f "$PID_FILE" ]]; then
    read -r DAEMON_PID < "$PID_FILE" || true
    if [[ -n "$DAEMON_PID" ]]; then
        # This wakes the daemon from sleep AND updates the watchdog
        kill -USR1 "$DAEMON_PID" 2>/dev/null || true
    fi
fi

# 2. READ STATE (Atomic)
# Default values
UNIT="KB"
UP="0"
DOWN="0"
CLASS="network-init"

if [[ -f "$STATE_FILE" ]]; then
    read -r UNIT UP DOWN CLASS < "$STATE_FILE"
fi

# 3. OUTPUT LOGIC
case "${1:-}" in
    unit) TEXT="$UNIT" ;;
    up)   TEXT="$UP" ;;
    down) TEXT="$DOWN" ;;
    *)    echo "{}"; exit 0 ;;
esac

# Tooltip is always full info
TOOLTIP="Download: ${DOWN} ${UNIT}/s\rUpload:   ${UP} ${UNIT}/s"

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$TEXT" "$CLASS" "$TOOLTIP"
