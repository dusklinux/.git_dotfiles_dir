#!/bin/bash
#
# A script to unmount and lock a LUKS or BitLocker encrypted drive.
# Designed for use with a keybind in environments like Hyprland.
# It uses the device's UUID for robust identification.
#

# --- User-configurable variables ---
# The UUID of the encrypted partition to lock.
# This MUST match the UUID used in your unlock script.
# Find this by running `lsblk -f` or `sudo blkid`.
DEVICE_UUID="bde4bde0-19f7-4ba9-a0f0-541fec19beb6"

# The mount point (e.g., a path defined in /etc/fstab)
MOUNT_POINT="/mnt/enclosure"
# --- End of configuration ---

# Construct the stable device path using the UUID. This is the physical encrypted partition.
DEVICE_PATH="/dev/disk/by-uuid/$DEVICE_UUID"

# 1. Check if the underlying physical device exists before we do anything.
if ! [ -b "$DEVICE_PATH" ]; then
    echo "Error: Encrypted device with UUID $DEVICE_UUID not found."
    echo "Please check the UUID in the script or ensure the drive is connected."
    exit 1
fi

# 2. Check if the drive is actually mounted. If it's not, there's nothing to do.
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Device is not mounted at $MOUNT_POINT. Nothing to do."
    # We also check if the device is perhaps unlocked but not mounted.
    # If so, we should proceed to lock it.
    # We find the luks-opened device by looking up which device is held by the physical partition
    UNLOCKED_DEVICE_PATH=$(lsblk -no pkname "$DEVICE_PATH" | xargs -r -I {} find /dev/mapper -lname "*/{}")
    if [ -b "$UNLOCKED_DEVICE_PATH" ]; then
         echo "Device is unlocked but not mounted. Proceeding to lock."
    else
         exit 0
    fi
fi

# 3. Find the unlocked device mapper path (e.g., /dev/dm-0) from the mount point.
# This is the device we need to unmount.
if [ -z "$UNLOCKED_DEVICE_PATH" ]; then # Check if we found it in the previous step
    UNLOCKED_DEVICE_PATH=$(findmnt -n -o SOURCE --target "$MOUNT_POINT")
fi


if [ ! -b "$UNLOCKED_DEVICE_PATH" ]; then
    echo "Error: Could not determine the unlocked device path from mount point $MOUNT_POINT."
    echo "The device might be in an inconsistent state. Manual intervention may be required."
    exit 1
fi

# 4. Unmount the device using udisksctl.
# This avoids a direct sudo password prompt by using the system's polkit agent.
echo "Unmounting $UNLOCKED_DEVICE_PATH from $MOUNT_POINT..."
udisksctl unmount --block-device "$UNLOCKED_DEVICE_PATH" --no-user-interaction

# Give the system a moment to process the unmount operation.
sleep 1

# 5. Verify that the device has been unmounted successfully.
if mountpoint -q "$MOUNT_POINT"; then
    echo "Error: Failed to unmount the device from $MOUNT_POINT."
    echo "You may need to unmount it manually with 'sudo umount $MOUNT_POINT'."
    exit 1
else
    echo "Successfully unmounted from $MOUNT_POINT."
fi

# 6. Lock the original encrypted device.
# This will trigger a polkit prompt for a password if required.
echo "Locking the encrypted container at $DEVICE_PATH..."
if udisksctl lock --block-device "$DEVICE_PATH"; then
    echo "Successfully locked device."
else
    # This branch might be taken if the user cancels the password prompt.
    echo "Failed to lock the device. It may have already been locked or an error occurred."
    exit 1
fi

exit 0
