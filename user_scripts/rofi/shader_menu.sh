#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# METADATA & ERROR HANDLING
# -----------------------------------------------------------------------------
# Description: Rofi Menu for Hyprshade (Toggle Shaders)
# Dependencies: rofi, hyprshade
# Context: Hyprland on Arch Linux (Hyprshade output sanitization added)

set -u
set -o pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------

# Visual Assets (Nerd Fonts)
declare -A icons=(
    [active]=""      # Eye open (Active)
    [inactive]=""    # Eye slashed (Inactive)
    [off]=""         # Cancel/Off
    [shader]=""      # Generic Shader/Code icon
)

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------

# Trim leading/trailing whitespace from a string
trim() {
    local var="$*"
    # Remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

check_dependencies() {
    local dependencies=(rofi hyprshade)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: Critical dependency '$cmd' is missing." >&2
            exit 1
        fi
    done
}

# -----------------------------------------------------------------------------
# MAIN LOGIC
# -----------------------------------------------------------------------------

check_dependencies

# Get current shader and clean it immediately
raw_current=$(hyprshade current)
current_shader=$(trim "$raw_current")

selection="${1:-}"

# --- PHASE 1: INITIAL RENDER ---
if [[ -z "$selection" ]]; then
    echo -e "\0prompt\x1fShaders"
    echo -e "\0markup-rows\x1ftrue"
    echo -e "\0use-hot-keys\x1ftrue"

    # 1. Add "Turn Off" Option
    if [[ -z "$current_shader" ]]; then
        echo -e "<b>Turn Off (Current)</b>\0icon\x1f${icons[off]}\x1finfo\x1foff"
    else
        echo -e "Turn Off\0icon\x1f${icons[off]}\x1finfo\x1foff"
    fi

    # 2. List available shaders safely
    mapfile -t available_shaders < <(hyprshade ls)

    if [[ ${#available_shaders[@]} -eq 0 ]]; then
        echo -e "No shaders found\0icon\x1f${icons[off]}\x1finfo\x1fcancel"
        exit 0
    fi

    for raw_shader in "${available_shaders[@]}"; do
        # Clean the shader name from 'hyprshade ls' output
        shader=$(trim "$raw_shader")
        
        [[ -z "$shader" ]] && continue

        if [[ "$shader" == "$current_shader" ]]; then
            label="<span weight='bold' color='#a6e3a1'>${shader} (Active)</span>"
            icon="${icons[active]}"
        else
            label="${shader}"
            icon="${icons[shader]}"
        fi

        # Pass clean 'shader' name in the info field
        echo -e "${label}\0icon\x1f${icon}\x1finfo\x1f${shader}"
    done
    exit 0
fi

# --- PHASE 2: SELECTION PARSING ---

# Prefer ROFI_INFO if available (it contains the clean value we passed above)
if [[ -n "${ROFI_INFO:-}" ]]; then
    target="$ROFI_INFO"
else
    # Fallback: Clean the visible text
    # 1. Remove Pango tags
    clean_text=$(echo "$selection" | sed 's/<[^>]*>//g')
    # 2. Remove " (Active)" suffix if it exists
    clean_text="${clean_text% (Active)}"
    # 3. Trim whitespace
    target=$(trim "$clean_text")
fi

# Handle Special Commands
if [[ "$target" == "off" ]] || [[ "$target" == "cancel" ]]; then
    if [[ "$target" == "off" ]]; then
        hyprshade off
    fi
    exit 0
fi

# --- PHASE 3: EXECUTION ---

# Final sanity clean before execution
final_target=$(trim "$target")

# Re-check current state for toggle logic
real_current_raw=$(hyprshade current)
real_current=$(trim "$real_current_raw")

if [[ "$final_target" == "$real_current" ]]; then
    hyprshade off
    # Optional: Notification
    # notify-send "Hyprshade" "Shader disabled"
else
    hyprshade on "$final_target"
    # Optional: Notification
    # notify-send "Hyprshade" "Enabled: $final_target"
fi

exit 0
