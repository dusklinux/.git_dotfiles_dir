#!/bin/bash
#
# set_qt_theme.sh
#
# Silently configures the Kvantum theme by:
# 1. Reading the user's selected theme name.
# 2. Finding the corresponding Kvantum theme directory.
# 3. Symlinking the theme directory to ~/.config/Kvantum/
# 4. Updating the Kvantum config file to use the new theme.
#
# This script produces NO output on success or expected "failure"
# (e.g., file not found), making it suitable for automation.

# Exit immediately if a variable is unset.
set -u
# Ensure pipelines fail if any command in them fails.
set -o pipefail

# --- Configuration ---

# File containing the name of the user's currently set master theme.
readonly USER_THEME_FILE="$HOME/.config/theming/user_set_theme.txt"

# Base directory where all theme source files are stored.
readonly ALL_THEMES_BASE_DIR="$HOME/.config/theming/all_themes"

# Kvantum's directory for theme *symlinks* (uppercase 'K').
readonly KVANTUM_LINK_DIR="$HOME/.config/Kvantum"

# Kvantum's directory for its *configuration file* (uppercase 'K').
readonly KVANTUM_CONFIG_DIR="$HOME/.config/Kvantum"

# Kvantum's main configuration file.
readonly KVANTUM_CONFIG_FILE="$KVANTUM_CONFIG_DIR/kvantum.kvconfig"

# --- Execution ---

# 1. Read the user's master theme name.
#    Exit silently if the file doesn't exist or is unreadable.
if [[ ! -r "$USER_THEME_FILE" ]]; then
    exit 0
fi

# Read the theme name from the file.
readonly USER_THEME=$(cat "$USER_THEME_FILE")

# Exit silently if the file was empty.
if [[ -z "$USER_THEME" ]]; then
    exit 0
fi

# 2. Find the Kvantum theme directory.
#    This is the .../myTheme/Kvantum/ part of the path.
readonly KVANTUM_SOURCE_BASE_DIR="$ALL_THEMES_BASE_DIR/$USER_THEME/Kvantum"

# Exit silently if the Kvantum source directory doesn't exist.
if [[ ! -d "$KVANTUM_SOURCE_BASE_DIR" ]]; then
    exit 0
fi

# Find the *actual* theme directory (theme_name) inside the source dir.
# We assume there is exactly one subdirectory, as implied.
# We use find + head to grab the first directory found.
readonly KVANTUM_THEME_PATH=$(find "$KVANTUM_SOURCE_BASE_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

# Exit silently if no theme subdirectory was found.
if [[ -z "$KVANTUM_THEME_PATH" ]]; then
    exit 0
fi

# Get just the name of the theme directory (e.g., "theme_name").
readonly KVANTUM_THEME_NAME=$(basename "$KVANTUM_THEME_PATH")

# 3. Create target directories and symlink the theme.
#    All output and errors are silenced. We use '|| exit 0' to
#    prevent 'set -e' (if it were active) from stopping the script
#    and to exit gracefully if the command fails (e.g., permissions).

# Ensure the symlink target directory exists.
mkdir -p "$KVANTUM_LINK_DIR" 2>/dev/null || exit 0

# Create/update the symlink.
# ln -n: Do not dereference symlinks in the target directory.
# ln -f: Force removal of existing destination files/symlinks.
# ln -s: Create a symbolic link.
# The trailing slash on $KVANTUM_LINK_DIR/ is important.
ln -nfs "$KVANTUM_THEME_PATH" "$KVANTUM_LINK_DIR/" 2>/dev/null || exit 0

# 4. Update the Kvantum configuration file.

# Ensure the Kvantum config directory exists.
mkdir -p "$KVANTUM_CONFIG_DIR" 2>/dev/null || exit 0

# Write the new configuration file, overwriting any existing one.
# This sets the 'theme' key under the [General] section.
printf '%s\n' '[General]' "theme=$KVANTUM_THEME_NAME" > "$KVANTUM_CONFIG_FILE" 2>/dev/null || exit 0

# Explicitly exit with success.
exit 0

