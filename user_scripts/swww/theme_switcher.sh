#!/bin/bash

# ==============================================================================
# Hyprland Theme Switcher
# ==============================================================================
#
# Description:
#   Unifies theme switching logic for Hyprland components.
#   - Toggles GTK Theme (gsettings)
#   - Updates Waypaper configuration
#   - Updates SWWW randomization script (sets mode)
#   - Triggers SWWW randomization script (applies new wallpaper + Matugen)
#
# Usage:
#   ./theme_switcher.sh -l | --light    Switch to Light theme
#   ./theme_switcher.sh -d | --dark     Switch to Dark theme
#   ./theme_switcher.sh -h | --help     Show help
#
# ==============================================================================

# --- Safe Execution Mode ---
set -o nounset    # Exit on undefined variables
set -o pipefail   # Catch pipe failures

# --- Bash Version Check ---
if ((BASH_VERSINFO[0] < 4)); then
    printf 'ERROR: Bash 4.0+ required. Current: %s\n' "$BASH_VERSION" >&2
    exit 1
fi

# --- Constants & Configuration ---
readonly WAYPAPER_CONFIG="${HOME}/.config/waypaper/config.ini"
readonly SWWW_SCRIPT="${HOME}/user_scripts/swww/swww_random_standalone.sh"
readonly SYMLINK_SCRIPT="${HOME}/user_scripts/swww/symlink_dark_light_directory.sh"

# ANSI Color Codes for Output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Exit status tracker
declare -i overall_status=0

# --- Helper Functions ---

log_info() {
    printf '%b[INFO]%b %s\n' "${BLUE}" "${NC}" "$1"
}

log_success() {
    printf '%b[OK]%b %s\n' "${GREEN}" "${NC}" "$1"
}

log_warn() {
    printf '%b[WARN]%b %s\n' "${YELLOW}" "${NC}" "$1" >&2
    overall_status=1
}

log_error() {
    printf '%b[ERROR]%b %s\n' "${RED}" "${NC}" "$1" >&2
    overall_status=1
}

check_dependency() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command '${cmd}' not found. Please install it."
        exit 1
    fi
}

usage() {
    cat <<-EOF
	Usage: $(basename "$0") [OPTION]
	
	Options:
	  -l, --light    Switch to Light theme
	  -d, --dark     Switch to Dark theme
	  -h, --help     Show this help message
	EOF
}

validate_file() {
    local filepath="$1"
    local desc="${2:-File}"

    if [[ ! -f "$filepath" ]]; then
        log_error "${desc} not found: ${filepath}"
        return 1
    fi
    if [[ ! -r "$filepath" ]]; then
        log_error "${desc} not readable: ${filepath}"
        return 1
    fi
    return 0
}

ensure_executable() {
    local filepath="$1"
    local desc="${2:-Script}"

    if ! validate_file "$filepath" "$desc"; then
        return 1
    fi
    if [[ ! -x "$filepath" ]]; then
        if ! chmod +x "$filepath" 2>/dev/null; then
            log_error "Cannot make ${desc} executable: ${filepath}"
            return 1
        fi
        log_info "Made ${desc} executable."
    fi
    return 0
}

kill_process_safely() {
    local proc_name="$1"
    local -i i

    # Check if process exists (suppress stderr for permission issues)
    if ! pgrep -x "$proc_name" &>/dev/null; then
        return 0
    fi

    log_info "Terminating ${proc_name}..."
    pkill -x "$proc_name" 2>/dev/null

    # Wait up to 2 seconds (20 iterations × 0.1s)
    for ((i = 0; i < 20; i++)); do
        if ! pgrep -x "$proc_name" &>/dev/null; then
            log_success "${proc_name} terminated gracefully."
            return 0
        fi
        sleep 0.1
    done

    # Force kill if still running
    if pgrep -x "$proc_name" &>/dev/null; then
        log_warn "${proc_name} did not exit gracefully, force killing..."
        pkill -9 -x "$proc_name" 2>/dev/null
        sleep 0.3
        
        if pgrep -x "$proc_name" &>/dev/null; then
            log_error "Failed to terminate ${proc_name}."
            return 1
        fi
    fi

    log_success "${proc_name} terminated."
    return 0
}

# --- Argument Parsing ---

if (($# == 0)); then
    log_error "No arguments provided."
    usage >&2
    exit 1
fi

# Warn about extra arguments
if (($# > 1)); then
    log_warn "Extra arguments ignored. Only processing: $1"
fi

MODE=""

case "$1" in
    -l|--light)
        MODE="light"
        ;;
    -d|--dark)
        MODE="dark"
        ;;
    -h|--help)
        usage
        exit 0  # Help exits successfully
        ;;
    *)
        log_error "Invalid argument: $1"
        usage >&2
        exit 1
        ;;
esac

log_info "Initializing theme switch to: ${GREEN}${MODE^^}${NC}"

# --- Pre-flight Checks ---

log_info "Running pre-flight checks..."

# Check required commands
check_dependency "gsettings"
check_dependency "sed"
check_dependency "pgrep"
check_dependency "pkill"
check_dependency "matugen"

# Validate files and scripts
validate_file "$WAYPAPER_CONFIG" "Waypaper config" || exit 1
ensure_executable "$SWWW_SCRIPT" "SWWW script" || exit 1
ensure_executable "$SYMLINK_SCRIPT" "Symlink script" || exit 1

log_success "Pre-flight checks passed."

# --- Core Logic ---

# 1. Set GTK Color Scheme
log_info "Setting GTK color scheme..."
if gsettings set org.gnome.desktop.interface color-scheme "prefer-${MODE}" 2>/dev/null; then
    log_success "GTK color scheme set to 'prefer-${MODE}'."
else
    log_warn "Failed to set GTK color scheme (gsettings may be unavailable)."
fi

# 2. Handle Waypaper Process
kill_process_safely "waypaper" || true  # Non-fatal

# 3. Update Waypaper Config
log_info "Updating Waypaper configuration..."

# Flexible pattern: handles variable whitespace around = and between args
if sed -i -E \
    "s/(post_command\s*=\s*matugen\s+--mode\s+)(light|dark)(\s+image)/\1${MODE}\3/" \
    "$WAYPAPER_CONFIG" 2>/dev/null; then
    
    # Verify the substitution took effect
    if grep -qE "post_command.*matugen.*--mode\s+${MODE}" "$WAYPAPER_CONFIG" 2>/dev/null; then
        log_success "Waypaper configuration updated."
    else
        log_warn "Waypaper config pattern not found or unchanged."
    fi
else
    log_error "Failed to modify Waypaper configuration."
fi

# 4. Update SWWW Script
log_info "Updating SWWW script configuration..."

if sed -i -E \
    "s/^(readonly\s+theme_mode=)\"[^\"]*\"/\1\"${MODE}\"/" \
    "$SWWW_SCRIPT" 2>/dev/null; then
    
    # Verify the substitution
    if grep -qE "^readonly\s+theme_mode=\"${MODE}\"" "$SWWW_SCRIPT" 2>/dev/null; then
        log_success "SWWW script configuration updated."
    else
        log_warn "SWWW script pattern not found or unchanged."
    fi
else
    log_error "Failed to modify SWWW script."
fi

# 5. Sync Filesystem (ensure changes are written)
log_info "Syncing filesystem..."
sync
sleep 0.2

# 6. Update Directory Symlinks
log_info "Updating wallpaper directory symlinks..."
if "$SYMLINK_SCRIPT" "--${MODE}"; then
    log_success "Symlinks updated to ${MODE} directory."
else
    log_error "Failed to update symlinks."
fi

# 7. Run SWWW Standalone Script
log_info "Executing SWWW randomization script..."
if "$SWWW_SCRIPT"; then
    log_success "SWWW script executed successfully."
else
    log_warn "SWWW script execution had issues (check script output above)."
fi

# 8. Brief propagation delay
log_info "Allowing system propagation (1s)..."
sleep 1

# --- Final Report ---

echo  # Blank line for readability

if ((overall_status == 0)); then
    log_success "Theme switched to ${MODE^^} successfully!"
else
    log_warn "Theme switch to ${MODE^^} completed with warnings. Review output above."
fi

exit "$overall_status"
