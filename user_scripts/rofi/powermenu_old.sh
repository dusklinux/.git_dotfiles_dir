#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Rofi Power Menu for Hyprland + UWSM
# Optimized for Arch Linux with Bash 5+
# -----------------------------------------------------------------------------

set -u
set -o pipefail

# Prevent multiple instances using atomic file locking
readonly LOCK_FILE="/run/user/${UID}/rofi-power.lock"
exec 200>"$LOCK_FILE"
flock -n 200 || exit 0

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------

declare -Ar ICONS=(
    [shutdown]=""
    [reboot]=""
    [suspend]=""
    [soft_reboot]=""
    [logout]=""
    [lock]=""
    [cancel]=""
)

declare -Ar LABELS=(
    [shutdown]="Shutdown"
    [reboot]="Reboot"
    [suspend]="Suspend"
    [soft_reboot]="Soft Reboot"
    [logout]="Logout"
    [lock]="Lock"
    [cancel]="Cancel"
)

# O(1) confirmation lookup
declare -Ar DEFAULT_CONFIRMS=(
    [shutdown]=1 [reboot]=1 [logout]=1 [soft_reboot]=1
)

# Ordered menu entries
declare -a menu_order=(lock logout suspend reboot soft_reboot shutdown)

# Mutable confirmation set (can be overridden via args)
declare -A confirmations=()

# Runtime state
declare show_symbols=true
declare dry_run=false

# -----------------------------------------------------------------------------
# ACTION FUNCTIONS (eliminates eval)
# -----------------------------------------------------------------------------

action::shutdown() {
    systemctl poweroff &
}

action::reboot() {
    systemctl reboot &
}

action::suspend() {
    systemctl suspend &
}

action::soft_reboot() {
    systemctl soft-reboot &
}

action::logout() {
    if command -v uwsm &>/dev/null; then
        # UWSM handles graceful Wayland session shutdown
        uwsm stop &
    elif [[ -n ${XDG_SESSION_ID:-} ]]; then
        loginctl terminate-session "$XDG_SESSION_ID" &
    else
        # Ultimate fallback: signal Hyprland directly
        hyprctl dispatch exit &
    fi
}

action::lock() {
    # Idempotent: skip if already locked
    pgrep -x hyprlock &>/dev/null && return 0
    # MUST run detached to not block script/rofi
    hyprlock &
    disown
}

# Dispatcher map
declare -Ar ACTIONS=(
    [shutdown]=action::shutdown
    [reboot]=action::reboot
    [suspend]=action::suspend
    [soft_reboot]=action::soft_reboot
    [logout]=action::logout
    [lock]=action::lock
)

# -----------------------------------------------------------------------------
# UTILITY FUNCTIONS
# -----------------------------------------------------------------------------

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

check_deps() {
    local -ar required=(rofi systemctl)
    local cmd
    for cmd in "${required[@]}"; do
        command -v "$cmd" &>/dev/null || die "Missing dependency: $cmd"
    done
}

validate_keys() {
    local context="$1"; shift
    local key
    for key in "$@"; do
        [[ -v ACTIONS[$key] ]] || die "Invalid $context: '$key'"
    done
}

# Print Rofi row with proper escaping
print_row() {
    local key="$1" label="$2" info="$3"
    local icon="${ICONS[$key]:-}"

    if [[ $show_symbols == true && -n $icon ]]; then
        printf '%s\0icon\x1f%s\x1finfo\x1f%s\n' \
            "<span font_size='medium'>${icon}  ${label}</span>" \
            "$icon" "$info"
    else
        printf '%s\0info\x1f%s\n' \
            "<span font_size='medium'>${label}</span>" "$info"
    fi
}

print_help() {
    cat <<'HELP'
Usage: rofi-power-menu [OPTIONS]

A power menu for Hyprland/UWSM using Rofi.

Options:
  -h, --help              Show this help and exit
  --dry-run               Log actions without executing
  --confirm=A/B/C         Slash-separated actions requiring confirmation
  --choices=A/B/C         Slash-separated menu entries to display
  --symbols               Show Nerd Font icons (default)
  --no-symbols            Hide icons

Available actions:
  shutdown, reboot, suspend, soft_reboot, logout, lock

Examples:
  rofi-power-menu --choices=lock/logout/shutdown
  rofi-power-menu --confirm=shutdown/reboot --no-symbols
HELP
}

# -----------------------------------------------------------------------------
# ARGUMENT PARSING
# -----------------------------------------------------------------------------

# Initialize confirmations from defaults
for key in "${!DEFAULT_CONFIRMS[@]}"; do
    confirmations[$key]=1
done

if ! parsed=$(getopt \
    --options=h \
    --longoptions=help,dry-run,confirm:,choices:,symbols,no-symbols \
    --name "${0##*/}" \
    -- "$@" 2>/dev/null); then
    die "Invalid arguments. Use --help for usage."
fi
eval set -- "$parsed"
unset parsed

while true; do
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        --confirm)
            confirmations=()  # Clear defaults
            IFS='/' read -ra _items <<< "$2"
            validate_keys "confirm" "${_items[@]}"
            for _k in "${_items[@]}"; do confirmations[$_k]=1; done
            unset _items _k
            shift 2
            ;;
        --choices)
            IFS='/' read -ra menu_order <<< "$2"
            validate_keys "choices" "${menu_order[@]}"
            shift 2
            ;;
        --symbols)
            show_symbols=true
            shift
            ;;
        --no-symbols)
            show_symbols=false
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            die "Unhandled option: $1"
            ;;
    esac
done

check_deps

# -----------------------------------------------------------------------------
# MAIN LOGIC
# -----------------------------------------------------------------------------

selection="${1:-}"

# === PHASE 1: Render Initial Menu ===
if [[ -z $selection ]]; then
    # Safe uptime extraction
    if uptime_raw=$(uptime -p 2>/dev/null); then
        uptime_str="${uptime_raw#up }"
    else
        uptime_str="unknown"
    fi

    # Rofi directives (using printf for reliable control chars)
    printf '\0prompt\x1fSystem (%s)\n' "$uptime_str"
    printf '\0markup-rows\x1ftrue\n'
    printf '\0use-hot-keys\x1ftrue\n'

    for entry in "${menu_order[@]}"; do
        print_row "$entry" "${LABELS[$entry]}" "$entry"
    done
    exit 0
fi

# === PHASE 2: Parse Selection ===

# Safely strip Pango markup
clean_selection=$(printf '%s' "$selection" | sed 's/<[^>]*>//g')

# Extract key and optional state (format: "key" or "key:state")
IFS=':' read -r key state <<< "$selection"
state="${state:-}"  # Ensure defined for set -u

# === PHASE 3: Resolve Key ===

if [[ ! -v ACTIONS[$key] ]]; then
    # Fallback: heuristic text matching (handles Rofi info loss)
    resolved=false
    for k in "${!LABELS[@]}"; do
        if [[ $clean_selection == *"${LABELS[$k]}"* ]]; then
            key="$k"
            resolved=true
            # Detect confirmation acknowledgment
            [[ $clean_selection == *Yes* ]] && state="confirmed"
            break
        fi
    done

    if [[ $resolved == false ]]; then
        # Check for cancel variants
        if [[ $clean_selection == *[Cc]ancel* ]]; then
            exit 0
        fi
        die "Unrecognized selection: '$clean_selection'"
    fi
fi

# Explicit cancel
[[ $key == cancel ]] && exit 0

# === PHASE 4: Confirmation Dialog ===

if [[ -v confirmations[$key] && $state != confirmed ]]; then
    printf '\0prompt\x1fConfirm %s?\n' "${LABELS[$key]}"
    printf '\0markup-rows\x1ftrue\n'

    # "Yes" option - Colors removed, relies on Rofi theme
    yes_label="<span weight='bold'>Yes, ${LABELS[$key]}</span>"
    print_row "$key" "$yes_label" "${key}:confirmed"

    # "No" option - Colors removed, relies on Rofi theme
    no_label="<span weight='bold'>No, Cancel</span>"
    printf '%s\0info\x1fcancel\n' "$no_label"

    exit 0
fi

# === PHASE 5: Execute Action ===

if [[ $dry_run == true ]]; then
    msg="[DRY RUN] Would execute: $key"
    printf '%s\n' "$msg" >&2
    command -v notify-send &>/dev/null && notify-send "Power Menu" "$msg"
    exit 0
fi

# Small delay allows Rofi to fully close before power action
# Prevents race conditions with session/display managers
sleep 0.1

# Dispatch to action function (backgrounded for non-blocking exit)
"${ACTIONS[$key]}"

exit 0
