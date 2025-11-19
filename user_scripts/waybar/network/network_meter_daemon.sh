#!/usr/bin/env bash
# waybar-netd: Optimized network speed daemon
# Writes a single atomic state line: "UNIT UP DOWN CLASS"

set -euo pipefail

# Store in RAM (tmpfs) for speed and to save SSD wear
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="$RUNTIME/waybar-net"
STATE_FILE="$STATE_DIR/state"
mkdir -p "$STATE_DIR"

# Cleanup on exit
trap 'rm -rf "$STATE_DIR"' EXIT

get_primary_iface() {
    # reliable way to get the interface currently routing internet traffic
    ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}'
}

# Initialize
rx_prev=0
tx_prev=0
iface=""

while :; do
    start_time=$(date +%s%N)

    # Dynamically find interface (self-healing)
    current_iface=$(get_primary_iface)
    
    # Handle no network case
    if [[ -z "$current_iface" ]]; then
        # Atomic write: UNIT UP DOWN CLASS
        printf "KB 0 0 network-kb\n" > "$STATE_FILE.tmp"
        mv -f "$STATE_FILE.tmp" "$STATE_FILE"
        rx_prev=0; tx_prev=0
        sleep 1
        continue
    fi

    # Check if interface changed, reset counters to avoid huge spikes
    if [[ "$current_iface" != "$iface" ]]; then
        iface="$current_iface"
        rx_prev=0; tx_prev=0
    fi

    # Read statistics using pure bash (faster than cat)
    # Check if file exists to avoid crash on disconnect
    if [[ -r "/sys/class/net/$iface/statistics/rx_bytes" ]]; then
        read -r rx_now < "/sys/class/net/$iface/statistics/rx_bytes"
        read -r tx_now < "/sys/class/net/$iface/statistics/tx_bytes"
    else
        rx_now=0; tx_now=0
    fi

    # Initialize on first run
    if [[ $rx_prev -eq 0 && $tx_prev -eq 0 ]]; then
        rx_prev=$rx_now
        tx_prev=$tx_now
        sleep 1
        continue
    fi

    # Calculate Deltas
    rx_delta=$(( rx_now - rx_prev ))
    tx_delta=$(( tx_now - tx_prev ))
    
    # Handle counter overflow/reset
    (( rx_delta < 0 )) && rx_delta=0
    (( tx_delta < 0 )) && tx_delta=0

    rx_prev=$rx_now
    tx_prev=$tx_now

    # Formatting Logic (Embedded AWK for precise float handling)
    # Calculates both display values and determines the unit
    awk -v rx="$rx_delta" -v tx="$tx_delta" '
    function fmt(val, is_mb) {
        if (is_mb) {
            val = val / 1048576
            if (val < 10) return sprintf("%.1f", val)  # 1.5
            if (val < 999) return sprintf("%.0f", val)  # 150
            return "999"
        } else {
            val = val / 1024
            if (val < 999) return sprintf("%.0f", val)
            return "999"
        }
    }
    BEGIN {
        max = (rx > tx ? rx : tx)
        if (max >= 1048576) { # 1 MB
            unit="MB"
            cls="network-mb"
            up_str=fmt(tx, 1)
            down_str=fmt(rx, 1)
        } else {
            unit="KB"
            cls="network-kb"
            up_str=fmt(tx, 0)
            down_str=fmt(rx, 0)
        }
        printf "%s %s %s %s\n", unit, up_str, down_str, cls
    }' > "$STATE_FILE.tmp"

    # Atomic Move
    mv -f "$STATE_FILE.tmp" "$STATE_FILE"

    # Precise Sleep: Compensate for calculation time
    end_time=$(date +%s%N)
    elapsed=$(( (end_time - start_time) / 1000000 )) # ms
    sleep_sec=$(( 1000 - elapsed ))
    
    if (( sleep_sec > 0 )); then
        # sleep takes seconds, convert ms to s
        sleep "0.$(printf "%03d" $sleep_sec)"
    fi
done
