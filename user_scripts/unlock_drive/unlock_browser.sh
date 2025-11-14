#!/bin/bash
#
# A script to unlock and mount a LUKS or BitLocker encrypted drive.
# Designed for use with a keybind in environments like Hyprland.
# Now using UUID for robust device identification.
#

# --- User-configurable variables ---
# The UUID of the encrypted partition to unlock.
# Find this by running `lsblk -f` or `sudo blkid` in your terminal.
DEVICE_UUID="48182dde-f5ae-4878-bc15-fe60cf6cd271"

# The mount point (e.g., a path defined in /etc/fstab)
MOUNT_POINT="/mnt/browser"
# --- End of configuration ---

# Construct the stable device path using the UUID
DEVICE_PATH="/dev/disk/by-uuid/$DEVICE_UUID"

# 1. Check if the device actually exists before we do anything.
if ! [ -b "$DEVICE_PATH" ]; then
    # You might want to use notify-send for a desktop notification
    echo "Error: Device with UUID $DEVICE_UUID not found."
    echo "Please check the UUID in the script or ensure the drive is connected."
    exit 1
fi

# 2. Check if the drive is already mounted. If so, exit gracefully.
if mountpoint -q "$MOUNT_POINT"; then
	echo "Device is already mounted at $MOUNT_POINT. Exiting."
    exit 0
fi

# 3. Attempt to unlock the drive, retrying on incorrect password.
# The user will be prompted by a graphical polkit agent until successful.
# stderr is redirected to /dev/null to suppress error messages from failed attempts.
echo "Attempting to unlock device..."
while ! UNLOCK_OUTPUT=$(udisksctl unlock --block-device "$DEVICE_PATH" 2>/dev/null); do
    # If the user cancels the password prompt, udisksctl returns a non-zero exit code.
    # We check if the command failed because of cancellation to avoid an infinite loop.
    if [ $? -ne 0 ] && ! pgrep -x "polkit-gnome-au|polkit-kde-auth|lxqt-policykit|mate-polkit" > /dev/null; then
        echo "Unlock cancelled by user or polkit agent not running. Exiting."
        exit 1
    fi
    # The colon ':' is a silent, efficient no-op, waiting for the next loop iteration.
    :
done

# 4. Handle slow drive: Wait for the unlocked device to become available.
# udisksctl output is "Unlocked /dev/sdX as /dev/dm-Y." We extract /dev/dm-Y.
UNLOCKED_DEVICE_PATH=$(echo "$UNLOCK_OUTPUT" | awk '{print $NF}' | tr -d '.')

echo "Device unlocked. Waiting for mapper path $UNLOCKED_DEVICE_PATH to appear..."
# Wait up to 15 seconds for the device mapper path to appear.
# This is more robust than a fixed 'sleep'.
TIMEOUT=15
ELAPSED=0
while [ ! -b "$UNLOCKED_DEVICE_PATH" ]; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "Timed out waiting for $UNLOCKED_DEVICE_PATH to become available."
        exit 1
    fi
    sleep 1
    ((ELAPSED++))
done

# 5. Mount the unlocked device using udisksctl. This avoids a sudo password prompt.
echo "Mounting $UNLOCKED_DEVICE_PATH..."
udisksctl mount --block-device "$UNLOCKED_DEVICE_PATH" --no-user-interaction > /dev/null

if mountpoint -q "$MOUNT_POINT"; then
    echo "Successfully mounted on $MOUNT_POINT."
else
    echo "Failed to mount the device."
    exit 1
fi

exit 0
