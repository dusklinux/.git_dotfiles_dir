#!/bin/bash

# --- Configuration ---
USER_THEME_FILE="$HOME/.config/theming/user_set_theme.txt"
ALL_THEMES_DIR="$HOME/.config/theming/all_themes"
LOCAL_THEMES_DIR="$HOME/.local/share/themes"
GTK4_CONFIG_DIR="$HOME/.config/gtk-4.0"

# --- Helper function for error messages ---
# Outputs to stderr, so it won't break "silent" stdout
error_exit() {
    echo "GTK Script Error: $1" >&2
    exit 1
}

# --- 1. Read the user's chosen theme name ---
if [ ! -f "$USER_THEME_FILE" ]; then
    error_exit "Theme file not found: $USER_THEME_FILE"
fi

myTheme=$(cat "$USER_THEME_FILE")

if [ -z "$myTheme" ]; then
    error_exit "Theme file is empty: $USER_THEME_FILE"
fi

# --- 2. Find the actual GTK theme directory ---
THEME_GTK_DIR="$ALL_THEMES_DIR/$myTheme/gtk"

if [ ! -d "$THEME_GTK_DIR" ]; then
    error_exit "Theme GTK directory not found: $THEME_GTK_DIR"
fi

# Find the single theme directory inside the 'gtk' folder
# We use find to get the full path reliably
GTK_THEME_DIR_PATH=$(find "$THEME_GTK_DIR" -mindepth 1 -maxdepth 1 -type d)

# Check if we found exactly one directory
if [ -z "$GTK_THEME_DIR_PATH" ] || [ $(echo "$GTK_THEME_DIR_PATH" | wc -l) -ne 1 ]; then
    error_exit "Expected exactly one theme directory inside $THEME_GTK_DIR, but found none or more than one."
fi

# Get the directory's name (e.g., "Orchis-Orange-compact")
GTK_THEME_NAME=$(basename "$GTK_THEME_DIR_PATH")

# --- 3. Symlink the theme to .local/share/themes ---
# Ensure the target directory exists
mkdir -p "$LOCAL_THEMES_DIR"

# Create the symlink. -nfs (no-dereference, force, symbolic)
# This links the entire directory (e.g., .../Orchis-Orange-compact) into .../.local/share/themes/
ln -nfs "$GTK_THEME_DIR_PATH" "$LOCAL_THEMES_DIR/"

# --- 4. Set the GTK theme using gsettings ---
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME"

# --- 5. Symlink GTK-4.0 files for libadwaita ---
GTK4_SOURCE_DIR="$LOCAL_THEMES_DIR/$GTK_THEME_NAME/gtk-4.0"

# Check if the theme has a gtk-4.0 directory. If not, we can't link it.
if [ -d "$GTK4_SOURCE_DIR" ]; then
    # Ensure the config directory exists
    mkdir -p "$GTK4_CONFIG_DIR"
    
    # Symlink the *contents* of the gtk-4.0 folder
    # We add a trailing / to the source to handle contents safely
    ln -nfs "$GTK4_SOURCE_DIR"/* "$GTK4_CONFIG_DIR/"
fi

# --- Script finished silently ---
exit 0
