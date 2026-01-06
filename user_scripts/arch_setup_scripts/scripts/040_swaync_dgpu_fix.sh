#!/usr/bin/env bash
# systemd drop-in to force SwayNC to iGPU for power saving
# toggle-swaync-gpu
# Purpose: Toggles systemd drop-in to force SwayNC to iGPU for power saving.
# Context: Arch Linux / Hyprland / UWSM
#
# -----------------------------------------------------------------------------

# --- Strict Mode ---
set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
# The directory where systemd user overrides live
CONFIG_DIR="${HOME}/.config/systemd/user/swaync.service.d"
# The active configuration file (Systemd reads this)
ACTIVE_FILE="${CONFIG_DIR}/gpu-fix.conf"
# The disabled configuration file (Systemd ignores this)
BACKUP_FILE="${CONFIG_DIR}/gpu-fix.conf.bak"
# Service name
SERVICE="swaync.service"

# --- Styling ---
BOLD=$'\e[1m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
RED=$'\e[31m'
RESET=$'\e[0m'

# --- Helper Functions ---
log_info()    { printf "${BLUE}[INFO]${RESET} %s\n" "$1"; }
log_success() { printf "${GREEN}[OK]${RESET} %s\n" "$1"; }
log_err()     { printf "${RED}[ERROR]${RESET} %s\n" "$1" >&2; }

# --- Argument Parsing ---
AUTO_MODE=false
for arg in "$@"; do
  if [[ "$arg" == "--auto" ]]; then
    AUTO_MODE=true
  fi
done

# --- Logic ---

# 1. Validation: Ensure the directory exists
if [[ ! -d "$CONFIG_DIR" ]]; then
    log_err "Directory not found: $CONFIG_DIR"
    printf "Please create the directory and the initial 'gpu-fix.conf' file before running this script.\n"
    exit 1
fi

# 2. State Detection
if [[ -f "$ACTIVE_FILE" ]]; then
    CURRENT_STATE="ACTIVE"
    TARGET_ACTION="DISABLE"
elif [[ -f "$BACKUP_FILE" ]]; then
    CURRENT_STATE="DISABLED"
    TARGET_ACTION="ENABLE"
else
    log_err "No configuration file found (checked .conf and .conf.bak)."
    printf "Expected to find 'gpu-fix.conf' or 'gpu-fix.conf.bak' inside '%s'.\n" "$CONFIG_DIR"
    exit 1
fi

# 3. User Interaction
if [[ "$AUTO_MODE" == "true" ]]; then
    # In auto mode, we strictly want to DISABLE/DELETE the fix.
    # If it is currently ACTIVE, we proceed to disable it.
    # If it is currently DISABLED, we do nothing and exit.
    if [[ "$CURRENT_STATE" == "DISABLED" ]]; then
        log_success "Auto mode: Fix is already DISABLED. No changes made."
        exit 0
    fi
    
    printf "${BOLD}Current SwayNC GPU Fix State:${RESET} ${BLUE}%s${RESET}\n" "$CURRENT_STATE"
    log_info "Auto mode detected. Proceeding to $TARGET_ACTION fix..."
else
    printf "${BOLD}Current SwayNC GPU Fix State:${RESET} ${BLUE}%s${RESET}\n" "$CURRENT_STATE"
    read -r -p "$(printf "Do you want to ${BOLD}%s${RESET} the power saving fix? [y/N] " "$TARGET_ACTION")" CONFIRM

    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled by user."
        exit 0
    fi
fi

# 4. Execution
if [[ "$CURRENT_STATE" == "ACTIVE" ]]; then
    # Disable: Rename .conf -> .conf.bak
    mv --no-clobber "$ACTIVE_FILE" "$BACKUP_FILE"
    log_success "Configuration renamed to .bak (Fix Disabled)"
else
    # Enable: Rename .conf.bak -> .conf
    mv --no-clobber "$BACKUP_FILE" "$ACTIVE_FILE"
    log_success "Configuration renamed to .conf (Fix Enabled)"
fi

# 5. Systemd Reload & Restart
# We use --user because this is a user-session service
log_info "Reloading systemd user daemon..."
systemctl --user daemon-reload

log_info "Restarting $SERVICE..."
# FIX: Added '|| true' to prevent 'set -e' from killing the script if restart fails
systemctl --user restart "$SERVICE" || true

# 6. Verification
# We check if the service is active.
# Note: 'is-active' returns 0 if active, non-zero otherwise.
if systemctl --user is-active --quiet "$SERVICE"; then
    log_success "$SERVICE is up and running."
    
    # Optional: Visual confirmation of the environment (Advanced debugging)
    if [[ "$TARGET_ACTION" == "ENABLE" ]]; then
        PID=$(systemctl --user show --property MainPID --value "$SERVICE")
        if [[ "$PID" -ne 0 ]]; then
             printf "${BOLD}Applied Environment Check:${RESET}\n"
             xargs -0 -L1 -a "/proc/$PID/environ" 2>/dev/null | grep -E "WLR_DRM_DEVICES|AQ_DRM_DEVICES|rec_gpu_id" || true
        fi
    fi
else
    # FIX: Changed from 'exit 1' to 'exit 0' (and logging error).
    # This ensures the Orchestra script sees this as a "Success" even if SwayNC isn't running,
    # preventing the entire installation chain from aborting.
    log_err "$SERVICE failed to restart. Check 'journalctl --user -xeu $SERVICE'."
    log_info "Continuing orchestration regardless of service state."
    exit 0
fi
