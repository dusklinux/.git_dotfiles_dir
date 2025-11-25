#!/bin/bash
#
# USB Sound Notification Script
# Plays audio feedback when USB devices are connected/disconnected
#
# Usage: usb-sound.sh <connect|disconnect>
#
# Typical udev rule:
#   ACTION=="add", SUBSYSTEM=="usb", RUN+="/usr/local/bin/usb-sound.sh connect"
#   ACTION=="remove", SUBSYSTEM=="usb", RUN+="/usr/local/bin/usb-sound.sh disconnect"
#
# View logs: journalctl -t usb-sound
#

# --- STRICT MODE (partial - we handle errors manually for udev compatibility) ---
set -o pipefail

# --- CONFIGURATION ---
export PATH="/usr/bin:/usr/local/bin:/bin:/sbin:/usr/sbin"

readonly SCRIPT_NAME="${0##*/}"
readonly LOG_TAG="usb-sound"

# Sound files (primary and fallback)
readonly SOUND_CONNECT_PRIMARY="/usr/share/sounds/freedesktop/stereo/dialog-information.oga"
readonly SOUND_CONNECT_FALLBACK="/usr/share/sounds/freedesktop/stereo/device-added.oga"
readonly SOUND_DISCONNECT_PRIMARY="/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
readonly SOUND_DISCONNECT_FALLBACK="/usr/share/sounds/freedesktop/stereo/device-removed.oga"

# --- LOGGING FUNCTIONS ---
log_info() {
    logger -t "$LOG_TAG" -- "$*"
}

log_error() {
    logger -t "$LOG_TAG" -p user.err -- "ERROR: $*"
}

# --- USAGE ---
show_usage() {
    cat <<EOF
USB Sound Notification Script

USAGE:
    $SCRIPT_NAME <ACTION>

ACTIONS:
    connect       Play the USB device connection sound
    disconnect    Play the USB device disconnection sound
    -h, --help    Display this help message

DESCRIPTION:
    This script detects the currently active user session and plays
    an audio notification through their PulseAudio/PipeWire server.
    
    It is designed to be called from udev rules when USB devices
    are plugged in or removed.

EXAMPLES:
    $SCRIPT_NAME connect      # Play connection sound
    $SCRIPT_NAME disconnect   # Play disconnection sound

LOGS:
    journalctl -t $LOG_TAG

EXIT CODES:
    0    Success (or no active session found - not an error)
    1    Error (invalid arguments, missing dependencies, etc.)
EOF
}

# --- HELPER FUNCTIONS ---

# Check if a command is available
require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: $cmd"
        return 1
    fi
}

# Resolve sound file (try primary, then fallback)
resolve_sound_file() {
    local primary="$1"
    local fallback="$2"
    
    if [[ -f "$primary" ]]; then
        printf '%s' "$primary"
        return 0
    elif [[ -f "$fallback" ]]; then
        log_info "Primary sound not found, using fallback: ${fallback##*/}"
        printf '%s' "$fallback"
        return 0
    else
        log_error "No sound files found: tried ${primary##*/} and ${fallback##*/}"
        return 1
    fi
}

# Find the active graphical session user
get_active_user() {
    local session_id user_name session_state
    
    require_command loginctl || return 1
    
    while read -r session_id user_name; do
        # Skip empty lines
        [[ -z "$session_id" || -z "$user_name" ]] && continue
        
        # Handle both new (--value) and old systemd syntax
        if session_state=$(loginctl show-session "$session_id" -p State --value 2>/dev/null); then
            : # New systemd, got the value directly
        elif session_state=$(loginctl show-session "$session_id" -p State 2>/dev/null); then
            # Old systemd returns "State=active", extract value
            session_state="${session_state#State=}"
        else
            continue
        fi
        
        if [[ "$session_state" == "active" ]]; then
            printf '%s' "$user_name"
            return 0
        fi
    done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1, $3}')
    
    return 1
}

# Play sound for the target user
play_sound() {
    local sound_file="$1"
    local event_type="$2"
    local user="$3"
    local uid="$4"
    
    # Verify sound file exists (should already be checked, but be safe)
    if [[ ! -f "$sound_file" ]]; then
        log_error "Sound file does not exist: $sound_file"
        return 1
    fi
    
    # Verify runtime directory exists
    if [[ ! -d "/run/user/$uid" ]]; then
        log_error "Runtime directory missing: /run/user/$uid"
        return 1
    fi
    
    log_info "USB $event_type: user='$user' uid=$uid sound='${sound_file##*/}'"
    
    # Play sound in a detached subshell to prevent blocking udev
    # - Export XDG_RUNTIME_DIR for PulseAudio/PipeWire socket discovery
    # - Volume 65536 = 100% (paplay uses 16-bit linear scale)
    # - Redirect stderr to prevent noise in udev logs
    # - disown to fully detach the background process
    (
        export XDG_RUNTIME_DIR="/run/user/$uid"
        runuser -u "$user" -- paplay --volume=65536 "$sound_file" 2>/dev/null
    ) &
    disown 2>/dev/null
    
    return 0
}

# --- MAIN ---
main() {
    local action="${1:-}"
    local target_user target_uid sound_file event_type
    
    # Parse action argument
    case "$action" in
        "")
            echo "Error: No action specified." >&2
            echo >&2
            echo "Run '$SCRIPT_NAME --help' for usage information." >&2
            exit 1
            ;;
        -h|--help|help)
            show_usage
            exit 0
            ;;
        connect)
            event_type="connection"
            ;;
        disconnect)
            event_type="disconnection"
            ;;
        *)
            echo "Error: Unknown action '$action'" >&2
            echo >&2
            echo "Valid actions: connect, disconnect" >&2
            echo "Run '$SCRIPT_NAME --help' for usage information." >&2
            exit 1
            ;;
    esac
    
    # Verify required commands exist
    require_command runuser || exit 1
    require_command paplay || exit 1
    require_command id || exit 1
    
    # Find active user session
    if ! target_user=$(get_active_user); then
        log_info "No active user session found (login screen?). Exiting quietly."
        exit 0
    fi
    
    # Get user's UID and validate
    if ! target_uid=$(id -u "$target_user" 2>/dev/null); then
        log_error "Failed to get UID for user '$target_user'"
        exit 1
    fi
    
    # Validate UID is a number
    if ! [[ "$target_uid" =~ ^[0-9]+$ ]]; then
        log_error "Invalid UID '$target_uid' for user '$target_user'"
        exit 1
    fi
    
    # Resolve sound file based on action
    case "$action" in
        connect)
            sound_file=$(resolve_sound_file "$SOUND_CONNECT_PRIMARY" "$SOUND_CONNECT_FALLBACK") || exit 1
            ;;
        disconnect)
            sound_file=$(resolve_sound_file "$SOUND_DISCONNECT_PRIMARY" "$SOUND_DISCONNECT_FALLBACK") || exit 1
            ;;
    esac
    
    # Play the sound
    play_sound "$sound_file" "$event_type" "$target_user" "$target_uid" || exit 1
    
    exit 0
}

# Invoke main with all script arguments
main "$@"
