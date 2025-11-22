#!/usr/bin/env bash

# ==============================================================================
# Hyprsunset Slider (Finalized)
# ==============================================================================

set -u # Error on unset variables

# --- Constants ---
readonly APP_NAME="hyprsunset"
readonly TITLE_HINT="Hyprsunset"
readonly LOCK_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${APP_NAME}_slider.lock"
readonly STATE_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hyprsunset_last_temp"

# Temperature Limits
readonly DEFAULT_TEMP=4500
readonly MIN_TEMP=1000
readonly MAX_TEMP=6000
readonly STARTUP_WAIT=5

# --- Dependency Check ---
for cmd in yad hyprctl pgrep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        notify-send -u critical "$TITLE_HINT Error" "Missing dependency: $cmd"
        exit 1
    fi
done

# ==============================================================================
# 1. Single Instance & Focus Logic (Standardized)
# ==============================================================================

# Use File Descriptor 200 for locking (Cleaner method)
exec 200>"$LOCK_FILE"

_focus_existing() {
    # Method 1: Hyprland JSON lookup (Most robust)
    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        local addr
        # Look for window by Title
        addr=$(hyprctl clients -j | jq -r --arg t "$TITLE_HINT" '.[] | select(.title == $t) | .address' | head -n1)
        if [[ -n "$addr" && "$addr" != "null" ]]; then
            hyprctl dispatch focuswindow "address:$addr" >/dev/null 2>&1
            return 0
        fi
    fi

    # Method 2: Fallback to Title Regex
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch focuswindow "title:^${TITLE_HINT}$" >/dev/null 2>&1
        return 0
    fi

    # Method 3: wmctrl (X11/Wayland fallback)
    if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -a "$TITLE_HINT" 2>/dev/null
    fi
}

# If we cannot acquire the lock, focus the existing window and exit
if ! flock -n 200; then
    _focus_existing
    exit 0
fi

# ==============================================================================
# 2. Service Management (Daemon Auto-Start)
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

    # 3. Wait for IPC Readiness (Critical to prevent slider lag)
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

# Ensure daemon is running before showing UI
if ! is_daemon_running; then
    start_daemon || true
fi

# YAD UI Definition (Fixed Size & Layout)
YAD_CMD=(
    yad
    --title="$TITLE_HINT"
    --class="$TITLE_HINT"
    --scale
    --text="Hyprsunset (K)                      󰡬"
    --min-value="$MIN_TEMP"
    --max-value="$MAX_TEMP"
    --value="$CURRENT_TEMP"
    --step=50
    --show-value
    --print-partial
    --width=420                # Matched to other sliders
    --height=90                # Matched to other sliders
    --window-icon="preferences-system"
    --button="Close":1
    --buttons-layout=center    # Matched to other sliders
    --fixed                    # CRITICAL: Prevents tiling in Hyprland
)

# Loop using Process Substitution
while IFS= read -r NEW_TEMP; do
    # Sanitize input (integer only)
    NEW_TEMP=${NEW_TEMP%.*}
    
    # Ignore empty or unchanged values
    if [[ -z "$NEW_TEMP" || "$NEW_TEMP" == "$CURRENT_TEMP" ]]; then
        continue
    fi

    # Try to apply temperature
    if ! hyprctl hyprsunset temperature "$NEW_TEMP" >/dev/null 2>&1; then
        # IPC Failed. Check if we should attempt a restart (Rate Limit: Once every 3s)
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
