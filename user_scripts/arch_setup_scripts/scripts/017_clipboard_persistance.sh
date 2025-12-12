#!/usr/bin/env bash
# ==============================================================================
# ARCH LINUX / UWSM CLIPBOARD MANAGER
# Role: Elite DevOps Engineer
# Description: Toggles cliphist persistence in .config/uwsm/env
# Environment: Bash 5+, Hyprland, UWSM
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. STRICT MODE & ERROR HANDLING
# ------------------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

# Trap for cleanup (even though we keep it clean, good habit)
trap 'exit_code=$?; [[ $exit_code -ne 0 ]] && log_err "Script exited with error code $exit_code"; exit $exit_code' EXIT

# ------------------------------------------------------------------------------
# 2. STYLING & LOGGING
# ------------------------------------------------------------------------------
# UPDATED: Added $ for correct ANSI-C quoting
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly BLUE=$'\033[0;34m'
readonly YELLOW=$'\033[1;33m'
readonly BOLD=$'\033[1m'
readonly NC=$'\033[0m' # No Color

log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_err() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

# ------------------------------------------------------------------------------
# 3. PRIVILEGE CHECK
# ------------------------------------------------------------------------------
# ARCHITECT NOTE: We are editing ~/.config.
# Running as root is dangerous for file permissions. We enforce USER mode.
if [[ $EUID -eq 0 ]]; then
  log_err "Do NOT run this script as root/sudo."
  log_err "This script modifies your personal user configuration (~/.config)."
  log_err "Please run again as your normal user."
  exit 1
fi

# ------------------------------------------------------------------------------
# 4. CONFIGURATION
# ------------------------------------------------------------------------------
readonly CONFIG_DIR="${HOME}/.config/uwsm"
readonly CONFIG_FILE="${CONFIG_DIR}/env"
# The specific line we are targeting
readonly TARGET_LINE='export CLIPHIST_DB_PATH="${XDG_RUNTIME_DIR}/cliphist.db"'

# ------------------------------------------------------------------------------
# 5. PRE-FLIGHT CHECKS
# ------------------------------------------------------------------------------
if [[ ! -f "$CONFIG_FILE" ]]; then
  log_err "Configuration file not found at: ${CONFIG_FILE}"
  log_info "Please ensure UWSM is initialized and the path is correct."
  exit 1
fi

# ------------------------------------------------------------------------------
# 6. LOGIC CORE
# ------------------------------------------------------------------------------

update_config() {
  local mode="$1"

  # We use | as sed delimiter to avoid clashing with file paths in the string
  if [[ "$mode" == "ephemeral" ]]; then
    # Check if already uncommented (active)
    if grep -q "^${TARGET_LINE}" "$CONFIG_FILE"; then
      log_info "Config is already set to Ephemeral."
      return
    fi

    # Uncomment the line: Search for commented version, replace with active version
    # We allow for flexible whitespace after the #
    sed -i "s|^\s*#\s*export CLIPHIST_DB_PATH=.*|${TARGET_LINE}|" "$CONFIG_FILE"
    log_success "Set to Ephemeral. (Line uncommented)."

  elif [[ "$mode" == "persistent" ]]; then
    # Check if already commented (inactive)
    if grep -q "^\s*#\s*export CLIPHIST_DB_PATH" "$CONFIG_FILE"; then
      log_info "Config is already set to Persistent."
      return
    fi

    # Comment out the line
    sed -i "s|^export CLIPHIST_DB_PATH=.*|# ${TARGET_LINE}|" "$CONFIG_FILE"
    log_success "Set to Persistent. (Line commented out)."
  fi
}

# ------------------------------------------------------------------------------
# 7. USER INTERFACE
# ------------------------------------------------------------------------------
clear
printf "${BOLD}UWSM Clipboard Persistence Manager${NC}\n"
printf "Target: ${CONFIG_FILE}\n\n"

printf "${BOLD}Which mode do you prefer?${NC}\n\n"

printf "  ${BOLD}1) Ephemeral (RAM-based)${NC}\n"
printf "     - Clipboard history is stored in RAM.\n"
printf "     - It ${RED}disappears${NC} when you reboot or shutdown.\n"
printf "     - Good for privacy and saving disk writes.\n\n"

printf "  ${BOLD}2) Persistent (Disk-based)${NC}\n"
printf "     - Clipboard history is stored on your hard drive.\n"
printf "     - Your history ${GREEN}stays available${NC} even after you reboot.\n"
printf "     - Standard behavior for most users.\n\n"

# UPDATED: Prompt now indicates default and handles empty input
read -rp "Select option [1/2] (default: 1): " choice
choice="${choice:-1}"

case "$choice" in
1)
  log_info "Applying Ephemeral settings..."
  update_config "ephemeral"
  ;;
2)
  log_info "Applying Persistent settings..."
  update_config "persistent"
  ;;
*)
  log_err "Invalid selection. Exiting."
  exit 1
  ;;
esac

# ------------------------------------------------------------------------------
# 8. POST-PROCESS
# ------------------------------------------------------------------------------
# Check for UWSM presence to suggest reload
if command -v uwsm >/dev/null 2>&1; then
  printf "\n"
  log_info "Changes saved."
  log_info "To apply changes immediately, log out and back in, or restart at a later time."
else
  log_warn "uwsm command not found in PATH. Ensure you are in a UWSM session."
fi

# Reset trap before clean exit
trap - EXIT
exit 0
