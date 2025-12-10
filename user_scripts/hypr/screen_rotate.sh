#!/usr/bin/env bash
# ==============================================================================
#  ARCH LINUX / HYPRLAND / UWSM — SMART ROTATION UTILITY
#  Role: Elite DevOps Automation
#  Description: Context-aware screen rotation that preserves scale factors.
# ==============================================================================

# 1. Strict Mode & Safety (Bash 5+ Standards)
# ------------------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

# 2. Global Constants (ANSI-C Quoting for "Elite" Color Handling)
# ------------------------------------------------------------------------------
readonly C_RED=$'\e[31m'
readonly C_GREEN=$'\e[32m'
readonly C_YELLOW=$'\e[33m'
readonly C_BLUE=$'\e[34m'
readonly C_BOLD=$'\e[1m'
readonly C_RESET=$'\e[0m'

# cleanup_trap: Ensures clean exit codes are respected.
cleanup_trap() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        printf "%s[ERROR]%s Script aborted unexpectedly (Exit Code: %d).\n" \
            "$C_RED" "$C_RESET" "$exit_code" >&2
    fi
}
trap cleanup_trap EXIT

# 3. Environment & Privilege Checks
# ------------------------------------------------------------------------------
# Dependency Check: We need 'jq' for JSON parsing.
if ! command -v jq &> /dev/null; then
    printf "%s[ERROR]%s 'jq' is missing. Install it with: sudo pacman -S jq\n" \
        "$C_RED" "$C_RESET" >&2
    exit 1
fi

# Root Check: Hyprland IPC fails if executed as root/sudo due to socket ownership.
if [[ $EUID -eq 0 ]]; then
    printf "%s[ERROR]%s Root detected. Please run this as your normal user to access the Hyprland socket.\n" \
        "$C_RED" "$C_RESET" >&2
    exit 1
fi

# 4. Argument Parsing (+90 or -90)
# ------------------------------------------------------------------------------
DIRECTION=0

if [[ $# -ne 1 ]]; then
    printf "%s[INFO]%s Usage: %s [+90|-90]\n" \
        "$C_YELLOW" "$C_RESET" "${0##*/}"
    exit 1
fi

case "$1" in
    "+90") DIRECTION=1 ;;  # Clockwise
    "-90") DIRECTION=-1 ;; # Counter-Clockwise
    *) 
        printf "%s[ERROR]%s Invalid flag '%s'. Use +90 or -90.\n" \
            "$C_RED" "$C_RESET" "$1" >&2
        exit 1 
        ;;
esac

# 5. Hardware Detection (Smart Query)
# ------------------------------------------------------------------------------
# We fetch the entire JSON blob once to minimize IPC calls (Performance).
# We strictly select index [0] as per your "single monitor system" constraint.
MON_STATE=$(hyprctl monitors -j)

# Extract precise values using jq
NAME=$(printf "%s" "$MON_STATE" | jq -r '.[0].name')
SCALE=$(printf "%s" "$MON_STATE" | jq -r '.[0].scale')
CURRENT_TRANSFORM=$(printf "%s" "$MON_STATE" | jq -r '.[0].transform')

# Validation: Ensure we actually found a monitor
if [[ -z "$NAME" || "$NAME" == "null" ]]; then
    printf "%s[ERROR]%s No active monitors detected via Hyprland IPC.\n" \
        "$C_RED" "$C_RESET" >&2
    exit 1
fi

# 6. Transformation Logic (Modulo Arithmetic)
# ------------------------------------------------------------------------------
# Hyprland Transforms: 0=Normal, 1=90, 2=180, 3=270
# The '+ 4' ensures we handle negative wraparounds correctly in Bash logic.
NEW_TRANSFORM=$(( (CURRENT_TRANSFORM + DIRECTION + 4) % 4 ))

# 7. Execution (State overwrite)
# ------------------------------------------------------------------------------
# We use 'preferred' and 'auto' to remain robust against resolution changes,
# but we STRICTLY inject the detected $SCALE to prevent UI scaling issues.

printf "%s[INFO]%s Rotating %s%s%s (Scale: %s): %d -> %d\n" \
    "$C_BLUE" "$C_RESET" "$C_BOLD" "$NAME" "$C_RESET" "$SCALE" "$CURRENT_TRANSFORM" "$NEW_TRANSFORM"

# Apply the new configuration immediately via IPC
if hyprctl keyword monitor "${NAME}, preferred, auto, ${SCALE}, transform, ${NEW_TRANSFORM}" > /dev/null; then
    printf "%s[SUCCESS]%s Rotation applied successfully.\n" \
        "$C_GREEN" "$C_RESET"
    
    # Notify user visually if notify-send is available (optional UX improvement)
    if command -v notify-send &> /dev/null; then
        notify-send -a "System" "Display Rotated" "Monitor: $NAME\nTransform: $NEW_TRANSFORM" -h string:x-canonical-private-synchronous:display-rotate
    fi
else
    printf "%s[ERROR]%s Failed to apply Hyprland keyword.\n" \
        "$C_RED" "$C_RESET" >&2
    exit 1
fi

# Clean exit
trap - EXIT
exit 0
