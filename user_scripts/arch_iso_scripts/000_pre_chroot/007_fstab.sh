#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# MODULE: FSTAB GENERATION
# -----------------------------------------------------------------------------
set -euo pipefail
readonly C_GREEN=$'\033[32m' C_RESET=$'\033[0m'

echo ">> Generating Fstab..."

# Generate
genfstab -U /mnt > /mnt/etc/fstab

# Verify & Print
echo -e "${C_GREEN}=== /mnt/etc/fstab contents ===${C_RESET}"
cat /mnt/etc/fstab

echo -e "\n[SUCCESS] Fstab generated."
