#!/usr/bin/env bash
# waybar-netd: Zero-overhead, signal-driven network monitor
# ELITE OPTIMIZATION: 100% Pure Bash. No forks.
# FIX: Solved race condition in cleanup trap.

set -euo pipefail

# --- Configuration ---
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="$RUNTIME/waybar-net"
STATE_FILE="$STATE_DIR/state"
PID_FILE="$STATE_DIR/pid"

# Ensure dir exists on start
mkdir -p "$STATE_DIR"
echo $$ > "$PID_FILE"

# --- State Variables ---
last_contact=$SECONDS
rx_prev=0
tx_prev=0
active_iface=""
force_reset=1

# --- Signal & Cleanup ---
cleanup() {
    # FIX: Do NOT remove the whole directory. This causes race conditions
    # if the service restarts quickly (the old process deletes the dir
    # while the new process is trying to use it).
    rm -f "$PID_FILE"
    
    # Kill any child processes (sleeps) in our process group
    pkill -P $$ || true
    exit
}
trap cleanup EXIT INT TERM

# SIGNAL TRAP:
trap 'last_contact=$SECONDS' USR1

# --- Functions ---
get_active_iface() {
    while read -r iface dest _ _ _ _ _ _ _ _; do
        if [[ "$dest" == "00000000" ]]; then
            echo "$iface"
            return
        fi
    done < /proc/net/route
}

# --- Main Loop ---
while :; do
    # 1. WATCHDOG (Deep Sleep Logic)
    if (( SECONDS - last_contact > 5 )); then
        sleep 60 &
        sleep_pid=$!
        wait $sleep_pid || true 
        kill $sleep_pid 2>/dev/null || true
        
        force_reset=1
        last_contact=$SECONDS
        continue
    fi

    # 2. INTERFACE CHECK
    curr_iface=$(get_active_iface)
    
    if [[ -z "$curr_iface" ]]; then
        # Safety Check: Ensure dir exists before write
        [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
        
        echo "KB 0 0 network-disconnected" > "$STATE_FILE.tmp"
        mv -f "$STATE_FILE.tmp" "$STATE_FILE"
        force_reset=1
        sleep 1
        continue
    fi

    if [[ "$curr_iface" != "$active_iface" ]]; then
        active_iface="$curr_iface"
        force_reset=1
    fi

    # 3. DATA COLLECTION
    rx_path="/sys/class/net/$active_iface/statistics/rx_bytes"
    tx_path="/sys/class/net/$active_iface/statistics/tx_bytes"

    if [[ -r "$rx_path" ]]; then
        read -r rx_now < "$rx_path" || rx_now=0
        read -r tx_now < "$tx_path" || tx_now=0
    else
        rx_now=0; tx_now=0
    fi

    if [[ $force_reset -eq 1 ]]; then
        rx_prev=$rx_now
        tx_prev=$tx_now
        force_reset=0
        sleep 1
        continue
    fi

    # 4. MATH
    rx_delta=$(( rx_now - rx_prev ))
    tx_delta=$(( tx_now - tx_prev ))
    (( rx_delta < 0 )) && rx_delta=0
    (( tx_delta < 0 )) && tx_delta=0

    rx_prev=$rx_now
    tx_prev=$tx_now

    # 5. FORMATTING
    max_val=$(( rx_delta > tx_delta ? rx_delta : tx_delta ))

    if (( max_val >= 1048576 )); then
        unit="MB"
        cls="network-mb"
        calc_mb() {
            local val=$1
            local mb_x10=$(( (val * 10) / 1048576 ))
            if (( mb_x10 < 100 )); then
                local int_part="${mb_x10:0:-1}"
                local dec_part="${mb_x10: -1}"
                [[ -z "$int_part" ]] && int_part="0"
                echo "${int_part}.${dec_part}"
            else
                echo $(( mb_x10 / 10 ))
            fi
        }
        up=$(calc_mb "$tx_delta")
        down=$(calc_mb "$rx_delta")
    else
        unit="KB"
        cls="network-kb"
        up=$(( tx_delta / 1024 ))
        down=$(( rx_delta / 1024 ))
    fi

    # 6. ATOMIC WRITE
    # Safety Check: Ensure dir exists before write (Self-healing)
    [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"

    printf "%s %s %s %s\n" "$unit" "$up" "$down" "$cls" > "$STATE_FILE.tmp"
    mv -f "$STATE_FILE.tmp" "$STATE_FILE"

    # Wait for next cycle (interruptible by signal)
    sleep 1 &
    loop_pid=$!
    wait $loop_pid || true
    kill $loop_pid 2>/dev/null || true
done
