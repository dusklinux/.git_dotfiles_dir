#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: configure_skel.sh
# Description: Stages the dotfiles deployment script into /etc/skel.
# Context: Arch Linux ISO (Chroot Environment)
# -----------------------------------------------------------------------------

# Strict Mode:
# -e: Exit on error
# -u: Exit on unset variables
# -o pipefail: Exit if any command in a pipe fails
set -euo pipefail
# Bash 4.4+: Ensure subshells inherit the -e setting
shopt -s inherit_errexit 2>/dev/null || true

# -----------------------------------------------------------------------------
# Visuals
# -----------------------------------------------------------------------------
declare -r BLUE=$'\033[0;34m'
declare -r GREEN=$'\033[0;32m'
declare -r RED=$'\033[0;31m'
declare -r YELLOW=$'\033[0;33m'
declare -r NC=$'\033[0m'

# -----------------------------------------------------------------------------
# Critical Pre-Flight Check
# -----------------------------------------------------------------------------
printf "\n${RED}[CRITICAL CHECK]${NC} Verify Environment:\n"
printf "Have you switched to the chroot environment by running: ${BLUE}arch-chroot /mnt${NC} ?\n"
read -r -p "Type 'yes' to proceed, or anything else to exit: " user_conf

if [[ "${user_conf,,}" != "yes" ]]; then
    printf "\n${RED}[ABORTING]${NC} You must be inside the chroot environment to run this script.\n"
    printf "Please run the following command first:\n"
    printf "\n    ${BLUE}arch-chroot /mnt${NC}\n\n"
    exit 1
fi

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
declare -r SOURCE_FILE="/deploy_dotfiles.sh"
declare -r SKEL_DIR="/etc/skel"
declare -r TARGET_FILE="$SKEL_DIR/deploy_dotfiles.sh"

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

# 1. Validation
if [[ ! -f "$SOURCE_FILE" ]]; then
    log_error "Source file not found at: $SOURCE_FILE"
fi

log_info "Configuring skeleton directory..."

# 2. Preparation
mkdir -p -- "$SKEL_DIR"

# 3. Execution
# Check if target exists to provide specific logging context
if [[ -f "$TARGET_FILE" ]]; then
    log_warn "File found at destination. Replacing: $TARGET_FILE"
else
    log_info "Copying source to skeleton..."
fi

# cp -f: Force copy. Overwrites target if exists, does not remove source.
cp -f -- "$SOURCE_FILE" "$TARGET_FILE"

# 4. Permissions (Strict)
# Re-apply permissions to ensure the overwritten file has the correct mode
chmod 755 -- "$TARGET_FILE"

# 5. Ownership
chown root:root -- "$TARGET_FILE"

# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------
log_success "Skeleton configured. Future users will inherit: $TARGET_FILE"
