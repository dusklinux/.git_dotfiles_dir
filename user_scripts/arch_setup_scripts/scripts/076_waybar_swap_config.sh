#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: waybar_swap_config.sh
# Description: Atomically swaps Waybar config/style with a 'pill' variant.
#              Includes rollback safety, pure bash parsing, and UWSM support.
# Author: Elite DevOps (AI)
# Version: 2.1.0
# -----------------------------------------------------------------------------

# 1. Strict Error Handling & Shell Options
set -u              # Error on unset variables
set -o pipefail     # Piped commands fail if any part fails
shopt -s extglob    # Enable extended globbing for string trimming

# 2. Constants
readonly BASE_DIR="${HOME}/.config/waybar"
readonly PILL_DIR="${BASE_DIR}/pill"
readonly TARGET_FILES=("config.jsonc" "style.css")
readonly APP_NAME="waybar"
readonly NOTIFY_TIMEOUT=4000

# 3. Aesthetics (TTY-Aware)
# Only use colors if connected to a terminal and NO_COLOR is unused
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    readonly C_RESET=$'\033[0m'
    readonly C_INFO=$'\033[1;34m'
    readonly C_SUCCESS=$'\033[1;32m'
    readonly C_WARN=$'\033[1;33m'
    readonly C_ERR=$'\033[1;31m'
    readonly C_BOLD=$'\033[1m'
    readonly C_DIM=$'\033[2m'
else
    readonly C_RESET='' C_INFO='' C_SUCCESS='' C_WARN='' C_ERR='' C_BOLD='' C_DIM=''
fi

# 4. Global State
TMP_DIR=""

# 5. Helper Functions

log_info()    { printf "%s[INFO]%s %s\n" "$C_INFO" "$C_RESET" "${1:-}"; }
log_success() { printf "%s[OK]%s %s\n" "$C_SUCCESS" "$C_RESET" "${1:-}"; }
log_warn()    { printf "%s[WARN]%s %s\n" "$C_WARN" "$C_RESET" "${1:-}"; }
log_err()     { printf "%s[ERROR]%s %s\n" "$C_ERR" "$C_RESET" "${1:-}" >&2; }

# Graceful exit handler
cleanup() {
    # Only remove TMP_DIR if it was actually created
    if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
        rm -rf "${TMP_DIR}"
    fi
}
trap cleanup EXIT INT TERM

# Pure Bash config name extractor (No external binaries)
# Usage: get_config_name "path/to/file" "Fallback Name"
get_config_name() {
    local file="${1:-}"
    local fallback="${2:-Unknown}"
    local first_line

    if [[ -r "$file" ]]; then
        # Read first line without spawning a subprocess
        read -r first_line < "$file" || true
        # Check if line starts with //
        if [[ "$first_line" =~ ^[[:space:]]*//[[:space:]]*(.+)$ ]]; then
            local name="${BASH_REMATCH[1]}"
            # Trim trailing whitespace using extglob
            echo "${name%%+([[:space:]])}"
            return
        fi
    fi
    echo "$fallback"
}

notify_user() {
    local config_name="${1:-Config}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send \
            --app-name="Waybar Manager" \
            --icon="preferences-desktop-display" \
            --expire-time="$NOTIFY_TIMEOUT" \
            "Waybar Config Applied" \
            "${config_name}"
    fi
}

# 6. Core Logic

reload_waybar() {
    # Check if Waybar is running
    if pgrep -x "${APP_NAME}" > /dev/null; then
        log_info "Reloading Waybar..."
        # We don't use set -e here to avoid crashing if process vanishes in race condition
        if ! pkill -SIGUSR2 -x "${APP_NAME}"; then
            log_warn "Failed to signal Waybar. It may have crashed."
        fi
    else
        log_info "Waybar not running. Starting..."
        
        # Smart UWSM detection
        if command -v uwsm >/dev/null 2>&1; then
            # New UWSM syntax preferred, fallback to uwsm-app binary if needed
            if uwsm check >/dev/null 2>&1; then
                 uwsm app -- "${APP_NAME}" >/dev/null 2>&1 &
            else
                 # Older versions or if 'check' isn't supported
                 uwsm-app -- "${APP_NAME}" >/dev/null 2>&1 &
            fi
        else
            "${APP_NAME}" > /dev/null 2>&1 &
        fi
        disown
    fi
}

# The Swap Operation with Rollback Capability
perform_swap() {
    log_info "Initiating swap transaction..."

    # 1. Validation
    if [[ ! -d "${BASE_DIR}" ]] || [[ ! -d "${PILL_DIR}" ]]; then
        log_err "Directory structure mismatch."
        log_err "Expected: ${BASE_DIR} and ${PILL_DIR}"
        exit 1
    fi

    for file in "${TARGET_FILES[@]}"; do
        [[ -f "${BASE_DIR}/${file}" ]] || { log_err "Missing source: $file"; exit 1; }
        [[ -f "${PILL_DIR}/${file}" ]] || { log_err "Missing target: $file"; exit 1; }
    done

    # 2. Lazy Temp Directory Creation
    TMP_DIR=$(mktemp -d) || { log_err "Failed to create temp dir"; exit 1; }

    # 3. Transactional Swap
    local -a step_1_done=()
    local -a step_2_done=()
    local file

    # Internal function to rollback changes on failure
    rollback() {
        log_err "Swap failed. Rolling back changes..."
        local r_file
        
        # Undo Step 2 (Pill -> Base)
        for r_file in "${step_2_done[@]}"; do
            # Move back from Base to Pill
            mv -f "${BASE_DIR}/${r_file}" "${PILL_DIR}/${r_file}"
        done

        # Undo Step 1 (Base -> Temp)
        for r_file in "${step_1_done[@]}"; do
            # Move back from Temp to Base
            mv -f "${TMP_DIR}/${r_file}" "${BASE_DIR}/${r_file}"
        done
        log_info "Rollback complete. State restored."
    }

    # Execute Swap
    for file in "${TARGET_FILES[@]}"; do
        # Step 1: Base -> Temp
        if mv "${BASE_DIR}/${file}" "${TMP_DIR}/${file}"; then
            step_1_done+=("$file")
        else
            rollback; exit 1
        fi

        # Step 2: Pill -> Base
        if mv "${PILL_DIR}/${file}" "${BASE_DIR}/${file}"; then
            step_2_done+=("$file")
        else
            rollback; exit 1
        fi

        # Step 3: Temp -> Pill (Finalize)
        if ! mv "${TMP_DIR}/${file}" "${PILL_DIR}/${file}"; then
            # If this fails, we actually have a partial state (Base is new, Pill is empty)
            # We treat this as a failure and revert everything
            rollback; exit 1
        fi
    done

    # 4. Success Handling
    local new_config_name
    new_config_name=$(get_config_name "${BASE_DIR}/config.jsonc" "Option 1")

    log_success "Swapped to: ${C_BOLD}${new_config_name}${C_RESET}"
    notify_user "${new_config_name}"
    
    reload_waybar
}

# Interactive Menu
interactive_choose() {
    printf "\n%s:: Waybar UI Manager ::%s\n" "$C_BOLD" "$C_RESET"

    local current_name pill_name
    current_name=$(get_config_name "${BASE_DIR}/config.jsonc" "Option 1")
    pill_name=$(get_config_name "${PILL_DIR}/config.jsonc" "Option 2")

    printf "\n%sCurrent:%s   %s\n" "$C_INFO" "$C_RESET" "$current_name"
    printf "%sAvailable:%s %s\n\n" "$C_INFO" "$C_RESET" "$pill_name"

    echo "1) Keep '${current_name}' (Default)"
    echo "2) Apply '${pill_name}'"
    
    local choice
    # -r prevents backslash escaping, -p prompt is standard
    read -r -p "Select option [1]: " choice
    choice=${choice:-1}

    if [[ "$choice" == "2" ]]; then
        perform_swap
        
        printf "\n"
        read -r -p "Do you want to keep this configuration? [Y/n] " confirm
        confirm=${confirm:-y}

        if [[ "$confirm" =~ ^[Nn] ]]; then
            log_warn "Reverting configuration..."
            perform_swap
        else
            log_success "Configuration kept."
        fi
    else
        log_info "No changes made."
    fi
}

# 7. Main
main() {
    case "${1:-}" in
        --choose|-c)
            interactive_choose
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [--choose]"
            ;;
        *)
            perform_swap
            ;;
    esac
}

main "$@"
