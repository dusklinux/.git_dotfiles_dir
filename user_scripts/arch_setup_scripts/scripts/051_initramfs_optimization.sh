#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Script: optimize_mkinitcpio.sh
# Description: Conditionally configures mkinitcpio for BTRFS and Systemd hooks.
# Author: Elite DevOps / Arch Architect
# Target: Arch Linux / Hyprland / UWSM
# -----------------------------------------------------------------------------

# Strict Mode
set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
CONFIG_FILE="/etc/mkinitcpio.conf"

# --- Styling (Using \033 for broad compatibility) ---
BOLD=$'\033[1m'
RESET=$'\033[0m'
GREEN=$'\033[32m'
RED=$'\033[31m'
BLUE=$'\033[34m'
YELLOW=$'\033[33m'

# --- Helper Functions ---
# We use %b here so it interprets color codes passed inside the message argument
log_info() { printf "${BLUE}[INFO]${RESET} %b\n" "$1"; }
log_success() { printf "${GREEN}[OK]${RESET} %b\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${RESET} %b\n" "$1"; }
log_error() { printf "${RED}[ERROR]${RESET} %b\n" "$1" >&2; }

# --- 1. Root Privilege Check (Auto-Escalation) ---
if [[ $EUID -ne 0 ]]; then
   # We use basic echo here to ensure visibility before styling functions load fully
   printf "Root privileges required. Elevating...\n"
   exec sudo "$0" "$@"
   exit 0
fi

# --- Cleanup Trap ---
cleanup() {
    if [[ $? -ne 0 ]]; then
        log_error "Script failed unexpectedly."
    fi
}
trap cleanup EXIT

# --- Main Logic ---
main() {
    log_info "Starting mkinitcpio optimization for Arch Linux..."

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file $CONFIG_FILE not found!"
        exit 1
    fi

    # 1. BTRFS Configuration
    local root_fs_type
    root_fs_type=$(findmnt -n -o FSTYPE /) || root_fs_type="unknown"
    
    printf "\n${BOLD}Step 1: Filesystem Configuration${RESET}\n"
    # This line was the culprit. %b in log_info will now render ${YELLOW} correctly.
    log_info "Detected Root Filesystem: ${YELLOW}${root_fs_type}${RESET}"
    
    printf "Is your root filesystem BTRFS formatted? [y/N] "
    read -r -n 1 btrfs_response
    printf "\n"

    if [[ "$btrfs_response" =~ ^[Yy]$ ]]; then
        log_info "Applying BTRFS modules and binaries..."
        sed -i -e 's/^MODULES=.*/MODULES=(btrfs)/' "$CONFIG_FILE"
        sed -i -e 's|^BINARIES=.*|BINARIES=(/usr/bin/btrfs)|' "$CONFIG_FILE"
        log_success "BTRFS settings applied."
    else
        log_info "Skipping BTRFS specific configuration."
    fi

    # 2. Hooks Optimization
    printf "\n${BOLD}Step 2: Hooks Optimization${RESET}\n"
    printf "Current Hooks Strategy: systemd, autodetect, microcode, modconf, kms, sd-vconsole, block, filesystems.\n"
    printf "Would you like to apply these optimized systemd hooks? [y/N] "
    read -r -n 1 hooks_response
    printf "\n"

    if [[ "$hooks_response" =~ ^[Yy]$ ]]; then
        log_info "Applying optimized systemd hooks..."
        sed -i -e 's/^HOOKS=.*/HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)/' "$CONFIG_FILE"
        log_success "Hooks optimized."
    else
        log_info "Skipping Hooks optimization."
    fi

    # 3. Regeneration
    printf "\n${BOLD}Step 3: Regenerating Initramfs${RESET}\n"
    log_info "Running mkinitcpio -P..."
    
    # We pipe stdout to /dev/null if you want a silent run, but for mkinitcpio visibility is safer
    if mkinitcpio -P; then
        printf "\n"
        log_success "Initramfs regeneration complete. Reboot to apply changes."
    else
        log_error "Failed to regenerate initramfs."
        exit 1
    fi
}

main
