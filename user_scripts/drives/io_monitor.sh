#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Script: io-monitor.sh
# Description: Full Disk I/O Dashboard (Educational Edition)
#              Shows RAM Buffers + Lifetime Totals + Instant Write Speed.
#              Supports CLI arguments for instant launch.
# Version: 6.0
# -----------------------------------------------------------------------------

# Strict Mode
set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true

# --- Configuration & ANSI Colors ---
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_CYAN=$'\033[0;36m'
readonly C_GREEN=$'\033[0;32m'
readonly C_RED=$'\033[0;31m'
readonly C_PURPLE=$'\033[0;35m'
readonly C_GREY=$'\033[0;90m'

# --- Trap & Cleanup ---
cleanup() {
    tput cnorm 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# --- Dependency Check ---
check_deps() {
    local -a deps=(iostat lsblk watch grep awk)
    local -a missing=()
    
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        printf "%s[Error] Missing dependencies: %s%s\n" "$C_RED" "${missing[*]}" "$C_RESET" >&2
        exit 1
    fi
}

# --- Drive Selection (Interactive) ---
select_drive() {
    local -a dev_list=()
    
    # Send UI to stderr
    {
        clear
        printf "%s%s:: Drive Selection ::%s\n" "$C_BOLD" "$C_CYAN" "$C_RESET"
        printf "%s%-10s %-10s %-10s %-20s%s\n" "$C_BOLD" "NAME" "SIZE" "TYPE" "MODEL" "$C_RESET"
        printf "%s%s%s\n" "$C_GREY" "--------------------------------------------------------" "$C_RESET"
    } >&2

    # Parse lsblk
    while read -r name size type model; do
        dev_list+=("$name")
        local formatted
        printf -v formatted "%-10s %-10s %-10s %-20s" "$name" "$size" "$type" "${model:-N/A}"
        printf "%s%s%s\n" "$C_GREEN" "$formatted" "$C_RESET" >&2
    done < <(lsblk -dno NAME,SIZE,TYPE,MODEL | grep -vE '^(loop|sr|ram|zram)')

    if (( ${#dev_list[@]} == 0 )); then
        printf "%s[Error] No physical drives detected.%s\n" "$C_RED" "$C_RESET" >&2
        exit 1
    fi

    printf "\n%sTarget Drive (e.g., sda): %s" "$C_BOLD" "$C_RESET" >&2
    
    local input
    if ! read -r -t 60 input; then
        printf "\n%s[Error] Timed out waiting for input.%s\n" "$C_RED" "$C_RESET" >&2
        exit 1
    fi

    input="${input#/dev/}"

    # Validate against list
    local valid=0
    for dev in "${dev_list[@]}"; do
        if [[ "$dev" == "$input" ]]; then
            valid=1
            break
        fi
    done

    if [[ $valid -eq 0 ]]; then
        printf "%s[Error] Invalid device name '%s'.%s\n" "$C_RED" "$input" "$C_RESET" >&2
        exit 1
    fi

    echo "$input"
}

# --- Main Logic ---
main() {
    check_deps
    
    local drive=""

    # Check if user provided an argument (e.g., ./io-monitor.sh sda)
    if [[ -n "${1:-}" ]]; then
        # Strip potential /dev/ prefix
        drive="${1#/dev/}"
        
        # Validate that it is a real block device
        if [[ ! -b "/dev/$drive" ]]; then
            printf "%s[Error] Device '/dev/%s' does not exist or is not a block device.%s\n" "$C_RED" "$drive" "$C_RESET" >&2
            exit 1
        fi
    else
        # No argument provided, launch interactive menu
        drive=$(select_drive)
    fi

    # Educational Command Strings (for display in dashboard)
    local cmd_ram="grep -E '^(Dirty|Writeback):' /proc/meminfo"
    local cmd_life="iostat -m -d /dev/${drive}"
    local cmd_inst="iostat -y -m -d /dev/${drive} 1 1"

    # Prepare Watch Command
    local cmd="
    # --- 1. MEMORY ---
    printf \"${C_BOLD}${C_CYAN}--- 1. System Write Buffer (RAM) --- ${C_RESET}${C_GREY}[ ${cmd_ram} ]${C_RESET}\n\"; 
    grep -E '^(Dirty|Writeback):' /proc/meminfo | awk '{printf \"  %-15s %.2f MB\n\", \$1, \$2/1024}'; 
    
    # --- 2. LIFETIME TOTALS ---
    printf \"\n${C_BOLD}${C_PURPLE}--- 2. Lifetime (Since Boot) --- ${C_RESET}${C_GREY}[ ${cmd_life} ]${C_RESET}\n\"; 
    iostat -m -d /dev/${drive} | grep -E '^(Device|${drive})';

    # --- 3. INSTANT SPEED ---
    printf \"\n${C_BOLD}${C_GREEN}--- 3. Instant Speed (Last 1s) --- ${C_RESET}${C_GREY}[ ${cmd_inst} ]${C_RESET}\n\"; 
    iostat -y -m -d /dev/${drive} 1 1 | grep '${drive}'
    "

    clear
    printf "%sInitializing Dashboard for /dev/%s...%s\n" "$C_GREEN" "$drive" "$C_RESET"
    sleep 0.5

    watch --color -t -d -n 1 "$cmd"
}

# Pass all arguments to main
main "${@}"
