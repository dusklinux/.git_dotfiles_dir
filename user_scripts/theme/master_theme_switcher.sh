#!/usr/bin/env bash

# ============================================================================
# THEME SCRIPTS CONFIGURATION
# Define your theme-switching scripts below in the ORDER they should execute
# Each script will receive the theme name as an argument
# ============================================================================
THEME_SCRIPTS=(
    "$HOME/user_scripts/theme/qt.sh"
    "$HOME/user_scripts/theme/color_files.sh"
    "$HOME/user_scripts/theme/gtk.sh"
    "$HOME/user_scripts/theme/obsidian.sh"
    "$HOME/user_scripts/theme/reload_commands.sh"
    "$HOME/user_scripts/theme/asus_keyboard.sh"
    "$HOME/user_scripts/theme/wallpaper_swww.sh"
)

# ============================================================================
# PATHS
# ============================================================================
THEMES_DIR="$HOME/.config/theming/all_themes"
THEME_FILE="$HOME/.config/theming/user_set_theme.txt"

# ============================================================================
# PREREQUISITES CHECK
# ============================================================================
if ! command -v gum &> /dev/null; then
    notify-send -u critical "Theme Switcher" "gum is not installed!\nInstall: yay -S gum"
    exit 1
fi

if [ ! -d "$THEMES_DIR" ]; then
    notify-send -u critical "Theme Switcher" "Themes directory not found:\n$THEMES_DIR"
    exit 1
fi

# ============================================================================
# COLLECT AVAILABLE THEMES
# ============================================================================
mapfile -t themes < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

if [ ${#themes[@]} -eq 0 ]; then
    gum style --foreground 196 --border normal --border-foreground 196 --padding "1 2" --margin "1" "No themes found in themes directory"
    exit 1
fi

# ============================================================================
# SHOW CURRENT THEME
# ============================================================================
current_theme=""
if [ -f "$THEME_FILE" ]; then
    current_theme=$(<"$THEME_FILE")
fi

# ============================================================================
# THEME SELECTION INTERFACE
# ============================================================================
if [ -n "$current_theme" ]; then
    selected_theme=$(printf '%s\n' "${themes[@]}" | gum choose \
        --header "⚡ Select Theme (Current: $current_theme)" \
        --height 20 \
        --cursor.foreground 212 \
        --selected.foreground 212)
else
    selected_theme=$(printf '%s\n' "${themes[@]}" | gum choose \
        --header "⚡ Select Theme" \
        --height 20 \
        --cursor.foreground 212 \
        --selected.foreground 212)
fi

# Exit gracefully if user cancels (ESC or Ctrl+C)
if [ -z "$selected_theme" ]; then
    exit 0
fi

# Skip if same theme is selected
if [ "$selected_theme" = "$current_theme" ]; then
    gum style --foreground 214 --padding "0 2" "Theme '$selected_theme' is already active"
    exit 0
fi

# ============================================================================
# SAVE THEME SELECTION
# ============================================================================
echo -n "$selected_theme" > "$THEME_FILE"

# ============================================================================
# APPLY THEME SEQUENTIALLY
# ============================================================================
total_scripts=${#THEME_SCRIPTS[@]}
current=0

gum style --bold --foreground 212 --padding "1 2" "Applying theme: $selected_theme"

for script in "${THEME_SCRIPTS[@]}"; do
    ((current++))
    script_name=$(basename "$script" .sh)
    
    if [ -f "$script" ]; then
        echo "[$current/$total_scripts] Applying $script_name..."
        bash "$script" 2>/dev/null
    else
        echo "[$current/$total_scripts] Skipping $script_name (not found)"
    fi
done

# ============================================================================
# COMPLETION
# ============================================================================
gum style \
    --border rounded \
    --border-foreground 212 \
    --padding "1 2" \
    --margin "1 0" \
    --bold \
    "✓ Theme '$selected_theme' applied successfully!"

# Optional: Send desktop notification (comment out if not needed)
notify-send "Theme Switcher" "Theme '$selected_theme' applied" -i preferences-desktop-theme

# this will kill the current kitty window
kill $(ps -o ppid= $$)

exit 0
