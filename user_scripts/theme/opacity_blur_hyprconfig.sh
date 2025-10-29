#!/usr/bin/env bash

#==============================================================================
# Hyprland Blur & Opacity Toggle Script
#
# This script atomically toggles the blur setting within the 'blur' block
# of the specified configuration file. Concurrently, it adjusts the
# active_opacity and inactive_opacity settings based on the new blur state.
#
# This script creates no backups and produces no terminal output on success.
# It is designed to be bound to a hotkey.
#==============================================================================

# --- User Configuration ---
# Opacity values when blur is ENABLED
readonly OPACITY_ACTIVE_ENABLED="0.8"
readonly OPACITY_INACTIVE_ENABLED="0.6"

# Opacity values when blur is DISABLED
readonly OPACITY_ACTIVE_DISABLED="1.0"
readonly OPACITY_INACTIVE_DISABLED="1.0"

# --- Script Implementation ---

# Resolve the configuration file path
readonly CONFIG_FILE="${HOME}/.config/hypr/source/appearance.conf"

# Perform a preliminary check to ensure the config file exists.
# If not, exit with a non-zero status without any output.
if [ ! -f "$CONFIG_FILE" ]; then
    exit 1
fi

# Determine the current state of blur by searching for 'enabled = true'
# exclusively within the '/blur {/ ... /}/' address range.
if sed -n '/blur {/,/}/ { /enabled = / p }' "$CONFIG_FILE" | grep -q 'true'; then
    
    #--- STATE: Blur is ENABLED ---
    # Action: Disable blur and disable transparency.
    
    # 1. Disable blur:
    #    The address range '/blur {/,/}/' ensures this 's' command
    #    only operates on the 'enabled' line inside the 'blur' block.
    sed -i '/blur {/,/}/ s/enabled = true/enabled = false/' "$CONFIG_FILE"
    
    # 2. Disable transparency (set opacity to 1.0):
    #    This regex captures the leading whitespace and key ('\1')
    #    and replaces only the value, preserving indentation.
    sed -i "s/^\([[:space:]]*active_opacity = \).*/\1${OPACITY_ACTIVE_DISABLED}/" "$CONFIG_FILE"
    sed -i "s/^\([[:space:]]*inactive_opacity = \).*/\1${OPACITY_INACTIVE_DISABLED}/" "$CONFIG_FILE"

else
    
    #--- STATE: Blur is DISABLED ---
    # Action: Enable blur and enable transparency.
    
    # 1. Enable blur:
    sed -i '/blur {/,/}/ s/enabled = false/enabled = true/' "$CONFIG_FILE"
    
    # 2. Enable transparency (set to configured values):
    sed -i "s/^\([[:space:]]*active_opacity = \).*/\1${OPACITY_ACTIVE_ENABLED}/" "$CONFIG_FILE"
    sed -i "s/^\([[:space:]]*inactive_opacity = \).*/\1${OPACITY_INACTIVE_ENABLED}/" "$CONFIG_FILE"

fi

hyprctl reload

# Exit gracefully
exit 0
