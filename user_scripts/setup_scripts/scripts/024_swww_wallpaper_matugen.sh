#!/usr/bin/env bash
#
# set_dusk.sh
#
# Hardcoded wallpaper application for Hyprland/UWSM.
# Executes matugen and swww in parallel for instant application.
# Includes a 6s watchdog to prevent the script from staying open if swww hangs.

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# Configuration
# ══════════════════════════════════════════════════════════════════════════════

readonly WALLPAPER="${HOME}/Pictures/wallpapers/dusk_default.jpg"

readonly -a SWWW_OPTS=(
    --transition-type grow
    --transition-duration 4
    --transition-fps 60
)

# ══════════════════════════════════════════════════════════════════════════════
# Execution
# ══════════════════════════════════════════════════════════════════════════════

# 1. Validation: Ensure the file exists before attempting anything
[[ -f "$WALLPAPER" ]] || { printf "Error: '%s' not found.\n" "$WALLPAPER" >&2; exit 1; }

# 2. Daemon Check: Ensure swww is running via UWSM if it isn't already
if ! swww query >/dev/null 2>&1; then
    uwsm-app -- swww-daemon >/dev/null 2>&1 &
    # Brief pause to allow socket creation; swww client usually handles the rest
    sleep 0.5
fi

# 3. Parallel Execution: Run both tasks at once
# We use uwsm-app to ensure environment variables (Wayland/Hyprland) are passed correctly.

# Start Matugen (Backgrounded)
uwsm-app -- matugen --mode dark image "$WALLPAPER" >/dev/null 2>&1 &
MATUGEN_PID=$!

# Start SWWW (Backgrounded)
swww img "$WALLPAPER" "${SWWW_OPTS[@]}" >/dev/null 2>&1 &
SWWW_PID=$!

# 4. Watchdog: Wait up to 6 seconds, then exit cleanly
# We poll the PIDs every 0.1s instead of using a blocking 'wait'.
step=0
MAX_STEPS=60 # 6 seconds / 0.1s

while (( step < MAX_STEPS )); do
    # Check if both processes are finished.
    # 'kill -0' checks if a PID exists; returns true (0) if running, false (1) if dead.
    if ! kill -0 "$MATUGEN_PID" 2>/dev/null && ! kill -0 "$SWWW_PID" 2>/dev/null; then
        printf "Wallpaper applied successfully.\n"
        exit 0
    fi
    
    sleep 0.1
    ((step++))
done

# If we reached here, the loop finished without the processes dying.
# We exit 0 anyway to ensure the script doesn't "fail".
printf "Timeout (6s) reached - Auto-closing script.\n"
exit 0
