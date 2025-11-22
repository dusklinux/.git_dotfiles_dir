#!/bin/bash

# ==============================================================================
#  ASUS CONTROL CENTER (v2025.12.3 - Validation Fix)
#  Target: Arch Linux / Hyprland (TUF F15)
#  Fixes: "Red Default" bug on cancel; Empty input handling
# ==============================================================================

# --- Colors ---
C_PURPLE="#bd93f9"
C_PINK="#ff79c6"
C_GREEN="#50fa7b"
C_ORANGE="#ffb86c"
C_RED="#ff5555"
C_CYAN="#8be9fd"
C_TEXT="#f8f8f2"

# --- Safety & Environment ---
export RUST_LOG=error 

# Ensure dependencies exist
for cmd in gum asusctl grep sed; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "\e[31mError: Required command '$cmd' not found.\e[0m"
        exit 1
    fi
done

if [ "$EUID" -ne 0 ]; then
    gum style --foreground "$C_RED" "Error: Must be run as root (sudo)."
    exit 1
fi

# --- Helper: Clean Execution ---
exec_asus() {
    asusctl "$@" 2>&1 | grep -vE "^(\[|INFO|WARN|ERRO|zbus)"
}

# --- Core Data Functions ---

get_active_profile() {
    local raw
    raw=$(exec_asus profile -p | grep "Active profile is")
    if [ -z "$raw" ]; then echo "Unknown"; else echo "$raw" | sed 's/Active profile is //' | xargs; fi
}

get_fan_status_string() {
    local output
    output=$(exec_asus fan-curve -g | grep "CPU:")
    if [ -z "$output" ]; then echo "$(gum style --foreground "$C_RED" "Error/BIOS")"; return; fi

    if echo "$output" | grep -q "enabled: true"; then
        echo "$(gum style --foreground "$C_GREEN" "ACTIVE (Custom)")"
    else
        echo "$(gum style --foreground "$C_ORANGE" "BIOS DEFAULT")"
    fi
}

get_curve_preview() {
    local raw
    raw=$(exec_asus fan-curve -g | grep "CPU:" | cut -d',' -f2- | head -c 20)
    if [ -z "$raw" ]; then echo "No Data"; else echo "${raw}..."; fi
}

# --- The Dashboard ---
show_dashboard() {
    clear
    local profile=$(get_active_profile)
    local fan_state=$(get_fan_status_string)
    local curve_prev=$(get_curve_preview)
    
    gum style --foreground "$C_PURPLE" --border-foreground "$C_PURPLE" --border double --align center --width 50 --margin "1 1" \
        "ASUS CONTROL CENTER" "Ultimate Edition"

    gum style --foreground "$C_TEXT" --border rounded --padding "0 1" --margin "0 1" \
        " Profile:    $(gum style --foreground "$C_PINK" "$profile")" \
        " Fan State:  $fan_state" \
        " Curve Data: $(gum style --foreground "$C_ORANGE" "$curve_prev")"
        
    echo ""
}

# --- Fan Logic ---

apply_curve_logic() {
    local profile_raw="$1"
    local curve_data="$2"
    local profile_clean="${profile_raw,,}"
    profile_clean=$(echo "$profile_clean" | xargs)

    if [[ "$profile_clean" == "quiet" || "$profile_clean" == "silent" ]]; then
        gum style --foreground "$C_ORANGE" "WARNING: 'Quiet' profile is usually locked by BIOS. Using Balanced recommended."
        sleep 2
    fi

    gum style --foreground "$C_PURPLE" "Applying to: '$profile_clean'..."

    if ! asusctl fan-curve -m "$profile_clean" -f cpu -D "$curve_data" > /dev/null 2>&1; then
        gum style --foreground "$C_RED" "Failed to write CPU curve."; read -n 1 -s -r -p "Press key..."; return
    fi
    if ! asusctl fan-curve -m "$profile_clean" -f gpu -D "$curve_data" > /dev/null 2>&1; then
        gum style --foreground "$C_RED" "Failed to write GPU curve."; read -n 1 -s -r -p "Press key..."; return
    fi

    if asusctl fan-curve -m "$profile_clean" -e true > /dev/null 2>&1; then
        gum style --foreground "$C_GREEN" "SUCCESS: Curves Enabled."
    else
        gum style --foreground "$C_RED" "Failed to enable. Try switching profiles first."
    fi
    sleep 2
}

run_fan_wizard() {
    gum style --foreground "$C_CYAN" "Fan Curve Wizard (8 Points)"
    
    local st=$(gum input --placeholder "Start Temp (e.g. 30)" --width 20)
    local sf=$(gum input --placeholder "Start Fan % (e.g. 10)" --width 20)
    local ti=$(gum input --placeholder "Temp Increment (e.g. 10)" --width 20)
    local fi=$(gum input --placeholder "Fan % Increment (e.g. 12)" --width 20)

    if ! [[ "$st" =~ ^[0-9]+$ && "$sf" =~ ^[0-9]+$ && "$ti" =~ ^[0-9]+$ && "$fi" =~ ^[0-9]+$ ]]; then
        gum style --foreground "$C_RED" "Invalid numbers entered."
        sleep 2; return
    fi

    declare -a points
    for i in {0..7}; do
        ct=$((st + i * ti)); [ $ct -gt 100 ] && ct=100
        cf=$((sf + i * fi)); [ $cf -gt 100 ] && cf=100
        points+=("${ct}c:${cf}%")
    done
    
    local final_curve=$(IFS=,; echo "${points[*]}")
    gum style --foreground "$C_ORANGE" "Generated: $final_curve"
    if gum confirm "Apply this curve?"; then
        apply_curve_logic "$(get_active_profile)" "$final_curve"
    fi
}

# --- Aura Logic (RGB & Speed) ---

rgb_to_hex() {
    local r g b
    IFS=',' read -r r g b <<< "$1"
    r=$(echo "$r" | xargs); g=$(echo "$g" | xargs); b=$(echo "$b" | xargs)

    if ! [[ "$r" =~ ^[0-9]+$ && "$g" =~ ^[0-9]+$ && "$b" =~ ^[0-9]+$ ]]; then
        echo "FAIL"; return 1
    fi
    printf "%02X%02X%02X\n" "$r" "$g" "$b"
}

pick_color() {
    local choice=$(gum choose --cursor="➜ " --header "Select Color" \
        "Red" "Green" "Blue" "White" "Cyan" "Magenta" "Yellow" "Orange" "Purple" "Pink" \
        "Custom Hex" "Custom RGB" "Back")

    local hex=""
    
    # Handle Cancellation (Esc)
    if [[ -z "$choice" || "$choice" == "Back" ]]; then
        return 1
    fi

    case "$choice" in
        "Red") hex="FF0000" ;;
        "Green") hex="00FF00" ;;
        "Blue") hex="0000FF" ;;
        "White") hex="FFFFFF" ;;
        "Cyan") hex="00FFFF" ;;
        "Magenta") hex="FF00FF" ;;
        "Yellow") hex="FFFF00" ;;
        "Orange") hex="FFA500" ;;
        "Purple") hex="800080" ;;
        "Pink") hex="FFC0CB" ;;
        "Custom Hex") 
             local input=$(gum input --placeholder "e.g. #FF0000 or FF0000")
             # Remove #, whitespace, uppercase
             hex=$(echo "$input" | sed 's/#//g' | xargs | tr '[:lower:]' '[:upper:]')
             ;;
        "Custom RGB")
             local input=$(gum input --placeholder "e.g. 255,0,0")
             hex=$(rgb_to_hex "$input")
             if [[ "$hex" == "FAIL" ]]; then
                # Return empty on failure implies abort
                return 1
             fi
             ;;
    esac
    
    # Strict Validation: If invalid, return Error Code (1) instead of Red
    if ! [[ $hex =~ ^[0-9A-F]{6}$ ]]; then
         return 1
    fi
    
    echo "$hex"
}

pick_speed() {
    local spd=$(gum choose --header "Select Speed" "Low" "Med" "High")
    if [[ -z "$spd" ]]; then return 1; fi
    echo "${spd,,}" 
}

menu_aura() {
    while true; do
        clear
        gum style --foreground "$C_CYAN" --border rounded --padding "0 1" --align center "Keyboard Aura Manager"
        
        local mode=$(gum choose --cursor="➜ " --header "Select Mode" \
            "Static (Single Color)" \
            "Breathe (Fade In/Out)" \
            "Rainbow Cycle (Global)" \
            "Pulse (Fast Blink)" \
            "Next Mode (Toggle)" \
            "Back")

        case "$mode" in
            "Static (Single Color)")
                local color=$(pick_color)
                # Validation: If pick_color failed/cancelled (returned empty), do nothing
                if [[ -n "$color" ]]; then
                    gum style --foreground "$C_PURPLE" "Setting Static: #$color"
                    exec_asus aura static -c "$color" >/dev/null
                fi
                ;;
            "Breathe (Fade In/Out)")
                local color=$(pick_color)
                if [[ -n "$color" ]]; then
                    local speed=$(pick_speed)
                    if [[ -n "$speed" ]]; then
                        gum style --foreground "$C_PURPLE" "Setting Breathe: #$color ($speed)"
                        exec_asus aura breathe -c "$color" -s "$speed" >/dev/null
                    fi
                fi
                ;;
            "Pulse (Fast Blink)")
                local color=$(pick_color)
                if [[ -n "$color" ]]; then
                    local speed=$(pick_speed)
                    if [[ -n "$speed" ]]; then
                         gum style --foreground "$C_PURPLE" "Setting Pulse: #$color ($speed)"
                         exec_asus aura pulse -c "$color" -s "$speed" >/dev/null
                    fi
                fi
                ;;
            "Rainbow Cycle (Global)")
                local speed=$(pick_speed)
                if [[ -n "$speed" ]]; then
                    gum style --foreground "$C_PURPLE" "Setting Rainbow Cycle ($speed)"
                    exec_asus aura rainbow-cycle -s "$speed" >/dev/null
                fi
                ;;
            "Next Mode (Toggle)")
                exec_asus aura -n >/dev/null
                gum style --foreground "$C_GREEN" "Toggled Next Mode"
                ;;
            "Back"|"") # Handle explicit Back or Esc
                break 
                ;;
        esac
        sleep 0.2
    done
}

# --- Menus ---

menu_fans() {
    local active_prof=$(get_active_profile)
    local choice=$(gum choose --cursor="➜ " --header "Fan Controls ($active_prof)" \
        "1. Wizard: Create Custom Curve" \
        "2. Preset: Silentish (Slow)" \
        "3. Preset: Balanced (Medium)" \
        "4. Preset: Turbo (Max)" \
        "5. Reset to BIOS Defaults" \
        "b. Back")
        
    local curve=""
    case "$choice" in
        "1. Wizard: Create Custom Curve") run_fan_wizard; return ;;
        "2. Preset: Silentish (Slow)") curve="50c:0%,60c:20%,70c:40%,80c:60%,90c:80%,95c:100%,100c:100%,100c:100%" ;;
        "3. Preset: Balanced (Medium)") curve="40c:10%,50c:25%,60c:40%,70c:55%,80c:70%,90c:85%,100c:100%,100c:100%" ;;
        "4. Preset: Turbo (Max)") curve="30c:100%,40c:100%,50c:100%,60c:100%,70c:100%,80c:100%,90c:100%,100c:100%" ;;
        "5. Reset to BIOS Defaults")
            if gum confirm "Reset to defaults?"; then
                local lower_prof=$(echo "$active_prof" | tr '[:upper:]' '[:lower:]' | xargs)
                asusctl fan-curve -m "$lower_prof" -e false >/dev/null 2>&1
                gum style --foreground "$C_GREEN" "Reset Complete."
                sleep 1
            fi
            return ;;
        "b. Back") return ;;
    esac

    if [ -n "$curve" ]; then apply_curve_logic "$active_prof" "$curve"; fi
}

menu_profiles() {
    mapfile -t profiles < <(exec_asus profile -l | grep -E "^[a-zA-Z]+$" | grep -v "Active")
    if [ ${#profiles[@]} -eq 0 ]; then profiles=("Quiet" "Balanced" "Performance"); fi
    profiles+=("Back")
    local selected=$(gum choose --header "Switch Power Profile" "${profiles[@]}")
    if [[ "$selected" != "Back" && -n "$selected" ]]; then
        asusctl profile -P "$selected" >/dev/null 2>&1
        gum style --foreground "$C_GREEN" "Switched to $selected"
        sleep 1
    fi
}

# --- Main Loop ---
while true; do
    show_dashboard
    ACTION=$(gum choose --cursor="➜ " --header "Main Menu" "1. Manage Fan Curves" "2. Switch Power Profile" "3. Keyboard Aura" "q. Quit")
    case "$ACTION" in
        "1. Manage Fan Curves") menu_fans ;;
        "2. Switch Power Profile") menu_profiles ;;
        "3. Keyboard Aura") menu_aura ;;
        "q. Quit") clear; exit 0 ;;
    esac
done
