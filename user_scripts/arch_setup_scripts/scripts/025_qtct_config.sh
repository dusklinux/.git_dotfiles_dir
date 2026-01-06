#!/usr/bin/env bash
# Enforces specific [Appearance] settings in qt5ct and qt6ct
# ==============================================================================
# Script: setup_qt_theme.sh
# Description: Enforces specific [Appearance] settings in qt5ct and qt6ct.
# Environment: Arch Linux / Hyprland / UWSM
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Strict Mode & Safety
# ------------------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# 2. Logging & Presentation
# ------------------------------------------------------------------------------
declare -r RESET=$'\033[0m'
declare -r BOLD=$'\033[1m'
declare -r GREEN=$'\033[32m'
declare -r BLUE=$'\033[34m'
declare -r RED=$'\033[31m'

log_info() { printf "${BLUE}${BOLD}[INFO]${RESET} %s\n" "$1"; }
log_success() { printf "${GREEN}${BOLD}[OK]${RESET} %s\n" "$1"; }
log_err() { printf "${RED}${BOLD}[ERROR]${RESET} %s\n" "$1" >&2; }

# ------------------------------------------------------------------------------
# 3. Cleanup Trap
# ------------------------------------------------------------------------------
# Ensures no temporary files are left behind, keeping the system clean.
cleanup() {
    if [[ -n "${TEMP_FILE:-}" ]] && [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
}
trap cleanup EXIT ERR

# ------------------------------------------------------------------------------
# 4. Core Logic
# ------------------------------------------------------------------------------
update_qt_config() {
    local app_name="$1"       # e.g., qt5ct
    local conf_file="$2"      # Full path to config
    local dialog_val="$3"     # default or xdgdesktopportal
    local colors_file="$4"    # filename of the colors conf

    log_info "Processing configuration for ${BOLD}${app_name}${RESET}..."

    # Ensure directory exists
    local config_dir
    config_dir=$(dirname "$conf_file")
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
        log_info "Created directory: $config_dir"
    fi

    # Create a temporary file for atomic writing
    TEMP_FILE=$(mktemp)

    # --------------------------------------------------------------------------
    # STEP A: Generate the enforced header
    # We use single quotes for the format string to prevent shell expansion,
    # but pass $HOME as a literal string because the user config requires it.
    # --------------------------------------------------------------------------
    {
        printf "[Appearance]\n"
        printf "color_scheme_path=\$HOME/.config/matugen/generated/%s\n" "$colors_file"
        printf "custom_palette=true\n"
        printf "standard_dialogs=%s\n" "$dialog_val"
        printf "style=Fusion\n"
    } > "$TEMP_FILE"

    # --------------------------------------------------------------------------
    # STEP B: Filter existing file (if it exists)
    # We strip out [Appearance] and the specific keys we just wrote to avoid
    # duplicates. All other sections (Fonts, Interface) are preserved perfectly.
    # --------------------------------------------------------------------------
    if [[ -f "$conf_file" ]]; then
        awk '
            BEGIN { 
                # Keys to strip from the old file to avoid duplication
                keys["style"]=1
                keys["custom_palette"]=1
                keys["standard_dialogs"]=1
                keys["color_scheme_path"]=1
            }

            # Skip the specific [Appearance] section header
            /^\[Appearance\]/ { next }

            # Check if line matches "key=value" format
            /=/ {
                split($0, map, "=")
                key = map[1]
                # If this key is one we are managing, skip it (we wrote it at the top)
                if (key in keys) { next }
            }

            # Print everything else (Fonts, Interface, other Appearance keys)
            { print }
        ' "$conf_file" >> "$TEMP_FILE"
    else
        log_info "File $conf_file did not exist. Creating new."
    fi

    # --------------------------------------------------------------------------
    # STEP C: Atomic Apply
    # Move temp file to actual file. No backup files (.bak) created.
    # --------------------------------------------------------------------------
    mv "$TEMP_FILE" "$conf_file"
    log_success "Updated $conf_file"
}

# ------------------------------------------------------------------------------
# 5. Execution
# ------------------------------------------------------------------------------

# Define paths
QT5_CONF="$HOME/.config/qt5ct/qt5ct.conf"
QT6_CONF="$HOME/.config/qt6ct/qt6ct.conf"

# Update Qt5 Config
# Requirements: standard_dialogs=default, qt5ct-colors.conf
update_qt_config "qt5ct" "$QT5_CONF" "default" "qt5ct-colors.conf"

# Update Qt6 Config
# Requirements: standard_dialogs=xdgdesktopportal, qt6ct-colors.conf
update_qt_config "qt6ct" "$QT6_CONF" "xdgdesktopportal" "qt6ct-colors.conf"

log_success "Qt configuration sync complete."
