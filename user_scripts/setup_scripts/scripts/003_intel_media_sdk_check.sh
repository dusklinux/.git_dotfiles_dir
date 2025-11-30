#!/usr/bin/env bash
# ==============================================================================
#  INTEL MEDIA SDK SELECTOR (5th-11th Gen)
# ==============================================================================

# 1. Safety & Strict Mode
set -euo pipefail

# 2. Privileges Check
# This script performs a system installation (pacman), so it MUST be run as root.
if [[ "$EUID" -ne 0 ]]; then
    printf "\033[0;31m[ERROR]\033[0m This script must be run as root (S | ... in Orchestra).\n" >&2
    exit 1
fi

# 3. Colors (Local definition to ensure standalone functionality)
readonly GREEN="\033[0;32m"
readonly YELLOW="\033[0;33m"
readonly BLUE="\033[0;34m"
readonly BOLD="\033[1m"
readonly RESET="\033[0m"

detect_cpu_info() {
    printf "\n%s>>> SYSTEM CPU INFORMATION:%s\n" "${BLUE}" "${RESET}"
    if [[ -f /proc/cpuinfo ]]; then
        # Extract the model name, grab the first core, remove the label, trim whitespace
        grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs
    else
        echo "Unable to read /proc/cpuinfo. Attempting lscpu..."
        lscpu | grep "Model name" || echo "Unknown CPU."
    fi
    printf "%s----------------------------------------%s\n\n" "${BLUE}" "${RESET}"
}

main() {
    printf "%s[INFO]%s Starting Intel Media SDK Compatibility Check...\n" "${BLUE}" "${RESET}"

    while true; do
        echo -e "${BOLD}Do you have an Intel CPU between 5th Gen and 11th Gen?${RESET}"
        echo -e "Options: [y]es, [n]o, [d]on't know"
        read -r -p "Select: " _choice

        case "${_choice,,}" in
            y|yes)
                printf "%s[RUN]%s Installing intel-media-sdk...\n" "${YELLOW}" "${RESET}"
                # --needed skips if already up to date, --noconfirm for script flow
                pacman -S --needed --noconfirm intel-media-sdk
                printf "%s[SUCCESS]%s Intel Media SDK installed.\n" "${GREEN}" "${RESET}"
                break
                ;;
            n|no)
                printf "%s[INFO]%s Skipping installation (Hardware not compatible/selected).\n" "${YELLOW}" "${RESET}"
                break
                ;;
            d|dont*|idk|*)
                # Handle "I don't know" or invalid input by showing info and looping
                detect_cpu_info
                echo -e "${YELLOW}Tip: Look for the number after 'i3/i5/i7/i9'.${RESET}"
                echo -e "Examples: i7-${BOLD}8{RESET}550U (8th Gen), i5-${BOLD}11{RESET}35G7 (11th Gen).\n"
                ;;
        esac
    done
}

main
