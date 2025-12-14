#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose: Switch Hyprland animation config to 'dusky.conf'
# Env:     Arch Linux / Hyprland / UWSM
# -----------------------------------------------------------------------------

# Strict Mode
set -euo pipefail

# --- Configuration ---
# Updated source to point to dusky.conf
readonly SOURCE_FILE="${HOME}/.config/hypr/source/animations/dusky.conf"
readonly TARGET_LINK="${HOME}/.config/hypr/source/animations/active/active.conf"

# --- Styling (StdOut only) ---
readonly C_RESET=$'\033[0m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_GREY=$'\033[0;90m'

# --- Main Logic ---
main() {
    # 1. Validate Source
    if [[ ! -f "$SOURCE_FILE" ]]; then
        printf "${C_RESET}[${C_GREY}$(date +%T)${C_RESET}] ${C_GREEN}[ERROR]${C_RESET} Source file missing: %s\n" "$SOURCE_FILE" >&2
        exit 1
    fi

    # 2. Clean Execution (Explicit Delete)
    # We check if the target exists (as file or symlink) and remove it explicitly
    if [[ -L "$TARGET_LINK" || -e "$TARGET_LINK" ]]; then
        rm "$TARGET_LINK"
    fi

    # 3. Create Symlink
    ln -fs "$SOURCE_FILE" "$TARGET_LINK"

    # 4. Feedback
    printf "${C_RESET}[${C_GREY}$(date +%T)${C_RESET}] ${C_BLUE}[INFO]${C_RESET}  Switched animation to: ${C_GREEN}Dusky${C_RESET}\n"
}

main "$@"
