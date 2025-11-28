#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Description: Optimizes Kernel VM parameters for ZRAM on Arch/Hyprland
# Author:      DevOps Engineer (Arch/UWSM)
# Standards:   Bash 5+, strict mode, no backups, clean logging
# Logic:       Detects ZRAM -> Prompts -> Overwrites Config -> Reloads Sysctl
# -----------------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
readonly CONFIG_FILE="/etc/sysctl.d/99-vm-zram-parameters.conf"

# --- Styling ---
readonly C_RESET='\033[0m'
readonly C_GREEN='\033[1;32m'
readonly C_BLUE='\033[1;34m'
readonly C_RED='\033[1;31m'
readonly C_YELLOW='\033[1;33m'

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

# --- 3. User Confirmation ---
printf "${C_YELLOW}[?]${C_RESET} Optimize kernel parameters for high-performance ZRAM? (Higher RAM usage) [y/N]: "
read -r -n 1 response
printf "\n"

if [[ ! "$response" =~ ^[yY]$ ]]; then
    log_info "Operation cancelled by user."
    exit 0
fi

# --- 4. Apply Configuration (Overwrite Mode) ---
if [[ -f "$CONFIG_FILE" ]]; then
    log_warn "File exists at ${CONFIG_FILE}. Overwriting entirely..."
else
    log_info "Creating new configuration at ${CONFIG_FILE}..."
fi

# Ensure directory exists
[[ -d "/etc/sysctl.d" ]] || mkdir -p "/etc/sysctl.d"

# 'cat >' truncates the file to 0 length before writing, ensuring a clean overwrite.
cat <<EOF > "$CONFIG_FILE"
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF

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
