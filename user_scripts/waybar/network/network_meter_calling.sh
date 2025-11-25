#!/usr/bin/env bash
#===============================================================================
# waybar-net: Prints JSON for Waybar custom network module
# Usage: waybar-net [unit|up|upload|down|download]
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
readonly STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar-net"
readonly STATE_FILE="${STATE_DIR}/state"
readonly HEARTBEAT_FILE="${STATE_DIR}/heartbeat"
readonly PIDFILE="${STATE_DIR}/daemon.pid"

#-------------------------------------------------------------------------------
# Initialization
#-------------------------------------------------------------------------------
# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Update heartbeat to signal activity to daemon
touch "$HEARTBEAT_FILE"

# Wake daemon via PID file (safer than pkill -f)
if [[ -r "$PIDFILE" ]]; then
    if read -r daemon_pid < "$PIDFILE" 2>/dev/null && [[ -n "$daemon_pid" ]]; then
        # Verify process exists before signaling
        if kill -0 "$daemon_pid" 2>/dev/null; then
            kill -USR1 "$daemon_pid" 2>/dev/null || true
        fi
    fi
fi

#-------------------------------------------------------------------------------
# Read State with Defaults
#-------------------------------------------------------------------------------
UNIT="KB"
UP="0"
DOWN="0"
CLASS="network-kb"

# Read state file with validation
if [[ -f "$STATE_FILE" && -r "$STATE_FILE" && -s "$STATE_FILE" ]]; then
    if IFS=' ' read -r r_unit r_up r_down r_class < "$STATE_FILE" 2>/dev/null; then
        # Only accept non-empty values
        [[ -n "${r_unit:-}" ]]  && UNIT="$r_unit"
        [[ -n "${r_up:-}" ]]    && UP="$r_up"
        [[ -n "${r_down:-}" ]]  && DOWN="$r_down"
        [[ -n "${r_class:-}" ]] && CLASS="$r_class"
    fi
fi

#-------------------------------------------------------------------------------
# Generate Output
#-------------------------------------------------------------------------------
case "${1:-}" in
    unit)
        TEXT="$UNIT"
        TOOLTIP="Unit: ${UNIT}/s"
        ;;
    up|upload)
        TEXT="$UP"
        TOOLTIP="Upload: ${UP} ${UNIT}/s\\nDownload: ${DOWN} ${UNIT}/s"
        ;;
    down|download)
        TEXT="$DOWN"
        TOOLTIP="Download: ${DOWN} ${UNIT}/s\\nUpload: ${UP} ${UNIT}/s"
        ;;
    *)
        printf '%s\n' '{}'
        exit 0
        ;;
esac

#-------------------------------------------------------------------------------
# JSON Output (with basic escaping for safety)
#-------------------------------------------------------------------------------
# Escape any quotes or backslashes in values
json_safe() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
    "$(json_safe "$TEXT")" \
    "$(json_safe "$CLASS")" \
    "$TOOLTIP"
