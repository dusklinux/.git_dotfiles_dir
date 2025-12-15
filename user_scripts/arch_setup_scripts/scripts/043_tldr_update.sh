#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: update_tldr.sh
# Description: Safely updates the tldr cache in an Arch/Hyprland environment.
# Author: Elite DevOps (AI)
# Environment: Arch Linux | Bash 5+ | UWSM
# -----------------------------------------------------------------------------

# --- 1. Strict Mode & Safety ---
set -euo pipefail
IFS=$'\n\t'

# --- 2. Configuration & Visuals ---
# ANSI Colors for modern terminal feedback
readonly C_RESET='\033[0m'
readonly C_BOLD='\033[1m'
readonly C_GREEN='\033[1;32m'
readonly C_BLUE='\033[1;34m'
readonly C_RED='\033[1;31m'

# Application binary
readonly BIN_TLDR="tldr"

# --- 3. Helper Functions ---

# Logging helper using printf (no forks)
log_info()    { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"; }
log_success() { printf "${C_GREEN}[OK]${C_RESET}   %s\n" "$1"; }
log_error()   { printf "${C_RED}[ERR]${C_RESET}  %s\n" "$1" >&2; }

# Cleanup function (triggered on EXIT)
cleanup() {
    # No temporary files are created, but we reset cursor/colors just in case.
    # If the script was interrupted, this ensures the terminal isn't borked.
    printf "${C_RESET}"
}
trap cleanup EXIT

# --- 4. Pre-flight Checks ---

check_dependencies() {
    # Pure bash check for existence without spawning a subshell
    if ! command -v "$BIN_TLDR" >/dev/null 2>&1; then
        log_error "Command '$BIN_TLDR' not found."
        log_error "Install it via pacman: sudo pacman -S tealdeer (recommended) or tldr"
        exit 1
    fi
}

check_connectivity() {
    # Quick, lightweight connectivity check before attempting update
    # Uses /dev/tcp bash feature to avoid external ping binaries if possible
    log_info "Verifying connectivity..."
    if ! timeout 2 bash -c 'cat < /dev/null > /dev/tcp/tldr.sh/443' 2>/dev/null; then
        log_error "No internet connection to tldr.sh. Update aborted."
        exit 1
    fi
}

# --- 5. Main Execution ---

main() {
    log_info "Initializing tldr cache update for User: ${USER}"
    
    check_dependencies
    check_connectivity

    log_info "Executing update..."
    
    # Run the update.
    # Note: We do not capture stdout/stderr to a file (Clean constraint).
    # We let tldr stream its own output if it's verbose, or handle errors via '||'.
    if "$BIN_TLDR" --update; then
        echo "" # Newline for visual separation
        log_success "TLDR cache updated successfully."
    else
        echo ""
        log_error "Failed to update TLDR cache."
        exit 1
    fi
}

# Execute Main
main "$@"
