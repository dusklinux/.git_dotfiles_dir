#!/usr/bin/env bash

# ==============================================================================
# Script: update_vsftpd_root.sh
# Description: Safely updates local_root in /etc/vsftpd.conf and restarts service.
# Author: Arch Linux System Architect
# Environment: Arch Linux / Hyprland / UWSM
# ==============================================================================

# Strict error handling
set -euo pipefail

# ------------------------------------------------------------------------------
# Visuals & Logging
# ------------------------------------------------------------------------------
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m' # No Color

log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

# ------------------------------------------------------------------------------
# Privilege Escalation
# ------------------------------------------------------------------------------
# Check if running as root. If not, re-execute with sudo.
if [[ $EUID -ne 0 ]]; then
   log_info "Elevating permissions to modify system configuration..."
   exec sudo "$0" "$@"
fi

# ------------------------------------------------------------------------------
# Cleanup Trap
# ------------------------------------------------------------------------------
cleanup() {
    # Catching exit code to determine final message
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code $exit_code."
    fi
}
trap cleanup EXIT

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
CONFIG_FILE="/etc/vsftpd.conf"
SERVICE_NAME="vsftpd.service"

# Check if config exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Configuration file $CONFIG_FILE not found. Is vsftpd installed?"
    exit 1
fi

# ------------------------------------------------------------------------------
# User Interaction
# ------------------------------------------------------------------------------
# Clear screen for focus
clear

printf "${BLUE}::${NC} VSFTPD Configuration Manager\n"
printf "${BLUE}::${NC} Current 'local_root' configuration:\n"

# Grep for active config to show user current state
if grep -q "^local_root=" "$CONFIG_FILE"; then
    grep "^local_root=" "$CONFIG_FILE" | sed "s/^/${YELLOW}   > ${NC}/"
else
    printf "${YELLOW}   (Not currently set or commented out)${NC}\n"
fi

printf "\n"
read -rp "Enter the new local_root directory path: " NEW_ROOT

# Trim trailing slash from input if present
NEW_ROOT="${NEW_ROOT%/}"

# ------------------------------------------------------------------------------
# Validation
# ------------------------------------------------------------------------------
if [[ -z "$NEW_ROOT" ]]; then
    log_error "Path cannot be empty."
    exit 1
fi

if [[ ! -d "$NEW_ROOT" ]]; then
    log_error "Directory '$NEW_ROOT' does not exist."
    printf "   Use 'mkdir -p %s' to create it first.\n" "$NEW_ROOT"
    exit 1
fi

# ------------------------------------------------------------------------------
# Modification Logic
# ------------------------------------------------------------------------------
log_info "Updating $CONFIG_FILE..."

# Strategy:
# 1. Look for an uncommented (active) line starting with 'local_root='.
# 2. If found, replace it using sed.
# 3. If NOT found, append it to the end of the file.

if grep -q "^local_root=" "$CONFIG_FILE"; then
    # Use | as delimiter in sed to avoid conflicts with / in file paths
    sed -i "s|^local_root=.*|local_root=$NEW_ROOT|" "$CONFIG_FILE"
    log_success "Updated existing configuration entry."
else
    # Check if file ends with newline, append one if not, then append config
    # This prevents appending to the middle of the last line if \n is missing
    [[ -n "$(tail -c1 "$CONFIG_FILE")" ]] && printf "\n" >> "$CONFIG_FILE"
    
    printf "local_root=%s\n" "$NEW_ROOT" >> "$CONFIG_FILE"
    log_success "Added new configuration entry (was missing or commented)."
fi

# ------------------------------------------------------------------------------
# Service Restart
# ------------------------------------------------------------------------------
log_info "Restarting $SERVICE_NAME..."

if systemctl restart "$SERVICE_NAME"; then
    log_success "Service restarted successfully."
else
    log_error "Failed to restart service. Check 'journalctl -xeu $SERVICE_NAME'."
    exit 1
fi

# Final verification
STATUS=$(systemctl is-active "$SERVICE_NAME")
if [[ "$STATUS" == "active" ]]; then
    log_success "VSFTPD is running with new root: $NEW_ROOT"
else
    log_warn "VSFTPD status is: $STATUS"
fi
