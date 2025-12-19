#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Name:        matugen_config.sh
# Description: Configures Matugen via Rofi or CLI. Updates Waypaper, random_theme,
#              GTK Theme, and Wallpaper Directory Symlinks cleanly.
# -----------------------------------------------------------------------------
# Usage Instructions:
# This script supports both interactive (Rofi) and headless (CLI) modes.
#
# 1. Interactive Mode:
#    Run without arguments to launch the Rofi menu.
#    $ ./matugen_config.sh
#
# 2. CLI Mode (Headless):
#    Pass flags to skip the menu and apply settings directly.
#    Any omitted flag defaults to "standard" (Mode: Dark, Type: Disable, Contrast: Disable).
#
#    Flags:
#      --mode <dark|light>       : Sets the theme mode. (Default: dark)
#      --type <scheme>           : Sets the Matugen scheme type.
#                                  Options: scheme-content, scheme-expressive, scheme-fidelity,
#                                  scheme-fruit-salad, scheme-monochrome, scheme-neutral,
#                                  scheme-rainbow, scheme-tonal-spot, scheme-vibrant.
#      --contrast <value>        : Sets contrast (-1.0 to 1.0).
#                                  Increments of 0.2 (e.g., -0.8, 0.4). Use 0 or omit to disable.
#      --defaults                : Immediately applies default settings (Dark, No Type, No Contrast).
#      -h, --help                : Show this help message.
#
#    Examples:
#      ./matugen_config.sh --mode light --type scheme-fruit-salad
#      ./matugen_config.sh --mode dark --contrast 0.4
#      ./matugen_config.sh --defaults

# -----------------------------------------------------------------------------
# Name:        matugen_config.sh
# Description: Centralized configuration bridge for the Matugen wallpaper color 
#              generator within a Hyprland/UWSM environment.
#
# Functionality:
#   1. Input Resolution:
#      - Interactive: Launches a hierarchical Rofi menu to select Mode (Light/Dark),
#        Type (Scheme), and Contrast variables if no arguments are passed.
#      - Headless (CLI): Accepts flags (--mode, --type, --contrast, --defaults)
#        for automated execution via keybinds or external scripts.
#
#   2. Process Safety & State Management:
#      - Gracefully terminates running 'waypaper' instances (SIGTERM -> wait -> SIGKILL)
#        to prevent configuration overwrite race conditions during file edits.
#
#   3. Configuration Injection (Persistence):
#      - Constructs a specific argument string (e.g., "-m dark -t scheme-fruit-salad")
#        based on inputs.
#      - Uses 'sed' to inject this string into the 'post_command' of 
#        ~/.config/waypaper/config.ini.
#      - Uses 'sed' to inject the same string into the 'uwsm-app' call within 
#        ~/user_scripts/theme_matugen/random_theme.sh.
#
#   4. Environment Synchronization:
#      - GTK: Updates 'org.gnome.desktop.interface color-scheme' via gsettings
#        to match the selected mode (prefer-dark/prefer-light).
#      - Filesystem: Triggers 'symlink_dark_light_directory.sh' to repoint 
#        wallpaper source directories based on the selected mode.
#
#   5. Execution:
#      - Syncs filesystem buffers.
#      - Chains execution (exec) to 'random_theme.sh' to immediately generate
#        the theme and refresh the wallpaper without forking a new shell.
#
# Usage:
#   $ ./matugen_config.sh                      # Rofi Menu
#   $ ./matugen_config.sh --mode light --defaults
#   $ ./matugen_config.sh --mode dark --type scheme-vibrant --contrast 0.4
# -----------------------------------------------------------------------------

# --- Safety & Environment ---
set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
readonly WAYPAPER_CONFIG="${HOME}/.config/waypaper/config.ini"
readonly RANDOM_THEME="${HOME}/user_scripts/theme_matugen/random_theme.sh"
readonly SYMLINK_SCRIPT="${HOME}/user_scripts/theme_matugen/dark_light_directory_switch.sh"

# Colors for logging
readonly C_RESET=$'\033[0m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_RED=$'\033[1;31m'

# --- Defaults ---
DEFAULT_MODE="dark"
DEFAULT_TYPE="disable"
DEFAULT_CONTRAST="disable"

# Global variables
TARGET_MODE="$DEFAULT_MODE"
TARGET_TYPE="$DEFAULT_TYPE"
TARGET_CONTRAST="$DEFAULT_CONTRAST"

# --- Functions ---

log_info() { printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"; }
log_succ() { printf "${C_GREEN}[OK]${C_RESET}   %s\n" "$1"; }
log_err()  { printf "${C_RED}[ERR]${C_RESET}  %s\n" "$1" >&2; }

cleanup() {
    if [[ $? -ne 0 ]]; then
        log_err "Script exited with errors."
    fi
}
trap cleanup EXIT

rofi_menu() {
    local prompt="$1"
    local options="$2"
    echo -e "$options" | rofi -dmenu -i -p "$prompt"
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
            log_succ "${proc_name} terminated gracefully."
            return 0
        fi
        sleep 0.1
    done

    # Force kill if still running
    if pgrep -x "$proc_name" &>/dev/null; then
        log_err "${proc_name} did not exit gracefully, force killing..."
        pkill -9 -x "$proc_name" 2>/dev/null
        sleep 0.3
    fi

    log_succ "${proc_name} terminated."
}

# --- Parsing Logic ---

usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo "If no options are provided, launches Rofi menu."
    echo
    echo "Options:"
    echo "  --mode <dark|light>      Set theme mode (Default: dark)"
    echo "  --type <scheme>          Set scheme type (Default: disabled)"
    echo "  --contrast <val>         Set contrast -1.0 to 1.0 (Default: disabled)"
    echo "  --defaults               Run immediately with full defaults"
    echo "  -h, --help               Show this help"
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)     TARGET_MODE="$2"; shift 2 ;;
            --type)     TARGET_TYPE="$2"; shift 2 ;;
            --contrast) TARGET_CONTRAST="$2"; shift 2 ;;
            --defaults) shift ;; # Defaults are already set
            -h|--help)  usage ;;
            *)          log_err "Unknown option: $1"; usage ;;
        esac
    done
}

run_rofi_mode() {
    log_info "No arguments provided. Starting Rofi mode..."

    # 1. Select Mode
    local sel_mode
    sel_mode=$(rofi_menu "Matugen Mode" "dark\nlight")
    [[ -z "$sel_mode" ]] && exit 0
    TARGET_MODE="$sel_mode"

    # 2. Select Type
    local types_list="disable
scheme-content
scheme-expressive
scheme-fidelity
scheme-fruit-salad
scheme-monochrome
scheme-neutral
scheme-rainbow
scheme-tonal-spot
scheme-vibrant"
    
    local sel_type
    sel_type=$(rofi_menu "Matugen Type" "$types_list")
    [[ -z "$sel_type" ]] && exit 0
    TARGET_TYPE="$sel_type"

    # 3. Select Contrast (0.2 increments, excluding 0)
    local contrast_list="disable
-1.0
-0.8
-0.6
-0.4
-0.2
0.2
0.4
0.6
0.8
1.0"

    local sel_contrast
    sel_contrast=$(rofi_menu "Matugen Contrast" "$contrast_list")
    [[ -z "$sel_contrast" ]] && exit 0
    TARGET_CONTRAST="$sel_contrast"
}

# --- Main Execution ---

# 1. Decision: CLI or Rofi?
if [[ $# -gt 0 ]]; then
    parse_args "$@"
    log_info "Running in CLI Mode."
else
    run_rofi_mode
fi

# 2. Validation
if [[ ! -f "$WAYPAPER_CONFIG" ]]; then
    log_err "Waypaper config not found at: $WAYPAPER_CONFIG"
    exit 1
fi
if [[ ! -x "$RANDOM_THEME" ]]; then
    log_err "random_theme script not executable or found at: $RANDOM_THEME"
    exit 1
fi
if [[ ! -x "$SYMLINK_SCRIPT" ]]; then
    log_err "Symlink script not executable or found at: $SYMLINK_SCRIPT"
    exit 1
fi

# 3. Safety: Kill Waypaper to prevent config overwrite
kill_process_safely "waypaper"

# 4. Build Flag String
build_flags="--mode $TARGET_MODE"

if [[ "$TARGET_TYPE" != "disable" ]]; then
    build_flags+=" --type $TARGET_TYPE"
fi

if [[ "$TARGET_CONTRAST" != "disable" ]]; then
    build_flags+=" --contrast $TARGET_CONTRAST"
fi

log_info "Configuration: $build_flags"

# 5. Apply Configuration (sed)

# A. Update Waypaper Config
log_info "Updating Waypaper configuration..."
sed -i "s|^post_command = matugen .* image \$wallpaper$|post_command = matugen $build_flags image \$wallpaper|" "$WAYPAPER_CONFIG"

# B. Update random_theme Randomization Script
log_info "Updating random_theme script flags..."
sed -i "s|^\s*setsid uwsm-app -- matugen .* image \"\$target_wallpaper\".*|    setsid uwsm-app -- matugen $build_flags image \"\$target_wallpaper\" \\\|" "$RANDOM_THEME"

# 6. Sync Filesystem
# Ensure file writes are committed before proceeding
log_info "Syncing filesystem..."
sync
sleep 0.2

# 7. Execute Changes

# A. Set GTK Color Scheme (Integrated from old script)
log_info "Setting GTK color scheme..."
if gsettings set org.gnome.desktop.interface color-scheme "prefer-${TARGET_MODE}" 2>/dev/null; then
    log_succ "GTK color scheme set to 'prefer-${TARGET_MODE}'."
else
    # Log as error but do not exit (maintain robustness)
    log_err "Failed to set GTK color scheme (gsettings may be unavailable)."
fi

# B. Update Symlinks
# Calls the script with --light or --dark based on TARGET_MODE
log_info "Updating wallpaper directory symlinks..."
if "$SYMLINK_SCRIPT" "--$TARGET_MODE"; then
    log_succ "Symlinks updated to $TARGET_MODE."
else
    log_err "Failed to update symlinks (Directory likely not found). Proceeding anyway..."
    # Warning issued, exit code omitted to allow flow to continue.
fi

# C. Trigger Wallpaper Refresh
log_info "Triggering wallpaper refresh..."
exec "$RANDOM_THEME"
