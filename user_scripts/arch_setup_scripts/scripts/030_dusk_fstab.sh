#!/usr/bin/env bash
# Appends entries to /etc/fstab (personal, only for dusk)
# -----------------------------------------------------------------------------
# Script: 032_fstab_append_asus_v3.sh
# Description: Conditionally appends entries to /etc/fstab.
#              - User Confirmation Driven (No strict hardware enforcement)
#              - Atomic Write & Verify Strategy
#              - Auto-Rollback on failure (Leaves no trace/backups on success)
# Author: Elite DevOps (Arch/Hyprland)
# -----------------------------------------------------------------------------

# 1. Strict Safety
set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION AREA
# -----------------------------------------------------------------------------
IFS= read -r -d '' FSTAB_CONTENT <<'EOF' || true

#XXXXXXXXXXXXXXXXXXXXXXXX--HARD DISKS BTRFS & NTFS--XXXXXXXXXXXXXXXXXXXXXXXXX

#External Machanacial Hard Disk - BTRFS (WD Passport)

#UUID=bb5a5a44-4b30-4db2-822f-ceab3171ee51	/mnt/fast	btrfs		defaults,discard=async,comment=x-gvfs-show,compress=zstd:3,noatime,space_cache=v2,nofail,noauto,autodefrag,subvol=/	0 0

#External Machanacial Hard Disk - NTFS (WD Passport)

#UUID=319E44F71F4E3E14	/mnt/slow	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0


# WD ntfs passport fast
UUID=70EED6A1EED65F42	/mnt/fast	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0


#External Machanacial Hard Disk - BTRFS (WD Passport) (no copy on write also disables compression zstd but improves speed of the drive)

UUID=5A921A119219F26D	/mnt/slow	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0



#External Machanacial Hard Disk - BTRFS (OLD WD BOOK)

UUID=46798d3b-cda7-4031-818f-37a06abbeb37	/mnt/wdfast	btrfs		defaults,discard=async,comment=x-gvfs-show,compress=zstd:3,noatime,space_cache=v2,nofail,noauto,autodefrag,subvol=/	0 0


#External Machanacial Hard Disk - btrfs (OLD WD BOOK)

UUID=2765359f-232e-4165-bc69-ef402b50c74c	/mnt/wdslow	btrfs		defaults,discard=async,comment=x-gvfs-show,compress=zstd:3,noatime,space_cache=v2,nofail,noauto,autodefrag,subvol=/	0 0


#External Machanacial Hard Disk - NTFS (Enclosure)

UUID=5A428B8A428B6A19	/mnt/enclosure	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX



#XXXXXXXXXXXXXXXXXXXXXXXX--SSDs BTRFS & NTFS--XXXXXXXXXXXXXXXXXXXXXXXXX

#SSD NTFS (Windows)

UUID=848A215E8A214E4C	/mnt/windows	ntfs3	defaults,noatime,uid=1000,gid=1000,umask=002,windows_names,noauto,nofail,comment=x-gvfs-show 0 0


#SSD BTRFS with Copy_on_Write Disabled which also disabled Compression (Browser)

UUID=1adeb61a-0605-4bbc-8178-bb81fe1fca09	/mnt/browser	btrfs		defaults,nodatacow,ssd,discard=async,comment=x-gvfs-show,noatime,space_cache=v2,nofail,noauto,subvol=/	0 0


#SSD NTFS (Media)

UUID=9C38076638073F30	/mnt/media	ntfs3	defaults,noatime,uid=1000,gid=1000,umask=002,windows_names,noauto,nofail,comment=x-gvfs-show 0 0


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


#Disk Swap

#UUID=6087d4bf-bd82-4c40-9197-3f5450b72241	none	swap	defaults 0 0

#Ramdisk (don't use this, use zram1 instead)

#tmpfs /mnt/ramdisk tmpfs rw,noatime,exec,size=2G,uid=1000,gid=1000,mode=0755,comment=x-gvfs-show 0 0
EOF
readonly FSTAB_CONTENT

# 2. Internal Constants
readonly TARGET_FILE="/etc/fstab"
readonly MARKER_START="# === ARCH ORCHESTRA: DUSK PERSONAL MOUNTS [START] ==="
readonly MARKER_END="# === ARCH ORCHESTRA: DUSK PERSONAL MOUNTS [END] ==="

# 3. Aesthetics
readonly C_RESET=$'\033[0m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_YELLOW=$'\033[1;33m'
readonly C_RED=$'\033[1;31m'
readonly C_BOLD=$'\033[1m'

log_info()    { printf "%s[INFO]%s %s\n" "$C_BLUE" "$C_RESET" "$1"; }
log_success() { printf "%s[OK]%s %s\n" "$C_GREEN" "$C_RESET" "$1"; }
log_warn()    { printf "%s[WARN]%s %s\n" "$C_YELLOW" "$C_RESET" "$1" >&2; }
log_error()   { printf "%s[ERROR]%s %s\n" "$C_RED" "$C_RESET" "$1" >&2; }

# 4. Root Privilege Check
if [[ $EUID -ne 0 ]]; then
    log_info "Root privileges required. Elevating..."
    script_path=$(readlink -f "$0")
    exec sudo "$script_path" "$@"
fi

# 5. User Identity Confirmation
confirm_target_machine() {
    local sys_vendor="Unknown"
    local sys_product="Unknown"

    # Informational Hardware Check (Does not enforce logic)
    [[ -r /sys/class/dmi/id/sys_vendor ]] && sys_vendor=$(< /sys/class/dmi/id/sys_vendor)
    [[ -r /sys/class/dmi/id/product_name ]] && sys_product=$(< /sys/class/dmi/id/product_name)

    # Cleanup whitespace
    sys_vendor="${sys_vendor//[[:space:]]/}"
    sys_product="${sys_product//[[:space:]]/}"

    printf "\n"
    log_info "System identifies as: ${C_BOLD}${sys_vendor} ${sys_product}${C_RESET}"
    
    # Explicit User Question
    printf "\n"
    log_warn "This script is configured for: ${C_BOLD}Dusk's Personal ASUS Laptop${C_RESET}"
    log_warn "It will modify /etc/fstab."
    
    # Force read from TTY to handle piping
    local response
    if ! read -r -p "Is this the correct target machine? [y/N] " response < /dev/tty; then
         log_error "Could not read user input."
         exit 1
    fi

    if [[ ! "$response" =~ ^[yY]$ ]]; then
        log_info "User selected NO. Exiting cleanly."
        exit 0
    fi
}

# 6. Main Logic
main() {
    confirm_target_machine

    # A. Pre-flight Checks
    if [[ ! -f "$TARGET_FILE" ]]; then
        log_error "Critical: $TARGET_FILE not found."
        exit 1
    fi

    if [[ -z "${FSTAB_CONTENT//[[:space:]]/}" ]]; then
        log_warn "No content provided in script configuration. Nothing to append."
        exit 0
    fi

    # Idempotency: Check if markers exist
    if grep -Fq "$MARKER_START" "$TARGET_FILE"; then
        log_success "Custom mounts already present in fstab. Skipping."
        exit 0
    fi

    # B. Ephemeral Backup Strategy
    local temp_backup
    temp_backup=$(mktemp)
    cp "$TARGET_FILE" "$temp_backup"
    
    log_info "Applying changes..."

    # Ensure newline at end of file
    if [[ -s "$TARGET_FILE" && -n "$(tail -c1 "$TARGET_FILE")" ]]; then
        printf "\n" >> "$TARGET_FILE"
    fi

    # Append Content
    {
        printf "%s\n" "$MARKER_START"
        printf "%s\n" "$FSTAB_CONTENT"
        printf "%s\n" "$MARKER_END"
    } >> "$TARGET_FILE"

    # C. Verification & Rollback
    log_info "Verifying syntax..."
    
    if mount --fake --all --verbose >/dev/null 2>&1; then
        log_success "Syntax check passed."
        
        # SUCCESS: Remove the temp backup (Clean execution)
        rm -f "$temp_backup"
        
        log_info "Reloading systemd..."
        systemctl daemon-reload
        log_success "Done."
    else
        log_error "SYNTAX CHECK FAILED. Rolling back changes..."
        
        # FAILURE: Restore from temp backup
        cat "$temp_backup" > "$TARGET_FILE"
        rm -f "$temp_backup"
        
        log_error "Changes reverted. /etc/fstab is untouched."
        exit 1
    fi
}

main
