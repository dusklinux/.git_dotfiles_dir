#!/usr/bin/env bash
# Choose default File Manager between Thunar (GUI) and Yazi (Tui)
# Script: fm-switcher.sh
# Description: Toggles Hyprland file manager between Thunar (GUI) and Yazi (TUI)
#              Respects UWSM and Arch Linux standards.
# Author: Elite DevOps Engineer
# -----------------------------------------------------------------------------

set -euo pipefail

# --- Configuration ---
CONFIG_FILE="$HOME/.config/hypr/source/keybinds.conf"

# --- Styling ---
BOLD=$'\033[1m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m' # No Color

# --- Logging Functions ---
log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

# --- Error Handling ---
cleanup() {
    # Trap cleanup logic (if needed in future expansions)
    :
}
trap cleanup EXIT

# --- Prerequisite Checks ---
if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Configuration file not found at: $CONFIG_FILE"
    exit 1
fi

# --- Helper: Check Current State ---
# Returns 0 if the specified manager is currently set, 1 otherwise
is_current_manager() {
    local manager="$1"
    if grep -q "^\$fileManager = $manager" "$CONFIG_FILE"; then
        return 0
    else
        return 1
    fi
}

# --- Operation: Switch to Thunar ---
switch_to_thunar() {
    if is_current_manager "thunar"; then
        log_success "System is already configured for Thunar. No changes made."
        return
    fi

    log_info "Switching configuration to Thunar..."

    # 1. Update Variable
    sed -i 's/\$fileManager = yazi/\$fileManager = thunar/' "$CONFIG_FILE"

    # 2. Update Keybind (Remove terminal wrapper flags)
    # Target: bindd = $mainMod, E, File Manager, exec, uwsm-app -- $terminal -e $fileManager
    # Replace with: bindd = $mainMod, E, File Manager, exec, uwsm-app $fileManager
    sed -i 's/uwsm-app -- \$terminal -e \$fileManager/uwsm-app \$fileManager/' "$CONFIG_FILE"

    # 3. Update MIME defaults
    log_info "Updating XDG MIME defaults..."
    xdg-mime default thunar.desktop inode/directory

    log_success "Switched to Thunar successfully."
}

# --- Operation: Switch to Yazi ---
switch_to_yazi() {
    if is_current_manager "yazi"; then
        log_success "System is already configured for Yazi. No changes made."
        return
    fi

    log_info "Switching configuration to Yazi..."

    # 1. Update Variable
    sed -i 's/\$fileManager = thunar/\$fileManager = yazi/' "$CONFIG_FILE"

    # 2. Update Keybind (Add terminal wrapper flags)
    # Target: bindd = $mainMod, E, File Manager, exec, uwsm-app $fileManager
    # Replace with: bindd = $mainMod, E, File Manager, exec, uwsm-app -- $terminal -e $fileManager
    # Note: We match strictly to ensure we don't double-patch
    sed -i 's/uwsm-app \$fileManager/uwsm-app -- \$terminal -e \$fileManager/' "$CONFIG_FILE"

    # 3. Update MIME defaults
    log_info "Updating XDG MIME defaults..."
    xdg-mime default yazi.desktop inode/directory

    log_success "Switched to Yazi successfully."
}

# --- Main Interaction Loop ---
main() {
    printf "${BOLD}File Manager Switcher (UWSM/Hyprland)${NC}\n"
    
    # --- Detection Logic ---
    if is_current_manager "thunar"; then
        printf "Current Config: ${GREEN}Thunar${NC}\n"
    elif is_current_manager "yazi"; then
        printf "Current Config: ${GREEN}Yazi${NC}\n"
    else
        printf "Current Config: ${RED}Unknown / Neither${NC}\n"
    fi
    printf -- "--------------------------------------\n"

    printf "1) Switch to ${BOLD}Thunar${NC} (GUI) [Default]\n"
    printf "2) Switch to ${BOLD}Yazi${NC} (Terminal)\n"
    printf "q) Quit\n"
    
    # Read with default logic
    read -r -p "Select an option [1]: " choice

    # Trim whitespace (optional but good practice)
    choice="${choice#"${choice%%[![:space:]]*}"}"

    case "$choice" in
        1|thunar|Thunar|"")
            switch_to_thunar
            ;;
        2|yazi|Yazi)
            switch_to_yazi
            ;;
        q|Q)
            log_info "Exiting."
            exit 0
            ;;
        *)
            log_error "Invalid selection."
            exit 1
            ;;
    esac
}

main
