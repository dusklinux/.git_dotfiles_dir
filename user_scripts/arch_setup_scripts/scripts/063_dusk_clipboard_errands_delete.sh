#!/usr/bin/env bash
# ==============================================================================
#  MODULE: Clipboard Persistence Cleaner (Rofi-Cliphist)
#  CONTEXT: Hyprland / UWSM Environment
#  AUTHOR: Dusk's Architect
# ==============================================================================

# 1. Strict Error Handling
set -euo pipefail

# 2. Environment & Constants
# Using ${HOME} ensures UWSM/Systemd user context compatibility
readonly PINS_DIR="${HOME}/.local/share/rofi-cliphist/pins"
readonly ERRANDS_FILE="${HOME}/.local/share/errands/data.json"

# 3. Output Formatting (Direct to Stdout for Orchestra Capture)
# FIX: Use $'...' (ANSI-C quoting) so Bash interprets \033 as the actual Escape character
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[0;34m'
readonly BOLD=$'\033[1m'
readonly RESET=$'\033[0m'

log_info() { printf "%s[INFO]%s  %s\n" "${BLUE}" "${RESET}" "$1"; }
log_ok()   { printf "%s[OK]%s    %s\n" "${GREEN}" "${RESET}" "$1"; }
log_warn() { printf "%s[WARN]%s  %s\n" "${YELLOW}" "${RESET}" "$1"; }

# 4. Cleanup Trap (Standard Practice)
cleanup() {
    # No temporary files to remove, but we ensure a clean exit code
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        printf "%s[ERR]%s   Script failed with exit code %d\n" "${RED}" "${RESET}" "$exit_code"
    fi
}
trap cleanup EXIT

# ==============================================================================
#  MAIN LOGIC
# ==============================================================================

main() {
    log_info "Checking clipboard persistence configuration..."

    # Check if directory exists; if not, there is nothing to clean.
    if [[ ! -d "$PINS_DIR" ]]; then
        log_info "Pins directory not found at: ${PINS_DIR}"
        log_ok "No cleanup required."
        exit 0
    fi

    local file_count
    # Fast counting of files without parsing ls output
    file_count=$(find "$PINS_DIR" -maxdepth 1 -type f | wc -l)

    if [[ "$file_count" -eq 0 ]]; then
        log_info "Pins directory is empty."
        exit 0
    fi

    log_warn "Found ${BOLD}${file_count}${RESET} pinned clipboard items."
    
    # --- Interactive Prompt ---
    # We explicitly ask for confirmation to identify the user.
    # Added explicit flush of stdout/buffers just in case, though usually not strictly needed in bash
    printf "\n%s[?]%s Is this %sDusk's%s personal computer? (y/N) " "${YELLOW}" "${RESET}" "${BOLD}" "${RESET}"
    read -r response

    # Convert to lowercase for comparison
    local choice="${response,,}"

    if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
        # IDENTITY CONFIRMED: DUSK
        log_ok "Identity confirmed. Preserving existing clipboard pins."
        return 0
    else
        # IDENTITY UNCONFIRMED: CLEANUP REQUIRED
        log_warn "New environment detected. Purging previous user's clipboard pins..."

        # 1. Stop cliphist services momentarily if running (Hyprland/UWSM safety)
        # We ignore errors here in case the service isn't running yet.
        if systemctl --user is-active --quiet cliphist.service; then
            log_info "Pausing cliphist service for safe deletion..."
            systemctl --user stop cliphist.service || true
        fi

        # 2. Perform Clean Deletion
        # Using find -delete is atomic and handles large file counts better than rm *
        find "${PINS_DIR:?}" -type f -delete

        # 3. Verify
        if [[ -z "$(ls -A "$PINS_DIR")" ]]; then
            log_ok "Clipboard pins wiped successfully."
        else
            printf "%s[ERR]%s   Failed to delete all files in %s\n" "${RED}" "${RESET}" "$PINS_DIR"
            exit 1
        fi

        # 4. Remove Errands Data (Added as requested)
        if [[ -f "$ERRANDS_FILE" ]]; then
            rm -f "$ERRANDS_FILE"
            log_ok "Removed errands data file: ${ERRANDS_FILE}"
        fi

        # 5. Restart service if we stopped it (Optional, but good manners)
        # However, usually the orchestra script handles service enablement later.
        # We leave it stopped to be clean, or let UWSM handle the restart on next login.
    fi
}

main "$@"
