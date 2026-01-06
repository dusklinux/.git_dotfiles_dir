#!/usr/bin/env bash
# Install AUR helper - Paru or YAY
# -----------------------------------------------------------------------------
# Script: 009_aur_helper_final_v3.sh
# Description: The "Nuclear Option" AUR Helper Installer.
#              1. Asks user for preference (Paru vs Yay).
#              2. DEFAULT: Attempts to build Paru (Rust).
#              3. FAIL-SAFE: If Paru fails (or user chooses Yay), installs Yay.
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
        if [[ "$BUILD_DIR" == /tmp/* ]]; then
            log_info "Cleaning up temporary build context..."
            rm -rf -- "${BUILD_DIR}"
        fi
    fi
    
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
    local target="$1" 
    
    # 1. Check if binary works
    if command -v "$target" &>/dev/null; then
        if "$target" --version &>/dev/null; then
            return 0 # Healthy
        else
            log_warn "Binary '$target' exists but is SEGFAULTING/BROKEN."
        fi
    fi

    # 2. Check Pacman DB for variants
    local -a db_entries=("$PACMAN_DB/$target"*/)
    
    if [[ ${#db_entries[@]} -gt 0 ]]; then
        log_warn "Ghost package detected in Pacman DB: $target"
        
        if pacman -Qq "$target" &>/dev/null; then
             pacman -Rns --noconfirm "$target" || true
        fi
        
        # NUCLEAR OPTION: Force remove db entries
        local -a remaining_entries=("$PACMAN_DB/$target"*/)
        for entry in "${remaining_entries[@]}"; do
            if [[ -d "$entry" ]]; then
                log_warn "Force removing corrupted DB entry: $entry"
                rm -rf -- "$entry"
            fi
        done
    fi
    
    return 1
}

build_helper() {
    local r_user="$1"
    local url="$2"
    local pkg_name="$3"
    
    log_info "Starting build for: $pkg_name"
    
    BUILD_DIR=$(mktemp -d)
    local r_group
    r_group=$(id -gn "$r_user")
    chown -R "$r_user:$r_group" "$BUILD_DIR"
    chmod 700 "$BUILD_DIR"

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

# Wrapper for Paru installation
try_install_paru() {
    local r_user="$1"

    if sanitize_target "paru"; then
        log_success "Paru is already installed and functional."
        return 0
    fi

    log_info "Attempting to install Paru..."
    pacman -S --needed --noconfirm "${PARU_DEPS[@]}"

    if build_helper "$r_user" "$PARU_URL" "paru"; then
        log_success "Paru successfully installed."
        return 0
    fi

    return 1
}

# Wrapper for Yay installation
try_install_yay() {
    local r_user="$1"

    if sanitize_target "yay"; then
        log_success "Yay is already installed and functional."
        return 0
    fi

    log_info "Attempting to install Yay..."
    pacman -S --needed --noconfirm "${YAY_DEPS[@]}"

    if build_helper "$r_user" "$YAY_URL" "yay"; then
        log_success "Yay successfully installed."
        return 0
    fi

    return 1
}

# --- Main ---
main() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Must run as root (sudo)."
        exit 1
    fi
    
    acquire_lock

    local r_user
    if ! r_user=$(get_real_user); then
        exit 1
    fi
    log_info "Target User: $r_user"

    # --- Interactive Prompt ---
    echo ""
    log_info "Select AUR Helper to install:"
    echo -e "  ${GREEN}[P]${NC}aru (Default) - Rust-based, feature-rich, recommended."
    echo -e "  ${YELLOW}[y]${NC}ay            - Go-based, classic, reliable."
    
    # Read user input, default to 'P'
    read -r -p "Enter selection [P/y]: " choice
    choice=${choice:-P}

    if [[ "$choice" =~ ^[yY] ]]; then
        # ---------------------------------------------------------
        # Path A: User specifically requested Yay
        # ---------------------------------------------------------
        log_info "User selected: Yay"
        if try_install_yay "$r_user"; then
            exit 0
        else
            log_error "Yay installation failed."
            exit 1
        fi
    else
        # ---------------------------------------------------------
        # Path B: User selected Paru (or Default) -> Fallback to Yay
        # ---------------------------------------------------------
        log_info "User selected: Paru (with fallback)"
        
        if try_install_paru "$r_user"; then
            exit 0
        fi

        # PARU FAILED - TRIGGER FALLBACK
        log_error "Paru installation failed."
        log_info ">>> INITIATING FALLBACK PROTOCOL: YAY <<<"
        
        # Clean up any partial Paru mess before starting Yay
        sanitize_target "paru" || true

        if try_install_yay "$r_user"; then
            log_success "Fallback Complete: Yay installed successfully."
            exit 0
        else
            log_error "CRITICAL FAILURE: Both Paru and Yay failed to build."
            exit 1
        fi
    fi
}

main "$@"
