#!/bin/bash

# Script to manage BitLocker drives on Fedora/Linux
# Provides options to unlock (mount) and lock (unmount) drives.

# --- Configuration ---
# Base directory for mounting. Using /media/user is standard for user mounts.
# $SUDO_USER holds the username of the user who invoked sudo.
MOUNT_BASE_DIR="/media/${SUDO_USER:-$(whoami)}" # Fallback to current user if SUDO_USER is not set (though script needs sudo)
MAPPER_PREFIX="bitlk_"

# --- Helper Functions ---
function error_exit {
    echo ""
    echo "❌ ERROR: $1" >&2
    # Optionally add cleanup logic here if needed in the future
    exit 1
}

function success_msg {
    echo "✅ SUCCESS: $1"
}

function info_msg {
    echo "ℹ️  INFO: $1"
}

# --- Pre-run Checks ---
# Check if running as root/sudo
if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run with sudo (e.g., 'sudo ./bitlocker_manager.sh')."
fi

# Check if SUDO_USER is set (important for mount point ownership)
if [[ -z "$SUDO_USER" ]]; then
    # This case is less likely if EUID check passes, but good to have
    info_msg "Warning: \$SUDO_USER not set. Mount point ownership might default to root."
    # Attempt to get the logged-in user if possible, otherwise use 'user' as placeholder
    CURRENT_USER=$(logname 2>/dev/null || whoami)
    MOUNT_BASE_DIR="/media/${CURRENT_USER}"
    info_msg "Attempting to use base mount directory: ${MOUNT_BASE_DIR}"

    # Re-check if we derived a valid user
    if [[ "$CURRENT_USER" == "root" ]] && [[ -z "$SUDO_USER" ]]; then
         info_msg "Warning: Could not reliably determine non-root user. Files might be owned by root."
    fi
fi


# Check if cryptsetup command exists
if ! command -v cryptsetup &> /dev/null; then
    error_exit "'cryptsetup' command not found. Please install it (e.g., 'sudo dnf install cryptsetup')."
fi

# Check if lsblk command exists
if ! command -v lsblk &> /dev/null; then
    error_exit "'lsblk' command not found. Please install util-linux (usually present)."
fi

# Check if findmnt command exists
if ! command -v findmnt &> /dev/null; then
    error_exit "'findmnt' command not found. Please install util-linux (usually present)."
fi


# --- Unlock Function ---
function unlock_bitlocker {
    echo "--- Unlock BitLocker Drive ---"
    echo "Available partitions:"
    # List block devices, focusing on partitions. Add LABEL for easier identification.
    # Exclude loop devices and ROMs which are typically not BitLocker targets.
    lsblk -o NAME,SIZE,TYPE,LABEL,MOUNTPOINT -p -e 7,11 # -p shows full path, -e 7,11 excludes loop and rom
    echo "-----------------------------"

    local device_path
    while true; do
        read -p "Enter the full device path of the BitLocker partition (e.g., /dev/sdb1): " device_path
        if [[ -z "$device_path" ]]; then
            echo "Input cannot be empty. Please try again."
        elif [[ ! "$device_path" =~ ^/dev/[a-zA-Z0-9]+[0-9]*$ ]]; then
             echo "Invalid format. Please enter a path like /dev/sdxY."
        elif [ ! -b "$device_path" ]; then
            echo "Device '$device_path' does not exist or is not a block device. Check 'lsblk' output."
        else
            break # Valid input
        fi
    done

    local device_name=$(basename "$device_path")
    local mapper_name="${MAPPER_PREFIX}${device_name}"
    local mount_point="${MOUNT_BASE_DIR}/${mapper_name}"

    # Check if already mapped or mounted
    if [ -e "/dev/mapper/$mapper_name" ]; then
        error_exit "Device seems already mapped as '/dev/mapper/$mapper_name'. Try locking it first if needed."
    fi
    if findmnt --source "/dev/mapper/$mapper_name" --noheadings &> /dev/null; then
         error_exit "Device '/dev/mapper/$mapper_name' seems already mounted. Try locking it first if needed."
    fi
     if [ -d "$mount_point" ] && [ "$(ls -A $mount_point)" ]; then
         info_msg "Warning: Mount point '$mount_point' exists and is not empty. Mounting might overlay existing files."
         read -p "Continue anyway? (y/N): " confirm
         if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
             info_msg "Aborting unlock."
             return
         fi
     fi


    info_msg "Attempting to unlock '$device_path'..."

    # Loop until the correct password is provided
    while true; do
        # cryptsetup will prompt for the password interactively
        if cryptsetup bitlkOpen "$device_path" "$mapper_name"; then
            success_msg "Device '$device_path' unlocked as '/dev/mapper/$mapper_name'."
            break # Exit password loop on success
        else
            local crypt_status=$?
            # Check common exit codes if possible (e.g., 2 often means wrong password/no key)
             if [[ $crypt_status -eq 2 ]]; then
                 echo "❌ Incorrect password or no key found. Please try again."
                 # Optional: add a way to break out if the user wants to cancel
                 read -p "Try again? (Y/n): " retry_confirm
                 if [[ "$retry_confirm" =~ ^[Nn]$ ]]; then
                     error_exit "Password attempt cancelled."
                     return 1 # Indicate failure within function
                 fi
             else
                 error_exit "cryptsetup failed with status $crypt_status. Cannot unlock drive."
                 return 1 # Indicate failure within function
             fi
        fi
    done

    info_msg "Creating mount point '$mount_point'..."
    # Create the base directory if it doesn't exist (e.g., /media/user)
     if [ ! -d "$MOUNT_BASE_DIR" ]; then
         mkdir -p "$MOUNT_BASE_DIR" || error_exit "Failed to create base directory '$MOUNT_BASE_DIR'."
         # Set permissions on the base directory if we created it
         chown "$SUDO_USER:$SUDO_GID" "$MOUNT_BASE_DIR" || info_msg "Warning: Could not set ownership on '$MOUNT_BASE_DIR'."
         chmod 700 "$MOUNT_BASE_DIR" || info_msg "Warning: Could not set permissions on '$MOUNT_BASE_DIR'."
     fi
    # Create the specific mount point directory
    mkdir -p "$mount_point" || error_exit "Failed to create mount point directory '$mount_point'."
    # Set ownership to the original user for easy access in file manager
    local user_id=$(id -u "$SUDO_USER")
    local group_id=$(id -g "$SUDO_USER")
    chown "$user_id:$group_id" "$mount_point" || info_msg "Warning: Could not set ownership on mount point '$mount_point'. Access might be restricted."


    info_msg "Mounting '/dev/mapper/$mapper_name' to '$mount_point'..."
    # Mount with options allowing the user RW access, especially for NTFS/FAT
    # Auto-detect filesystem type first. Add common types if needed.
    if mount -o "uid=$user_id,gid=$group_id,rw,users,exec,umask=007" "/dev/mapper/$mapper_name" "$mount_point"; then
         success_msg "Device mounted successfully at '$mount_point'."
         info_msg "It should now appear in your file manager's sidebar."
         # Optionally open the file manager (requires knowing the user's environment)
         # Example for GNOME/Nautilus (run as the user):
         # sudo -u $SUDO_USER xdg-open "$mount_point" &> /dev/null || true
    else
         local mount_status=$?
         error_msg "Failed to mount the device (exit code $mount_status)."
         # Cleanup on mount failure
         info_msg "Cleaning up..."
         cryptsetup bitlkClose "$mapper_name" || info_msg "Warning: Failed to close mapper '$mapper_name' after mount failure."
         rmdir "$mount_point" 2>/dev/null || info_msg "Warning: Could not remove empty mount point '$mount_point'."
         error_exit "Mounting failed. Device has been re-locked (if possible)."
         return 1 # Indicate failure
    fi
     return 0 # Indicate success
}


# --- Lock Function ---
function lock_bitlocker {
    echo "--- Lock BitLocker Drive ---"
    info_msg "Looking for active BitLocker mappings managed by this script..."

    # Find active mappers matching the script's naming convention
    local active_mappers=()
    local mapper_path="/dev/mapper/${MAPPER_PREFIX}"*
    # Check if the glob expands to anything other than the literal string
    shopt -s nullglob # Make glob return empty if no match
    local found_mappers=( $mapper_path )
    shopt -u nullglob # Restore glob behavior

    if [ ${#found_mappers[@]} -eq 0 ]; then
        info_msg "No active BitLocker devices found matching the pattern '/dev/mapper/${MAPPER_PREFIX}*'."
        info_msg "You might need to unlock a drive first, or it was mapped manually with a different name."
        return
    fi

    echo "Active BitLocker Mappings:"
    PS3="Select the number of the device to lock: "
    select mapper_fullpath in "${found_mappers[@]}"; do
        if [[ -n "$mapper_fullpath" ]]; then
            local mapper_name=$(basename "$mapper_fullpath")
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    # Derive potential mount point from mapper name
    # Note: This assumes the script's naming convention was used for mounting
    local potential_mount_point="${MOUNT_BASE_DIR}/${mapper_name}"

    # Find the actual mount point using findmnt (more reliable)
    local mount_point=$(findmnt -n -o TARGET --source "$mapper_fullpath")

    if [ -z "$mount_point" ]; then
        info_msg "Mapper '$mapper_name' exists but does not seem to be mounted."
        read -p "Do you want to attempt to close the mapper anyway? (y/N): " confirm_close
        if [[ ! "$confirm_close" =~ ^[Yy]$ ]]; then
            info_msg "Aborting lock operation."
            return
        fi
        # Proceed directly to closing the mapper
    else
        info_msg "Found mount point '$mount_point' for '$mapper_name'."
        info_msg "Attempting to unmount '$mount_point'..."
        if umount "$mount_point"; then
            success_msg "Unmounted successfully."

             # Attempt to remove the mount point directory if it's empty
             if rmdir "$mount_point" 2>/dev/null; then
                 success_msg "Removed empty mount point directory '$mount_point'."
             else
                 info_msg "Mount point directory '$mount_point' could not be removed (might not be empty or permissions issue)."
             fi
        else
            local umount_status=$?
            error_exit "Failed to unmount '$mount_point' (exit code $umount_status). Check if files are in use. Cannot proceed with locking."
            return 1 # Indicate failure
        fi
    fi

    # Close the BitLocker mapper device
    info_msg "Attempting to close (lock) the mapper '/dev/mapper/$mapper_name'..."
    if cryptsetup bitlkClose "$mapper_name"; then
        success_msg "Mapper '/dev/mapper/$mapper_name' closed successfully. Drive is locked."
    else
        local crypt_status=$?
        error_exit "Failed to close mapper '$mapper_name' (exit code $crypt_status)."
        return 1 # Indicate failure
    fi
     return 0 # Indicate success
}


# --- Main Menu ---
echo "==============================="
echo " BitLocker Drive Manager"
echo "==============================="
echo " Base Mount Directory: $MOUNT_BASE_DIR"
echo " User for Permissions: $SUDO_USER"
echo "-------------------------------"

PS3="Choose an option (1-3): "
options=("Unlock (Mount) a BitLocker Drive" "Lock (Unmount) an Active Drive" "Exit")

select opt in "${options[@]}"; do
    case $REPLY in
        1)
            unlock_bitlocker
            break # Break after function call to show menu again unless exit
            ;;
        2)
            lock_bitlocker
            break # Break after function call
            ;;
        3)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option '$REPLY'. Please choose 1, 2, or 3."
            ;;
    esac
    # Prompt again after an action
    echo ""
    echo "-------------------------------"
    # Need to manually re-display the menu options within the loop if 'break' is removed
    # for i in "${!options[@]}"; do printf "%d) %s\n" $((i+1)) "${options[i]}"; done

done # The 'select' statement itself handles the looping prompt

# Fallback exit if loop somehow terminates without explicit exit
exit 0
