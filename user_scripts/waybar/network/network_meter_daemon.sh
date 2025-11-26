#!/usr/bin/env bash
# waybar-netd: Signal-driven network speed daemon
set -euo pipefail

RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="$RUNTIME/waybar-net"
STATE_FILE="$STATE_DIR/state"
HEARTBEAT_FILE="$STATE_DIR/heartbeat"
mkdir -p "$STATE_DIR"

# Initialize heartbeat
touch "$HEARTBEAT_FILE"

# Cleanup on exit
trap 'rm -rf "$STATE_DIR"' EXIT

# SIGNAL TRAP: Use no-op. 
# This interrupts 'wait', allowing the loop to continue.
trap ':' USR1

get_primary_iface() {
    # FIX: ( ... || true ) prevents the script from crashing if network is unreachable
    (ip route get 1.1.1.1 2>/dev/null || true) | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}'
}

rx_prev=0
tx_prev=0
iface=""

while :; do
    # --- OPTIMIZED WATCHDOG ---
    now=$(printf '%(%s)T' -1)
    
    if [[ -f "$HEARTBEAT_FILE" ]]; then
        last_heartbeat=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || echo 0)
    else
        last_heartbeat=0
    fi
    
    diff=$(( now - last_heartbeat ))

    # If Waybar hasn't touched the file in 3 seconds:
    if (( diff > 3 )); then
        # Sleep for 60 seconds (background)
        sleep 600 &
        sleep_pid=$!
        
        # Wait blocks until sleep finishes OR signal USR1 arrives.
        # If signal arrives, wait returns >128. We catch that with || true
        wait $sleep_pid || true
        
        # If we woke up early due to signal, kill the sleep process
        kill $sleep_pid 2>/dev/null || true
        
        # Restart loop immediately to process data
        continue
    fi
    # ----------------

    start_time=$(date +%s%N)
    current_iface=$(get_primary_iface)
    
    # Graceful handling if no interface found (e.g. network down)
    if [[ -z "$current_iface" ]]; then
        # Write safe zeros
        echo "KB 0 0 network-kb" > "$STATE_FILE.tmp"
        mv -f "$STATE_FILE.tmp" "$STATE_FILE"
        rx_prev=0; tx_prev=0
        sleep 1
        continue
    fi

    # Interface switching logic
    if [[ "$current_iface" != "$iface" ]]; then
        iface="$current_iface"
        rx_prev=0; tx_prev=0
    fi

    # Read stats safely
    if [[ -r "/sys/class/net/$iface/statistics/rx_bytes" ]]; then
        read -r rx_now < "/sys/class/net/$iface/statistics/rx_bytes"
        read -r tx_now < "/sys/class/net/$iface/statistics/tx_bytes"
    else
        rx_now=0; tx_now=0
    fi

    # Handle first run (prev=0) to avoid spikes
    if [[ $rx_prev -eq 0 && $tx_prev -eq 0 ]]; then
        rx_prev=$rx_now
        tx_prev=$tx_now
        sleep 1
        continue
    fi

    rx_delta=$(( rx_now - rx_prev ))
    tx_delta=$(( tx_now - tx_prev ))
    (( rx_delta < 0 )) && rx_delta=0
    (( tx_delta < 0 )) && tx_delta=0

    rx_prev=$rx_now
    tx_prev=$tx_now

    # Math and formatting (MB/KB switching)
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

    mv -f "$STATE_FILE.tmp" "$STATE_FILE"

    # Precision sleep
    end_time=$(date +%s%N)
    elapsed=$(( (end_time - start_time) / 1000000 ))
    sleep_sec=$(( 1000 - elapsed ))
    if (( sleep_sec > 0 )); then
        sleep "0.$(printf "%03d" $sleep_sec)"
    fi
done
