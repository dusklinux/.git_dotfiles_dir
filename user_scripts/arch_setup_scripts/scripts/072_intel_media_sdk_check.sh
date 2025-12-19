#!/usr/bin/env bash
# ==============================================================================
#  INTEL MEDIA SDK SELECTOR (5th-11th Gen)
# ==============================================================================

# 1. Safety & Strict Mode
set -euo pipefail

# 2. Privileges Check
if [[ "$EUID" -ne 0 ]]; then
    printf "\e[0;31m[ERROR]\e[0m This script must be run as root.\n" >&2
    exit 1
fi

# 3. Colors (Using ANSI-C Quoting for immediate interpretation)
readonly GREEN=$'\e[0;32m'
readonly YELLOW=$'\e[0;33m'
readonly BLUE=$'\e[0;34m'
readonly BOLD=$'\e[1m'
readonly RESET=$'\e[0m'

detect_cpu_info() {
    printf "\n%s>>> SYSTEM CPU INFORMATION:%s\n" "${BLUE}" "${RESET}"
    if [[ -f /proc/cpuinfo ]]; then
        # Efficiently grab model name using pure bash/grep without heavy pipe chains
        grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs
    else
        lscpu | grep "Model name" || echo "Unknown CPU."
    fi
    printf "%s----------------------------------------%s\n\n" "${BLUE}" "${RESET}"
}

main() {
    printf "%s[INFO]%s Starting Intel Media SDK Compatibility Check...\n" "${BLUE}" "${RESET}"

    # ADDED: Auto-detect and show CPU info immediately for educated decision making
    detect_cpu_info

    while true; do
        # Using printf for consistency, generally safer than echo -e in strict scripts
        printf "%sDo you have an Intel CPU between 5th Gen and 11th Gen?%s\n" "${BOLD}" "${RESET}"
        printf "Options: [y]es, [n]o, [d]on't know\n"
        read -r -p "Select: " _choice

        case "${_choice,,}" in
            y|yes)
                printf "%s[RUN]%s Installing intel-media-sdk...\n" "${YELLOW}" "${RESET}"
                pacman -S --needed --noconfirm intel-media-sdk
                printf "%s[SUCCESS]%s Intel Media SDK installed.\n" "${GREEN}" "${RESET}"
                break
                ;;
            n|no)
                printf "%s[INFO]%s Skipping installation (Hardware not compatible/selected).\n" "${YELLOW}" "${RESET}"
                break
                ;;
            d|dont*|idk|*)
                # Kept this here as a fallback reminder if they select 'd'
                detect_cpu_info
                printf "%sTip: Look for the number after 'i3/i5/i7/i9'.%s\n" "${YELLOW}" "${RESET}"
                # Fixed typo below: {RESET} -> ${RESET}
                printf "Examples: i7-%s8%s550U (8th Gen), i5-%s11%s35G7 (11th Gen).\n\n" "${BOLD}" "${RESET}" "${BOLD}" "${RESET}"
                ;;
        esac
    done
}

main
