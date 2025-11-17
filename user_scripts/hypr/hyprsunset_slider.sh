#!/usr/bin/env bash
set -euo pipefail

# hyprsunset real-time slider for Hyprland (improved)
# - updates `hyprctl hyprsunset temperature` as you move the slider (uses yad --print-partial)
# - will start hyprsunset if it's not already running (tries systemd --user first, falls back to launching binary)
# - keeps the last value in /tmp/hyprsunset.temp
# - title is "hyprsunset" (useful for Hyprland window rules)
# - more robust error handling and a short wait for hyprsunset IPC readiness

TEMP_FILE="/tmp/hyprsunset.temp"
DEFAULT_TEMP=4500
MIN_TEMP=1000
MAX_TEMP=5000

# how long to wait (seconds) after starting hyprsunset for IPC to be available
STARTUP_WAIT=5

# check dependencies
if ! command -v yad >/dev/null 2>&1; then
    echo "This script requires 'yad'. Install it (e.g. sudo pacman -S yad)" >&2
    exit 1
fi
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "hyprctl not found in PATH. This script must run on a system with Hyprland." >&2
    exit 1
fi

# Initialize temp file if missing
if [ ! -f "$TEMP_FILE" ]; then
    echo "$DEFAULT_TEMP" > "$TEMP_FILE"
fi

# Read last value (fallback to default on failure)
CURRENT_TEMP=$(cat "$TEMP_FILE" 2>/dev/null || echo "$DEFAULT_TEMP")
# keep only integer part
CURRENT_TEMP=${CURRENT_TEMP%.*}

# helper: check if hyprsunset process exists
is_hyprsunset_running() {
    # if systemd service is used, the process may still be named 'hyprsunset'
    if pgrep -x hyprsunset >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# helper: try to start hyprsunset
start_hyprsunset() {
    echo "hyprsunset not running — attempting to start it..." >&2

    # try systemd --user first if available
    if command -v systemctl >/dev/null 2>&1; then
        # try starting the user service (works if the package provided a systemd unit)
        if systemctl --user start hyprsunset.service 2>/dev/null; then
            echo "started hyprsunset via systemctl --user" >&2
        fi
    fi

    # if still not running, fall back to spawning the binary in background
    if ! is_hyprsunset_running; then
        if command -v hyprsunset >/dev/null 2>&1; then
            # run in background, detach
            nohup hyprsunset >/dev/null 2>&1 &
            disown >/dev/null 2>&1 || true
            echo "launched hyprsunset binary in background" >&2
        else
            echo "hyprsunset binary not found; cannot start it." >&2
            return 1
        fi
    fi

    # wait shortly for IPC readiness
    local deadline=$((SECONDS + STARTUP_WAIT))
    while [ $SECONDS -le $deadline ]; do
        # try a harmless hyprctl call to probe readiness
        if hyprctl hyprsunset temperature "$CURRENT_TEMP" >/dev/null 2>&1; then
            echo "hyprsunset IPC ready" >&2
            return 0
        fi
        sleep 0.2
    done

    echo "timeout waiting for hyprsunset IPC" >&2
    return 1
}

# Build YAD arguments
YAD_ARGS=(
    --title="hyprsunset"
    --text="hyprsunset"
    --scale
    --min-value="$MIN_TEMP"
    --max-value="$MAX_TEMP"
    --value="$CURRENT_TEMP"
    --step=1
    --show-value
    --print-partial
    --width=420
    --height=90
    --button=OK:0
    --buttons-layout=center
)

# Launch YAD and read partial values as they come out
"yad" "${YAD_ARGS[@]}" | while IFS= read -r NEW_TEMP; do
    # normalize to integer (yad may emit floats)
    NEW_TEMP_INT=${NEW_TEMP%.*}

    # skip if empty or unchanged
    if [ -z "$NEW_TEMP_INT" ] || [ "$NEW_TEMP_INT" = "$CURRENT_TEMP" ]; then
        continue
    fi

    # attempt to set temperature via hyprctl. If it fails, try to start hyprsunset and retry once.
    if ! hyprctl hyprsunset temperature "$NEW_TEMP_INT" >/dev/null 2>&1; then
        # try to start hyprsunset if not running
        if ! is_hyprsunset_running; then
            start_hyprsunset || true
        fi
        # retry once (don't fail loudly if it still doesn't work)
        hyprctl hyprsunset temperature "$NEW_TEMP_INT" >/dev/null 2>&1 || true
    fi

    # persist last value locally
    echo "$NEW_TEMP_INT" > "$TEMP_FILE" || true
    CURRENT_TEMP="$NEW_TEMP_INT"
done

YAD_EXIT=${PIPESTATUS[0]:-1}

# graceful exit
if [ "$YAD_EXIT" -ne 0 ]; then
    exit 0
fi

exit 0
