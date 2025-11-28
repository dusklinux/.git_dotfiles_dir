#!/usr/bin/env bash
#
# set_dusk.sh
#
# Hardcoded wallpaper application for Hyprland/UWSM.
# Executes matugen and swww in parallel for instant application.

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

# 4. Cleanup: Wait for both processes to finish so the script exits cleanly
wait "$MATUGEN_PID" "$SWWW_PID"

exit 0
