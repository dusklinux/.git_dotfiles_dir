#!/usr/bin/env bash
# Zram values for system swappiness 
# -----------------------------------------------------------------------------
# Description: Optimizes Kernel VM parameters for ZRAM on Arch/Hyprland
# Author:      DevOps Engineer (Arch/UWSM)
# Standards:   Bash 5+, strict mode, no backups, clean logging
# Logic:       Detects ZRAM -> Mode Menu -> Overwrites Config -> Reloads Sysctl
# -----------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
readonly CONFIG_FILE="/etc/sysctl.d/99-vm-zram-parameters.conf"

# --- Styling ---
readonly C_RESET=$'\033[0m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_RED=$'\033[1;31m'
readonly C_YELLOW=$'\033[1;33m'

log_info()    { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"; }
log_success() { printf "${C_GREEN}[OK]${C_RESET} %s\n" "$1"; }
log_warn()    { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$1"; }
log_error()   { printf "${C_RED}[ERROR]${C_RESET} %s\n" "$1" >&2; }

cleanup() {
    # Trap handler
    :
}
trap cleanup EXIT

# --- 1. Privilege Check ---
if [[ $EUID -ne 0 ]]; then
    log_info "Root privileges required. Escalating..."
    exec sudo "$0" "$@"
fi

# --- 2. ZRAM Detection ---
# Checking /proc/swaps is the most direct kernel interface method
if ! grep -q "^/dev/zram" /proc/swaps; then
    log_warn "No active ZRAM swap devices detected."
    log_info "Optimization aborted. Please enable ZRAM first."
    exit 0
fi

log_success "Active ZRAM device detected."

# --- 3. Mode Selection & Parameter Definition ---

# OPTION 1: Standard (Your original parameters)
read -r -d '' CONF_STANDARD <<EOF || true
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF

# OPTION 2: Aggressive (High RAM/Performance)
# TODO: EDIT THESE PARAMETERS AS NEEDED FOR YOUR SETUP
read -r -d '' CONF_AGGRESSIVE <<EOF || true
# --- ZRAM & SWAP BEHAVIOR ---
# Aggressively swap anonymous memory to ZRAM to free up space for page cache
vm.swappiness = 190
# ZRAM is non-rotational; disable read-ahead
vm.page-cluster = 0

# --- FILESYSTEM CACHE (The "Snappy" Factor) ---
# Retain dentry and inode caches strictly
vm.vfs_cache_pressure = 10
# Allow dirty data to stay in RAM for a bit, but flush in smooth streams
vm.dirty_bytes = 1073741824
vm.dirty_background_bytes = 268435456

# --- MEMORY ALLOCATION & COMPACTION ---
# Increase the reserve to prevent Direct Reclaim stutters
vm.watermark_scale_factor = 300
# Disable the boost factor as we have a static high scale factor
vm.watermark_boost_factor = 0
# Aggressively defragment memory for HugePages
vm.compaction_proactiveness = 50
# Reserve space for atomic operations (Network/DMA)
vm.min_free_kbytes = 131072

# --- APPLICATION COMPATIBILITY ---
# Prevent "map allocation failed" errors in heavy games/apps
vm.max_map_count = 2147483642
EOF

printf "${C_YELLOW}[?]${C_RESET} Select ZRAM Optimization Level:\n"
printf "    1) Standard (Balanced for typical Arch desktop)\n"
printf "    2) Aggressive (High Performance/High RAM utilization)\n"
printf "    3) Cancel\n"
printf "Choice [1/2/3]: "
read -r -n 1 selection
printf "\n"

# Variable to hold the final config content
selected_conf=""

case "$selection" in
    1)
        log_info "Selected: Standard Optimization."
        selected_conf="$CONF_STANDARD"
        ;;
    2)
        log_info "Selected: Aggressive Optimization."
        selected_conf="$CONF_AGGRESSIVE"
        ;;
    3)
        log_info "Operation cancelled by user."
        exit 0
        ;;
    *)
        log_error "Invalid selection."
        exit 1
        ;;
esac

# --- 4. Apply Configuration (Overwrite Mode) ---
if [[ -f "$CONFIG_FILE" ]]; then
    log_warn "File exists at ${CONFIG_FILE}. Overwriting entirely..."
else
    log_info "Creating new configuration at ${CONFIG_FILE}..."
fi

# Ensure directory exists
[[ -d "/etc/sysctl.d" ]] || mkdir -p "/etc/sysctl.d"

# Write the selected configuration
echo "$selected_conf" > "$CONFIG_FILE"

log_success "Configuration written."

# --- 5. Reload Kernel Parameters ---
log_info "Reloading sysctl parameters..."

# We use --load to specifically target this file and apply it immediately
if sysctl --load "$CONFIG_FILE" > /dev/null; then
    log_success "Kernel parameters optimized successfully."
else
    log_error "Failed to reload sysctl settings."
    exit 1
fi

exit 0
