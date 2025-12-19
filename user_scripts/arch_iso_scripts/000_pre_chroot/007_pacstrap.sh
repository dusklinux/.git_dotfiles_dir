#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# MODULE: PACSTRAP (VERIFIED HARDWARE & FIXED REGEX)
# AUTHOR: Elite DevOps Setup
# -----------------------------------------------------------------------------
set -euo pipefail

# --- Colors ---
if [[ -t 1 ]]; then
    readonly C_BOLD=$'\033[1m' 
    readonly C_GREEN=$'\033[32m' 
    readonly C_YELLOW=$'\033[33m' 
    readonly C_RED=$'\033[31m' 
    readonly C_RESET=$'\033[0m'
else
    readonly C_BOLD="" C_GREEN="" C_YELLOW="" C_RED="" C_RESET=""
fi

# --- Configuration ---
MOUNT_POINT="/mnt"
USE_GENERIC_FIRMWARE=0

# Base packages every system needs
FINAL_PACKAGES=(
    base base-devel linux linux-headers 
    neovim btrfs-progs dosfstools git
    networkmanager yazi
)

# --- Logging Helpers ---
log_info() { echo -e "${C_GREEN}[INFO]${C_RESET} $1"; }
log_warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $1"; }
log_err()  { echo -e "${C_RED}[ERROR]${C_RESET} $1"; }

# --- Helper: Check if package exists in Arch Repos ---
package_exists() {
    pacman -Si "$1" &> /dev/null
}

# --- Helper: Detect Hardware & Add Package ---
# FIXED: Now uses grep -iE (Extended Regex) to support word boundaries (\b)
detect_and_add() {
    local name="$1"     # Human Name (e.g. "AMD Legacy")
    local pattern="$2"  # Regex Pattern
    local pkg="$3"      # Arch Package Name
    
    # If we already fell back to generic, stop checking specific ones
    if [[ $USE_GENERIC_FIRMWARE -eq 1 ]]; then return; fi

    echo -ne "   > Scanning for $name... "
    
    # lspci -mm: Machine readable output
    # grep -iE: Case insensitive + Extended Regex (required for | and \b)
    if lspci -mm | grep -iE "$pattern" &> /dev/null; then
        echo -e "${C_GREEN}FOUND${C_RESET}"
        
        # Verify package actually exists before adding
        if package_exists "$pkg"; then
            echo -e "     -> Queuing Verified Package: ${C_BOLD}$pkg${C_RESET}"
            FINAL_PACKAGES+=("$pkg")
        else
            echo -e "     -> ${C_YELLOW}Hardware found, but package '$pkg' missing in repo.${C_RESET}"
            echo -e "     -> Switching to Safe Mode (Generic Firmware)."
            USE_GENERIC_FIRMWARE=1
        fi
    else
        echo -e "NO"
    fi
}

# ==============================================================================
# 1. SAFETY PRE-FLIGHT CHECKS
# ==============================================================================
echo -e "${C_BOLD}=== PACSTRAP: HARDWARE-VERIFIED EDITION ===${C_RESET}"

# Check Root
if [[ $EUID -ne 0 ]]; then
   log_err "This script must be run as root."
   exit 1
fi

# Check Mount
if ! mountpoint -q "$MOUNT_POINT"; then
    log_err "$MOUNT_POINT is not a mountpoint. Mount your partitions first."
    exit 1
fi

# Check Network
if ! ping -c 1 archlinux.org &> /dev/null; then
    log_err "No internet connection. Cannot install packages."
    exit 1
fi

# Sync DB (Crucial for package_exists check)
log_info "Syncing package databases..."
pacman -Sy --noconfirm &> /dev/null

# ==============================================================================
# 2. CPU MICROCODE
# ==============================================================================
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
case "$CPU_VENDOR" in
    "GenuineIntel")
        log_info "CPU: Intel Detected"
        FINAL_PACKAGES+=("intel-ucode")
        # Intel CPUs usually imply Intel Chipset/WiFi
        detect_and_add "Intel Chipset/WiFi" "intel" "linux-firmware-intel"
        ;;
    "AuthenticAMD")
        log_info "CPU: AMD Detected"
        FINAL_PACKAGES+=("amd-ucode")
        ;;
    *)
        log_warn "Unknown CPU Vendor ($CPU_VENDOR). VM Environment?"
        ;;
esac

# ==============================================================================
# 3. PERIPHERAL DETECTION (With "Corporation" Fix)
# ==============================================================================
log_info "Scanning PCI Bus..."

# Ensure lspci is available
if ! command -v lspci &>/dev/null; then
    log_warn "'lspci' not found. Installing pciutils temporarily..."
    pacman -S --noconfirm pciutils &>/dev/null
fi

# -- GRAPHICS --
# Note: \b ensures we match "ati" as a whole word, not inside "Corporation"
detect_and_add "Nvidia GPU"        "nvidia"                 "linux-firmware-nvidia"
detect_and_add "AMD GPU (Modern)"  "amdgpu|navi|rdna"       "linux-firmware-amdgpu"
detect_and_add "AMD GPU (Legacy)"  "\b(radeon|ati)\b"       "linux-firmware-radeon"

# -- NETWORKING --
detect_and_add "Mediatek WiFi/BT"  "mediatek"               "linux-firmware-mediatek"
detect_and_add "Broadcom WiFi"     "broadcom"               "linux-firmware-broadcom"
detect_and_add "Atheros WiFi"      "atheros"                "linux-firmware-atheros"
# Match "Realtek" OR "RTL" at start of word (e.g. RTL8821)
detect_and_add "Realtek Eth/WiFi"  "realtek|\brtl"          "linux-firmware-realtek"


# ==============================================================================
# 4. FINAL PACKAGE ASSEMBLY
# ==============================================================================

# If any detection failed/missing, we must install the massive generic package
if [[ $USE_GENERIC_FIRMWARE -eq 1 ]]; then
    log_warn "Fallback Triggered: Installing generic linux-firmware."
    
    # Filter out any specific firmware we might have added earlier to avoid conflicts
    CLEAN_LIST=()
    for pkg in "${FINAL_PACKAGES[@]}"; do
        if [[ ! $pkg == "linux-firmware-"* ]]; then
            CLEAN_LIST+=("$pkg")
        fi
    done
    FINAL_PACKAGES=("${CLEAN_LIST[@]}" "linux-firmware")

else
    # Optimization Path: Add the license file required by split packages
    FINAL_PACKAGES+=("linux-firmware-whence")
fi

# ==============================================================================
# 5. EXECUTION
# ==============================================================================
echo ""
echo -e "${C_BOLD}Final Package List:${C_RESET}"
printf '%s\n' "${FINAL_PACKAGES[@]}"
echo ""

read -r -p "Ready to run pacstrap? [Y/n] " confirm
if [[ ! "${confirm,,}" =~ ^(y|yes|)$ ]]; then
    log_warn "Aborted by user."
    exit 0
fi

echo "Installing..."
# -K initializes keyring in the target
# NOTE: Because we used 'set -e' at the top, if this fails, the script 
# exits immediately with the error code, triggering the Orchestra's error handler.
pacstrap -K "$MOUNT_POINT" "${FINAL_PACKAGES[@]}" --needed

echo -e "\n${C_GREEN}Pacstrap Complete.${C_RESET}"
