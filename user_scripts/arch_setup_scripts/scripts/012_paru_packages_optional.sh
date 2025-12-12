#!/usr/bin/env bash
# ==============================================================================
# Script Name: 012_paru_packages_optional.sh
# Description: Autonomous AUR/Repo package installer with interactive selection.
# Context:     Arch Linux (Rolling) | Hyprland | UWSM
# Author:      Gemini (Elite DevOps Persona)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. STRICT SAFETY & SETTINGS
# ------------------------------------------------------------------------------
set -uo pipefail

# ------------------------------------------------------------------------------
# 2. VISUALS & LOGGING
# ------------------------------------------------------------------------------
# FIX APPLIED: Using $'' ANSI-C quoting for proper escape sequence interpretation.
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_YELLOW=$'\033[1;33m'
readonly C_RED=$'\033[1;31m'
readonly C_CYAN=$'\033[1;36m'
readonly C_MAGENTA=$'\033[1;35m'

# Logging functions write to stderr by default to keep stdout clean for piping if needed
log_info()    { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1" >&2; }
log_success() { printf "${C_GREEN}[SUCCESS]${C_RESET} %s\n" "$1" >&2; }
log_warn()    { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$1" >&2; }
log_err()     { printf "${C_RED}[ERROR]${C_RESET} %s\n" "$1" >&2; }
log_task()    { printf "\n${C_BOLD}${C_CYAN}:: %s${C_RESET}\n" "$1" >&2; }

# ------------------------------------------------------------------------------
# 3. CLEANUP & TRAPS
# ------------------------------------------------------------------------------
cleanup() {
  tput cnorm # Restore cursor
  printf "${C_RESET}" >&2
}
trap cleanup EXIT INT TERM

# ------------------------------------------------------------------------------
# 4. PRE-FLIGHT CHECKS
# ------------------------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
  log_err "This script must NOT be run as root."
  log_err "AUR helpers like 'paru' handle sudo privileges internally."
  exit 1
fi

if ! command -v paru &>/dev/null; then
  log_err "Critical dependency 'paru' is missing."
  exit 1
fi

# ------------------------------------------------------------------------------
# 5. CONFIGURATION
# ------------------------------------------------------------------------------
# NOTE: To add a category, use the prefix "## ".
# The script detects lines starting with "## " as headers, not packages.
readonly AVAILABLE_PACKAGES=(

"## Misc Tools"
"pacseek"
"keypunch-git"
"pinta"
"youtube-dl-gui-bin"
"sysmontask"
"preload"
"edex-ui-bin"

"## Games & Fun"
"pipes.sh"
"2048.c"
"clidle-bin"
"maze-tui"
"vitetris"
"pokete"
"brogue-ce"

"## Asus Hardware"
"wdpass"
"resvg"
"dislocker"
"lazydocker"
"asusctl"

"## Legacy Drivers"
"b43-firmware"
)

readonly TIMEOUT_SEC=10

# ------------------------------------------------------------------------------
# 6. SELECTION LOGIC
# ------------------------------------------------------------------------------
select_packages() {
  local selection_complete=0
  local selected_list=()
  local user_in
  local confirm_choice
  local current_cat="General" # Default category if none specified

  # Count actual packages (excluding headers starting with ##) for display
  local pkg_count=0
  for item in "${AVAILABLE_PACKAGES[@]}"; do
    [[ "$item" != "## "* ]] && ((pkg_count++))
  done

  # 1. Ask for "Install All" shortcut
  log_task "Selection Mode"
  printf "${C_YELLOW}Do you want to install ALL %s optional packages? [y/N] ${C_RESET}" "$pkg_count" >&2
  read -r install_all_choice

  if [[ "$install_all_choice" == "y" || "$install_all_choice" == "Y" ]]; then
    log_info "All packages selected for installation."
    # Output DATA to stdout (Filtering out headers)
    for item in "${AVAILABLE_PACKAGES[@]}"; do
      [[ "$item" != "## "* ]] && printf "%s\n" "$item"
    done
    return
  fi

  # 2. Manual Selection Loop
  while [[ $selection_complete -eq 0 ]]; do
    selected_list=() 
    current_cat="General"
    
    printf "\n${C_BOLD}--- Manual Package Selection ---${C_RESET}\n" >&2
    printf "Instruction: Press 'y' to install, 'Enter' to skip (Default: No).\n\n" >&2

    for pkg in "${AVAILABLE_PACKAGES[@]}"; do
      # CHECK: Is this a Category Header?
      if [[ "$pkg" == "## "* ]]; then
        current_cat="${pkg:3}" # Strip the "## " prefix
        printf "\n${C_BOLD}${C_MAGENTA}:: Group: %s${C_RESET}\n" "$current_cat" >&2
        continue
      fi

      printf " :: Install ${C_CYAN}%s${C_RESET}? [y/N] " "$pkg" >&2
      read -r user_in
      
      if [[ "$user_in" == "y" || "$user_in" == "Y" ]]; then
        selected_list+=("$pkg")
        printf "    ${C_GREEN}-> Added to queue${C_RESET}\n" >&2
      else
        printf "    ${C_MAGENTA}-> Skipped${C_RESET}\n" >&2
      fi
    done

    # 3. Summary and Confirmation
    printf "\n${C_BOLD}--- Selection Summary ---${C_RESET}\n" >&2
    if [[ ${#selected_list[@]} -eq 0 ]]; then
      log_warn "No packages selected."
    else
      for item in "${selected_list[@]}"; do
        printf " + %s\n" "$item" >&2
      done
    fi

    printf "\n" >&2
    printf "${C_YELLOW}Are you happy with this selection? [Y/n] (n = re-select) ${C_RESET}" >&2
    read -r confirm_choice

    if [[ "$confirm_choice" == "n" || "$confirm_choice" == "N" ]]; then
      log_info "Restarting selection process..."
      continue
    else
      selection_complete=1
    fi
  done

  # Output final DATA to stdout to be captured
  printf "%s\n" "${selected_list[@]}"
}

# ------------------------------------------------------------------------------
# 7. MAIN LOGIC
# ------------------------------------------------------------------------------
main() {
  # --- Phase 1: Package Selection ---
  # capture stdout of select_packages into array
  mapfile -t TARGET_PACKAGES < <(select_packages)

  # Check if array is empty
  if [[ ${#TARGET_PACKAGES[@]} -eq 0 ]]; then
    log_success "No packages selected. Exiting script gracefully."
    exit 0
  fi

  # --- Phase 2: Installation ---
  log_task "Starting Installation Sequence"
  log_info "Target Packages: ${#TARGET_PACKAGES[@]}"
  
  local success_count=0
  local fail_count=0
  local failed_pkgs=()

  # Update Repos
  log_task "Synchronizing Repositories (paru -Sy)..."
  if ! paru -Sy; then
    log_err "Failed to synchronize repositories. Aborting."
    exit 1
  fi

  for pkg in "${TARGET_PACKAGES[@]}"; do
    [[ -z "$pkg" ]] && continue # Skip empty lines

    log_task "Processing: ${pkg}"

    # Check installed
    if paru -Qi "$pkg" &>/dev/null; then
      log_success "${pkg} is already installed. Skipping."
      continue
    fi

    # Auto Install
    log_info "Auto-installing ${pkg}..."
    if paru -S --needed --noconfirm "$pkg"; then
      log_success "Installed ${pkg} (Auto)."
      ((success_count++))
    else
      # Failure / Intervention
      printf "\n" >&2
      log_warn "Automatic install failed for ${pkg}."
      printf "${C_YELLOW}  -> Conflict/Error detected. Retry manually? [y/N] (Waiting %ss)... ${C_RESET}" "$TIMEOUT_SEC" >&2

      local user_input=""
      if read -t "$TIMEOUT_SEC" -n 1 -s user_input; then
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
          printf "\n" >&2
          log_info "Switching to Manual Mode for ${pkg}..."
          
          if paru -S "$pkg"; then
            log_success "Installed ${pkg} (Manual Recovery)."
            ((success_count++))
          else
            log_err "Manual install also failed for ${pkg}."
            ((fail_count++))
            failed_pkgs+=("$pkg")
          fi
          continue
        fi
      fi
      
      # Timeout or No
      printf "\n" >&2
      log_err "Skipping ${pkg}."
      ((fail_count++))
      failed_pkgs+=("$pkg")
    fi
  done

  # --- Summary ---
  printf "\n" >&2
  printf "${C_BOLD}========================================${C_RESET}\n" >&2
  printf "${C_BOLD} INSTALLATION SUMMARY ${C_RESET}\n" >&2
  printf "${C_BOLD}========================================${C_RESET}\n" >&2
  log_info "Successful: ${success_count}"

  if [[ $fail_count -gt 0 ]]; then
    log_err "Failed: ${fail_count}"
    log_err "The following packages failed to install:"
    for f in "${failed_pkgs[@]}"; do
      printf "   - %s\n" "$f" >&2
    done
  else
    log_success "All requested packages processed successfully."
  fi
  printf "\n" >&2
}

main "$@"
