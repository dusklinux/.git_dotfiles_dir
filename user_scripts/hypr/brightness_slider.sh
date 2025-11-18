#!/usr/bin/env bash

# --- single-instance guard start (brightness, Hyprland-aware) ---
LOCK_KEY="brightness_slider"
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
LOCK_BASE="$XDG_RUNTIME_DIR/yad_locks"
mkdir -p "$LOCK_BASE"
LOCKFILE="$LOCK_BASE/$LOCK_KEY.lock"
LOCKDIR="$LOCK_BASE/$LOCK_KEY.lockdir"
TITLE_HINT="Brightness"    # change THIS if your yad uses a different --title or --name

_try_focus_existing() {
  # X11 fallback
  if command -v wmctrl >/dev/null 2>&1; then
    wmctrl -a "$TITLE_HINT" 2>/dev/null || true
    return 0
  fi

  # Hyprland: try hyprctl dispatch by title, then fallback to clients-json -> address
  if command -v hyprctl >/dev/null 2>&1; then
    # Try direct dispatcher match by title
    if hyprctl dispatch focuswindow "title:$TITLE_HINT" >/dev/null 2>&1; then
      return 0
    fi

    # Fallback: use clients JSON (requires jq) to get an address and focus by address
    if command -v jq >/dev/null 2>&1; then
      addr=$(hyprctl clients -j 2>/dev/null | jq -r --arg t "$TITLE_HINT" '.[] | select(.title == $t) | .address' | head -n1)
      if [ -n "$addr" ] && [ "$addr" != "null" ]; then
        hyprctl dispatch focuswindow "address:$addr" >/dev/null 2>&1 || true
        return 0
      fi
    fi
  fi

  return 1
}

if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCKFILE" || exit 0
  if ! flock -n 9; then
    _try_focus_existing
    exit 0
  fi
  trap 'exec 9>&-; exit' INT TERM EXIT
else
  if mkdir "$LOCKDIR" 2>/dev/null; then
    printf "%s\n" "$$" > "$LOCKDIR/pid"
    trap 'if [ -f "$LOCKDIR/pid" ] && [ "$(cat "$LOCKDIR/pid")" = "$$" ]; then rm -rf "$LOCKDIR"; fi; exit' INT TERM EXIT
  else
    if [ -f "$LOCKDIR/pid" ]; then
      OLDPID=$(cat "$LOCKDIR/pid" 2>/dev/null || true)
      if [ -n "$OLDPID" ] && kill -0 "$OLDPID" 2>/dev/null; then
        _try_focus_existing
        exit 0
      else
        rm -rf "$LOCKDIR"
        if mkdir "$LOCKDIR" 2>/dev/null; then
          printf "%s\n" "$$" > "$LOCKDIR/pid"
          trap 'if [ -f "$LOCKDIR/pid" ] && [ "$(cat "$LOCKDIR/pid")" = "$$" ]; then rm -rf "$LOCKDIR"; fi; exit' INT TERM EXIT
        else
          _try_focus_existing
          exit 0
        fi
      fi
    else
      _try_focus_existing
      exit 0
    fi
  fi
fi
# --- single-instance guard end ---

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
