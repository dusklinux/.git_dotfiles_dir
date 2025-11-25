#!/usr/bin/env bash
# ==============================================================================
# Hyprland Monitor Scale Adjustment Script
# Precision-engineered for Arch Linux / Hyprland
# ==============================================================================

# Strict mode: exit on error, undefined variables, and pipe failures
set -euo pipefail

# Force C locale for consistent decimal point handling
export LC_ALL=C

# --- Configuration ---

# Target monitor (leave empty to auto-detect focused monitor)
# Override via environment: HYPR_SCALE_MONITOR="DP-1" ./script.sh +
readonly TARGET_MONITOR="${HYPR_SCALE_MONITOR:-}"

# Notification settings
readonly NOTIFY_TAG="hypr_scale_adjust"
readonly NOTIFY_TIMEOUT=2000

# Known good scale values (MUST be sorted ascending)
readonly GOOD_SCALES=(1.00 1.20 1.25 1.333333 1.50 1.60 1.666667 2.00 2.40 2.50 3.00)

# --- Helper Functions ---

die() {
    printf '%s: %s\n' "$(basename "$0")" "$*" >&2
    exit 1
}

usage() {
    cat <<-EOF
	Usage: $(basename "$0") [+|-]
	
	Options:
	  +   Increase display scale to next preset
	  -   Decrease display scale to previous preset
	
	Environment:
	  HYPR_SCALE_MONITOR   Override target monitor (e.g., "DP-1")
	
	Example:
	  $(basename "$0") +
	  HYPR_SCALE_MONITOR="eDP-1" $(basename "$0") -
	EOF
    exit 1
}

check_dependencies() {
    local missing=() cmd
    for cmd in hyprctl jq awk; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    
    ((${#missing[@]} == 0)) || die "missing required commands: ${missing[*]}"
}

send_notification() {
    local -r scale="$1" monitor="$2"
    
    # notify-send is optional - fail silently if unavailable
    command -v notify-send &>/dev/null || return 0
    
    notify-send \
        -h "string:x-canonical-private-synchronous:${NOTIFY_TAG}" \
        -u low \
        -t "$NOTIFY_TIMEOUT" \
        "Display Scale: ${scale}" \
        "Monitor: ${monitor}" 2>/dev/null || true
}

calculate_new_scale() {
    local -r current="$1" direction="$2"
    
    awk -v cur="$current" -v dir="$direction" -v scales="${GOOD_SCALES[*]}" '
    BEGIN {
        n = split(scales, arr, " ")
        
        # Find index of scale closest to current value
        best_idx = 1
        min_diff = 1e9
        for (i = 1; i <= n; i++) {
            diff = cur - arr[i]
            if (diff < 0) diff = -diff
            if (diff < min_diff) {
                min_diff = diff
                best_idx = i
            }
        }
        
        # Compute target index based on direction
        target = (dir == "+") ? best_idx + 1 : best_idx - 1
        
        # Clamp to valid range
        if (target < 1) target = 1
        if (target > n) target = n
        
        print arr[target]
    }'
}

# Floating-point safe comparison using awk
# Returns 0 (true) if values differ, 1 (false) if equal
scales_differ() {
    awk -v a="$1" -v b="$2" 'BEGIN { exit (a == b) }'
}

# --- Main Logic ---

main() {
    check_dependencies
    
    # Validate command-line arguments
    if [[ $# -ne 1 ]] || [[ "$1" != "+" && "$1" != "-" ]]; then
        usage
    fi
    local -r direction="$1"
    
    # Fetch all monitor data in a single call
    local monitors_json
    if ! monitors_json=$(hyprctl -j monitors 2>/dev/null); then
        die "failed to query hyprctl (is Hyprland running?)"
    fi
    
    # Determine which monitor to adjust
    local monitor="$TARGET_MONITOR"
    if [[ -z "$monitor" ]]; then
        monitor=$(jq -r '.[] | select(.focused) | .name // empty' <<< "$monitors_json")
        [[ -n "$monitor" ]] || die "no focused monitor detected"
    fi
    
    # Extract data for target monitor with error checking
    local monitor_json
    if ! monitor_json=$(jq -e --arg m "$monitor" '.[] | select(.name == $m)' <<< "$monitors_json" 2>/dev/null); then
        die "monitor '${monitor}' not found"
    fi
    
    # Parse all values in a single jq invocation
    local width height refresh pos_x pos_y scale
    IFS=$'\t' read -r width height refresh pos_x pos_y scale < <(
        jq -r '[.width, .height, .refreshRate, .x, .y, .scale] | @tsv' <<< "$monitor_json"
    )
    
    # Validate critical parsed value
    if [[ -z "$scale" || "$scale" == "null" ]]; then
        die "failed to parse current scale for '${monitor}'"
    fi
    
    # Round refresh rate to nearest integer (Hyprland convention)
    local refresh_int
    printf -v refresh_int '%.0f' "$refresh"
    
    # Determine new scale
    local new_scale
    new_scale=$(calculate_new_scale "$scale" "$direction")
    
    # Apply changes only if scale actually changed
    if scales_differ "$new_scale" "$scale"; then
        # Construct Hyprland monitor rule: NAME,WxH@HZ,POSxPOS,SCALE
        local -r rule="${monitor},${width}x${height}@${refresh_int},${pos_x}x${pos_y},${new_scale}"
        
        if ! hyprctl keyword monitor "$rule" &>/dev/null; then
            die "failed to apply monitor rule: ${rule}"
        fi
        
        send_notification "$new_scale" "$monitor"
    else
        # We're at the scale limit
        send_notification "${new_scale} (Limit)" "$monitor"
    fi
}

main "$@"
