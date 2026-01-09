#!/usr/bin/env bash
# Applies the default wallpaper and generates a matching color scheme.
# Runs swww and matugen in parallel with a 6-second watchdog timeout.

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# Configuration
# ══════════════════════════════════════════════════════════════════════════════

readonly WALLPAPER="${HOME}/Pictures/wallpapers/dusk_default.jpg"
readonly DAEMON_WAIT_CYCLES=20  # 2s total (20 × 0.1s)
readonly WATCHDOG_CYCLES=60    # 6s total (60 × 0.1s)

readonly -a SWWW_OPTS=(
    --transition-type grow
    --transition-duration 4
    --transition-fps 60
)

# ══════════════════════════════════════════════════════════════════════════════
# Dependencies
# ══════════════════════════════════════════════════════════════════════════════

sudo pacman -S --needed --noconfirm matugen swww

# ══════════════════════════════════════════════════════════════════════════════
# Validation
# ══════════════════════════════════════════════════════════════════════════════

[[ -f "$WALLPAPER" ]] || {
    printf "Error: Wallpaper '%s' not found.\n" "$WALLPAPER" >&2
    exit 1
}

# ══════════════════════════════════════════════════════════════════════════════
# Daemon Initialization
# ══════════════════════════════════════════════════════════════════════════════

if ! swww query &>/dev/null; then
    swww-daemon &>/dev/null &
    
    # Poll for daemon readiness
    cycles=$DAEMON_WAIT_CYCLES
    while ! swww query &>/dev/null && (( cycles-- > 0 )); do
        sleep 0.1
    done
    
    if ! swww query &>/dev/null; then
        printf "Error: swww-daemon failed to start within 2 seconds.\n" >&2
        exit 1
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Parallel Execution
# ══════════════════════════════════════════════════════════════════════════════

matugen --mode dark image "$WALLPAPER" &>/dev/null &
MATUGEN_PID=$!

swww img "$WALLPAPER" "${SWWW_OPTS[@]}" &>/dev/null &
SWWW_PID=$!

# ══════════════════════════════════════════════════════════════════════════════
# Watchdog
# ══════════════════════════════════════════════════════════════════════════════

step=0
while (( step < WATCHDOG_CYCLES )); do
    matugen_running=0
    swww_running=0
    
    if kill -0 "$MATUGEN_PID" 2>/dev/null; then matugen_running=1; fi
    if kill -0 "$SWWW_PID" 2>/dev/null; then swww_running=1; fi

    if [[ $matugen_running -eq 0 && $swww_running -eq 0 ]]; then
        matugen_status=0
        swww_status=0
        wait "$MATUGEN_PID" || matugen_status=$?
        wait "$SWWW_PID" || swww_status=$?
        
        if (( matugen_status == 0 && swww_status == 0 )); then
            printf "Wallpaper and color scheme applied successfully.\n"
        else
            printf "Warning: Task(s) failed (matugen=%d, swww=%d).\n" \
                "$matugen_status" "$swww_status"
        fi
        exit 0
    fi
    
    sleep 0.1
    ((++step))
done

printf "Timeout (6s) reached - script auto-closing.\n"
exit 0
