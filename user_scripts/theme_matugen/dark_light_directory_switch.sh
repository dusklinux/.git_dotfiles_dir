#!/bin/bash

# ==============================================================================
# WALLPAPER DIRECTORY MANAGER (Physical Move Strategy)
# ==============================================================================
# Description: Physically moves Light/Dark directories in and out of the
#              active wallpapers folder.
# Safety:      - NEVER deletes files.
#              - Aborts on path collisions.
#              - Verifies move success.
#              - Optimized for Bash 5+ (No subshells).
# ==============================================================================

set -euo pipefail

# --- CONFIGURATION ---
# Use declare -r for read-only variables (Bash best practice)
declare -r BASE_DIR="${HOME}/Pictures"
declare -r WALLPAPER_ROOT="${BASE_DIR}/wallpapers"

# Directory names
declare -r LIGHT_NAME="light"
declare -r DARK_NAME="dark"

# Storage locations (When not active)
declare -r STORED_LIGHT="${BASE_DIR}/${LIGHT_NAME}"
declare -r STORED_DARK="${BASE_DIR}/${DARK_NAME}"

# Active locations (When inside wallpapers folder)
declare -r ACTIVE_LIGHT="${WALLPAPER_ROOT}/${LIGHT_NAME}"
declare -r ACTIVE_DARK="${WALLPAPER_ROOT}/${DARK_NAME}"

# --- HELPERS ---

# Simple, hardcoded colors are fine for a personal utility
log()     { printf '\033[1;34m::\033[0m %s\n' "$*"; }
success() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn()    { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()     { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTION]

Physically moves 'light' and 'dark' directories to toggle themes.

Options:
  (no args)   Toggle state based on current content.
  --light     Force switch to Light.
  --dark      Force switch to Dark.
  --status    Print current state (useful for bars/scripts).
  -h, --help  Show this help.
EOF
}

# --- CORE LOGIC ---

# Moves a directory safely with validation
# Usage: safe_move "source_path" "destination_parent_dir"
safe_move() {
    local src="$1"
    local dest_parent="$2"
    
    # Bash String Manipulation (Faster than calling $(basename))
    local dir_name="${src##*/}" 
    local final_dest="${dest_parent}/${dir_name}"

    # 1. Validation: Don't move if it doesn't exist
    if [[ ! -d "${src}" ]]; then
        # If it's not at source, checks if it's already at destination
        if [[ -d "${final_dest}" ]]; then
            return 0
        fi
        die "Directory '${src}' not found, and it is not at '${final_dest}'."
    fi

    # 2. Safety: Reject symlinks (We only want to move real directories)
    if [[ -L "${src}" ]]; then
        die "Safety Abort: '${src}' is a symlink. We only move real directories."
    fi

    # 3. Collision Detection: Destination must not exist
    if [[ -e "${final_dest}" ]]; then
        die "Collision detected! '${final_dest}' already exists. \
Move it manually to prevent data loss."
    fi

    # 4. Execution
    log "Moving ${dir_name} -> ${dest_parent##*/}/..."
    
    # -n (no-clobber) is our final safety net
    mv -n -- "${src}" "${dest_parent}" || die "mv command failed."

    # 5. Post-Move Verification (Paranoia check)
    if [[ -d "${src}" ]]; then
        die "Move failed silently: Source '${src}' still exists."
    fi
}

switch_to_light() {
    # 1. Evacuate Dark (Active -> Storage) if it exists
    if [[ -d "${ACTIVE_DARK}" ]]; then
        safe_move "${ACTIVE_DARK}" "${BASE_DIR}"
    fi

    # 2. Check if we are already done
    if [[ -d "${ACTIVE_LIGHT}" ]]; then
        success "Light mode is already active."
        return 0
    fi

    # 3. Deploy Light (Storage -> Active)
    safe_move "${STORED_LIGHT}" "${WALLPAPER_ROOT}"
    success "Switched to Light Mode."
}

switch_to_dark() {
    # 1. Evacuate Light (Active -> Storage) if it exists
    if [[ -d "${ACTIVE_LIGHT}" ]]; then
        safe_move "${ACTIVE_LIGHT}" "${BASE_DIR}"
    fi

    # 2. Check if we are already done
    if [[ -d "${ACTIVE_DARK}" ]]; then
        success "Dark mode is already active."
        return 0
    fi

    # 3. Deploy Dark (Storage -> Active)
    safe_move "${STORED_DARK}" "${WALLPAPER_ROOT}"
    success "Switched to Dark Mode."
}

show_status() {
    local state="UNKNOWN"
    
    if [[ -d "${ACTIVE_LIGHT}" && ! -d "${ACTIVE_DARK}" ]]; then
        state="light"
    elif [[ -d "${ACTIVE_DARK}" && ! -d "${ACTIVE_LIGHT}" ]]; then
        state="dark"
    elif [[ -d "${ACTIVE_LIGHT}" && -d "${ACTIVE_DARK}" ]]; then
        state="ambiguous"
    fi

    printf "%s\n" "$state"
}

detect_and_toggle() {
    # Boolean logic using arithmetic context (Bash specific, cleaner)
    local is_light=0
    local is_dark=0

    [[ -d "${ACTIVE_LIGHT}" ]] && is_light=1
    [[ -d "${ACTIVE_DARK}" ]] && is_dark=1

    if (( is_light && !is_dark )); then
        log "State: Light. Switching to Dark..."
        switch_to_dark
    elif (( is_dark && !is_light )); then
        log "State: Dark. Switching to Light..."
        switch_to_light
    elif (( !is_light && !is_dark )); then
        log "State: Empty. Defaulting to Dark..."
        switch_to_dark
    else
        die "Ambiguous state: Both 'light' and 'dark' folders found in wallpapers/. Fix manually."
    fi
}

# --- MAIN ---

main() {
    # Pre-flight: Ensure base structure exists
    mkdir -p "${BASE_DIR}" "${WALLPAPER_ROOT}"

    # Argument Parsing
    case "${1:-}" in
        "")         detect_and_toggle ;;
        --light)    switch_to_light ;;
        --dark)     switch_to_dark ;;
        --status)   show_status ;; 
        -h|--help)  usage; exit 0 ;;
        *)          die "Invalid argument: $1" ;;
    esac
}

main "$@"
