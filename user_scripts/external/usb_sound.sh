#!/bin/bash

# This script is run by a udev rule (as root).
# It MUST be placed in a system-wide path like /usr/local/bin/
# It will NOT work from a user's home directory due to security policies.

# --- ABSOLUTE PATHS ---
# udev has a minimal PATH, so we must use absolute paths for all commands.
LOGINCTL_CMD="/usr/bin/loginctl"
GREP_CMD="/usr/bin/grep"
HEAD_CMD="/usr/bin/head"
AWK_CMD="/usr/bin/awk"
ID_CMD="/usr/bin/id"
PAPLAY_CMD="/usr/bin/paplay"
RUNUSER_CMD="/usr/bin/runuser"
BASH_CMD="/usr/bin/bash"

# Fallback paths
if [ ! -f "$RUNUSER_CMD" ]; then RUNUSER_CMD="/bin/runuser"; fi
if [ ! -f "$BASH_CMD" ]; then BASH_CMD="/bin/bash"; fi
if [ ! -f "$GREP_CMD" ]; then GREP_CMD="/bin/grep"; fi
if [ ! -f "$AWK_CMD" ]; then AWK_CMD="/bin/awk"; fi
if [ ! -f "$HEAD_CMD" ]; then HEAD_CMD="/bin/head"; fi

# 1. Find the active graphical user
# We query loginctl for a session that has a 'seat' (like seat0)
# and is not a 'tty' (a text-only console).
# We must use --no-pager to prevent it from trying to page output.
SESSION_INFO=$($LOGINCTL_CMD --no-pager list-sessions --no-legend | $GREP_CMD 'seat' | $GREP_CMD -v 'tty' | $HEAD_CMD -n 1)

if [ -z "$SESSION_INFO" ]; then
    # Fallback: if no graphical session, just find the first logged-in user
    SESSION_INFO=$($LOGINCTL_CMD --no-pager list-sessions --no-legend | $HEAD_CMD -n 1)
fi

if [ -z "$SESSION_INFO" ]; then
    exit 1
fi

# Get the User ID and Username from the session info
USER_ID=$(echo "$SESSION_INFO" | $AWK_CMD '{print $2}')
USER_NAME=$($ID_CMD -un "$USER_ID")

if [ -z "$USER_NAME" ] || [ -z "$USER_ID" ]; then
    exit 1
fi

# 2. Set the user's audio environment variables
export XDG_RUNTIME_DIR="/run/user/$USER_ID"
export PULSE_SERVER="unix:${XDG_RUNTIME_DIR}/pulse/native"

# 3. Define the sound files
SOUND_CONNECT="/usr/share/sounds/freedesktop/stereo/device-added.oga"
SOUND_DISCONNECT="/usr/share/sounds/freedesktop/stereo/device-removed.oga"

# 4. Play the sound *as the user*
play_as_user() {
    local sound_file=$1
    if [ -f "$sound_file" ]; then
        
        # We need the full command inside quotes for bash -c
        local cmd_to_run="XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR PULSE_SERVER=$PULSE_SERVER $PAPLAY_CMD '$sound_file'"
        
        # Run it. Note: No trailing '&' inside the quotes.
        # runuser will daemonize it properly.
        $RUNUSER_CMD -u "$USER_NAME" -- $BASH_CMD -c "$cmd_to_run" &
    else
        : # Do nothing if sound file not found
    fi
}

# The udev rule will pass "connect" or "disconnect" as the first argument ($1).
case "$1" in
    connect)
        play_as_user "$SOUND_CONNECT"
        ;;
    disconnect)
        play_as_user "$SOUND_DISCONNECT"
        ;;
    *)
        : # Do nothing for unknown action
        ;;
esac

exit 0
