#!/bin/bash

# ==============================================================================
#  ASUS CONTROL CENTER (v2025.12.4 - Production Ready)
#  Target: Arch Linux / Hyprland (TUF F15)
#  Fixes: Reserved word bug, signal handling, validation, efficiency
# ==============================================================================

set -o pipefail

# --- Colors (immutable constants) ---
readonly C_PURPLE="#bd93f9"
readonly C_PINK="#ff79c6"
readonly C_GREEN="#50fa7b"
readonly C_ORANGE="#ffb86c"
readonly C_RED="#ff5555"
readonly C_CYAN="#8be9fd"
readonly C_TEXT="#f8f8f2"

# --- Safety & Environment ---
export RUST_LOG=error

# --- Cleanup & Signal Handling ---
cleanup() {
    tput cnorm 2>/dev/null  # Restore cursor visibility
    stty echo 2>/dev/null   # Restore echo
    clear
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# --- Dependency Check ---
readonly REQUIRED_CMDS=(gum asusctl grep sed cut head tr)
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        printf '\e[31mError: Required command "%s" not found.\e[0m\n' "$cmd" >&2
        exit 1
    fi
done

# --- Root Check ---
if (( EUID != 0 )); then
    gum style --foreground "$C_RED" "Error: Must be run as root (sudo)."
    exit 1
fi

# --- Helper: Trim Whitespace (Pure Bash) ---
trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"   # Remove leading
    s="${s%"${s##*[![:space:]]}"}"   # Remove trailing
    printf '%s' "$s"
}

# --- Helper: Press Any Key ---
press_any_key() {
    printf '%s\n' "${1:-Press any key to continue...}"
    read -r -n 1 -s
}

# --- Helper: Clean asusctl Execution ---
exec_asus() {
    asusctl "$@" 2>&1 | grep -vE '^(\[|INFO|WARN|ERRO|ERROR|DEBUG|zbus)'
}

# --- Core Data Functions ---

get_active_profile() {
    local raw
    raw=$(exec_asus profile -p 2>/dev/null | grep -o 'Active profile is.*')
    if [[ -z "$raw" ]]; then
        printf 'Unknown'
        return 1
    fi
    raw="${raw#Active profile is }"
    trim "$raw"
}

get_fan_status_string() {
    local output
    output=$(exec_asus fan-curve -g 2>/dev/null | grep "CPU:")
    
    if [[ -z "$output" ]]; then
        gum style --foreground "$C_RED" "Error/BIOS"
        return 1
    fi

    if [[ "$output" == *"enabled: true"* ]]; then
        gum style --foreground "$C_GREEN" "ACTIVE (Custom)"
    else
        gum style --foreground "$C_ORANGE" "BIOS DEFAULT"
    fi
}

get_curve_preview() {
    local raw
    raw=$(exec_asus fan-curve -g 2>/dev/null | grep "CPU:" | cut -d',' -f2- | head -c 20)
    if [[ -z "$raw" ]]; then
        printf 'No Data'
    else
        printf '%s...' "$raw"
    fi
}

# --- The Dashboard ---
show_dashboard() {
    clear
    
    local profile fan_state curve_prev
    profile=$(get_active_profile)
    fan_state=$(get_fan_status_string)
    curve_prev=$(get_curve_preview)
    
    gum style --foreground "$C_PURPLE" --border-foreground "$C_PURPLE" \
        --border double --align center --width 50 --margin "1 1" \
        "ASUS CONTROL CENTER" "Ultimate Edition"

    gum style --foreground "$C_TEXT" --border rounded --padding "0 1" --margin "0 1" \
        " Profile:    $(gum style --foreground "$C_PINK" "$profile")" \
        " Fan State:  $fan_state" \
        " Curve Data: $(gum style --foreground "$C_ORANGE" "$curve_prev")"
        
    echo
}

# ==============================================================================
#  FAN CURVE LOGIC
# ==============================================================================

apply_curve_logic() {
    local profile_raw="$1"
    local curve_data="$2"
    local profile_clean
    
    profile_clean="${profile_raw,,}"
    profile_clean=$(trim "$profile_clean")

    if [[ -z "$profile_clean" ]]; then
        gum style --foreground "$C_RED" "Error: No profile specified."
        sleep 2
        return 1
    fi

    if [[ "$profile_clean" == "quiet" || "$profile_clean" == "silent" ]]; then
        gum style --foreground "$C_ORANGE" \
            "WARNING: 'Quiet' profile is often locked by BIOS."
        gum style --foreground "$C_ORANGE" \
            "Using Balanced profile is recommended."
        sleep 2
    fi

    gum style --foreground "$C_PURPLE" "Applying curves to profile: '$profile_clean'..."

    # Apply CPU curve
    if ! asusctl fan-curve -m "$profile_clean" -f cpu -D "$curve_data" >/dev/null 2>&1; then
        gum style --foreground "$C_RED" "Failed to write CPU curve."
        press_any_key
        return 1
    fi
    
    # Apply GPU curve
    if ! asusctl fan-curve -m "$profile_clean" -f gpu -D "$curve_data" >/dev/null 2>&1; then
        gum style --foreground "$C_RED" "Failed to write GPU curve."
        press_any_key
        return 1
    fi

    # Enable custom curves
    if asusctl fan-curve -m "$profile_clean" -e true >/dev/null 2>&1; then
        gum style --foreground "$C_GREEN" "SUCCESS: Custom curves enabled!"
    else
        gum style --foreground "$C_RED" "Failed to enable curves."
        gum style --foreground "$C_ORANGE" "Try switching profiles first, then retry."
    fi
    sleep 2
}

run_fan_wizard() {
    gum style --foreground "$C_CYAN" "Fan Curve Wizard (8 Points)"
    echo
    
    # NOTE: Using descriptive names to avoid reserved word 'fi'
    local start_temp start_fan temp_incr fan_incr
    
    start_temp=$(gum input --placeholder "Start Temp (e.g. 30)" --width 25)
    [[ -z "$start_temp" ]] && return 1
    
    start_fan=$(gum input --placeholder "Start Fan % (e.g. 10)" --width 25)
    [[ -z "$start_fan" ]] && return 1
    
    temp_incr=$(gum input --placeholder "Temp Increment (e.g. 10)" --width 25)
    [[ -z "$temp_incr" ]] && return 1
    
    fan_incr=$(gum input --placeholder "Fan % Increment (e.g. 12)" --width 25)
    [[ -z "$fan_incr" ]] && return 1

    # Validate all inputs are positive integers
    local var
    for var in "$start_temp" "$start_fan" "$temp_incr" "$fan_incr"; do
        if ! [[ "$var" =~ ^[0-9]+$ ]]; then
            gum style --foreground "$C_RED" "Invalid input: All values must be positive integers."
            sleep 2
            return 1
        fi
    done

    # Generate 8-point curve
    local -a points=()
    local i curr_temp curr_fan
    
    for i in {0..7}; do
        curr_temp=$(( start_temp + i * temp_incr ))
        (( curr_temp > 100 )) && curr_temp=100
        
        curr_fan=$(( start_fan + i * fan_incr ))
        (( curr_fan > 100 )) && curr_fan=100
        
        points+=("${curr_temp}c:${curr_fan}%")
    done
    
    local final_curve
    IFS=',' final_curve="${points[*]}"
    
    echo
    gum style --foreground "$C_ORANGE" "Generated curve:"
    gum style --foreground "$C_TEXT" "$final_curve"
    echo
    
    if gum confirm "Apply this curve to current profile?"; then
        apply_curve_logic "$(get_active_profile)" "$final_curve"
    fi
}

# ==============================================================================
#  AURA RGB LOGIC
# ==============================================================================

rgb_to_hex() {
    local input="$1"
    local r g b
    
    IFS=',' read -r r g b <<< "$input"
    
    # Trim whitespace (pure bash)
    r=$(trim "$r")
    g=$(trim "$g")
    b=$(trim "$b")

    # Validate all are numeric
    if ! [[ "$r" =~ ^[0-9]+$ && "$g" =~ ^[0-9]+$ && "$b" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Validate range 0-255
    if (( r > 255 || g > 255 || b > 255 )); then
        return 1
    fi
    
    printf '%02X%02X%02X' "$r" "$g" "$b"
}

pick_color() {
    local choice hex input
    
    choice=$(gum choose --cursor="➜ " --header "Select Color" \
        "Red" "Green" "Blue" "White" "Cyan" "Magenta" "Yellow" "Orange" "Purple" "Pink" \
        "Custom Hex" "Custom RGB" "Back")

    # Handle Cancellation (Esc) or Back
    [[ -z "$choice" || "$choice" == "Back" ]] && return 1

    case "$choice" in
        Red)      hex="FF0000" ;;
        Green)    hex="00FF00" ;;
        Blue)     hex="0000FF" ;;
        White)    hex="FFFFFF" ;;
        Cyan)     hex="00FFFF" ;;
        Magenta)  hex="FF00FF" ;;
        Yellow)   hex="FFFF00" ;;
        Orange)   hex="FFA500" ;;
        Purple)   hex="800080" ;;
        Pink)     hex="FFC0CB" ;;
        "Custom Hex")
            input=$(gum input --placeholder "e.g. #FF0000 or FF0000")
            [[ -z "$input" ]] && return 1
            
            # Remove # prefix, trim, uppercase (pure bash)
            hex="${input#\#}"
            hex=$(trim "$hex")
            hex="${hex^^}"
            ;;
        "Custom RGB")
            input=$(gum input --placeholder "e.g. 255,0,0")
            [[ -z "$input" ]] && return 1
            
            if ! hex=$(rgb_to_hex "$input"); then
                gum style --foreground "$C_RED" "Invalid RGB. Values must be 0-255."
                sleep 1
                return 1
            fi
            ;;
    esac
    
    # Final validation: Must be exactly 6 hex characters
    if ! [[ "$hex" =~ ^[0-9A-Fa-f]{6}$ ]]; then
        gum style --foreground "$C_RED" "Invalid hex format. Use 6 hex characters."
        sleep 1
        return 1
    fi
    
    printf '%s' "${hex^^}"
}

pick_speed() {
    local spd
    spd=$(gum choose --header "Select Speed" "Low" "Med" "High")
    [[ -z "$spd" ]] && return 1
    printf '%s' "${spd,,}"
}

menu_aura() {
    local mode color speed
    
    while true; do
        clear
        gum style --foreground "$C_CYAN" --border rounded \
            --padding "0 1" --align center "Keyboard Aura Manager"
        echo
        
        mode=$(gum choose --cursor="➜ " --header "Select Mode" \
            "Static (Single Color)" \
            "Breathe (Fade In/Out)" \
            "Rainbow Cycle (Global)" \
            "Pulse (Fast Blink)" \
            "Next Mode (Toggle)" \
            "Back")

        # Handle Escape or empty selection
        [[ -z "$mode" || "$mode" == "Back" ]] && break

        case "$mode" in
            "Static (Single Color)")
                if color=$(pick_color); then
                    gum style --foreground "$C_PURPLE" "Setting Static: #$color"
                    exec_asus aura static -c "$color" >/dev/null
                    sleep 0.5
                fi
                ;;
            "Breathe (Fade In/Out)")
                if color=$(pick_color); then
                    if speed=$(pick_speed); then
                        gum style --foreground "$C_PURPLE" "Setting Breathe: #$color @ $speed"
                        exec_asus aura breathe -c "$color" -s "$speed" >/dev/null
                        sleep 0.5
                    fi
                fi
                ;;
            "Pulse (Fast Blink)")
                if color=$(pick_color); then
                    if speed=$(pick_speed); then
                        gum style --foreground "$C_PURPLE" "Setting Pulse: #$color @ $speed"
                        exec_asus aura pulse -c "$color" -s "$speed" >/dev/null
                        sleep 0.5
                    fi
                fi
                ;;
            "Rainbow Cycle (Global)")
                if speed=$(pick_speed); then
                    gum style --foreground "$C_PURPLE" "Setting Rainbow Cycle @ $speed"
                    exec_asus aura rainbow-cycle -s "$speed" >/dev/null
                    sleep 0.5
                fi
                ;;
            "Next Mode (Toggle)")
                exec_asus aura -n >/dev/null
                gum style --foreground "$C_GREEN" "Toggled to next mode"
                sleep 0.5
                ;;
        esac
    done
}

# ==============================================================================
#  MENU FUNCTIONS
# ==============================================================================

menu_fans() {
    local active_prof choice curve
    active_prof=$(get_active_profile)
    
    choice=$(gum choose --cursor="➜ " --header "Fan Controls ($active_prof)" \
        "1. Wizard: Create Custom Curve" \
        "2. Preset: Silentish (Slow)" \
        "3. Preset: Balanced (Medium)" \
        "4. Preset: Turbo (Max)" \
        "5. Reset to BIOS Defaults" \
        "b. Back")

    # Handle empty (Escape pressed)
    [[ -z "$choice" || "$choice" == "b. Back" ]] && return
        
    case "$choice" in
        "1. Wizard: Create Custom Curve")
            run_fan_wizard
            return
            ;;
        "2. Preset: Silentish (Slow)")
            curve="50c:0%,60c:20%,70c:40%,80c:60%,90c:80%,95c:100%,100c:100%,100c:100%"
            ;;
        "3. Preset: Balanced (Medium)")
            curve="40c:10%,50c:25%,60c:40%,70c:55%,80c:70%,90c:85%,100c:100%,100c:100%"
            ;;
        "4. Preset: Turbo (Max)")
            curve="30c:100%,40c:100%,50c:100%,60c:100%,70c:100%,80c:100%,90c:100%,100c:100%"
            ;;
        "5. Reset to BIOS Defaults")
            if gum confirm "Reset fan curves to BIOS defaults?"; then
                local lower_prof="${active_prof,,}"
                lower_prof=$(trim "$lower_prof")
                if asusctl fan-curve -m "$lower_prof" -e false >/dev/null 2>&1; then
                    gum style --foreground "$C_GREEN" "Reset to BIOS defaults complete."
                else
                    gum style --foreground "$C_RED" "Failed to reset."
                fi
                sleep 1
            fi
            return
            ;;
    esac

    [[ -n "$curve" ]] && apply_curve_logic "$active_prof" "$curve"
}

menu_profiles() {
    local -a profiles
    local selected
    
    mapfile -t profiles < <(exec_asus profile -l 2>/dev/null | grep -E '^[a-zA-Z]+$' | grep -v "Active")
    
    # Fallback if no profiles detected
    (( ${#profiles[@]} == 0 )) && profiles=("Quiet" "Balanced" "Performance")
    
    profiles+=("Back")
    
    selected=$(gum choose --header "Switch Power Profile" "${profiles[@]}")
    
    if [[ -n "$selected" && "$selected" != "Back" ]]; then
        if asusctl profile -P "$selected" >/dev/null 2>&1; then
            gum style --foreground "$C_GREEN" "Switched to: $selected"
        else
            gum style --foreground "$C_RED" "Failed to switch profile."
        fi
        sleep 1
    fi
}

# ==============================================================================
#  MAIN ENTRY POINT
# ==============================================================================

main() {
    local action
    
    while true; do
        show_dashboard
        
        action=$(gum choose --cursor="➜ " --header "Main Menu" \
            "1. Manage Fan Curves" \
            "2. Switch Power Profile" \
            "3. Keyboard Aura (RGB)" \
            "q. Quit")
        
        case "$action" in
            "1. Manage Fan Curves")    menu_fans ;;
            "2. Switch Power Profile") menu_profiles ;;
            "3. Keyboard Aura (RGB)")  menu_aura ;;
            "q. Quit"|"")              break ;;
        esac
    done
    
    clear
}

main "$@"
