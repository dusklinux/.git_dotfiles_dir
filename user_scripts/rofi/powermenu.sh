#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# METADATA & ERROR HANDLING
# -----------------------------------------------------------------------------
# Description: Robust Rofi Power Menu for Hyprland + UWSM
# Dependencies: rofi, systemd, uwsm (or loginctl), hyprlock

# We eschew 'set -e' to prevent premature termination during conditional checks,
# but enforce 'set -u' to catch ephemeral variable initialization errors.
set -u
set -o pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------

# Visual Assets (Nerd Fonts)
declare -A icons=(
    [shutdown]=""
    [reboot]=""
    [suspend]=""
    [soft_reboot]=""
    [logout]=""
    [lock]=""
    [cancel]=""
)

# Display Labels
declare -A texts=(
    [shutdown]="Shutdown"
    [reboot]="Reboot"
    [suspend]="Suspend"
    [soft_reboot]="Soft Reboot"
    [logout]="Logout"
    [lock]="Lock"
)

# Command Definitions
# Using arrays allows for safer argument handling than simple strings.
declare -A actions

# Shutdown: Standard systemd poweroff
actions[shutdown]="systemctl poweroff"

# Reboot: Standard systemd reboot
actions[reboot]="systemctl reboot"

# Suspend: Standard systemd suspend
actions[suspend]="systemctl suspend"

# Soft Reboot: Faster reboot via userspace (systemd v254+)
actions[soft_reboot]="systemctl soft-reboot"

# Logout: Detect UWSM (Universal Wayland Session Manager)
# Since you are running Hyprland via UWSM, 'uwsm stop' is the quintessential method
# to ensure all user-space services terminate gracefully.
if command -v uwsm >/dev/null 2>&1; then
    actions[logout]="uwsm stop"
else
    # Fallback: Terminate the specific session ID safely
    actions[logout]="loginctl terminate-session ${XDG_SESSION_ID:-}"
fi

# Lock: Idempotent check for running hyprlock instance.
# 'pgrep -x' is utilized here as it is more robust than 'pidof' in specific shell contexts.
actions[lock]="pgrep -x hyprlock >/dev/null || hyprlock"

# Menu Options Definition
# Order determines display order in Rofi
all_options=(lock logout suspend reboot soft_reboot shutdown)
confirmations=(reboot shutdown logout soft_reboot)

# Runtime Flags
dryrun=false
showsymbols=true

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------

# Validate that critical dependencies exist to avoid silent failures
check_dependencies() {
    local dependencies=(rofi systemctl)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: Critical dependency '$cmd' is missing." >&2
            exit 1
        fi
    done
}

# Validate command line arguments against allowed actions
check_valid() {
    local context="$1"
    shift 1
    for entry in "$@"; do
        if [[ -z "${actions[$entry]+x}" ]]; then
            echo "Invalid $context: $entry" >&2
            exit 1
        fi
    done
}

# Generate the Rofi formatting string
# Format: Text \0 icon \x1f ICON_VAL \x1f info \x1f INFO_VAL
print_entry() {
    local key="$1"
    local text="$2"
    local icon="${icons[$key]}"
    local info="$3"
    
    if [[ "$showsymbols" == "true" ]]; then
        # Pango markup allows for granular font control
        local label="<span font_size='medium'>${icon}  ${text}</span>"
        printf "%s\0icon\x1f%s\x1finfo\x1f%s\n" "$label" "$icon" "$info"
    else
        local label="<span font_size='medium'>${text}</span>"
        printf "%s\0info\x1f%s\n" "$label" "$info"
    fi
}

# -----------------------------------------------------------------------------
# ARGUMENT PARSING
# -----------------------------------------------------------------------------

# Use getopt for robust standard parsing
parsed=$(getopt --options=h --longoptions=help,dry-run,confirm:,choices:,choose:,symbols,no-symbols --name "$0" -- "$@")
if [ $? -ne 0 ]; then echo 'Terminating...' >&2; exit 1; fi
eval set -- "$parsed"
unset parsed

while true; do
    case "$1" in
        -h|--help) exit 0 ;;
        --dry-run) dryrun=true; shift 1 ;;
        --confirm)
            IFS='/' read -ra confirmations <<< "$2"
            check_valid "confirm" "${confirmations[@]}"
            shift 2
            ;;
        --choices)
            IFS='/' read -ra all_options <<< "$2"
            check_valid "choices" "${all_options[@]}"
            shift 2
            ;;
        --symbols) showsymbols=true; shift 1 ;;
        --no-symbols) showsymbols=false; shift 1 ;;
        --) shift; break ;;
        *) echo "Internal error" >&2; exit 1 ;;
    esac
done

check_dependencies

# -----------------------------------------------------------------------------
# MAIN LOGIC
# -----------------------------------------------------------------------------

# Rofi passes the selected entry as the first argument ($1)
selection="${1:-}"

# --- PHASE 1: INITIAL RENDER ---
if [[ -z "$selection" ]]; then
    # Send Rofi Control Headers
    # Calculate uptime for a "System" prompt status (e.g., "System (up 2h)")
    sys_uptime=$(uptime -p | sed 's/up //')
    echo -e "\0prompt\x1fSystem (${sys_uptime})"
    echo -e "\0markup-rows\x1ftrue"
    echo -e "\0use-hot-keys\x1ftrue"

    for entry in "${all_options[@]}"; do
        print_entry "$entry" "${texts[$entry]}" "$entry"
    done
    exit 0
fi

# --- PHASE 2: SELECTION PARSING ---

# 1. Sanitize Input
# Remove Pango markup to handle text-based fallback matching
clean_selection=$(echo "$selection" | sed 's/<[^>]*>//g')

# 2. Parse State (Key:State)
# We attempt to split the selection by ':' to extract the key and the state (confirmed)
IFS=':' read -r key state <<< "$selection"

# 3. Fallback Resolution (The Fix)
# If Rofi fails to pass the 'info' metadata (returning only the label text),
# we must heuristically resolve the intended action and state.
if [[ -z "${actions[$key]+x}" ]]; then
    found=false
    for k in "${!texts[@]}"; do
        # Check if the cleaned selection contains the action text (e.g., "Yes, Reboot" contains "Reboot")
        if [[ "$clean_selection" == *"${texts[$k]}"* ]]; then
            key="$k"
            found=true
            
            # CRITICAL FIX: Detect Confirmation State from Text
            # If the text contains "Yes", we imply the state is 'confirmed'.
            # This breaks the infinite loop when Rofi drops the 'info' packet.
            if [[ "$clean_selection" == *"Yes"* ]]; then
                state="confirmed"
            fi
            break
        fi
    done
    
    # Handle invalid keys
    if [[ "$found" == "false" && "$key" != "cancel" ]]; then
        # If "cancel" was selected via text matching, it might fail the hash check
        if [[ "$clean_selection" == *"cancel"* ]]; then
            exit 0
        fi
        echo "Error: Unknown action identifier '$clean_selection'" >&2
        exit 1
    fi
fi

# Handle Cancellation explicitly
if [[ "$key" == "cancel" ]]; then
    exit 0
fi

# --- PHASE 3: CONFIRMATION LOGIC ---

need_confirm=false
for item in "${confirmations[@]}"; do
    if [[ "$item" == "$key" ]]; then
        need_confirm=true
        break
    fi
done

# Display Confirmation Menu if needed and not yet confirmed
if [[ "$need_confirm" == "true" && "$state" != "confirmed" ]]; then
    echo -e "\0prompt\x1fAre you sure?"
    echo -e "\0markup-rows\x1ftrue"
    
    # YES Option
    # We pass "$key:confirmed" in the info field.
    label_yes="<span weight='bold' color='#f38ba8'>Yes, ${texts[$key]}</span>"
    print_entry "$key" "$label_yes" "${key}:confirmed"
    
    # NO Option
    label_no="<span weight='bold'>No, cancel</span>"
    print_entry "cancel" "$label_no" "cancel"
    
    exit 0
fi

# --- PHASE 4: EXECUTION ---

cmd="${actions[$key]}"

if [[ "$dryrun" == "true" ]]; then
    echo "[DRY RUN] Action: $key" >&2
    echo "[DRY RUN] Command: $cmd" >&2
    # Send a notification if notify-send exists, for visibility
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Power Menu (Dry Run)" "Action: $key\nCommand: $cmd"
    fi
else
    # Execute the command
    eval "$cmd"
fi

exit 0
