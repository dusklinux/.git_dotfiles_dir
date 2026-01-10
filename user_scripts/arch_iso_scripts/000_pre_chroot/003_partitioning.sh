#!/usr/bin/env bash
# ==============================================================================
# MODULE: INTERACTIVE DISK PARTITIONING
# Context: Arch ISO Environment
# Dependency: 'cfdisk' (part of util-linux)
# ==============================================================================

# --- 1. SETTINGS & SAFETY ---
set -euo pipefail

# Visual Constants
readonly C_BOLD=$'\033[1m'
readonly C_RED=$'\033[31m'
readonly C_GREEN=$'\033[32m'
readonly C_YELLOW=$'\033[33m'
readonly C_BLUE=$'\033[34m'
readonly C_CYAN=$'\033[36m'
readonly C_RESET=$'\033[0m'

# Cleanup Trap (Resets cursor/terminal state if interrupted)
trap 'tput cnorm; echo -e "${C_RESET}"; exit' INT TERM EXIT

# --- 2. BOOT MODE DETECTION ---
# We detect the mode to give the correct partitioning advice.
if [[ -d /sys/firmware/efi/efivars ]]; then
    BOOT_MODE="UEFI"
else
    BOOT_MODE="BIOS"
fi

# --- 3. INSTRUCTIONAL INTERFACE ---
clear
echo -e "${C_BOLD}=== ARCH LINUX PARTITIONING WIZARD (${C_BLUE}${BOOT_MODE}${C_RESET}${C_BOLD}) ===${C_RESET}"
echo ""
echo -e "${C_BOLD}Step 1: Partition Design${C_RESET}"
echo "We will now launch 'cfdisk' to organize your drive."
echo "You can keep existing Windows/Linux partitions (Dual Boot) or delete everything."
echo ""

if [[ "$BOOT_MODE" == "UEFI" ]]; then
    echo -e "${C_CYAN}Instruction for UEFI Systems:${C_RESET}"
    echo -e "  1. ${C_GREEN}EFI Partition${C_RESET}:  At least 512MB  (Type: ${C_BOLD}EFI System${C_RESET})"
    echo -e "  2. ${C_GREEN}Root Partition${C_RESET}: At least 15GB (Type: ${C_BOLD}Linux Filesystem${C_RESET})"
else
    echo -e "${C_CYAN}Instruction for BIOS (Legacy) Systems:${C_RESET}"
    echo "  * If using GPT partition table (Recommended):"
    echo -e "  1. ${C_GREEN}Boot Loader${C_RESET}:    1MB exact       (Type: ${C_BOLD}BIOS Boot${C_RESET})"
    echo -e "  2. ${C_GREEN}Root Partition${C_RESET}: At least 15GB (Type: ${C_BOLD}Linux Filesystem${C_RESET})"
    echo "  * If using MBR/DOS partition table: Just create one Linux partition."
fi

echo ""
echo -e "${C_YELLOW}${C_BOLD}NOTE:${C_RESET} Your data is safe until you select [ Write ] inside cfdisk."
echo -e "      If you have Windows, simply leave those partitions alone."
echo ""
read -r -p "${C_BOLD}Press [Enter] to list detected drives...${C_RESET}" _unused

# --- 4. DRIVE SELECTION LOOP ---
while true; do
    clear
    echo -e "${C_BOLD}=== AVAILABLE PHYSICAL DRIVES ===${C_RESET}"
    # -d: nodeps (leafs), -o: output columns, -e: exclude loop devices
    lsblk -d -e 7,11 -o NAME,SIZE,MODEL,TYPE,RO | grep -v "loop"
    echo ""
    
    echo -e "${C_CYAN}Which drive do you want to partition?${C_RESET}"
    read -r -p "Enter name (e.g., nvme0n1 or sda): " DRIVE_INPUT

    # Sanitize Input: Remove /dev/ prefix if user typed it, then re-add it
    # This handles both "sda" and "/dev/sda" inputs correctly.
    CLEAN_NAME="${DRIVE_INPUT#/dev/}"
    TARGET_DEV="/dev/${CLEAN_NAME}"

    if [[ -b "$TARGET_DEV" ]]; then
        echo ""
        echo -e "${C_GREEN}>> Selected: $TARGET_DEV${C_RESET}"
        echo "Launching partition editor..."
        sleep 1
        
        # Launch cfdisk
        # FIX: Redirect STDIN/STDOUT/STDERR to /dev/tty to bypass orchestrator logging pipe
        # allowing ncurses to function correctly.
        cfdisk "$TARGET_DEV" < /dev/tty > /dev/tty 2>&1
        
        echo ""
        echo -e "${C_GREEN}>> Partitioning complete for $TARGET_DEV.${C_RESET}"
        echo "Review your layout below:"
        lsblk -o NAME,SIZE,TYPE,FSTYPE "$TARGET_DEV"
        echo ""
        
        # Confirmation to proceed or re-partition
        read -r -p "Are you happy with this layout? [Y/n] (n restarts tool): " CONFIRM
        if [[ "${CONFIRM,,}" =~ ^(n|no)$ ]]; then
            continue
        fi
        
        break
    else
        echo -e "${C_RED}Error: Device '$TARGET_DEV' not found. Please try again.${C_RESET}"
        sleep 2
    fi
done

echo -e "${C_BOLD}>> Partitioning step finished.${C_RESET}"
# Exit cleanly for the orchestrator
exit 0
