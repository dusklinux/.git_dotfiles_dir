#!/bin/bash

# ==============================================================================
# SCRIPT CONFIGURATION
# ==============================================================================
# Duration to run Waybar in seconds
DURATION=60

# The lock file prevents the script from running multiple times simultaneously
LOCK_FILE="/tmp/waybar_timer_script.lock"

# ==============================================================================
# SAFETY & CONCURRENCY CHECKS
# ==============================================================================

# 1. FILE LOCKING:
# We open a file descriptor (200) to the lock file.
# flock -n tries to acquire a lock. If it fails (exit code 1), another instance is running.
exec 200>"$LOCK_FILE"
flock -n 200 || {
    echo "Error: An instance of this script is already running."
    exit 1
}

# 2. EXISTING PROCESS CHECK:
# We check if waybar is ALREADY running (manually or via Hyprland config).
# If it is, we do not touch it to avoid killing your main status bar.
if pgrep -x "waybar" > /dev/null; then
    echo "Error: Waybar is already running. This script will not interfere with an existing instance."
    exit 1
fi

# ==============================================================================
# CLEANUP TRAP
# ==============================================================================
# This function runs AUTOMATICALLY when the script exits for ANY reason.
# This includes:
# - Natural completion (time up)
# - Script crash
# - User hitting Ctrl+C (SIGINT)
# - System sending SIGTERM
cleanup() {
    # Check if our specific child process is still running
    if [[ -n "$WAYBAR_PID" ]] && kill -0 "$WAYBAR_PID" 2>/dev/null; then
        echo "Stopping Waybar (PID: $WAYBAR_PID)..."
        kill "$WAYBAR_PID" 
        
        # Wait briefly to ensure it dies, if not, force kill
        wait "$WAYBAR_PID" 2>/dev/null || true
    fi
    
    # Double check: Ensure no orphaned waybar processes exist if the PID method failed
    # (Only if we are sure we started it, checking pgrep again is a safety net)
    if pgrep -x "waybar" > /dev/null; then
        # Ensure we only kill if it looks like the one we started (sanity check)
        killall waybar 2>/dev/null
    fi

    # Remove the lock file cleanly
    rm -f "$LOCK_FILE"
    echo "Clean exit."
}

# Register the trap for EXIT, SIGINT (Ctrl+C), and SIGTERM
trap cleanup EXIT INT TERM

# ==============================================================================
# EXECUTION
# ==============================================================================

echo "Starting Waybar via uwsm-app for $DURATION seconds..."

# Start Waybar in the background using the requested command
uwsm-app -- waybar &
WAYBAR_PID=$!

# 3. STARTUP VERIFICATION:
# Wait 1 second and check if it actually started (catches config errors)
sleep 1
if ! kill -0 "$WAYBAR_PID" 2>/dev/null; then
    echo "Error: Waybar failed to start or died immediately."
    exit 1
fi

echo "Waybar active (PID: $WAYBAR_PID). Timer started."

# ==============================================================================
# MONITORING (The Logic)
# ==============================================================================
# We need to wait for EITHER:
# A) The duration to expire
# B) The Waybar process to die (e.g., user ran 'pkill waybar')
#
# 'tail --pid=$PID -f /dev/null' blocks until the PID disappears.
# 'timeout' kills that 'tail' command if the duration passes.

timeout "$DURATION" tail --pid="$WAYBAR_PID" -f /dev/null
EXIT_STATUS=$?

# ==============================================================================
# STATUS REPORTING
# ==============================================================================

if [ $EXIT_STATUS -eq 124 ]; then
    echo "Time limit reached ($DURATION seconds)."
else
    echo "Waybar was closed externally before time limit."
fi

# The script now reaches the end. 
# The 'trap cleanup EXIT' defined above triggers automatically here.
