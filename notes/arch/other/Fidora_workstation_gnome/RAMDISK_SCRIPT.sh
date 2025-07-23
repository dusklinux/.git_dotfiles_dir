#!/bin/bash

# --- Configuration ---
MOUNT_POINT="/mnt/ramdisk"
FSTAB_FILE="/etc/fstab"
SCRIPT_NAME=$(basename "$0")

# --- Helper Functions ---

# Function to print messages
echoinfo() {
    echo "[INFO] $1"
}

echowarn() {
    echo "[WARN] $1"
}

echoerror() {
    echo "[ERROR] $1" >&2
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echoerror "This script must be run as root or with sudo."
        exit 1
    fi
}

# Function to parse size string (e.g., 512M, 2G) and return size in MB and GB
# Returns values in global variables: SIZE_MB, SIZE_GB, SIZE_FSTAB
parse_size() {
    local input_size=$1
    local size_num
    local size_unit

    # Regex to extract number and unit (M/m or G/g)
    if [[ ! "$input_size" =~ ^([0-9]+)([MGmg])$ ]]; then
        echoerror "Invalid size format. Use numbers followed by M (for MB) or G (for GB). Example: 512M, 2G"
        return 1
    fi

    size_num=${BASH_REMATCH[1]}
    size_unit=$(echo "${BASH_REMATCH[2]}" | tr 'mg' 'MG') # Uppercase unit

    if [[ "$size_unit" == "M" ]]; then
        SIZE_MB=$size_num
        # Using floating point for GB calculation (bc required)
        if command -v bc &>/dev/null; then
            SIZE_GB=$(bc <<< "scale=2; $size_num / 1024")
        else
            SIZE_GB="N/A (bc not installed)" # Fallback if bc isn't available
        fi
        SIZE_FSTAB="${size_num}M"
    elif [[ "$size_unit" == "G" ]]; then
        # Using floating point for MB calculation (bc required)
         if command -v bc &>/dev/null; then
            SIZE_MB=$(bc <<< "scale=0; $size_num * 1024 / 1") # Integer MB
        else
            SIZE_MB="N/A (bc not installed)" # Fallback if bc isn't available
        fi
        SIZE_GB=$size_num
        SIZE_FSTAB="${size_num}G"
    else
        # This case should not be reached due to regex, but added for safety
        echoerror "Internal error: Invalid size unit detected after regex."
        return 1
    fi

    # Check if number is valid
    if [[ ! "$size_num" =~ ^[0-9]+$ ]] || [[ "$size_num" -le 0 ]]; then
        echoerror "Invalid size number: '$size_num'. Must be a positive integer."
        return 1
    fi

    return 0
}

# Function to check if the mount point is already in fstab
check_fstab() {
    grep -q " $MOUNT_POINT .* tmpfs " "$FSTAB_FILE"
}

# Function to check if the mount point is currently mounted
check_mount() {
    mountpoint -q "$MOUNT_POINT"
}

# --- Main Actions ---

# Function to create and mount the ramdisk
create_ramdisk() {
    echoinfo "Starting Ramdisk Creation..."

    # 1. Check if already configured or mounted
    if check_fstab; then
        echoerror "Ramdisk entry already found in $FSTAB_FILE for $MOUNT_POINT."
        echoinfo "If you want to change the size, remove the existing ramdisk first."
        return 1
    fi
    if check_mount; then
        echowarn "$MOUNT_POINT is already mounted. Unmounting before proceeding might be needed if it's not the expected tmpfs."
        # Add logic here if you want to automatically unmount or handle this differently
    fi

    # 2. Prompt for size
    local desired_size=""
    while true; do
        read -p "Enter desired ramdisk size (e.g., 512M for 512MB, 2G for 2GB): " desired_size
        if parse_size "$desired_size"; then
            break # Exit loop if parsing is successful
        fi
        # If parse_size failed, it prints an error, loop continues
    done

    # 3. Confirm size
    echoinfo "You requested a size for the ramdisk:"
    echoinfo " -> In Megabytes (MB): $SIZE_MB"
    echoinfo " -> In Gigabytes (GB): $SIZE_GB"
    echoinfo " -> fstab entry size: $SIZE_FSTAB"

    local confirmation=""
    read -p "Proceed with creating ramdisk of size $SIZE_FSTAB? (y/N): " confirmation
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echoinfo "Ramdisk creation cancelled by user."
        return 1
    fi

    # 4. Create mount point directory
    echoinfo "Creating mount point directory: $MOUNT_POINT"
    if ! mkdir -p "$MOUNT_POINT"; then
        echoerror "Failed to create mount point directory $MOUNT_POINT."
        return 1
    fi
    chmod 1777 "$MOUNT_POINT" # Set permissions similar to /tmp (sticky bit)

    # 5. Backup fstab
    local backup_fstab="${FSTAB_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
    echoinfo "Backing up $FSTAB_FILE to $backup_fstab"
    if ! cp "$FSTAB_FILE" "$backup_fstab"; then
        echoerror "Failed to backup $FSTAB_FILE. Aborting."
        # Clean up created directory if backup fails
        rmdir "$MOUNT_POINT" &>/dev/null
        return 1
    fi

    # 6. Add entry to fstab for persistence
    local fstab_entry="tmpfs $MOUNT_POINT tmpfs defaults,size=$SIZE_FSTAB,mode=1777,noatime,comment=x-gvfs-show 0 0"
    echoinfo "Adding the following entry to $FSTAB_FILE:"
    echo " -> $fstab_entry"
    if ! echo "$fstab_entry" >> "$FSTAB_FILE"; then
        echoerror "Failed to add entry to $FSTAB_FILE."
        echoinfo "Restoring $FSTAB_FILE from backup: $backup_fstab"
        cp "$backup_fstab" "$FSTAB_FILE"
         # Clean up created directory if add fails
        rmdir "$MOUNT_POINT" &>/dev/null
        return 1
    fi

    # 7. Mount the ramdisk
    echoinfo "Mounting the ramdisk: mount $MOUNT_POINT"
    if ! mount "$MOUNT_POINT"; then
        echoerror "Failed to mount $MOUNT_POINT. Check system logs ('journalctl -n 50') or dmesg."
        echowarn "The fstab entry was added, but mounting failed. You might need to manually resolve this or remove the entry."
        # Consider reverting fstab change here if mount fails? More complex recovery.
        return 1
    fi

    # 8. Verify mount
    if check_mount; then
        echoinfo "Ramdisk successfully created, added to fstab, and mounted at $MOUNT_POINT."
        echoinfo "It will persist across reboots."
        df -h "$MOUNT_POINT" # Show disk usage for confirmation
    else
        echoerror "Mount verification failed for $MOUNT_POINT after attempting mount."
        return 1
    fi

    return 0
}

# Function to benchmark the ramdisk
benchmark_ramdisk() {
    echoinfo "Starting Ramdisk Benchmark..."

    # 1. Check if mounted
    if ! check_mount; then
        echoerror "Ramdisk $MOUNT_POINT is not mounted. Cannot perform benchmark."
        echoinfo "Please create or mount the ramdisk first."
        return 1
    fi
    # Verify it's tmpfs
    if ! mount | grep -q " on $MOUNT_POINT type tmpfs "; then
         echoerror "$MOUNT_POINT is mounted, but it doesn't appear to be a tmpfs filesystem."
         return 1
    fi

    # 2. Prompt for test file size
    local test_size_str=""
    local test_size_bytes=0
    local block_size="1M" # Use 1MB blocks for dd
    local count=0
    while true; do
        read -p "Enter test file size (e.g., 1G, 256M): " test_size_str
        if [[ "$test_size_str" =~ ^([0-9]+)([MGmg])$ ]]; then
            local num=${BASH_REMATCH[1]}
            local unit=$(echo "${BASH_REMATCH[2]}" | tr 'mg' 'MG')
            if [[ "$unit" == "M" ]]; then
                count=$num
                test_size_bytes=$(( num * 1024 * 1024 ))
                break
            elif [[ "$unit" == "G" ]]; then
                count=$(( num * 1024 ))
                test_size_bytes=$(( num * 1024 * 1024 * 1024 ))
                break
            fi
        else
            echoerror "Invalid format. Use numbers followed by M or G (e.g., 1G, 256M)."
        fi
    done

    echoinfo "Benchmarking with test file size: ${test_size_str} (${count} blocks of ${block_size})"
    local test_file="$MOUNT_POINT/benchmark_tempfile"

    # Ensure enough space? Optional, dd will fail if not enough space.
    # available_space=$(df --output=avail -B 1 "$MOUNT_POINT" | tail -n 1)
    # if (( test_size_bytes > available_space )); then
    #     echoerror "Not enough free space on $MOUNT_POINT for a ${test_size_str} test file."
    #     return 1
    # fi

    # Cleanup old test file if exists
    rm -f "$test_file"

    # 3. Write Test
    echoinfo "Performing Write Test..."
    # Capture dd's stderr output which contains timing/speed info
    # Use oflag=direct to bypass cache for potentially more realistic throughput
    local write_output
    local start_time end_time write_time_s

    start_time=$(date +%s.%N)
    # We capture stderr to a variable. status=progress prints to stderr too.
    write_output=$(dd if=/dev/zero of="$test_file" bs=$block_size count=$count oflag=direct status=progress 2>&1)
    local write_status=$?
    end_time=$(date +%s.%N)
    write_time_s=$(bc <<< "scale=3; $end_time - $start_time")


    if [[ $write_status -ne 0 ]]; then
        echoerror "Write test failed (dd exit code: $write_status)."
        echo "dd output:"
        echo "$write_output"
        rm -f "$test_file" # Clean up partial file
        return 1
    fi

    # Extract speed info from dd output (example: ... 1.5 GB/s)
    # This regex tries to find the last number followed by unit/s (GB/s, MB/s etc)
    local write_speed_str=$(echo "$write_output" | grep -oE '[0-9.]+ ([KMG]B|Bytes)/s$' | tail -n 1)
     # Fallback: Calculate from bytes/time if parsing fails
    local write_bytes=$(echo "$write_output" | grep 'bytes' | head -n1 | awk '{print $1}')
    local write_speed_mbs=0
    local write_speed_gbs=0

    if [[ -n "$write_bytes" && "$write_bytes" -gt 0 && $(echo "$write_time_s > 0" | bc -l) -eq 1 ]]; then
         # Calculate in MB/s (10^6)
        write_speed_mbs=$(bc <<< "scale=2; $write_bytes / $write_time_s / 1000000")
        # Calculate in GB/s (10^9)
        write_speed_gbs=$(bc <<< "scale=2; $write_bytes / $write_time_s / 1000000000")
    fi

    echoinfo "Write Test Summary:"
    echoinfo " -> Time taken: ${write_time_s} seconds"
    echoinfo " -> Speed (calculated): ${write_speed_mbs} MB/s | ${write_speed_gbs} GB/s"
    [[ -n "$write_speed_str" ]] && echoinfo " -> Speed (reported by dd): ${write_speed_str}"


    # 4. Clear Page Cache (important for accurate read test)
    echoinfo "Clearing filesystem cache before read test..."
    sync
    if ! echo 3 > /proc/sys/vm/drop_caches; then
        echowarn "Failed to clear caches (might require root privileges even within sudo). Read speed might be inflated."
    fi
    sleep 1 # Give caches a moment to clear

    # 5. Read Test
    echoinfo "Performing Read Test..."
    local read_output
    start_time=$(date +%s.%N)
    # Use iflag=direct to bypass cache
    read_output=$(dd if="$test_file" of=/dev/null bs=$block_size iflag=direct status=progress 2>&1)
    local read_status=$?
    end_time=$(date +%s.%N)
    local read_time_s=$(bc <<< "scale=3; $end_time - $start_time")


    if [[ $read_status -ne 0 ]]; then
        echoerror "Read test failed (dd exit code: $read_status)."
        echo "dd output:"
        echo "$read_output"
        rm -f "$test_file"
        return 1
    fi

    # Extract speed info
    local read_speed_str=$(echo "$read_output" | grep -oE '[0-9.]+ ([KMG]B|Bytes)/s$' | tail -n 1)
    local read_bytes=$(echo "$read_output" | grep 'bytes' | head -n1 | awk '{print $1}') # Should match write_bytes
    local read_speed_mbs=0
    local read_speed_gbs=0

     if [[ -n "$read_bytes" && "$read_bytes" -gt 0 && $(echo "$read_time_s > 0" | bc -l) -eq 1 ]]; then
         # Calculate in MB/s (10^6)
        read_speed_mbs=$(bc <<< "scale=2; $read_bytes / $read_time_s / 1000000")
        # Calculate in GB/s (10^9)
        read_speed_gbs=$(bc <<< "scale=2; $read_bytes / $read_time_s / 1000000000")
    fi

    echoinfo "Read Test Summary:"
    echoinfo " -> Time taken: ${read_time_s} seconds"
    echoinfo " -> Speed (calculated): ${read_speed_mbs} MB/s | ${read_speed_gbs} GB/s"
     [[ -n "$read_speed_str" ]] && echoinfo " -> Speed (reported by dd): ${read_speed_str}"

    # 6. Cleanup
    echoinfo "Cleaning up test file: $test_file"
    rm -f "$test_file"

    echoinfo "Benchmark finished."
    return 0
}

# Function to remove the ramdisk and its configuration
remove_ramdisk() {
    echoinfo "Starting Ramdisk Removal..."

    local fstab_entry_found=false
    local mount_point_mounted=false

    if check_fstab; then
        fstab_entry_found=true
        echoinfo "Found ramdisk entry in $FSTAB_FILE."
    fi

    if check_mount; then
        mount_point_mounted=true
        echoinfo "Ramdisk is currently mounted at $MOUNT_POINT."
    fi

    if ! $fstab_entry_found && ! $mount_point_mounted; then
        echoinfo "No ramdisk configuration found in $FSTAB_FILE and $MOUNT_POINT is not mounted."
        echoinfo "Nothing to remove."
        # Check if mount point directory exists orphanedly
        if [[ -d "$MOUNT_POINT" ]]; then
            echowarn "Mount point directory $MOUNT_POINT exists but seems unused. You might want to remove it manually ('sudo rmdir $MOUNT_POINT')."
        fi
        return 0
    fi

    # Confirmation
    local confirmation=""
    read -p "This will unmount $MOUNT_POINT and remove its entry from $FSTAB_FILE. Continue? (y/N): " confirmation
     if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echoinfo "Ramdisk removal cancelled by user."
        return 1
    fi

    # 1. Unmount
    if $mount_point_mounted; then
        echoinfo "Unmounting $MOUNT_POINT..."
        if ! umount "$MOUNT_POINT"; then
            echoerror "Failed to unmount $MOUNT_POINT. It might be busy."
            echowarn "Attempting lazy unmount: umount -l $MOUNT_POINT"
            if ! umount -l "$MOUNT_POINT"; then
                 echoerror "Lazy unmount also failed. Please close any applications using $MOUNT_POINT and try again."
                 echoinfo "Cannot proceed with fstab removal while mount point is busy."
                 return 1
            else
                 echoinfo "Lazy unmount successful. Filesystem will detach when not busy."
            fi
        else
            echoinfo "$MOUNT_POINT unmounted successfully."
        fi
    fi

    # 2. Remove from fstab
    if $fstab_entry_found; then
        local backup_fstab="${FSTAB_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
        echoinfo "Backing up $FSTAB_FILE to $backup_fstab before modification."
        if ! cp "$FSTAB_FILE" "$backup_fstab"; then
            echoerror "Failed to backup $FSTAB_FILE. Aborting fstab modification."
            return 1
        fi

        echoinfo "Removing ramdisk entry from $FSTAB_FILE..."
        # Use sed to delete the line containing " /mnt/ramdisk " and " tmpfs "
        # Using a temporary file for safety before replacing original
        if ! sed "/ $MOUNT_POINT .* tmpfs /d" "$FSTAB_FILE" > "${FSTAB_FILE}.tmp"; then
            echoerror "Failed to process $FSTAB_FILE with sed."
            rm -f "${FSTAB_FILE}.tmp"
            return 1
        fi

        # Verify the tmp file looks okay (optional check: count lines?)
        if ! mv "${FSTAB_FILE}.tmp" "$FSTAB_FILE"; then
             echoerror "Failed to replace $FSTAB_FILE with the modified version."
             echoinfo "Attempting to restore backup $backup_fstab..."
             cp "$backup_fstab" "$FSTAB_FILE"
             return 1
        fi
        echoinfo "Successfully removed entry from $FSTAB_FILE."
    fi

    # 3. Remove mount point directory (only if it exists and is empty)
    if [[ -d "$MOUNT_POINT" ]]; then
       echoinfo "Removing mount point directory $MOUNT_POINT..."
        if ! rmdir "$MOUNT_POINT"; then
            # It might fail if unmount was lazy and still busy, or if user put files there manually after unmount
            echowarn "Could not remove directory $MOUNT_POINT. It might not be empty or still in use."
            echowarn "You may need to remove it manually later: sudo rmdir $MOUNT_POINT"
        else
            echoinfo "Mount point directory $MOUNT_POINT removed."
        fi
    fi

    echoinfo "Ramdisk removal process finished."
    return 0
}


# --- Main Script Execution ---

check_root

# Check for dependencies
if ! command -v bc &> /dev/null; then
    echowarn "'bc' command not found. Advanced calculations for GB/MB confirmation might not be precise."
    echowarn "Please install 'bc' (e.g., 'sudo dnf install bc')."
fi
if ! command -v dd &> /dev/null; then
    echoerror "'dd' command not found. Cannot perform benchmarks."
    echoerror "Please install 'coreutils' (usually installed by default)."
    exit 1
fi


# Main menu loop
while true; do
    echo "-------------------------------------"
    echo " Ramdisk Management Script "
    echo " Mount Point: $MOUNT_POINT"
    echo "-------------------------------------"
    echo "Choose an action:"
    echo " 1) Create Persistent Ramdisk"
    echo " 2) Benchmark Ramdisk ($MOUNT_POINT)"
    echo " 3) Remove Ramdisk"
    echo " 4) Exit"
    echo "-------------------------------------"
    read -p "Enter your choice [1-4]: " main_choice

    case $main_choice in
        1)
            create_ramdisk
            ;;
        2)
            benchmark_ramdisk
            ;;
        3)
            remove_ramdisk
            ;;
        4)
            echoinfo "Exiting script."
            exit 0
            ;;
        *)
            echoerror "Invalid choice. Please enter a number between 1 and 4."
            ;;
    esac
    echo # Add a newline for better readability before next menu display
    read -p "Press Enter to return to the main menu..."
    clear # Clear screen before showing menu again (optional)
done
