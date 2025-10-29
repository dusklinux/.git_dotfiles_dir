#!/bin/bash
#
# set_theme_files.sh
#
# This script silently reads a theme name from a user-defined file
# and symlinks all *files* (not directories) from the corresponding
# theme directory into a 'current' theme directory.
#
# It is designed to be run as part of a larger theming sequence
# and will only output messages to stderr in case of an error.

# --- Configuration ---

# File containing the name of the desired theme
THEME_FILE="$HOME/.config/theming/user_set_theme.txt"

# Base directory where all theme directories are stored
ALL_THEMES_DIR="$HOME/.config/theming/all_themes"

# Target directory for the current theme's symlinked *files*
CURRENT_THEME_DIR="$HOME/.config/theming/current"

# --- Error Handling Helper ---
# Function to log errors to stderr
log_error() {
  # All output from this script goes to stderr
  echo "ERROR (set_theme_files.sh): $1" >&2
}

# --- Pre-flight Checks ---

# 1. Ensure the target directory exists
#    -p is silent if the directory already exists.
if ! mkdir -p "$CURRENT_THEME_DIR"; then
  log_error "Could not create or access target directory: $CURRENT_THEME_DIR"
  exit 1
fi

# 2. Check if the theme selection file exists and is readable
if [ ! -r "$THEME_FILE" ]; then
  log_error "Theme file not found or not readable: $THEME_FILE"
  exit 1
fi

# --- Read Theme Name ---

# 3. Read the theme name from the file.
#    -r prevents backslash escapes from being interpreted.
read -r THEME_NAME < "$THEME_FILE"

# 4. Check if the theme name is empty
if [ -z "$THEME_NAME" ]; then
  log_error "Theme file is empty: $THEME_FILE"
  exit 1
fi

# --- Validate Source ---

# 5. Construct and validate the source theme directory
SOURCE_THEME_DIR="$ALL_THEMES_DIR/$THEME_NAME"

if [ ! -d "$SOURCE_THEME_DIR" ]; then
  log_error "Theme directory not found for theme '$THEME_NAME' at: $SOURCE_THEME_DIR"
  exit 1
fi

# --- Execution ---

# 6. Clean the target directory of any old files and symlinks.
#    This prevents stale files if the new theme has fewer files.
#    -maxdepth 1 ensures we only touch items in the root of CURRENT_THEME_DIR.
#    We redirect stderr to /dev/null to silence "No such file or directory"
#    if the directory is already empty.
find "$CURRENT_THEME_DIR" -maxdepth 1 -type f -delete 2>/dev/null
find "$CURRENT_THEME_DIR" -maxdepth 1 -type l -delete 2>/dev/null

# 7. Find all *files* (not directories) in the source directory and symlink them.
#    -maxdepth 1 ensures we only get files from the root of SOURCE_THEME_DIR.
#    -print0 and 'read -d' handle filenames with spaces or newlines.

find "$SOURCE_THEME_DIR" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' SOURCE_FILE; do
  
  # Get just the filename
  FILENAME=$(basename "$SOURCE_FILE")
  
  # Define the destination path
  DEST_LINK="$CURRENT_THEME_DIR/$FILENAME"
  
  # Create the symbolic link
  # -n: Do not follow symlinks in destination (treat symlink as a file)
  # -f: Force (overwrite existing destination file/link)
  # -s: Symbolic
  if ! ln -nfs "$SOURCE_FILE" "$DEST_LINK"; then
    log_error "Failed to create symlink for: $SOURCE_FILE"
    # We log the error but continue, in case it's a minor issue
    # on one file that shouldn't stop the whole script.
  fi
done

# Exit with success. All errors have been sent to stderr.
exit 0
