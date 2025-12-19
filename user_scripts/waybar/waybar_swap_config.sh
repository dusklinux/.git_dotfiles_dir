#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: waybar-swap.sh
# Description: Swaps Waybar config/style with a 'pill' variant and reloads.
# Environment: Arch Linux / Hyprland / UWSM
# Author: Elite DevOps (AI)
# -----------------------------------------------------------------------------

# 1. Strict Error Handling
set -euo pipefail

# 2. Constants & Configuration
readonly BASE_DIR="${HOME}/.config/waybar"
readonly PILL_DIR="${BASE_DIR}/pill"
readonly TARGET_FILES=("config.jsonc" "style.css")
readonly APP_NAME="waybar"

# 3. Aesthetics (ANSI Colors)
readonly C_RESET='\033[0m'
readonly C_INFO='\033[1;34m'   # Bold Blue
readonly C_SUCCESS='\033[1;32m' # Bold Green
readonly C_ERR='\033[1;31m'     # Bold Red

# 4. Logging Helper Functions
log_info()    { printf "${C_INFO}[INFO]${C_RESET} %s\n" "$1"; }
log_success() { printf "${C_SUCCESS}[OK]${C_RESET} %s\n" "$1"; }
log_err()     { printf "${C_ERR}[ERROR]${C_RESET} %s\n" "$1" >&2; }

# 5. Cleanup Strategy (Trap)
# Create a secure temp directory for the swap transaction
TMP_DIR=$(mktemp -d)

cleanup() {
    # Ensure temp dir is removed on exit, regardless of success/failure
    if [[ -d "${TMP_DIR}" ]]; then
        rm -rf "${TMP_DIR}"
    fi
}
trap cleanup EXIT

# 6. Validation
main() {
    # Verify directories exist
    if [[ ! -d "${BASE_DIR}" ]] || [[ ! -d "${PILL_DIR}" ]]; then
        log_err "Directory structure mismatch. Ensure ${BASE_DIR} and ${PILL_DIR} exist."
        exit 1
    fi

    # Verify specific files exist in BOTH locations to prevent partial swaps
    for file in "${TARGET_FILES[@]}"; do
        if [[ ! -f "${BASE_DIR}/${file}" ]]; then
            log_err "Missing source file: ${BASE_DIR}/${file}"
            exit 1
        fi
        if [[ ! -f "${PILL_DIR}/${file}" ]]; then
            log_err "Missing target file: ${PILL_DIR}/${file}"
            exit 1
        fi
    done

    log_info "Swapping configuration files..."

    # 7. The Swap Logic (Atomic-ish via Temp Buffer)
    for file in "${TARGET_FILES[@]}"; do
        # Step A: Move Active -> Temp
        mv "${BASE_DIR}/${file}" "${TMP_DIR}/${file}"
        
        # Step B: Move Pill -> Active
        mv "${PILL_DIR}/${file}" "${BASE_DIR}/${file}"
        
        # Step C: Move Temp (Old Active) -> Pill
        mv "${TMP_DIR}/${file}" "${PILL_DIR}/${file}"
    done

    log_success "Configs swapped successfully."

    # 8. Process Management (UWSM Aware)
    if pgrep -x "${APP_NAME}" > /dev/null; then
        log_info "Waybar is running. Reloading configuration..."
        # SIGUSR2 is the native reload signal for Waybar (reloads CSS and Config)
        pkill -SIGUSR2 -x "${APP_NAME}"
        log_success "Waybar signal sent."
    else
        log_info "Waybar is not running. Starting via UWSM..."
        # Launch using UWSM to ensure proper systemd scoping and env vars
        if command -v uwsm > /dev/null 2>&1; then
            uwsm-app -- "${APP_NAME}" > /dev/null 2>&1 &
        else
            # Fallback if UWSM isn't in PATH (unlikely given constraints)
            "${APP_NAME}" > /dev/null 2>&1 &
        fi
        disown
        log_success "Waybar started."
    fi
}

# Execute
main
