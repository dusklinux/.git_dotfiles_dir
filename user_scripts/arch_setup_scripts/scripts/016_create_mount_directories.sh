#!/usr/bin/env bash
# creates mount directories at /mnt/
# -----------------------------------------------------------------------------
# Script: 016_create_mount_directories.sh
# Description: Pre-creates stable mount points in /mnt
# Context: 
#   By default, Linux automounts external drives to dynamic paths like 
#   '/run/media/$USER/Label'. This changes every time you reconnect a drive.
#
#   This script creates PERMANENT directories in '/mnt/name'.
#   This allows you to map your drives via UUID in '/etc/fstab' so they 
#   always appear in the same place for scripts, torrents, and steam libraries.
#
# System: Arch Linux / Hyprland / UWSM
# -----------------------------------------------------------------------------

# --- Configuration ---
readonly BASE_DIR="/mnt"
# These are Dusk's specific mount points
readonly DUSK_PRESETS=(
  "windows"
  "wdslow"
  "wdfast"
  "fast"
  "slow"
  "media"
  "enclosure"
)

# --- Styling & Colors ---
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_GREEN=$'\033[32m'
readonly C_BLUE=$'\033[34m'
readonly C_YELLOW=$'\033[33m'
readonly C_RED=$'\033[31m'

# --- Safety & Error Handling ---
set -euo pipefail

# Trap for clean exit on signals
trap cleanup EXIT INT TERM

cleanup() {
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
  printf "%b=== Arch Mount Point Setup ===%b\n" "${C_BOLD}" "${C_RESET}"
  printf "Standard auto-mount path: %b/run/media/%s/[DriveLabel]%b\n" "${C_YELLOW}" "${USER:-user}" "${C_RESET}"
  printf "Target stable path:       %b%s/[Directory]%b\n\n" "${C_GREEN}" "${BASE_DIR}" "${C_RESET}"
  
  log_info "NOTE: After running this, you must configure UUIDs in /etc/fstab"
  log_info "to mount your drives to these new folders automatically."

  printf "\n%bSelect an option:%b\n" "${C_BOLD}" "${C_RESET}"
  printf "  [D] Create Dusk's Config (windows, wdslow, fast, enclosure, etc.)\n"
  printf "  [C] Custom selection (Enter your own directory names)\n"
  printf "  [E] Exit / Do Nothing (Default)\n"

  # Read single character, silent input
  read -r -p $'\n> ' user_choice

  case "${user_choice,,}" in
  d | dusk)
    target_dirs=("${DUSK_PRESETS[@]}")
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
  e | exit | n | no | '')
    # Default behavior is now to exit
    log_info "No changes made. Exiting."
    exit 0
    ;;
  *)
    log_err "Invalid selection. Exiting."
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
      else
        log_err "Failed to create: ${full_path}"
      fi
    fi
  done

  printf "\n"
  log_success "Directory creation complete."
  printf "%bREMINDER: Edit %b/etc/fstab%b and map your drive UUIDs to these paths!%b\n" "${C_YELLOW}" "${C_BOLD}" "${C_YELLOW}" "${C_RESET}"
}

main "$@"
