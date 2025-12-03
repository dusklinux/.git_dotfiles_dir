#!/usr/bin/env bash
# ==============================================================================
# Script Name: configure_zram.sh
# Description: Configures zram-generator dynamically based on available RAM.
#              - > 8 GiB RAM:  zram-size = ram - 2000
#              - <= 8 GiB RAM: zram-size = ram (full)
# Context:     Arch Linux Install (Chrooted Environment)
# ==============================================================================

# ------------------------------------------------------------------------------
# Strict Mode & Safety
# ------------------------------------------------------------------------------
set -euo pipefail

# ------------------------------------------------------------------------------
# Constants & Configuration
# ------------------------------------------------------------------------------
# 8 GiB in KiB (8 * 1024 * 1024)
readonly THRESHOLD_KB=8388608
readonly CONFIG_PATH="/etc/systemd/zram-generator.conf"
readonly MOUNT_TARGET="/mnt/zram1"

# ANSI Colors (using $'...' for immediate escape interpretation)
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly BLUE=$'\033[0;34m'
readonly NC=$'\033[0m' # No Color

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------
log_info()    { printf '%s[INFO]%s %s\n' "$BLUE" "$NC" "$*"; }
log_success() { printf '%s[SUCCESS]%s %s\n' "$GREEN" "$NC" "$*"; }
log_error()   { printf '%s[ERROR]%s %s\n' "$RED" "$NC" "$*" >&2; }

die() {
    log_error "$@"
    exit 1
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root (or inside the chroot)."
    fi
}

# Pure Bash function to read MemTotal from /proc/meminfo
# Eliminates the need for grep/awk subprocesses
get_total_ram_kb() {
    local key val unit
    if [[ ! -r /proc/meminfo ]]; then
        return 1
    fi

    while read -r key val unit; do
        if [[ "$key" == "MemTotal:" ]]; then
            echo "$val"
            return 0
        fi
    done < /proc/meminfo
    return 1
}

# ------------------------------------------------------------------------------
# Main Logic
# ------------------------------------------------------------------------------
main() {
    check_root

    log_info "Analyzing system memory..."
    sleep 1

    # 1. Get Memory (Pure Bash)
    local total_mem_kb
    total_mem_kb=$(get_total_ram_kb) || die "Could not read MemTotal from /proc/meminfo"

    # 2. Validate Integer
    if [[ ! "$total_mem_kb" =~ ^[0-9]+$ ]]; then
        die "Invalid memory value detected: $total_mem_kb"
    fi

    local total_mem_gb=$(( total_mem_kb / 1024 / 1024 ))

    # 3. Determine ZRAM Parameter
    # Logic: If > 8GB, reserve 2000MB. If <= 8GB, use full RAM.
    local zram_size_param=""
    
    if (( total_mem_kb > THRESHOLD_KB )); then
        zram_size_param="ram - 2000"
        log_info "Detected ${total_mem_gb}GB RAM (> 8GB). Setting size to 'ram - 2000'."
    else
        zram_size_param="ram"
        log_info "Detected ${total_mem_gb}GB RAM (<= 8GB). Setting size to full 'ram'."
    fi
    sleep 1

    # 4. Prepare Mount Point
    if [[ ! -d "$MOUNT_TARGET" ]]; then
        log_info "Creating mount point: $MOUNT_TARGET"
        mkdir -p "$MOUNT_TARGET"
        sleep 1
    else
        log_info "Mount point $MOUNT_TARGET already exists."
    fi

    # 5. Write Configuration Atomically
    log_info "Writing configuration to $CONFIG_PATH..."
    sleep 1

cat <<EOF > "$CONFIG_PATH"
[zram0]
zram-size = ${zram_size_param}
compression-algorithm = zstd

[zram1]
zram-size = ${zram_size_param}
fs-type = ext2
mount-point = ${MOUNT_TARGET}
compression-algorithm = zstd
options = rw,nosuid,nodev,discard,X-mount.mode=1777
EOF

    # 6. Verify Write
    if [[ -s "$CONFIG_PATH" ]]; then
        log_success "Zram configuration generated successfully."
        sleep 1
    else
        die "Failed to write configuration file."
    fi
}

# Execute
main
