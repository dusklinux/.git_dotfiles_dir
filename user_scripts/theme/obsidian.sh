#!/bin/bash

# --- User Configuration ---
# This variable defines the path to your Obsidian vault's configuration directory.
# Modify this path if your vault's .obsidian directory is located elsewhere.
readonly OBSIDIAN_CONFIG_DIR="$HOME/Documents/pensive/.obsidian"

# --- Static Configuration ---
# Source of truth for the currently selected theme name.
readonly THEME_CONFIG_FILE="$HOME/.config/theming/user_set_theme.txt"

# Base directory where all master theme configurations are stored.
readonly ALL_THEMES_DIR="$HOME/.config/theming/all_themes"

# --- Script Safety Guards ---
# Exit immediately if any command fails (returns a non-zero status).
set -e
# Exit immediately if the script attempts to use an unset variable.
set -u

# --- Main Execution ---

# 1. Validate and Read Theme Configuration
# We check if the config file exists and is readable (-r).
# If not, silently exit with a non-zero status.
if [ ! -r "$THEME_CONFIG_FILE" ]; then
    exit 1
fi

# Read the theme name from the file. `set -e` ensures that if `cat` fails
# (e.g., permissions), the script will halt.
readonly THEME_NAME=$(cat "$THEME_CONFIG_FILE")

# 2. Validate Theme Name
# Check if the variable is non-empty. If the file was empty, $THEME_NAME
# will be a zero-length string.
if [ -z "$THEME_NAME" ]; then
    # File was empty. Silently exit with a non-zero status.
    exit 1
fi

# 3. Define Source and Target Paths
readonly SOURCE_THEME_DIR="$ALL_THEMES_DIR/$THEME_NAME/obsidian/theme_folder"
readonly SOURCE_APPEARANCE_FILE="$ALL_THEMES_DIR/$THEME_NAME/obsidian/appearance.json"
readonly TARGET_THEMES_DIR="$OBSIDIAN_CONFIG_DIR/themes"

# 4. Perform Comprehensive Pre-flight Checks
# This is the core of the script's robustness. We verify that all
# required sources and destinations exist *before* running any commands.
# If any single check fails, the script will silently exit.
if [ ! -d "$SOURCE_THEME_DIR" ] || \
   [ ! -r "$SOURCE_APPEARANCE_FILE" ] || \
   [ ! -d "$OBSIDIAN_CONFIG_DIR" ] || \
   [ ! -d "$TARGET_THEMES_DIR" ]; then
    # A required directory or file is missing or inaccessible.
    # Silently exit with a non-zero status.
    exit 1
fi

# 5. Execute Symlinking Operations
# All checks have passed. We can now safely execute the link commands.
# All output (stdout and stderr) is redirected to /dev/null for silence.
# `set -e` guarantees that if `ln` fails, the script will stop.

# Enable `nullglob` shell option. If the source directory is empty and
# contains no matching files, the `*` glob will expand to *nothing*
# instead of the literal string "/*", which would cause `ln` to fail.
shopt -s nullglob

# Command 1: Symlink theme files from the source folder.
# This executes your requested command: ln -nfs .../* .../
# If $SOURCE_THEME_DIR is empty, nullglob expands `*` to nothing,
# `ln` is called with no source files, and it will (safely) error out,
# which `set -e` will catch. This is correct behavior.
ln -nfs "$SOURCE_THEME_DIR"/* "$TARGET_THEMES_DIR/" &> /dev/null

# Revert the shell option for good hygiene.
shopt -u nullglob

# Command 2: Symlink the appearance.json file.
ln -nfs "$SOURCE_APPEARANCE_FILE" "$OBSIDIAN_CONFIG_DIR/" &> /dev/null

# 6. Success
# If the script reaches this point, all operations completed successfully.
exit 0
