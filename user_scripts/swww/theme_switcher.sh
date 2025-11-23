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
#   ./theme_switcher.sh -light | --light | -l
#   ./theme_switcher.sh -dark  | --dark  | -d
#
# ==============================================================================

# --- Safe Execution Mode ---
set -u # Exit on undefined variables

# --- Constants & Configuration ---
readonly WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
readonly SWWW_SCRIPT="$HOME/user_scripts/swww/swww_random_standalone.sh"
readonly SYMLINK_SCRIPT="$HOME/user_scripts/swww/symlink_dark_light_directory.sh"

# ANSI Color Codes for Output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# --- Helper Functions ---

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Required command '$1' not found. Please install it."
        exit 1
    fi
}

usage() {
    echo "Usage: $(basename "$0") [OPTION]"
    echo "Options:"
    echo "  -l, --light    Switch to Light theme"
    echo "  -d, --dark     Switch to Dark theme"
    echo "  -h, --help     Show this help message"
    exit 1
}

kill_process_safely() {
    local proc_name="$1"
    
    if pgrep -x "$proc_name" > /dev/null; then
        log_info "Terminating $proc_name..."
        pkill -x "$proc_name"
        
        # Wait loop (max 2 seconds, checking every 0.1s)
        for _ in {1..20}; do
            if ! pgrep -x "$proc_name" > /dev/null; then
                log_success "$proc_name terminated gracefully."
                return 0
            fi
            sleep 0.1
        done

        # Force kill if still running
        if pgrep -x "$proc_name" > /dev/null; then
            log_warn "$proc_name did not exit, forcing kill..."
            pkill -9 -x "$proc_name"
            sleep 0.5
        fi
    fi
}

# --- Argument Parsing ---

if [[ $# -eq 0 ]]; then
    usage
fi

MODE=""

case "$1" in
    -l|--light|-light)
        MODE="light"
        ;;
    -d|--dark|-dark)
        MODE="dark"
        ;;
    -h|--help)
        usage
        ;;
    *)
        log_error "Invalid argument: $1"
        usage
        ;;
esac

log_info "Initializing switch to: ${GREEN}${MODE^^}${NC}"

# --- Pre-flight Checks ---

check_dependency "gsettings"
check_dependency "sed"
check_dependency "grep"
# Kept 'matugen' check to ensure system sanity, even though called in sub-script
check_dependency "matugen" 

if [[ ! -f "$WAYPAPER_CONFIG" ]]; then
    log_error "Waypaper config not found: $WAYPAPER_CONFIG"
    exit 1
fi

if [[ ! -f "$SWWW_SCRIPT" ]]; then
    log_error "SWWW script not found: $SWWW_SCRIPT"
    exit 1
fi

if [[ ! -f "$SYMLINK_SCRIPT" ]]; then
    log_error "Symlink script not found: $SYMLINK_SCRIPT"
    exit 1
fi
chmod +x "$SYMLINK_SCRIPT" # Ensure it is executable

# --- Core Logic ---

# 1. Set GTK Color Scheme
log_info "Setting GTK color scheme..."
if [[ "$MODE" == "light" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
fi

# 2. Handle Waypaper Process
kill_process_safely "waypaper"

# 3. Update Waypaper Config (post_command)
# This updates the config so if you run Waypaper manually later, it respects the last set mode.
log_info "Updating Waypaper configuration..."
sed -i "s/post_command = matugen --mode \(light\|dark\) image \$wallpaper/post_command = matugen --mode $MODE image \$wallpaper/" "$WAYPAPER_CONFIG"

# 4. Update SWWW Script (theme_mode variable)
# CRITICAL FIX: Adjusted regex to match the line even without the '# <-- SET THIS' comment
log_info "Updating SWWW script configuration..."
sed -i "s/^readonly theme_mode=\".*\"/readonly theme_mode=\"$MODE\"/" "$SWWW_SCRIPT"

# 5. Sync Filesystem
sync
sleep 0.2

# 5.5. Update Directory Symlinks
log_info "Updating wallpaper directory symlinks..."
# We pass --light or --dark using the $MODE variable we already have
if "$SYMLINK_SCRIPT" --"$MODE"; then
    log_success "Symlinks updated to directory: $MODE"
else
    log_error "Failed to update symlinks."
    # We do not exit here, so the rest of the theme switch can complete
fi

# 6. Run SWWW Standalone Script
# This script handles picking a random wallpaper and running matugen
log_info "Executing SWWW randomization script: $(basename "$SWWW_SCRIPT")"

if "$SWWW_SCRIPT"; then
    log_success "SWWW script executed successfully."
else
    log_warn "SWWW script execution encountered an issue."
fi

# 7. Wait for completion
log_info "Waiting for system propagation (2s)..."
sleep 2

log_success "Theme switched to ${MODE^^} successfully."
exit 0
