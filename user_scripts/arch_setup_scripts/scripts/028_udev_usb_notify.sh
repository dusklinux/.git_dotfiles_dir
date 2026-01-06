#!/usr/bin/env bash
# sets up USB audio cues for connecting/discconnecting usb devices
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────────────────────
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly BLUE=$'\033[0;34m'
readonly NC=$'\033[0m'

log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
log_error()   { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

# ─────────────────────────────────────────────────────────────
# Root Check (re-execute with sudo if needed)
# ─────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    log_info "Elevating to root..."
    exec sudo bash "$0" "$@"
fi

# ─────────────────────────────────────────────────────────────
# Resolve Original User
# ─────────────────────────────────────────────────────────────
if [[ -z "${SUDO_USER:-}" ]]; then
    log_error "Cannot determine original user. Run without sudo."
    exit 1
fi

readonly USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
readonly SOURCE_SCRIPT="${USER_HOME}/user_scripts/external/usb_sound.sh"
readonly UDEV_RULE_FILE="/etc/udev/rules.d/90-usb-sound.rules"

readonly UDEV_RULE_CONTENT='ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="/usr/local/bin/usb_sound.sh connect"
ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="/usr/local/bin/usb_sound.sh disconnect"'

# ─────────────────────────────────────────────────────────────
# Verify Source Exists
# ─────────────────────────────────────────────────────────────
if [[ ! -f "$SOURCE_SCRIPT" ]]; then
    log_error "Source script not found: $SOURCE_SCRIPT"
    exit 1
fi

# ─────────────────────────────────────────────────────────────
# Step 1: Set Permissions
# ─────────────────────────────────────────────────────────────
log_info "Setting permissions on source script..."
chmod 755 "$SOURCE_SCRIPT"
log_success "Permissions set (755)"

# ─────────────────────────────────────────────────────────────
# Step 2: Create Symlink
# ─────────────────────────────────────────────────────────────
log_info "Creating symlink..."
ln -nfs "$SOURCE_SCRIPT" /usr/local/bin/
log_success "Symlink created"

# ─────────────────────────────────────────────────────────────
# Step 3: Write Udev Rule
# ─────────────────────────────────────────────────────────────
log_info "Writing udev rule..."
printf '%s\n' "$UDEV_RULE_CONTENT" > "$UDEV_RULE_FILE"
log_success "Udev rule written"

# ─────────────────────────────────────────────────────────────
# Step 4: Reload Udev Rules
# ─────────────────────────────────────────────────────────────
log_info "Reloading udev rules..."
udevadm control --reload-rules
log_success "Udev rules reloaded"

log_success "Setup complete!"
