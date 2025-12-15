#!/usr/bin/env bash
# ==============================================================================
#  SCRIPT: 011_nvidia_open_source.sh
#  DESCRIPTION: Interactive NVIDIA Open Source Driver Installer (Turing+)
#  CONTEXT: Arch Linux / Hyprland / UWSM
# ==============================================================================

# 1. Safety & Environment
set -o errexit   # Exit on error
set -o nounset   # Abort on unbound variables
set -o pipefail  # Catch pipe errors

# 2. Privileges Check
if [[ "${EUID}" -ne 0 ]]; then
    printf "\e[31mError: This script must be run as root (sudo).\e[0m\n" >&2
    exit 1
fi

# 3. Aesthetics (Re-declaring for standalone safety, though Orchestra likely provides them)
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[0;34m'
readonly NC=$'\033[0m' # No Color

# 4. Helper Functions

detect_gpu_hardware() {
    printf "\n%b>>> DETECTING GPU HARDWARE...%b\n" "${BLUE}" "${NC}"
    
    if ! command -v lspci &>/dev/null; then
        printf "%bInstalling pciutils for detection...%b\n" "${YELLOW}" "${NC}"
        pacman -S --needed --noconfirm pciutils >/dev/null 2>&1
    fi

    # Modern bash: capture output cleanly
    local gpu_list
    gpu_list=$(lspci -mm | grep -i -E 'vga|3d|display')

    if [[ -z "$gpu_list" ]]; then
        printf "%bNo Graphics Controllers found via lspci.%b\n" "${RED}" "${NC}"
    else
        printf "%bFound the following GPU devices:%b\n" "${GREEN}" "${NC}"
        # Parse and pretty print the PCI output
        while IFS= read -r line; do
            # Extract device name (usually the string after the vendor/device IDs)
            # lspci -mm format: Slot "Class" "Vendor" "Device" ...
            local vendor
            local device
            vendor=$(echo "$line" | cut -d'"' -f4)
            device=$(echo "$line" | cut -d'"' -f6)
            printf "  • %b%s%b: %s\n" "${YELLOW}" "$vendor" "${NC}" "$device"
        done <<< "$gpu_list"
    fi
    printf "\n"
}

perform_install() {
    printf "\n%b>>> INSTALLING NVIDIA OPEN KERNEL MODULES & UTILITIES...%b\n" "${BLUE}" "${NC}"
    
    # Packages requested:
    # nvidia-open-dkms: Open source kernel modules (Turing 20xx and newer recommended)
    # nvidia-utils: Userspace tools
    # nvidia-settings: Configuration GUI
    # opencl-nvidia: OpenCL support
    # libva-nvidia-driver: VA-API (Video Acceleration)
    # nvidia-prime: Hybrid GPU offloading
    # egl-wayland: Crucial for Hyprland/Wayland compositors
    
    local packages=(
        "nvidia-open-dkms"
        "nvidia-utils"
        "nvidia-settings"
        "opencl-nvidia"
        "libva-nvidia-driver"
        "nvidia-prime"
        "egl-wayland"
    )

    # Install
    pacman -S --needed "${packages[@]}"

    printf "\n%b[SUCCESS] NVIDIA packages installed.%b\n" "${GREEN}" "${NC}"
    printf "%b[NOTE] Ensure 'nvidia_drm.modeset=1' is in your kernel parameters.%b\n" "${YELLOW}" "${NC}"
    printf "%b[NOTE] If using mkinitcpio, ensure hooks are updated.%b\n" "${YELLOW}" "${NC}"
}

# 5. Main Logic Loop
main() {
    # Added: Automatically detect and list all GPUs at startup
    detect_gpu_hardware

    local valid_input=0
    
    while [[ $valid_input -eq 0 ]]; do
        printf "%bDo you have an NVIDIA GPU (10-series to 60-series)?%b\n" "${YELLOW}" "${NC}"
        read -r -p "Select [y]es, [n]o, or [c]heck/idk: " user_choice

        case "${user_choice,,}" in
            y|yes)
                perform_install
                valid_input=1
                ;;
            n|no)
                printf "%bSkipping NVIDIA installation.%b\n" "${BLUE}" "${NC}"
                valid_input=1
                ;;
            c|check|idk|"i don't know")
                detect_gpu_hardware
                # Loop continues, asking the question again after showing info
                ;;
            *)
                printf "%bInvalid option. Please choose y, n, or c.%b\n" "${RED}" "${NC}"
                ;;
        esac
    done
}

main
