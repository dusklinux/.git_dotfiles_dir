#!/usr/bin/env bash
# ==============================================================================
# Script: 063_hyprexpo_plugin.sh
# Description: Toggles Hyprland HyprExpo plugin and manages hyprpm dependencies.
# Environment: Arch Linux / Hyprland / UWSM
# Author: Elite DevOps (AI)
# ==============================================================================

# 1. Safety & Configuration
set -euo pipefail
IFS=$'\n\t'

# Trap for clean exit
cleanup() {
  # Reset cursor if hidden by a spinner or unfinished output
  printf "\e[?25h"
}
trap cleanup EXIT INT TERM

# 2. Variables & Constants
# Colors for feedback (Using ANSI-C quoting for robustness)
readonly C_RESET=$'\033[0m'
readonly C_INFO=$'\033[1;34m'    # Blue
readonly C_SUCCESS=$'\033[1;32m' # Green
readonly C_WARN=$'\033[1;33m'    # Yellow
readonly C_ERR=$'\033[1;31m'     # Red

# Configuration Files
readonly HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
readonly KEY_CONF="$HOME/.config/hypr/source/keybinds.conf"
readonly PLUGINS_REPO="https://github.com/hyprwm/hyprland-plugins"

# Patterns to match
# NOTE: Exact string matching for your config
readonly PATTERN_KEYBIND="bindd = ALT, TAB, Toggle Expo, hyprexpo:expo, toggle"
readonly PATTERN_PLUGIN_SRC="source = ~/.config/hypr/source/plugins.conf"

# 3. Helper Functions
log_info() { printf "${C_INFO}[INFO]${C_RESET} %s\n" "$1"; }
log_success() { printf "${C_SUCCESS}[OK]${C_RESET} %s\n" "$1"; }
log_warn() { printf "${C_WARN}[WARN]${C_RESET} %s\n" "$1"; }
log_error() { printf "${C_ERR}[ERROR]${C_RESET} %s\n" "$1" >&2; }

# Function to check file existence
ensure_file() {
  if [[ ! -f "$1" ]]; then
    log_error "Configuration file not found: $1"
    return 1
  fi
}

# Function to modify file in-place (No backup files created)
# Usage: modify_line "file" "pattern" "action (comment/uncomment)"
modify_config() {
  local file="$1"
  local pattern="$2"
  local action="$3"
  local esc_pattern

  # Escape strictly regex meta-characters for grep (EXCLUDING forward slash /)
  # This prevents 'grep: warning: stray \ before /'
  esc_pattern=$(printf '%s\n' "$pattern" | sed 's/[][\.*^$]/\\&/g')

  if [[ "$action" == "uncomment" ]]; then
    # Uncomment: Find line starting with optional space + # + optional space + pattern
    # We use pipe | delimiter in sed so paths (/) don't break the command
    if grep -qE "^[[:space:]]*#[[:space:]]*${esc_pattern}" "$file"; then
      sed -i "s|^[[:space:]]*#[[:space:]]*${esc_pattern}|${pattern}|" "$file"
      log_success "Uncommented in $(basename "$file"): '$pattern'"
    elif grep -qE "^[[:space:]]*${esc_pattern}" "$file"; then
      log_info "Already enabled in $(basename "$file"): '$pattern'"
    else
      log_warn "Pattern not found to uncomment in $(basename "$file")"
    fi
  elif [[ "$action" == "comment" ]]; then
    # Comment: Find line starting with pattern (no #)
    if grep -qE "^[[:space:]]*${esc_pattern}" "$file"; then
      sed -i "s|^[[:space:]]*${esc_pattern}|# ${pattern}|" "$file"
      log_success "Commented out in $(basename "$file"): '$pattern'"
    elif grep -qE "^[[:space:]]*#[[:space:]]*${esc_pattern}" "$file"; then
      log_info "Already disabled in $(basename "$file"): '$pattern'"
    else
      log_warn "Pattern not found to comment in $(basename "$file")"
    fi
  fi
}

# 4. Main Execution Flow
main() {
  # Verify environment files exist
  ensure_file "$HYPR_CONF"
  ensure_file "$KEY_CONF"

  # User Interaction
  printf "\n${C_INFO}HyprExpo Configuration Manager${C_RESET}\n"
  
  # --- UPDATED PROMPT SECTION ---
  printf "This plugin provides an overview/birdseye window viewer (ALT+TAB).\n"
  printf "${C_WARN}RECOMMENDATION:${C_RESET} It is strongly recommended to ${C_WARN}DISABLE${C_RESET} this plugin for now, as it causes problems sometimes.\n"
  printf "You can run this script individually later from the scripts directory to enable it safely.\n"
  
  # FIX: Add a small delay.
  # Since 'printf' above goes through the Orchestra pipe (buffered), and the prompt below 
  # goes directly to TTY (instant), we need to wait for the pipe to catch up (flush)
  # so the text appears in the correct order.
  sleep 0.5
  
  # FIX: Write to /dev/tty to bypass Orchestra tee buffering so prompt is visible
  # FIX: Force read from /dev/tty to bypass empty stdin pipe
  printf "Do you want to enable HyprExpo? [y/N]: " >/dev/tty
  read -r choice < /dev/tty

  # Default to 'no' if choice is empty
  if [[ -z "$choice" ]]; then
    choice="no"
  fi

  case "${choice,,}" in
  y | yes)
    ACTION="enable"
    ;;
  n | no)
    ACTION="disable"
    ;;
  *)
    log_error "Invalid input. Exiting."
    exit 1
    ;;
  esac
  # -----------------------------

  # Logic: Disable
  if [[ "$ACTION" == "disable" ]]; then
    log_info "Disabling HyprExpo configuration..."

    # 1. Comment out keybind
    modify_config "$KEY_CONF" "$PATTERN_KEYBIND" "comment"

    # 2. Comment out plugin source
    modify_config "$HYPR_CONF" "$PATTERN_PLUGIN_SRC" "comment"

    log_success "HyprExpo disabled. Reloading Hyprland..."
    # FIX: Add || true to prevent script failure if socket is busy
    hyprctl reload >/dev/null || true
    exit 0
  fi

  # Logic: Enable
  if [[ "$ACTION" == "enable" ]]; then
    log_info "Enabling HyprExpo configuration..."

    # 1. Uncomment keybind
    modify_config "$KEY_CONF" "$PATTERN_KEYBIND" "uncomment"

    # 2. Uncomment plugin source
    modify_config "$HYPR_CONF" "$PATTERN_PLUGIN_SRC" "uncomment"

    # 3. Hyprpm Operations
    if ! command -v hyprpm &>/dev/null; then
      log_error "'hyprpm' is not installed. Please install it to use plugins."
      exit 1
    fi

    log_info "Initializing Plugin Manager (hyprpm)..."
    log_warn "Output is shown below. Please enter sudo password if requested."

    # Update headers
    printf "\n${C_INFO}-> Running: hyprpm update${C_RESET}\n"
    if ! hyprpm update; then
      log_error "Could not update hyprpm headers."
      exit 1
    fi

    # Add Plugin Repo
    # We pipe 'yes' to handle the "Do you trust this author? [Y/n]" prompt automatically
    printf "\n${C_INFO}-> Running: hyprpm add (auto-confirming trust)${C_RESET}\n"
    
    # FIX: Disable pipefail temporarily. 'yes' often triggers SIGPIPE (141) if hyprpm 
    # exits early (e.g. repo already exists), causing the script to fail spuriously.
    set +o pipefail
    if ! yes | hyprpm add "$PLUGINS_REPO"; then
      log_warn "Repo add finished with status $?. Proceeding assuming success or already exists."
    fi
    set -o pipefail

    # Enable HyprExpo
    printf "\n${C_INFO}-> Running: hyprpm enable hyprexpo${C_RESET}\n"
    if hyprpm enable hyprexpo; then
      log_success "Plugin enabled successfully."
    else
      log_error "Failed to enable hyprexpo."
      exit 1
    fi

    log_success "Configuration complete. Reloading Hyprland..."
    # FIX: Add || true
    hyprctl reload >/dev/null || true
  fi
}

main "$@"
