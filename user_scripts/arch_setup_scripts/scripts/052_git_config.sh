#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Elite DevOps Git Configurator for Arch/Hyprland Environment
# -----------------------------------------------------------------------------
# Description: Safely appends Delta configuration to ~/.gitconfig
# Author:      System Architect
# Shell:       Bash 5.0+
# -----------------------------------------------------------------------------

# Strict Mode (Fail on error, unset vars, pipe failures)
set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION ZONE
# Edit the content inside the GIT_DELTA_CONFIG variable to add/remove lines.
# -----------------------------------------------------------------------------

# The target file
readonly TARGET_FILE="${HOME}/.gitconfig"

# The unique string to check if configuration already exists.
# Choose a line that is unique to this specific block.
readonly FINGERPRINT="diffFilter = delta --color-only"

# The configuration block to append.
# Note: Keep the indentation exactly as you want it to appear in the file.
define_config_content() {
    cat <<'EOF'
[core]
    pager = delta
[interactive]
    diffFilter = delta --color-only
[delta]
    navigate = true    # use n and N to move between diff sections
    side-by-side = true
    line-numbers = true
    hyperlinks = true
    tabs = 2
    true-color = always
# the ugly thing at the top being omited
    hunk-header-style = omit
# 2. FORCE the File Path to the top in a nice box
    file-style = box bold yellow
    file-decoration-style = none
# Wrap as many times as needed.
    wrap-max-lines = 100
EOF
}

# -----------------------------------------------------------------------------
# UTILITIES
# -----------------------------------------------------------------------------

# ANSI Colors
readonly C_RESET=$'\033[0m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_RED=$'\033[1;31m'
readonly C_GRAY=$'\033[0;90m'

log_info()    { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"; }
log_success() { printf "${C_GREEN}[OK]${C_RESET}   %s\n" "$1"; }
log_error()   { printf "${C_RED}[ERR]${C_RESET}  %s\n" "$1" >&2; }

# Cleanup trap
cleanup() {
    # If we created a lock or temp file, we would remove it here.
    # Currently just a placeholder for robust architecture.
    :
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------

main() {
    # 0. Ensure Dependencies
    # We install git-delta first to ensure the config below is valid.
    log_info "Ensuring dependency 'git-delta' is installed via pacman..."
    sudo pacman -S --needed --noconfirm git-delta

    local config_content
    config_content="$(define_config_content)"

    # 1. Ensure the file exists
    if [[ ! -f "$TARGET_FILE" ]]; then
        log_info "File $TARGET_FILE not found. Creating it..."
        touch "$TARGET_FILE"
    fi

    # 2. Check for idempotency (Fingerprinting)
    # We use grep -F (fixed string) for speed and safety against regex characters.
    if grep -Fq "$FINGERPRINT" "$TARGET_FILE"; then
        log_success "Configuration already detected in $TARGET_FILE."
        log_info "No changes made."
        exit 0
    fi

    log_info "Configuration block not found. Preparing to append..."

    # 3. Safety Check: Ensure file ends with a newline before appending
    # tail -c1 reads the last byte. If it's not empty and not a newline, add one.
    if [[ -s "$TARGET_FILE" ]] && [[ "$(tail -c1 "$TARGET_FILE" | wc -l)" -eq 0 ]]; then
        log_info "Fixing missing trailing newline in $TARGET_FILE..."
        printf "\n" >> "$TARGET_FILE"
    fi

    # 4. Append the configuration
    # We allow the expansion of the variable content into the file.
    printf "%s\n" "$config_content" >> "$TARGET_FILE"

    log_success "Successfully appended Delta config to $TARGET_FILE."
}

main "$@"
