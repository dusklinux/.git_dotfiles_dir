#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# MODULE: DISK PARTITIONING & MOUNTING (BIOS & UEFI SUPPORT)
# -----------------------------------------------------------------------------
set -euo pipefail
readonly C_BOLD=$'\033[1m' C_RED=$'\033[31m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_BLUE=$'\033[34m' C_RESET=$'\033[0m'

# --- Helpers ---
sanitize_dev() {
    local input="${1%/}"
    input="${input#/dev/}"
    echo "/dev/$input"
}

is_ssd() {
    local dev="$1"
    local parent
    parent=$(lsblk -no PKNAME "$dev" | head -n1)
    local rot
    rot=$(cat "/sys/block/$parent/queue/rotational" 2>/dev/null || echo 1)
    (( rot == 0 ))
}

# Check Boot Mode
if [[ -d /sys/firmware/efi/efivars ]]; then
    BOOT_MODE="UEFI"
else
    BOOT_MODE="BIOS"
fi

# --- Main Logic ---
umount -R /mnt 2>/dev/null || true

clear
echo -e "${C_BOLD}=== DISK SETUP (${C_BLUE}$BOOT_MODE Mode${C_RESET}${C_BOLD}) ===${C_RESET}"

# --- INSTRUCTIONS ---
echo -e "${C_YELLOW}>> PRE-REQ: Ensure partitions exist (run 'cfdisk').${C_RESET}"
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    echo -e "${C_YELLOW}   - 1x EFI Partition (Type: EFI System, ~512MB)${C_RESET}"
    echo -e "${C_YELLOW}   - 1x ROOT Partition (Type: Linux Filesystem)${C_RESET}"
else
    echo -e "${C_YELLOW}   - 1x BIOS Boot Partition (Type: BIOS Boot, 1MB) [Required for GPT]${C_RESET}"
    echo -e "${C_YELLOW}   - 1x ROOT Partition (Type: Linux Filesystem)${C_RESET}"
fi
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS

# 1. INPUTS
while true; do
    read -rp "Enter ROOT partition (e.g. nvme0n1p2): " raw_root
    ROOT_PART=$(sanitize_dev "$raw_root")
    if [[ -b "$ROOT_PART" ]]; then break; else echo "${C_YELLOW}Invalid device: $ROOT_PART${C_RESET}"; fi
done

ESP_PART=""
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    while true; do
        read -rp "Enter EFI partition (e.g. nvme0n1p1): " raw_esp
        ESP_PART=$(sanitize_dev "$raw_esp")
        [[ "$ESP_PART" == "$ROOT_PART" ]] && echo "EFI cannot be ROOT." && continue
        if [[ -b "$ESP_PART" ]]; then break; else echo "${C_YELLOW}Invalid device: $ESP_PART${C_RESET}"; fi
    done
    echo -e "\n${C_BOLD}Target:${C_RESET} ROOT=$ROOT_PART | EFI=$ESP_PART"
else
    echo -e "\n${C_BOLD}Target:${C_RESET} ROOT=$ROOT_PART | BOOT=Legacy (No mount needed)"
fi

# 2. MODE SELECTION
DO_FORMAT=false
echo -e "\n${C_RED}${C_BOLD}!!! WARNING !!!${C_RESET}"
read -r -p "Do you want to FORMAT these partitions? (Choosing 'n' mounts existing drives) [y/N]: " fmt_choice
if [[ "${fmt_choice,,}" =~ ^(y|yes)$ ]]; then
    DO_FORMAT=true
    echo -e "${C_RED}>> DATA WILL BE WIPED. <<${C_RESET}"
else
    echo -e "${C_GREEN}>> RESCUE MODE: Mounting existing system without formatting. <<${C_RESET}"
fi

# --- LOGIC UPDATE START ---
if [ "$DO_FORMAT" = true ]; then
    # Strict safety check for Formatting: Defaults to NO
    read -r -p ":: Proceed with FORMATTING? [y/N] " confirm
    [[ "${confirm,,}" != "y" ]] && exit 1
else
    # Convenience check for Mounting: Defaults to YES
    read -r -p ":: Proceed with MOUNTING? [Y/n] " confirm
    [[ "${confirm,,}" =~ ^(n|no)$ ]] && exit 1
fi
# --- LOGIC UPDATE END ---

# 3. EXECUTION
if [ "$DO_FORMAT" = true ]; then
    # --- FORMATTING ---
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        echo ">> Formatting EFI..."
        mkfs.fat -F 32 -n "EFI" "$ESP_PART"
    fi
    
    echo ">> Formatting ROOT (BTRFS)..."
    mkfs.btrfs -f -L "ROOT" "$ROOT_PART"
    
    echo ">> Creating Subvolumes..."
    mount -t btrfs "$ROOT_PART" /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    umount /mnt
else
    # --- RESCUE ---
    echo ">> Skipping Format. Checking filesystem..."
    if ! lsblk -f "$ROOT_PART" | grep -q "btrfs"; then
        echo "${C_RED}Error: Partition $ROOT_PART is not BTRFS.${C_RESET}"
        exit 1
    fi

    # Subvolume Validation
    echo ">> Verifying subvolume structure..."
    mount -t btrfs "$ROOT_PART" /mnt
    if [[ ! -d "/mnt/@" ]] || [[ ! -d "/mnt/@home" ]]; then
        echo "${C_RED}Error: Subvolumes @ or @home not found on $ROOT_PART.${C_RESET}"
        echo "${C_RED}Cannot proceed with standard Arch layout mount.${C_RESET}"
        umount /mnt
        exit 1
    fi
    umount /mnt
fi

# 4. MOUNTING
BTRFS_OPTS="rw,noatime,compress=zstd:3,space_cache=v2"
if is_ssd "$ROOT_PART"; then
    echo ">> SSD Detected. Adding optimizations."
    BTRFS_OPTS+=",ssd,discard=async"
fi

echo ">> Mounting ROOT (@)..."
mount -o "${BTRFS_OPTS},subvol=@" "$ROOT_PART" /mnt

echo ">> Preparing directories..."
mkdir -p /mnt/{home,boot}

echo ">> Mounting HOME (@home)..."
mount -o "${BTRFS_OPTS},subvol=@home" "$ROOT_PART" /mnt/home

if [[ "$BOOT_MODE" == "UEFI" ]]; then
    echo ">> Mounting EFI..."
    mount "$ESP_PART" /mnt/boot
fi

echo -e "${C_GREEN}Disks mounted successfully.${C_RESET}"
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    lsblk -f "$ROOT_PART" "$ESP_PART"
else
    lsblk -f "$ROOT_PART"
fi

echo -e "\n${C_BOLD}Next Steps:${C_RESET}"
echo "1. Run 'pacstrap' to install the base system."
echo "2. Run 'genfstab -U /mnt >> /mnt/etc/fstab' to save this layout."
