#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# METADATA & ERROR HANDLING
# -----------------------------------------------------------------------------
# Description: Robust Rofi Power Menu for Hyprland + UWSM
# Dependencies: rofi, systemd, uwsm (optional), hyprlock
# Version: 2.0.0

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

# Display Labels - must mirror all keys used in options/confirmations
declare -A texts=(
    [shutdown]="Shutdown"
    [reboot]="Reboot"
    [suspend]="Suspend"
    [soft_reboot]="Soft Reboot"
    [logout]="Logout"
    [lock]="Lock"
    [cancel]="Cancel"
)

# Command Definitions - simple commands only (no shell constructs)
declare -A actions=(
    [shutdown]="systemctl poweroff"
    [reboot]="systemctl reboot"
    [suspend]="systemctl suspend"
    [soft_reboot]="systemctl soft-reboot"
    [lock]="__lock_screen__"
)

# Logout: Detect UWSM or use loginctl fallback
if command -v uwsm >/dev/null 2>&1; then
    actions[logout]="uwsm stop"
else
    actions[logout]="loginctl terminate-user ${USER:-$(id -un)}"
fi

# Confirmation lookup (associative array for O(1) lookup)
declare -A needs_confirmation=(
    [reboot]=1
    [shutdown]=1
    [logout]=1
    [soft_reboot]=1
)

# Menu options - order determines display order in Rofi
all_options=(lock logout suspend reboot soft_reboot shutdown)

# Runtime Flags
dryrun=false
showsymbols=true

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------

show_help() {
    cat << 'EOF'
Usage: powermenu [OPTIONS] [SELECTION]

A robust Rofi power menu for Hyprland + UWSM.

OPTIONS:
    -h, --help              Show this help message and exit
    --dry-run               Print commands without executing them
    --confirm=LIST          Slash-separated actions requiring confirmation
                            Default: reboot/shutdown/logout/soft_reboot
    --choices=LIST          Slash-separated actions to display
                            Default: lock/logout/suspend/reboot/soft_reboot/shutdown
    --symbols               Show icons (default)
    --no-symbols            Hide icons

EXAMPLES:
    powermenu
    powermenu --dry-run
    powermenu --choices=lock/logout/shutdown
    powermenu --confirm=shutdown/reboot --no-symbols

AVAILABLE ACTIONS:
    lock, logout, suspend, reboot, soft_reboot, shutdown
EOF
}

# Lock screen with idempotent check
lock_screen() {
    if ! pgrep -x hyprlock >/dev/null 2>&1; then
        hyprlock &
        disown
    fi
}

# Validate that critical dependencies exist
check_dependencies() {
    local -a deps=(rofi systemctl)
    local cmd

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf 'Error: Required dependency "%s" not found.\n' "$cmd" >&2
            exit 1
        fi
    done

    # Warn about optional dependencies
    if [[ ! -x "$(command -v hyprlock)" ]]; then
        printf 'Warning: hyprlock not found; lock action will fail.\n' >&2
    fi
}

# Validate entries against defined actions
check_valid() {
    local context="$1"
    shift
    local entry

    for entry in "$@"; do
        if [[ -z "${actions[$entry]+isset}" ]]; then
            printf 'Invalid %s: "%s"\n' "$context" "$entry" >&2
            printf 'Valid options: %s\n' "${!actions[*]}" >&2
            exit 1
        fi
    done
}

# Generate a Rofi menu entry
# Rofi format: text\0icon\x1fICON\x1finfo\x1fINFO
print_entry() {
    local key="$1"
    local text="$2"
    local info="$3"
    local icon="${icons[$key]:-}"
    local label

    if [[ "$showsymbols" == true && -n "$icon" ]]; then
        label="${icon}  ${text}"
        printf '%s\0icon\x1f%s\x1finfo\x1f%s\n' "$label" "$icon" "$info"
    else
        printf '%s\0info\x1f%s\n' "$text" "$info"
    fi
}

# Get system uptime portably
get_uptime() {
    local seconds days hours mins

    if uptime -p &>/dev/null; then
        uptime -p | sed 's/^up //'
        return
    fi

    # Fallback: parse /proc/uptime (Linux) or use sysctl (BSD)
    if [[ -r /proc/uptime ]]; then
        read -r seconds _ < /proc/uptime
        seconds="${seconds%%.*}"
    else
        seconds=$(sysctl -n kern.boottime 2>/dev/null | awk '{print systime() - $4}' | tr -d ',') || seconds=0
    fi

    days=$((seconds / 86400))
    hours=$(((seconds % 86400) / 3600))
    mins=$(((seconds % 3600) / 60))

    if ((days > 0)); then
        printf '%dd %dh' "$days" "$hours"
    elif ((hours > 0)); then
        printf '%dh %dm' "$hours" "$mins"
    else
        printf '%dm' "$mins"
    fi
}

# Execute the selected action
execute_action() {
    local key="$1"
    local cmd="${actions[$key]}"

    if [[ "$dryrun" == true ]]; then
        printf '[DRY-RUN] Action: %s\n' "$key" >&2
        printf '[DRY-RUN] Command: %s\n' "$cmd" >&2
        command -v notify-send >/dev/null 2>&1 && \
            notify-send "Power Menu (Dry Run)" "Would execute: $key"
        return 0
    fi

    case "$key" in
        lock)
            lock_screen
            ;;
        *)
            # Safe: commands are simple "cmd arg" format without shell metacharacters
            # shellcheck disable=SC2086
            exec $cmd
            ;;
    esac
}

# -----------------------------------------------------------------------------
# ARGUMENT PARSING
# -----------------------------------------------------------------------------

parsed=$(getopt \
    --options=h \
    --longoptions=help,dry-run,confirm:,choices:,symbols,no-symbols \
    --name "${0##*/}" \
    -- "$@" 2>&1) || {
    printf '%s\n' "$parsed" >&2
    exit 1
}

eval set -- "$parsed"
unset parsed

while true; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --dry-run)
            dryrun=true
            shift
            ;;
        --confirm)
            # Rebuild confirmation map from argument
            needs_confirmation=()
            IFS='/' read -ra _confirm_list <<< "$2"
            check_valid "confirmation action" "${_confirm_list[@]}"
            for _item in "${_confirm_list[@]}"; do
                needs_confirmation["$_item"]=1
            done
            unset _confirm_list _item
            shift 2
            ;;
        --choices)
            IFS='/' read -ra all_options <<< "$2"
            check_valid "menu choice" "${all_options[@]}"
            shift 2
            ;;
        --symbols)
            showsymbols=true
            shift
            ;;
        --no-symbols)
            showsymbols=false
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            printf 'Internal error: unhandled option "%s"\n' "$1" >&2
            exit 1
            ;;
    esac
done

check_dependencies

# -----------------------------------------------------------------------------
# MAIN LOGIC
# -----------------------------------------------------------------------------

# Rofi passes selection as first positional argument
selection="${1:-}"

# --- PHASE 1: INITIAL MENU RENDER ---
if [[ -z "$selection" ]]; then
    sys_uptime=$(get_uptime)
    
    # Rofi control headers
    printf '\0prompt\x1fSystem (%s)\n' "$sys_uptime"
    printf '\0markup-rows\x1ffalse\n'
    printf '\0use-hot-keys\x1ftrue\n'

    for entry in "${all_options[@]}"; do
        print_entry "$entry" "${texts[$entry]}" "$entry"
    done
    exit 0
fi

# --- PHASE 2: PARSE SELECTION ---

# Strip any Pango/HTML markup for fallback matching
clean_selection=$(sed 's/<[^>]*>//g' <<< "$selection")

# Parse "key:state" format (state is "confirmed" after confirmation)
IFS=':' read -r key state <<< "$selection"
state="${state:-}"

# Fallback: resolve key from display text if info field was lost
if [[ -z "${actions[$key]+isset}" ]]; then
    resolved=false

    for candidate in "${!texts[@]}"; do
        if [[ "$clean_selection" == *"${texts[$candidate]}"* ]]; then
            key="$candidate"
            resolved=true

            # Detect confirmation from "Yes" prefix
            [[ "$clean_selection" == *"Yes,"* ]] && state="confirmed"
            break
        fi
    done

    if [[ "$resolved" == false ]]; then
        # Check for cancel action
        if [[ "$clean_selection" == *"No,"* || "$clean_selection" == *"cancel"* ]]; then
            exit 0
        fi
        printf 'Error: Unknown selection "%s"\n' "$clean_selection" >&2
        exit 1
    fi
fi

# Handle cancel
[[ "$key" == "cancel" ]] && exit 0

# Final validation
if [[ -z "${actions[$key]+isset}" ]]; then
    printf 'Error: Invalid action key "%s"\n' "$key" >&2
    exit 1
fi

# --- PHASE 3: CONFIRMATION ---

if [[ -n "${needs_confirmation[$key]+isset}" && "$state" != "confirmed" ]]; then
    printf '\0prompt\x1fAre you sure?\n'
    printf '\0markup-rows\x1ffalse\n'

    # Confirmation options
    print_entry "$key" "Yes, ${texts[$key]}" "${key}:confirmed"
    print_entry "cancel" "No, cancel" "cancel"

    exit 0
fi

# --- PHASE 4: EXECUTE ---

execute_action "$key"
exit 0
