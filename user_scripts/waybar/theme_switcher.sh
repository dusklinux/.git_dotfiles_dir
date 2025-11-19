#!/bin/bash

# ==============================================================================
# Hyprland Theme Switcher
# ==============================================================================
#
# Description:
#   Unifies theme switching logic for Hyprland components.
#   - Toggles GTK Theme (gsettings)
#   - Updates Waypaper configuration
#   - Updates SWWW randomization script
#   - Generates and applies Matugen colors based on the current wallpaper
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
readonly MATUGEN_CMD="matugen"

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
check_dependency "matugen"

if [[ ! -f "$WAYPAPER_CONFIG" ]]; then
    log_error "Waypaper config not found: $WAYPAPER_CONFIG"
    exit 1
fi

if [[ ! -f "$SWWW_SCRIPT" ]]; then
    log_error "SWWW script not found: $SWWW_SCRIPT"
    exit 1
fi

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
# We use a flexible regex to capture whatever mode was previously set
log_info "Updating Waypaper configuration..."
sed -i "s/post_command = matugen --mode \(light\|dark\) image \$wallpaper/post_command = matugen --mode $MODE image \$wallpaper/" "$WAYPAPER_CONFIG"

# 4. Update SWWW Script (theme_mode variable)
# Uses ^ and $ anchors to ensure we only edit the specific configuration line
log_info "Updating SWWW script configuration..."
sed -i "s/^readonly theme_mode=\".*\" # <-- SET THIS$/readonly theme_mode=\"$MODE\" # <-- SET THIS/" "$SWWW_SCRIPT"

# 5. Sync Filesystem
sync
sleep 0.2

# 6. Extract Wallpaper Path
# Using awk with '=' delimiter, handling potential whitespace around the equals sign
current_wallpaper_path=$(grep '^wallpaper[[:space:]]*=' "$WAYPAPER_CONFIG" | awk -F'=' '{print $2}' | xargs)

if [[ -z "$current_wallpaper_path" ]]; then
    log_error "Could not extract wallpaper path from config."
    exit 1
fi

# Expand tilde (~) to $HOME
current_wallpaper_path="${current_wallpaper_path/#\~/$HOME}"

if [[ ! -f "$current_wallpaper_path" ]]; then
    log_error "Wallpaper file missing at: $current_wallpaper_path"
    exit 1
fi

# 7. Apply Matugen Theme
log_info "Generating colors from: $(basename "$current_wallpaper_path")"

# Running Matugen
# We allow it to fail (|| true) but suppress only standard errors if desired.
# Removing '2>/dev/null' allows you to see errors if they happen, 
# but if you prefer silence, you can add it back.
# Currently set to suppress stderr to match original behavior but kept clean.
if matugen --mode "$MODE" image "$current_wallpaper_path" 2>/dev/null; then
    log_success "Matugen applied successfully."
else
    log_warn "Matugen command reported an issue (or produced no output), but continuing..."
fi

# 8. Wait for completion
log_info "Waiting for system propagation (2s)..."
sleep 2

log_success "Theme switched to ${MODE^^} successfully."
exit 0
