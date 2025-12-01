#!/usr/bin/env bash
# ==============================================================================
# 01_pre_install_setup.sh
# Description: Arch Linux ISO Pre-configuration (Font, Cowspace, Neovim)
# Environment: Arch Linux ISO (Live) - Root User
# ==============================================================================

# --- Strict Mode ---
set -u
set -o pipefail
IFS=$'\n\t'

# --- Formatting & Feedback ---
BOLD=$(tput bold 2>/dev/null || true)
RESET=$(tput sgr0 2>/dev/null || true)
GREEN=$(tput setaf 2 2>/dev/null || true)
RED=$(tput setaf 1 2>/dev/null || true)
BLUE=$(tput setaf 4 2>/dev/null || true)
YELLOW=$(tput setaf 3 2>/dev/null || true)

msg_info() { printf "${BLUE}%s[INFO] %s${RESET}\n" "${BOLD}" "$1"; }
msg_ok()   { printf "${GREEN}%s[OK]   %s${RESET}\n" "${BOLD}" "$1"; }
msg_warn() { printf "${YELLOW}%s[WARN] %s${RESET}\n" "${BOLD}" "$1"; }
msg_err()  { printf "${RED}%s[ERR]  %s${RESET}\n" "${BOLD}" "$1" >&2; }

# --- Main Logic Function ---
run_setup_steps() {
    
    # 1. Set Console Font
    msg_info "Setting console font to latarcyrheb-sun32..."
    setfont latarcyrheb-sun32 || msg_warn "Could not set font. Continuing..."

    # 2. Battery Charge Threshold
    msg_info "Configuring battery charge thresholds..."
    BAT_DIR=$(find /sys/class/power_supply -maxdepth 1 -name "BAT*" -print -quit)
    if [[ -n "$BAT_DIR" ]]; then
        BAT_CTRL="$BAT_DIR/charge_control_end_threshold"
        if [[ -f "$BAT_CTRL" ]] && [[ -w "$BAT_CTRL" ]]; then
            BAT_NAME=$(basename "$BAT_DIR")
            printf "60" > "$BAT_CTRL"
            msg_ok "Battery charge limit set to 60%% on $BAT_NAME."
        else
            msg_warn "Battery found but threshold control not supported."
        fi
    else
        msg_warn "No battery detected (skipped)."
    fi

    # 3. Cowspace (RAM) Configuration
    msg_info "Configuring Live Environment Storage (Cowspace)..."
    TOTAL_RAM=$(free -h | awk '/^Mem:/ {print $2}')
    
    printf "   %sNOTE:%s Cowspace is the RAM allocated for the live OS filesystem.\n" "${BOLD}" "${RESET}"
    printf "   %sTotal System RAM Available: %s%s\n" "${BOLD}" "${GREEN}${TOTAL_RAM}" "${RESET}"

    # Default 2G
    DEFAULT_COW="2G"
    printf "${YELLOW}%sEnter desired Cowspace size (e.g., 4G, 2G) [Default: %s]: ${RESET}" "${BOLD}" "$DEFAULT_COW"
    read -r USER_COW || USER_COW=""
    TARGET_COW="${USER_COW:-$DEFAULT_COW}"

    if [[ ! "$TARGET_COW" =~ ^[0-9]+[GgMm]$ ]]; then
        msg_err "Invalid format '$TARGET_COW'. Use standard sizes like 2G or 4G."
        return 1
    fi

    msg_info "Resizing Cowspace to $TARGET_COW..."
    if mount -o remount,size="$TARGET_COW" /run/archiso/cowspace; then
        msg_ok "Cowspace resized."
        df -h /run/archiso/cowspace | awk 'NR==2 {print "   Verified Size: " $2}'
    else
        msg_err "Failed to resize cowspace. Check RAM availability."
        return 1
    fi

    # 4. Keyring & packages Install
    msg_info "Initializing Pacman keyring..."
    pacman-key --init
    pacman-key --populate archlinux
    msg_ok "Keyring populated."

    msg_info "Installing packages..."
    # Using --noconfirm since the script is automated and running as root
    pacman -Sy --needed neovim git curl --noconfirm
    msg_ok "Neovim installed."

    # 5. Timezone
    msg_info "Configuring System Time..."
    DEFAULT_TZ="Asia/Kolkata"
    printf "${YELLOW}%sSelect Timezone [Default: %s]: ${RESET}" "${BOLD}" "$DEFAULT_TZ"
    read -r USER_TZ || USER_TZ=""
    TARGET_TZ="${USER_TZ:-$DEFAULT_TZ}"

    msg_info "Setting timezone to: $TARGET_TZ"
    if ! timedatectl set-timezone "$TARGET_TZ"; then
        msg_err "Failed to set timezone. Check spelling."
        return 1
    fi

    msg_info "Enabling NTP..."
    timedatectl set-ntp true
    msg_ok "NTP enabled."

    # 6. List Drives
    msg_info "Listing block devices..."
    printf "\n"
    lsblk
    printf "\n"
    
    return 0
}

# --- Retry Loop ---
while true; do
    if run_setup_steps; then
        msg_ok "Pre-install setup complete."
        exit 0
    else
        # Capture exit code from the function
        EXIT_CODE=$? 
        msg_err "Script failed with exit code $EXIT_CODE."
        
        printf "\n${YELLOW}%sWould you like to retry the script? [Y/n] ${RESET}" "${BOLD}"
        read -r USER_RETRY || USER_RETRY=""
        
        USER_RETRY=${USER_RETRY:-Y}
        if [[ "$USER_RETRY" =~ ^[Yy]$ ]]; then
            msg_info "Retrying setup..."
            printf "\n----------------------------------------\n\n"
            continue
        else
            msg_err "Aborting."
            exit $EXIT_CODE
        fi
    fi
done
