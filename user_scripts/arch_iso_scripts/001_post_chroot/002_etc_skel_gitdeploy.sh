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
# Bash 4.4+: Ensure subshells inherit the -e setting (Robustness upgrade)
shopt -s inherit_errexit 2>/dev/null || true

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
declare -r SOURCE_FILE="/deploy_dotfiles.sh"
declare -r SKEL_DIR="/etc/skel"
declare -r TARGET_FILE="$SKEL_DIR/deploy_dotfiles.sh"

# -----------------------------------------------------------------------------
# Logging (Fast ANSI)
# -----------------------------------------------------------------------------
# We use $'' format for faster parsing and readonly variables
declare -r BLUE=$'\033[0;34m'
declare -r GREEN=$'\033[0;32m'
declare -r RED=$'\033[0;31m'
declare -r NC=$'\033[0m'

log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
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
# mkdir -p is idempotent; it won't error if dir exists.
# We use -- to strictly terminate flags, ensuring safety against weird filenames.
mkdir -p -- "$SKEL_DIR"

# 3. Execution
# -f: Force move (don't prompt)
log_info "Moving source to skeleton..."
mv -f -- "$SOURCE_FILE" "$TARGET_FILE"

# 4. Permissions (Strict)
# 755: rwx (Owner), rx (Group), rx (World) - Standard for scripts.
# We explicitly set this before user creation.
chmod 755 -- "$TARGET_FILE"

# 5. Ownership
# Ensure root owns the template. The 'useradd' command will change ownership
# of the *copy* it makes, but the template itself must remain root-owned.
chown root:root -- "$TARGET_FILE"

# -----------------------------------------------------------------------------
# Completion
# -----------------------------------------------------------------------------
log_success "Skeleton configured. Future users will inherit: $TARGET_FILE"
