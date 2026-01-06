#!/usr/bin/env bash
# powerkey and lid behaviour. 
# -----------------------------------------------------------------------------
# Script: setup_logind_power.sh
# Description: Configures systemd-logind for Hyprland/UWSM power management.
# Author: Elite DevOps (Arch/Hyprland Architect)
# -----------------------------------------------------------------------------

# strict error handling
set -euo pipefail

# -----------------------------------------------------------------------------
# Visuals & Logging
# -----------------------------------------------------------------------------
readonly COLOR_RESET=$'\033[0m'
readonly COLOR_INFO=$'\033[1;34m'   # Blue
readonly COLOR_SUCCESS=$'\033[1;32m' # Green
readonly COLOR_WARN=$'\033[1;33m'   # Yellow
readonly COLOR_ERR=$'\033[1;31m'    # Red

log_info() { printf "${COLOR_INFO}[INFO]${COLOR_RESET} %s\n" "$1"; }
log_success() { printf "${COLOR_SUCCESS}[OK]${COLOR_RESET} %s\n" "$1"; }
log_err() { printf "${COLOR_ERR}[ERROR]${COLOR_RESET} %s\n" "$1" >&2; }

# Cleanup trap (Clean exit)
cleanup() {
    # No temporary files are created, but this ensures a clean exit code return
    :
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Privilege Check
# -----------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    log_info "Root privileges required for /etc/systemd modification."
    log_info "Re-executing with sudo..."
    exec sudo "$0" "$@"
fi

# -----------------------------------------------------------------------------
# Main Logic
# -----------------------------------------------------------------------------

# 1. Prompt User
printf "${COLOR_WARN}Power Management Configuration:${COLOR_RESET}\n"
printf "  - Power Key -> Suspend\n"
printf "  - Lid Close -> Ignore (Turn off screen only, no suspend)\n"
printf "\n"
read -r -p "Do you want to apply these settings to /etc/systemd/logind.conf? [y/N] " response

# 2. Logic Flow
if [[ "$response" =~ ^[yY]([eE][sS])?$ ]]; then
    log_info "Applying configuration to /etc/systemd/logind.conf..."

    # Write file (Replaces content entirely or creates if missing)
    cat > /etc/systemd/logind.conf << 'EOF'
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free
#  Software Foundation; either version 2.1 of the License, or (at your option)
#  any later version.
#
# Entries in this file show the compile time defaults. Local configuration
# should be created by either modifying this file (or a copy of it placed in
# /etc/ if the original file is shipped in /usr/), or by creating "drop-ins" in
# the /etc/systemd/logind.conf.d/ directory. The latter is generally
# recommended. Defaults can be restored by simply deleting the main
# configuration file and all drop-ins located in /etc/.
#
# Use 'systemd-analyze cat-config systemd/logind.conf' to display the full config.
#
# See logind.conf(5) for details.

[Login]
#NAutoVTs=6
#ReserveVT=6
#KillUserProcesses=no
#KillOnlyUsers=
#KillExcludeUsers=root
#InhibitDelayMaxSec=5
#UserStopDelaySec=10
#SleepOperation=suspend-then-hibernate suspend
HandlePowerKey=suspend
#HandlePowerKeyLongPress=ignore
#HandleRebootKey=reboot
#HandleRebootKeyLongPress=poweroff
#HandleSuspendKey=suspend
#HandleSuspendKeyLongPress=hibernate
#HandleHibernateKey=hibernate
#HandleHibernateKeyLongPress=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
#HandleLidSwitchDocked=ignore
#HandleSecureAttentionKey=secure-attention-key
#PowerKeyIgnoreInhibited=no
#SuspendKeyIgnoreInhibited=no
#HibernateKeyIgnoreInhibited=no
#LidSwitchIgnoreInhibited=yes
#RebootKeyIgnoreInhibited=no
#HoldoffTimeoutSec=30s
#IdleAction=ignore
#IdleActionSec=30min
#RuntimeDirectorySize=10%
#RuntimeDirectoryInodesMax=
#RemoveIPC=yes
#InhibitorsMax=8192
#SessionsMax=8192
#StopIdleSessionSec=infinity
#DesignatedMaintenanceTime=
#WallMessages=yes
EOF

    log_success "Configuration written successfully."
    log_info "Changes will have taken effect after you reboot the system."

else
    # User declined
    printf "Okay, I won't do it.\n"
fi

exit 0
