#!/usr/bin/env bash
# waybar-net: Signal generator and JSON formatter

# FLAGS: unit, up, down

# Use fast paths
STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar-net"
STATE_FILE="$STATE_DIR/state"
HEARTBEAT_FILE="$STATE_DIR/heartbeat"
PID_FILE="$STATE_DIR/pid"

# 1. SIGNALING (Optimized)
# Ensure dir exists
if [[ ! -d "$STATE_DIR" ]]; then
    mkdir -p "$STATE_DIR"
fi

# Touch heartbeat (I am alive)
touch "$HEARTBEAT_FILE"

# Send Signal via PID (Fastest method, avoids scanning /proc)
if [[ -f "$PID_FILE" ]]; then
    # Read PID, ensure it's a number, send signal. Redirect errors to null.
    read -r DAEMON_PID < "$PID_FILE" || true
    if [[ -n "$DAEMON_PID" ]]; then
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
    unit)
        TEXT="$UNIT"
        ;;
    up)
        TEXT="$UP"
        ;;
    down)
        TEXT="$DOWN"
        ;;
    *)
        echo "{}"
        exit 0
        ;;
esac

# Tooltip is always full info
TOOLTIP="Download: ${DOWN} ${UNIT}/s\nUpload:   ${UP} ${UNIT}/s"

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$TEXT" "$CLASS" "$TOOLTIP"
