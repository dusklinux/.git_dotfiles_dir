#!/usr/bin/env bash
# ==============================================================================
#  Arch Linux Systemd-boot Optimizer (Hyprland/UWSM Context)
#  Description: Configures systemd-boot timeout and kernel log levels.
#  Author: Elite DevOps Engineer
# ==============================================================================

# --- 1. Safety & Environment ---
set -euo pipefail
IFS=$'\n\t'

# Cleanup trap
trap 'printf "\n\033[1;31m[!] Script interrupted or failed.\033[0m\n"; exit 1' ERR SIGINT SIGTERM

# --- 2. Styling (ANSI $ Syntax) ---
# Using $'...' format as requested for robust interpretation
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_YELLOW=$'\033[1;33m'
readonly C_RED=$'\033[1;31m'
readonly C_CYAN=$'\033[1;36m'

log_info()    { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"; }
log_success() { printf "${C_GREEN}[OK]${C_RESET}   %s\n" "$1"; }
log_warn()    { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$1"; }
log_error()   { printf "${C_RED}[ERR]${C_RESET}  %s\n" "$1"; exit 1; }

# --- 3. Root Privilege Check ---
if [[ $EUID -ne 0 ]]; then
    log_info "Root privileges required. Elevating..."
    exec sudo "$0" "$@"
fi

# --- 4. Bootloader Verification ---
readonly LOADER_CONF="/boot/loader/loader.conf"
readonly ENTRIES_DIR="/boot/loader/entries"

if [[ ! -f "$LOADER_CONF" ]] || [[ ! -d "$ENTRIES_DIR" ]]; then
    log_warn "Systemd-boot configuration not found at /boot/loader/."
    log_info "Skipping optimization (This script is for systemd-boot only)."
    exit 0
fi

# --- 5. Helper Functions ---
ask_confirm() {
    local prompt="$1"
    local choice
    while true; do
        # Visual cue: (Y/n) implies Y is default
        printf "${C_CYAN}[?]${C_RESET} %s ${C_BOLD}(Y/n)${C_RESET}: " "$prompt"
        read -r choice
        # Logic: Empty string (Enter key) defaults to "yes"
        case "${choice,,}" in 
            y|yes|"") return 0 ;;
            n|no)     return 1 ;;
            *)        printf "    Please answer yes (y) or no (n).\n" ;;
        esac
    done
}

# --- 6. Configuration Analysis ---

clear
printf "${C_BOLD}:: Arch Linux Systemd-boot Optimizer${C_RESET}\n"

# A. Find the default entry
# We grab the value after 'default' (ignoring whitespace).
default_entry_name=$(grep "^default" "$LOADER_CONF" | awk '{print $2}' | tr -d '[:space:]')

if [[ -z "$default_entry_name" ]]; then
    log_warn "No 'default' line found in loader.conf. Cannot safely optimize kernel options."
    log_info "We can still optimize the menu timeout."
    target_entry_file=""
else
    # Systemd-boot allows 'default arch' to map to 'entries/arch.conf'
    # We check for the file exactly as named, or with .conf appended.
    if [[ -f "${ENTRIES_DIR}/${default_entry_name}" ]]; then
        target_entry_file="${ENTRIES_DIR}/${default_entry_name}"
    elif [[ -f "${ENTRIES_DIR}/${default_entry_name}.conf" ]]; then
        target_entry_file="${ENTRIES_DIR}/${default_entry_name}.conf"
    else
        log_error "Default entry '${default_entry_name}' specified in loader.conf, but file not found in ${ENTRIES_DIR}."
    fi
    printf "   Target Config: %s\n" "$LOADER_CONF"
    printf "   Target Entry:  %s\n\n" "$target_entry_file"
fi

# --- 7. Interactive Prompts ---

do_timeout=false
do_quiet=false

# Prompt 1: Boot Menu Timeout
if ask_confirm "Speed up boot? (Disable menu: timeout 0)"; then
    do_timeout=true
fi

# Prompt 2: Quiet Boot (Only if we found a valid entry file)
if [[ -n "$target_entry_file" ]]; then
    if ask_confirm "Disable boot screen logs? (Replace 'loglevel' with 'quiet')"; then
        do_quiet=true
    fi
fi

# --- 8. Execution ---

printf "\n${C_BOLD}:: Applying Configuration...${C_RESET}\n"

# A. Apply Timeout (loader.conf)
if [[ "$do_timeout" == true ]]; then
    if grep -q "^timeout" "$LOADER_CONF"; then
        # Replace existing timeout
        sed -i 's/^timeout.*/timeout  0/' "$LOADER_CONF"
        log_success "Boot menu disabled (timeout set to 0)."
    else
        # Append timeout if missing
        echo "timeout 0" >> "$LOADER_CONF"
        log_success "Boot menu disabled (timeout 0 added)."
    fi
fi

# B. Apply Quiet Mode (Entry File)
if [[ "$do_quiet" == true && -n "$target_entry_file" ]]; then
    # Strategy:
    # 1. Look for 'loglevel=X'. If found, replace with 'quiet'.
    # 2. If 'loglevel' is NOT found, check if 'quiet' is already there.
    # 3. If neither, append 'quiet' to the options line.
    
    # Check current content of options line
    current_options=$(grep "^options" "$target_entry_file")
    
    if [[ "$current_options" =~ loglevel=[0-9]+ ]]; then
        # Replace loglevel=X with quiet
        sed -i -E 's/loglevel=[0-9]+/quiet/g' "$target_entry_file"
        log_success "Replaced 'loglevel' with 'quiet' in ${default_entry_name}."
    elif [[ "$current_options" != *"quiet"* ]]; then
        # Append quiet to end of options line
        sed -i '/^options/ s/$/ quiet/' "$target_entry_file"
        log_success "Appended 'quiet' to kernel options in ${default_entry_name}."
    else
        log_info "'quiet' is already present. No changes needed."
    fi
fi

# --- 9. Completion ---

if [[ "$do_timeout" == true || "$do_quiet" == true ]]; then
    printf "\n"
    log_success "Systemd-boot configuration updated."
    printf "${C_BOLD}   Changes will take effect on the next reboot.${C_RESET}\n"
else
    printf "\n"
    log_info "No changes applied."
fi

# Cleanup trap
trap - ERR SIGINT SIGTERM
exit 0
