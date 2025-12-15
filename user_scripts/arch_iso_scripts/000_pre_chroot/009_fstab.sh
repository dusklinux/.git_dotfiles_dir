#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# MODULE: FSTAB GENERATION
# -----------------------------------------------------------------------------
set -euo pipefail
readonly C_GREEN=$'\033[32m' C_RESET=$'\033[0m'
readonly C_YELLOW=$'\033[33m'
readonly C_RED=$'\033[31m'
readonly C_CYAN=$'\033[36m'

# 1. Ask for confirmation with a warning
echo -e "\n${C_YELLOW}WARNING:${C_RESET} If you are mounting an existing system to repair it (arch-chroot),"
echo "regenerating fstab will overwrite your existing file and discard manual entries."
read -r -p "Do you want to generate a new fstab? [Y/n] " response

# 2. Conditional Execution
if [[ "$response" =~ ^([yY][eE][sS]|[yY])?$ ]]; then
    echo ">> Generating Fstab..."

    # Generate
    genfstab -U /mnt > /mnt/etc/fstab

    # Verify & Print
    echo -e "${C_GREEN}=== /mnt/etc/fstab contents ===${C_RESET}"
    cat /mnt/etc/fstab

    echo -e "\n[SUCCESS] Fstab generated."

    # CRITICAL NEXT STEP PROMPT
    echo -e "\n${C_RED}##########################################################${C_RESET}"
    echo -e "${C_RED}##             CRITICAL NEXT STEP REQUIRED              ##${C_RESET}"
    echo -e "${C_RED}##########################################################${C_RESET}"
    echo -e "${C_YELLOW}You must now enter the new system environment manually.${C_RESET}"
    echo -e "${C_YELLOW}Please type the following command exactly:${C_RESET}\n"
    echo -e "    ${C_CYAN}arch-chroot /mnt${C_RESET}\n"
    echo -e "${C_RED}##########################################################${C_RESET}\n"

else
    echo ">> Skipping fstab generation as requested."
fi
