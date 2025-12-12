#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: mount_setup.sh
# Description: Interactive creation of mount points in /mnt
# System: Arch Linux / Hyprland / UWSM
# Author: Gemini (DevOps Architect)
# -----------------------------------------------------------------------------

# --- Configuration ---
# Easily configure default directories here.
# These will be created inside the BASE_DIR.
readonly BASE_DIR="/mnt"
readonly DEFAULT_DIRS=(
  "windows"
  "wdslow"
  "wdfast"
  "fast"
  "slow"
  "media"
  "enclosure"
)

# --- Styling & Colors ---
readonly C_RESET='\033[0m'
readonly C_BOLD='\033[1m'
readonly C_GREEN='\033[32m'
readonly C_BLUE='\033[34m'
readonly C_YELLOW='\033[33m'
readonly C_RED='\033[31m'

# --- Safety & Error Handling ---
set -euo pipefail

# Trap for clean exit on signals (SIGINT, SIGTERM)
trap cleanup EXIT INT TERM

cleanup() {
  # Reset colors on exit
  printf "%b" "${C_RESET}"
}

# --- Logging Functions ---
log_info() { printf "%b[INFO]%b  %b\n" "${C_BLUE}" "${C_RESET}" "$1"; }
log_success() { printf "%b[OK]%b    %b\n" "${C_GREEN}" "${C_RESET}" "$1"; }
log_warn() { printf "%b[WARN]%b  %b\n" "${C_YELLOW}" "${C_RESET}" "$1"; }
log_err() { printf "%b[ERR]%b   %b\n" "${C_RED}" "${C_RESET}" "$1" >&2; }

# --- Root Privilege Check (Auto-Escalate) ---
check_privileges() {
  if [[ "${EUID}" -ne 0 ]]; then
    log_info "Root privileges required. Elevating..."
    # Preserve environment to keep terminal settings, re-execute the script
    if exec sudo -E "$0" "$@"; then
      exit 0
    else
      log_err "Failed to acquire root permissions."
      exit 1
    fi
  fi
}

# --- Logic ---
main() {
  check_privileges

  local -a target_dirs
  local user_input

  clear
  printf "%b=== Arch Mount Point Setup ===%b\n\n" "${C_BOLD}" "${C_RESET}"
  log_info "Base directory: ${C_BOLD}${BASE_DIR}${C_RESET}"
  log_info "Default targets: ${C_BOLD}${DEFAULT_DIRS[*]}${C_RESET}"

  printf "\n%bHow would you like to proceed?%b\n" "${C_BOLD}" "${C_RESET}"
  printf "  [Y] Use defaults (Create all)\n"
  printf "  [C] Custom selection (Enter names)\n"
  printf "  [N] Cancel\n"

  # Read single character, silent input
  read -r -p $'\n> ' user_choice

  case "${user_choice,,}" in # ,, converts to lowercase
  y | yes | '')
    target_dirs=("${DEFAULT_DIRS[@]}")
    ;;
  c | custom)
    printf "\n%bEnter directory names separated by space:%b\n" "${C_BLUE}" "${C_RESET}"
    read -r -p "> " -a custom_input_array

    if [[ ${#custom_input_array[@]} -eq 0 ]]; then
      log_err "No names entered. Exiting."
      exit 1
    fi
    target_dirs=("${custom_input_array[@]}")
    ;;
  n | no)
    log_info "Operation cancelled by user."
    exit 0
    ;;
  *)
    log_err "Invalid selection."
    exit 1
    ;;
  esac

  printf "\n"
  log_info "Processing ${#target_dirs[@]} directory(s)..."

  for dir_name in "${target_dirs[@]}"; do
    # Sanitize input: Remove slashes to prevent directory traversal
    local clean_name="${dir_name//\//}"
    local full_path="${BASE_DIR}/${clean_name}"

    # Skip empty strings
    [[ -z "$clean_name" ]] && continue

    if [[ -d "$full_path" ]]; then
      log_warn "Skipping '${clean_name}': Already exists at ${full_path}"
    else
      if mkdir -p "$full_path"; then
        log_success "Created: ${full_path}"
        # Optional: Set permissions if needed (currently root:root 755 default)
        # chmod 755 "$full_path"
      else
        log_err "Failed to create: ${full_path}"
      fi
    fi
  done

  printf "\n"
  log_success "Operation complete."
}

main "$@"
