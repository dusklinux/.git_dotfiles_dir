#!/usr/bin/env bash
#
# Name: fixntfs
# Description: Robust NTFS repair tool for Arch/Hyprland (Supports BitLocker/LUKS)
# Author: Elite DevOps
# Dependencies: ntfs-3g, cryptsetup, util-linux
#
# Features:
# - Handles Spaces in Labels correctly (via lsblk --pairs)
# - Robust Trap/Cleanup for temporary mappings
# - Privilege escalation handling
# - Colored output for Hyprland/UWSM environments
#

# --- Strict Mode ---
set -euo pipefail

# --- Configuration ---
# ANSI Colors
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_RED=$'\033[31m'
readonly C_GREEN=$'\033[32m'
readonly C_YELLOW=$'\033[33m'
readonly C_BLUE=$'\033[34m'
readonly C_CYAN=$'\033[36m'
readonly C_GRAY=$'\033[90m'

# Temporary Mapper Name (Randomized to prevent collisions)
readonly TMP_MAPPER="ntfs_repair_$(date +%s)"
readonly TMP_MAPPER_PATH="/dev/mapper/${TMP_MAPPER}"

# --- Data Stores ---
declare -a CAND_DEV=()
declare -a CAND_FS=()
declare -a CAND_LABEL=()
declare -a CAND_SIZE=()
declare -a CAND_MOUNT=()

# --- Privilege Check ---
if [[ $EUID -ne 0 ]]; then
    printf '%s[INFO] Elevating permissions for hardware access...%s\n' "${C_GRAY}" "${C_RESET}"
    exec sudo "$0" "$@"
fi

# --- Cleanup Trap ---
# Ensures mapper is closed even if script crashes or user Ctrl+C
cleanup() {
    local exit_code=$?
    if [[ -e "${TMP_MAPPER_PATH}" ]]; then
        printf '\n%s[CLEANUP] Closing temporary container...%s\n' "${C_GRAY}" "${C_RESET}"
        # Suppress error if already closed
        cryptsetup close "${TMP_MAPPER}" 2>/dev/null || true
    fi
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

# --- Helpers ---
log_info() { printf '%s[INFO]%s %s\n' "${C_BLUE}" "${C_RESET}" "$1"; }
log_succ() { printf '%s[OK]%s   %s\n' "${C_GREEN}" "${C_RESET}" "$1"; }
log_warn() { printf '%s[WARN]%s %s\n' "${C_YELLOW}" "${C_RESET}" "$1"; }
log_err()  { printf '%s[ERR]%s  %s\n' "${C_RED}" "${C_RESET}" "$1" >&2; exit 1; }

check_deps() {
    local cmd
    local -a deps=(ntfsfix lsblk cryptsetup)
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_err "Missing dependency: '$cmd'. Please install 'ntfs-3g' and 'cryptsetup'."
        fi
    done
}

# --- Core Logic ---

scan_drives() {
    local line name fstype label size mountpoint

    # Use --pairs to safely handle spaces in labels (e.g. LABEL="My Drive")
    # Redirect stderr to devnull to hide irrelevant lsblk warnings
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        # Reset vars
        name="" fstype="" label="" size="" mountpoint=""

        # Regex Parsing of Key="Value" pairs
        [[ $line =~ NAME=\"([^\"]*)\" ]] && name="${BASH_REMATCH[1]}"
        [[ $line =~ FSTYPE=\"([^\"]*)\" ]] && fstype="${BASH_REMATCH[1]}"
        [[ $line =~ LABEL=\"([^\"]*)\" ]] && label="${BASH_REMATCH[1]}"
        [[ $line =~ SIZE=\"([^\"]*)\" ]] && size="${BASH_REMATCH[1]}"
        [[ $line =~ MOUNTPOINT=\"([^\"]*)\" ]] && mountpoint="${BASH_REMATCH[1]}"

        # Filter Logic
        case "$fstype" in
            ntfs|BitLocker|crypto_LUKS)
                CAND_DEV+=("$name")
                CAND_FS+=("$fstype")
                CAND_LABEL+=("$label")
                CAND_SIZE+=("$size")
                CAND_MOUNT+=("$mountpoint")
                ;;
        esac
    done < <(lsblk -pn -o NAME,FSTYPE,LABEL,SIZE,MOUNTPOINT --pairs 2>/dev/null)

    if [[ ${#CAND_DEV[@]} -eq 0 ]]; then
        log_err "No NTFS, BitLocker, or LUKS partitions found on this system."
    fi
}

repair_volume() {
    local target="$1"
    
    printf '\n%s[REPAIR] Running ntfsfix on %s...%s\n' "${C_CYAN}" "$target" "${C_RESET}"
    
    # -b: Clear bad sector list (force re-check)
    # -d: Clear dirty flag (fixes "The disk contains an unclean file system")
    if ntfsfix -b -d "$target"; then
        printf '\n'
        log_succ "Volume marked clean. Fast Startup/Hibernation flags cleared."
    else
        printf '\n'
        log_err "ntfsfix failed. The drive might need a full Windows chkdsk /f."
    fi
}

handle_locked() {
    local device="$1"
    local type="$2"
    local inner_fs
    local -a crypt_args=(open "$device" "$TMP_MAPPER")

    log_info "Locked container detected ($type). Unlocking temporarily..."
    
    # Specific handling for BitLocker
    [[ "$type" == "BitLocker" ]] && crypt_args+=(--type bitlk)

    # Let cryptsetup handle the password prompt securely
    if cryptsetup "${crypt_args[@]}"; then
        log_succ "Container unlocked to: ${TMP_MAPPER_PATH}"
        
        # Check what is INSIDE the container
        inner_fs=$(lsblk -no FSTYPE "${TMP_MAPPER_PATH}" 2>/dev/null) || inner_fs=""
        
        if [[ "$inner_fs" == "ntfs" ]]; then
            repair_volume "${TMP_MAPPER_PATH}"
        else
            log_warn "The unlocked container holds '$inner_fs', not NTFS. Skipping repair."
        fi
    else
        log_err "Failed to unlock container."
    fi
}

# --- Main Execution ---

main() {
    check_deps
    
    printf '\n%s=== NTFS Dirty Bit Fixer ===%s\n' "${C_BOLD}${C_BLUE}" "${C_RESET}"
    scan_drives

    local count=${#CAND_DEV[@]}
    local i
    
    printf '\n%sAvailable Drives:%s\n\n' "${C_BOLD}" "${C_RESET}"
    
    # C-Style loop prevents the "((i++))" set -e crash if index is 0
    for ((i = 0; i < count; i++)); do
        local d_label="${CAND_LABEL[i]:-No Label}"
        local d_mount="${CAND_MOUNT[i]}"
        local d_fs="${CAND_FS[i]}"
        local status_color="${C_GREEN}"
        
        # Color logic
        if [[ "$d_fs" == "BitLocker" ]] || [[ "$d_fs" == "crypto_LUKS" ]]; then
            status_color="${C_YELLOW}"
            d_mount="[LOCKED]"
        elif [[ -n "$d_mount" ]]; then
            status_color="${C_RED}"
        fi
        
        # Print formatted row
        printf '  %s%2d)%s %-10s │ %-12s │ %-15s │ %s%s%s\n' \
            "${C_BOLD}" "$((i + 1))" "${C_RESET}" \
            "${CAND_SIZE[i]}" \
            "${d_fs}" \
            "${d_label:0:15}" \
            "${status_color}" "${d_mount:--}" "${C_RESET}"
    done

    printf '\n'
    local selection
    read -rp "${C_BOLD}Select Drive to Fix (1-${count}): ${C_RESET}" selection

    # Validation
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || ((selection < 1 || selection > count)); then
        log_err "Invalid selection."
    fi

    # Map selection to array index
    local idx=$((selection - 1))
    local target_dev="${CAND_DEV[idx]}"
    local target_fs="${CAND_FS[idx]}"
    local target_mount="${CAND_MOUNT[idx]}"

    # Unmount logic (Mount point is safer than dev path)
    if [[ -n "$target_mount" ]]; then
        log_warn "Volume is mounted at: $target_mount"
        local confirm
        read -rp "Unmount to proceed? [y/N] " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            # Try unmounting by mountpoint first
            if umount "$target_mount" 2>/dev/null; then
                log_succ "Unmounted successfully."
            else
                log_err "Failed to unmount. Close any apps using the drive."
            fi
        else
            log_err "Aborted by user."
        fi
    fi

    # Dispatcher
    case "$target_fs" in
        BitLocker|crypto_LUKS)
            handle_locked "$target_dev" "$target_fs"
            ;;
        *)
            repair_volume "$target_dev"
            ;;
    esac

    printf '\n'
    log_succ "Operation complete."
}

main "$@"
