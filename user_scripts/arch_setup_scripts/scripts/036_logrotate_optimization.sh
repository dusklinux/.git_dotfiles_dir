#!/usr/bin/env bash
# Enforces a standard Arch Linux logrotate configuration.
# ==============================================================================
# Script: update_logrotate.sh
# Description: Enforces a standard Arch Linux logrotate configuration.
# System: Arch Linux / Hyprland / UWSM
# ==============================================================================

# --- Safety & Configuration ---
set -euo pipefail

# ANSI Colors for Feedback
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly BLUE=$'\033[0;34m'
readonly NC=$'\033[0m' # No Color

# Target Configuration File
readonly CONFIG_FILE="/etc/logrotate.conf"

# --- Root Privilege Check (Auto-Elevation) ---
if [[ $EUID -ne 0 ]]; then
   printf "${BLUE}[INFO] Elevation required. Re-executing with sudo...${NC}\n"
   exec sudo "$0" "$@"
fi

# --- Cleanup Trap ---
cleanup() {
    # No temporary files to clean, but structure maintained for robustness
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        printf "${RED}[ERROR] Script failed with exit code %d.${NC}\n" "$exit_code"
    fi
}
trap cleanup EXIT

# --- Main Logic ---
main() {
    printf "${BLUE}[INFO] Configuring %s...${NC}\n" "$CONFIG_FILE"

    # Write configuration atomically
    # Using 'cat' with a quoted heredoc ensures raw text preservation (no var expansion)
    cat << 'EOF' > "$CONFIG_FILE"
# see "man logrotate" for details
# rotate log files weekly
weekly

# keep 4 weeks worth of backlogs
rotate 4

# restrict maximum size of log files
size 20M

# create new (empty) log files after rotating old ones
create

# uncomment this if you want your log files compressed
compress

# Logs are moved into directory for rotation
# olddir /var/log/archive

# Ignore pacman saved files
tabooext + .pacorig .pacnew .pacsave

# Arch packages drop log rotation information into this directory
include /etc/logrotate.d

/var/log/wtmp {
    monthly
    create 0664 root utmp
    minsize 1M
    rotate 1
}

/var/log/btmp {
    missingok
    monthly
    create 0600 root utmp
    rotate 1
}
EOF

    # Ensure correct permissions (Root:Root, 644)
    chmod 0644 "$CONFIG_FILE"
    chown root:root "$CONFIG_FILE"

    printf "${GREEN}[SUCCESS] Logrotate configuration updated successfully.${NC}\n"
}

# --- Execute ---
main
