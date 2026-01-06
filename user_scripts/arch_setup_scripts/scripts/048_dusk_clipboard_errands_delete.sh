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
    # Argument Parsing
    local auto_mode=false
    for arg in "$@"; do
        case "$arg" in
            --auto) auto_mode=true ;;
        esac
    done

    log_info "Checking for pre-existing clipboard/errands artifacts..."

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

    # --- User Interaction Logic ---
    if [[ "$auto_mode" == "true" ]]; then
        log_info "Auto-mode enabled: Skipping user confirmation prompt."
    else
        log_warn "Detected ${BOLD}${file_count}${RESET} clipboard pins and/or Errands data from the repository author."
        printf "        %sThis data belongs to Dusk (the dotfiles creator).%s\n" "${YELLOW}" "${RESET}"
        printf "        %sMost users should remove these for a clean installation.%s\n" "${YELLOW}" "${RESET}"
        
        # Explicitly asking if they are YOU. The default 'N' (capitalized) encourages deletion.
        printf "\n%s[?]%s Are you the author (Dusk) restoring your own backup? (y/N) " "${YELLOW}" "${RESET}" 
        read -r response

        # Convert to lowercase for comparison
        local choice="${response,,}"

        if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
            # IDENTITY CONFIRMED: DUSK
            log_ok "Identity confirmed. Preserving existing clipboard pins and errands."
            return 0
        fi
        # Fall through to cleanup if choice is not yes
    fi

    # --- Cleanup Routine ---
    # IDENTITY UNCONFIRMED OR AUTO-MODE: CLEANUP REQUIRED
    
    if [[ "$auto_mode" == "true" ]]; then
        log_info "Purging personal artifacts (Auto)..."
    else
        log_info "Standard installation detected. Purging author's personal artifacts..."
    fi

    # 1. Stop cliphist services momentarily if running (Hyprland/UWSM safety)
    if systemctl --user is-active --quiet cliphist.service; then
        log_info "Pausing cliphist service for safe deletion..."
        systemctl --user stop cliphist.service || true
    fi

    # 2. Perform Clean Deletion
    find "${PINS_DIR:?}" -type f -delete

    # 3. Verify
    if [[ -z "$(ls -A "$PINS_DIR")" ]]; then
        log_ok "Clipboard pins wiped successfully."
    else
        printf "%s[ERR]%s   Failed to delete all files in %s\n" "${RED}" "${RESET}" "$PINS_DIR"
        exit 1
    fi

    # 4. Remove Errands Data
    if [[ -f "$ERRANDS_FILE" ]]; then
        rm -f "$ERRANDS_FILE"
        log_ok "Removed errands data file: ${ERRANDS_FILE}"
    fi

    # 5. Service restart handled by UWSM/Orchestra later
}

main "$@"
