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

    # Try systemd --user first (try both unit and plain name). If it returns success,
    # wait a short while for the process to appear.
    if command -v systemctl >/dev/null 2>&1; then
        for svc in hyprsunset.service hyprsunset; do
            if systemctl --user start "$svc" 2>/dev/null; then
                echo "requested start via systemctl --user ($svc)" >&2
                # give systemd a small grace period for the process to spawn
                local deadline=$((SECONDS + STARTUP_WAIT + 5))
                while [ $SECONDS -le $deadline ]; do
                    if is_hyprsunset_running; then
                        echo "hyprsunset started (systemd)" >&2
                        break
                    fi
                    sleep 0.2
                done
                break
            fi
        done
    fi

    # If still not running, try launching the binary directly in a detached session.
    if ! is_hyprsunset_running; then
        if hyprpath=$(command -v hyprsunset 2>/dev/null); then
            echo "launching hyprsunset binary ($hyprpath) with setsid" >&2
            # use setsid to detach fully; fall back to nohup if setsid not allowed
            if setsid "$hyprpath" >/dev/null 2>&1 < /dev/null & then
                disown >/dev/null 2>&1 || true
            else
                nohup "$hyprpath" >/dev/null 2>&1 &
                disown >/dev/null 2>&1 || true
            fi
            echo "launched hyprsunset binary in background" >&2
        else
            echo "hyprsunset binary not found; cannot start it." >&2
            return 1
        fi
    fi

    # Wait for IPC readiness. Give a slightly longer window than before.
    local deadline=$((SECONDS + STARTUP_WAIT + 5))
    while [ $SECONDS -le $deadline ]; do
        # try a harmless hyprctl call to probe readiness
        if hyprctl hyprsunset temperature "$CURRENT_TEMP" >/dev/null 2>&1; then
            echo "hyprsunset IPC ready" >&2
            return 0
        fi
        sleep 0.25
    done

    # Final check: if process exists but IPC didn't respond, don't treat as fatal.
    if is_hyprsunset_running; then
        echo "hyprsunset process present but IPC still not ready after timeout" >&2
        return 0
    fi

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
