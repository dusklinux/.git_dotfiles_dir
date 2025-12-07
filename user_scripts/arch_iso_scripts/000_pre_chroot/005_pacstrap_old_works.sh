#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# MODULE: PACSTRAP (BASE SYSTEM)
# -----------------------------------------------------------------------------
set -euo pipefail
readonly C_BOLD=$'\033[1m' C_RESET=$'\033[0m'

echo -e "${C_BOLD}=== PACSTRAP ===${C_RESET}"

# Microcode Detection
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
UCODE_PKG=""
[[ "$CPU_VENDOR" == "GenuineIntel" ]] && UCODE_PKG="intel-ucode"
[[ "$CPU_VENDOR" == "AuthenticAMD" ]] && UCODE_PKG="amd-ucode"
echo "Detected CPU: $CPU_VENDOR ($UCODE_PKG)"

# Package List
PACKAGES=(
    base base-devel linux linux-headers linux-firmware
    neovim btrfs-progs dosfstools git
)
[[ -n "$UCODE_PKG" ]] && PACKAGES+=("$UCODE_PKG")

# Input Flush to prevent accidental defaults
read -r -t 0.1 -n 10000 discard || true

echo "Installing: ${PACKAGES[*]}"
# Added --needed to prevent redownloading/reinstalling if already present
pacstrap -K /mnt "${PACKAGES[@]}" --needed

echo "Pacstrap complete."
