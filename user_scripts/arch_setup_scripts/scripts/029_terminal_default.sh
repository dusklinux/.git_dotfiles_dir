#!/usr/bin/env bash
# sets the default terminal to kitty
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────────────────────
readonly GREEN=$'\033[0;32m'
readonly BLUE=$'\033[0;34m'
readonly NC=$'\033[0m'

log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }

# ─────────────────────────────────────────────────────────────
# Write File
# ─────────────────────────────────────────────────────────────
readonly TARGET_FILE="${HOME}/.config/xdg-terminals.list"

log_info "Writing ${TARGET_FILE}..."
printf '%s\n' "kitty.desktop" > "$TARGET_FILE"
log_success "Done"
