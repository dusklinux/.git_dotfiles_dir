#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: setup_dotfiles.sh
# Description: Bootstraps dotfiles using a bare git repository method.
# Target: Arch Linux / Hyprland / UWSM environment
# Author: Elite DevOps Engineer
# -----------------------------------------------------------------------------

# strict mode: exit on error, undefined vars, or pipe failures
set -euo pipefail

# -----------------------------------------------------------------------------
# Constants & Configuration
# -----------------------------------------------------------------------------
readonly REPO_URL="https://github.com/dusklinux/dusky"
readonly DOTFILES_DIR="${HOME}/dusky"
readonly GIT_EXEC="/usr/bin/git"

# ANSI Color Codes for modern, readable output
readonly C_RESET='\033[0m'
readonly C_INFO='\033[1;34m'    # Bold Blue
readonly C_SUCCESS='\033[1;32m' # Bold Green
readonly C_ERROR='\033[1;31m'   # Bold Red
readonly C_WARN='\033[1;33m'    # Bold Yellow

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
log_info() {
    printf "${C_INFO}[INFO]${C_RESET} %s\n" "$1"
}

log_success() {
    printf "${C_SUCCESS}[OK]${C_RESET} %s\n" "$1"
}

log_error() {
    printf "${C_ERROR}[ERROR]${C_RESET} %s\n" "$1" >&2
}

# Cleanup function to be trapped on exit
cleanup() {
    # If the script fails halfway, we might want to alert the user.
    # Since we aren't creating temp files, this is minimal.
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code $exit_code."
    fi
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------
main() {
    # 1. Pre-flight Checks
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed. Please run 'pacman -S git' first."
        exit 1
    fi

    log_info "Starting dotfiles bootstrap for user: $USER"
    log_info "Target Directory: $DOTFILES_DIR"

    # --- ADDED COMMAND START ---
    # Cleaning up existing directory to ensure a fresh clone
    rm -rf "$DOTFILES_DIR"
    # --- ADDED COMMAND END ---

    # 2. Clone the Bare Repository
    if [[ -d "$DOTFILES_DIR" ]]; then
        printf "${C_WARN}[WARN]${C_RESET} Directory %s already exists. Skipping clone.\n" "$DOTFILES_DIR"
    else
        log_info "Cloning bare repository..."
        
        # Using --depth 1 for speed (shallow clone) as requested
        if "$GIT_EXEC" clone --bare --depth 1 "$REPO_URL" "$DOTFILES_DIR"; then
            log_success "Repository cloned successfully."
        else
            log_error "Failed to clone repository."
            exit 1
        fi
    fi

    # 3. Checkout Files
    log_info "Checking out configuration files to $HOME..."
    log_info "NOTE: This will overwrite existing files (forced checkout)."

    # We explicitly define git-dir and work-tree to bridge the bare repo to $HOME
    if "$GIT_EXEC" --git-dir="$DOTFILES_DIR/" --work-tree="$HOME" checkout -f; then
        log_success "Dotfiles checked out successfully."
    else
        log_error "Checkout failed. You may have conflicting files that git cannot overwrite despite -f."
        exit 1
    fi

    # 4. Completion
    log_success "Setup complete. Your Hyprland/UWSM environment is ready."
}

# Invoke main
main
