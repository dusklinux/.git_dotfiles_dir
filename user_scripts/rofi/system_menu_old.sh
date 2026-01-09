#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# ARCH/HYPRLAND ROFI MENU SYSTEM
# Optimized for Bash 5+ | Dependencies: rofi-wayland, uwsm, kitty, hyprctl, fd, file
# -----------------------------------------------------------------------------

# Strict mode: Exit on error, error on unset vars, error if pipe fails
set -uo pipefail

# --- CONFIGURATION ---
readonly SCRIPTS_DIR="${HOME}/user_scripts"
readonly HYPR_CONF="${HOME}/.config/hypr"
readonly HYPR_SOURCE="${HYPR_CONF}/source"

# --- SEARCH CONFIGURATION ---
readonly SEARCH_DIR="${HOME}/Documents/pensive/linux"

# Applications
readonly TERMINAL="kitty"
readonly EDITOR="${EDITOR:-nvim}"
readonly FILE_MANAGER="yazi" # Added explicitly for directory handling

# Rofi Command
readonly ROFI_CMD=(
    rofi 
    -dmenu 
    -i 
    -theme-str 'window {width: 25%;} listview {lines: 10;}'
)

# --- CORE FUNCTIONS ---

menu() {
    local prompt="$1"
    local options="$2"
    local preselect="${3:-}"
    
    local cmd_args=("${ROFI_CMD[@]}" -p "$prompt")

    if [[ -n "$preselect" ]]; then
        local index
        index=$(printf "%b" "$options" | grep -nxF "$preselect" | cut -d: -f1 || true)
        if [[ -n "$index" ]]; then
            cmd_args+=("-selected-row" "$((index - 1))")
        fi
    fi

    printf "%b" "$options" | "${cmd_args[@]}"
}

run_app() {
    uwsm-app -- "$@" >/dev/null 2>&1 &
    disown
    exit 0
}

run_term() {
    local cmd="$1"
    local class="${2:-floating_script}"
    
    uwsm-app -- "$TERMINAL" --class "$class" -e bash -c "$cmd" >/dev/null 2>&1 &
    disown
    exit 0
}

open_editor() {
    local file="$1"
    uwsm-app -- "$TERMINAL" --class "nvim_config" -e "$EDITOR" "$file" >/dev/null 2>&1 &
    disown
    exit 0
}

# --- MENUS ---

show_main_menu() {
    local selection
    selection=$(menu "Main" "🔍  Search Notes\n󰀻  Apps\n󰧑  Learn/Help\n󱓞  Utils\n󱚤  AI & Voice\n  Visuals & Theme\n󰇅  Hardware & System\n  Configs\n  Power")
    
    route_selection "$selection"
}

route_selection() {
    local choice="${1,,}"

    case "$choice" in
        *search*)    perform_global_search ;;
        *apps*)      run_app rofi -show drun -run-command "uwsm app -- {cmd}" ;; 
        *learn*)     show_learn_menu ;;
        *utils*)     show_utils_menu ;;
        *ai*)        show_ai_menu ;;
        *visuals*)   show_visuals_menu ;;
        *hardware*)  show_hardware_menu ;;
        *configs*)   show_config_menu ;;
        *power*)     run_app rofi -show power-menu -modi "power-menu:$SCRIPTS_DIR/rofi/powermenu.sh" ;;
        *)           exit 0 ;;
    esac
}

# --- SEARCH LOGIC (FIXED) ---

perform_global_search() {
    local selected_relative
    local full_path
    local search_output

    # 1. Generate List (Relative Paths)
    # We cd into the dir first so fd/find outputs relative paths
    if command -v fd >/dev/null 2>&1; then
        # fd default is relative when no path arg is given
        search_output=$(cd "${SEARCH_DIR}" && fd --type f --hidden --exclude .git .)
    else
        # find outputs ./file, sed strips the leading ./ for clean UI
        search_output=$(cd "${SEARCH_DIR}" && find . -type f -not -path '*/.*' | sed 's|^\./||')
    fi

    # 2. Get Selection (Rofi displays clean relative paths)
    selected_relative=$(printf "%s\n" "$search_output" | "${ROFI_CMD[@]}" -theme-str 'window {width: 80%;}' -p "Search")

    # 3. Handle Selection
    if [[ -n "$selected_relative" ]]; then
        
        # RECONSTRUCT FULL PATH for execution
        full_path="${SEARCH_DIR}/${selected_relative}"

        # A. Handle Directories (Yazi)
        if [[ -d "$full_path" ]]; then
            run_term "$FILE_MANAGER \"$full_path\"" "yazi_filemanager"
        fi

        # B. Check MIME Type for Files
        local mime_type
        mime_type=$(file --mime-type -b "$full_path")

        case "$mime_type" in
            # Text/Code -> Open in Editor (Terminal)
            text/*|application/json|application/x-shellscript|application/toml|application/x-yaml|application/xml|application/x-conf|application/x-config)
                open_editor "$full_path"
                ;;
            # Empty files -> Open in Editor
            inode/x-empty)
                open_editor "$full_path"
                ;;
            # Everything else -> xdg-open (GUI)
            *)
                uwsm-app -- xdg-open "$full_path" >/dev/null 2>&1 &
                disown
                exit 0
                ;;
        esac
    else
        show_main_menu
    fi
}

show_learn_menu() {
    local choice
    choice=$(menu "Learn" "  Keybindings (List)\n󰣇  Arch Wiki\n  Hyprland Wiki")
    
    case "${choice,,}" in
        *keybind*) run_app "$SCRIPTS_DIR/rofi/keybindings.sh" ;;
        *arch*)    run_app xdg-open "https://wiki.archlinux.org/" ;;
        *hypr*)    run_app xdg-open "https://wiki.hypr.land/" ;;
        *)         show_main_menu ;;
    esac
}

show_ai_menu() {
    local choice
    choice=$(menu "AI Tools" "󰔊  TTS - Kokoro (GPU)\n󰔊  TTS - Kokoro (CPU)\n  STT - Faster Whisper\n  STT - Parakeet (GPU)\n󰍉  OCR Selection")

    case "${choice,,}" in
        *kokoro*gpu*) run_app "$SCRIPTS_DIR/tts_stt/kokoro_gpu/speak.sh" ;;
        *kokoro*cpu*) run_app "$SCRIPTS_DIR/tts_stt/kokoro_cpu/kokoro.sh" ;;
        *whisper*)    run_app "$SCRIPTS_DIR/tts_stt/faster_whisper/faster_whisper_sst.sh" ;;
        *parakeet*)   run_app "$SCRIPTS_DIR/tts_stt/parakeet/parakeet.sh" ;;
        *ocr*)
            if region=$(slurp); then
                grim -g "$region" - | tesseract stdin stdout -l eng | wl-copy
            fi
            exit 0 
            ;;
        *) show_main_menu ;;
    esac
}

show_visuals_menu() {
    local choice
    choice=$(menu "Visuals" "󰸌  Cycle Matugen Theme\n󰸌  Matugen Config\n  Wallpaper App\n  Rofi Wallpaper\n󱐋  Animations\n  Shaders\n  Hyprsunset Slider")
    
    case "${choice,,}" in
        *cycle*)     run_app "$SCRIPTS_DIR/theme_matugen/random_theme.sh" ;;
        *matugen*)   run_app "$SCRIPTS_DIR/theme_matugen/matugen_config.sh" ;;
        *rofi*wallpaper*) run_app "$SCRIPTS_DIR/rofi/rofi_wallpaper_selctor.sh" ;;
        *wallpaper*) run_app waypaper ;;
        *animation*) run_app rofi -show animations -modi "animations:$SCRIPTS_DIR/rofi/hypr_anim.sh" ;;
        *shader*)    run_app "$SCRIPTS_DIR/rofi/shader_menu.sh" ;;
        *sunset*)    run_app "$SCRIPTS_DIR/sliders/hyprsunset_slider.sh" ;;
        *)           show_main_menu ;;
    esac
}

show_utils_menu() {
    local choice
    choice=$(menu "Utils" "  Wi-Fi (TUI)\n󰂯  Bluetooth\n  Audio Mixer\n󰌾  Unlock Browser Drives\n  Lock Browser Drives")

    case "${choice,,}" in
        *wi-fi*)     run_term "wifitui" "wifitui" ;;
        *bluetooth*) run_app blueman-manager ;;
        *audio*)     run_app pavucontrol ;;
        *unlock*)    run_term "$SCRIPTS_DIR/drives/drive_manager.sh unlock browser" ;;
        *lock*)      run_term "$SCRIPTS_DIR/drives/drive_manager.sh lock browser" ;;
        *)           show_main_menu ;;
    esac
}

show_hardware_menu() {
    local choice
    choice=$(menu "Hardware" "󰍹  Refresh Rate: 144Hz (Gaming)\n󰍹  Refresh Rate: 48Hz (Battery)\n  ASUS Control Center\n󰍜  Toggle Waybar")

    case "${choice,,}" in
        *144hz*)
            hyprctl keyword monitor eDP-1,1920x1080@144,0x0,1.6 >/dev/null
            hyprctl keyword misc:vrr 1 >/dev/null
            exit 0
            ;;
        *48hz*)
            hyprctl keyword monitor eDP-1,1920x1080@48,0x0,1.6 >/dev/null
            hyprctl keyword misc:vrr 0 >/dev/null
            exit 0
            ;;
        *asus*)   run_term "sudo $SCRIPTS_DIR/asus/asusctl.sh" "asusctl" ;; 
        *waybar*) run_app "$SCRIPTS_DIR/waybar/toggle_timer_waybar.sh" ;;
        *)        show_main_menu ;;
    esac
}

show_config_menu() {
    local choice
    choice=$(menu "Edit Configs" "  Hyprland Main\n  Keybinds\n󱐋  Animations\n󰖲  Input\n󰍹  Monitors\n  Window Rules\n󰍜  Waybar\n  Hypridle\n  Hyprlock")

    case "${choice,,}" in
        *hyprland*)   open_editor "$HYPR_CONF/hyprland.conf" ;;
        *keybind*)    open_editor "$HYPR_SOURCE/keybinds.conf" ;;
        *animation*)  open_editor "$HYPR_SOURCE/animations/active/active.conf" ;;
        *input*)      open_editor "$HYPR_SOURCE/input.conf" ;;
        *monitor*)    open_editor "$HYPR_SOURCE/monitors.conf" ;;
        *window*)     open_editor "$HYPR_SOURCE/window_rules.conf" ;;
        *waybar*)     open_editor "$HOME/.config/waybar/config.jsonc" ;;
        *hypridle*)   open_editor "$HYPR_CONF/hypridle.conf" ;;
        *hyprlock*)   open_editor "$HYPR_CONF/hyprlock.conf" ;;
        *)            show_main_menu ;;
    esac
}

# --- ENTRY POINT ---

if [[ -n "${1:-}" ]]; then
    route_selection "$1"
else
    show_main_menu
fi
