#!/usr/bin/env bash
# waybar-netd: Signal-driven network speed daemon
set -euo pipefail

RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="$RUNTIME/waybar-net"
STATE_FILE="$STATE_DIR/state"
HEARTBEAT_FILE="$STATE_DIR/heartbeat"
mkdir -p "$STATE_DIR"

touch "$HEARTBEAT_FILE"
trap 'rm -rf "$STATE_DIR"' EXIT

# TRAP: Allow USR1 to interrupt sleep without crashing the script
trap ':' USR1

get_primary_iface() {
    (ip route get 1.1.1.1 2>/dev/null || true) | \
        awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}'
}

rx_prev=0
tx_prev=0
iface=""

while :; do
    # 1. WATCHDOG: Check if Waybar is active
    now=$(printf '%(%s)T' -1)
    if [[ -f "$HEARTBEAT_FILE" ]]; then
        last_heartbeat=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || echo 0)
    else
        last_heartbeat=0
    fi
    
    # If Waybar has been gone for >3 seconds, Deep Sleep (10 mins)
    if (( (now - last_heartbeat) > 3 )); then
        # We run sleep in background & wait so we can catch the wake-up signal
        sleep 600 &
        wait $! || true  # <--- CRITICAL FIX: '|| true' prevents crash on signal
        kill $! 2>/dev/null || true
        continue
    fi

    # 2. CHECK CONNECTION
    current_iface=$(get_primary_iface)

    # 3. DISCONNECTED STATE (Low Power)
    if [[ -z "$current_iface" ]]; then
        echo "- - - network-disconnected" > "$STATE_FILE.tmp"
        mv -f "$STATE_FILE.tmp" "$STATE_FILE"
        rx_prev=0; tx_prev=0
        
        # Sleep 3s, but allow wake-up signal
        sleep 3 &
        wait $! || true
        continue
    fi

    # 4. CONNECTED STATE
    start_time=$(date +%s%N)

    if [[ "$current_iface" != "$iface" ]]; then
        iface="$current_iface"
        rx_prev=0; tx_prev=0
    fi

    if [[ -r "/sys/class/net/$iface/statistics/rx_bytes" ]]; then
        read -r rx_now < "/sys/class/net/$iface/statistics/rx_bytes"
        read -r tx_now < "/sys/class/net/$iface/statistics/tx_bytes"
    else
        rx_now=0; tx_now=0
    fi

    if [[ $rx_prev -eq 0 && $tx_prev -eq 0 ]]; then
        rx_prev=$rx_now; tx_prev=$tx_now
        # Short sleep for init
        sleep 1 || true
        continue
    fi

    rx_delta=$(( rx_now - rx_prev ))
    tx_delta=$(( tx_now - tx_prev ))
    # Safety checks
    [[ $rx_delta -lt 0 ]] && rx_delta=0
    [[ $tx_delta -lt 0 ]] && tx_delta=0

    rx_prev=$rx_now
    tx_prev=$tx_now

    awk -v rx="$rx_delta" -v tx="$tx_delta" '
    function fmt(val, is_mb) {
        if (is_mb) {
            val = val / 1048576
            if (val < 10) return sprintf("%.1f", val)
            return sprintf("%.0f", val)
        } else {
            val = val / 1024
            return sprintf("%.0f", val)
        }
    }
    BEGIN {
        max = (rx > tx ? rx : tx)
        if (max >= 1048576) {
            printf "MB %s %s network-mb\n", fmt(tx, 1), fmt(rx, 1)
        } else {
            printf "KB %s %s network-kb\n", fmt(tx, 0), fmt(rx, 0)
        }
    }' > "$STATE_FILE.tmp"
    mv -f "$STATE_FILE.tmp" "$STATE_FILE"

    # 5. PRECISION SLEEP (Fixed Math)
    end_time=$(date +%s%N)
    elapsed_ms=$(( (end_time - start_time) / 1000000 ))
    sleep_ms=$(( 1000 - elapsed_ms ))

    # CRITICAL FIX: Handle cases where sleep_ms >= 1000 or <= 0
    if (( sleep_ms >= 1000 )); then
        sleep 1 || true
    elif (( sleep_ms > 0 )); then
        # Format explicitly to avoid "0.1000" bug
        sleep "0.$(printf "%03d" $sleep_ms)" || true
    fi
done
