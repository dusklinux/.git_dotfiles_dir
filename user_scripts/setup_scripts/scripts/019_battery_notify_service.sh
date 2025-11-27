#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: install_battery_notify.sh
# Description: Symlinks and enables the battery_notify service.
# Environment: Arch Linux / Hyprland / UWSM
# Author: DevOps Assistant
# -----------------------------------------------------------------------------

# --- Strict Error Handling ---
set -euo pipefail

# --- Styling & Colors ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# --- Configuration ---
readonly SERVICE_NAME="battery_notify.service"
# Respect XDG_CONFIG_HOME, default to ~/.config if unset
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly SYSTEMD_USER_DIR="${CONFIG_DIR}/systemd/user"
# Based on the specific command provided:
readonly SOURCE_FILE="$HOME/user_scripts/battery/notify/${SERVICE_NAME}"
readonly TARGET_LINK="${SYSTEMD_USER_DIR}/${SERVICE_NAME}"

# --- Helper Functions ---
log_info() {
  printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

log_success() {
  printf "${GREEN}[OK]${NC} %s\n" "$1"
}

log_error() {
  printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
}

# Cleanup/Error Trap
cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_error "Script failed with exit code $exit_code."
  fi
}
trap cleanup EXIT

# --- Main Logic ---

main() {
  log_info "Initializing battery notify installation..."

  # 1. Validation: Ensure source exists
  if [[ ! -f "$SOURCE_FILE" ]]; then
    log_error "Source file not found at: $SOURCE_FILE"
    return 1
  fi

  # 2. Preparation: Ensure target directory exists
  if [[ ! -d "$SYSTEMD_USER_DIR" ]]; then
    log_info "Creating systemd user directory: $SYSTEMD_USER_DIR"
    mkdir -p "$SYSTEMD_USER_DIR"
  fi

  # 3. Execution: Create Symlink
  # -n: Treat destination as a normal file if it is a directory (no dereference)
  # -f: Force removal of existing destination files
  # -s: Symbolic link
  log_info "Linking service file..."
  ln -nfs "$SOURCE_FILE" "$TARGET_LINK"

  # 4. Systemd Registration
  log_info "Reloading systemd user daemon..."
  systemctl --user daemon-reload

  log_info "Enabling and starting $SERVICE_NAME..."
  systemctl --user enable --now "$SERVICE_NAME"

  log_success "Battery notification service installed and running."
}

main
