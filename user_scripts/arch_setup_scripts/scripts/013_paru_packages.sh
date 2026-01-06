#!/usr/bin/env bash
# To install AUR packages
# ==============================================================================
# Script Name: install_pkg_manifest.sh
# Description: Autonomous AUR/Repo package installer with failure intervention.
# Context:     Arch Linux (Rolling) | Hyprland | UWSM
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. STRICT SAFETY & SETTINGS
# ------------------------------------------------------------------------------
# -u: Treat unset variables as an error
# -o pipefail: Pipeline fails if any command fails
# We do NOT use -e globally because we need to continue if one package fails.
set -uo pipefail

# ------------------------------------------------------------------------------
# 2. VISUALS & LOGGING
# ------------------------------------------------------------------------------
# ANSI Colors for clean output
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_YELLOW=$'\033[1;33m'
readonly C_RED=$'\033[1;31m'
readonly C_CYAN=$'\033[1;36m'

log_info() { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"; }
log_success() { printf "${C_GREEN}[SUCCESS]${C_RESET} %s\n" "$1"; }
log_warn() { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$1"; }
log_err() { printf "${C_RED}[ERROR]${C_RESET} %s\n" "$1"; }
log_task() { printf "\n${C_BOLD}${C_CYAN}:: %s${C_RESET}\n" "$1"; }

# ------------------------------------------------------------------------------
# 3. CLEANUP & TRAPS
# ------------------------------------------------------------------------------
cleanup() {
  # Restore cursor if it was hidden
  tput cnorm
  # Reset colors
  printf "${C_RESET}"
}
trap cleanup EXIT INT TERM

# ------------------------------------------------------------------------------
# 4. PRE-FLIGHT CHECKS
# ------------------------------------------------------------------------------
# Constraint: AUR helpers should NOT be run as root.
if [[ $EUID -eq 0 ]]; then
  log_err "This script must NOT be run as root."
  log_err "AUR helpers like 'paru' or 'yay' handle sudo privileges internally."
  log_err "Please run as your normal user."
  exit 1
fi

# Smart Detection: Check for paru, fallback to yay
AUR_HELPER=""
if command -v paru &>/dev/null; then
  AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
  AUR_HELPER="yay"
else
  log_err "Critical dependency missing. Neither 'paru' nor 'yay' found."
  exit 1
fi

# ------------------------------------------------------------------------------
# 5. CONFIGURATION
# ------------------------------------------------------------------------------
# User Package Manifest - Edit this array to add/remove packages.
readonly PACKAGES=(
  "wlogout"
  "adwaita-qt6"
  "adwaita-qt5"
  "otf-atkinson-hyperlegible-next"
  "fluent-icon-theme-git"

  # installing manually with script because this is a massive package that includes every cursor theme
  # "bibata-cursor-theme-bin"

  "python-pywalfox"
  "hyprshade"
  "waypaper"
  "peaclock"
  "tray-tui"
  "wifitui-bin"
  "xdg-terminal-exec"
)

# Only wait this long if an error occurs and intervention is requested.
readonly TIMEOUT_SEC=10

# ------------------------------------------------------------------------------
# 6. MAIN LOGIC
# ------------------------------------------------------------------------------
main() {
  log_task "Starting Autonomous Package Installation Sequence"
  log_info "Target Packages: ${#PACKAGES[@]}"
  log_info "Using AUR Helper: ${C_BOLD}${AUR_HELPER}${C_RESET}"
  log_info "Mode: Fully Automatic. Intervention only on Error (${TIMEOUT_SEC}s timeout)."

  local success_count=0
  local fail_count=0
  local failed_pkgs=()

  # Perform a system update first (Standard Arch Practice)
  log_task "Synchronizing Repositories (${AUR_HELPER} -Sy)..."
  if ! "$AUR_HELPER" -Sy; then
    log_err "Failed to synchronize repositories. Aborting to prevent partial states."
    exit 1
  fi

  for pkg in "${PACKAGES[@]}"; do
    log_task "Processing: ${pkg}"

    # 1. Check if already installed
    if "$AUR_HELPER" -Qi "$pkg" &>/dev/null; then
      log_success "${pkg} is already installed. Skipping."
      continue
    fi

    # 2. Autonomous Installation
    log_info "Auto-installing ${pkg}..."
    
    # We use --noconfirm to automate "Yes" prompts.
    # We DO NOT hide output (no &>/dev/null) so you see download progress.
    if "$AUR_HELPER" -S --needed --noconfirm "$pkg"; then
      log_success "Installed ${pkg} (Auto)."
      ((success_count++))
    else
      # 3. Conflict/Error Handling
      # If we are here, auto-install failed (PGP key issue, conflict, build fail).
      printf "\n"
      log_warn "Automatic install failed for ${pkg}."
      printf "${C_YELLOW}  -> Conflict/Error detected. Retry manually? [y/N] (Waiting %ss)... ${C_RESET}" "$TIMEOUT_SEC"

      local user_input=""
      
      # Wait strictly 10 seconds. If no input, we skip.
      if read -t "$TIMEOUT_SEC" -n 1 -s user_input; then
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
          printf "\n"
          log_info "Switching to Manual Mode for ${pkg}..."
          
          # Run without --noconfirm to allow user to handle conflicts/keys
          if "$AUR_HELPER" -S "$pkg"; then
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

      # Timeout or User said No
      printf "\n"
      log_err "Skipping ${pkg} (Resolution timed out or skipped)."
      ((fail_count++))
      failed_pkgs+=("$pkg")
    fi

  done

  # --------------------------------------------------------------------------
  # 7. SUMMARY
  # --------------------------------------------------------------------------
  printf "\n"
  printf "${C_BOLD}========================================${C_RESET}\n"
  printf "${C_BOLD} INSTALLATION SUMMARY ${C_RESET}\n"
  printf "${C_BOLD}========================================${C_RESET}\n"
  log_info "Successful: ${success_count}"

  if [[ $fail_count -gt 0 ]]; then
    log_err "Failed: ${fail_count}"
    log_err "The following packages failed to install:"
    for f in "${failed_pkgs[@]}"; do
      printf "   - %s\n" "$f"
    done
  else
    log_success "All requested packages processed successfully."
  fi

  printf "\n"
}

main "$@"
