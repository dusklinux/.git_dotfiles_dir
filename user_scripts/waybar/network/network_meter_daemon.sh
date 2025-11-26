#!/usr/bin/env bash
# waybar-netd: Zero-overhead, signal-driven network monitor
# OPTIMIZATION: Uses pure bash builtins to avoid spawning processes.

set -euo pipefail

# --- Configuration ---
# Use numeric ID for runtime dir to be safe
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="$RUNTIME/waybar-net"
STATE_FILE="$STATE_DIR/state"
HEARTBEAT_FILE="$STATE_DIR/heartbeat"
PID_FILE="$STATE_DIR/pid"

mkdir -p "$STATE_DIR"

# Write PID for fast signaling (Avoiding 'pkill' overhead)
echo $$ > "$PID_FILE"

# Cleanup on exit
cleanup() {
    rm -rf "$STATE_DIR"
    exit
}
trap cleanup EXIT INT TERM

# SIGNAL TRAP:
# This is the "Wake Up" switch. It interrupts the 'wait' command.
trap ':' USR1

# Create heartbeat initially
touch "$HEARTBEAT_FILE"

# --- Pure Bash Functions (No Forks) ---

get_active_iface() {
    # Reads /proc/net/route directly. 
    # Field 2 is destination. 00000000 is default gateway. Field 1 is Iface.
    while read -r iface dest _ _ _ _ _ _ _ _; do
        if [[ "$dest" == "00000000" ]]; then
            echo "$iface"
            return
        fi
    done < /proc/net/route
}

# --- Main Loop ---

rx_prev=0
tx_prev=0
active_iface=""
force_reset=1

while :; do
    # 1. WATCHDOG (The Sleep Logic)
    # Get current time (Bash 4.2+ builtin, no 'date' command needed)
    printf -v now '%(%s)T' -1
    
    # Check file age. 'stat' is the only necessary external call here.
    if [[ -f "$HEARTBEAT_FILE" ]]; then
        last_heartbeat=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null || echo 0)
    else
        last_heartbeat=0
    fi
    
    # Calculate silence duration
    diff=$(( now - last_heartbeat ))

    # If Waybar hasn't asked for data in 5 seconds...
    if (( diff > 5 )); then
        # 1. Enter Low Power Mode
        # We start a background sleep and wait for it.
        # This allows the shell to be completely idle (0% CPU) until:
        # A) 60 seconds pass
        # B) A SIGUSR1 signal kills the 'wait'
        
        sleep 60 &
        sleep_pid=$!
        wait $sleep_pid || true # 'wait' returns exit code >128 on signal
        
        # Kill the sleep process if we woke up early
        kill $sleep_pid 2>/dev/null || true
        
        # 2. Wake Up Routine
        # Force a counter reset so we don't calculate a huge delta from the sleep time
        force_reset=1
        continue
    fi

    # 2. INTERFACE & DATA COLLECTION
    curr_iface=$(get_active_iface)
    
    # Edge Case: No Network
    if [[ -z "$curr_iface" ]]; then
        # Atomic write to avoid partial reads
        echo "KB 0 0 network-disconnected" > "$STATE_FILE.tmp"
        mv -f "$STATE_FILE.tmp" "$STATE_FILE"
        force_reset=1
        sleep 1
        continue
    fi

    # Edge Case: Interface Switched (WiFi -> Ethernet)
    if [[ "$curr_iface" != "$active_iface" ]]; then
        active_iface="$curr_iface"
        force_reset=1
    fi

    # Read Bytes (Pure Bash File IO)
    rx_path="/sys/class/net/$active_iface/statistics/rx_bytes"
    tx_path="/sys/class/net/$active_iface/statistics/tx_bytes"

    if [[ -r "$rx_path" ]]; then
        read -r rx_now < "$rx_path" || rx_now=0
        read -r tx_now < "$tx_path" || tx_now=0
    else
        rx_now=0; tx_now=0
    fi

    # 3. SPIKE PREVENTION
    if [[ $force_reset -eq 1 ]]; then
        rx_prev=$rx_now
        tx_prev=$tx_now
        force_reset=0
        # Wait 1s to establish a baseline speed
        sleep 1
        continue
    fi

    # 4. MATH (Pure Bash Integer Math)
    rx_delta=$(( rx_now - rx_prev ))
    tx_delta=$(( tx_now - tx_prev ))
    
    # Handle Counter Rollover
    (( rx_delta < 0 )) && rx_delta=0
    (( tx_delta < 0 )) && tx_delta=0

    rx_prev=$rx_now
    tx_prev=$tx_now

    # 5. FORMATTING (Awk)
    # This is the only "heavy" lift, optimized for the 3-digit constraint.
    awk -v rx="$rx_delta" -v tx="$tx_delta" '
    function human(val) {
        # Logic: 
        # If < 999.5 KB -> Show KB (Integer)
        # If >= 999.5 KB -> Show MB
        
        val_kb = val / 1024
        
        if (val_kb < 999.5) {
            # Return integer KB (e.g., "999", "50", "0")
            return sprintf("%.0f", val_kb)
        } else {
            val_mb = val_kb / 1024
            # If 1.0 - 9.9 MB -> Show 1 decimal (e.g., "1.1", "5.5")
            if (val_mb < 9.95) {
                return sprintf("%.1f", val_mb)
            }
            # If >= 10 MB -> Show Integer (e.g., "10", "100")
            return sprintf("%.0f", val_mb)
        }
    }
    
    BEGIN {
        # Determine Unit based on MAX speed (keep Up/Down consistent)
        max = (rx > tx ? rx : tx)
        
        # 1023488 bytes is approx 999.5 KB
        if (max >= 1023488) {
            unit="MB"
            cls="network-mb"
        } else {
            unit="KB"
            cls="network-kb"
        }

        # Format values
        up = human(tx)
        down = human(rx)

        # Output
        printf "%s %s %s %s\n", unit, up, down, cls
    }' > "$STATE_FILE.tmp"

    mv -f "$STATE_FILE.tmp" "$STATE_FILE"

    sleep 1
done
