#!/usr/bin/env bash

# ==============================================================================
# Hyprsunset Slider (Optimized)
# ==============================================================================
# - Real-time temperature adjustment for Hyprland
# - Auto-launches hyprsunset if missing
# - Single-instance enforcement with window focus
# - Crash protection and efficient IPC handling
# ==============================================================================

set -u # Error on unset variables (safety)

# --- Constants ---
readonly APP_NAME="hyprsunset"
readonly TITLE_HINT="Hyprsunset"
readonly LOCK_KEY="hyprsunset_slider"

# Use XDG_RUNTIME_DIR for security/isolation (falls back to /tmp if unset)
readonly RUN_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
readonly STATE_FILE="$RUN_DIR/hyprsunset_last_temp"
readonly LOCK_BASE="$RUN_DIR/yad_locks"
readonly LOCK_FILE="$LOCK_BASE/$LOCK_KEY.lock"
readonly LOCK_DIR="$LOCK_BASE/$LOCK_KEY.lockdir"

readonly DEFAULT_TEMP=4500
readonly MIN_TEMP=1000
readonly MAX_TEMP=6000
readonly STARTUP_WAIT=5

# --- Dependency Check ---
for cmd in yad hyprctl pgrep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        notify-send -u critical "$TITLE_HINT Error" "Missing dependency: $cmd"
        echo "Error: Missing dependency '$cmd'" >&2
        exit 1
    fi
done

# ==============================================================================
# 1. Single Instance & Focus Logic
# ==============================================================================

_focus_existing_window() {
    # Method 1: wmctrl (fastest if available)
    if command -v wmctrl >/dev/null 2>&1; then
        if wmctrl -a "$TITLE_HINT" 2>/dev/null; then return 0; fi
    fi

    # Method 2: hyprctl direct dispatch
    if hyprctl dispatch focuswindow "title:^${TITLE_HINT}$" >/dev/null 2>&1; then
        return 0
    fi

    # Method 3: Manual address lookup (robust fallback)
    if command -v jq >/dev/null 2>&1; then
        local addr
        addr=$(hyprctl clients -j | jq -r --arg t "$TITLE_HINT" '.[] | select(.title == $t) | .address' | head -n1)
        if [[ -n "$addr" && "$addr" != "null" ]]; then
            hyprctl dispatch focuswindow "address:$addr" >/dev/null 2>&1
            return 0
        fi
    fi
    return 1
}

# Ensure lock directory exists
mkdir -p "$LOCK_BASE"

# Try to acquire lock
if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
        _focus_existing_window
        exit 0
    fi
    # Lock acquired, cleanup on exit
    trap 'exec 9>&-; rm -f "$LOCK_FILE"; exit' INT TERM EXIT
else
    # Fallback for systems without flock (rare, but safe)
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        echo "$$" > "$LOCK_DIR/pid"
        trap 'rm -rf "$LOCK_DIR"; exit' INT TERM EXIT
    else
        if [ -f "$LOCK_DIR/pid" ]; then
            old_pid=$(cat "$LOCK_DIR/pid" 2>/dev/null || echo "")
            if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
                _focus_existing_window
                exit 0
            else
                # Stale lock detected
                rm -rf "$LOCK_DIR"
                mkdir "$LOCK_DIR"
                echo "$$" > "$LOCK_DIR/pid"
                trap 'rm -rf "$LOCK_DIR"; exit' INT TERM EXIT
            fi
        fi
    fi
fi

# ==============================================================================
# 2. Service Management Functions
# ==============================================================================

# Initialize state file if missing
if [ ! -f "$STATE_FILE" ]; then
    echo "$DEFAULT_TEMP" > "$STATE_FILE"
fi

get_current_temp() {
    local val
    val=$(cat "$STATE_FILE" 2>/dev/null || echo "$DEFAULT_TEMP")
    echo "${val%.*}" # Integer only
}

is_daemon_running() {
    # Check for process belonging to current user only
    pgrep -u "$(id -u)" -x "$APP_NAME" >/dev/null 2>&1
}

start_daemon() {
    echo "Starting $APP_NAME..." >&2

    # 1. Try systemd --user
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl --user start "$APP_NAME" 2>/dev/null; then
            # Wait for process to appear
            local deadline=$((SECONDS + STARTUP_WAIT))
            while [ $SECONDS -le $deadline ]; do
                is_daemon_running && return 0
                sleep 0.2
            done
        fi
    fi

    # 2. Fallback: Direct Binary Launch
    if ! is_daemon_running; then
        local bin_path
        bin_path=$(command -v "$APP_NAME" 2>/dev/null)
        
        if [ -n "$bin_path" ]; then
            # Use setsid to detach completely
            setsid "$bin_path" >/dev/null 2>&1 &
            disown $! 2>/dev/null || true
        else
            notify-send -u critical "Hyprsunset Error" "Binary not found."
            return 1
        fi
    fi

    # 3. Wait for IPC Readiness (Critical for preventing lag)
    local deadline=$((SECONDS + STARTUP_WAIT))
    local current=$(get_current_temp)
    while [ $SECONDS -le $deadline ]; do
        if hyprctl hyprsunset temperature "$current" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.2
    done
    
    return 1
}

# ==============================================================================
# 3. Main Logic Loop
# ==============================================================================

CURRENT_TEMP=$(get_current_temp)
LAST_RESTART_ATTEMPT=0

# Ensure it's running before showing UI
if ! is_daemon_running; then
    start_daemon || true
fi

# YAD UI Definition
YAD_CMD=(
    yad
    --title="$TITLE_HINT"
    --class="$TITLE_HINT"
    --scale
    --text="Temperature (K)"
    --min-value="$MIN_TEMP"
    --max-value="$MAX_TEMP"
    --value="$CURRENT_TEMP"
    --step=50
    --show-value
    --print-partial
    --width=400
    --height=50
    --window-icon="preferences-system"
    --button="Close":1
    --buttons-layout=end
)

# Loop using Process Substitution to avoid subshell issues
while IFS= read -r NEW_TEMP; do
    # Sanitize input (integer only)
    NEW_TEMP=${NEW_TEMP%.*}
    
    # Ignore empty or unchanged values
    if [[ -z "$NEW_TEMP" || "$NEW_TEMP" == "$CURRENT_TEMP" ]]; then
        continue
    fi

    # Try to apply temperature
    if ! hyprctl hyprsunset temperature "$NEW_TEMP" >/dev/null 2>&1; then
        # IPC Failed.
        
        # Check if we should attempt a restart (Rate Limit: Once every 3 seconds)
        NOW=$(date +%s)
        if (( NOW - LAST_RESTART_ATTEMPT > 3 )); then
            if ! is_daemon_running; then
                start_daemon || true
            fi
            LAST_RESTART_ATTEMPT=$NOW
            
            # Retry the command once
            hyprctl hyprsunset temperature "$NEW_TEMP" >/dev/null 2>&1 || true
        fi
    fi

    # Update state
    CURRENT_TEMP="$NEW_TEMP"
    echo "$CURRENT_TEMP" > "$STATE_FILE"

done < <("${YAD_CMD[@]}")

exit 0
