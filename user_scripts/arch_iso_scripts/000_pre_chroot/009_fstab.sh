#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# MODULE: FSTAB GENERATION
# -----------------------------------------------------------------------------
set -euo pipefail
readonly C_GREEN=$'\033[32m' C_RESET=$'\033[0m'
readonly C_YELLOW=$'\033[33m'

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
else
    echo ">> Skipping fstab generation as requested."
fi
