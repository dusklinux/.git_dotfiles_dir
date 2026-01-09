#!/usr/bin/env bash
# set Hyprland animation config to dusky (Default)
# -----------------------------------------------------------------------------
# Purpose: Switch Hyprland animation config to 'dusky.conf'
# Env:     Arch Linux / Hyprland / UWSM
# -----------------------------------------------------------------------------

set -euo pipefail

# --- Configuration ---
readonly SOURCE_FILE="${HOME}/.config/hypr/source/animations/dusky.conf"
readonly TARGET_LINK="${HOME}/.config/hypr/source/animations/active/active.conf"

# --- Colors ---
readonly C_RESET=$'\033[0m'
readonly C_RED=$'\033[1;31m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_GREY=$'\033[0;90m'

main() {
    # Validate source exists
    if [[ ! -e "$SOURCE_FILE" ]]; then
        printf "[${C_GREY}%s${C_RESET}] ${C_RED}[ERROR]${C_RESET} Source missing: %s\n" \
            "$(date +%T)" "$SOURCE_FILE" >&2
        exit 1
    fi

    # Ensure target directory exists
    mkdir -p "${TARGET_LINK%/*}"

    # Create symlink (force overwrites existing file/symlink)
    ln -sf "$SOURCE_FILE" "$TARGET_LINK"

    printf "[${C_GREY}%s${C_RESET}] ${C_BLUE}[INFO]${C_RESET}  Switched animation to: ${C_GREEN}dusky${C_RESET}\n" \
        "$(date +%T)"
}

main "$@"
