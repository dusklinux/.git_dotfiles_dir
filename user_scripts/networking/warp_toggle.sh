#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: warp-toggle.sh
# Description: Robust toggle for Cloudflare WARP with UWSM/Hyprland notifications.
# Author: Elite DevOps
# Environment: Arch Linux / Hyprland / UWSM
# Dependencies: warp-cli, libnotify (notify-send)
# -----------------------------------------------------------------------------

# --- Strict Mode & Safety ---
set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
readonly APP_NAME="Cloudflare WARP"
readonly TIMEOUT_SEC=10
readonly ICON_CONN="network-vpn"
readonly ICON_DISC="network-offline"
readonly ICON_WAIT="network-transmit-receive"
readonly ICON_ERR="dialog-error"

# --- Styling (ANSI Colors with TTY detection) ---
if [[ -t 1 ]]; then
    readonly C_RESET=$'\033[0m'
    readonly C_BOLD=$'\033[1m'
    readonly C_GREEN=$'\033[1;32m'
    readonly C_BLUE=$'\033[1;34m'
    readonly C_RED=$'\033[1;31m'
    readonly C_YELLOW=$'\033[1;33m'
else
    readonly C_RESET='' C_BOLD='' C_GREEN='' C_BLUE='' C_RED='' C_YELLOW=''
fi

# --- Logging Functions ---

log_info() {
    printf "%s[INFO]%s %s\n" "$C_BLUE" "$C_RESET" "$1"
}

log_success() {
    printf "%s[OK]%s   %s\n" "$C_GREEN" "$C_RESET" "$1"
}

log_warn() {
    printf "%s[WARN]%s %s\n" "$C_YELLOW" "$C_RESET" "$1" >&2
}

log_error() {
    printf "%s[ERR]%s  %s\n" "$C_RED" "$C_RESET" "$1" >&2
}

# --- Notification Helper ---
# Checks for notify-send existence to avoid errors in headless environments
notify_user() {
    local title="$1"
    local message="$2"
    local urgency="${3:-low}" # low, normal, critical
    local icon="${4:-$ICON_WAIT}"
    
    if command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" -a "$APP_NAME" -i "$icon" "$title" "$message"
    fi
}

# --- Core Logic ---

get_warp_status() {
    # 1. Run status
    # 2. Filter for "Status update" line
    # 3. Use awk sub() to trim leading/trailing whitespace specifically
    local output
    output=$(warp-cli status 2>/dev/null) || return 1
    
    awk -F': ' '/Status update/ {
        val = $2
        sub(/^[ \t]+/, "", val) # Trim leading
        sub(/[ \t]+$/, "", val) # Trim trailing
        print val
    }' <<< "$output"
}

wait_for_connection() {
    local timer=0
    
    log_info "Initiating connection sequence..."
    notify_user "Connecting..." "Establishing secure tunnel." "normal" "$ICON_WAIT"

    # Send connect command quietly
    if ! warp-cli connect &>/dev/null; then
        log_error "Failed to send connect command."
        notify_user "Error" "Failed to send connect command." "critical" "$ICON_ERR"
        return 1
    fi

    # Loop with safe arithmetic
    while (( timer < TIMEOUT_SEC )); do
        local current_state
        current_state=$(get_warp_status) || current_state="Unknown"

        if [[ "$current_state" == "Connected" ]]; then
            log_success "WARP is now Connected."
            notify_user "Connected" "Secure tunnel active." "normal" "$ICON_CONN"
            return 0
        fi

        sleep 1
        (( timer++ )) || true # Prevent 'set -e' exit on 0 start or intermediate values
    done

    # Timeout reached
    log_error "Connection timed out after ${TIMEOUT_SEC}s."
    notify_user "Timeout" "Failed to connect within ${TIMEOUT_SEC} seconds." "critical" "$ICON_ERR"
    return 1
}

disconnect_warp() {
    log_info "Disconnecting..."
    
    if warp-cli disconnect &>/dev/null; then
        log_success "Disconnected successfully."
        notify_user "Disconnected" "Secure tunnel closed." "low" "$ICON_DISC"
    else
        log_error "Failed to disconnect."
        notify_user "Error" "Failed to disconnect WARP." "critical" "$ICON_ERR"
        return 1
    fi
}

main() {
    # Dependency Check
    if ! command -v warp-cli &>/dev/null; then
        log_error "warp-cli not found. Please install 'cloudflare-warp-bin'."
        exit 1
    fi

    # Get Status
    local status
    status=$(get_warp_status) || status="Unknown"

    log_info "Current Status: ${C_BOLD}${status}${C_RESET}"

    # Logic Switch
    case "$status" in
        "Connected"|"Connecting")
            disconnect_warp
            ;;
        "Disconnected")
            wait_for_connection
            ;;
        *)
            log_warn "Unknown status detected: '$status'. Attempting to connect."
            wait_for_connection
            ;;
    esac
}

main "$@"
