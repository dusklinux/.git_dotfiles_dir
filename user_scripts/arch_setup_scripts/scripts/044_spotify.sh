#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Script: 044_spotify.sh
# Description: Installs Spotify via Paru or Yay and runs SpotX verbatim.
#              Does NOT delete SpotX backups.
#              Asks for user confirmation before proceeding.
# -----------------------------------------------------------------------------

# --- Strict Error Handling ---
set -euo pipefail
IFS=$'\n\t'

# --- Styling & Colors ---
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_INFO=$'\033[34m'    # Blue
readonly C_SUCCESS=$'\033[32m' # Green
readonly C_ERR=$'\033[31m'     # Red
readonly C_WARN=$'\033[33m'    # Yellow

# --- Logging Helpers (Stdout only, no log files) ---
log_info() { printf "${C_BOLD}${C_INFO}[INFO]${C_RESET} %s\n" "$1"; }
log_success() { printf "${C_BOLD}${C_SUCCESS}[OK]${C_RESET} %s\n" "$1"; }
log_error() { printf "${C_BOLD}${C_ERR}[ERROR]${C_RESET} %s\n" "$1" >&2; }

# --- Cleanup Trap ---
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code $exit_code."
    fi
    # No variable unsetting or file deletion needed here.
}
trap cleanup EXIT

# --- Global Variables ---
AUR_HELPER=""

# --- Prerequisite Checks ---
check_environment() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run as root. AUR helpers require a non-root user."
        exit 1
    fi

    # Check for paru, then yay, else fail
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    else
        log_error "Neither 'paru' nor 'yay' was found. Please install an AUR helper first."
        exit 1
    fi
}

# --- Main Logic ---

check_environment

# 0. User Confirmation
# Using printf to maintain color consistency with the prompt
printf "${C_BOLD}${C_WARN}[?]${C_RESET} Do you want to install Spotify? [y/N] "
read -r response

# Check if response starts with y or Y. Default is No.
if [[ ! "$response" =~ ^[yY](es)?$ ]]; then
    log_info "Okay, I won't install Spotify."
    exit 0
fi

# 1. Install/Reinstall Spotify
log_info "Installing Spotify via $AUR_HELPER..."
if "$AUR_HELPER" -S --noconfirm spotify; then
    log_success "Spotify installed successfully."
else
    log_error "$AUR_HELPER failed to install Spotify."
    exit 1
fi

# 2. Run SpotX Verbatim
log_info "Executing SpotX script..."
# Using 'curl -sSL' ensures we follow redirects silently, piped directly to bash.
# We do not interfere with the script's internal logic or backups.
bash <(curl -sSL https://spotx-official.github.io/run.sh)

log_success "Process finished. Spotify is ready."
