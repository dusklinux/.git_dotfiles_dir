#!/bin/bash

# ==============================================================================
#  ASUS CONTROL CENTER (v2025.12.7 - Arch/Hyprland Edition)
#  Target: ASUS TUF/ROG Laptops
#  Features: Multi-State Power Monitor, Fan Curves, Aura RGB, Clean UI
# ==============================================================================

set -o pipefail

# --- Colors (Dracula Theme) ---
readonly C_PURPLE="#bd93f9"
readonly C_PINK="#ff79c6"
readonly C_GREEN="#50fa7b"
readonly C_ORANGE="#ffb86c"
readonly C_RED="#ff5555"
readonly C_CYAN="#8be9fd"
readonly C_TEXT="#f8f8f2"
readonly C_GREY="#6272a4"

# --- Environment ---
export RUST_LOG=error

# --- Cleanup ---
cleanup() {
    tput cnorm 2>/dev/null
    stty echo 2>/dev/null
    clear
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# --- Dependency Check ---
readonly REQUIRED_CMDS=(gum asusctl grep sed awk cut)
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required command '$cmd' not found."
        exit 1
    fi
done

# --- Root Check ---
if (( EUID != 0 )); then
    gum style --foreground "$C_RED" "Error: Must be run as root (sudo)."
    exit 1
fi

# --- Helpers ---

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

press_any_key() {
    gum style --foreground "$C_GREY" "${1:-Press any key to continue...}"
    read -r -n 1 -s
}

# --- Core Execution Wrapper ---
# Filters out the zbus/tracing noise provided in the logs
exec_asus() {
    asusctl "$@" 2>&1 | grep -vE '^(\[|INFO|WARN|ERRO|ERROR|DEBUG|zbus|Optional|Starting)'
}

# --- RGB & Color Logic (Ported & Integrated) ---

rgb_to_hex() {
    local input="$1"
    local r g b
    
    IFS=',' read -r r g b <<< "$input"
    
    r=$(trim "$r")
    g=$(trim "$g")
    b=$(trim "$b")

    # Validate numeric and range 0-255
    if ! [[ "$r" =~ ^[0-9]+$ && "$g" =~ ^[0-9]+$ && "$b" =~ ^[0-9]+$ ]]; then
        return 1
    fi
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
            hex="${input#\#}"
            hex=$(trim "$hex")
            hex="${hex^^}"
            ;;
        "Custom RGB")
            input=$(gum input --placeholder "e.g. 255,0,0")
            [[ -z "$input" ]] && return 1
            if ! hex=$(rgb_to_hex "$input"); then
                gum style --foreground "$C_RED" "Invalid RGB. Values must be 0-255." >&2
                sleep 1
                return 1
            fi
            ;;
    esac
    
    # Validation
    if ! [[ "$hex" =~ ^[0-9A-Fa-f]{6}$ ]]; then
        gum style --foreground "$C_RED" "Invalid hex format. Use 6 hex characters." >&2
        sleep 1
        return 1
    fi
    
    printf '%s' "${hex^^}"
}

# --- Data Fetching ---

# Fetches Active, AC, and Battery profiles in one go
get_power_states() {
    local raw active ac bat
    raw=$(exec_asus profile -p)
    
    # Parse based on standard output format:
    active=$(echo "$raw" | grep "Active profile" | awk '{print $NF}')
    ac=$(echo "$raw" | grep "Profile on AC" | awk '{print $NF}')
    bat=$(echo "$raw" | grep "Profile on Battery" | awk '{print $NF}')

    [[ -z "$active" ]] && active="Unknown"
    [[ -z "$ac" ]] && ac="Unknown"
    [[ -z "$bat" ]] && bat="Unknown"

    printf "%s|%s|%s" "$active" "$ac" "$bat"
}

get_fan_status() {
    local output
    output=$(exec_asus fan-curve -g 2>/dev/null | grep "CPU:")
    if [[ "$output" == *"enabled: true"* ]]; then
        gum style --foreground "$C_GREEN" "CUSTOM CURVE"
    else
        gum style --foreground "$C_ORANGE" "BIOS DEFAULT"
    fi
}

# --- Dashboard ---
show_dashboard() {
    clear
    local p_states fan_state active ac bat
    
    p_states=$(get_power_states)
    IFS='|' read -r active ac bat <<< "$p_states"
    
    fan_state=$(get_fan_status)
    
    gum style --foreground "$C_PURPLE" --border double --align center --width 60 --margin "1 1" \
        "ASUS CONTROL CENTER"
    
    # Grid layout for power states
    gum join --horizontal --align center \
        "$(gum style --width 20 --border rounded --padding "0 1" --foreground "$C_PINK" "ACTIVE" "$active")" \
        "$(gum style --width 20 --border rounded --padding "0 1" --foreground "$C_CYAN" "AC POLICY" "$ac")" \
        "$(gum style --width 20 --border rounded --padding "0 1" --foreground "$C_ORANGE" "BAT POLICY" "$bat")"

    gum style --align center --foreground "$C_TEXT" --margin "0 1" \
        "Fan Strategy: $fan_state"
    echo
}

# ==============================================================================
#  KEYBOARD (Aura & Brightness)
# ==============================================================================

set_brightness() {
    local choice level_arg led_path int_val
    
    choice=$(gum choose --header "Select Brightness Level" \
        "Off (0)" \
        "Low (1)" \
        "Medium (2)" \
        "High (3)" \
        "Back")

    [[ "$choice" == "Back" || -z "$choice" ]] && return

    # Map text to integer
    case "$choice" in
        "Off"*)    int_val=0; level_arg="off" ;;
        "Low"*)    int_val=1; level_arg="low" ;;
        "Medium"*) int_val=2; level_arg="med" ;;
        "High"*)   int_val=3; level_arg="high" ;;
    esac

    gum style --foreground "$C_PURPLE" "Setting brightness to: $choice..."
    
    if exec_asus -k "$level_arg" >/dev/null 2>&1; then
        gum style --foreground "$C_GREEN" "Done."
    else
        led_path="/sys/class/leds/asus::kbd_backlight/brightness"
        if [[ -f "$led_path" ]]; then
            echo "$int_val" > "$led_path"
            gum style --foreground "$C_GREEN" "Applied via sysfs."
        else
            gum style --foreground "$C_RED" "Failed: Could not control keyboard brightness."
        fi
    fi
    sleep 0.5
}

menu_keyboard() {
    local hex
    while true; do
        clear
        gum style --foreground "$C_CYAN" --border rounded "Keyboard Control"
        echo
        
        local choice
        choice=$(gum choose --cursor="➜ " --header "Select Action" \
            "Set Brightness (0-3)" \
            "Aura: Static Color" \
            "Aura: Breathe" \
            "Aura: Rainbow Cycle" \
            "Aura: Pulse" \
            "Back")

        [[ -z "$choice" || "$choice" == "Back" ]] && break

        case "$choice" in
            "Set Brightness"*) 
                set_brightness 
                ;;
            "Aura: Static"*)
                if hex=$(pick_color); then
                    exec_asus aura static -c "${hex}" >/dev/null
                    gum style --foreground "$C_GREEN" "Static color applied ($hex)"
                    sleep 0.5
                fi
                ;;
            "Aura: Breathe"*)
                if hex=$(pick_color); then
                     exec_asus aura breathe -c "${hex}" -s "med" >/dev/null
                     gum style --foreground "$C_GREEN" "Breath effect active ($hex)"
                     sleep 0.5
                fi
                ;;
            "Aura: Rainbow"*)
                exec_asus aura rainbow-cycle -s "med" >/dev/null
                gum style --foreground "$C_GREEN" "Rainbow cycle active"
                sleep 0.5
                ;;
            "Aura: Pulse"*)
                if hex=$(pick_color); then
                    exec_asus aura pulse -c "${hex}" -s "med" >/dev/null
                    gum style --foreground "$C_GREEN" "Pulse active ($hex)"
                    sleep 0.5
                fi
                ;;
        esac
    done
}

# ==============================================================================
#  POWER PROFILES
# ==============================================================================

menu_profiles() {
    local -a profiles
    # Get available profiles
    mapfile -t profiles < <(exec_asus profile -l 2>/dev/null | grep -E '^[a-zA-Z]+$' | grep -v "Active")
    (( ${#profiles[@]} == 0 )) && profiles=("Quiet" "Balanced" "Performance")

    local target
    target=$(gum choose --header "Apply Profile To..." \
        "Active Session Only" \
        "AC Power Default" \
        "Battery Default" \
        "GLOBAL (All Sources)" \
        "Back")

    [[ "$target" == "Back" || -z "$target" ]] && return

    local selected_prof
    selected_prof=$(gum choose --header "Select Profile" "${profiles[@]}")
    [[ -z "$selected_prof" ]] && return

    gum style --foreground "$C_PURPLE" "Applying $selected_prof..."

    case "$target" in
        "Active"*)  exec_asus profile -P "$selected_prof" ;;
        "AC"*)      exec_asus profile -a "$selected_prof" ;;
        "Battery"*) exec_asus profile -b "$selected_prof" ;;
        "GLOBAL"*)
            exec_asus profile -P "$selected_prof" >/dev/null
            exec_asus profile -a "$selected_prof" >/dev/null
            exec_asus profile -b "$selected_prof" >/dev/null
            ;;
    esac
    
    gum style --foreground "$C_GREEN" "Profile Updated."
    sleep 1
}

# ==============================================================================
#  FAN CURVES
# ==============================================================================

run_fan_wizard() {
    gum style --foreground "$C_CYAN" "Fan Curve Wizard (Interpolation)" >&2
    echo >&2
    
    local min_temp max_temp min_fan max_fan
    
    # 1. Get Start/End Points instead of increments
    min_temp=$(gum input --placeholder "Start Temp (e.g. 30)" --width 25)
    [[ -z "$min_temp" ]] && return 1
    
    max_temp=$(gum input --placeholder "End Temp (e.g. 90)" --value "95" --width 25)
    [[ -z "$max_temp" ]] && return 1

    min_fan=$(gum input --placeholder "Start Fan % (e.g. 0)" --width 25)
    [[ -z "$min_fan" ]] && return 1

    max_fan=$(gum input --placeholder "End Fan % (e.g. 100)" --value "100" --width 25)
    [[ -z "$max_fan" ]] && return 1

    # Validate inputs
    for var in "$min_temp" "$max_temp" "$min_fan" "$max_fan"; do
        if ! [[ "$var" =~ ^[0-9]+$ ]]; then
            gum style --foreground "$C_RED" "Invalid input: Integers only." >&2
            sleep 2
            return 1
        fi
    done

    # Logic Check: Start must be less than End
    if (( min_temp >= max_temp || min_fan > max_fan )); then
        gum style --foreground "$C_RED" "Error: Start values must be lower than End values." >&2
        sleep 2
        return 1
    fi

    # 2. Calculate the 8 points using Linear Interpolation (awk for precision)
    # Formula: v = start + (end - start) * (i / 7)
    local raw_points
    raw_points=$(awk -v t1="$min_temp" -v t2="$max_temp" \
                     -v f1="$min_fan"  -v f2="$max_fan" '
    BEGIN {
        for(i=0; i<8; i++) {
            # Calculate ratio (0.0 to 1.0)
            r = i / 7;
            
            # Interpolate Temp
            t = t1 + (t2 - t1) * r;
            
            # Interpolate Fan
            f = f1 + (f2 - f1) * r;
            
            # Round to integer and print
            printf "%.0fc:%.0f%%", t, f;
            
            if(i<7) printf ",";
        }
    }')
    
    echo >&2
    gum style --foreground "$C_ORANGE" "Generated smooth curve:" >&2
    gum style --foreground "$C_TEXT" "$raw_points" >&2
    echo >&2
    
    if gum confirm "Apply this curve?"; then
        echo "$raw_points"
    else
        return 1
    fi
}

menu_fans() {
    local p_states active ac bat choice curve
    
    # Get just the active profile for display
    p_states=$(get_power_states)
    IFS='|' read -r active ac bat <<< "$p_states"
    
    choice=$(gum choose --cursor="➜ " --header "Fan Controls ($active)" \
        "Wizard: Create Custom Curve" \
        "Preset: Silentish" \
        "Preset: Balanced" \
        "Preset: Turbo" \
        "Reset to BIOS Defaults" \
        "Back")

    [[ -z "$choice" || "$choice" == "Back" ]] && return

    case "$choice" in
        "Wizard"*) 
             curve=$(run_fan_wizard)
             # If wizard was cancelled/failed, curve will be empty
             [[ -z "$curve" ]] && return
             ;;
        "Preset: Silentish") curve="50c:0%,60c:20%,70c:40%,80c:60%,90c:80%,95c:100%,100c:100%,100c:100%" ;;
        "Preset: Balanced")  curve="40c:10%,50c:25%,60c:40%,70c:55%,80c:70%,90c:85%,100c:100%,100c:100%" ;;
        "Preset: Turbo")     curve="30c:100%,40c:100%,50c:100%,60c:100%,70c:100%,80c:100%,90c:100%,100c:100%" ;;
        "Reset"*)
            if gum confirm "Reset to BIOS defaults?"; then
                local prof_arg="${active,,}"
                prof_arg=$(trim "$prof_arg")
                exec_asus fan-curve -m "$prof_arg" -e false >/dev/null 2>&1
                gum style --foreground "$C_GREEN" "Reset complete."
                sleep 1
            fi
            return 
            ;;
    esac

    if [[ -n "$curve" ]]; then
        local prof_arg="${active,,}"
        prof_arg=$(trim "$prof_arg")
        gum style --foreground "$C_PURPLE" "Applying curve to $active..."
        exec_asus fan-curve -m "$prof_arg" -f cpu -D "$curve" >/dev/null
        exec_asus fan-curve -m "$prof_arg" -f gpu -D "$curve" >/dev/null
        exec_asus fan-curve -m "$prof_arg" -e true >/dev/null
        gum style --foreground "$C_GREEN" "Curve Applied."
        sleep 1
    fi
}

# ==============================================================================
#  MAIN LOOP
# ==============================================================================

main() {
    local action
    while true; do
        show_dashboard
        
        # Pure list selection (Vim/Arrow keys only)
        action=$(gum choose --cursor="➜ " --header "Main Menu" \
            "Manage Fan Curves" \
            "Power Profiles" \
            "Keyboard Control" \
            "Quit")
        
        case "$action" in
            "Manage Fan Curves")          menu_fans ;;
            "Power Profiles")             menu_profiles ;;
            "Keyboard Control")           menu_keyboard ;;
            "Quit"|"")                    break ;;
        esac
    done
    clear
}

main "$@"
