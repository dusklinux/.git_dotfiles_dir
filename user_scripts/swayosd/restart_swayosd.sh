#!/usr/bin/env bash

# ================================================================
# SWAYOSD ROBUST RESTART SCRIPT (UWSM COMPLIANT)
# ================================================================
# Safely restarts swayosd-server with proper process management
# Priority: uwsm-app → systemd-run → setsid (fallback)
# ================================================================

set -euo pipefail

# ─────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────

readonly SERVER_BIN="/usr/bin/swayosd-server"
readonly PROCESS_NAME="swayosd-server"
readonly SHUTDOWN_ATTEMPTS=20
readonly SHUTDOWN_INTERVAL=0.1
readonly STARTUP_DELAY=0.5

# ─────────────────────────────────────────────────────────────────
# HELPER FUNCTIONS
# ─────────────────────────────────────────────────────────────────

is_running() {
    pgrep -x "$PROCESS_NAME" >/dev/null 2>&1
}

log_error() {
    printf 'Error: %s\n' "$*" >&2
}

log_success() {
    printf 'Success: %s\n' "$*"
}

# ─────────────────────────────────────────────────────────────────
# VALIDATION
# ─────────────────────────────────────────────────────────────────

if [[ ! -x "$SERVER_BIN" ]]; then
    log_error "Server binary not found or not executable: $SERVER_BIN"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────
# PHASE 1: SAFE SHUTDOWN
# ─────────────────────────────────────────────────────────────────

if is_running; then
    # Graceful shutdown (SIGTERM)
    pkill -x "$PROCESS_NAME" 2>/dev/null || true

    # Wait for process to terminate
    for ((_i = 0; _i < SHUTDOWN_ATTEMPTS; _i++)); do
        is_running || break
        sleep "$SHUTDOWN_INTERVAL"
    done

    # Force kill if still running (SIGKILL)
    if is_running; then
        pkill -9 -x "$PROCESS_NAME" 2>/dev/null || true
        sleep 0.1
    fi

    # Verify termination succeeded
    if is_running; then
        log_error "Failed to terminate existing $PROCESS_NAME process"
        exit 1
    fi
fi

# ─────────────────────────────────────────────────────────────────
# PHASE 2: CLEAN STARTUP
# ─────────────────────────────────────────────────────────────────

if command -v uwsm-app >/dev/null 2>&1; then
    # UWSM native: wraps process in active UWSM session scope
    uwsm-app -- "$SERVER_BIN" >/dev/null 2>&1 &

elif command -v systemd-run >/dev/null 2>&1; then
    # Systemd: transient scope under user session
    # Include PID + timestamp to guarantee uniqueness
    unit_name="swayosd-$$-$(date +%s)"
    systemd-run --user --scope --unit="$unit_name" \
        -- "$SERVER_BIN" >/dev/null 2>&1 &

else
    # Legacy fallback: create new session for full detachment
    setsid "$SERVER_BIN" >/dev/null 2>&1 &
fi

# Detach background job from shell job table
disown 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────
# PHASE 3: VERIFICATION
# ─────────────────────────────────────────────────────────────────

sleep "$STARTUP_DELAY"

if is_running; then
    log_success "SwayOSD server restarted"
    exit 0
else
    log_error "SwayOSD server failed to start"
    exit 1
fi
