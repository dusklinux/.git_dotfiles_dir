#!/usr/bin/env bash
# Installation of Gnome Keyring components
# ==============================================================================
# Script Name: setup_gnome_keyring.sh
# Description: Automates the installation of Gnome Keyring components and 
#              configures PAM for auto-unlocking on login.
#              Designed for Arch Linux (Hyprland/UWSM ecosystem).
# Target:      /etc/pam.d/login
# ==============================================================================

set -euo pipefail

# --- Configuration ---
TARGET_FILE="/etc/pam.d/login"
BACKUP_DIR="/etc/pam.d"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${TARGET_FILE}.bak.${TIMESTAMP}"
PACKAGES=("gnome-keyring" "libsecret" "seahorse")

# --- Formatting ---
BOLD=$'\e[1m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
RED=$'\e[31m'
RESET=$'\e[0m'

# --- Helper Functions ---

log_info() {
    printf "${BOLD}${GREEN}[INFO]${RESET} %s\n" "$1"
}

log_warn() {
    printf "${BOLD}${YELLOW}[WARN]${RESET} %s\n" "$1"
}

log_error() {
    printf "${BOLD}${RED}[ERROR]${RESET} %s\n" "$1" >&2
}

# Check if script is run as root, if not, re-execute with sudo
ensure_root() {
    if [[ $EUID -ne 0 ]]; then
        log_warn "Root privileges required. Elevating..."
        exec sudo "$0" "$@"
    fi
}

# --- Main Execution ---

main() {
    # 1. Privilege Check
    ensure_root

    # 2. Install Packages
    log_info "Installing necessary packages: ${PACKAGES[*]}..."
    if pacman -S --needed --noconfirm "${PACKAGES[@]}"; then
        log_info "Packages installed/verified successfully."
    else
        log_error "Failed to install packages via pacman."
        exit 1
    fi

    # 3. Create Backup
    if [[ -f "$TARGET_FILE" ]]; then
        log_info "Backing up existing configuration to $BACKUP_FILE..."
        cp "$TARGET_FILE" "$BACKUP_FILE"
    else
        log_warn "$TARGET_FILE does not exist. Creating a new one."
    fi

    # 4. Write New Configuration
    # Note: Using standard ASCII spaces to ensure PAM compatibility.
    log_info "Writing new PAM configuration to $TARGET_FILE..."
    
    cat > "$TARGET_FILE" <<EOF
#%PAM-1.0

# 1. Standard Checks
auth       requisite     pam_nologin.so
auth       include       system-local-login
auth       optional      pam_gnome_keyring.so

# 2. Account Management
account    include       system-local-login

# 3. Session Setup
session    include       system-local-login
session    optional      pam_gnome_keyring.so auto_start

# 4. Password Changes
password   include       system-local-login
password   optional      pam_gnome_keyring.so
EOF

    # 5. Verification
    if [[ $? -eq 0 ]]; then
        log_info "Configuration updated successfully."
        echo ""
        printf "${BOLD}Success!${RESET} The GNOME Keyring PAM module is now configured.\n"
        printf "A reboot or re-login is required for the PAM changes to take effect.\n"
    else
        log_error "Failed to write to $TARGET_FILE. Restoring backup..."
        if [[ -f "$BACKUP_FILE" ]]; then
            cp "$BACKUP_FILE" "$TARGET_FILE"
            log_warn "Backup restored."
        fi
        exit 1
    fi
}

main "$@"
