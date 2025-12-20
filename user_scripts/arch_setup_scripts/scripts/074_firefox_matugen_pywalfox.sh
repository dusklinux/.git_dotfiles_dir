#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: 044_firefox_pywal.sh
# Description: Setup Firefox, Pywalfox, and Matugen (Orchestra compatible)
# Environment: Arch Linux / Hyprland / UWSM
# -----------------------------------------------------------------------------

# --- Safety & Error Handling ---
set -euo pipefail
IFS=$'\n\t'

# --- Bash Version Guard (Bash 4.0+ required) ---
if ((BASH_VERSINFO[0] < 4)); then
    printf "Error: Bash 4.0+ required\n" >&2
    exit 1
fi

# --- Visual Styling ---
if command -v tput &>/dev/null && (( $(tput colors) >= 8 )); then
    readonly C_RESET=$'\033[0m'
    readonly C_BOLD=$'\033[1m'
    readonly C_BLUE=$'\033[38;5;45m'
    readonly C_GREEN=$'\033[38;5;46m'
    readonly C_MAGENTA=$'\033[38;5;177m'
    readonly C_WARN=$'\033[38;5;214m'
    readonly C_ERR=$'\033[38;5;196m'
else
    readonly C_RESET='' C_BOLD='' C_BLUE='' C_GREEN=''
    readonly C_MAGENTA='' C_WARN='' C_ERR=''
fi

# --- Configuration ---
readonly TARGET_URL='https://addons.mozilla.org/en-US/firefox/addon/pywalfox/'
readonly BROWSER_BIN='firefox'
readonly NATIVE_HOST_PKG='python-pywalfox'
readonly THEME_ENGINE_PKG='matugen'

# --- Logging Utilities ---
log_info()    { printf '%b[INFO]%b %s\n' "${C_BLUE}" "${C_RESET}" "$1"; }
log_success() { printf '%b[SUCCESS]%b %s\n' "${C_GREEN}" "${C_RESET}" "$1"; }
log_warn()    { printf '%b[WARNING]%b %s\n' "${C_WARN}" "${C_RESET}" "$1" >&2; }
die()         { printf '%b[ERROR]%b %s\n' "${C_ERR}" "${C_RESET}" "$1" >&2; exit 1; }

# --- Helper Functions ---

check_aur_helper() {
    if command -v paru &>/dev/null; then
        echo "paru"
    elif command -v yay &>/dev/null; then
        echo "yay"
    else
        return 1
    fi
}

preflight() {
    if ((EUID == 0)); then
        die 'This script must be run as a normal user, not Root/Sudo.'
    fi
}

# --- Main Logic ---
main() {
    preflight

    # 1. Interactive Prompt (TTY Safe)
    printf '\n%b>>> OPTIONAL SETUP: FIREFOX, PYWALFOX & MATUGEN%b\n' "${C_WARN}" "${C_RESET}" > /dev/tty
    printf 'This will install Firefox, Matugen, and the Pywalfox backend.\n' > /dev/tty
    printf '%bDo you want to proceed? [y/N]:%b ' "${C_BOLD}" "${C_RESET}" > /dev/tty
    
    local response=''
    if [[ -r /dev/tty ]]; then read -r response < /dev/tty; else read -r response || true; fi

    if [[ ! "${response,,}" =~ ^y(es)?$ ]]; then
        log_info 'Skipping setup by user request.'
        exit 0
    fi

    # 2. Install Standard Packages (Firefox & Matugen)
    log_info "Ensuring ${BROWSER_BIN} and ${THEME_ENGINE_PKG} are installed..."
    
    # We use sudo for pacman. The --needed flag prevents re-installing if present.
    if sudo pacman -S --needed --noconfirm "${BROWSER_BIN}" "${THEME_ENGINE_PKG}"; then
        log_success "Core packages installed/verified."
        hash -r 2>/dev/null || true
    else
        die "Failed to install ${BROWSER_BIN} or ${THEME_ENGINE_PKG}."
    fi

    # 3. Install AUR Backend (python-pywalfox)
    log_info "Checking for Pywalfox native backend..."
    
    local helper
    if helper=$(check_aur_helper); then
        log_info "Using ${helper} to install ${NATIVE_HOST_PKG}..."
        # Run without sudo (helper handles it). Use --needed to skip if present.
        if "$helper" -S --needed --noconfirm "${NATIVE_HOST_PKG}"; then
            log_success "${NATIVE_HOST_PKG} is ready."
        else
            die "Failed to install ${NATIVE_HOST_PKG} using ${helper}."
        fi
    else
        log_warn "No AUR helper (paru/yay) found. Skipping ${NATIVE_HOST_PKG} installation."
        log_warn "You must install 'python-pywalfox' manually for colors to update!"
        sleep 2
    fi

    # 4. Instructions
    if [[ -t 1 ]]; then clear; fi

    printf '%b%b' "${C_BOLD}" "${C_BLUE}"
    cat <<'BANNER'
   ╔═══════════════════════════════════════╗
   ║      PYWALFOX SETUP ASSISTANT         ║
   ║      Arch / Hyprland / UWSM           ║
   ╚═══════════════════════════════════════╝
BANNER
    printf '%b\n' "${C_RESET}"

    # CRITICAL WARNINGS
    printf "%b[IMPORTANT CONFIGURATION NOTE]%b\n" "${C_WARN}" "${C_RESET}"
    printf "1. %bMatugen must be configured%b for this to work (already setup for dusky).\n" "${C_BOLD}" "${C_RESET}"
    printf "   Ensure you have a config at: ~/.config/matugen/config.toml\n"
    printf "2. You must have the Pywalfox extension installed in the browser.\n\n"

    printf '%bStep 1:%b I will open Firefox. Click %b"Add to Firefox"%b.\n' "${C_MAGENTA}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
    printf '%bStep 2:%b Click the Extension Icon -> %b"Fetch Pywal Colors"%b.\n\n' "${C_MAGENTA}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"

    printf 'Press %b[ENTER]%b to launch Firefox...' "${C_GREEN}" "${C_RESET}" > /dev/tty
    if [[ -r /dev/tty ]]; then read -r < /dev/tty; else read -r || true; fi

    # 5. Launch Browser
    printf '\n'
    log_info "Launching ${BROWSER_BIN}..."

    if command -v uwsm &>/dev/null; then
        uwsm app -- "${BROWSER_BIN}" "${TARGET_URL}" &>/dev/null &
    else
        if command -v setsid &>/dev/null; then
            setsid -f "${BROWSER_BIN}" "${TARGET_URL}" &>/dev/null
        else
            nohup "${BROWSER_BIN}" "${TARGET_URL}" &>/dev/null 2>&1 &
        fi
    fi

    disown &>/dev/null || true
    sleep 1
    log_success "Firefox setup sequence complete."
}

main "$@"
