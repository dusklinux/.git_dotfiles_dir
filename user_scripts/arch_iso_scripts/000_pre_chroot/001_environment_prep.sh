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
# We only ask if RAM is < 32GB, otherwise default is usually fine, 
# but we will keep your logic as it's good for custom setups.
TOTAL_RAM=$(free -h | awk '/^Mem:/ {print $2}')
msg_info "System RAM: $TOTAL_RAM"

# Non-interactive default if user just hits enter
DEFAULT_COW="2G"
read -r -p ":: Enter Cowspace size (e.g. 4G) [Default: $DEFAULT_COW]: " USER_COW
TARGET_COW="${USER_COW:-$DEFAULT_COW}"

if [[ ! "$TARGET_COW" =~ ^[0-9]+[GgMm]$ ]]; then
    echo "Invalid format. using Default."
    TARGET_COW="$DEFAULT_COW"
fi

msg_info "Resizing Cowspace to $TARGET_COW..."
mount -o remount,size="$TARGET_COW" /run/archiso/cowspace
df -h /run/archiso/cowspace | awk 'NR==2 {print "   New Size: " $2}'

# 4. Time & Network
msg_info "Configuring Time (NTP)..."
timedatectl set-ntp true

# 5. Pacman Init & Tools
msg_info "Initializing Pacman Keyring..."
pacman-key --init
pacman-key --populate archlinux

msg_info "Installing Tools (Neovim, Git, Curl)..."
# Updates database and installs tools. 
# --needed skips if already there (saves time)
pacman -Sy --needed --noconfirm neovim git curl

msg_ok "Environment Ready."
