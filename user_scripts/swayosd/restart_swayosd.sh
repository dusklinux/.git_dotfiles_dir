#!/usr/bin/env bash

# ----------------------------------------------------------------
# SWAYOSD ROBUST RESTART SCRIPT
# ----------------------------------------------------------------

SERVER_BIN="/usr/bin/swayosd-server"

# 1. SAFE SHUTDOWN
# Check if the server is running specifically (ignoring the backend).
if pgrep -x "swayosd-server" > /dev/null; then
    # Send SIGTERM (polite kill signal)
    pkill -x "swayosd-server"

    # 2. ATOMIC WAIT LOOP (The Critical Fix)
    # We must wait for the process to actually release the Wayland socket.
    # We check every 0.1s, up to 2 seconds.
    for i in {1..20}; do
        if ! pgrep -x "swayosd-server" > /dev/null; then
            break
        fi
        sleep 0.1
    done

    # 3. FORCE KILL SAFETY NET
    # If it is STILL alive after 2 seconds, force kill it (-9).
    if pgrep -x "swayosd-server" > /dev/null; then
        pkill -9 -x "swayosd-server"
    fi
fi

# 4. CLEAN STARTUP
# We use 'setsid' to create a new session. This is superior to 'nohup' &
# because it completely detaches the process tree from this script.
# If this script is killed, swayosd will survive.
setsid "$SERVER_BIN" >/dev/null 2>&1 &

# 5. VERIFICATION
# Wait a split second to ensure it launched successfully.
sleep 0.2
if pgrep -x "swayosd-server" > /dev/null; then
    echo "Success: SwayOSD server restarted."
else
    echo "Error: SwayOSD server failed to start."
    exit 1
fi
