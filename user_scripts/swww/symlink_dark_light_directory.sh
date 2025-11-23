#!/bin/bash

# ==============================================================================
# WALLPAPER SYMLINK MANAGER
# ==============================================================================
# Description: Manages symlinks between Light and Dark wallpaper directories.
# Behavior:    - Ensures source directories exist.
#              - Safely handles the 'active' symlink (atomic switching).
#              - Toggles state by default, or accepts --light / --dark flags.
# ==============================================================================

# strict mode: exit on error, unset vars are errors, pipelines fail if any command fails
set -euo pipefail

# --- CONFIGURATION ---
BASE_DIR="$HOME/Pictures"
LIGHT_DIR="$BASE_DIR/light"
DARK_DIR="$BASE_DIR/dark"
WALLPAPER_ROOT="$BASE_DIR/wallpapers"
LINK_NAME="active"
LINK_PATH="$WALLPAPER_ROOT/$LINK_NAME"

# --- FUNCTIONS ---

usage() {
    echo "Usage: $(basename "$0") [OPTION]"
    echo "Manage wallpaper symlinks for Light/Dark modes."
    echo ""
    echo "Options:"
    echo "  (no args)   Toggle between Light and Dark based on current link."
    echo "  --light     Force switch to Light directory."
    echo "  --dark      Force switch to Dark directory."
    echo "  --help      Show this help message."
    exit 0
}

# Function to create the symlink atomically
update_symlink() {
    local target_dir="$1"
    local link_location="$2"
    local tmp_link="${link_location}.tmp"

    echo "-> Switching wallpaper source to: $target_dir"

    # 1. Create a temporary symlink first
    # This ensures we don't break the current link if something goes wrong during creation
    ln -sfn "$target_dir" "$tmp_link"

    # 2. Atomically rename the temp link to the real link name
    # 'mv -T' treats the destination as a file, overwriting it instantly.
    # This prevents race conditions where an application might see a missing file.
    mv -T "$tmp_link" "$link_location"
    
    echo "-> Success: $link_location points to $target_dir"
}

# --- PRE-FLIGHT CHECKS ---

# 1. Create Source Directories
# We create the 'light' and 'dark' directories.
# We also create 'wallpapers', which is the PARENT of the 'active' link.
# CRITICAL: We do NOT mkdir the 'active' path itself. If 'active' is a real directory,
# symlinking will fail or nest inside it.
mkdir -p "$LIGHT_DIR"
mkdir -p "$DARK_DIR"
mkdir -p "$WALLPAPER_ROOT"

# 2. Safety Check: Collision Detection
# If 'active' exists and is a physical Directory (not a symlink), we must abort.
# We should not delete a folder that might contain actual user files.
if [[ -d "$LINK_PATH" && ! -L "$LINK_PATH" ]]; then
    echo "CRITICAL ERROR: '$LINK_PATH' exists and is a real directory."
    echo "This script expects '$LINK_PATH' to be a symlink."
    echo "Please manually move your files out of '$LINK_PATH' and delete the directory before running this script."
    exit 1
fi

# --- STATE LOGIC ---

TARGET_STATE=""

# Parse Arguments
if [[ $# -eq 0 ]]; then
    # === TOGGLE MODE ===
    # Check where the link currently points
    if [[ -L "$LINK_PATH" ]]; then
        CURRENT_TARGET=$(readlink -f "$LINK_PATH")
        
        if [[ "$CURRENT_TARGET" == "$LIGHT_DIR" ]]; then
            TARGET_STATE="dark"
        elif [[ "$CURRENT_TARGET" == "$DARK_DIR" ]]; then
            TARGET_STATE="light"
        else
            echo "Current link points to unknown location: $CURRENT_TARGET"
            echo "Resetting to Dark mode."
            TARGET_STATE="dark"
        fi
    else
        echo "No active link found. Initializing to Dark mode."
        TARGET_STATE="dark"
    fi
else
    # === FLAG MODE ===
    case "$1" in
        --light)
            TARGET_STATE="light"
            ;;
        --dark)
            TARGET_STATE="dark"
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Error: Invalid argument '$1'"
            usage
            ;;
    esac
fi

# --- EXECUTION ---

case "$TARGET_STATE" in
    light)
        update_symlink "$LIGHT_DIR" "$LINK_PATH"
        ;;
    dark)
        update_symlink "$DARK_DIR" "$LINK_PATH"
        ;;
esac
