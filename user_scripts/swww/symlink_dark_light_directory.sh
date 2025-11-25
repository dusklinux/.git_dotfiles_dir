#!/bin/bash

# ==============================================================================
# WALLPAPER SYMLINK MANAGER
# ==============================================================================
# Description: Manages symlinks between Light and Dark wallpaper directories.
# Behavior:    - Ensures source directories exist.
#              - Safely handles the 'active' symlink (atomic switching).
#              - Toggles state by default, or accepts --light / --dark flags.
# ==============================================================================

set -euo pipefail

# --- CONFIGURATION ---
readonly BASE_DIR="${HOME}/Pictures"
readonly LIGHT_DIR="${BASE_DIR}/light"
readonly DARK_DIR="${BASE_DIR}/dark"
readonly WALLPAPER_ROOT="${BASE_DIR}/wallpapers"
readonly LINK_NAME="active"
readonly LINK_PATH="${WALLPAPER_ROOT}/${LINK_NAME}"

# Track temp link for cleanup
TMP_LINK=""

# --- FUNCTIONS ---

cleanup() {
    # Remove temp link on exit/interrupt (ignore errors)
    [[ -n "${TMP_LINK}" ]] && rm -f -- "${TMP_LINK}" 2>/dev/null
    return 0
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTION]

Manage wallpaper symlinks for Light/Dark modes.

Options:
  (no args)   Toggle between Light and Dark based on current link.
  --light     Force switch to Light directory.
  --dark      Force switch to Dark directory.
  -h, --help  Show this help message.
EOF
}

update_symlink() {
    local target_dir="$1"
    local link_location="$2"
    # Use PID for unique temp name (prevents race conditions)
    TMP_LINK="${link_location}.tmp.$$"

    printf -- '-> Switching wallpaper source to: %s\n' "${target_dir}"

    # Create temporary symlink (--no-dereference via -n)
    ln -sfn -- "${target_dir}" "${TMP_LINK}" \
        || die "Failed to create temporary symlink at '${TMP_LINK}'"

    # Atomically rename temp link to final location
    # -T: treat destination as file, not directory
    # -f: force overwrite without prompt
    mv -Tf -- "${TMP_LINK}" "${link_location}" \
        || die "Failed to atomically rename symlink to '${link_location}'"

    TMP_LINK=""  # Clear on success (prevent cleanup from removing final link)
    printf -- '-> Success: %s -> %s\n' "${link_location}" "${target_dir}"
}

main() {
    trap cleanup EXIT INT TERM

    local target_state=""

    # --- PRE-FLIGHT CHECKS ---

    # Create all required directories in one call
    mkdir -p -- "${LIGHT_DIR}" "${DARK_DIR}" "${WALLPAPER_ROOT}"

    # Collision detection: abort if path exists and is NOT a symlink
    if [[ -e "${LINK_PATH}" && ! -L "${LINK_PATH}" ]]; then
        if [[ -d "${LINK_PATH}" ]]; then
            die "'${LINK_PATH}' exists as a real directory (not a symlink). Remove it first."
        else
            die "'${LINK_PATH}' exists as a regular file (not a symlink). Remove it first."
        fi
    fi

    # --- ARGUMENT PARSING ---

    if [[ $# -eq 0 ]]; then
        # === TOGGLE MODE ===
        if [[ -L "${LINK_PATH}" ]]; then
            # Use readlink WITHOUT -f to get exact stored path (avoids canonicalization mismatch)
            local current_target
            current_target=$(readlink -- "${LINK_PATH}")

            case "${current_target}" in
                "${LIGHT_DIR}")
                    target_state="dark"
                    ;;
                "${DARK_DIR}")
                    target_state="light"
                    ;;
                *)
                    printf 'Warning: Link points to unknown location: %s\n' "${current_target}" >&2
                    printf 'Resetting to Dark mode.\n' >&2
                    target_state="dark"
                    ;;
            esac
        else
            printf 'No active link found. Initializing to Dark mode.\n'
            target_state="dark"
        fi

    elif [[ $# -eq 1 ]]; then
        # === FLAG MODE ===
        case "$1" in
            --light)
                target_state="light"
                ;;
            --dark)
                target_state="dark"
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                printf 'Error: Unknown option: %s\n\n' "$1" >&2
                usage >&2
                exit 1
                ;;
            *)
                printf 'Error: Invalid argument: %s\n\n' "$1" >&2
                usage >&2
                exit 1
                ;;
        esac
    else
        printf 'Error: Too many arguments (expected 0 or 1, got %d)\n\n' "$#" >&2
        usage >&2
        exit 1
    fi

    # --- EXECUTION ---

    case "${target_state}" in
        light)
            update_symlink "${LIGHT_DIR}" "${LINK_PATH}"
            ;;
        dark)
            update_symlink "${DARK_DIR}" "${LINK_PATH}"
            ;;
        *)
            # Should never happen, but defensive programming
            die "Internal error: unexpected target state '${target_state}'"
            ;;
    esac
}

main "$@"
