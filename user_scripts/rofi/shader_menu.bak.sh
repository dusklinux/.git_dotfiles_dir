#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# METADATA & DESCRIPTION
# -----------------------------------------------------------------------------
# Description: Interactive Rofi Shader Menu with LIVE PREVIEW
# Logic: Abuses Rofi's exit codes to toggle shaders while scrolling.
# Fix: Uses Bash Arrays to handle Rofi -theme-str quotes safely.

set -u
set -o pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------

# Visual Assets
declare -A icons=(
    [active]=""
    [inactive]=""
    [off]=""
    [shader]=""
)

# Rofi Command Construction (Using Array for Safety)
# This prevents the "Failed to parse -theme-str" error.
rofi_cmd=(
    rofi
    -dmenu
    -i
    -markup-rows
    -theme-str "window {location: center; anchor: center; fullscreen: false; width: 400px;}"
)

# -----------------------------------------------------------------------------
# STATE MANAGEMENT
# -----------------------------------------------------------------------------

# 1. Capture Original State (for Cancellation)
# We need to know what was running BEFORE you opened the menu
raw_orig=$(hyprshade current)
# Trim whitespace
ORIGINAL_SHADER="${raw_orig#"${raw_orig%%[![:space:]]*}"}"
ORIGINAL_SHADER="${ORIGINAL_SHADER%"${ORIGINAL_SHADER##*[![:space:]]}"}"
[[ -z "$ORIGINAL_SHADER" ]] && ORIGINAL_SHADER="off"

# -----------------------------------------------------------------------------
# DATA PREPARATION
# -----------------------------------------------------------------------------

# Get list of shaders
mapfile -t raw_list < <(hyprshade ls)
declare -a shaders
shaders+=("off") # Prepend 'off' as the first option

# Clean the list
for raw in "${raw_list[@]}"; do
    clean="${raw#"${raw%%[![:space:]]*}"}"
    clean="${clean%"${clean##*[![:space:]]}"}"
    [[ -n "$clean" ]] && shaders+=("$clean")
done

# Find current index to pre-select
current_idx=0
for i in "${!shaders[@]}"; do
    if [[ "${shaders[$i]}" == "$ORIGINAL_SHADER" ]]; then
        current_idx=$i
        break
    fi
done

# -----------------------------------------------------------------------------
# RENDER LOOP
# -----------------------------------------------------------------------------

while true; do
    # Generate Menu Content
    menu_content=""
    
    # Get currently applied shader for UI highlighting
    raw_curr=$(hyprshade current)
    curr_clean="${raw_curr#"${raw_curr%%[![:space:]]*}"}"
    curr_clean="${curr_clean%"${curr_clean##*[![:space:]]}"}"
    [[ -z "$curr_clean" ]] && curr_clean="off"

    for item in "${shaders[@]}"; do
        if [[ "$item" == "$curr_clean" ]]; then
            # Active Item
            if [[ "$item" == "off" ]]; then
                 line="<span weight='bold' color='#f38ba8'>${icons[off]}  Turn Off (Active)</span>"
            else
                 line="<span weight='bold' color='#a6e3a1'>${icons[active]}  ${item} (Active)</span>"
            fi
        else
            # Inactive Item
             if [[ "$item" == "off" ]]; then
                 line="${icons[inactive]}  Turn Off"
            else
                 line="${icons[shader]}  ${item}"
            fi
        fi
        menu_content+="${line}\n"
    done

    # -------------------------------------------------------------------------
    # EXECUTE ROFI
    # -------------------------------------------------------------------------
    # We expand the array using "${rofi_cmd[@]}" to preserve quotes.
    
    selection=$(echo -e "$menu_content" | "${rofi_cmd[@]}" \
        -p "Shader Preview" \
        -selected-row "$current_idx" \
        -kb-custom-1 "Down" \
        -kb-custom-2 "Up" \
        -kb-row-down "" \
        -kb-row-up "")
    
    exit_code=$?

    # -------------------------------------------------------------------------
    # HANDLE INPUT
    # -------------------------------------------------------------------------

    max_idx=$((${#shaders[@]} - 1))

    if [[ $exit_code -eq 10 ]]; then
        # User pressed DOWN (Custom 1)
        ((current_idx++))
        if [[ $current_idx -gt $max_idx ]]; then current_idx=0; fi
        
        target="${shaders[$current_idx]}"
        if [[ "$target" == "off" ]]; then
            hyprshade off
        else
            hyprshade on "$target"
        fi

    elif [[ $exit_code -eq 11 ]]; then
        # User pressed UP (Custom 2)
        ((current_idx--))
        if [[ $current_idx -lt 0 ]]; then current_idx=$max_idx; fi
        
        target="${shaders[$current_idx]}"
        if [[ "$target" == "off" ]]; then
            hyprshade off
        else
            hyprshade on "$target"
        fi

    elif [[ $exit_code -eq 0 ]]; then
        # User pressed ENTER (Confirm)
        # If selection is empty (user hit enter on empty list), exit safely
        [[ -z "$selection" ]] && exit 0
        
        notify-send "Hyprshade" "Set to: ${shaders[$current_idx]}" -i video-display
        exit 0

    else
        # User pressed ESC (Cancel) or closed window
        # Revert to the original state
        if [[ "$ORIGINAL_SHADER" == "off" ]]; then
            hyprshade off
        else
            hyprshade on "$ORIGINAL_SHADER"
        fi
        exit 0
    fi
done
