#!/usr/bin/env bash
# Enables user services for AUR packages
# ==============================================================================
# ARCH LINUX USER SERVICE ENABLER (Arch/Hyprland/UWSM Context)
# ==============================================================================
# Description: Enables systemd USER services safely and sequentially.
#              Intended for session services (Waybar, Dunst, Pipewire, etc.).
# Logic:       Checks NON-Root -> Iterates Array -> Checks Unit Existence -> Enables
# Standards:   Bash 5+, set -euo pipefail, No Logs, STRICTLY NO SUDO
# ==============================================================================

# --- 1. Strict Error Handling & Safety ---
set -euo pipefail

# --- 2. Configuration (User Editable) ---
# Add your USER services here.
# NOTE: These are services run by your user (no sudo), often specific to Hyprland.
readonly TARGET_USER_SERVICES=(
  "hypridle.service" # Idle daemon

  ##addmore here

)

# --- 3. Formatting & Visuals ---
# Using ANSI-C Quoting ($'\e') for robust color support
readonly C_RESET=$'\e[0m'
readonly C_BOLD=$'\e[1m'
readonly C_GREEN=$'\e[32m'
readonly C_YELLOW=$'\e[33m'
readonly C_RED=$'\e[31m'
readonly C_BLUE=$'\e[34m'
readonly C_PURPLE=$'\e[35m'

log_info() { printf "${C_BLUE}[INFO]${C_RESET}  %s\n" "$1"; }
log_success() { printf "${C_GREEN}[OK]${C_RESET}    %s\n" "$1"; }
log_warn() { printf "${C_YELLOW}[SKIP]${C_RESET}  %s\n" "$1"; }
log_err() { printf "${C_RED}[FAIL]${C_RESET}  %s\n" "$1"; }
log_crit() { printf "${C_RED}${C_BOLD}[ERROR]${C_RESET} %s\n" "$1"; }

# --- 4. Cleanup Trap ---
cleanup() {
  printf "%s" "${C_RESET}"
}
trap cleanup EXIT INT TERM

# --- 5. Root Guard (Prevent Sudo) ---
# Running user services as root is almost always a mistake.
if [[ $EUID -eq 0 ]]; then
  log_crit "Do NOT run this script as root/sudo."
  printf "        These are user-level services. Run simply as: ${C_BOLD}./$(basename "$0")${C_RESET}\n"
  exit 1
fi

# --- 6. Main Logic ---
main() {
  printf "\n${C_BOLD}Starting User Service Initialization (UWSM/Hyprland)...${C_RESET}\n"
  printf "${C_BOLD}-------------------------------------------------------${C_RESET}\n"

  local svc_name

  for svc_name in "${TARGET_USER_SERVICES[@]}"; do
    # 6a. Check if the unit exists in user paths (~/.config/systemd/user or /usr/lib/systemd/user)
    # Note: We use 'systemctl --user' here
    if systemctl --user list-unit-files "$svc_name" &>/dev/null; then

      # 6b. Attempt to enable and start
      if output=$(systemctl --user enable --now "$svc_name" 2>&1); then
        log_success "Enabled & Started: ${C_PURPLE}$svc_name${C_RESET}"
      else
        log_err "Could not enable $svc_name. Reason:"
        printf "      %s\n" "$output"
      fi

    else
      # 6c. Handle missing services gracefully
      log_warn "Service not found: ${C_PURPLE}$svc_name${C_RESET}. Skipping..."
    fi
  done

  printf "${C_BOLD}-------------------------------------------------------${C_RESET}\n"
  log_info "User services updated."
  printf "\n"
}

main "$@"
