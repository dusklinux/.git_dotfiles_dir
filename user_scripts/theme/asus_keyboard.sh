#!/bin/sh
#
# wal-asus-kb: Sets ASUS keyboard backlight from the pywal color palette.
#

# --- IMPORTANT ---
# Enter your sudo password below.
# Note: Storing your password in a plain text file is a security risk.
# Proceed only if you understand and accept this risk.
PASSWORD="2345"


# Exit immediately if a command exits with a non-zero status.
set -e

# Define the path to the keyboard color file.
KEYBOARD_CSS_FILE="$HOME/.config/theming/current/keyboard.css"

# Ascertain that the keyboard color file is extant.
if [ ! -f "$KEYBOARD_CSS_FILE" ]; then
    printf "Error: Keyboard color file not found at %s\\n" "$KEYBOARD_CSS_FILE" >&2
    exit 1
fi

# Extract the hexadecimal color code.
# Assumes file contains only the hex code (e.g., "8fbcbb" or "#8fbcbb").
COLOR=$(sed 's/#//' "$KEYBOARD_CSS_FILE" | tr -d '[:space:]')

# Verify that a color was successfully extracted.
if [ -z "$COLOR" ]; then
    printf "Error: Could not extract color from %s\\n" "$KEYBOARD_CSS_FILE" >&2
    exit 1
fi

# Check if the password has been set.
if [ "$PASSWORD" = "YOUR_PASSWORD_HERE" ]; then
    printf "Error: Password not set in script. Please edit the file to add your password.\\n" >&2
    exit 1
fi

# Apply the extracted color to the keyboard backlight via asusctl.
# The `echo` command pipes the password to `sudo -S`, which reads the password
# from standard input instead of the terminal.
echo "$PASSWORD" | sudo -S asusctl aura static -c "$COLOR"
