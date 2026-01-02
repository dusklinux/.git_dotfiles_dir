#!/bin/bash

# ==============================================================================
# net-sentry.sh
# Elite Network Discovery & Monitoring Tool for Arch Linux
# Wraps arp-scan to provide live connection tracking and inventory.
# ==============================================================================

# --- Strict Mode ---
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error when substituting.
# -o pipefail: pipeline return status is the value of the last (failed) command.
set -euo pipefail

# --- Constants & Styles ---
readonly C_RESET=$'\e[0m'
readonly C_BOLD=$'\e[1m'
readonly C_DIM=$'\e[2m'
readonly C_RED=$'\e[31m'
readonly C_GREEN=$'\e[32m'
readonly C_YELLOW=$'\e[33m'
readonly C_BLUE=$'\e[34m'
readonly C_CYAN=$'\e[36m'
readonly C_MAGENTA=$'\e[35m'
readonly C_WHITE=$'\e[37m'

readonly DEPENDENCIES=("arp-scan")

# --- Signal Trapping ---
cleanup() {
    # If we are in the alternate screen buffer (some terms), this helps resets
    # But mostly just a clean exit message.
    printf "\n%s[*] Scan interrupted. Exiting.%s\n" "${C_CYAN}" "${C_RESET}" >&2
    exit 0
}
trap cleanup SIGINT SIGTERM

# --- Pre-flight Checks ---

# Self-elevate to root if not already running as root
if [[ $EUID -ne 0 ]]; then
    printf "%s%s[*]%s Root privileges required for packet injection.\n" "${C_CYAN}" "${C_BOLD}" "${C_RESET}"
    
    if ! command -v sudo &>/dev/null; then
        printf "%s%sError:%s 'sudo' not found. Cannot elevate privileges.\n" "${C_RED}" "${C_BOLD}" "${C_RESET}" >&2
        exit 1
    fi

    printf "%sRe-executing with sudo...%s\n\n" "${C_DIM}" "${C_RESET}"
    exec sudo --preserve-env=HOME "$0" "$@"
    # exec replaces the process. We should never reach here unless sudo failed to exec.
    exit 1
fi

# --- Dependency Management ---

install_dependencies() {
    local missing=()
    local dep
    
    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        return 0
    fi
    
    printf "%s%s[*]%s Missing dependencies detected: %s%s%s\n" \
        "${C_YELLOW}" "${C_BOLD}" "${C_RESET}" \
        "${C_CYAN}" "${missing[*]}" "${C_RESET}"
    
    printf "%sInstalling via pacman...%s\n\n" "${C_DIM}" "${C_RESET}"
    
    if ! pacman -S --needed --noconfirm "${missing[@]}"; then
        printf "\n%s%sError:%s Failed to install dependencies.\n" "${C_RED}" "${C_BOLD}" "${C_RESET}" >&2
        printf "Try running manually: %ssudo pacman -S %s%s\n" "${C_BOLD}" "${missing[*]}" "${C_RESET}" >&2
        exit 1
    fi
    
    printf "\n%s%s[✓]%s Dependencies installed successfully.\n\n" "${C_GREEN}" "${C_BOLD}" "${C_RESET}"
}

install_dependencies

# --- Variables ---
INTERFACE=""
DURATION=0
MODE="" # Empty to trigger menu
INTERVAL=2
START_TIME=$SECONDS

# --- Functions ---

usage() {
    cat <<EOF
${C_BOLD}Usage:${C_RESET} ${0##*/} [OPTIONS]

  no arguments - Launch Interactive Menu

  ${C_BOLD}Options:${C_RESET}
  -i <iface>   Specify network interface (default: auto-detect)
  -l           Live Dashboard: Continuous refreshing list (Like 'top')
  -m           Monitor Mode: Log events when devices Join/Leave
  -q           Quick Scan: Force single scan (skip menu)
  -t <seconds> Duration: Stop scanning after X seconds (default: infinite)
  -s <seconds> Interval: Seconds between scans (default: 2)
  -h           Show this help

${C_BOLD}Examples:${C_RESET}
  ${0##*/}                 # Interactive Menu
  ${0##*/} -q              # Single quick scan
  ${0##*/} -l              # Continuous Dashboard
  ${0##*/} -m              # Track history (Joins/Leaves)

EOF
    exit 0
}

get_default_interface() {
    # LC_ALL=C ensures 'ip' output is in English (e.g., searches for "default" not "Standard")
    LC_ALL=C ip route show default 2>/dev/null | awk '
        /^default/ {
            for (i = 1; i <= NF; i++) {
                if ($i == "dev" && i < NF) { print $(i+1); exit }
            }
        }'
}

# Uses the user-specified format for strictly deterministic parsing
# Format: IP [tab] MAC [tab] Vendor
scan_network() {
    LC_ALL=C arp-scan --interface="$INTERFACE" --localnet --ignoredups --plain \
        --format='${ip}\t${mac}\t${vendor}' 2>/dev/null
}

print_header() {
    printf "${C_BOLD}%-16s %-20s %-30s${C_RESET}\n" "IP Address" "MAC Address" "Vendor"
    printf "${C_DIM}────────────────────────────────────────────────────────────────${C_RESET}\n"
}

# --- Argument Parsing ---
while getopts ":i:t:s:mlqh" opt; do
    case ${opt} in
        i) INTERFACE=$OPTARG ;;
        t) DURATION=$OPTARG ;;
        s) INTERVAL=$OPTARG ;;
        m) MODE="monitor" ;;
        l) MODE="live" ;;
        q) MODE="scan" ;; # Quick scan flag
        h) usage ;;
        :) 
            printf "%sError:%s Option -%s requires an argument.\n" "${C_RED}" "${C_RESET}" "${OPTARG}" >&2
            exit 1 
            ;;
        \?) 
            printf "%sError:%s Invalid option: -%s\n" "${C_RED}" "${C_RESET}" "${OPTARG}" >&2
            exit 1 
            ;;
    esac
done
# Shift positional arguments to allow handling non-flag args later if needed
shift $((OPTIND - 1))

# --- Input Validation ---

if ! [[ "$DURATION" =~ ^[0-9]+$ ]]; then
    printf "%sError:%s Duration (-t) must be a non-negative integer.\n" "${C_RED}" "${C_RESET}" >&2
    exit 1
fi

if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [[ "$INTERVAL" -eq 0 ]]; then
    printf "%sError:%s Interval (-s) must be a positive integer.\n" "${C_RED}" "${C_RESET}" >&2
    exit 1
fi

if [[ -z "$INTERFACE" ]]; then
    INTERFACE=$(get_default_interface)
    if [[ -z "$INTERFACE" ]]; then
        printf "%sError:%s Could not auto-detect network interface.\n" "${C_RED}" "${C_RESET}" >&2
        printf "Please specify one using %s-i <iface>%s.\n" "${C_BOLD}" "${C_RESET}" >&2
        exit 1
    fi
fi

if [[ ! -e "/sys/class/net/${INTERFACE}" ]]; then
    printf "%sError:%s Interface '%s' does not exist.\n" "${C_RED}" "${C_RESET}" "${INTERFACE}" >&2
    exit 1
fi

# --- Main Logic ---

# === Interactive Menu ===
# If no mode was set via flags, prompt the user
if [[ -z "$MODE" ]]; then
    printf "\n%s%s::%s Select Operation Mode:%s\n" "${C_CYAN}" "${C_BOLD}" "${C_RESET}" "${C_BOLD}"
    printf "   %s1)%s Single Scan     %s(Quick snapshot)%s\n" "${C_CYAN}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    printf "   %s2)%s Live Dashboard  %s(Real-time list)%s\n" "${C_CYAN}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    printf "   %s3)%s Monitor Mode    %s(Log joins/leaves)%s\n" "${C_CYAN}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    printf "\n"
    
    # || choice="" handles Ctrl+D (EOF) gracefully under set -u
    read -r -p "${C_BOLD}Enter choice [1-3]: ${C_RESET}" choice || choice=""

    case "$choice" in
        2) MODE="live" ;;
        3) MODE="monitor" ;;
        *) MODE="scan" ;; # Default catch-all
    esac
    printf "\n"
fi

# Execute Selected Mode
if [[ "$MODE" == "scan" ]]; then
    # === Standard Single Scan ===
    printf "%s%s::%s Initializing Net-Sentry on %s%s%s...\n" "${C_CYAN}" "${C_BOLD}" "${C_RESET}" "${C_MAGENTA}" "${INTERFACE}" "${C_RESET}"
    printf "%sPerforming comprehensive ARP sweep...%s\n\n" "${C_DIM}" "${C_RESET}"
    
    print_header
    
    host_count=0
    while IFS=$'\t' read -r ip mac vendor; do
        if [[ -n "$ip" && -n "$mac" ]]; then
            printf "${C_GREEN}%-16s${C_RESET} ${C_YELLOW}%-20s${C_RESET} ${C_BLUE}%-30s${C_RESET}\n" "$ip" "$mac" "$vendor"
            # Prefix increment to avoid exit code 1 when host_count is 0 under set -e
            ((++host_count))
        fi
    done < <(scan_network)

    echo ""
    printf "%s[*] Scan Complete: %d host(s) found.%s\n" "${C_CYAN}" "$host_count" "${C_RESET}"

elif [[ "$MODE" == "live" ]]; then
    # === Live Dashboard Mode ===
    
    while true; do
        # Check Duration
        if [[ $DURATION -gt 0 && $(( SECONDS - START_TIME )) -ge $DURATION ]]; then
            printf "%s[*] Time limit reached. Exiting.%s\n" "${C_CYAN}" "${C_RESET}"
            exit 0
        fi

        # Clear screen (ANSI) and move cursor to top-left
        printf "\033[2J\033[H"
        
        TS=$(date +'%H:%M:%S')
        printf "%s%s::%s Net-Sentry Live View [%s] on %s%s%s\n" "${C_CYAN}" "${C_BOLD}" "${C_RESET}" "$TS" "${C_MAGENTA}" "${INTERFACE}" "${C_RESET}"
        printf "%sRefreshing every %ss. Press Ctrl+C to stop.%s\n\n" "${C_DIM}" "$INTERVAL" "${C_RESET}"

        print_header

        host_count=0
        while IFS=$'\t' read -r ip mac vendor; do
            if [[ -n "$ip" && -n "$mac" ]]; then
                printf "${C_GREEN}%-16s${C_RESET} ${C_YELLOW}%-20s${C_RESET} ${C_BLUE}%-30s${C_RESET}\n" "$ip" "$mac" "$vendor"
                ((++host_count))
            fi
        done < <(scan_network)

        printf "\n%sTotal Hosts: %d%s" "${C_WHITE}" "$host_count" "${C_RESET}"
        
        sleep "$INTERVAL"
    done

else
    # === Monitor Mode (Event Logging) ===
    printf "%s%s::%s Initializing Live Monitor on %s%s%s...\n" "${C_CYAN}" "${C_BOLD}" "${C_RESET}" "${C_MAGENTA}" "${INTERFACE}" "${C_RESET}"
    printf "%s[*] Press Ctrl+C to stop.%s\n\n" "${C_DIM}" "${C_RESET}"
    
    declare -A known_hosts=()
    declare -A current_scan=()
    first_run=true

    while true; do
        if [[ $DURATION -gt 0 && $(( SECONDS - START_TIME )) -ge $DURATION ]]; then
            printf "%s[*] Time limit reached. Exiting.%s\n" "${C_CYAN}" "${C_RESET}"
            break
        fi

        TS=$(date +'%H:%M:%S')

        # Reset Current Scan
        # We unset and re-declare to ensure it's empty
        unset current_scan
        declare -A current_scan

        # 1. Scan
        while IFS=$'\t' read -r ip mac vendor; do
            if [[ -n "$mac" ]]; then
                current_scan["$mac"]="$ip|$vendor"
            fi
        done < <(scan_network)

        # 2. First Run Baseline
        if [[ "$first_run" == true ]]; then
            count=${#current_scan[@]}
            printf "%s[%s] Initial baseline established: %d hosts online.%s\n" "${C_DIM}" "$TS" "$count" "${C_RESET}"
            for mac in "${!current_scan[@]}"; do
                known_hosts["$mac"]="${current_scan[$mac]}"
                IFS='|' read -r ip vendor <<< "${current_scan[$mac]}"
                printf "    %s%-15s %-17s %s%s\n" "${C_DIM}" "$ip" "$mac" "$vendor" "${C_RESET}"
            done
            first_run=false
            sleep "$INTERVAL"
            continue
        fi

        # 3. Check for NEW
        for mac in "${!current_scan[@]}"; do
            # Use ${var:-} to default to empty if unset, safe for set -u
            if [[ -z "${known_hosts[$mac]:-}" ]]; then
                IFS='|' read -r ip vendor <<< "${current_scan[$mac]}"
                printf "%s[%s] [+] DEVICE JOINED:%s %s (%s) - %s\n" "${C_GREEN}" "$TS" "${C_RESET}" "$ip" "$mac" "$vendor"
                known_hosts["$mac"]="${current_scan[$mac]}"
            fi
        done

        # 4. Check for LOST
        for mac in "${!known_hosts[@]}"; do
            if [[ -z "${current_scan[$mac]:-}" ]]; then
                IFS='|' read -r ip vendor <<< "${known_hosts[$mac]}"
                printf "%s[%s] [-] DEVICE LEFT:  %s %s (%s) - %s\n" "${C_RED}" "$TS" "${C_RESET}" "$ip" "$mac" "$vendor"
                
                unset "known_hosts[$mac]"
            fi
        done

        sleep "$INTERVAL"
    done
fi
