#!/usr/bin/env bash
#===============================================================================
# network_meter_daemon.sh: Signal-driven network speed daemon for waybar-net
# Monitors network throughput and writes stats for waybar-net client
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
readonly RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
readonly STATE_DIR="${RUNTIME}/waybar-net"
readonly STATE_FILE="${STATE_DIR}/state"
readonly STATE_TMP="${STATE_FILE}.tmp"
readonly HEARTBEAT_FILE="${STATE_DIR}/heartbeat"
readonly PIDFILE="${STATE_DIR}/daemon.pid"

readonly IDLE_TIMEOUT=3      # Seconds without heartbeat before idling
readonly IDLE_SLEEP=60       # Seconds to sleep when idle
readonly UPDATE_INTERVAL=1   # Target update interval in seconds

#-------------------------------------------------------------------------------
# Initialization
#-------------------------------------------------------------------------------
mkdir -p "$STATE_DIR"
printf '%d\n' "$$" > "$PIDFILE"
touch "$HEARTBEAT_FILE"

#-------------------------------------------------------------------------------
# Cleanup
#-------------------------------------------------------------------------------
cleanup() {
    rm -f "$PIDFILE" "$STATE_FILE" "$STATE_TMP" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

#-------------------------------------------------------------------------------
# Signal Handler: No-op to interrupt sleep/wait
#-------------------------------------------------------------------------------
trap ':' USR1

#-------------------------------------------------------------------------------
# Functions
#-------------------------------------------------------------------------------
get_primary_iface() {
    # Get interface used for default route
    # Wrapped to prevent exit on network unreachable
    { ip route get 1.1.1.1 2>/dev/null || true; } \
        | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}'
}

get_current_time() {
    # Use bash built-in (4.2+) for efficiency
    printf '%(%s)T' -1
}

write_state() {
    # Atomic write: write to temp, then rename
    printf '%s\n' "$1" > "$STATE_TMP"
    mv -f "$STATE_TMP" "$STATE_FILE"
}

#-------------------------------------------------------------------------------
# State Variables
#-------------------------------------------------------------------------------
rx_prev=0
tx_prev=0
iface=""
waking_from_idle=0

#-------------------------------------------------------------------------------
# Main Loop
#-------------------------------------------------------------------------------
while :; do
    #---------------------------------------------------------------------------
    # Idle Detection: Sleep when Waybar isn't polling
    #---------------------------------------------------------------------------
    now=$(get_current_time)
    
    if [[ -f "$HEARTBEAT_FILE" ]]; then
        last_heartbeat=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null) || last_heartbeat=0
    else
        last_heartbeat=0
    fi
    
    idle_duration=$((now - last_heartbeat))
    
    if ((idle_duration > IDLE_TIMEOUT)); then
        # Enter idle mode: background sleep, interruptible by USR1
        sleep "$IDLE_SLEEP" &
        sleep_pid=$!
        wait "$sleep_pid" 2>/dev/null || true
        kill "$sleep_pid" 2>/dev/null || true
        
        # Mark that we need to reset counters to avoid data spike
        waking_from_idle=1
        continue
    fi
    
    #---------------------------------------------------------------------------
    # Reset After Idle: Prevents massive spike from accumulated bytes
    #---------------------------------------------------------------------------
    if ((waking_from_idle)); then
        rx_prev=0
        tx_prev=0
        waking_from_idle=0
    fi
    
    #---------------------------------------------------------------------------
    # Timing for Precision Sleep
    #---------------------------------------------------------------------------
    start_ns=$(date +%s%N)
    
    #---------------------------------------------------------------------------
    # Get Network Interface
    #---------------------------------------------------------------------------
    current_iface=$(get_primary_iface)
    
    # Handle no network connection
    if [[ -z "$current_iface" ]]; then
        write_state "KB 0 0 network-kb"
        rx_prev=0
        tx_prev=0
        sleep "$UPDATE_INTERVAL"
        continue
    fi
    
    # Handle interface change (e.g., WiFi to Ethernet)
    if [[ "$current_iface" != "$iface" ]]; then
        iface="$current_iface"
        rx_prev=0
        tx_prev=0
    fi
    
    #---------------------------------------------------------------------------
    # Read Network Statistics
    #---------------------------------------------------------------------------
    rx_file="/sys/class/net/${iface}/statistics/rx_bytes"
    tx_file="/sys/class/net/${iface}/statistics/tx_bytes"
    
    if [[ -r "$rx_file" ]] && [[ -r "$tx_file" ]]; then
        read -r rx_now < "$rx_file" || rx_now=0
        read -r tx_now < "$tx_file" || tx_now=0
    else
        rx_now=0
        tx_now=0
    fi
    
    #---------------------------------------------------------------------------
    # First Run: Initialize Baseline
    #---------------------------------------------------------------------------
    if ((rx_prev == 0 && tx_prev == 0)); then
        rx_prev=$rx_now
        tx_prev=$tx_now
        sleep "$UPDATE_INTERVAL"
        continue
    fi
    
    #---------------------------------------------------------------------------
    # Calculate Deltas (bytes per second)
    #---------------------------------------------------------------------------
    rx_delta=$((rx_now - rx_prev))
    tx_delta=$((tx_now - tx_prev))
    
    # Handle counter wrap (rare, but possible on 32-bit systems)
    if ((rx_delta < 0)); then
        rx_delta=0
    fi
    if ((tx_delta < 0)); then
        tx_delta=0
    fi
    
    rx_prev=$rx_now
    tx_prev=$tx_now
    
    #---------------------------------------------------------------------------
    # Format Output: Auto-switch between KB and MB
    #---------------------------------------------------------------------------
    awk -v rx="$rx_delta" -v tx="$tx_delta" '
    BEGIN {
        max = (rx > tx) ? rx : tx
        
        if (max >= 1048576) {
            # MB mode
            unit = "MB"
            cls = "network-mb"
            rxv = rx / 1048576
            txv = tx / 1048576
            # One decimal for < 10, integer for >= 10
            rx_str = (rxv < 10) ? sprintf("%.1f", rxv) : sprintf("%.0f", rxv)
            tx_str = (txv < 10) ? sprintf("%.1f", txv) : sprintf("%.0f", txv)
        } else {
            # KB mode
            unit = "KB"
            cls = "network-kb"
            rx_str = sprintf("%.0f", rx / 1024)
            tx_str = sprintf("%.0f", tx / 1024)
        }
        
        # Output format: UNIT UP DOWN CLASS
        printf "%s %s %s %s\n", unit, tx_str, rx_str, cls
    }' > "$STATE_TMP"
    
    mv -f "$STATE_TMP" "$STATE_FILE"
    
    #---------------------------------------------------------------------------
    # Precision Sleep: Maintain Consistent 1-Second Intervals
    #---------------------------------------------------------------------------
    end_ns=$(date +%s%N)
    elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
    sleep_ms=$((1000 - elapsed_ms))
    
    if ((sleep_ms >= 1000)); then
        # Edge case: loop was instant (shouldn't happen normally)
        sleep 1
    elif ((sleep_ms > 10)); then
        # Normal case: sleep remaining time
        # Format milliseconds as decimal seconds (e.g., 500 -> 0.500)
        printf -v sleep_time '0.%03d' "$sleep_ms"
        sleep "$sleep_time"
    fi
    # If sleep_ms <= 10, skip sleep (we're already behind)
done
