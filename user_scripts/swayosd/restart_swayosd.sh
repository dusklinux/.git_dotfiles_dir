#!/usr/bin/env bash

# ----------------------------------------------------------------
# SWAYOSD ROBUST RESTART SCRIPT (UWSM COMPLIANT)
# ----------------------------------------------------------------

SERVER_BIN="/usr/bin/swayosd-server"

# 1. SAFE SHUTDOWN
if pgrep -x "swayosd-server" > /dev/null; then
    pkill -x "swayosd-server"

    # Atomic wait loop
    for i in {1..20}; do
        if ! pgrep -x "swayosd-server" > /dev/null; then
            break
        fi
        sleep 0.1
    done

    # Force kill safety net
    if pgrep -x "swayosd-server" > /dev/null; then
        pkill -9 -x "swayosd-server"
    fi
fi

# 2. CLEAN STARTUP (UWSM / SYSTEMD DETACHMENT)
# We prioritize 'uwsm app' for full session compliance.
# If not found, we fall back to 'systemd-run' (generic systemd).
# Finally, 'setsid' for legacy non-systemd systems.

UNIT_NAME="swayosd-server-$(date +%s)"

if command -v uwsm &> /dev/null; then
    # --- UWSM NATIVE METHOD ---
    # Wraps the process in a scope managed by the active UWSM session.
    # This ensures correct lifecycle management (cleanup on logout).
    uwsm app -- "$SERVER_BIN" >/dev/null 2>&1 &

elif command -v systemd-run &> /dev/null; then
    # --- SYSTEMD GENERIC METHOD ---
    # Creates a transient scope under the user manager.
    systemd-run --user --scope --unit="$UNIT_NAME" -- "$SERVER_BIN" >/dev/null 2>&1 &
else
    # --- LEGACY FALLBACK ---
    setsid "$SERVER_BIN" >/dev/null 2>&1 &
fi

# 3. VERIFICATION
sleep 0.2
if pgrep -x "swayosd-server" > /dev/null; then
    echo "Success: SwayOSD server restarted."
else
    echo "Error: SwayOSD server failed to start."
    exit 1
fi
