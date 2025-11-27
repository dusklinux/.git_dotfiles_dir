#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: 009_aur_paru_final.sh
# Description: Automated Paru installer (Root/Sudo mode).
#              Combines best-practice safety checks with Arch-compliant pkg mgmt.
# Author: Arch Linux Systems Architect
# -----------------------------------------------------------------------------

# --- Strict Mode ---
set -euo pipefail

# --- Configuration ---
readonly PARU_URL="https://aur.archlinux.org/paru.git"
# We include 'rust' here so makepkg doesn't stop to ask for it
readonly BUILD_DEPS=("base-devel" "git" "rust")

# --- Formatting ---
readonly BLUE='\033[0;34m'
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

# --- Cleanup Trap ---
BUILD_DIR=""
cleanup() {
  local exit_code=$?
  if [[ -n "${BUILD_DIR:-}" && -d "${BUILD_DIR}" ]]; then
    log_info "Cleaning up temporary build context..."
    rm -rf "${BUILD_DIR}"
  fi
  if [[ $exit_code -ne 0 ]]; then
    log_error "Script failed with exit code $exit_code"
  fi
}
trap cleanup EXIT

# --- Main Execution ---
main() {
  # 1. Root Validation
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (sudo)."
    log_error "Usage: sudo $0"
    exit 1
  fi

  # 2. Identify Real User
  local real_user="${SUDO_USER:-}"
  if [[ -z "$real_user" ]]; then
    log_error "SUDO_USER is unset. Run via 'sudo ./script.sh'"
    exit 1
  fi

  local real_group
  real_group=$(id -gn "$real_user")

  # 3. Idempotency Check (Check Database, not just PATH)
  if pacman -Qi paru &>/dev/null; then
    log_success "Paru is already installed in the Pacman DB. Skipping."
    exit 0
  fi

  log_info "Initiating Paru Auto-Install for user: ${real_user}"

  # 4. System Prep (Root)
  # CRITICAL FIX: Removed '-y' to prevent partial upgrades.
  # Assumes user keeps their system reasonably up to date.
  log_info "Verifying build dependencies..."
  pacman -S --needed --noconfirm "${BUILD_DEPS[@]}"

  # 5. Prepare Build Environment
  BUILD_DIR=$(mktemp -d)
  # Fix permissions so the non-root user can write to /tmp/xxxx
  chown "${real_user}:${real_group}" "${BUILD_DIR}"
  chmod 700 "${BUILD_DIR}"

  log_info "Build context created at: ${BUILD_DIR}"

  # 6. Clone & Build (Privilege Drop)
  log_info "Cloning and building Paru (as ${real_user})..."

  # We spawn a bash subshell as the normal user to handle the build logic
  sudo -u "${real_user}" bash -c '
        set -euo pipefail
        build_dir="$1"
        repo_url="$2"
        
        cd "$build_dir"
        git clone --depth 1 "$repo_url" paru
        cd paru
        
        # -s: Sync deps (satisfied by step 4, but safe to keep)
        # --noconfirm: Non-interactive
        makepkg --noconfirm -s
    ' -- "${BUILD_DIR}" "${PARU_URL}"

  # 7. Install Artifact (Root)
  log_info "Installing compiled package..."

  # Find the specific package file.
  # We look for *.pkg.tar.zst to ensure we don't accidentally grab a debug package if configured wrong.
  # Note: If you want debug packages, remove the exclusion, but usually we just want the main binary.
  local pkg_file
  pkg_file=$(find "${BUILD_DIR}/paru" -name "paru-[0-9]*.pkg.tar.zst" -print -quit)

  if [[ -n "$pkg_file" ]]; then
    pacman -U --noconfirm "$pkg_file"
    log_success "Paru has been successfully installed."
  else
    log_error "Compilation finished, but no valid .pkg.tar.zst found."
    exit 1
  fi
}

main "$@"
