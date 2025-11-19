#!/bin/bash

# --- CONFIGURATION ---
# Set a secure path so we don't need to hardcode commands
export PATH="/usr/bin:/usr/local/bin:/bin"

# Logging tag for journalctl (view logs with: journalctl -t usb-sound)
LOG_TAG="usb-sound"

# --- 1. ROBUST USER DETECTION ---
# We cannot assume the session is not a TTY (Hyprland runs on TTYs).
# We need to find the session that has a "State" of "active".

target_user=""
target_uid=""

# Get list of all sessions (ID and User)
while read -r session_id user_name; do
    # Check the state of this session
    session_state=$(loginctl show-session -p State --value "$session_id")
    
    if [[ "$session_state" == "active" ]]; then
        target_user="$user_name"
        target_uid=$(id -u "$user_name")
        break
    fi
done < <(loginctl list-sessions --no-legend | awk '{print $1, $3}')

# Exit if no active user found (e.g., sitting at login screen)
if [[ -z "$target_user" ]]; then
    logger -t "$LOG_TAG" "No active user session found. Exiting."
    exit 0
fi

# --- 2. AUDIO SETUP ---
# Point to the user's PulseAudio/PipeWire socket
export XDG_RUNTIME_DIR="/run/user/$target_uid"

# --- 3. SOUND SELECTION ---
# You requested clearer, louder sounds. 
# using "dialog-information" (a sharp ping) for connect
# and "service-logout" (a lower descending tone) or "dialog-warning" for disconnect.
# These exist in the standard freedesktop/libcanberra sets.

SOUND_CONNECT="/usr/share/sounds/freedesktop/stereo/dialog-information.oga"
SOUND_DISCONNECT="/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"

# Fallback to standard sounds if the louder ones don't exist
[[ ! -f "$SOUND_CONNECT" ]] && SOUND_CONNECT="/usr/share/sounds/freedesktop/stereo/device-added.oga"
[[ ! -f "$SOUND_DISCONNECT" ]] && SOUND_DISCONNECT="/usr/share/sounds/freedesktop/stereo/device-removed.oga"

# --- 4. PLAYBACK FUNCTION ---
play_sound() {
    local file="$1"
    
    # Log the attempt
    logger -t "$LOG_TAG" "Detecting $2 for user $target_user. Playing $file"

    if [[ -f "$file" ]]; then
        # runuser is safer and cleaner than su. 
        # We run paplay in the background (&) so udev doesn't hang.
        # We set the volume explicitly to 100% (65536) just in case.
        runuser -u "$target_user" -- paplay --volume=65536 "$file" &
    else
        logger -t "$LOG_TAG" "Sound file not found: $file"
    fi
}

# --- 5. EXECUTION ---
case "$1" in
    connect)
        play_sound "$SOUND_CONNECT" "connection"
        ;;
    disconnect)
        play_sound "$SOUND_DISCONNECT" "disconnection"
        ;;
esac

exit 0
