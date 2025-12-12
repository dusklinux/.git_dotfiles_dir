#!/usr/bin/env bash
# ==============================================================================
#  Arch Linux GRUB Optimizer (Hyprland/UWSM Context)
#  Description: Interactively configures GRUB kernel parameters for performance.
#  Author: Elite DevOps Engineer
# ==============================================================================

# --- 1. Safety & Environment ---
set -euo pipefail
IFS=$'\n\t'

# Cleanup trap (Even though we run clean, we catch interruptions)
trap 'printf "\n\033[1;31m[!] Script interrupted or failed.\033[0m\n"; exit 1' ERR SIGINT SIGTERM

# --- 2. Styling (UWSM/Hyprland aesthetic) ---
# Updated to use ANSI-C quoting ($'...') per request
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_YELLOW=$'\033[1;33m'
readonly C_RED=$'\033[1;31m'
readonly C_CYAN=$'\033[1;36m'

log_info()    { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"; }
log_success() { printf "${C_GREEN}[OK]${C_RESET}   %s\n" "$1"; }
log_warn()    { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$1"; }
log_error()   { printf "${C_RED}[ERR]${C_RESET}  %s\n" "$1"; exit 1; }

# --- 3. Root Privilege Check (Auto-Elevation) ---
if [[ $EUID -ne 0 ]]; then
    log_info "Root privileges required. Elevating..."
    exec sudo "$0" "$@"
fi

# --- 4. Grub Verification ---
readonly GRUB_CFG="/etc/default/grub"

if [[ ! -f "$GRUB_CFG" ]]; then
    log_warn "GRUB configuration file not found at $GRUB_CFG."
    log_info "It appears you are using a different bootloader (systemd-boot, rEFInd, etc.)."
    printf "${C_BOLD}No actions are required or possible with this script.${C_RESET}\n"
    exit 0
fi

# --- 5. Helper Functions ---
ask_confirm() {
    local prompt="$1"
    local choice
    while true; do
        printf "${C_CYAN}[?]${C_RESET} %s ${C_BOLD}(y/n)${C_RESET}: " "$prompt"
        read -r choice
        case "${choice,,}" in 
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *)     printf "    Please answer yes (y) or no (n).\n" ;;
        esac
    done
}

# --- 6. Main Logic ---
clear
printf "${C_BOLD}:: Arch Linux GRUB Optimizer${C_RESET}\n"
printf "   Target: %s\n\n" "$GRUB_CFG"

# -- Initialize base parameter string --
# We start with loglevel=3 as requested in your target string
kernel_params="loglevel=3"

# -- Interactive Configuration --

# 1. ZRAM / Zswap
if ask_confirm "Optimize for ZRAM? (Disable zswap: zswap.enabled=0)"; then
    kernel_params+=" zswap.enabled=0"
fi

# 2. Btrfs
if ask_confirm "Are you using BTRFS on root? (rootfstype=btrfs)"; then
    kernel_params+=" rootfstype=btrfs"
fi

# 3. Power Saving (Laptop)
if ask_confirm "Force PCIe Active State Power Management? (pcie_aspm=force)"; then
    kernel_params+=" pcie_aspm=force"
fi

# 4. Filesystem Check
if ask_confirm "Skip boot filesystem check? (fsck.mode=skip)"; then
    kernel_params+=" fsck.mode=skip"
fi

# 5. General GRUB Tweaks (Timeout & OS Prober)
modify_extras=false
if ask_confirm "Apply general GRUB tweaks? (Timeout=1s, Enable OS Prober)"; then
    modify_extras=true
fi

# --- 7. Execution ---

printf "\n${C_BOLD}:: Applying Configuration...${C_RESET}\n"

# A. Apply Kernel Parameters
# We use sed to replace the entire GRUB_CMDLINE_LINUX_DEFAULT line.
# Note: We use | as delimiter to avoid path conflicts, though rare in kernel params.
log_info "Setting kernel parameters: ${C_BOLD}${kernel_params}${C_RESET}"

if sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${kernel_params}\"|" "$GRUB_CFG"; then
    log_success "Kernel parameters updated."
else
    log_error "Failed to write kernel parameters."
fi

# B. Apply Extras (Timeout & OS Prober)
if [[ "$modify_extras" == true ]]; then
    log_info "Setting GRUB timeout to 1 second..."
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' "$GRUB_CFG"

    log_info "Enabling OS Prober..."
    # Uncomment the line if it exists as commented, or ensure it's set to false (which enables prober logic in some configs)
    # The user request specifically asked for: GRUB_DISABLE_OS_PROBER=false
    if grep -q "^#GRUB_DISABLE_OS_PROBER=false" "$GRUB_CFG"; then
        sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' "$GRUB_CFG"
    elif grep -q "^GRUB_DISABLE_OS_PROBER=" "$GRUB_CFG"; then
        sed -i 's/^GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "$GRUB_CFG"
    else
        # If line doesn't exist, append it
        echo "GRUB_DISABLE_OS_PROBER=false" >> "$GRUB_CFG"
    fi
    log_success "General tweaks applied."
fi

# --- 8. Regeneration ---
printf "\n${C_BOLD}:: Regenerating GRUB Configuration...${C_RESET}\n"

if command -v grub-mkconfig >/dev/null 2>&1; then
    # We allow stdout here so the user sees the mkconfig progress
    if grub-mkconfig -o /boot/grub/grub.cfg; then
        printf "\n"
        log_success "GRUB configuration successfully regenerated."
        printf "${C_BOLD}   Please reboot your system to apply changes.${C_RESET}\n"
    else
        log_error "grub-mkconfig failed."
    fi
else
    log_error "Command 'grub-mkconfig' not found. Is the 'grub' package installed?"
fi

# Remove the trap so we don't print the error message on clean exit
trap - ERR SIGINT SIGTERM
exit 0
