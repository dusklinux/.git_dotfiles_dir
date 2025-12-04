#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# MODULE: DISK PARTITIONING & MOUNTING
# -----------------------------------------------------------------------------
set -euo pipefail
readonly C_BOLD=$'\033[1m' C_RED=$'\033[31m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_RESET=$'\033[0m'

# --- Helpers ---
sanitize_dev() {
    local input="${1%/}" # remove trailing slash
    input="${input#/dev/}" # remove /dev/ prefix if typed
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

# --- Main Logic ---
clear
echo -e "${C_BOLD}=== DISK SETUP ===${C_RESET}"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS

# 1. INPUTS
while true; do
    read -rp "Enter ROOT partition (e.g. nvme0n1p3): " raw_root
    ROOT_PART=$(sanitize_dev "$raw_root")
    if [[ -b "$ROOT_PART" ]]; then break; else echo "${C_YELLOW}Invalid device: $ROOT_PART${C_RESET}"; fi
done

while true; do
    read -rp "Enter EFI partition (e.g. nvme0n1p1): " raw_esp
    ESP_PART=$(sanitize_dev "$raw_esp")
    [[ "$ESP_PART" == "$ROOT_PART" ]] && echo "EFI cannot be ROOT." && continue
    if [[ -b "$ESP_PART" ]]; then break; else echo "${C_YELLOW}Invalid device: $ESP_PART${C_RESET}"; fi
done

echo -e "\n${C_BOLD}Target:${C_RESET} ROOT=$ROOT_PART | EFI=$ESP_PART"

# 2. MODE SELECTION (Format vs Rescue)
DO_FORMAT=false
echo -e "\n${C_RED}${C_BOLD}!!! WARNING !!!${C_RESET}"
read -r -p "Do you want to FORMAT these partitions? (Choosing 'n' mounts existing drives) [y/N]: " fmt_choice
if [[ "${fmt_choice,,}" =~ ^(y|yes)$ ]]; then
    DO_FORMAT=true
    echo -e "${C_RED}>> DATA WILL BE WIPED. <<${C_RESET}"
else
    echo -e "${C_GREEN}>> RESCUE MODE: Mounting existing system without formatting. <<${C_RESET}"
fi

read -r -p ":: Proceed? [y/N] " confirm
[[ "${confirm,,}" != "y" ]] && exit 1

# 3. EXECUTION
if [ "$DO_FORMAT" = true ]; then
    # --- FORMATTING PATH ---
    echo ">> Formatting EFI..."
    mkfs.fat -F 32 -n "EFI" "$ESP_PART"
    
    echo ">> Formatting ROOT (BTRFS)..."
    mkfs.btrfs -f -L "ROOT" "$ROOT_PART"
    
    echo ">> Creating Subvolumes..."
    mount -t btrfs "$ROOT_PART" /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    umount /mnt
else
    # --- RESCUE PATH ---
    echo ">> Skipping Format. Checking filesystem..."
    if ! lsblk -f "$ROOT_PART" | grep -q "btrfs"; then
        echo "${C_RED}Error: Partition $ROOT_PART is not BTRFS. Cannot mount subvolumes.${C_RESET}"
        exit 1
    fi
fi

# 4. MOUNTING (Common Path)
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

echo ">> Mounting EFI..."
mount --mkdir "$ESP_PART" /mnt/boot

echo -e "${C_GREEN}Disks mounted successfully.${C_RESET}"
lsblk -f "$ROOT_PART" "$ESP_PART"
