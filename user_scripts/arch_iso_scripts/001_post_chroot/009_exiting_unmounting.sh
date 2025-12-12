#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script Name: 05-finish-install.sh
# Description: Final instruction set for Arch Linux installation.
#              Displays critical post-install manual steps for the user.
# Author:      Arch Linux System Architect
# -----------------------------------------------------------------------------

# 1. Safety & Environment
# -----------------------
set -euo pipefail

# [FIX] Sanitize Terminal Environment
# If the current terminal type is unknown (e.g., xterm-kitty in a minimal chroot),
# fallback to generic 'xterm' to prevent 'clear' or 'tput' from crashing.
if ! tput longname &>/dev/null; then
    export TERM=xterm
fi

# 2. Visual Configuration (Modern Bash)
# -------------------------------------
# ANSI Color Codes
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_GREEN=$'\033[1;32m'
readonly C_CYAN=$'\033[1;36m'
readonly C_YELLOW=$'\033[1;33m'
readonly C_RED=$'\033[1;31m'
readonly C_WHITE=$'\033[1;37m'

# 3. Helper Functions
# -------------------
print_banner() {
    printf "\n%b%s%b\n" "${C_GREEN}${C_BOLD}" "========================================" "${C_RESET}"
    printf "%b%s%b\n"   "${C_GREEN}${C_BOLD}" "   ARCH LINUX INSTALLATION COMPLETE     " "${C_RESET}"
    printf "%b%s%b\n"   "${C_GREEN}${C_BOLD}" "========================================" "${C_RESET}"
}

print_step() {
    local step_num="$1"
    local cmd="$2"
    local desc="$3"
    
    printf "\n%b[Step %s]%b %s\n" "${C_CYAN}" "${step_num}" "${C_RESET}" "${desc}"
    printf "   %b$ %b%s%b\n" "${C_WHITE}" "${C_YELLOW}${C_BOLD}" "${cmd}" "${C_RESET}"
}

print_warning() {
    printf "\n%b[!] CRITICAL WARNING:%b %s\n" "${C_RED}${C_BOLD}" "${C_RESET}" "$1"
}

# 4. Main Execution Logic
# -----------------------
main() {
    # Clear screen for readability
    clear

    print_banner

    printf "\nThe automated portion of the installation is finished.\n"
    printf "Please perform the following steps %bMANUALLY%b to ensure filesystem integrity.\n" "${C_BOLD}" "${C_RESET}"

    # Step 1: Exit Chroot
    print_step "1" "exit" "Return to the live ISO environment."
    printf "   %b(Note: make sure the "root@archiso" changes slightly indicating it exited.)%b\n" "${C_WHITE}" "${C_RESET}"

    # Step 2: Unmount
    print_step "2" "umount -R /mnt" "Unmount all partitions cleanly to flush changes to disk."
    print_warning "Failure to unmount before poweroff may result in data corruption."

    # Step 3: Poweroff
    print_step "3" "poweroff" "Shutdown the system."

    # Final Reminder
    printf "\n%b%s%b\n" "${C_CYAN}" "----------------------------------------" "${C_RESET}"
    printf "%b NEXT STEPS:%b\n" "${C_WHITE}${C_BOLD}" "${C_RESET}"
    printf " 1. Wait for the system to fully power down.\n"
    printf " 2. %bREMOVE the USB Installation Media.%b\n" "${C_RED}${C_BOLD}" "${C_RESET}"
    printf " 3. Power on the machine to boot into your new Arch Hyprland system.\n"
    printf " 4. Enter your username and password to start hyprland after booting.\n"
    printf "%b%s%b\n\n" "${C_CYAN}" "----------------------------------------" "${C_RESET}"
}

# Execute Main
main
