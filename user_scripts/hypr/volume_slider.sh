#!/usr/bin/env bash
set -euo pipefail

# Real-time volume slider for PipeWire/PulseAudio using yad (labeled)
# - updates volume as you drag the slider (uses yad --print-partial)
# - stores last value in /tmp/volume_slider.temp
# - prefers pamixer (simple), falls back to pactl
# Usage: ./volume_slider.sh [-s SINK]
# Only change from original: added a top label (--text) to indicate purpose.

TEMP_FILE="/tmp/volume_slider.temp"
DEFAULT_PCT=50
MIN_PCT=0
MAX_PCT=99   # allow amplification above 100%
SINK=""

print_usage() {
    cat <<EOF
Usage: $0 [-s SINK]

Options:
  -s SINK    specify sink name or index (passed to pactl or pamixer if supported)
EOF
}

while getopts ":s:h" opt; do
    case "$opt" in
        s) SINK="$OPTARG" ;;
        h) print_usage; exit 0 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
        \?) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
    esac
done

BACKEND=""
if command -v pamixer >/dev/null 2>&1; then
    BACKEND="pamixer"
elif command -v pactl >/dev/null 2>&1; then
    BACKEND="pactl"
else
    echo "This script requires either 'pamixer' or 'pactl' to be installed." >&2
    echo "On Arch: sudo pacman -S pamixer alsa-utils pulseaudio-ctl" >&2
    exit 1
fi

resolve_pactl_sink() {
    if [ -n "$SINK" ]; then
        echo "$SINK"
        return
    fi
    DEFAULT=$(pactl info 2>/dev/null | awk -F": " '/Default Sink/ {print $2}' | tr -d '\n')
    if [ -n "$DEFAULT" ]; then
        echo "$DEFAULT"
        return
    fi
    pactl list short sinks 2>/dev/null | awk 'NR==1{print $2}'
}

get_current_pct() {
    if [ "$BACKEND" = "pamixer" ]; then
        if [ -n "$SINK" ]; then
            pamixer --sink="$SINK" --get-volume 2>/dev/null || echo "$DEFAULT_PCT"
        else
            pamixer --get-volume 2>/dev/null || echo "$DEFAULT_PCT"
        fi
        return
    fi

    S=$(resolve_pactl_sink)
    if [ -z "$S" ]; then
        echo "$DEFAULT_PCT"
        return
    fi
    RAW=$(pactl get-sink-volume "$S" 2>/dev/null || true)
    if [ -z "$RAW" ]; then
        echo "$DEFAULT_PCT"
        return
    fi
    PCT=$(printf "%s" "$RAW" | grep -m1 -oE '[0-9]+%' | tr -d '%')
    if [ -z "$PCT" ]; then
        echo "$DEFAULT_PCT"
    else
        echo "$PCT"
    fi
}

set_volume_pct() {
    local pct="$1"
    if [ "$BACKEND" = "pamixer" ]; then
        if [ -n "$SINK" ]; then
            pamixer --sink="$SINK" --set-volume "$pct" --unmute >/dev/null 2>&1 || true
        else
            pamixer --set-volume "$pct" --unmute >/dev/null 2>&1 || true
        fi
        return
    fi

    S=$(resolve_pactl_sink)
    if [ -z "$S" ]; then
        return
    fi
    pactl set-sink-volume "$S" "${pct}%" >/dev/null 2>&1 || true
    pactl set-sink-mute "$S" 0 >/dev/null 2>&1 || true
}

if [ ! -f "$TEMP_FILE" ]; then
    echo "$DEFAULT_PCT" > "$TEMP_FILE"
fi

CURRENT_PCT=$(cat "$TEMP_FILE" 2>/dev/null || echo "$DEFAULT_PCT")

YAD_ARGS=(
    --scale
    --title="volume"
    --text="volume"
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
        set_volume_pct "$NEW_PCT_INT"
        echo "$NEW_PCT_INT" > "$TEMP_FILE" || true
        CURRENT_PCT="$NEW_PCT_INT"
    fi
done

YAD_EXIT=${PIPESTATUS[0]:-1}

if [ "$YAD_EXIT" -ne 0 ]; then
    exit 0
fi

exit 0
