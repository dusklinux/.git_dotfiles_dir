#!/bin/bash

# ==============================================================================
#  UNIVERSAL DRIVE MANAGER (FSTAB NATIVE)
#  ------------------------------------------------------------------------------
#  Usage: ./drive_manager.sh [action] [target]
#  Example: ./drive_manager.sh unlock browser
#           ./drive_manager.sh status
# ==============================================================================

# Strict mode - exit on undefined vars, pipe failures
set -o nounset
set -o pipefail

# ------------------------------------------------------------------------------
#  CONFIGURATION
# ------------------------------------------------------------------------------
# Format: [name]="TYPE|MOUNTPOINT|OUTER_UUID|INNER_UUID|HINT"
#
# TYPE:
#   PROTECTED : Encrypted (LUKS/BitLocker). Requires OUTER & INNER UUIDs.
#   SIMPLE    : Standard partition. Leave INNER_UUID empty.
#
# HINT (Optional): Password reminder displayed during unlock.
#
# UUID GUIDE:
#   OUTER_UUID : UUID of raw partition (lsblk -f while LOCKED)
#   INNER_UUID : UUID of filesystem inside (lsblk -f while UNLOCKED)
#                Must match UUID in /etc/fstab. Leave empty for SIMPLE drives.


# ------------------------------------------------------------------------------
#  ADD NEW DRIVES HERE
#  IMPORTANT: Maintain the pipe '|' structure to avoid "unbound variable" errors.
# ------------------------------------------------------------------------------

# TEMPLATE: Encrypted / Protected Drive (LUKS/BitLocker)
# All 5 fields must be filled.
# DRIVES["name"]="PROTECTED|/mnt/path|OUTER_UUID|INNER_UUID|HINT_TEXT"

# TEMPLATE: Simple / Standard Partition (Ext4/NTFS/Btrfs)
# Must have empty pipes '||' at the end for the empty INNER_UUID and HINT.
# DRIVES["name"]="SIMPLE|/mnt/path|PARTITION_UUID||"

# ------------------------------------------------------------------------------
#
declare -A DRIVES

# --- PROTECTED DRIVES ---
DRIVES["browser"]="PROTECTED|/mnt/browser|0a52e1bb-4fa0-4138-a150-f59467903e22|1adeb61a-0605-4bbc-8178-bb81fe1fca09|LAP_P"
DRIVES["media"]="PROTECTED|/mnt/media|55d50d6d-a1ed-41d9-ba38-a6542eebbcd9|9C38076638073F30|LAP_P"
DRIVES["slow"]="PROTECTED|/mnt/slow|e15929e5-417f-4761-b478-55c9a7c24220|5A921A119219F26D|game_simple"
DRIVES["wdslow"]="PROTECTED|/mnt/wdslow|01f38f5b-86de-4499-b93f-6c982e2067cb|2765359f-232e-4165-bc69-ef402b50c74c|game_simple"
DRIVES["wdfast"]="PROTECTED|/mnt/wdfast|953a147e-a346-4fea-91f4-a81ec97fa56a|46798d3b-cda7-4031-818f-37a06abbeb37|game_simple"
DRIVES["enclosure"]="PROTECTED|/mnt/enclosure|bde4bde0-19f7-4ba9-a0f0-541fec19beb6|5A428B8A428B6A19|pass_p"

# --- SIMPLE DRIVES ---
DRIVES["fast"]="SIMPLE|/mnt/fast|70EED6A1EED65F42||"

# ------------------------------------------------------------------------------
#  CONSTANTS
# ------------------------------------------------------------------------------
readonly MAX_UNLOCK_RETRIES=100
readonly FILESYSTEM_TIMEOUT=15
readonly LOCK_RETRY_DELAY=1
readonly LOCK_MAX_RETRIES=5
readonly SETTLE_DELAY=1
readonly SCRIPT_NAME="${0##*/}"
readonly LOCK_FILE="/tmp/.drive_manager.lock"

# Global config variables (set by validate_config)
declare -g TYPE="" MOUNTPOINT="" OUTER_UUID="" INNER_UUID="" HINT=""

# ------------------------------------------------------------------------------
#  COLOR HANDLING
# ------------------------------------------------------------------------------
# Disable colors if not on a terminal
if [[ -t 1 ]] && [[ -t 2 ]]; then
    readonly C_BLUE=$'\033[1;34m'
    readonly C_RED=$'\033[1;31m'
    readonly C_GREEN=$'\033[1;32m'
    readonly C_YELLOW=$'\033[1;33m'
    readonly C_WHITE=$'\033[1;37m'
    readonly C_RESET=$'\033[0m'
else
    readonly C_BLUE="" C_RED="" C_GREEN="" C_YELLOW="" C_WHITE="" C_RESET=""
fi

# ------------------------------------------------------------------------------
#  LOGGING FUNCTIONS
# ------------------------------------------------------------------------------
log()        { printf '%s[DRIVE]%s %s\n' "$C_BLUE" "$C_RESET" "$1"; }
err()        { printf '%s[ERROR]%s %s\n' "$C_RED" "$C_RESET" "$1" >&2; }
success()    { printf '%s[SUCCESS]%s %s\n' "$C_GREEN" "$C_RESET" "$1"; }
print_hint() { printf '%s[HINT]%s  %s\n' "$C_YELLOW" "$C_RESET" "$1"; }
debug()      { [[ "${DEBUG:-0}" == "1" ]] && printf '%s[DEBUG]%s %s\n' "$C_WHITE" "$C_RESET" "$1" >&2; }

# ------------------------------------------------------------------------------
#  CLEANUP & SIGNAL HANDLING
# ------------------------------------------------------------------------------
cleanup() {
    # Remove lock file if we own it
    [[ -f "$LOCK_FILE" ]] && rm -f "$LOCK_FILE" 2>/dev/null
}
trap cleanup EXIT

acquire_lock() {
    # Simple file-based locking to prevent concurrent execution
    if [[ -f "$LOCK_FILE" ]]; then
        local pid
        pid=$(<"$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            err "Another instance is running (PID: $pid)"
            exit 1
        fi
        # Stale lock file, remove it
        rm -f "$LOCK_FILE"
    fi
    printf '%s' "$$" > "$LOCK_FILE"
}

# ------------------------------------------------------------------------------
#  HELPER FUNCTIONS
# ------------------------------------------------------------------------------
check_dependencies() {
    local missing=()
    local deps=(
        "udisksctl"
        "mountpoint"
        "lsblk"
        "pgrep"
        "sync"
        "sudo"
        "grep"
        "sleep"
    )

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if ((${#missing[@]} > 0)); then
        err "Missing required commands: ${missing[*]}"
        exit 1
    fi
}

check_polkit_agent() {
    local -r polkit_pattern='polkit-gnome-authentication-agent|polkit-kde-authentication-agent|lxqt-policykit|mate-polkit|hyprpolkitagent|polkit-agent-helper'
    pgrep -f "$polkit_pattern" >/dev/null 2>&1
}

is_block_device_ready() {
    local device="$1"
    # Check both that the path exists AND it's a valid block device
    # This handles broken symlinks in /dev/disk/by-uuid/
    [[ -L "$device" && -b "$device" ]] || [[ -b "$device" ]]
}

show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME {unlock|lock|status} [drive_name]

Actions:
  unlock <name>  Unlock and mount the specified drive
  lock <name>    Unmount and lock the specified drive
  status         Show status of all configured drives

Options:
  -h, --help     Show this help message
  DEBUG=1        Enable debug output (e.g., DEBUG=1 $SCRIPT_NAME status)

Available drives: ${!DRIVES[*]}

Examples:
  $SCRIPT_NAME unlock browser
  $SCRIPT_NAME lock media
  $SCRIPT_NAME status
EOF
}

show_status() {
    local name type mountpoint
    local -a sorted_names

    # Use readarray with process substitution for safe sorting
    readarray -t sorted_names < <(printf '%s\n' "${!DRIVES[@]}" | sort)

    printf '\n%s%-14s %-10s %-8s %s%s\n' \
        "$C_WHITE" "DRIVE" "TYPE" "STATUS" "MOUNTPOINT" "$C_RESET"
    printf '%s\n' "------------------------------------------------------"

    for name in "${sorted_names[@]}"; do
        IFS='|' read -r type mountpoint _ _ _ <<< "${DRIVES[$name]}"

        if mountpoint -q "$mountpoint" 2>/dev/null; then
            printf '%s●%s %-13s %-10s %-8s %s\n' \
                "$C_GREEN" "$C_RESET" "$name" "$type" "mounted" "$mountpoint"
        else
            printf '%s○%s %-13s %-10s %-8s %s\n' \
                "$C_RED" "$C_RESET" "$name" "$type" "unmounted" "$mountpoint"
        fi
    done
    printf '\n'
}

validate_config() {
    local target="$1"

    # Check if key exists in associative array
    if [[ -z "${DRIVES[$target]+_}" ]]; then
        err "Drive '$target' not found in configuration."
        printf 'Available drives: %s\n' "${!DRIVES[*]}" >&2
        exit 1
    fi

    # Parse configuration into global variables
    IFS='|' read -r TYPE MOUNTPOINT OUTER_UUID INNER_UUID HINT <<< "${DRIVES[$target]}"

    # Validate TYPE
    if [[ -z "$TYPE" ]]; then
        err "Configuration error: TYPE is empty for '$target'"
        exit 1
    fi

    if [[ "$TYPE" != "PROTECTED" && "$TYPE" != "SIMPLE" ]]; then
        err "Configuration error: TYPE must be 'PROTECTED' or 'SIMPLE', got '$TYPE'"
        exit 1
    fi

    # Validate MOUNTPOINT
    if [[ -z "$MOUNTPOINT" ]]; then
        err "Configuration error: MOUNTPOINT is empty for '$target'"
        exit 1
    fi

    # Verify mountpoint directory exists
    if [[ ! -d "$MOUNTPOINT" ]]; then
        err "Mountpoint directory does not exist: $MOUNTPOINT"
        err "Create it with: sudo mkdir -p '$MOUNTPOINT'"
        exit 1
    fi

    # Validate OUTER_UUID
    if [[ -z "$OUTER_UUID" ]]; then
        err "Configuration error: OUTER_UUID is empty for '$target'"
        exit 1
    fi

    # PROTECTED drives require INNER_UUID
    if [[ "$TYPE" == "PROTECTED" && -z "$INNER_UUID" ]]; then
        err "Configuration error: PROTECTED drives require INNER_UUID for '$target'"
        exit 1
    fi

    debug "Loaded config: TYPE=$TYPE, MOUNTPOINT=$MOUNTPOINT, OUTER_UUID=$OUTER_UUID"
}

wait_for_device() {
    local device="$1"
    local timeout="$2"
    local elapsed=0

    # Try udevadm settle first for event-based waiting
    if command -v udevadm &>/dev/null; then
        udevadm settle --timeout="$timeout" 2>/dev/null || true
    fi

    # Poll as verification/fallback
    while ! is_block_device_ready "$device"; do
        if ((elapsed >= timeout)); then
            return 1
        fi
        sleep 1
        ((++elapsed))  # Pre-increment avoids exit code issue with set -e
    done

    return 0
}

# ------------------------------------------------------------------------------
#  UNLOCK FUNCTION
# ------------------------------------------------------------------------------
do_unlock() {
    local target="$1"
    local outer_dev inner_dev mount_dev
    local unlock_attempts=0
    local unlock_output

    log "Starting unlock process for '$target'..."

    # Check if already mounted
    if mountpoint -q "$MOUNTPOINT" 2>/dev/null; then
        success "'$target' is already mounted at $MOUNTPOINT"
        return 0
    fi

    if [[ "$TYPE" == "PROTECTED" ]]; then
        outer_dev="/dev/disk/by-uuid/$OUTER_UUID"
        inner_dev="/dev/disk/by-uuid/$INNER_UUID"

        # Check if physical disk exists
        if ! is_block_device_ready "$outer_dev"; then
            err "Physical drive not found (UUID: $OUTER_UUID)"
            err "Is the drive connected? Check with: lsblk -f"
            exit 1
        fi

        # Check if already unlocked
        if is_block_device_ready "$inner_dev"; then
            log "Container already unlocked (filesystem found)"
        else
            log "Unlocking encrypted container..."

            # Display hint if available
            [[ -n "$HINT" ]] && print_hint "$HINT"

            # Verify polkit agent is running
            if ! check_polkit_agent; then
                err "No Polkit authentication agent detected"
                err "Start one with: /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &"
                exit 1
            fi

            # Unlock with retry limit
            while true; do
                # Capture both stdout and stderr separately
                if unlock_output=$(udisksctl unlock --block-device "$outer_dev" 2>&1); then
                    log "$unlock_output"
                    break
                fi

                ((++unlock_attempts))

                if ((unlock_attempts >= MAX_UNLOCK_RETRIES)); then
                    err "Maximum unlock attempts ($MAX_UNLOCK_RETRIES) reached"
                    exit 1
                fi

                if ! check_polkit_agent; then
                    err "Polkit agent stopped running"
                    exit 1
                fi

                log "Attempt $unlock_attempts/$MAX_UNLOCK_RETRIES failed. Retrying..."
                [[ -n "$HINT" ]] && print_hint "$HINT"
            done

            # Wait for filesystem to appear (race condition fix)
            log "Waiting for filesystem to initialize..."
            if ! wait_for_device "$inner_dev" "$FILESYSTEM_TIMEOUT"; then
                err "Timeout waiting for filesystem (UUID: $INNER_UUID)"
                err "Check status with: lsblk -f"
                exit 1
            fi
        fi

        mount_dev="$inner_dev"
    else
        # SIMPLE drive
        mount_dev="/dev/disk/by-uuid/$OUTER_UUID"

        if ! is_block_device_ready "$mount_dev"; then
            err "Drive not found (UUID: $OUTER_UUID)"
            err "Is the drive connected? Check with: lsblk -f"
            exit 1
        fi
    fi

    # Mount the drive
    log "Mounting to $MOUNTPOINT..."

    local mount_error

    # Try udisksctl first (uses polkit, respects fstab)
    if mount_error=$(udisksctl mount --block-device "$mount_dev" 2>&1); then
        success "'$target' mounted at $MOUNTPOINT"
        return 0
    fi

    debug "udisksctl mount failed: $mount_error"

    # Fallback to sudo mount
    if mount_error=$(sudo mount "$MOUNTPOINT" 2>&1); then
        success "'$target' mounted at $MOUNTPOINT"
        return 0
    fi

    # Both methods failed
    err "Mount failed with udisksctl and sudo mount"
    err "Last error: $mount_error"
    err "Check /etc/fstab entry for $MOUNTPOINT"
    exit 1
}

# ------------------------------------------------------------------------------
#  LOCK FUNCTION
# ------------------------------------------------------------------------------
do_lock() {
    local target="$1"
    local outer_dev inner_dev unmount_target
    local retries=0

    log "Starting lock process for '$target'..."

    # Determine the block device being mounted (needed for udisksctl unmount)
    if [[ "$TYPE" == "PROTECTED" ]]; then
        outer_dev="/dev/disk/by-uuid/$OUTER_UUID"
        inner_dev="/dev/disk/by-uuid/$INNER_UUID"
        unmount_target="$inner_dev"
    else
        outer_dev=""  # Not used for simple drives
        unmount_target="/dev/disk/by-uuid/$OUTER_UUID"
    fi

    # Unmount phase
    if mountpoint -q "$MOUNTPOINT" 2>/dev/null; then
        log "Unmounting $MOUNTPOINT..."

        # Sync filesystems before unmount
        sync

        # 1. Try udisksctl first (polite request to Thunar/GVFS)
        if ! udisksctl unmount -b "$unmount_target" 2>/dev/null; then
            # 2. Fallback to sudo if udisks failed (e.g., not user mounted)
            log "Udisks unmount failed, trying sudo umount..."
            if ! sudo umount "$MOUNTPOINT"; then
                err "Unmount completely failed. Check 'lsof +f -- $MOUNTPOINT'"
                exit 1
            fi
        fi
        log "Unmount successful"
    else
        log "$MOUNTPOINT was not mounted"
    fi

    # Lock phase (PROTECTED only)
    if [[ "$TYPE" == "PROTECTED" ]]; then
        # Check if outer device still exists (wasn't physically removed)
        if [[ ! -e "$outer_dev" ]]; then
            success "Device removed physically. Done."
            return 0
        fi

        # Give kernel/udev time to update device tree after unmount
        sleep "$SETTLE_DELAY"

        # Wait for udev events to settle
        if command -v udevadm &>/dev/null; then
            udevadm settle --timeout=5 2>/dev/null || true
        fi

        # Check and lock the container
        # We verify by checking if TYPE="crypt" exists for this device
        while lsblk -n -r -o TYPE "$outer_dev" 2>/dev/null | grep -q "crypt"; do
            log "Locking container (Attempt $((retries + 1)))..."

            if udisksctl lock --block-device "$outer_dev" 2>/dev/null; then
                success "Encrypted container locked"
                return 0
            fi

            ((++retries))

            if ((retries >= LOCK_MAX_RETRIES)); then
                err "Could not lock device after $LOCK_MAX_RETRIES attempts."
                err "Mapper is still active. Is something else using /dev/mapper/..?"
                # Debug info on failure
                lsblk "$outer_dev" >&2
                exit 1
            fi

            sleep "$LOCK_RETRY_DELAY"
        done

        success "Container was already locked"
    else
        success "Simple drive '$target' unmounted"
    fi
}

# ------------------------------------------------------------------------------
#  MAIN
# ------------------------------------------------------------------------------
main() {
    # Handle no arguments
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    local action="${1:-}"
    local target="${2:-}"

    # Handle special actions that don't need target
    case "$action" in
        -h|--help|help)
            show_usage
            exit 0
            ;;
        status)
            check_dependencies
            show_status
            exit 0
            ;;
    esac

    # Validate we have both action and target for lock/unlock
    if [[ -z "$target" ]]; then
        err "Missing drive name for '$action' action"
        show_usage
        exit 1
    fi

    # Acquire exclusive lock for lock/unlock operations
    acquire_lock

    # Check dependencies
    check_dependencies

    # Validate and load config (sets TYPE, MOUNTPOINT, OUTER_UUID, INNER_UUID, HINT)
    validate_config "$target"

    # Execute action
    case "$action" in
        unlock)
            do_unlock "$target"
            ;;
        lock)
            do_lock "$target"
            ;;
        *)
            err "Unknown action: '$action'"
            show_usage
            exit 1
            ;;
    esac
}

# Run main with all arguments
main "$@"

exit 0
