#!/bin/bash

# --- GRUB Recovery and Configuration Script ---
# Version: 1.4 (Add config options: timeout, verbose, menu visibility)
# Author: Gemini AI (with input from user request)
# Date: 2025-04-24
#
# Purpose: Automate GRUB reinstallation and configuration for multi-boot systems.
#          Compatible with Debian/Ubuntu derivatives and Fedora.
# Features:
#   - Detects UEFI/BIOS mode.
#   - Attempts to auto-detect GRUB installation target (ESP or MBR disk).
#   - Allows manual selection of targets.
#   - Handles chrooting into an installed system (useful from Live USB).
#   - Detects and uses appropriate grub/grub2 commands.
#   - Reinstalls GRUB (using --force for grub2-install on UEFI).
#   - Optionally modifies /etc/default/grub settings (timeout, verbose boot, menu style).
#   - Enables os-prober to detect other OSes.
#   - Updates GRUB configuration using detected paths (/boot/grub or /boot/grub2).
#   - Creates backups of configuration files.
#   - Logs all actions to a file.
#   - Optional interactive dialog interface.
#   - Dry-run mode.

Command-Line Options:

#   --set-timeout <seconds>: Sets the GRUB_TIMEOUT.
#   --enable-verbose: Removes quiet splash from GRUB_CMDLINE_LINUX_DEFAULT.
#   --disable-verbose: Ensures quiet splash are present in GRUB_CMDLINE_LINUX_DEFAULT.
#   --show-menu: Sets GRUB_TIMEOUT_STYLE=menu.
#   --hide-menu: Sets GRUB_TIMEOUT_STYLE=hidden

# --- Configuration ---
SCRIPT_NAME=$(basename "$0")
LOG_DIR="/var/log"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="/tmp/grub_backups_$(date +%Y%m%d_%H%M%S)"
USE_DIALOG=false # Set to true to try using dialog boxes if available
DRY_RUN=false
AUTO_YES=false

# --- Global Variables for Detected Commands ---
GRUB_INSTALL_CMD=""
GRUB_MKCONFIG_CMD=""
GRUB_PROBE_CMD="" # For potential future use, usually os-prober

# --- Global Variables for /etc/default/grub Modifications ---
SET_GRUB_TIMEOUT="" # Stores the desired timeout value
SET_GRUB_VERBOSE="" # "true" or "false"
SET_GRUB_MENU_STYLE="" # "menu", "hidden", "countdown"

# --- Helper Functions ---

# Logging
log_message() {
    local level="$1"
    local message="$2"
    # Log to file and also print to stderr to avoid interfering with stdout/pipe/tee issues
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$LOG_FILE" >&2
}

# Error Handling
handle_error() {
    local lineno="$1"
    local message="$2"
    local code="${3:-1}"
    log_message "ERROR" "Error on line ${lineno}: ${message}"
    # Optionally attempt cleanup here if needed (e.g., umount)
    cleanup_mounts # Attempt cleanup on error
    exit "$code"
}

trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR # Basic error trapping

# Check for root privileges
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        log_message "ERROR" "This script must be run as root. Please use sudo."
        exit 1
    fi
    log_message "INFO" "Root privileges verified."
}

# Check for required commands and determine GRUB command variants
check_dependencies() {
    local missing_deps=()
    local core_utils=("lsblk" "blkid" "mount" "umount" "parted" "findmnt" "grep" "awk" "tee" "mkdir" "cp" "sync" "chroot" "sed") # Added sed
    local grub_deps_found=false

    log_message "INFO" "Checking for GRUB command variants..."
    if command -v grub2-install &> /dev/null && command -v grub2-mkconfig &> /dev/null; then
        log_message "INFO" "Found grub2 commands (Fedora/RHEL style)."
        GRUB_INSTALL_CMD="grub2-install"
        GRUB_MKCONFIG_CMD="grub2-mkconfig"
        grub_deps_found=true
    elif command -v grub-install &> /dev/null && command -v grub-mkconfig &> /dev/null; then
        log_message "INFO" "Found grub commands (Debian/Ubuntu style)."
        GRUB_INSTALL_CMD="grub-install"
        GRUB_MKCONFIG_CMD="grub-mkconfig"
        grub_deps_found=true
    else
        missing_deps+=("grub(2)-install" "grub(2)-mkconfig")
    fi

    # Check for os-prober (optional but recommended for multi-boot)
    if command -v os-prober &> /dev/null; then
        GRUB_PROBE_CMD="os-prober"
    else
        log_message "WARN" "os-prober not found. Detection of other operating systems will be skipped."
        # Don't add to missing_deps as it's optional
    fi

    # Check core utilities
    log_message "INFO" "Checking for core utility dependencies..."
    for cmd in "${core_utils[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ "$USE_DIALOG" == "true" ]]; then
        if ! command -v dialog &> /dev/null; then
             missing_deps+=("dialog")
        fi
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_message "ERROR" "Missing required commands: ${missing_deps[*]}. Please install them."
        echo "Error: Missing required commands: ${missing_deps[*]}. Please install them." >&2
        echo "Example installation commands:" >&2
        echo "  Debian/Ubuntu: sudo apt update && sudo apt install grub-efi-amd64-bin grub-pc-bin os-prober util-linux parted coreutils sed [dialog]" >&2
        echo "  Fedora:        sudo dnf install grub2-efi-x64 grub2-pc grub2-tools os-prober util-linux-user parted coreutils sed [dialog]" >&2
        exit 1
    fi
    log_message "INFO" "All required dependencies found."
}

# User Confirmation Prompt
confirm() {
    if [[ "$AUTO_YES" == "true" ]]; then
        log_message "INFO" "Auto-confirming action due to --yes flag: $1"
        return 0 # Simulate yes
    fi

    local prompt_message="$1"
    local response
    while true; do
        # Prompt explicitly to stderr, read from stdin (terminal)
        echo -n "$prompt_message [y/N]: " > /dev/tty
        read -r response < /dev/tty
        case "$response" in
            [yY][eE][sS]|[yY])
                log_message "INFO" "User confirmed action: $1"
                return 0 # Yes
                ;;
            [nN][oO]|[nN]|"") # Default to No
                log_message "WARN" "User declined action: $1"
                return 1 # No
                ;;
            *)
                echo "Please answer yes or no." > /dev/tty
                ;;
        esac
    done
}

# Dialog Wrapper functions
show_message() { # Title Text
    if [[ "$USE_DIALOG" == "true" ]] && command -v dialog &> /dev/null; then
        dialog --title "$1" --msgbox "$2" 10 60 2>/dev/tty
    else
        # Output directly to terminal
        echo -e "\n--- $1 ---\n$2\n" > /dev/tty
    fi
}

show_menu() { # Title MenuText Item1 Desc1 Item2 Desc2 ... -> Returns selected Item
    local title="$1"
    local menu_text="$2"
    shift 2
    if [[ "$USE_DIALOG" == "true" ]] && command -v dialog &> /dev/null; then
        # Dialog sends output to stderr, redirect it to capture, send prompts to tty
        dialog --clear --title "$title" --menu "$menu_text" 20 70 15 "$@" 2>&1 >/dev/tty || echo "CANCEL"
    else
        # --- Text-based Menu ---
        # Explicitly print prompts and menu to /dev/tty (the controlling terminal)
        # This avoids issues if stdout is redirected (e.g., by logging)
        echo -e "\n--- $title ---\n$menu_text\n" > /dev/tty
        local i=1
        local options=()
        local menu_items=("$@") # Copy args to avoid issues with shift modifying $@ during loop for options array
        while [[ $# -gt 0 ]]; do
            options+=("$1") # Store the internal value (e.g., "Yes_Confirm")
            # Print the menu item to the terminal
            echo "$i) $2" > /dev/tty # Show description ($2) to user
            shift 2 # Shift by 2 to get the next item/description pair
            i=$((i + 1))
        done
        echo "0) Cancel" > /dev/tty

        local choice
        while true; do
            # Prompt explicitly to terminal, read from terminal
            echo -n "Enter your choice [1-${#options[@]}, 0 to Cancel]: " > /dev/tty
            read -r choice < /dev/tty
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 && "$choice" -le ${#options[@]} ]]; then
                # Return the internal value corresponding to the choice
                # Need to get the Item ($1) based on the index ($choice-1)*2 from the original menu_items array
                local selected_item_index=$(( (choice - 1) * 2 ))
                echo "${menu_items[$selected_item_index]}"
                return 0
            elif [[ "$choice" == "0" ]]; then
                echo "CANCEL"
                return 1
            else
                echo "Invalid choice. Please try again." > /dev/tty
            fi
        done
    fi
}


show_input() { # Title Prompt Default -> Returns input
    local title="$1"
    local prompt_text="$2"
    local default_value="${3:-}"
    if [[ "$USE_DIALOG" == "true" ]] && command -v dialog &> /dev/null; then
        # Dialog sends output to stderr, redirect it to capture, send prompts to tty
        dialog --clear --title "$title" --inputbox "$prompt_text" 10 60 "$default_value" 2>&1 >/dev/tty || echo "CANCEL"
    else
        # Explicitly prompt and read from /dev/tty
        echo -e "\n--- $title ---\n$prompt_text" > /dev/tty
        echo -n "[Default: $default_value]: " > /dev/tty
        read -r input < /dev/tty
        if [[ -z "$input" ]]; then
            echo "$default_value"
        else
            echo "$input"
        fi
    fi
}

# --- Core Logic Functions ---

detect_boot_mode() {
    log_message "INFO" "Detecting system boot mode..."
    if [[ -d "/sys/firmware/efi/efivars" ]]; then
        log_message "INFO" "UEFI boot mode detected."
        echo "UEFI"
    else
        log_message "INFO" "Legacy BIOS boot mode detected."
        echo "BIOS"
    fi
}

find_esp_partition() {
    # (Function logic remains the same as before)
    log_message "INFO" "Attempting to find EFI System Partition (ESP)..."
    local esp_device
    # Try finding mounted /boot/efi first (common in chroot or Fedora)
    esp_device=$(findmnt -n -o SOURCE /boot/efi 2>/dev/null)
    if [[ -n "$esp_device" ]]; then
         log_message "INFO" "Found likely ESP via mounted /boot/efi: $esp_device"
         echo "$esp_device"
         return 0
    fi
    # Try finding mounted /efi first (less common)
    esp_device=$(findmnt -n -o SOURCE /efi 2>/dev/null)
    if [[ -n "$esp_device" ]]; then
         log_message "INFO" "Found likely ESP via mounted /efi: $esp_device"
         echo "$esp_device"
         return 0
    fi

    # Look for partitions with ESP type GUID or boot/esp flags
    # Using lsblk first as it's often more reliable for PARTTYPE
     esp_device=$(lsblk -o NAME,PARTTYPE,FSTYPE,SIZE,MOUNTPOINT -p -n | awk '$2 == "C12A7328-F81F-11D2-BA4B-00A0C93EC93B" {print $1}') # EFI System partition GUID
    if [[ -n "$esp_device" ]]; then
        log_message "INFO" "Found likely ESP via partition type GUID: $esp_device"
        echo "$esp_device"
        return 0
    fi

    # Fallback using parted for flags (might be less reliable parsing)
    local disk_list=$(lsblk -d -n -o NAME -p)
    for disk in $disk_list; do
       # Skip loop devices
       if [[ "$disk" == /dev/loop* ]]; then continue; fi
       local parted_output
       # Handle potential parted error messages gracefully
       parted_output=$(parted -s "$disk" print 2>/dev/null | grep -E '^[[:space:]]*[0-9]+' | grep -E '\s+(boot|esp)\s*,' | awk '/ fat32|vfat / {print $1}')
       if [[ -n "$parted_output" ]]; then
           local part_num=$(echo "$parted_output" | head -n 1) # Take the first match on the disk
           # Construct full path (handles nvme/sdX naming)
           if [[ "$disk" == *nvme* && ! "$disk" =~ p[0-9]+$ ]]; then # e.g. /dev/nvme0n1
               esp_device="${disk}p${part_num}"
           elif [[ "$disk" =~ ^/dev/[a-z]+$ ]]; then # e.g. /dev/sda
               esp_device="${disk}${part_num}"
           else # Already a partition? Or unexpected format. Use as is.
               esp_device="${disk}" # Less likely, but fallback
               log_message "WARN" "Unexpected disk format for parted flag detection: $disk. Trying with partition number $part_num directly."
               # Attempt to construct path if it looks like a base disk name
               if [[ "$disk" =~ ^/dev/[a-z]+$ ]]; then esp_device="${disk}${part_num}"; fi
           fi
           log_message "INFO" "Found likely ESP via parted flags on $disk: $esp_device"
           echo "$esp_device"
           return 0
        fi
    done

    log_message "WARN" "Could not automatically detect ESP partition."
    echo "" # Return empty if not found
}

find_boot_disk_bios() {
    # (Function logic remains the same as before)
    log_message "INFO" "Attempting to find primary boot disk for BIOS install..."
    # Heuristic: Often the first non-removable disk listed by lsblk
    local boot_disk
    boot_disk=$(lsblk -d -n -o NAME,ROTA,RM,TYPE -p | awk '$2 == "0" && $3 == "0" && $4 == "disk" {print $1}' | head -n 1) # Non-rotating, non-removable disk
    if [[ -z "$boot_disk" ]]; then
        # Fallback: just the first disk
         boot_disk=$(lsblk -d -n -o NAME,TYPE -p | awk '$2 == "disk" {print $1}' | head -n 1)
    fi

    if [[ -n "$boot_disk" ]]; then
        log_message "INFO" "Found likely BIOS boot disk: $boot_disk"
        echo "$boot_disk"
    else
        log_message "WARN" "Could not automatically detect BIOS boot disk."
        echo ""
    fi
}

select_partition_dialog() { # Type (e.g., ESP, root)
    # (Function logic remains the same, relies on show_menu which is now fixed)
    local type="$1"
    local options=()
    # Use -b to get bytes for easier sorting if needed, SIZE is human readable
    # List partitions only
    local device_list=$(lsblk -o NAME,SIZE,FSTYPE,TYPE,LABEL,MOUNTPOINT -p -n -l | grep 'part')
    local count=0

    while IFS= read -r line; do
        local name=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}')
        local fstype=$(echo "$line" | awk '{print $3}')
        # type is already filtered to 'part'
        local label=$(echo "$line" | awk '{print $5}')
        local mountpoint=$(echo "$line" | awk '{print $6}')

        count=$((count + 1))
        # Use name as the internal value, description for the user
        local desc="$size ${fstype:-no_fs} ${label:-\<no_label\>} ${mountpoint:-\<not_mounted\>}"
        options+=("$name" "$desc") # Item first, Description second for show_menu
    done <<< "$device_list"

    if [[ $count -eq 0 ]]; then
        show_message "Error" "No partitions found. Cannot proceed."
        return 1
    fi

    local choice
    choice=$(show_menu "Select $type Partition" "Choose the partition to use as $type:" "${options[@]}")

    if [[ "$choice" == "CANCEL" || -z "$choice" ]]; then
        log_message "WARN" "User cancelled $type partition selection."
        return 1
    fi

    log_message "INFO" "User selected $type partition: $choice"
    echo "$choice" # Returns the selected partition name (e.g., /dev/sda1)
}

select_disk_dialog() {
    # (Function logic remains the same, relies on show_menu which is now fixed)
    local options=()
    local device_list=$(lsblk -o NAME,SIZE,ROTA,RM,TYPE,MODEL -d -p -n -l) # List only disks (-d)
    local count=0

    while IFS= read -r line; do
        local name=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}')
        local rota=$(echo "$line" | awk '{print $3}') # Rotating?
        local rm=$(echo "$line" | awk '{print $4}')   # Removable?
        local type=$(echo "$line" | awk '{print $5}') # Type (disk)
        local model=$(echo "$line" | awk '{$1=$2=$3=$4=$5=""; print $0}' | sed 's/^[ \t]*//') # Get the rest as model

        if [[ "$type" == "disk" ]]; then
            count=$((count + 1))
            local rota_str="SSD/NVMe"; [[ "$rota" == "1" ]] && rota_str="HDD"
            local rm_str="Fixed"; [[ "$rm" == "1" ]] && rm_str="Removable"
            local desc="$size $rota_str $rm_str ${model:-\<no_model\>}"
            options+=("$name" "$desc") # Item first, Description second
        fi
    done <<< "$device_list"

     if [[ $count -eq 0 ]]; then
        show_message "Error" "No disks found. Cannot proceed."
        return 1
    fi

    local choice
    choice=$(show_menu "Select Boot Disk (for BIOS MBR)" "Choose the disk to install GRUB MBR on:" "${options[@]}")

    if [[ "$choice" == "CANCEL" || -z "$choice" ]]; then
        log_message "WARN" "User cancelled boot disk selection."
        return 1
    fi

    log_message "INFO" "User selected boot disk: $choice"
    echo "$choice" # Returns the selected disk name (e.g., /dev/sda)
}

# --- Chroot Environment Setup ---
MOUNT_POINTS=() # Array to keep track of mounted filesystems for cleanup

cleanup_mounts() {
    # Only run if MOUNT_POINTS array is not empty
    if [[ ${#MOUNT_POINTS[@]} -eq 0 ]]; then
        return
    fi
    log_message "INFO" "Cleaning up chroot mounts..."
    sync # Ensure data is written before unmounting
    # Unmount in reverse order of typical mounting
    local i
    for (( i=${#MOUNT_POINTS[@]}-1 ; i>=0 ; i-- )) ; do
        local mp="${MOUNT_POINTS[i]}"
        if findmnt --raw --target "$mp" > /dev/null; then
            log_message "INFO" "Unmounting $mp..."
            # Try recursive unmount first for nested/bind mounts
            if ! umount -R "$mp" 2>/dev/null; then
                 # Fallback to normal unmount if recursive fails or isn't needed
                 if ! umount "$mp" 2>/dev/null; then
                    log_message "WARN" "Failed to unmount $mp cleanly. Attempting lazy unmount..."
                    umount -l "$mp" 2>/dev/null || log_message "ERROR" "Lazy unmount also failed for $mp."
                 fi
            fi
        else
             log_message "INFO" "$mp already unmounted or not found."
        fi
    done
    MOUNT_POINTS=() # Reset the array
    log_message "INFO" "Chroot mount cleanup finished."
}

setup_chroot() {
    # (Function logic remains mostly the same, ensures ESP mounts to /boot/efi)
    local target_root_dev="$1"
    local target_esp_dev="$2" # Optional, needed for UEFI chroot install
    local chroot_dir="/mnt/grub_repair_target"

    log_message "INFO" "Setting up chroot environment for $target_root_dev ..."
    show_message "Chroot Setup" "Preparing to mount partitions for chroot into $target_root_dev."

    if [[ -d "$chroot_dir" ]]; then
        log_message "WARN" "$chroot_dir already exists. Attempting cleanup..."
        cleanup_mounts # Attempt to clean up previous mounts if script exited badly
        # Try removing directory only if empty after cleanup attempt
        rmdir "$chroot_dir" 2>/dev/null || log_message "WARN" "Could not remove existing $chroot_dir. May contain leftover mounts or files."
        # If still exists, error out
        if [[ -d "$chroot_dir" ]]; then
             log_message "ERROR" "$chroot_dir still exists and could not be removed. Please remove it manually."
             exit 1
        fi
    fi

    log_message "INFO" "Creating mount point: $chroot_dir"
    mkdir -p "$chroot_dir" || handle_error $LINENO "Failed to create $chroot_dir"

    # Register cleanup function to run on script exit (normal or error)
    # Ensure trap is set only once globally or manage it carefully here
    # trap cleanup_mounts EXIT INT TERM # Set globally later

    log_message "INFO" "Mounting root partition $target_root_dev to $chroot_dir"
    mount "$target_root_dev" "$chroot_dir" || handle_error $LINENO "Failed to mount root partition $target_root_dev"
    MOUNT_POINTS+=("$chroot_dir") # Add to array for cleanup

    # Detect and mount separate /boot partition if it exists *within the target system's fstab view*
    # Check common locations first
    if [[ -d "$chroot_dir/boot" ]] && ! findmnt --raw --target "$chroot_dir/boot" > /dev/null; then
         log_message "INFO" "Detected separate /boot directory structure. Attempting to mount based on likely device..."
         # Try to find partition mounted as /boot on the original system (heuristic)
         # This is tricky without parsing fstab. Let's try finding a partition with a /boot label or common FS type
         local boot_dev
         # Look for partition labeled 'boot' or specific FS types often used for boot
         boot_dev=$(lsblk -o NAME,LABEL,FSTYPE -p -n -l | awk -v rootdev="$target_root_dev" '$1 != rootdev && ($2 == "boot" || $3 ~ /ext[234]/) {print $1}' | head -n 1)

         if [[ -n "$boot_dev" ]] && [[ -b "$boot_dev" ]]; then
              log_message "INFO" "Found potential separate boot partition $boot_dev. Mounting to $chroot_dir/boot"
              # Ensure mount point exists inside chroot dir
              mkdir -p "$chroot_dir/boot"
              mount "$boot_dev" "$chroot_dir/boot" || log_message "WARN" "Failed to mount potential separate boot partition $boot_dev automatically."
              MOUNT_POINTS+=("$chroot_dir/boot")
         else
              log_message "INFO" "Could not reliably determine separate /boot partition device. Skipping automatic mount. Ensure it's mounted if needed."
         fi
    fi


    # Mount ESP if provided (UEFI), always target /boot/efi inside chroot
    local esp_mount_point="$chroot_dir/boot/efi"
    if [[ -n "$target_esp_dev" ]]; then
        log_message "INFO" "Mounting ESP partition $target_esp_dev to $esp_mount_point"
        mkdir -p "$esp_mount_point"
        # Check if already mounted by previous /boot mount perhaps
        if ! findmnt --raw --target "$esp_mount_point" > /dev/null; then
            mount "$target_esp_dev" "$esp_mount_point" || handle_error $LINENO "Failed to mount ESP partition $target_esp_dev to $esp_mount_point"
            MOUNT_POINTS+=("$esp_mount_point")
        else
            log_message "INFO" "$esp_mount_point appears to be already mounted (possibly via /boot). Verifying source..."
            if ! findmnt --raw --target "$esp_mount_point" --source "$target_esp_dev" > /dev/null; then
                log_message "WARN" "$esp_mount_point is mounted, but not from the expected ESP device $target_esp_dev. This might cause issues."
            fi
             # Add to MOUNT_POINTS anyway to ensure potential unmount attempt later
             if [[ ! " ${MOUNT_POINTS[@]} " =~ " ${esp_mount_point} " ]]; then
                 MOUNT_POINTS+=("$esp_mount_point")
             fi
        fi
    fi

    # Bind mount virtual filesystems (same as before)
    log_message "INFO" "Bind mounting virtual filesystems..."
    for fs in dev proc sys run; do
        local target_path="$chroot_dir/$fs"
        mkdir -p "$target_path"
        if ! findmnt --raw --target "$target_path" > /dev/null; then
            mount --bind "/$fs" "$target_path" || handle_error $LINENO "Failed to bind mount /$fs to $target_path"
            MOUNT_POINTS+=("$target_path")
        else
            log_message "WARN" "$target_path seems already mounted. Skipping bind mount for $fs."
             # Add to MOUNT_POINTS anyway to ensure potential unmount attempt later
             if [[ ! " ${MOUNT_POINTS[@]} " =~ " ${target_path} " ]]; then
                 MOUNT_POINTS+=("$target_path")
             fi
        fi
    done

    # Bind mount /dev/pts (same as before)
    local target_pts="$chroot_dir/dev/pts"
     mkdir -p "$target_pts"
     if ! findmnt --raw --target "$target_pts" > /dev/null; then
        mount --bind /dev/pts "$target_pts" || log_message "WARN" "Failed to bind mount /dev/pts"
        MOUNT_POINTS+=("$target_pts")
     else
         if [[ ! " ${MOUNT_POINTS[@]} " =~ " ${target_pts} " ]]; then
             MOUNT_POINTS+=("$target_pts")
         fi
     fi

    log_message "INFO" "Chroot environment setup complete at $chroot_dir."
    echo "$chroot_dir" # Return the chroot directory path
}

execute_in_chroot() {
    # (Function logic remains the same as before)
    local chroot_dir="$1"
    shift # Remove chroot_dir from args, rest is the command
    local command_to_run=("$@")

    log_message "INFO" "Executing in chroot ($chroot_dir): ${command_to_run[*]}"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_message "DRYRUN" "Would execute in chroot: ${command_to_run[*]}"
        return 0
    fi

    # Ensure network is available inside chroot if needed (e.g., for installing packages)
    if [[ -f "/etc/resolv.conf" ]]; then
        # Only copy if target doesn't exist or is not a symlink to systemd-resolved stub
        if [[ ! -e "$chroot_dir/etc/resolv.conf" ]] || \
           ([[ -L "$chroot_dir/etc/resolv.conf" ]] && [[ "$(readlink -f "$chroot_dir/etc/resolv.conf")" == *"stub-resolv.conf"* ]]); then
             # Check if target directory exists
             mkdir -p "$chroot_dir/etc"
             cp -L /etc/resolv.conf "$chroot_dir/etc/resolv.conf" || log_message "WARN" "Could not copy resolv.conf to chroot."
        fi
    fi

    # Execute the command
    # Use env -i to start with a cleaner environment inside chroot, passing only essential TERM
    # Use /usr/bin/env explicitly if needed
    if chroot "$chroot_dir" /usr/bin/env -i TERM="$TERM" PATH=/usr/sbin:/usr/bin:/sbin:/bin /bin/bash -c "${command_to_run[*]}"; then
        log_message "INFO" "Chroot command executed successfully: ${command_to_run[*]}"
        # Copy log file generated inside chroot back outside if needed (tricky)
        return 0
    else
        log_message "ERROR" "Chroot command failed (Exit Code: $?). Check messages above."
        return 1
    fi
}

# --- Function to Modify /etc/default/grub ---
modify_grub_default() {
    local file_path="$1"
    local key="$2"
    local value="$3"
    local comment_out="$4" # Optional: set to "true" to comment out the line

    if [[ ! -f "$file_path" ]]; then
        log_message "WARN" "$file_path not found. Cannot modify setting '$key'."
        return 1
    fi

    log_message "INFO" "Attempting to set '$key' to '$value' in $file_path"
    local sed_script=""

    # Escape value for sed (simple escaping for basic cases)
    local escaped_value=$(echo "$value" | sed -e 's/[\/&]/\\&/g')

    # Check if the key exists (commented or uncommented)
    if grep -qE "^\s*#?\s*$key=" "$file_path"; then
        # Key exists, modify it
        if [[ "$comment_out" == "true" ]]; then
             # Comment out the line if it's not already commented
            sed_script="s/^\s*$key=.*$/#&/;/^\s*#\s*$key=/s/^#\s*/# /" # Ensure only one #
        else
            # Uncomment if necessary and set the value
            sed_script="/^\s*#*\s*$key=/ s|^\s*#*\s*$key=.*|$key=$escaped_value|"
        fi
        log_message "INFO" "Modifying existing entry for '$key' in $file_path"
    elif [[ "$comment_out" != "true" ]]; then
        # Key doesn't exist, add it
        echo "$key=$escaped_value" >> "$file_path"
        log_message "INFO" "Adding new entry for '$key=$escaped_value' to $file_path"
        return 0 # Added, no further sed needed for this case
    else
         log_message "INFO" "Key '$key' not found and comment_out requested. No changes made."
         return 0 # Key not found, nothing to comment out
    fi

    # Apply the sed script
    if [[ -n "$sed_script" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_message "DRYRUN" "Would modify $file_path with sed command for key '$key'"
            log_message "DRYRUN" "Sed script detail: $sed_script"
        else
            # Create backup before modifying
            cp "$file_path" "${file_path}.bak_$(date +%Y%m%d_%H%M%S)" || { log_message "WARN" "Failed to create backup for $file_path"; }
            sed -i -E "$sed_script" "$file_path" || { log_message "ERROR" "Failed to modify $file_path for key '$key'"; return 1; }
            log_message "INFO" "Successfully updated '$key' in $file_path."
        fi
    fi
    return 0
}

# --- Function to Apply All Requested /etc/default/grub Modifications ---
apply_grub_default_mods() {
    local default_grub_path="$1"

    log_message "INFO" "Applying requested modifications to $default_grub_path..."
    local mod_applied=false

    if [[ ! -f "$default_grub_path" ]]; then
        log_message "ERROR" "$default_grub_path not found. Cannot apply modifications."
        return 1
    fi

    # 1. Set Timeout
    if [[ -n "$SET_GRUB_TIMEOUT" ]]; then
        if [[ "$SET_GRUB_TIMEOUT" =~ ^[0-9]+$ ]] || [[ "$SET_GRUB_TIMEOUT" == "-1" ]]; then
            modify_grub_default "$default_grub_path" "GRUB_TIMEOUT" "$SET_GRUB_TIMEOUT"
            mod_applied=true
        else
            log_message "WARN" "Invalid timeout value '$SET_GRUB_TIMEOUT' specified. Skipping timeout modification."
        fi
    fi

    # 2. Set Verbose Boot (Modify GRUB_CMDLINE_LINUX_DEFAULT)
    if [[ -n "$SET_GRUB_VERBOSE" ]]; then
        local current_cmdline=""
        # Get the current value, handling commented/uncommented lines
        current_cmdline=$(grep -E "^\s*#?\s*GRUB_CMDLINE_LINUX_DEFAULT=" "$default_grub_path" | sed -E 's/^\s*#?\s*GRUB_CMDLINE_LINUX_DEFAULT="(.*)"/\1/')

        local new_cmdline="$current_cmdline"
        if [[ "$SET_GRUB_VERBOSE" == "true" ]]; then
            # Remove quiet and splash
            log_message "INFO" "Enabling verbose boot (removing 'quiet splash' from GRUB_CMDLINE_LINUX_DEFAULT)."
            new_cmdline=$(echo "$new_cmdline" | sed -e 's/quiet//g' -e 's/splash//g' -e 's/  */ /g' -e 's/^ //g' -e 's/ $//g')
        elif [[ "$SET_GRUB_VERBOSE" == "false" ]]; then
             # Add quiet and splash if not present
             log_message "INFO" "Disabling verbose boot (ensuring 'quiet splash' are in GRUB_CMDLINE_LINUX_DEFAULT)."
             [[ "$new_cmdline" != *quiet* ]] && new_cmdline="quiet $new_cmdline"
             [[ "$new_cmdline" != *splash* ]] && new_cmdline="$new_cmdline splash"
             new_cmdline=$(echo "$new_cmdline" | sed -e 's/  */ /g' -e 's/^ //g' -e 's/ $//g')
        fi

        if [[ "$current_cmdline" != "$new_cmdline" ]]; then
            modify_grub_default "$default_grub_path" "GRUB_CMDLINE_LINUX_DEFAULT" "\"$new_cmdline\""
            mod_applied=true
        else
             log_message "INFO" "GRUB_CMDLINE_LINUX_DEFAULT already matches desired verbose setting ('$new_cmdline'). No change needed."
        fi
    fi

    # 3. Set Menu Style
    if [[ -n "$SET_GRUB_MENU_STYLE" ]]; then
         if [[ "$SET_GRUB_MENU_STYLE" =~ ^(menu|hidden|countdown)$ ]]; then
             modify_grub_default "$default_grub_path" "GRUB_TIMEOUT_STYLE" "$SET_GRUB_MENU_STYLE"
             mod_applied=true
         else
             log_message "WARN" "Invalid menu style '$SET_GRUB_MENU_STYLE' specified. Use 'menu', 'hidden', or 'countdown'. Skipping style modification."
         fi
    fi

    # 4. Enable/Disable os-prober (moved logic here)
    if [[ -n "$GRUB_PROBE_CMD" ]]; then # Check if os-prober was found
        log_message "INFO" "Checking $default_grub_path for os-prober setting..."
        if grep -qE '^\s*GRUB_DISABLE_OS_PROBER\s*=\s*true' "$default_grub_path"; then
            log_message "WARN" "GRUB_DISABLE_OS_PROBER is set to true in $default_grub_path. Other OSes might not be detected."
            if confirm "Enable OS Prober by setting GRUB_DISABLE_OS_PROBER=false?"; then
                modify_grub_default "$default_grub_path" "GRUB_DISABLE_OS_PROBER" "false"
                mod_applied=true
            fi
        else
             log_message "INFO" "os-prober appears to be enabled or not explicitly disabled in $default_grub_path."
             # Ensure it's explicitly set to false if not present or commented out
             if ! grep -qE '^\s*GRUB_DISABLE_OS_PROBER\s*=\s*false' "$default_grub_path"; then
                  log_message "INFO" "Ensuring GRUB_DISABLE_OS_PROBER=false is present in $default_grub_path for clarity."
                  modify_grub_default "$default_grub_path" "GRUB_DISABLE_OS_PROBER" "false"
                  mod_applied=true
             fi
        fi
    else
        log_message "WARN" "os-prober command not found. Cannot manage os-prober setting."
    fi


    if [[ "$mod_applied" == "true" ]]; then
         log_message "INFO" "Finished applying modifications to $default_grub_path."
         return 0 # Indicates changes were applied
    else
         log_message "INFO" "No modifications were applied to $default_grub_path."
         return 1 # Indicates no changes were applied
    fi
}


# --- GRUB Installation and Configuration ---

install_grub() {
    # Added --force for grub2-install in UEFI mode
    local boot_mode="$1"
    local target_device="$2" # Disk for BIOS, ESP partition for UEFI
    local efi_dir="${3:-/boot/efi}" # Only used for UEFI
    local bootloader_id="${4:-GRUB}" # Only used for UEFI

    log_message "INFO" "Starting GRUB installation (Mode: $boot_mode) using $GRUB_INSTALL_CMD..."
    mkdir -p "$BACKUP_DIR"

    # Determine GRUB config directory and path based on detected commands/system structure
    local grub_dir_path="/boot/grub" # Default assumption
    if [[ "$GRUB_INSTALL_CMD" == "grub2-install" ]] || [[ -d "/boot/grub2" ]]; then
         grub_dir_path="/boot/grub2"
         log_message "INFO" "Using GRUB directory: $grub_dir_path (detected grub2)"
    elif [[ -d "/boot/grub" ]]; then
         log_message "INFO" "Using GRUB directory: $grub_dir_path (detected grub)"
    else
         log_message "WARN" "Could not definitively detect /boot/grub or /boot/grub2. Assuming $grub_dir_path based on commands."
         # Fallback to grub2 if grub2 commands were found, else grub
         [[ "$GRUB_INSTALL_CMD" == "grub2-install" ]] && grub_dir_path="/boot/grub2"
    fi

    local grub_cfg_path="$grub_dir_path/grub.cfg"
    local default_grub_path="/etc/default/grub"

    # Ensure the presumed directory exists if we're about to write to it (install might create it, but mkconfig won't)
    mkdir -p "$grub_dir_path"

    # Backup existing configs if they exist
    if [[ -f "$grub_cfg_path" ]]; then
        log_message "INFO" "Backing up $grub_cfg_path to $BACKUP_DIR/"
        cp "$grub_cfg_path" "$BACKUP_DIR/" || log_message "WARN" "Failed to backup $grub_cfg_path"
    fi
    if [[ -f "$default_grub_path" ]]; then
        log_message "INFO" "Backing up $default_grub_path to $BACKUP_DIR/"
        cp "$default_grub_path" "$BACKUP_DIR/" || log_message "WARN" "Failed to backup $default_grub_path"
    fi

    # Prepare for grub-install
    local install_args=() # Use array for arguments
    if [[ "$boot_mode" == "UEFI" ]]; then
        # Ensure efi_dir exists
        mkdir -p "$efi_dir"
        install_args=(--target=x86_64-efi --efi-directory="$efi_dir" --bootloader-id="$bootloader_id" --recheck)
        # *** ADD --force FOR grub2-install IN UEFI MODE ***
        if [[ "$GRUB_INSTALL_CMD" == "grub2-install" ]]; then
             log_message "INFO" "Adding --force flag for grub2-install in UEFI mode."
             install_args+=(--force)
        fi
        log_message "INFO" "UEFI GRUB install command: $GRUB_INSTALL_CMD ${install_args[*]}"
    elif [[ "$boot_mode" == "BIOS" ]]; then
        install_args=("$target_device") # Install to the MBR of the disk
        log_message "INFO" "BIOS GRUB install command: $GRUB_INSTALL_CMD ${install_args[*]}"
    else
        log_message "ERROR" "Invalid boot mode specified for GRUB installation: $boot_mode"
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
         log_message "DRYRUN" "Would run: $GRUB_INSTALL_CMD ${install_args[*]}"
    else
        # Run the detected GRUB install command
        if "$GRUB_INSTALL_CMD" "${install_args[@]}"; then
            log_message "SUCCESS" "$GRUB_INSTALL_CMD completed successfully."
        else
            local exit_code=$?
            log_message "ERROR" "$GRUB_INSTALL_CMD failed (Exit Code: $exit_code). Check messages above."
            if [[ "$boot_mode" == "UEFI" ]]; then
                 log_message "HINT" "Common UEFI issues: ESP ($target_device) not mounted at $efi_dir? Secure Boot enabled/disabled mismatch? Incorrect architecture target? Missing grub(2)-efi packages? Check $LOG_FILE for details."
                 if ! findmnt --raw --target "$efi_dir" > /dev/null; then
                      log_message "HINT" "ESP partition ($target_device) does not appear to be mounted at $efi_dir"
                 fi
            else # BIOS
                 log_message "HINT" "Common BIOS issues: Correct disk ($target_device) selected? Disk writable? Missing grub(2)-pc packages? Check $LOG_FILE for details."
            fi
            # Fedora specific hint
            if [[ "$GRUB_INSTALL_CMD" == "grub2-install" ]]; then
                 log_message "HINT" "(Fedora/RHEL) Check for potential SELinux issues (try 'sudo setenforce 0' temporarily for testing, or check audit logs '/var/log/audit/audit.log')."
            fi
            return 1 # grub-install failed
        fi
    fi

    # --- Apply /etc/default/grub modifications BEFORE running mkconfig ---
    local mods_applied_rc=1 # 1 means no mods applied or attempted
    if apply_grub_default_mods "$default_grub_path"; then
        mods_applied_rc=0 # 0 means mods were applied
    fi
    # If mods failed (e.g., file not found), apply_grub_default_mods returns 1, but we still might want to run mkconfig.
    # If mods succeeded, mods_applied_rc is 0.

    # --- Update GRUB Configuration ---
    log_message "INFO" "Updating GRUB configuration ($grub_cfg_path) using $GRUB_MKCONFIG_CMD..."

    # Generate grub.cfg using the detected command and path
    local mkconfig_cmd=("$GRUB_MKCONFIG_CMD" -o "$grub_cfg_path")

    log_message "INFO" "Running: ${mkconfig_cmd[*]}"
     if [[ "$DRY_RUN" == "true" ]]; then
         log_message "DRYRUN" "Would run: ${mkconfig_cmd[*]}"
    else
        if "${mkconfig_cmd[@]}"; then
            log_message "SUCCESS" "GRUB configuration ($grub_cfg_path) updated successfully."
            log_message "INFO" "Check $grub_cfg_path to verify entries for all expected operating systems."
            # Basic verification
            if [[ -n "$GRUB_PROBE_CMD" ]]; then
                if grep -q 'menuentry ' "$grub_cfg_path" | grep -i -q -E 'windows|mac|ubuntu|fedora|debian|arch|mint'; then
                     log_message "INFO" "Entries for other operating systems seem to be present in $grub_cfg_path."
                else
                     log_message "WARN" "Did not find common keywords for other OSes in $grub_cfg_path. os-prober might not have run correctly or found other systems."
                fi
            fi
        else
            log_message "ERROR" "$mkconfig_cmd failed (Exit Code: $?). GRUB configuration might be incomplete or corrupted."
             if [[ "$GRUB_MKCONFIG_CMD" == "grub2-mkconfig" ]]; then
                 log_message "HINT" "(Fedora/RHEL) Check for potential SELinux issues (try 'sudo setenforce 0' temporarily for testing, or check audit logs '/var/log/audit/audit.log')."
            fi
            return 1 # mkconfig failed
        fi
    fi

    sync # Ensure all changes are written to disk
    log_message "INFO" "GRUB installation and configuration process finished."
    return 0 # Success
}


# --- Main Script Logic ---

# --- Argument Parsing (Add new config options) ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: sudo $SCRIPT_NAME [options]"
            echo ""
            echo "Core Options:"
            echo "  --mode [UEFI|BIOS]     Force boot mode (otherwise auto-detect)."
            echo "  --esp PARTITION        Specify ESP partition device (e.g., /dev/sda1) for UEFI."
            echo "  --disk DISK            Specify boot disk device (e.g., /dev/sda) for BIOS."
            echo "  --target-root PARTITION Specify root partition of the Linux OS to repair (required for chroot)."
            echo "  --chroot               Force using chroot (useful if running from installed OS to repair itself)."
            echo "  --bootloader-id NAME   Set UEFI bootloader ID (default: GRUB, common: fedora, ubuntu)."
            echo ""
            echo "Configuration Options (/etc/default/grub):"
            echo "  --set-timeout SECONDS  Set GRUB menu timeout (e.g., 5, 10, -1 for indefinite)."
            echo "  --enable-verbose       Enable verbose boot messages (removes 'quiet splash')."
            echo "  --disable-verbose      Disable verbose boot messages (adds 'quiet splash')."
            echo "  --show-menu            Set GRUB menu to always show (sets GRUB_TIMEOUT_STYLE=menu)."
            echo "  --hide-menu            Set GRUB menu to hide unless key pressed (sets GRUB_TIMEOUT_STYLE=hidden)."
            # Add more config options here if needed
            echo ""
            echo "Interface & Logging Options:"
            echo "  --dialog               Use dialog-based interface if available (requires 'dialog' package)."
            echo "  --no-dialog            Force text-based interface."
            echo "  --log-file FILE        Specify custom log file path."
            echo "  --dry-run              Show commands without executing them."
            echo "  -y|--yes               Automatically answer yes to confirmations (Use with extreme caution!)."
            echo "  -h|--help              Show this help message."
            echo ""
            echo "Notes:"
            echo " - Detects and uses appropriate grub/grub2 commands and paths."
            echo " - Adds '--force' to 'grub2-install' when run in UEFI mode."
            echo " - Configuration options modify '/etc/default/grub' before updating grub.cfg."
            echo ""
            echo "Example (Live USB, repair Fedora UEFI, set timeout to 10s, enable verbose boot):"
            echo "  sudo $SCRIPT_NAME --mode UEFI --target-root /dev/nvme0n1p5 --esp /dev/nvme0n1p1 \\"
            echo "      --set-timeout 10 --enable-verbose [--bootloader-id fedora]"
            echo ""
            echo "Example (Repair current Debian system, BIOS mode, ensure menu is shown):"
            echo "  sudo $SCRIPT_NAME --mode BIOS --disk /dev/sda --show-menu"
            exit 0
            ;;
        # Core Options
        --mode) DETECTED_MODE="$2"; shift ;;
        --esp) TARGET_ESP="$2"; shift ;;
        --disk) TARGET_DISK_BIOS="$2"; shift ;;
        --target-root) TARGET_ROOT_PARTITION="$2"; shift ;;
        --chroot) FORCE_CHROOT="true" ;;
        --bootloader-id) BOOTLOADER_ID="$2"; shift ;;
        # Config Options
        --set-timeout) SET_GRUB_TIMEOUT="$2"; shift ;;
        --enable-verbose) SET_GRUB_VERBOSE="true" ;;
        --disable-verbose) SET_GRUB_VERBOSE="false" ;;
        --show-menu) SET_GRUB_MENU_STYLE="menu" ;;
        --hide-menu) SET_GRUB_MENU_STYLE="hidden" ;;
        # Interface & Logging
        --dialog) USE_DIALOG="true" ;;
        --no-dialog) USE_DIALOG="false" ;;
        --log-file) LOG_FILE="$2"; shift ;;
        --dry-run) DRY_RUN="true"; log_message "INFO" "Dry run mode enabled." ;;
        -y|--yes) AUTO_YES="true"; log_message "WARN" "--yes flag enabled. Script will proceed without confirmation prompts." ;;

        *) log_message "ERROR" "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# --- Initial Checks ---
mkdir -p "$(dirname "$LOG_FILE")" # Ensure log directory exists
check_root
check_dependencies # Check deps and determine GRUB command names

log_message "INFO" "Starting GRUB Repair Script v1.4 (Log: $LOG_FILE)"
log_message "INFO" "Using GRUB commands: Install='$GRUB_INSTALL_CMD', MkConfig='$GRUB_MKCONFIG_CMD'"
# Log requested config changes
[[ -n "$SET_GRUB_TIMEOUT" ]] && log_message "INFO" "Requested GRUB timeout: $SET_GRUB_TIMEOUT"
[[ "$SET_GRUB_VERBOSE" == "true" ]] && log_message "INFO" "Requested verbose boot: Enabled"
[[ "$SET_GRUB_VERBOSE" == "false" ]] && log_message "INFO" "Requested verbose boot: Disabled"
[[ -n "$SET_GRUB_MENU_STYLE" ]] && log_message "INFO" "Requested GRUB menu style: $SET_GRUB_MENU_STYLE"


if [[ "$DRY_RUN" == "true" ]]; then
    show_message "Dry Run Mode" "Script is running in dry-run mode. No changes will be made."
fi

# --- Determine if Chroot is Needed ---
NEEDS_CHROOT="false"
if [[ -n "$TARGET_ROOT_PARTITION" ]]; then
    log_message "INFO" "--target-root specified ($TARGET_ROOT_PARTITION). Assuming chroot is required."
    NEEDS_CHROOT="true"
elif [[ "$FORCE_CHROOT" == "true" ]]; then
     log_message "INFO" "--chroot specified. Will attempt chroot."
     NEEDS_CHROOT="true"
     if [[ -z "$TARGET_ROOT_PARTITION" ]]; then
         TARGET_ROOT_PARTITION=$(select_partition_dialog "Target Linux Root") || { log_message "ERROR" "Target root partition selection cancelled or failed."; cleanup_mounts; exit 1; }
     fi
else
    current_root_dev=$(findmnt -n -o SOURCE /)
    # Check if running from Live USB more reliably
    if [[ -f /.live_is_live ]] || grep -q -E '(root=live:|boot=live|fromiso|cow_spacesize)' /proc/cmdline || [[ $(lsblk -o RM -n -d "$(findmnt -n -o SOURCE /)") == "1" ]]; then
         log_message "INFO" "Running from a likely Live environment."
         show_message "Environment" "It looks like you are running from a Live USB/CD.\n\nYou need to select the root partition of the Linux installation you want to repair."
         NEEDS_CHROOT="true"
         if [[ -z "$TARGET_ROOT_PARTITION" ]]; then
             TARGET_ROOT_PARTITION=$(select_partition_dialog "Target Linux Root") || { log_message "ERROR" "Target root partition selection cancelled or failed."; cleanup_mounts; exit 1; }
         fi
    else
         log_message "INFO" "Running from a likely installed system ($current_root_dev). Chroot not assumed unless specified."
         if confirm "Repair the currently running system ($current_root_dev)? (Answer 'no' to select a different one via chroot)"; then
             TARGET_ROOT_PARTITION="$current_root_dev" # Target is the current system
             log_message "INFO" "Targeting the currently running system."
             NEEDS_CHROOT="false" # Explicitly false now
         else
             log_message "INFO" "User opted to select a different system via chroot."
             NEEDS_CHROOT="true"
              if [[ -z "$TARGET_ROOT_PARTITION" ]]; then
                 TARGET_ROOT_PARTITION=$(select_partition_dialog "Target Linux Root") || { log_message "ERROR" "Target root partition selection cancelled or failed."; cleanup_mounts; exit 1; }
             fi
         fi
    fi
fi

# --- Determine Boot Mode ---
if [[ -z "$DETECTED_MODE" ]]; then
    DETECTED_MODE=$(detect_boot_mode)
    log_message "INFO" "Auto-detected boot mode: $DETECTED_MODE"
    # Use descriptive text for menu items
    choice=$(show_menu "Confirm Boot Mode" "Auto-detected '$DETECTED_MODE' mode. Is this correct?" \
        "Yes_Confirm" "Use detected '$DETECTED_MODE' mode" \
        "Select_UEFI" "Force UEFI Mode" \
        "Select_BIOS" "Force BIOS Mode")
    case "$choice" in
        Yes_Confirm) log_message "INFO" "User confirmed auto-detected mode: $DETECTED_MODE";;
        Select_UEFI) DETECTED_MODE="UEFI"; log_message "INFO" "User selected UEFI mode.";;
        Select_BIOS) DETECTED_MODE="BIOS"; log_message "INFO" "User selected BIOS mode.";;
        *) log_message "ERROR" "Boot mode selection cancelled."; cleanup_mounts; exit 1 ;;
    esac
else
    log_message "INFO" "Using specified boot mode: $DETECTED_MODE"
    if [[ "$DETECTED_MODE" != "UEFI" && "$DETECTED_MODE" != "BIOS" ]]; then
        log_message "ERROR" "Invalid mode specified with --mode. Use 'UEFI' or 'BIOS'."
        cleanup_mounts; exit 1
    fi
fi

# --- Determine Target Device/Partition ---
EFI_MOUNT_POINT="/boot/efi" # Standard ESP mount point

if [[ "$DETECTED_MODE" == "UEFI" ]]; then
    log_message "INFO" "Configuring for UEFI mode."
    if [[ -z "$TARGET_ESP" ]]; then
        TARGET_ESP=$(find_esp_partition)
        if [[ -n "$TARGET_ESP" ]]; then
            log_message "INFO" "Auto-detected ESP partition: $TARGET_ESP"
             if ! confirm "Use auto-detected ESP partition $TARGET_ESP?"; then
                 TARGET_ESP=$(select_partition_dialog "EFI System Partition (ESP)") || { log_message "ERROR" "ESP selection cancelled or failed."; cleanup_mounts; exit 1; }
             fi
        else
            log_message "WARN" "Could not auto-detect ESP. Please select manually."
            TARGET_ESP=$(select_partition_dialog "EFI System Partition (ESP)") || { log_message "ERROR" "ESP selection cancelled or failed."; cleanup_mounts; exit 1; }
        fi
    else
         log_message "INFO" "Using specified ESP partition: $TARGET_ESP"
    fi
    if [[ -z "$TARGET_ESP" ]]; then
        log_message "ERROR" "No ESP partition specified or selected. Cannot proceed with UEFI install."
        cleanup_mounts; exit 1
    fi
    if [[ ! -b "$TARGET_ESP" ]]; then
         log_message "ERROR" "Specified ESP ($TARGET_ESP) is not a valid block device."
         cleanup_mounts; exit 1
    fi
    BOOTLOADER_ID="${BOOTLOADER_ID:-GRUB}" # Default to GRUB if not set
    log_message "INFO" "UEFI Bootloader ID: $BOOTLOADER_ID (Common alternatives: fedora, ubuntu)"

else # BIOS Mode
    log_message "INFO" "Configuring for Legacy BIOS mode."
    if [[ -z "$TARGET_DISK_BIOS" ]]; then
        TARGET_DISK_BIOS=$(find_boot_disk_bios)
         if [[ -n "$TARGET_DISK_BIOS" ]]; then
            log_message "INFO" "Auto-detected potential BIOS boot disk: $TARGET_DISK_BIOS"
             if ! confirm "Install GRUB to MBR of auto-detected disk $TARGET_DISK_BIOS?"; then
                 TARGET_DISK_BIOS=$(select_disk_dialog) || { log_message "ERROR" "Boot disk selection cancelled or failed."; cleanup_mounts; exit 1; }
             fi
        else
            log_message "WARN" "Could not auto-detect BIOS boot disk. Please select manually."
            TARGET_DISK_BIOS=$(select_disk_dialog) || { log_message "ERROR" "Boot disk selection cancelled or failed."; cleanup_mounts; exit 1; }
        fi
    else
        log_message "INFO" "Using specified BIOS boot disk: $TARGET_DISK_BIOS"
    fi
     if [[ -z "$TARGET_DISK_BIOS" ]]; then
        log_message "ERROR" "No BIOS boot disk specified or selected. Cannot proceed with BIOS install."
        cleanup_mounts; exit 1
    fi
    if [[ ! -b "$TARGET_DISK_BIOS" ]]; then
         log_message "ERROR" "Specified disk ($TARGET_DISK_BIOS) is not a valid block device."
         cleanup_mounts; exit 1
    fi
fi

# --- Summary and Final Confirmation ---
# (Ensure ESP mount point check uses variable)
echo "---------------------------------------------" | tee -a "$LOG_FILE" >&2
log_message "INFO" "Configuration Summary:"
log_message "INFO" "  Mode: $DETECTED_MODE"
if [[ "$DETECTED_MODE" == "UEFI" ]]; then
    log_message "INFO" "  EFI System Partition (ESP): $TARGET_ESP"
    log_message "INFO" "  ESP Mount Point (Target): $EFI_MOUNT_POINT"
    log_message "INFO" "  Bootloader ID: $BOOTLOADER_ID"
     # Check if ESP is already mounted at the target location (relevant if NOT chrooting)
    if [[ "$NEEDS_CHROOT" == "false" ]] && ! findmnt --raw --target "$EFI_MOUNT_POINT" --source "$TARGET_ESP" > /dev/null; then
         log_message "WARN" "ESP $TARGET_ESP is not mounted at $EFI_MOUNT_POINT on the current system."
         if confirm "Attempt to mount $TARGET_ESP at $EFI_MOUNT_POINT?"; then
             mkdir -p "$EFI_MOUNT_POINT"
              if [[ "$DRY_RUN" != "true" ]]; then
                  mount "$TARGET_ESP" "$EFI_MOUNT_POINT" || { log_message "ERROR" "Failed to mount ESP. Cannot proceed."; cleanup_mounts; exit 1; }
                  log_message "INFO" "Mounted $TARGET_ESP at $EFI_MOUNT_POINT."
              else
                  log_message "DRYRUN" "Would mount $TARGET_ESP at $EFI_MOUNT_POINT."
              fi
         else
             log_message "ERROR" "ESP must be mounted at $EFI_MOUNT_POINT for non-chroot UEFI install. Aborting."
             cleanup_mounts; exit 1
         fi
    fi
else # BIOS
    log_message "INFO" "  Target Disk (for MBR): $TARGET_DISK_BIOS"
fi
if [[ "$NEEDS_CHROOT" == "true" ]]; then
    log_message "INFO" "  Target Root Partition (for chroot): $TARGET_ROOT_PARTITION"
else
     log_message "INFO" "  Targeting currently running system (no chroot)."
fi
# List requested config changes again in summary
[[ -n "$SET_GRUB_TIMEOUT" ]] && log_message "INFO" "  Requested GRUB Timeout: $SET_GRUB_TIMEOUT"
[[ "$SET_GRUB_VERBOSE" == "true" ]] && log_message "INFO" "  Requested Verbose Boot: Enabled"
[[ "$SET_GRUB_VERBOSE" == "false" ]] && log_message "INFO" "  Requested Verbose Boot: Disabled"
[[ -n "$SET_GRUB_MENU_STYLE" ]] && log_message "INFO" "  Requested GRUB Menu Style: $SET_GRUB_MENU_STYLE"

log_message "INFO" "  Log file: $LOG_FILE"
log_message "INFO" "  Backups will be stored in: $BACKUP_DIR"
echo "---------------------------------------------" | tee -a "$LOG_FILE" >&2

if [[ "$DRY_RUN" == "true" ]]; then
     show_message "Dry Run" "Dry run mode. Review the log file ($LOG_FILE) for actions that would be taken."
     # Add a specific dry run for chroot command construction if needed
     if [[ "$NEEDS_CHROOT" == "true" ]]; then
         log_message "DRYRUN" "[Chroot] Will attempt to mount filesystems and construct commands to run inside chroot."
     fi
     cleanup_mounts # Still run cleanup in case mounts were made before dry run exit
     exit 0
fi

if ! confirm "Proceed with the GRUB repair using the settings above?"; then
    log_message "INFO" "User aborted the operation."
    cleanup_mounts
    exit 0
fi


# --- Execute Repair ---
INSTALL_SUCCESS="false"
# Ensure cleanup runs even if install_grub fails or chroot fails
trap 'cleanup_mounts' EXIT INT TERM

if [[ "$NEEDS_CHROOT" == "true" ]]; then
    # --- Chroot Execution ---
    CHROOT_DIR=""
    ESP_ARG_FOR_CHROOT=""
    [[ "$DETECTED_MODE" == "UEFI" ]] && ESP_ARG_FOR_CHROOT="$TARGET_ESP"

    if CHROOT_DIR=$(setup_chroot "$TARGET_ROOT_PARTITION" "$ESP_ARG_FOR_CHROOT"); then
        log_message "INFO" "Successfully set up chroot at $CHROOT_DIR"

        # Define paths *inside* the chroot
        # Determine grub dir and commands *inside* the chroot environment before execution
        CHROOT_PREP_CMDS="
            echo '*** Preparing GRUB commands inside chroot ***'; \
            INSTALL_CMD=''; MKCONFIG_CMD=''; GRUB_DIR=''; \
            if command -v grub2-install &> /dev/null && command -v grub2-mkconfig &> /dev/null; then \
                INSTALL_CMD='grub2-install'; MKCONFIG_CMD='grub2-mkconfig'; GRUB_DIR='/boot/grub2'; \
            elif command -v grub-install &> /dev/null && command -v grub-mkconfig &> /dev/null; then \
                INSTALL_CMD='grub-install'; MKCONFIG_CMD='grub-mkconfig'; GRUB_DIR='/boot/grub'; \
            else \
                echo 'ERROR: Cannot find grub or grub2 commands inside chroot.'; exit 1; \
            fi; \
            CFG_PATH=\"\$GRUB_DIR/grub.cfg\"; \
            DEFAULT_GRUB_PATH='/etc/default/grub'; \
            EFI_DIR='/boot/efi'; \
            CHROOT_BACKUP_DIR='/tmp/grub_chroot_backups'; \
            mkdir -p \$GRUB_DIR; \
            mkdir -p \$CHROOT_BACKUP_DIR; \
            echo \"Using: \$INSTALL_CMD, \$MKCONFIG_CMD, \$CFG_PATH\"; \
        "

        # Build the grub-install command string for execution inside chroot
        grub_install_chroot_args_array=() # Use array
        if [[ "$DETECTED_MODE" == "UEFI" ]]; then
             grub_install_chroot_args_array=(--target=x86_64-efi --efi-directory="\$EFI_DIR" --bootloader-id="$BOOTLOADER_ID" --recheck)
             # *** ADD --force FOR grub2-install IN UEFI MODE (inside chroot check) ***
             CHROOT_PREP_CMDS+="
                if [[ \"\$INSTALL_CMD\" == \"grub2-install\" ]]; then \
                    echo 'INFO: Adding --force flag for grub2-install in UEFI mode (inside chroot).'; \
                    GRUB_INSTALL_EXTRA_ARGS='--force'; \
                else \
                    GRUB_INSTALL_EXTRA_ARGS=''; \
                fi; \
                if ! findmnt --raw --target \$EFI_DIR > /dev/null; then \
                     echo 'ERROR: ESP is not mounted at \$EFI_DIR inside the chroot environment.'; \
                     exit 1; \
                fi; \
             "
             # We'll append $GRUB_INSTALL_EXTRA_ARGS later in the command string
        else # BIOS
             grub_install_chroot_args_array=("$TARGET_DISK_BIOS") # Disk path is the same inside/outside chroot
             CHROOT_PREP_CMDS+="GRUB_INSTALL_EXTRA_ARGS='';" # Define empty extra args for BIOS
        fi

        # Convert array to string for the shell command
        grub_install_chroot_args_str=""
        for arg in "${grub_install_chroot_args_array[@]}"; do
            # Simple quoting, assumes args don't contain single quotes themselves
            grub_install_chroot_args_str+=" '$arg'"
        done

        # --- Build sed commands for /etc/default/grub modifications inside chroot ---
        chroot_sed_commands=""
        chroot_default_grub_backup_cmd="if [[ -f \$DEFAULT_GRUB_PATH ]]; then cp \$DEFAULT_GRUB_PATH \$CHROOT_BACKUP_DIR/default_grub_\$(date +%Y%m%d_%H%M%S); fi"

        # Timeout
        if [[ -n "$SET_GRUB_TIMEOUT" ]]; then
            if [[ "$SET_GRUB_TIMEOUT" =~ ^[0-9]+$ ]] || [[ "$SET_GRUB_TIMEOUT" == "-1" ]]; then
                chroot_sed_commands+="echo 'Applying timeout $SET_GRUB_TIMEOUT'; "
                chroot_sed_commands+="sed -i -E -e \"s/^\s*#?\s*(GRUB_TIMEOUT=).*/\1$SET_GRUB_TIMEOUT/\" \
                                   -e \"t\" -e \"\$aGRUB_TIMEOUT=$SET_GRUB_TIMEOUT\" \$DEFAULT_GRUB_PATH && "
            fi
        fi
        # Verbose Boot
        if [[ "$SET_GRUB_VERBOSE" == "true" ]]; then
             chroot_sed_commands+="echo 'Enabling verbose boot'; "
             chroot_sed_commands+="sed -i -E -e '/^\s*#?\s*GRUB_CMDLINE_LINUX_DEFAULT=/ s/quiet//g; /^\s*#?\s*GRUB_CMDLINE_LINUX_DEFAULT=/ s/splash//g; /^\s*#?\s*GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"\"/\"/g; /^\s*#?\s*GRUB_CMDLINE_LINUX_DEFAULT=/ s/\" +/\"/g; /^\s*#?\s*GRUB_CMDLINE_LINUX_DEFAULT=/ s/ +\"/\"/g' \$DEFAULT_GRUB_PATH && "
        elif [[ "$SET_GRUB_VERBOSE" == "false" ]]; then
             chroot_sed_commands+="echo 'Disabling verbose boot'; "
             # Add quiet if missing
             chroot_sed_commands+="sed -i -E -e '/^\s*#?\s*GRUB_CMDLINE_LINUX_DEFAULT=/ { /quiet/! s/=(\"[^\"]*)/=\1 quiet/ }' \$DEFAULT_GRUB_PATH && "
             # Add splash if missing
             chroot_sed_commands+="sed -i -E -e '/^\s*#?\s*GRUB_CMDLINE_LINUX_DEFAULT=/ { /splash/! s/=(\"[^\"]*)/=\1 splash/ }' \$DEFAULT_GRUB_PATH && "
             # Ensure default line exists if completely missing (basic version)
             chroot_sed_commands+="grep -qE '^\s*#?\s*GRUB_CMDLINE_LINUX_DEFAULT=' \$DEFAULT_GRUB_PATH || echo 'GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"' >> \$DEFAULT_GRUB_PATH && "
        fi
        # Menu Style
        if [[ -n "$SET_GRUB_MENU_STYLE" ]]; then
            if [[ "$SET_GRUB_MENU_STYLE" =~ ^(menu|hidden|countdown)$ ]]; then
                 chroot_sed_commands+="echo 'Setting menu style to $SET_GRUB_MENU_STYLE'; "
                 chroot_sed_commands+="sed -i -E -e \"s/^\s*#?\s*(GRUB_TIMEOUT_STYLE=).*/\1$SET_GRUB_MENU_STYLE/\" \
                                    -e \"t\" -e \"\$aGRUB_TIMEOUT_STYLE=$SET_GRUB_MENU_STYLE\" \$DEFAULT_GRUB_PATH && "
            fi
        fi
        # OS Prober (always ensure it's set to false unless user confirms otherwise later - handled by apply function logic)
        chroot_sed_commands+="echo 'Ensuring GRUB_DISABLE_OS_PROBER=false'; "
        chroot_sed_commands+="sed -i -E -e \"s/^\s*#?\s*(GRUB_DISABLE_OS_PROBER=).*/\1false/\" \
                           -e \"t\" -e \"\$aGRUB_DISABLE_OS_PROBER=false\" \$DEFAULT_GRUB_PATH && "
        # Remove trailing ' && '
        chroot_sed_commands=${chroot_sed_commands% && }


        # Build combined command string
        full_chroot_command="
            set -e; # Exit on error within chroot sub-shell
            $CHROOT_PREP_CMDS; \
            echo '*** Running GRUB repair inside chroot ***'; \
            mount -o remount,rw / || echo 'WARN: Remount rw failed, continuing...'; \
            echo '*** Applying /etc/default/grub modifications ***'; \
            $chroot_default_grub_backup_cmd; \
            if [[ -f \$DEFAULT_GRUB_PATH ]]; then \
                $chroot_sed_commands; \
                echo 'Finished applying /etc/default/grub modifications.'; \
            else \
                echo 'WARN: \$DEFAULT_GRUB_PATH not found, skipping modifications.'; \
            fi; \
            echo '*** Running GRUB Install ***'; \
            echo \"Running: \$INSTALL_CMD $grub_install_chroot_args_str \$GRUB_INSTALL_EXTRA_ARGS\"; \
            if \$INSTALL_CMD $grub_install_chroot_args_str \$GRUB_INSTALL_EXTRA_ARGS; then \
                echo \"\$INSTALL_CMD successful.\"; \
                echo '*** Updating GRUB Configuration ***'; \
                echo \"Running: \$MKCONFIG_CMD -o \$CFG_PATH\"; \
                if \$MKCONFIG_CMD -o \$CFG_PATH; then \
                    echo \"GRUB config update successful.\"; \
                    exit 0; \
                else \
                    echo 'ERROR: GRUB config update failed ($MKCONFIG_CMD).'; \
                    exit 1; \
                fi; \
            else \
                echo 'ERROR: GRUB install failed ($INSTALL_CMD).'; \
                exit 1; \
            fi; \
            sync; \
        "

        if execute_in_chroot "$CHROOT_DIR" "$full_chroot_command"; then
             log_message "SUCCESS" "GRUB repair completed successfully within chroot."
             INSTALL_SUCCESS="true"
             # Copy backups out of chroot
              if [[ -d "$CHROOT_DIR/tmp/grub_chroot_backups" ]]; then
                  cp -a "$CHROOT_DIR/tmp/grub_chroot_backups/." "$BACKUP_DIR/" && log_message "INFO" "Copied backups from chroot to $BACKUP_DIR"
              fi
        else
             log_message "ERROR" "GRUB repair failed within chroot. Check log messages above and within the chroot output."
             INSTALL_SUCCESS="false"
             # Add SELinux hint if chroot likely involved Fedora
             if [[ -f "$CHROOT_DIR/etc/fedora-release" ]]; then
                 log_message "HINT" "(Fedora/RHEL) Check for potential SELinux issues within chroot (try 'setenforce 0' in chroot before commands, or check audit logs)."
             fi
        fi
        # Cleanup is handled by trap

    else
        log_message "ERROR" "Failed to set up chroot environment. Aborting."
        INSTALL_SUCCESS="false"
        # Cleanup is handled by trap
    fi

else
    # --- Non-Chroot Execution (Repairing current system) ---
    log_message "INFO" "Performing GRUB repair on the currently running system."
    TARGET_DEV=""
    [[ "$DETECTED_MODE" == "UEFI" ]] && TARGET_DEV="$TARGET_ESP"
    [[ "$DETECTED_MODE" == "BIOS" ]] && TARGET_DEV="$TARGET_DISK_BIOS"

    # Pass the correct ESP mount point for UEFI non-chroot
    # install_grub now handles modifications internally before mkconfig
    if install_grub "$DETECTED_MODE" "$TARGET_DEV" "$EFI_MOUNT_POINT" "$BOOTLOADER_ID"; then
        INSTALL_SUCCESS="true"
    else
        INSTALL_SUCCESS="false"
    fi
    # Cleanup is handled by trap
fi

# --- Final Report ---
# Remove the cleanup trap before final messages
trap - EXIT INT TERM

# Explicitly call cleanup one last time to be sure
cleanup_mounts

echo "---------------------------------------------" | tee -a "$LOG_FILE" >&2
if [[ "$INSTALL_SUCCESS" == "true" ]]; then
    log_message "SUCCESS" "GRUB REPAIR PROCESS COMPLETED."
    show_message "Success" "GRUB repair process finished successfully.\n\nPlease review the log file for details:\n$LOG_FILE\n\nBackups of previous config files (if any) are in:\n$BACKUP_DIR\n\nIt is recommended to reboot your system to check if GRUB is working correctly."
else
    log_message "FAILURE" "GRUB REPAIR PROCESS FAILED."
    show_message "Failure" "GRUB repair process encountered errors.\n\nPlease review the log file for details:\n$LOG_FILE\n\nConsult the log for error messages to diagnose the problem."
fi
echo "---------------------------------------------" | tee -a "$LOG_FILE" >&2


exit 0

