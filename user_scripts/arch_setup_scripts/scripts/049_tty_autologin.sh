#!/usr/bin/env bash
# ==============================================================================
# Script Name: setup_autologin.sh
# Description: Configures systemd TTY1 autologin for Arch/Hyprland/UWSM.
#              Conditionally disables SDDM and creates systemd override.
# Author:      Elite DevOps Architect
# ==============================================================================

# Strict Mode
set -euo pipefail

# --- Configuration & Styling ---
readonly SYSTEMD_DIR="/etc/systemd/system/getty@tty1.service.d"
readonly OVERRIDE_FILE="${SYSTEMD_DIR}/override.conf"

# ANSI Colors
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly BLUE=$'\033[0;34m'
readonly YELLOW=$'\033[1;33m'
readonly NC=$'\033[0m' # No Color

# --- Helper Functions ---
log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

confirm_action() {
    local user_name="$1"
    printf "${YELLOW}Autologin Setup for TTY1 (Arch Linux)${NC}\n"
    printf "This will enable password-less login on boot for user: ${GREEN}%s${NC}\n" "${user_name}"
    printf "It provides faster boot times for Hyprland/UWSM setups.\n"
    
    read -r -p "Do you want to configure TTY autologin now? [y/N] " response
    if [[ ! "${response}" =~ ^[yY](es)?$ ]]; then
        log_info "Operation cancelled by user. No changes made."
        exit 0
    fi
}

# --- Logic Flow ---

# 1. Determine Target User
# If we are root, we look at SUDO_USER. If normal user, we look at USER.
if [[ "${EUID}" -eq 0 ]]; then
    target_user="${SUDO_USER:-}"
    if [[ -z "${target_user}" ]]; then
        log_error "Could not detect the actual user. Do not run this script from a raw root shell."
        log_error "Please run as your normal user via sudo."
        exit 1
    fi
else
    target_user="${USER}"
fi

# 2. Conditional Prompt
# Check if we have already confirmed via the environment variable (passed during sudo exec)
if [[ "${_AUTOLOGIN_CONFIRMED:-false}" != "true" ]]; then
    confirm_action "${target_user}"
fi

# 3. Privilege Escalation
# If not root, re-execute self with sudo, passing the confirmation flag to prevent double-prompting
if [[ "${EUID}" -ne 0 ]]; then
    log_info "Escalating privileges to apply changes..."
    export _AUTOLOGIN_CONFIRMED=true
    exec sudo -E "$0" "$@"
fi

# ==============================================================================
# 4. Execution Phase (Root)
# ==============================================================================

log_info "Configuring autologin for user: ${target_user}"

# 4.1 Handle Display Managers (SDDM)
if systemctl list-unit-files sddm.service &>/dev/null; then
    if systemctl is-enabled --quiet sddm.service 2>/dev/null; then
        log_info "Disabling SDDM service to prevent conflict..."
        systemctl disable sddm.service --quiet
        log_success "SDDM service disabled."
    else
        log_info "SDDM is installed but not enabled. Skipping."
    fi
else
    log_info "SDDM not found. Proceeding..."
fi

# 4.2 Create Directory Structure
if [[ ! -d "${SYSTEMD_DIR}" ]]; then
    log_info "Creating systemd override directory..."
    mkdir -p "${SYSTEMD_DIR}"
fi

# 4.3 Write the Override File (Clean write, no backups)
log_info "Writing override configuration..."

cat > "${OVERRIDE_FILE}" <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin ${target_user} --noclear --noissue %I \$TERM
EOF

# 4.4 Reload Daemon
systemctl daemon-reload

# --- Final Feedback ---
echo ""
log_success "Autologin configuration complete."
printf "  ${YELLOW}->${NC} File created: %s\n" "${OVERRIDE_FILE}"
printf "  ${YELLOW}->${NC} User set: %s\n" "${target_user}"
log_info "Reboot your machine to test the really fast bootup into TTY1."
