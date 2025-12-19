#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# MODULE: LIVE ENVIRONMENT PREP
# Description: Font, Cowspace, Battery, Time, Keyring, Neovim
# -----------------------------------------------------------------------------
set -euo pipefail
readonly C_BOLD=$'\033[1m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_BLUE=$'\033[34m' C_RESET=$'\033[0m'

msg_info() { echo -e "${C_BLUE}[INFO]${C_RESET} $1"; }
msg_ok()   { echo -e "${C_GREEN}[OK]${C_RESET}   $1"; }
msg_warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $1"; }

echo -e "${C_BOLD}=== PRE-INSTALL ENVIRONMENT SETUP ===${C_RESET}"

# 1. Console Font (Visuals first)
msg_info "Setting console font..."
setfont latarcyrheb-sun32 || msg_warn "Could not set font. Continuing..."

# 2. Battery Threshold (Laptop QoL)
BAT_DIR=$(find /sys/class/power_supply -maxdepth 1 -name "BAT*" -print -quit)
if [[ -n "$BAT_DIR" ]]; then
    BAT_CTRL="$BAT_DIR/charge_control_end_threshold"
    if [[ -f "$BAT_CTRL" ]] && [[ -w "$BAT_CTRL" ]]; then
        echo "60" > "$BAT_CTRL"
        msg_ok "Battery limit set to 60%."
    fi
fi

# 3. Cowspace (Critical for RAM-heavy compiles/installs)
# Logic Update: Only remount if user explicitly provides a value.
TOTAL_RAM=$(free -h | awk '/^Mem:/ {print $2}')
CURRENT_COW=$(df -h /run/archiso/cowspace | awk 'NR==2 {print $2}')

msg_info "System RAM: $TOTAL_RAM | Current Cowspace: $CURRENT_COW"

read -r -p ":: Enter new Cowspace size (e.g. 1G) [Leave empty to keep default]: " USER_COW

# Trim whitespace just in case
USER_COW="${USER_COW// /}"

if [[ -n "$USER_COW" ]]; then
    if [[ "$USER_COW" =~ ^[0-9]+[GgMm]$ ]]; then
        msg_info "Resizing Cowspace to $USER_COW..."
        if mount -o remount,size="$USER_COW" /run/archiso/cowspace; then
            NEW_SIZE=$(df -h /run/archiso/cowspace | awk 'NR==2 {print $2}')
            msg_ok "Cowspace successfully resized: $NEW_SIZE"
        else
            msg_warn "Remount failed. Keeping previous size."
        fi
    else
        msg_warn "Invalid format '$USER_COW'. Skipping resize."
    fi
else
    msg_info "No input detected. Keeping default Cowspace ($CURRENT_COW)."
fi

# 4. Time & Network
msg_info "Configuring Time (NTP)..."
timedatectl set-ntp true

# 5. Pacman Init, Keyring Refresh & Tools
#    Modified sequence to ensure robustness in the ISO environment.
#    Sleeps added to allow GPG agent/locks to clear between steps.
msg_info "Initializing and Refreshing Pacman Keys..."

msg_info "1/4: pacman-key --init"
pacman-key --init
sleep 2

msg_info "2/4: pacman-key --populate archlinux"
pacman-key --populate archlinux
sleep 2

msg_info "3/4: Installing latest archlinux-keyring..."
pacman -Sy --noconfirm archlinux-keyring
sleep 2

msg_info "4/4: Performing forced refresh (pacman -Syy)..."
pacman -Syy --noconfirm

msg_info "Installing Tools (Neovim, Git, Curl)..."
# Database is already updated from step 4, so we just install.
pacman -S --needed --noconfirm neovim git curl

msg_ok "Environment Ready."
