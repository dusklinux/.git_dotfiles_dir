#!/usr/bin/env bash
# ==============================================================================
#  ARCH LINUX PACKAGE CACHE CLEANER & STORAGE OPTIMIZER
# ==============================================================================
#  Description: Aggressively cleans Pacman and Paru caches.
#               Calculates and displays storage reclaimed.
#  Mode:        Run as USER (U). Elevates internally for Pacman.
# ==============================================================================

# 1. STRICT MODE
set -euo pipefail
IFS=$'\n\t'

# 2. GLOBAL VARIABLES
declare -g _CLEANUP_RAN=""
declare -g _SUDO_PID=""

# Storage tracking variables
declare -g ROOT_PART_DEVICE=""
declare -g HOME_PART_DEVICE=""
declare -g START_USED_ROOT=0
declare -g START_USED_HOME=0

# 3. COLOR INITIALIZATION (Safe TTY Check)
init_colors() {
    if [[ -t 1 ]]; then
        readonly R=$(tput setaf 1)
        readonly G=$(tput setaf 2)
        readonly Y=$(tput setaf 3)
        readonly B=$(tput setaf 4)
        readonly BOLD=$(tput bold)
        readonly RESET=$(tput sgr0)
    else
        readonly R="" G="" Y="" B="" BOLD="" RESET=""
    fi
}

# 4. UTILITY FUNCTIONS
log_task()    { printf "%s[TASK]%s    %s\n" "$B" "$RESET" "$*"; }
log_success() { printf "%s[SUCCESS]%s %s\n" "$G" "$RESET" "$*"; }
log_warn()    { printf "%s[WARN]%s    %s\n" "$Y" "$RESET" "$*"; }
log_error()   { printf "%s[ERROR]%s   %s\n" "$R" "$RESET" "$*" >&2; }

# Converts bytes to human readable format (GiB/MiB)
format_bytes() {
    local bytes="$1"
    if (( bytes > 1073741824 )); then
        awk -v val="$bytes" 'BEGIN {printf "%.2f GiB", val / 1073741824}'
    elif (( bytes > 1048576 )); then
        awk -v val="$bytes" 'BEGIN {printf "%.2f MiB", val / 1048576}'
    else
        awk -v val="$bytes" 'BEGIN {printf "%.2f KiB", val / 1024}'
    fi
}

# Gets used bytes for a specific path's filesystem
get_fs_used_bytes() {
    # df output in bytes (-B1), grab the 'Used' column
    df -B1 --output=used "$1" 2>/dev/null | tail -n1
}

# Gets the device name (e.g., /dev/nvme0n1p2) for a path to check partition equality
get_device_name() {
    df --output=source "$1" 2>/dev/null | tail -n1
}

capture_start_stats() {
    # Determine if Root and Home are separate partitions
    ROOT_PART_DEVICE=$(get_device_name "/var/cache/pacman/pkg")
    HOME_PART_DEVICE=$(get_device_name "$HOME/.cache")
    
    START_USED_ROOT=$(get_fs_used_bytes "/var/cache/pacman/pkg")
    
    # Only track Home separately if it's a different device
    if [[ "$ROOT_PART_DEVICE" != "$HOME_PART_DEVICE" ]]; then
        START_USED_HOME=$(get_fs_used_bytes "$HOME/.cache")
    fi
}

calculate_freed_stats() {
    local end_used_root
    local end_used_home
    local freed_root=0
    local freed_home=0
    local total_freed=0

    end_used_root=$(get_fs_used_bytes "/var/cache/pacman/pkg")
    freed_root=$(( START_USED_ROOT - end_used_root ))
    
    # Sanity check: if negative (something wrote to disk), treat as 0 freed
    (( freed_root < 0 )) && freed_root=0

    if [[ "$ROOT_PART_DEVICE" != "$HOME_PART_DEVICE" ]]; then
        end_used_home=$(get_fs_used_bytes "$HOME/.cache")
        freed_home=$(( START_USED_HOME - end_used_home ))
        (( freed_home < 0 )) && freed_home=0
    fi

    total_freed=$(( freed_root + freed_home ))

    printf "\n%s==================================================%s\n" "$G" "$RESET"
    printf "%s             STORAGE REPORT                       %s\n" "$G" "$RESET"
    printf "%s==================================================%s\n" "$G" "$RESET"
    
    if [[ "$ROOT_PART_DEVICE" == "$HOME_PART_DEVICE" ]]; then
         printf "Partition (Root+Home):  %s -> %s  (Freed: %s%s%s)\n" \
            "$(format_bytes "$START_USED_ROOT")" \
            "$(format_bytes "$end_used_root")" \
            "$BOLD" "$(format_bytes "$total_freed")" "$RESET"
    else
        printf "Root Partition:         %s -> %s  (Freed: %s)\n" \
            "$(format_bytes "$START_USED_ROOT")" \
            "$(format_bytes "$end_used_root")" \
            "$(format_bytes "$freed_root")"
            
        printf "Home Partition:         %s -> %s  (Freed: %s)\n" \
            "$(format_bytes "$START_USED_HOME")" \
            "$(format_bytes "$end_used_home")" \
            "$(format_bytes "$freed_home")"
            
        printf "\n%sTOTAL RECLAIMED:%s        %s%s%s\n" "$BOLD" "$RESET" "$G" "$(format_bytes "$total_freed")" "$RESET"
    fi
    printf "%s==================================================%s\n\n" "$G" "$RESET"
}

# 5. CLEANUP HANDLER
cleanup() {
    local exit_code=$?
    
    # Idempotency check
    if [[ -n "${_CLEANUP_RAN:-}" ]]; then return "$exit_code"; fi
    _CLEANUP_RAN=1

    # Kill background sudo keeper
    if [[ -n "${_SUDO_PID:-}" ]] && kill -0 "$_SUDO_PID" 2>/dev/null; then
        kill "$_SUDO_PID" 2>/dev/null || true
    fi

    # Reset cursor
    tput cnorm 2>/dev/null || true

    if [[ $exit_code -ne 0 ]]; then
        printf "\n%s[ERROR] Script exited with code %d%s\n" "$R" "$exit_code" "$RESET" >&2
    fi
}
trap cleanup EXIT INT TERM HUP

# 6. SUDO KEEPER
start_sudo_keeper() {
    (
        # Loop runs only while sudo is valid. If credentials expire, it exits.
        while sudo -n true 2>/dev/null; do
            sleep 50
            kill -0 "$$" 2>/dev/null || exit 0
        done
    ) &
    _SUDO_PID=$!
    disown "$_SUDO_PID"
}

# ==============================================================================
#  MAIN EXECUTION
# ==============================================================================

init_colors

# Privilege Check
if [[ "$EUID" -eq 0 ]]; then
    log_error "This script must be run as a NORMAL USER (Orchestrator Mode: 'U')."
    log_error "Paru refuses to run as root. Script handles elevation internally."
    exit 1
fi

# Sudo Auth
log_task "Checking sudo permissions for Pacman..."
if ! sudo -v; then
    log_error "Sudo authentication failed."
    exit 1
fi
start_sudo_keeper

clear
printf "\n%s==================================================%s\n" "$B" "$RESET"
printf "%s   SYSTEM STORAGE RECLAMATION (CACHE CLEANER)   %s\n" "$B" "$RESET"
printf "%s==================================================%s\n" "$B" "$RESET"
printf "%s[NOTE] This will remove ALL cached packages.%s\n\n" "$Y" "$RESET"

# 1. Capture Stats
log_task "Calculating current storage usage..."
capture_start_stats
sleep 1

# 2. Pacman Clean
if command -v pacman &>/dev/null; then
    log_task "Cleaning Pacman Cache..."
    # -Scc: Clean cache. --noconfirm: Answer yes automatically.
    if sudo pacman -Scc --noconfirm; then
        log_success "Pacman cache cleared."
    else
        log_warn "Pacman cache clean reported an issue (or was empty)."
    fi
else
    log_warn "Pacman not found."
fi

sleep 1

# 3. Paru Clean
if command -v paru &>/dev/null; then
    log_task "Cleaning Paru (AUR) Cache..."
    if paru -Scc --noconfirm; then
        log_success "Paru cache cleared."
    else
        log_warn "Paru cache clean reported an issue (or was empty)."
    fi
else
    log_warn "Paru not found. Skipping."
fi

sleep 1

# 4. Final Stats
calculate_freed_stats
