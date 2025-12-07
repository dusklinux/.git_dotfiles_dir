#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# MODULE: PACSTRAP (VERIFIED HARDWARE SPLIT)
# -----------------------------------------------------------------------------
set -uo pipefail

# --- Colors ---
if [[ -t 1 ]]; then
    readonly C_BOLD=$'\033[1m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_RED=$'\033[31m' C_RESET=$'\033[0m'
else
    readonly C_BOLD="" C_GREEN="" C_YELLOW="" C_RED="" C_RESET=""
fi

# --- Config ---
MOUNT_POINT="/mnt"
USE_GENERIC_FIRMWARE=0
FINAL_PACKAGES=(base base-devel linux linux-headers neovim btrfs-progs dosfstools git man-db man-pages networkmanager)

log_info() { echo -e "${C_GREEN}[INFO]${C_RESET} $1"; }
log_warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $1"; }
log_err()  { echo -e "${C_RED}[ERROR]${C_RESET} $1"; }

# --- Helper: Check if package exists in verified repos ---
package_exists() {
    pacman -Si "$1" &> /dev/null
}

# --- Helper: Detect & Add ---
detect_and_add() {
    local name="$1"     # Human Name
    local pattern="$2"  # lspci grep pattern
    local pkg="$3"      # Arch Package Name
    
    if [[ $USE_GENERIC_FIRMWARE -eq 1 ]]; then return; fi

    echo -ne "   > Scanning for $name... "
    if lspci -mm | grep -i "$pattern" &> /dev/null; then
        echo -e "${C_GREEN}FOUND${C_RESET}"
        if package_exists "$pkg"; then
            echo -e "     -> Queuing Verified Package: ${C_BOLD}$pkg${C_RESET}"
            FINAL_PACKAGES+=("$pkg")
        else
            echo -e "     -> ${C_YELLOW}Hardware found, but package '$pkg' missing in repo.${C_RESET}"
            USE_GENERIC_FIRMWARE=1
        fi
    else
        echo -e "NO"
    fi
}

# ==============================================================================
# 1. PRE-FLIGHT
# ==============================================================================
echo -e "${C_BOLD}=== PACSTRAP: HARDWARE-VERIFIED EDITION ===${C_RESET}"

[[ $EUID -ne 0 ]] && { log_err "Run as root."; exit 1; }
! mountpoint -q "$MOUNT_POINT" && { log_err "Mount /mnt first."; exit 1; }
! ping -c 1 archlinux.org &> /dev/null && { log_err "No Internet."; exit 1; }

log_info "Syncing DB to verify package existence..."
pacman -Sy --noconfirm &> /dev/null

# ==============================================================================
# 2. CPU & MICROCODE
# ==============================================================================
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
case "$CPU_VENDOR" in
    "GenuineIntel")
        log_info "CPU: Intel Detected"
        FINAL_PACKAGES+=("intel-ucode")
        # Intel usually implies Intel Chipset firmware
        detect_and_add "Intel Chipset/WiFi" "intel" "linux-firmware-intel"
        ;;
    "AuthenticAMD")
        log_info "CPU: AMD Detected"
        FINAL_PACKAGES+=("amd-ucode")
        ;;
    *) log_warn "Unknown CPU. VM?" ;;
esac

# ==============================================================================
# 3. PERIPHERAL DETECTION (Based on your Screenshots)
# ==============================================================================
log_info "Scanning PCI Bus..."

if ! command -v lspci &>/dev/null; then
    log_warn "lspci missing. Installing pciutils..."
    pacman -S --noconfirm pciutils &>/dev/null
fi

# -- GPU --
detect_and_add "Nvidia GPU"        "nvidia"             "linux-firmware-nvidia"
detect_and_add "AMD GPU (Modern)"  "amdgpu\|navi\|rdna" "linux-firmware-amdgpu"
detect_and_add "AMD GPU (Legacy)"  "radeon\|ati"        "linux-firmware-radeon"

# -- NETWORK (Crucial for laptops) --
detect_and_add "Mediatek WiFi/BT"  "mediatek"           "linux-firmware-mediatek"
detect_and_add "Broadcom WiFi"     "broadcom"           "linux-firmware-broadcom"
detect_and_add "Atheros WiFi"      "atheros"            "linux-firmware-atheros"
detect_and_add "Realtek Eth/WiFi"  "realtek\|rtl"       "linux-firmware-realtek"

# ==============================================================================
# 4. FINAL ASSEMBLY
# ==============================================================================
# Fallback Logic
if [[ $USE_GENERIC_FIRMWARE -eq 1 ]]; then
    log_warn "Detection uncertain or package missing. Falling back to GENERIC firmware."
    # Filter out specific firmware to avoid conflicts
    TEMP_LIST=()
    for pkg in "${FINAL_PACKAGES[@]}"; do
        [[ ! $pkg == "linux-firmware-"* ]] && TEMP_LIST+=("$pkg")
    done
    FINAL_PACKAGES=("${TEMP_LIST[@]}" "linux-firmware")
else
    # Optimization Logic: Add the license package required by split firmware
    FINAL_PACKAGES+=("linux-firmware-whence")
fi

echo -e "\n${C_BOLD}Final Package List:${C_RESET}"
printf '%s\n' "${FINAL_PACKAGES[@]}"

read -r -p "Run Pacstrap? [Y/n] " confirm
[[ "${confirm,,}" =~ ^(y|yes|)$ ]] || exit 0

echo "Installing..."
pacstrap -K "$MOUNT_POINT" "${FINAL_PACKAGES[@]}" --needed
