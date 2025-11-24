#!/bin/bash

# ==============================================================================
#  UNIVERSAL DRIVE MANAGER (FSTAB NATIVE)
#  ------------------------------------------------------------------------------
#  Usage: ./drive_manager.sh [action] [target]
#  Example: ./drive_manager.sh unlock browser
# ==============================================================================

# ------------------------------------------------------------------------------
#  CONFIGURATION
# ------------------------------------------------------------------------------
# Define your drives below.
# Format: [name]="TYPE|MOUNTPOINT|OUTER_UUID|INNER_UUID|HINT"
#
# TYPE: 
#   PROTECTED : Encrypted (LUKS/BitLocker). Needs OUTER & INNER UUIDs.
#   SIMPLE    : Standard partition. UUIDs can be left empty.
#
# HINT (Optional):
#   Add a pipe | followed by your text at the end of the line.
#
# UUID GUIDE:
#   OUTER_UUID : The UUID of the raw partition (run `lsblk -f` while LOCKED).
#   INNER_UUID : The UUID of the filesystem inside (run `lsblk -f` while UNLOCKED).
#                This MUST match the UUID in your /etc/fstab.

# Dont touch this declare thing, It tells the script to create a "Dictionary" instead of a numbered list.
declare -A DRIVES

# --- DRIVE 1: BROWSER (Protected with Hint) ---
# Added hint example at the end
DRIVES["browser"]="PROTECTED|/mnt/browser|48182dde-f5ae-4878-bc15-fe60cf6cd271|9cab0013-8640-483a-b3f0-4587cfedb694|LAP_P"

# --- DRIVE 2: MEDIA (Protected - No Hint) ---
# This will work exactly as before (Hint is optional)
DRIVES["media"]="PROTECTED|/mnt/media|55d50d6d-a1ed-41d9-ba38-a6542eebbcd9|9C38076638073F30|LAP_P"

# --- DRIVE 3: WD_Passport_Slow (Protected with hint) ---
DRIVES["slow"]="PROTECTED|/mnt/slow|e15929e5-417f-4761-b478-55c9a7c24220|5A921A119219F26D|game_simple"

# --- DRIVE 4: WD_Passport_Fast (Protected with hint) ---
DRIVES["fast"]="SIMPLE|/mnt/fast|70EED6A1EED65F42|game_simple"

# --- DRIVE 5: WD_Book_Slow (Protected with hint) ---
DRIVES["wdslow"]="PROTECTED|/mnt/wdslow|01f38f5b-86de-4499-b93f-6c982e2067cb|2765359f-232e-4165-bc69-ef402b50c74c|game_simple"

# --- DRIVE 6: WD_Book_Fast (Protected with hint) ---
DRIVES["wdfast"]="PROTECTED|/mnt/wdfast|953a147e-a346-4fea-91f4-a81ec97fa56a|46798d3b-cda7-4031-818f-37a06abbeb37|game_simple"

# --- DRIVE 7: Enclosure HDD (Protected with hint) ---
DRIVES["enclosure"]="PROTECTED|/mnt/enclosure|bde4bde0-19f7-4ba9-a0f0-541fec19beb6|5A428B8A428B6A19|pass_p"

# ------------------------------------------------------------------------------
#  CORE LOGIC
# ------------------------------------------------------------------------------

# Visual Logging
log() { echo -e "\033[1;34m[DRIVE]\033[0m $1"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
# New function for displaying hints
print_hint() { echo -e "\033[1;33m[HINT]\033[0m  $1"; }

# 1. Parse Arguments
ACTION=$1
TARGET=$2

if [[ -z "$ACTION" || -z "$TARGET" ]]; then
    echo "Usage: $0 {lock|unlock} {name}"
    echo "Available: ${!DRIVES[@]}"
    exit 1
fi

# 2. Load Drive Config
if [[ -z "${DRIVES[$TARGET]}" ]]; then
    err "Drive '$TARGET' is not in the configuration."
    exit 1
fi

# Updated to read the optional HINT into a variable
IFS='|' read -r TYPE MOUNTPOINT OUTER_UUID INNER_UUID HINT <<< "${DRIVES[$TARGET]}"

# ------------------------------------------------------------------------------
#  UNLOCK FUNCTION
# ------------------------------------------------------------------------------
do_unlock() {
    log "Starting unlock process for $TARGET..."

    # Check if already mounted
    if mountpoint -q "$MOUNTPOINT"; then
        success "$TARGET is already mounted at $MOUNTPOINT."
        exit 0
    fi

    # Handle Encryption
    if [[ "$TYPE" == "PROTECTED" ]]; then
        OUTER_DEV="/dev/disk/by-uuid/$OUTER_UUID"
        INNER_DEV="/dev/disk/by-uuid/$INNER_UUID"

        # Sanity check: Does the physical disk exist?
        if [[ ! -b "$OUTER_DEV" ]]; then
            err "Physical drive ($OUTER_UUID) not found. Is it connected?"
            exit 1
        fi

        # Check if already unlocked (Inner UUID exists)
        if [[ -b "$INNER_DEV" ]]; then
            log "Container already unlocked (Filesystem found)."
        else
            log "Unlocking container..."
            
            # --- NEW: Display Hint if it exists ---
            if [[ -n "$HINT" ]]; then
                print_hint "$HINT"
            fi
            # --------------------------------------

            # Using udisksctl to handle the passphrase prompt via GUI (Hyprland compatible)
            while ! udisksctl unlock --block-device "$OUTER_DEV" >/dev/null 2>&1; do
                if ! pgrep -x "polkit-gnome-au|polkit-kde-auth|lxqt-policykit|mate-polkit|hyprpolkitagent" > /dev/null; then
                    err "Unlock failed. No Polkit agent found (needed for password prompt)."
                    exit 1
                fi
                log "Wrong password or cancelled. Retrying..."
                # Redisplay hint on retry for convenience
                if [[ -n "$HINT" ]]; then print_hint "$HINT"; fi
            done

            # CRITICAL: The Race Condition Fix
            # We must wait for the Inner UUID to appear before 'mount' can find it.
            log "Waiting for filesystem to initialize..."
            TIMEOUT=15
            ELAPSED=0
            while [[ ! -b "$INNER_DEV" ]]; do
                if [[ $ELAPSED -ge $TIMEOUT ]]; then
                    err "Timed out waiting for filesystem ($INNER_UUID) to appear."
                    exit 1
                fi
                sleep 1
                ((ELAPSED++))
            done
        fi
    fi

    # Mount using udisksctl (Preferred) or system fstab (Fallback)
    log "Mounting to $MOUNTPOINT..."
    
    # Determine the correct device UUID to mount
    # For Protected, we mount the Inner UUID. For Simple, we mount the Outer UUID.
    if [[ "$TYPE" == "PROTECTED" ]]; then
        MOUNT_DEV="/dev/disk/by-uuid/$INNER_UUID"
    else
        MOUNT_DEV="/dev/disk/by-uuid/$OUTER_UUID"
    fi

    # Attempt udisksctl first 
    # This uses the same Polkit auth as 'unlock', preventing a second password prompt in the terminal.
    # It will still respect the mountpoint defined in /etc/fstab.
    if udisksctl mount --block-device "$MOUNT_DEV" >/dev/null 2>&1; then
        success "$TARGET mounted successfully."
    # Fallback to sudo mount if udisksctl fails (e.g. if not in fstab)
    elif sudo mount "$MOUNTPOINT"; then
        success "$TARGET mounted successfully."
    else
        err "Mount command failed. Check your /etc/fstab settings."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
#  LOCK FUNCTION
# ------------------------------------------------------------------------------
do_lock() {
    log "Starting lock process for $TARGET..."

    # 1. Unmount (Universal)
    # We use 'sudo umount' because it handles BTRFS subvolumes (e.g. /mnt/media[/@]) correctly.
    if mountpoint -q "$MOUNTPOINT"; then
        log "Unmounting $MOUNTPOINT..."
        if ! sudo umount "$MOUNTPOINT"; then
            err "Failed to unmount. Is a terminal or app using the drive?"
            exit 1
        fi
        log "Unmount successful."
    else
        log "$MOUNTPOINT was not mounted."
    fi

    # 2. Lock Container (Protected Only)
    if [[ "$TYPE" == "PROTECTED" ]]; then
        OUTER_DEV="/dev/disk/by-uuid/$OUTER_UUID"
        
        # Double check: Ensure the mapper is actually gone before locking
        # If BTRFS is slow to sync, locking immediately might fail.
        sync
        
        log "Locking encrypted container..."
        if udisksctl lock --block-device "$OUTER_DEV" >/dev/null 2>&1; then
            success "Encrypted container locked."
        else
            # Error handling: Check if it's already locked
            # We look for 'crypt' holders on the device
            if lsblk -n --output NAME "$OUTER_DEV" | grep -q "crypt"; then
                err "Failed to lock. Device is still busy/open."
                exit 1
            else
                success "Container was already locked."
            fi
        fi
    else
        success "Simple drive unmounted."
    fi
}

# ------------------------------------------------------------------------------
#  MAIN
# ------------------------------------------------------------------------------
case "$ACTION" in
    unlock) do_unlock ;;
    lock)   do_lock ;;
    *)      echo "Usage: $0 {lock|unlock} {name}"; exit 1 ;;
esac
