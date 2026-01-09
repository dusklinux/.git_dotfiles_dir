#!/usr/bin/env bash
# Sets up Warp VPN that can later be toggled on/off from Rofi menu.
# -----------------------------------------------------------------------------
# Metadata
# -----------------------------------------------------------------------------
# Description: Fully autonomous setup of Cloudflare Warp.
#              - Manual clean build (bypasses sudo prompts).
#              - Runs warp-cli as SUDO_USER.
#              - Includes Smart Polling for connection verification.
# -----------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Visuals
# -----------------------------------------------------------------------------
readonly C_RESET=$'\033[0m'
readonly C_GREEN=$'\033[32m'
readonly C_BLUE=$'\033[34m'
readonly C_RED=$'\033[31m'
readonly C_CYAN=$'\033[36m'
readonly C_YELLOW=$'\033[33m'

log_info() { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$*"; }
log_success() { printf "${C_GREEN}[OK]${C_RESET}   %s\n" "$*"; }
log_error() { printf "${C_RED}[ERR]${C_RESET}  %s\n" "$*" >&2; }
log_warn() { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$*"; }
log_step() { printf "\n${C_CYAN}:: %s${C_RESET}\n" "$*"; }

# -----------------------------------------------------------------------------
# Context Checks
# -----------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  log_error "This script must be run with sudo."
  exit 1
fi

REAL_USER="${SUDO_USER:-}"
if [[ -z "$REAL_USER" ]]; then
  log_error "Could not detect SUDO_USER. Run via: sudo ./script.sh"
  exit 1
fi

BUILD_DIR="/tmp/warp_autonomous_build"

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
cleanup() {
  if [[ -d "$BUILD_DIR" ]]; then
    rm -rf "$BUILD_DIR"
  fi
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Helper: Run command as the Real User
# -----------------------------------------------------------------------------
run_as_user() {
  sudo -u "$REAL_USER" -- "$@"
}

# -----------------------------------------------------------------------------
# Core Logic
# -----------------------------------------------------------------------------

install_package_manual() {
  log_step "Preparing Build Environment..."
  pacman -S --noconfirm --needed git base-devel

  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"
  chown -R "$REAL_USER":"$REAL_USER" "$BUILD_DIR"

  log_info "Cloning AUR repository as user: $REAL_USER"
  run_as_user git clone --quiet https://aur.archlinux.org/cloudflare-warp-nox-bin.git "$BUILD_DIR"

  cd "$BUILD_DIR" || exit 1

  log_info "Building package (makepkg)..."
  if ! run_as_user makepkg -f --noconfirm; then
    log_error "Build failed."
    exit 1
  fi

  log_info "Installing built package..."
  local pkg_file
  # Match any compression format (zst, xz, gz)
  pkg_file=$(find . -maxdepth 1 -name "*.pkg.tar.*" -print -quit)

  if [[ -n "$pkg_file" && -f "$pkg_file" ]]; then
    pacman -U --noconfirm "$pkg_file"
    log_success "Package installed successfully."
  else
    log_error "Could not locate built package file."
    exit 1
  fi
}

configure_service() {
  log_step "Initializing Service..."
  systemctl enable --now warp-svc.service

  log_info "Polling for socket availability..."
  local retries=0
  while ! systemctl is-active --quiet warp-svc.service; do
    if [[ $retries -ge 10 ]]; then
      log_error "Service timed out."
      exit 1
    fi
    sleep 1
    retries=$((retries + 1))  # FIX: Avoids set -e trap when retries=0
  done

  # Wait for internal daemon DB
  log_info "Waiting for daemon internal state..."
  sleep 5
}

setup_warp() {
  log_step "Configuring Warp (As user: $REAL_USER)..."

  # 1. Cleanup (CRITICAL FIX APPLIED HERE)
  log_info "Checking registration state..."
  if echo "y" | run_as_user warp-cli --accept-tos registration delete &>/dev/null; then
    log_success "Old registration deleted."
  else
    log_info "No valid prior registration found (or clean slate)."
  fi

  # 2. Register
  log_info "Registering new client..."
  local reg_success=0
  for i in {1..3}; do
    if echo "y" | run_as_user warp-cli --accept-tos registration new; then
      reg_success=1
      break
    else
      log_warn "Registration failed. Retrying... ($i/3)"
      sleep 2
    fi
  done

  if [[ $reg_success -eq 0 ]]; then
    log_error "Failed to register after multiple attempts."
    exit 1
  else
    log_success "Registration successful."
  fi

  # 3. Connect & Poll
  log_info "Connecting..."
  if run_as_user warp-cli --accept-tos connect; then
    log_info "Verifying connection..."

    # Polling Loop (Max 10 seconds)
    local connected=0
    for _ in {1..10}; do
      if run_as_user warp-cli --accept-tos status | grep -q "Connected"; then
        connected=1
        break
      fi
      sleep 1
    done

    if [[ $connected -eq 1 ]]; then
      log_success "Warp is Connected and Secured."
    else
      log_error "Connection timed out. Run 'warp-cli status' manually."
      exit 1
    fi
  else
    log_error "Failed to issue connect command."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  log_info "Starting Setup for User: $REAL_USER"

  if ! pacman -Qi cloudflare-warp-nox-bin &>/dev/null; then
    install_package_manual
  else
    log_success "Package already installed."
  fi

  configure_service
  setup_warp

  log_step "All Done. Traffic is secured."
}

# -----------------------------------------------------------------------------
# User Interaction / Pre-check
# -----------------------------------------------------------------------------
if ! command -v warp-cli &> /dev/null; then
  printf "${C_YELLOW}[?]${C_RESET} Cloudflare Warp is not installed.\n"
  read -r -p "Would you like to install and activate it? [Y/n] " response
  response=${response:-Y}
  
  if [[ "$response" =~ ^[nN]([oO])?$ ]]; then
    log_info "Installation aborted by user."
    exit 0
  fi
fi

main
