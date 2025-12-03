#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Script: install_neovim_npm.sh
# Description: Automates the installation of the global neovim npm package.
#              Checks for npm availability and root privileges.
# Author: DevOps Engineer
# -----------------------------------------------------------------------------

# strict mode - fail on error, undefined vars, or pipe failures
set -euo pipefail

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  log_err "This script must be run as root. Please use sudo."
  exit 1
fi

# Install/Check dependencies (Node.js and npm) via pacman
log_info "Ensuring Node.js and npm dependencies are installed..."
pacman -S --noconfirm --needed nodejs npm

# Check if npm is installed
if ! command -v npm &>/dev/null; then
  log_err "npm could not be found. Please install Node.js and npm first."
  # On Arch, you'd usually run: pacman -S nodejs npm
  exit 1
fi

log_info "npm detected: $(npm -v)"

# Install neovim globally
log_info "Installing neovim npm package globally..."

# --loglevel error keeps it quiet unless something breaks
# --yes (or implicit in most npm installs) ensures non-interactive
npm install -g neovim --loglevel error

if [[ $? -eq 0 ]]; then
  log_info "Neovim npm package installed successfully."
else
  log_err "Failed to install neovim npm package."
  exit 1
fi

# Verify installation
log_info "Verifying installation..."
if npm list -g neovim --depth=0 &>/dev/null; then
  log_info "Verification complete: neovim provider is active."
else
  log_err "Verification failed."
  exit 1
fi
