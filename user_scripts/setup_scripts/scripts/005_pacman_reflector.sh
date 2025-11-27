#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Description: Automates Reflector configuration for Arch Linux.
# Environment: Arch Linux / Hyprland / UWSM
# Author:      Elite DevOps & System Architect
# -----------------------------------------------------------------------------

# --- Strict Safety & Bash 5+ Settings ---
set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true

# --- Constants & Configuration ---
readonly CONFIG_PATH="/etc/xdg/reflector/reflector.conf"
readonly CONFIG_DIR="${CONFIG_PATH%/*}"

# --- Logging Helpers ---
log_info()    { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
log_success() { printf "\033[1;32m[OK]\033[0m   %s\n" "$*"; }
log_error()   { printf "\033[1;31m[ERR]\033[0m  %s\n" "$*" >&2; }

# --- Privilege Check (Auto-Elevation) ---
if [[ $EUID -ne 0 ]]; then
    log_info "Root privileges required. Elevating..."
    exec sudo -- "$0" "$@"
fi

# --- Cleanup Trap ---
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code $exit_code."
    fi
}
trap cleanup EXIT

# --- Main Logic ---
main() {
    log_info "Configuring Reflector at: $CONFIG_PATH"

    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
    fi

    # Write Configuration
    cat <<'EOF' > "$CONFIG_PATH"
--save /etc/pacman.d/mirrorlist

# Select the transfer protocol (--protocol).
--protocol https

# Select the country (--country).
# Consult the list of available countries with "reflector --list-countries" and
# select the countries nearest to you or the ones that you trust. For example:
--country India

# Use only the most recently synchronized mirrors (--latest).
--latest 6

# Sort the mirrors by synchronization time (--sort).
--sort rate
EOF

    # 3. Verification
    if [[ -f "$CONFIG_PATH" ]]; then
        log_success "Reflector configuration updated successfully."
        
        # FIX: Use '--' to signal end of flags, preventing grep from parsing '--sort' as an option.
        if grep -Fq -- "--sort rate" "$CONFIG_PATH"; then
             log_success "Verification passed: Configuration content validated."
        else
             log_error "Verification warning: Content might not have written correctly."
             exit 1
        fi
    else
        log_error "Failed to write configuration file."
        exit 1
    fi
}

main "$@"
