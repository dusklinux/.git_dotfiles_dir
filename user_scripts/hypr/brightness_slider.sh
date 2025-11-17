#!/usr/bin/env bash
set -euo pipefail

# Real-time brightness slider using yad + brightnessctl (labeled)
# - updates brightness as you drag the slider (uses yad --print-partial)
# - saves last value in /tmp/brightness_slider.temp
# - accepts optional device or class flags to pass to brightnessctl
# Usage: ./brightness_slider.sh [-d DEVICE] [-c CLASS]
# Only change from original: added a top label (--text) to indicate purpose.

TEMP_FILE="/tmp/brightness_slider.temp"
DEFAULT_PCT=50
MIN_PCT=1
MAX_PCT=99
DEVICE=""
CLASS=""

print_usage() {
    cat <<EOF
Usage: $0 [-d DEVICE] [-c CLASS]

Options:
  -d DEVICE    pass to brightnessctl as --device=DEVICE
  -c CLASS     pass to brightnessctl as --class=CLASS
EOF
}

while getopts ":d:c:h" opt; do
    case "$opt" in
        d) DEVICE="$OPTARG" ;;
        c) CLASS="$OPTARG" ;;
        h) print_usage; exit 0 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
        \?) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done

BRIGHTNESSCTL=(brightnessctl)
[ -n "$DEVICE" ] && BRIGHTNESSCTL+=(--device="$DEVICE")
[ -n "$CLASS" ] && BRIGHTNESSCTL+=(--class="$CLASS")

# dependencies
if ! command -v yad >/dev/null 2>&1; then
    echo "This script requires 'yad'. Install it (e.g. sudo pacman -S yad)" >&2
    exit 1
fi
if ! command -v brightnessctl >/dev/null 2>&1; then
    echo "brightnessctl not found in PATH. Install it (e.g. sudo pacman -S brightnessctl)" >&2
    exit 1
fi

# helper to read current percentage (integer 0-100)
get_current_pct() {
    if CURRENT_RAW=$("${BRIGHTNESSCTL[@]}" g 2>/dev/null); then
        if MAX_RAW=$("${BRIGHTNESSCTL[@]}" m 2>/dev/null); then
            if [ "$MAX_RAW" -gt 0 ]; then
                echo $(( (CURRENT_RAW * 100 + MAX_RAW/2) / MAX_RAW ))
                return 0
            fi
        fi
    fi
    echo "$DEFAULT_PCT"
}

if [ ! -f "$TEMP_FILE" ]; then
    echo "$DEFAULT_PCT" > "$TEMP_FILE"
fi

CURRENT_PCT=$(cat "$TEMP_FILE" 2>/dev/null || echo "$DEFAULT_PCT")

YAD_ARGS=(
    --scale
    --title="brightness"
    --text="brightness"
    --min-value="$MIN_PCT"
    --max-value="$MAX_PCT"
    --value="$CURRENT_PCT"
    --step=1
    --show-value
    --print-partial
    --width=420
    --height=90
    --buttons-layout=center
    --button=OK:0
)

"yad" "${YAD_ARGS[@]}" | while IFS= read -r NEW_PCT; do
    NEW_PCT_INT=${NEW_PCT%.*}
    if [ -n "$NEW_PCT_INT" ] && [ "$NEW_PCT_INT" != "$CURRENT_PCT" ]; then
        if ! "${BRIGHTNESSCTL[@]}" set "${NEW_PCT_INT}%" >/dev/null 2>&1; then
            :
        fi
        echo "$NEW_PCT_INT" > "$TEMP_FILE" || true
        CURRENT_PCT="$NEW_PCT_INT"
    fi
done

YAD_EXIT=${PIPESTATUS[0]:-1}

if [ "$YAD_EXIT" -ne 0 ]; then
    exit 0
fi

exit 0
