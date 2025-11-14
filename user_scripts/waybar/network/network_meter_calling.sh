#!/usr/bin/env bash
# waybar-net: prints tiny JSON for Waybar custom modules using daemon state
set -euo pipefail
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="$RUNTIME/waybar-net"

read_val() { [[ -r "$STATE_DIR/$1" ]] && cat "$STATE_DIR/$1" || echo ""; }

UNIT="$(read_val unit)"; CLASS="$(read_val class)"
UP="$(read_val up)";    DOWN="$(read_val down)"
if [[ -z "$UNIT" ]]; then UNIT="KB"; CLASS="network-kb"; UP="0"; DOWN="0"; fi

case "${1:-}" in
  unit) TEXT="$UNIT"; TIP="Unit: $UNIT/s" ;;
  up|upload) TEXT="$UP"; TIP="Upload: $UP $UNIT/s | Download: $DOWN $UNIT/s" ;;
  down|download) TEXT="$DOWN"; TIP="Download: $DOWN $UNIT/s | Upload: $UP $UNIT/s" ;;
  *) echo "{\"text\":\"--\",\"class\":\"$CLASS\",\"tooltip\":\"waybar-net <unit|up|down>\"}"; exit 0 ;;
esac

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$TEXT" "$CLASS" "$TIP"
