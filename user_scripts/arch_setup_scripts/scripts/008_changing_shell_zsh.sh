#!/usr/bin/env bash
# Changes shell to ZSH from bash
# ==============================================================================
# Script: switch_to_zsh.sh
# Description: Safely switches the user's shell to Zsh (Sudo-aware).
# Author: Elite DevOps Engineer
# Compatibility: Bash 5+ | Arch Linux
# ==============================================================================

# 1. Strict Mode
set -euo pipefail

# Cleanup on exit
cleanup() {
  printf "\033[0m" # Reset terminal colors
}
trap cleanup EXIT INT TERM

# 2. Formatting (Fixed ANSI-C Quoting)
# Using $'\e...' ensures the variables contain the actual Escape byte,
# preventing literal "\033" strings from appearing in your logs.
BOLD=$'\e[1m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
RED=$'\e[31m'
BLUE=$'\e[34m'
RESET=$'\e[0m'

log_info() { printf "${BLUE}[INFO]${RESET} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${RESET} %s\n" "$1"; }
log_err() { printf "${RED}[ERROR]${RESET} %s\n" "$1" >&2; }

# 3. Logic & Pre-flight
TARGET_SHELL_BIN="zsh"

# 3a. Determine actual target user
# If run with sudo, SUDO_USER holds the name of the real user (dusk).
# If run normally, USER holds the name.
if [[ -n "${SUDO_USER:-}" ]]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="$USER"
fi

# 3b. Verify Zsh installation
if ! command -v "$TARGET_SHELL_BIN" >/dev/null 2>&1; then
  log_err "Zsh is not installed."
  printf "       Run: ${BOLD}sudo pacman -S zsh${RESET} to install it.\n"
  exit 1
fi

TARGET_PATH=$(command -v "$TARGET_SHELL_BIN")

# 3c. Verify /etc/shells
if ! grep -Fxq "$TARGET_PATH" /etc/shells; then
  log_err "'$TARGET_PATH' is not in /etc/shells."
  exit 1
fi

# 3d. Check current shell
CURRENT_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7)

if [[ "$CURRENT_SHELL" == "$TARGET_PATH" ]]; then
  log_success "User '${BOLD}$TARGET_USER${RESET}' is already using Zsh ($TARGET_PATH)."
  exit 0
fi

# 4. Execution
log_info "Current shell: $CURRENT_SHELL"
log_info "Target shell:  $TARGET_PATH"
log_info "Targeting user: ${BOLD}$TARGET_USER${RESET}"

if [[ $EUID -eq 0 ]]; then
  # We are root (e.g. run via sudo).
  # We can change any user's shell without a password.
  chsh -s "$TARGET_PATH" "$TARGET_USER"
else
  # We are a normal user.
  # We must authenticate via PAM (password prompt) to change our own shell.
  chsh -s "$TARGET_PATH"
fi

if [[ $? -eq 0 ]]; then
  log_success "Shell changed successfully for ${BOLD}$TARGET_USER${RESET}."
else
  log_err "Failed to change shell."
  exit 1
fi

exit 0
