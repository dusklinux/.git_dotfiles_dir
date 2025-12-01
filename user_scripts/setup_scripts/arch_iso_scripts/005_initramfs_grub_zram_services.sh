#!/usr/bin/env bash
# --------------------------------------------------------------------------
# Arch Linux Boot, GRUB, and System Configuration Script
# Context: Post-Chroot | Arch Linux ISO
# Author: Elite DevOps Engineer
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
# 1. Safety & Environment
# --------------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

# Check for root (effectively checks if we have permissions in chroot)
if (( EUID != 0 )); then
    printf '\033[0;31m[ERROR] This script must be run as root (or inside chroot).\033[0m\n' >&2
    exit 1
fi

# --------------------------------------------------------------------------
# 2. Visual Helpers
# --------------------------------------------------------------------------
# Check if terminal supports colors
if [[ -t 1 ]]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    NC=$'\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

log_info()    { printf '%s[INFO]%s %s\n' "$BLUE" "$NC" "$1"; }
log_success() { printf '%s[SUCCESS]%s %s\n' "$GREEN" "$NC" "$1"; }
log_warn()    { printf '%s[WARNING]%s %s\n' "$YELLOW" "$NC" "$1" >&2; }
log_error()   { printf '%s[ERROR]%s %s\n' "$RED" "$NC" "$1" >&2; }

# Cleanup function to handle exit signals
cleanup() {
    local exit_code=$?
    if (( exit_code != 0 )); then
        log_error "Script failed with exit code: $exit_code"
    fi
}
trap cleanup EXIT INT TERM

# --------------------------------------------------------------------------
# 3. Interactive Prompts
# --------------------------------------------------------------------------
confirm_step() {
    local step_name="$1"
    local choice=""
    
    printf '\n%s------------------------------------------------%s\n' "$YELLOW" "$NC"
    printf '%sStep: %s%s\n' "$YELLOW" "$step_name" "$NC"
    
    read -rp "Do you want to proceed with this step? (y/n): " choice
    if [[ ! "${choice,,}" =~ ^y ]]; then
        log_info "Skipping $step_name..."
        return 1
    fi
    return 0
}

# --------------------------------------------------------------------------
# 4. Main Execution Logic
# --------------------------------------------------------------------------

# --- Step 28: Generating Initramfs ---
if confirm_step "Generate Initramfs (mkinitcpio)"; then
    log_info "Regenerating initramfs presets..."
    mkinitcpio -P
    log_success "Initramfs generation complete."
fi

# --- Step 29: Installing Grub Packages ---
if confirm_step "Install GRUB and Boot Tools"; then
    log_info "Installing GRUB, efibootmgr, grub-btrfs, and os-prober..."
    # --needed ensures we don't reinstall if already up to date
    pacman -S --needed --noconfirm grub efibootmgr grub-btrfs os-prober
    log_success "Packages installed."
fi

# --- Step 30: Configure GRUB ---
if confirm_step "Configure /etc/default/grub"; then
    GRUB_FILE="/etc/default/grub"
    
    if [[ ! -f "$GRUB_FILE" ]]; then
        log_error "$GRUB_FILE not found. Is GRUB installed?"
        exit 1
    fi

    # Logic for pcie_aspm=force flag
    log_warn "Configuration Check: ASPM Power Saving"
    printf '%s\n' "The 'pcie_aspm=force' flag reduces power usage (~7W) and heat."
    printf '%s\n' "However, it may cause instability on some hardware."
    
    local aspm_choice=""
    read -rp "Do you want to enable 'pcie_aspm=force'? (y/n): " aspm_choice

    # Construct the kernel parameters string
    local cmdline_params="loglevel=3 zswap.enabled=0 rootfstype=btrfs fsck.mode=skip"
    
    if [[ "${aspm_choice,,}" =~ ^y ]]; then
        cmdline_params="$cmdline_params pcie_aspm=force"
        log_info "Adding ASPM force flag."
    else
        log_info "Skipping ASPM force flag."
    fi

    log_info "Applying GRUB configuration..."
    
    # Robust sed replacement handling commented or uncommented lines
    # 1. Update CMDLINE default
    sed -i "s|^#\?GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$cmdline_params\"|" "$GRUB_FILE"
    
    # 2. Enable OS Prober (Change false to false and uncomment)
    sed -i 's|^#\?GRUB_DISABLE_OS_PROBER=.*|GRUB_DISABLE_OS_PROBER=false|' "$GRUB_FILE"
    
    # 3. Set Timeout to 1
    sed -i 's|^#\?GRUB_TIMEOUT=.*|GRUB_TIMEOUT=1|' "$GRUB_FILE"

    log_success "GRUB config updated (no backup files created)."
fi

# --- Step 31: Installing GRUB to EFI ---
if confirm_step "Install GRUB to ESP (/boot)"; then
    # Verify we are actually in a UEFI environment
    if [[ ! -d /sys/firmware/efi ]]; then
        log_warn "No EFI variables found at /sys/firmware/efi."
        log_warn "If you are in a chroot, ensure /sys is mounted."
        read -rp "Proceed anyway? (y/n): " force_efi
        [[ "${force_efi,,}" =~ ^y ]] || exit 1
    fi

    log_info "Installing GRUB bootloader..."
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
    log_success "GRUB installed to /boot."
fi

# --- Step 32: Generate GRUB Config File ---
if confirm_step "Generate grub.cfg"; then
    # Ensure dir exists
    mkdir -p /boot/grub
    
    log_info "Generating final GRUB configuration file..."
    grub-mkconfig -o /boot/grub/grub.cfg
    log_success "grub.cfg generated."
fi

# --- Step 33: ZRAM Configuration ---
if confirm_step "Configure ZRAM (zram-generator)"; then
    log_info "Calculating RAM for ZRAM sizing..."
    
    # Get Total RAM in kB
    local total_mem_kb
    total_mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    
    # Convert to MB
    local total_mem_mb=$((total_mem_kb / 1024))
    local zram_size_val=""
    
    # 8GB = 8192 MB. Using rigorous math.
    if (( total_mem_mb < 8192 )); then
        log_info "RAM is < 8GB ($total_mem_mb MB). Setting zram-size = ram."
        zram_size_val="ram"
    else
        log_info "RAM is >= 8GB ($total_mem_mb MB). Setting zram-size = ram - 2000."
        zram_size_val="ram - 2000"
    fi

    mkdir -p /mnt/zram1
    
    log_info "Writing /etc/systemd/zram-generator.conf..."
    cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = $zram_size_val
compression-algorithm = zstd

[zram1]
zram-size = $zram_size_val
fs-type = ext2
mount-point = /mnt/zram1
compression-algorithm = zstd
options = rw,nosuid,nodev,discard,X-mount.mode=1777
EOF

    log_success "ZRAM configuration created."
fi

# --- Step 34: System Services ---
if confirm_step "Enable System Services"; then
    log_info "Enabling system services..."
    
    # Array of services to enable
    # Included .service extension explicitly for clarity and robustness
    local services=(
        "NetworkManager.service"
        "tlp.service"
        "udisks2.service"
        "thermald.service"
        "bluetooth.service"
        "firewalld.service"
        "fstrim.timer"
        "systemd-timesyncd.service"
        "acpid.service"
        "vsftpd.service"
        "reflector.timer"
        "swayosd-libinput-backend.service"
        "systemd-resolved.service"
    )

    local success_count=0
    local fail_count=0

    # Iterate loop to prevent script exit if one service fails (Robustness)
    for service in "${services[@]}"; do
        # Check if unit exists to avoid noisy errors
        if systemctl list-unit-files "$service" &>/dev/null; then
            if systemctl enable "$service" &>/dev/null; then
                log_info "Enabled: $service"
                ((success_count++))
            else
                log_warn "Failed to enable: $service"
                ((fail_count++))
            fi
        else
            log_warn "Skipping missing unit: $service"
        fi
    done
    
    log_success "Service setup finished. Enabled: $success_count, Failed/Skipped: $fail_count."
fi

# --------------------------------------------------------------------------
# 5. Completion & Instructions
# --------------------------------------------------------------------------
printf '\n%s================================================%s\n' "$GREEN" "$NC"
printf '%s   CONFIGURATION SCRIPT FINISHED SUCCESSFULLY   %s\n' "$GREEN" "$NC"
printf '%s================================================%s\n\n' "$GREEN" "$NC"

printf "The automated setup for this section is complete.\n"
printf "Please perform the following final manual steps to exit cleanly:\n"

printf '\n%s1. Exit the chroot environment:%s\n' "$YELLOW" "$NC"
printf '   $ exit\n'

printf '\n%s2. Unmount all partitions recursively:%s\n' "$YELLOW" "$NC"
printf '   $ umount -R /mnt\n'

printf '\n%s3. Power off the machine:%s\n' "$YELLOW" "$NC"
printf '   $ poweroff\n'

echo ""
