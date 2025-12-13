#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: 009_aur_helper_final_v2.sh
# Description: The "Nuclear Option" AUR Helper Installer.
#              1. Sanitizes broken/ghost Paru installations.
#              2. Attempts to build Paru (Rust).
#              3. FAIL-SAFE: If Paru fails, deep cleans and installs Yay (Go).
# Author: Arch Linux Systems Architect
# -----------------------------------------------------------------------------

# --- Strict Mode ---
set -euo pipefail
shopt -s nullglob 

# --- Configuration ---
readonly PARU_URL="https://aur.archlinux.org/paru.git"
readonly YAY_URL="https://aur.archlinux.org/yay.git"
readonly PARU_DEPS=("base-devel" "git" "rust")
readonly YAY_DEPS=("base-devel" "git" "go")
readonly PACMAN_DB="/var/lib/pacman/local"
readonly LOCK_FILE="/tmp/aur_helper_installer.lock"

# --- Formatting & Logs ---
if [[ -t 1 ]]; then
    readonly BLUE=$'\033[0;34m'
    readonly GREEN=$'\033[0;32m'
    readonly YELLOW=$'\033[1;33m'
    readonly RED=$'\033[0;31m'
    readonly NC=$'\033[0m'
else
    readonly BLUE="" GREEN="" YELLOW="" RED="" NC=""
fi

log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*" >&2; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }

# --- Cleanup & Locks ---
BUILD_DIR=""
cleanup() {
    local exit_code=$?
    # Release lock
    rm -f "$LOCK_FILE"
    
    # Clean build dir
    if [[ -n "${BUILD_DIR:-}" && -d "${BUILD_DIR}" ]]; then
        # Safety check to ensure we are deleting a temp dir
        if [[ "$BUILD_DIR" == /tmp/* ]]; then
            log_info "Cleaning up temporary build context..."
            rm -rf -- "${BUILD_DIR}"
        fi
    fi
    
    # Only warn if it's a real failure (not 0)
    if [[ $exit_code -ne 0 ]]; then
        log_warn "Script exited with code $exit_code"
    fi
}
trap cleanup EXIT INT TERM

# --- Functions ---

acquire_lock() {
    if [[ -e "$LOCK_FILE" ]]; then
        log_error "Lock file exists ($LOCK_FILE). Is the script already running?"
        exit 1
    fi
    touch "$LOCK_FILE"
}

get_real_user() {
    local user="${SUDO_USER:-}"
    if [[ -z "$user" ]]; then
        log_error "SUDO_USER is unset. Run via 'sudo ./script.sh'"
        return 1
    fi
    if ! id "$user" &>/dev/null; then
        log_error "User $user does not exist."
        return 1
    fi
    echo "$user"
}

# The Critical "Ghost Package" Fixer
sanitize_target() {
    local target="$1" # e.g., "paru"
    
    # 1. Check if the binary works. If yes, we are good.
    if command -v "$target" &>/dev/null; then
        if "$target" --version &>/dev/null; then
            return 0 # Healthy
        else
            log_warn "Binary '$target' exists but is SEGFAULTING/BROKEN."
        fi
    fi

    # 2. Check Pacman DB for variants (paru, paru-bin, paru-git)
    local -a db_entries=("$PACMAN_DB/$target"*/)
    
    if [[ ${#db_entries[@]} -gt 0 ]]; then
        log_warn "Ghost package detected in Pacman DB: $target"
        
        # Try polite removal first
        if pacman -Qq "$target" &>/dev/null; then
             pacman -Rns --noconfirm "$target" || true
        fi
        
        # THE NUCLEAR OPTION
        local -a remaining_entries=("$PACMAN_DB/$target"*/)
        for entry in "${remaining_entries[@]}"; do
            if [[ -d "$entry" ]]; then
                log_warn "Force removing corrupted DB entry: $entry"
                rm -rf -- "$entry"
            fi
        done
    fi
    
    # Return 1 to indicate "Not Installed/Removed"
    return 1
}

build_helper() {
    local r_user="$1"
    local url="$2"
    local pkg_name="$3"
    
    log_info "Starting build for: $pkg_name"
    
    BUILD_DIR=$(mktemp -d)
    # Fix permissions for the build user
    local r_group
    r_group=$(id -gn "$r_user")
    chown -R "$r_user:$r_group" "$BUILD_DIR"
    chmod 700 "$BUILD_DIR"

    # Clone and Build in subshell
    if ! sudo -u "$r_user" bash -c '
        set -euo pipefail
        cd "$1"
        git clone --depth 1 "$2" "$3"
        cd "$3"
        makepkg --noconfirm -cf
    ' -- "$BUILD_DIR" "$url" "$pkg_name"; then
        log_error "Compilation of $pkg_name failed."
        return 1
    fi

    # Install
    log_info "Locating package archive..."
    local pkg_files=("$BUILD_DIR/$pkg_name"/*.pkg.tar.*)
    
    if [[ ${#pkg_files[@]} -gt 0 ]]; then
        log_info "Installing ${pkg_files[0]}..."
        pacman -U --noconfirm "${pkg_files[0]}"
        return 0
    else
        log_error "Build finished but no .pkg.tar.* found."
        return 1
    fi
}

# --- Main ---
main() {
    # 1. Root Check
    if [[ $EUID -ne 0 ]]; then
        log_error "Must run as root (sudo)."
        exit 1
    fi
    
    acquire_lock

    # 2. User Check
    local r_user
    if ! r_user=$(get_real_user); then
        exit 1
    fi
    log_info "Target User: $r_user"

    # 3. Check/Sanitize Paru (Returns 0 if healthy, 1 if missing)
    if sanitize_target "paru"; then
        log_success "Paru is already installed and functional. Exiting."
        exit 0
    fi

    # 4. Attempt Paru Install
    log_info "Attempting to install Paru..."
    pacman -S --needed --noconfirm "${PARU_DEPS[@]}"

    if build_helper "$r_user" "$PARU_URL" "paru"; then
        log_success "Paru successfully installed."
        exit 0
    fi

    # 5. PARU FAILED - TRIGGER FALLBACK
    log_error "Paru installation failed."
    log_info ">>> INITIATING FALLBACK PROTOCOL: YAY <<<"
    
    # FIX: "|| true" prevents set -e from killing the script when sanitize returns 1
    sanitize_target "paru" || true

    # 6. Install Yay
    pacman -S --needed --noconfirm "${YAY_DEPS[@]}"
    
    # Check if Yay is already okay
    if sanitize_target "yay"; then
        log_success "Yay is already functional."
        exit 0
    fi

    if build_helper "$r_user" "$YAY_URL" "yay"; then
        log_success "Fallback Complete: Yay installed successfully."
        exit 0
    else
        log_error "CRITICAL FAILURE: Both Paru and Yay failed to build."
        exit 1
    fi
}

main "$@"
