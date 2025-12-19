#!/usr/bin/env bash
#
# Arch Linux mkinitcpio Configuration Optimizer
# Context: Configures /etc/mkinitcpio.conf ONLY. Does NOT generate initramfs.
#

# --- 1. Safety & Environment ---
set -euo pipefail
IFS=$'\n\t'

# --- 2. Visuals & Helpers ---
BOLD=$'\e[1m'
RESET=$'\e[0m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
RED=$'\e[31m'
YELLOW=$'\e[33m'

log_info() { printf "${BLUE}[INFO]${RESET} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${RESET} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${RESET} %s\n" "$1"; }
log_step() { printf "\n${BOLD}${YELLOW}>>> STEP: %s${RESET}\n" "$1"; }

ask_next_step() {
    local step_description="$1"
    printf "\n${BLUE}----------------------------------------------------------------${RESET}\n"
    printf "${BOLD}UPCOMING STEP:${RESET} %s\n" "$step_description"

    if [[ "${INTERACTIVE_MODE:-false}" == "false" ]]; then
        printf "${GREEN}>> Auto-proceeding...${RESET}\n"
        return 0
    fi

    while true; do
        read -r -p "Action: [P]roceed, [S]kip, or [Q]uit? (p/s/q) [Default: p]: " choice
        choice=${choice:-p}
        case "${choice,,}" in
            p|proceed|y|yes) return 0 ;;
            s|skip) log_info "Skipping step: $step_description"; return 1 ;;
            q|quit) log_info "User requested exit."; exit 0 ;;
            *) printf "Invalid choice.\n" ;;
        esac
    done
}

# --- 3. Main Logic ---

# Check/Set Interactive Mode (defaults to Auto if not set by Orchestrator)
if [[ -z "${INTERACTIVE_MODE+x}" ]]; then
    # If this script is run standalone, default to auto, or ask? 
    # Consistent with previous script: assume auto if variable is unset/empty
    INTERACTIVE_MODE="false" 
fi

log_step "mkinitcpio.conf Optimization"

if ask_next_step "Configure mkinitcpio (BTRFS modules & Systemd hooks)"; then
    CONF_FILE="/etc/mkinitcpio.conf"

    if [[ -f "$CONF_FILE" ]]; then
        log_info "Applying BTRFS modules, binaries, and systemd hooks to $CONF_FILE..."
        
        # 1. MODULES: Add btrfs
        # 2. BINARIES: Add /usr/bin/btrfs (vital for btrfs checks at boot)
        # 3. HOOKS: Switch to systemd, removal of udev (replaced by systemd), add sd-vconsole
        
        sed -i -e 's/^MODULES=.*/MODULES=(btrfs)/' \
            -e 's|^BINARIES=.*|BINARIES=(/usr/bin/btrfs)|' \
            -e 's/^HOOKS=.*/HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)/' \
            "$CONF_FILE"
            
        log_success "mkinitcpio.conf updated successfully."
        log_info "NOTE: Initramfs generation will occur in a later step."
    else
        log_error "$CONF_FILE not found! Cannot apply configuration."
        exit 1
    fi
fi
