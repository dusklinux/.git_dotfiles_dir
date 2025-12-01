#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# ARCH LINUX INSTALLER - PART 2: PARTITIONS & BASE SYSTEM
# Context: Arch ISO Environment (Root)
# -----------------------------------------------------------------------------

# --- Strict Mode ---
set -euo pipefail
IFS=$'\n\t'

# --- Formatting Constants ---
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_RED=$'\033[31m'
readonly C_GREEN=$'\033[32m'
readonly C_BLUE=$'\033[34m'
readonly C_YELLOW=$'\033[33m'

# --- Helper Functions ---
step_pause() {
    sleep 1
}

msg_info()    { step_pause; printf '%s[INFO]%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
msg_success() { printf '%s[SUCCESS]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
msg_warn()    { printf '%s[WARN]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
msg_error()   { printf '%s[ERROR]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# Clears any buffered "Enter" keystrokes so Pacman doesn't auto-select defaults
flush_input() {
    read -r -t 0.1 -n 10000 discard || true
}

prompt_confirm() {
    flush_input
    local choice
    read -rp ":: Proceed with this step? [Y/n] " choice
    case "${choice,,}" in
        n|no) msg_info "Step aborted by user."; exit 0 ;;
        *) return 0 ;;
    esac
}

cleanup() {
    local exit_code=$?
    if (( exit_code != 0 )); then
        msg_warn "Script failed. Unmounting /mnt to ensure clean state..."
        umount -R /mnt 2>/dev/null || true
    fi
    exit "$exit_code"
}
trap cleanup EXIT

# --- Hardware Detection ---
is_partition() { [[ -b "$1" ]] && [[ "$1" =~ [0-9]$|p[0-9]+$ ]]; }
is_ssd() {
    local parent
    parent=$(lsblk -no PKNAME "$1" | head -n1)
    local rot
    rot=$(cat "/sys/block/$parent/queue/rotational" 2>/dev/null || echo 1)
    (( rot == 0 ))
}

# --- Pre-flight Checks ---
check_kernel_modules() {
    msg_info "Verifying kernel modules..."
    if ! modprobe vfat &>/dev/null; then
        msg_error "Kernel module 'vfat' missing. Did you update the kernel (pacman -Syu)? Reboot ISO."
    fi
    modprobe btrfs &>/dev/null || true
}

# -----------------------------------------------------------------------------
# MAIN PROCESS
# -----------------------------------------------------------------------------

check_kernel_modules

clear
printf '%sArch Linux Installation - Storage Configuration%s\n' "$C_BOLD" "$C_RESET"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS

printf "\n%sREMINDER:%s Partition your drive with 'cfdisk' first.\n" "$C_YELLOW" "$C_RESET"
printf "  > %sBOOT/ESP:%s Recommended 512MB - 1GB\n" "$C_BOLD" "$C_RESET"
printf "  > %sROOT:%s     Recommended 10GB+\n\n" "$C_BOLD" "$C_RESET"

# Get ROOT
while true; do
    read -rp "Enter ROOT partition (10GB+ e.g., /dev/nvme1n1p3): " ROOT_PART
    [[ -z "$ROOT_PART" ]] && continue
    if is_partition "$ROOT_PART"; then break; else msg_warn "Invalid partition."; fi
done

# Get ESP
while true; do
    read -rp "Enter BOOT/ESP partition (512MB+ e.g., /dev/nvme1n1p2): " ESP_PART
    [[ -z "$ESP_PART" ]] && continue
    if [[ "$ESP_PART" == "$ROOT_PART" ]]; then msg_warn "BOOT cannot be same as ROOT."; continue; fi
    if is_partition "$ESP_PART"; then break; else msg_warn "Invalid partition."; fi
done

printf "\n%sTarget:%s ROOT=%s | BOOT=%s\n" "$C_BOLD" "$C_RESET" "$ROOT_PART" "$ESP_PART"
printf "%sWARNING: Partitions will be formatted.%s\n" "$C_RED" "$C_RESET"
prompt_confirm

# -----------------------------------------------------------------------------
# 8. FORMATTING
# -----------------------------------------------------------------------------
msg_info "Formatting EFI ($ESP_PART)..."
mkfs.fat -F 32 -n "EFI" "$ESP_PART"

msg_info "Formatting ROOT ($ROOT_PART)..."
mkfs.btrfs -f -L "ROOT" "$ROOT_PART"

msg_info "Waiting for kernel to register partitions..."
udevadm settle
lsblk -f "$ESP_PART" "$ROOT_PART"
prompt_confirm

# -----------------------------------------------------------------------------
# 9 & 10. SUBVOLUMES
# -----------------------------------------------------------------------------
msg_info "Creating Subvolumes..."
mount -t btrfs "$ROOT_PART" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount -R /mnt
msg_success "Subvolumes created."

# -----------------------------------------------------------------------------
# 11-14. MOUNTING
# -----------------------------------------------------------------------------
BTRFS_OPTS="rw,noatime,compress=zstd:3,space_cache=v2"
if is_ssd "$ROOT_PART"; then
    msg_info "SSD detected. Enabling optimizations."
    BTRFS_OPTS+=",ssd,discard=async"
fi

msg_info "Mounting ROOT (@)..."
mount -o "${BTRFS_OPTS},subvol=@" "$ROOT_PART" /mnt

msg_info "Creating dirs..."
mkdir -p /mnt/{home,boot}

msg_info "Mounting HOME (@home)..."
mount -o "${BTRFS_OPTS},subvol=@home" "$ROOT_PART" /mnt/home

msg_info "Mounting BOOT..."
mount -t vfat "$ESP_PART" /mnt/boot

findmnt -R /mnt
prompt_confirm

# -----------------------------------------------------------------------------
# 15. REFLECTOR (Fixed Validation)
# -----------------------------------------------------------------------------
msg_info "Updating Mirrorlist..."

while true; do
    read -rp "Enter country (default: India, 'list' for options): " COUNTRY_INPUT
    if [[ "${COUNTRY_INPUT,,}" == "list" ]]; then
        reflector --list-countries
        continue
    fi
    TARGET_COUNTRY="${COUNTRY_INPUT:-India}"
    
    msg_info "Fetching mirrors for $TARGET_COUNTRY (Timeout: 20s)..."
    
    # Download to temp file to verify first
    if reflector --protocol https --country "$TARGET_COUNTRY" --latest 10 --sort rate --download-timeout 20 --save /tmp/mirrorlist_check; then
        # Check if file has at least 5 lines (headers + at least 1 server)
        LINE_COUNT=$(wc -l < /tmp/mirrorlist_check)
        if [[ $LINE_COUNT -gt 5 ]]; then
            mv /tmp/mirrorlist_check /etc/pacman.d/mirrorlist
            msg_success "Mirrors updated successfully ($LINE_COUNT lines)."
            cat /etc/pacman.d/mirrorlist
            break
        else
            msg_warn "Reflector returned an empty or invalid list. Please try a different country."
        fi
    else
        msg_warn "Reflector failed to connect."
    fi
    
    read -rp ":: Try again? [Y/n] " retry
    [[ "${retry,,}" == "n" ]] && break
done
prompt_confirm

# -----------------------------------------------------------------------------
# 16. INSTALLATION (Fixed Interaction)
# -----------------------------------------------------------------------------
msg_info "Detecting Microcode..."
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo 2>/dev/null | awk '{print $3}')
UCODE_PKG=""

[[ "$CPU_VENDOR" == "GenuineIntel" ]] && UCODE_PKG="intel-ucode"
[[ "$CPU_VENDOR" == "AuthenticAMD" ]] && UCODE_PKG="amd-ucode"
printf "Detected: %s. Package: %s\n" "$CPU_VENDOR" "${UCODE_PKG:-None}"

PACKAGES=(
    base base-devel linux linux-headers linux-firmware
    neovim btrfs-progs dosfstools git
)
[[ -n "$UCODE_PKG" ]] && PACKAGES+=("$UCODE_PKG")

msg_info "Starting Pacstrap..."
printf "\n%sNOTE: If you see 'ERROR: file not found: /etc/vconsole.conf', ignore it. It is harmless.%s\n" "$C_YELLOW" "$C_RESET"
printf "When prompted for providers (e.g. iptables), type your choice and hit Enter.\n"

# CRITICAL FIX: flush input buffer so previous 'Enter' keypresses don't auto-select defaults
flush_input

pacstrap -K /mnt "${PACKAGES[@]}"

msg_success "Pacstrap complete."
prompt_confirm

# -----------------------------------------------------------------------------
# 17. FSTAB
# -----------------------------------------------------------------------------
msg_info "Generating Fstab..."
genfstab -U /mnt > /mnt/etc/fstab

cat /mnt/etc/fstab
msg_success "Partitions & Base Install Finished."
