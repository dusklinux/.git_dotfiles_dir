#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# CONFIGURATION & PATHS
# -----------------------------------------------------------------------------
set -u
set -o pipefail

# Robust path definition using XDG standard
XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
ANIM_DIR="$XDG_CONFIG/hypr/source/animations"
LINK_DIR="$ANIM_DIR/active"
LINK_FILE="$LINK_DIR/active.conf"

# Visual Assets (Nerd Fonts)
ICON_ACTIVE=""   # Checkmark
ICON_FILE=""     # File
ICON_ERROR=""    # Warning

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------

notify_user() {
    local title="$1"
    local message="$2"
    local urgency="${3:-low}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -a "Hyprland Animations" "$title" "$message"
    fi
}

reload_hyprland() {
    # Reload Hyprland config to apply changes instantly
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null
    fi
}

# -----------------------------------------------------------------------------
# EXECUTION LOGIC (Selection Made)
# -----------------------------------------------------------------------------

# Retrieve the hidden info passed from Rofi
selection="${ROFI_INFO:-}"

# Fallback: If ROFI_INFO is empty, check $1 (for older Rofi versions or manual testing)
if [[ -z "$selection" && -n "${1:-}" ]]; then
    clean_name=$(echo "$1" | sed 's/<[^>]*>//g' | xargs)
    selection="$ANIM_DIR/$clean_name"
fi

if [[ -n "$selection" ]]; then
    if [[ ! -f "$selection" ]]; then
        notify_user "Error" "File not found: $selection" "critical"
        exit 1
    fi

    # Ensure target directory exists
    mkdir -p "$LINK_DIR"

    # Create Symlink (Atomic operation)
    # -n: Treat destination symlink to directory as file
    # -f: Force overwrite
    # -s: Symbolic link
    if ln -nfs "$selection" "$LINK_FILE"; then
        filename=$(basename "$selection")
        reload_hyprland
        notify_user "Success" "Switched to: $filename"
    else
        notify_user "Failure" "Could not create symlink." "critical"
        exit 1
    fi
    exit 0
fi

# -----------------------------------------------------------------------------
# MENU GENERATION (No Selection)
# -----------------------------------------------------------------------------

# Rofi Setup Headers
echo -e "\0prompt\x1fAnimations"
echo -e "\0markup-rows\x1ftrue"
echo -e "\0no-custom\x1ftrue"
echo -e "\0message\x1fSelect a configuration to apply instantly"

# Check if Source Directory Exists
if [[ ! -d "$ANIM_DIR" ]]; then
    echo -e "Directory Missing\0icon\x1f$ICON_ERROR\x1finfo\x1fignore"
    exit 0
fi

# Resolve currently active file to highlight it
# readlink -f resolves the absolute path of the symlink target
current_active=$(readlink -f "$LINK_FILE" 2>/dev/null || echo "")

# Iterate over .conf files
shopt -s nullglob
files=("$ANIM_DIR"/*.conf)

if [ ${#files[@]} -eq 0 ]; then
    echo -e "No .conf files found\0icon\x1f$ICON_ERROR\x1finfo\x1fignore"
    exit 0
fi
#
# Calculate active index and tell Rofi to apply the theme's 'Active' style
for i in "${!files[@]}"; do
    if [[ "${files[$i]}" == "$current_active" ]]; then
        echo -e "\0active\x1f$i"
        break
    fi
done

for file in "${files[@]}"; do
    filename=$(basename "$file")
    
    if [[ "$file" == "$current_active" ]]; then
        # Active State: Bold Green + Checkmark
          echo -e "<span weight='bold'>${filename}</span> <span size='small' style='italic'>(Active)</span>\0icon\x1f${ICON_ACTIVE}\x1finfo\x1f${file}"
    else
        # Inactive State: Standard Text + File Icon
        echo -e "${filename}\0icon\x1f${ICON_FILE}\x1finfo\x1f${file}"
    fi
done

exit 0
