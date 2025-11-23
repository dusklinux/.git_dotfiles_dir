#!/bin/bash
#
# simple_terminator.sh
#
# A lightweight, non-interactive utility to terminate processes and stop services.
# Optimized for Arch Linux / Hyprland (run with sudo).
#

# --- ROOT CHECK ---
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[1;31mError: This script must be run as root (sudo).\033[0m"
    exit 1
fi

# --- DETECT REAL USER ---
# We need this to stop 'systemctl --user' services correctly while running as root.
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_UID=$(id -u "$SUDO_USER")
else
    echo "Warning: Script not run via sudo. Assuming current user is root (this may affect user services)."
    REAL_USER="root"
    REAL_UID=0
fi

# --- CONFIGURATION ---

# 1. Processes (Raw Binaries to pkill)
TARGET_PROCESSES=(
    "hyprsunset"
    "swww-daemon"
    "waybar"
)

# 2. System Services (Requires Root)
TARGET_SYSTEM_SERVICES=(
    "firewalld"
    "vsftpd"
    "waydroid-container"
    "logrotate.timer"
    "sshd"
)

# 3. User Services (Requires User Context)
TARGET_USER_SERVICES=(
    "battery_notify"
    "blueman-applet"
    "blueman-manager"
    "hypridle"
    "hyprpolkitagent"
    "swaync"
    "gvfs-daemon"
    "gvfs-metadata"
    "network_meter"
)

# --- FUNCTIONS ---

print_status() {
    local status="$1"
    local name="$2"
    if [ "$status" == "success" ]; then
        echo -e "[\033[1;32m OK \033[0m] Stopped: $name"
    elif [ "$status" == "skip" ]; then
        echo -e "[\033[1;30mSKIP\033[0m] Not running: $name"
    else
        echo -e "[\033[1;31mFAIL\033[0m] Could not stop: $name"
    fi
}

stop_process() {
    local name="$1"
    if pgrep -x "$name" &> /dev/null; then
        pkill -x "$name"
        # Quick wait to ensure it dies
        for _ in {1..10}; do
            if ! pgrep -x "$name" &> /dev/null; then
                print_status "success" "$name"
                return
            fi
            sleep 0.1
        done
        print_status "fail" "$name"
    else
        print_status "skip" "$name"
    fi
}

stop_system_service() {
    local name="$1"
    if systemctl is-active --quiet "$name"; then
        systemctl stop "$name"
        if ! systemctl is-active --quiet "$name"; then
            print_status "success" "$name"
        else
            print_status "fail" "$name"
        fi
    else
        print_status "skip" "$name"
    fi
}

stop_user_service() {
    local name="$1"
    # Check status as the real user
    if sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" systemctl --user is-active --quiet "$name"; then
        # Stop as the real user
        sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" systemctl --user stop "$name"
        
        # Verify stop
        if ! sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" systemctl --user is-active --quiet "$name"; then
            print_status "success" "$name"
        else
            print_status "fail" "$name"
        fi
    else
        print_status "skip" "$name"
    fi
}

# --- EXECUTION ---

echo "----------------------------------------"
echo " Performance Terminator (Mode: AUTO)    "
echo " User Context: $REAL_USER               "
echo "----------------------------------------"

echo -e "\n\033[1;34m:: Processes\033[0m"
for p in "${TARGET_PROCESSES[@]}"; do
    stop_process "$p"
done

echo -e "\n\033[1;34m:: System Services\033[0m"
for s in "${TARGET_SYSTEM_SERVICES[@]}"; do
    stop_system_service "$s"
done

echo -e "\n\033[1;34m:: User Services\033[0m"
for u in "${TARGET_USER_SERVICES[@]}"; do
    stop_user_service "$u"
done

echo -e "\n----------------------------------------"
echo "Cleanup Complete."
echo "----------------------------------------"
