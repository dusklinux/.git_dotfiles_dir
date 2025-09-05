#!/usr/bin/env bash
# waybar-netd: ultra-light network speed daemon for Waybar
# Writes unit/class/upload/download into $XDG_RUNTIME_DIR/waybar-net/*
# - Unit is MB if max(up,down) >= 1 MiB/s else KB
# - Upload/Download are formatted to FIT <= 3 CHARS (including '.')

set -euo pipefail

RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="$RUNTIME/waybar-net"
mkdir -p "$STATE_DIR"

get_iface() {
  # Try: ip route get 1.1.1.1 -> dev IFACE
  local ifc
  ifc=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
  if [[ -z "${ifc:-}" ]]; then
    # Fallback to /proc/net/route default
    ifc=$(awk '$2=="00000000"{print $1; exit}' /proc/net/route 2>/dev/null)
  fi
  printf "%s" "${ifc:-}"
}

write_state() {
  local unit="$1" class="$2" up="$3" down="$4"
  printf "%s" "$unit"  > "$STATE_DIR/unit.tmp"  && mv -f "$STATE_DIR/unit.tmp"  "$STATE_DIR/unit"
  printf "%s" "$class" > "$STATE_DIR/class.tmp" && mv -f "$STATE_DIR/class.tmp" "$STATE_DIR/class"
  printf "%s" "$up"    > "$STATE_DIR/up.tmp"    && mv -f "$STATE_DIR/up.tmp"    "$STATE_DIR/up"
  printf "%s" "$down"  > "$STATE_DIR/down.tmp"  && mv -f "$STATE_DIR/down.tmp"  "$STATE_DIR/down"
}

iface=""
rx_prev=0 tx_prev=0

while :; do
  [[ -z "$iface" ]] && iface="$(get_iface)"
  if [[ -z "$iface" || ! -r /sys/class/net/$iface/statistics/rx_bytes ]]; then
    write_state "KB" "network-kb" "0" "0"
    sleep 1
    iface=""
    continue
  fi

  rx_now=$(< /sys/class/net/$iface/statistics/rx_bytes)
  tx_now=$(< /sys/class/net/$iface/statistics/tx_bytes)

  if [[ $rx_prev -eq 0 && $tx_prev -eq 0 ]]; then
    rx_prev=$rx_now; tx_prev=$tx_now; sleep 1; continue
  fi

  rx_delta=$(( rx_now - rx_prev ))
  tx_delta=$(( tx_now - tx_prev ))
  (( rx_delta < 0 )) && rx_delta=0
  (( tx_delta < 0 )) && tx_delta=0
  rx_prev=$rx_now
  tx_prev=$tx_now

  awk -v up_bps="$tx_delta" -v down_bps="$rx_delta" '
    function fmt_mb(bytes,   m) {
      m = bytes / 1048576.0
      if (m < 10)      return sprintf("%.1f", m)     # 0.0..9.9  (3 chars)
      else if (m < 1000) return sprintf("%.0f", m)   # 10..999   (<=3 chars)
      else             return "999"                  # clamp
    }
    function fmt_kb(bytes,   k) {
      k = bytes / 1024.0
      if (k >= 1000) return "999"                    # clamp
      return sprintf("%.0f", k)                      # 0..999
    }
    BEGIN {
      max = (up_bps > down_bps ? up_bps : down_bps)
      if (max >= 1048576) {
        unit="MB"; class="network-mb";
        up = fmt_mb(up_bps); down = fmt_mb(down_bps);
      } else {
        unit="KB"; class="network-kb";
        up = fmt_kb(up_bps); down = fmt_kb(down_bps);
      }
      print unit "\n" class "\n" up "\n" down
    }
  ' | {
    read -r UNIT
    read -r CLASS
    read -r UP
    read -r DOWN
    write_state "$UNIT" "$CLASS" "$UP" "$DOWN"
  }

  sleep 1
done
