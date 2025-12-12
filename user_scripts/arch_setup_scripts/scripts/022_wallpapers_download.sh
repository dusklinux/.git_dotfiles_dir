#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: get-wallpapers.sh
# Description: Downloads and installs Dusk wallpapers for Arch/Hyprland.
# Context: Arch Linux, Hyprland, UWSM.
# Author: Gemini (Elite DevOps Persona)
# -----------------------------------------------------------------------------

# --- 1. Safety & Environment ---
set -euo pipefail
IFS=$'\n\t'

# --- 2. Visuals & logging ---
# Detect TTY to prevent color codes in pipe output
if [[ -t 1 ]]; then
    readonly C_RESET=$'\033[0m'
    readonly C_BOLD=$'\033[1m'
    readonly C_GREEN=$'\033[32m'
    readonly C_BLUE=$'\033[34m'
    readonly C_RED=$'\033[31m'
    readonly C_YELLOW=$'\033[33m'
else
    readonly C_RESET='' C_BOLD='' C_GREEN='' C_BLUE='' C_RED='' C_YELLOW=''
fi

log_info()    { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$*"; }
log_success() { printf "${C_GREEN}[OK]${C_RESET}   %s\n" "$*"; }
log_warn()    { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$*"; }
log_error()   { printf "${C_RED}[ERR]${C_RESET}  %s\n" "$*" >&2; }

# --- 3. Configuration ---
readonly REPO_URL="https://github.com/dusklinux/images.git"
# Ensure HOME is set, otherwise error out immediately
readonly TARGET_PARENT="${HOME:?HOME not set}/Pictures"
# Use a unique temporary folder name to avoid collisions
readonly CLONE_DIR="$TARGET_PARENT/images-tmp-$$"
readonly SUBDIRS=("dark" "light")

# --- 4. Cleanup Trap ---
cleanup() {
    local exit_code=$?
    
    # Remove the clone directory if it exists
    if [[ -d "$CLONE_DIR" ]]; then
        rm -rf "$CLONE_DIR"
    fi
    
    # Restore cursor visibility
    if [[ -t 1 ]]; then
        tput cnorm 2>/dev/null || true
    fi

    if [[ $exit_code -ne 0 && $exit_code -ne 130 ]]; then
        log_error "Script failed with exit code $exit_code."
    fi
}
# Trap EXIT handles normal exits, errors, and interrupts (INT/TERM) automatically
trap cleanup EXIT

# --- 5. Helper Functions ---

show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    local temp
    
    if [[ -t 1 ]]; then
        tput civis 2>/dev/null || true # Hide cursor
    fi
    
    printf "${C_BLUE}Downloading resources... ${C_RESET}"
    
    while kill -0 "$pid" 2>/dev/null; do
        temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep "$delay"
        printf "\b\b\b\b\b\b"
    done
    
    printf "    \b\b\b\b"
    echo ""
}

# --- 6. Main Logic ---

main() {
    # Header
    printf "${C_BOLD}:: Wallpaper Manager for Arch/Hyprland${C_RESET}\n"
    
    # 6.1 Prompt User
    printf "   Would you like to download the Dusk wallpaper collection (~500MB)?\n"
    local response
    read -r -p "   [y/N] > " response
    
    if [[ ! "${response,,}" =~ ^y(es)?$ ]]; then
        log_info "Skipping download. You can manually manage wallpapers in $TARGET_PARENT."
        exit 0
    fi

    # 6.2 Pre-flight Checks
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed. Please run: sudo pacman -S git"
        exit 1
    fi

    # Ensure parent directory exists
    if [[ ! -d "$TARGET_PARENT" ]]; then
        log_info "Creating directory: $TARGET_PARENT"
        mkdir -p "$TARGET_PARENT"
    fi

    # 6.3 Download (Git Clone)
    log_info "Cloning repository from $REPO_URL..."
    
    # Run git in subshell, silencing output. 
    # If it fails, we catch the exit code via 'wait'.
    (git clone --depth 1 "$REPO_URL" "$CLONE_DIR" &>/dev/null) &
    local git_pid=$!
    
    show_spinner "$git_pid"
    
    if ! wait "$git_pid"; then
        log_error "Download failed."
        log_error "Check your internet connection or try cloning manually:"
        log_error "git clone $REPO_URL"
        exit 1
    fi
    log_success "Download complete."

    # 6.4 Move and Merge
    log_info "Processing files..."

    local dir src dest
    for dir in "${SUBDIRS[@]}"; do
        src="$CLONE_DIR/$dir"
        dest="$TARGET_PARENT/$dir"

        if [[ -d "$src" ]]; then
            if [[ -d "$dest" ]]; then
                log_warn "Directory '$dir' already exists. Merging..."
                
                # Attempt rsync (safest), fallback to cp with dot-trick
                if command -v rsync &> /dev/null; then
                    # -a: archive, --ignore-existing: don't overwrite if file exists
                    rsync -a --ignore-existing "$src/" "$dest/"
                else
                    # cp -n: no overwrite. "$src/." copies contents, avoids wildcard issues.
                    cp -rn "$src/." "$dest/" 2>/dev/null || true
                fi
            else
                mv "$src" "$TARGET_PARENT/"
            fi
            log_success "Installed: $dir wallpapers"
        else
            log_warn "Source directory '$dir' not found in repository."
        fi
    done

    # 6.5 Success
    log_success "Operation finished."
    log_info "Wallpapers located in: ${TARGET_PARENT/$HOME/\~}"
}

main "$@"
