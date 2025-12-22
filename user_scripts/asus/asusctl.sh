#!/bin/bash
# ==============================================================================
#  ASUS CONTROL CENTER (v2025.12.8 - Arch/Hyprland Edition)
#  Target: ASUS TUF/ROG Laptops
#  Features: Multi-State Power Monitor, Fan Curves, Aura RGB, Battery Limit
#  Requires: bash 5+, gum, asusctl
# ==============================================================================

set -o pipefail

# --- Constants (Dracula Theme) ---
declare -r C_PURPLE="#bd93f9"
declare -r C_PINK="#ff79c6"
declare -r C_GREEN="#50fa7b"
declare -r C_ORANGE="#ffb86c"
declare -r C_RED="#ff5555"
declare -r C_CYAN="#8be9fd"
declare -r C_TEXT="#f8f8f2"
declare -r C_GREY="#6272a4"
declare -r C_YELLOW="#f1fa8c"

# Version
declare -r VERSION="2025.12.8"

# --- Environment ---
export RUST_LOG=error

# --- State Variables ---
declare -i CLEANUP_DONE=0

# --- Cleanup ---
cleanup() {
    # Prevent re-entry
    (( CLEANUP_DONE )) && return
    CLEANUP_DONE=1
    
    tput cnorm 2>/dev/null  # Restore cursor
    stty echo 2>/dev/null   # Restore echo
    clear
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# --- Dependency Check ---
declare -ra REQUIRED_CMDS=(gum asusctl awk)
check_dependencies() {
    local cmd missing=()
    for cmd in "${REQUIRED_CMDS[@]}"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    
    if (( ${#missing[@]} )); then
        printf 'Error: Missing required commands: %s\n' "${missing[*]}" >&2
        exit 1
    fi
    
    # Version check for bash 5+ features
    if (( BASH_VERSINFO[0] < 5 )); then
        printf 'Error: Bash 5+ required (found: %s)\n' "$BASH_VERSION" >&2
        exit 1
    fi
}
check_dependencies

# --- Root Check ---
if (( EUID != 0 )); then
    # Attempt to use gum if available, fallback to echo
    if command -v gum &>/dev/null; then
        gum style --foreground "$C_RED" "Error: Must be run as root (sudo)."
    else
        echo "Error: Must be run as root (sudo)." >&2
    fi
    exit 1
fi

# ==============================================================================
#  UTILITY FUNCTIONS
# ==============================================================================

# Pure bash trim - no external commands
trim() {
    local s="${1-}"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# Core execution wrapper - filters zbus/tracing noise
exec_asus() {
    local output rc
    output=$(asusctl "$@" 2>&1)
    rc=$?
    # Filter noise lines but preserve meaningful output
    grep -vE '^(\[|INFO|WARN|ERRO|ERROR|DEBUG|zbus|Optional|Starting version)' <<< "$output"
    return "$rc"
}

# Styled notification helpers
notify_success() {
    gum style --foreground "$C_GREEN" "✓ ${1:-Done}"
}

notify_error() {
    gum style --foreground "$C_RED" "✗ ${1:-Error}"
}

notify_info() {
    gum style --foreground "$C_CYAN" "➜ ${1:-Info}"
}

# ==============================================================================
#  RGB & COLOR LOGIC
# ==============================================================================

rgb_to_hex() {
    local input="$1" r g b
    
    IFS=',' read -r r g b <<< "$input"
    
    # Trim whitespace
    r=$(trim "$r")
    g=$(trim "$g")
    b=$(trim "$b")

    # Validate: must be integers
    if ! [[ "$r$g$b" =~ ^[0-9]+$ ]] || [[ -z "$r" || -z "$g" || -z "$b" ]]; then
        return 1
    fi
    
    # Validate: range 0-255
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

    case "${choice:-Back}" in
        Back) return 1 ;;
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
            input=$(gum input --placeholder "e.g. #FF0000 or FF0000" --width 30)
            [[ -z "$input" ]] && return 1
            # Remove # prefix, trim, uppercase
            hex="${input#\#}"
            hex=$(trim "$hex")
            hex="${hex^^}"
            ;;
        "Custom RGB")
            input=$(gum input --placeholder "e.g. 255,0,0" --width 30)
            [[ -z "$input" ]] && return 1
            if ! hex=$(rgb_to_hex "$input"); then
                notify_error "Invalid RGB. Values must be 0-255."
                sleep 1
                return 1
            fi
            ;;
    esac
    
    # Final hex validation
    if ! [[ "${hex:-}" =~ ^[0-9A-F]{6}$ ]]; then
        notify_error "Invalid hex format. Use 6 hex characters."
        sleep 1
        return 1
    fi
    
    printf '%s' "$hex"
}

# ==============================================================================
#  DATA FETCHING
# ==============================================================================

# Returns: "active|ac|battery" pipe-separated string
get_power_states() {
    local raw active ac bat
    raw=$(exec_asus profile -p 2>/dev/null)
    
    # Single awk call with multiple pattern matches
    read -r active ac bat < <(awk '
        /Active profile/     { active = $NF }
        /Profile on AC/      { ac = $NF }
        /Profile on Battery/ { bat = $NF }
        END { 
            printf "%s %s %s", 
                (active ? active : "Unknown"),
                (ac ? ac : "Unknown"),
                (bat ? bat : "Unknown")
        }
    ' <<< "$raw")

    printf '%s|%s|%s' "${active:-Unknown}" "${ac:-Unknown}" "${bat:-Unknown}"
}

get_fan_status() {
    local output
    output=$(exec_asus fan-curve -g 2>/dev/null)
    
    if grep -q "CPU:.*enabled: true" <<< "$output" 2>/dev/null; then
        gum style --foreground "$C_GREEN" "CUSTOM CURVE"
    else
        gum style --foreground "$C_ORANGE" "BIOS DEFAULT"
    fi
}

get_charge_limit() {
    local limit
    # Try to read from sysfs first (most reliable)
    local sysfs_path="/sys/class/power_supply/BAT0/charge_control_end_threshold"
    
    if [[ -r "$sysfs_path" ]]; then
        limit=$(<"$sysfs_path")
    else
        # Fallback: parse from asusctl output if available
        limit=$(exec_asus -s 2>/dev/null | awk '/[Cc]harge.*[Ll]imit|[Cc]hg.*[Ll]imit/ {print $NF; exit}')
    fi
    
    # Validate and return
    if [[ "$limit" =~ ^[0-9]+$ ]] && (( limit >= 20 && limit <= 100 )); then
        printf '%d' "$limit"
    else
        printf '%s' "N/A"
    fi
}

# ==============================================================================
#  DASHBOARD
# ==============================================================================

show_dashboard() {
    clear
    local p_states fan_state active ac bat charge_limit
    
    # Fetch all states
    p_states=$(get_power_states)
    IFS='|' read -r active ac bat <<< "$p_states"
    fan_state=$(get_fan_status)
    charge_limit=$(get_charge_limit)
    
    # Header
    gum style --foreground "$C_PURPLE" --border double --align center --width 62 --margin "1 1" \
        "ASUS CONTROL CENTER v$VERSION"
    
    # Power states grid
    gum join --horizontal --align center \
        "$(gum style --width 20 --border rounded --padding "0 1" --foreground "$C_PINK" "ACTIVE" "$active")" \
        "$(gum style --width 20 --border rounded --padding "0 1" --foreground "$C_CYAN" "AC POLICY" "$ac")" \
        "$(gum style --width 20 --border rounded --padding "0 1" --foreground "$C_ORANGE" "BAT POLICY" "$bat")"

    # Status line with fan and battery info
    local battery_display
    if [[ "$charge_limit" == "N/A" ]]; then
        battery_display=$(gum style --foreground "$C_GREY" "N/A")
    elif (( charge_limit == 100 )); then
        battery_display=$(gum style --foreground "$C_GREEN" "${charge_limit}%")
    elif (( charge_limit >= 80 )); then
        battery_display=$(gum style --foreground "$C_CYAN" "${charge_limit}%")
    elif (( charge_limit >= 60 )); then
        battery_display=$(gum style --foreground "$C_YELLOW" "${charge_limit}%")
    else
        battery_display=$(gum style --foreground "$C_ORANGE" "${charge_limit}%")
    fi
    
    gum style --align center --foreground "$C_TEXT" --margin "0 1" \
        "Fan: $fan_state  │  Charge Limit: $battery_display"
    echo
}

# ==============================================================================
#  BATTERY CHARGE LIMIT (NEW FEATURE)
# ==============================================================================

menu_battery_limit() {
    local current_limit choice new_limit
    
    current_limit=$(get_charge_limit)
    
    clear
    gum style --foreground "$C_CYAN" --border rounded "Battery Charge Limit"
    echo
    gum style --foreground "$C_TEXT" "Current Limit: $(gum style --foreground "$C_YELLOW" "$current_limit")"
    echo
    
    choice=$(gum choose --cursor="➜ " --header "Select Option" \
        "Set Custom Limit (20-100%)" \
        "Preset: 60% (Maximum Longevity)" \
        "Preset: 80% (Balanced)" \
        "Preset: 100% (Full Charge)" \
        "One-Shot Charge to 100%" \
        "Back")

    case "${choice:-Back}" in
        Back) return ;;
        "Set Custom"*)
            new_limit=$(gum input \
                --placeholder "Enter limit (20-100)" \
                --width 30 \
                --header "Battery Charge Limit")
            
            [[ -z "$new_limit" ]] && return
            
            # Validate input
            new_limit=$(trim "$new_limit")
            new_limit="${new_limit%\%}"  # Remove trailing % if present
            
            if ! [[ "$new_limit" =~ ^[0-9]+$ ]]; then
                notify_error "Invalid input. Please enter a number."
                sleep 1
                return
            fi
            
            if (( new_limit < 20 || new_limit > 100 )); then
                notify_error "Value must be between 20 and 100."
                sleep 1
                return
            fi
            ;;
        "Preset: 60%"*)  new_limit=60 ;;
        "Preset: 80%"*)  new_limit=80 ;;
        "Preset: 100%"*) new_limit=100 ;;
        "One-Shot"*)
            notify_info "Enabling one-shot charge to 100%..."
            if exec_asus -o &>/dev/null; then
                notify_success "One-shot charge enabled. Battery will charge to 100% once."
            else
                notify_error "Failed to enable one-shot charge."
            fi
            sleep 1
            return
            ;;
    esac
    
    # Apply the new limit
    if [[ -n "${new_limit:-}" ]]; then
        notify_info "Setting charge limit to ${new_limit}%..."
        
        if exec_asus -c "$new_limit" &>/dev/null; then
            notify_success "Charge limit set to ${new_limit}%"
        else
            # Fallback: try direct sysfs write
            local sysfs_path="/sys/class/power_supply/BAT0/charge_control_end_threshold"
            if [[ -w "$sysfs_path" ]]; then
                if echo "$new_limit" > "$sysfs_path" 2>/dev/null; then
                    notify_success "Charge limit set via sysfs to ${new_limit}%"
                else
                    notify_error "Failed to set charge limit."
                fi
            else
                notify_error "Failed to set charge limit. Check asusctl configuration."
            fi
        fi
        sleep 1
    fi
}

# ==============================================================================
#  KEYBOARD (Aura & Brightness)
# ==============================================================================

set_brightness() {
    local choice level_arg int_val
    
    choice=$(gum choose --header "Select Brightness Level" \
        "Off (0)" \
        "Low (1)" \
        "Medium (2)" \
        "High (3)" \
        "Back")

    case "${choice:-Back}" in
        Back)      return ;;
        "Off"*)    int_val=0; level_arg="off" ;;
        "Low"*)    int_val=1; level_arg="low" ;;
        "Medium"*) int_val=2; level_arg="med" ;;
        "High"*)   int_val=3; level_arg="high" ;;
    esac

    notify_info "Setting brightness to: $choice..."
    
    if exec_asus -k "$level_arg" &>/dev/null; then
        notify_success "Brightness set."
    else
        # Fallback to sysfs
        local led_path="/sys/class/leds/asus::kbd_backlight/brightness"
        if [[ -w "$led_path" ]]; then
            if echo "$int_val" > "$led_path" 2>/dev/null; then
                notify_success "Applied via sysfs."
            else
                notify_error "Failed to control keyboard brightness."
            fi
        else
            notify_error "No control interface available."
        fi
    fi
    sleep 0.5
}

menu_keyboard() {
    local choice hex
    
    while true; do
        clear
        gum style --foreground "$C_CYAN" --border rounded "Keyboard Control"
        echo
        
        choice=$(gum choose --cursor="➜ " --header "Select Action" \
            "Set Brightness (0-3)" \
            "Aura: Static Color" \
            "Aura: Breathe" \
            "Aura: Rainbow Cycle" \
            "Aura: Pulse" \
            "Back")

        case "${choice:-Back}" in
            Back) break ;;
            "Set Brightness"*) 
                set_brightness 
                ;;
            "Aura: Static"*)
                if hex=$(pick_color); then
                    exec_asus aura static -c "$hex" &>/dev/null
                    notify_success "Static color applied ($hex)"
                    sleep 0.5
                fi
                ;;
            "Aura: Breathe"*)
                if hex=$(pick_color); then
                    exec_asus aura breathe -c "$hex" -s med &>/dev/null
                    notify_success "Breath effect active ($hex)"
                    sleep 0.5
                fi
                ;;
            "Aura: Rainbow"*)
                exec_asus aura rainbow-cycle -s med &>/dev/null
                notify_success "Rainbow cycle active"
                sleep 0.5
                ;;
            "Aura: Pulse"*)
                if hex=$(pick_color); then
                    exec_asus aura pulse -c "$hex" -s med &>/dev/null
                    notify_success "Pulse active ($hex)"
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
    local target selected_prof
    
    # Get available profiles dynamically
    mapfile -t profiles < <(exec_asus profile -l 2>/dev/null | grep -xE '[a-zA-Z]+')
    
    # Fallback to common defaults
    (( ${#profiles[@]} == 0 )) && profiles=("Quiet" "Balanced" "Performance")

    target=$(gum choose --header "Apply Profile To..." \
        "Active Session Only" \
        "AC Power Default" \
        "Battery Default" \
        "GLOBAL (All Sources)" \
        "Back")

    [[ "${target:-Back}" == "Back" ]] && return

    selected_prof=$(gum choose --header "Select Profile" "${profiles[@]}" "Back")
    [[ -z "$selected_prof" || "$selected_prof" == "Back" ]] && return

    notify_info "Applying $selected_prof..."

    case "$target" in
        "Active"*)
            exec_asus profile -P "$selected_prof" &>/dev/null
            ;;
        "AC"*)
            exec_asus profile -a "$selected_prof" &>/dev/null
            ;;
        "Battery"*)
            exec_asus profile -b "$selected_prof" &>/dev/null
            ;;
        "GLOBAL"*)
            exec_asus profile -P "$selected_prof" &>/dev/null
            exec_asus profile -a "$selected_prof" &>/dev/null
            exec_asus profile -b "$selected_prof" &>/dev/null
            ;;
    esac
    
    notify_success "Profile updated to: $selected_prof"
    sleep 1
}

# ==============================================================================
#  FAN CURVES
# ==============================================================================

run_fan_wizard() {
    local min_temp max_temp min_fan max_fan raw_points
    
    gum style --foreground "$C_CYAN" "Fan Curve Wizard (Linear Interpolation)" >&2
    echo >&2
    
    # Get temperature range
    min_temp=$(gum input --placeholder "Start Temp °C (e.g. 30)" --width 30 --header "Temperature Range")
    [[ -z "$min_temp" ]] && return 1
    
    max_temp=$(gum input --placeholder "End Temp °C (e.g. 95)" --value "95" --width 30)
    [[ -z "$max_temp" ]] && return 1

    # Get fan speed range
    min_fan=$(gum input --placeholder "Start Fan % (e.g. 0)" --width 30 --header "Fan Speed Range")
    [[ -z "$min_fan" ]] && return 1

    max_fan=$(gum input --placeholder "End Fan % (e.g. 100)" --value "100" --width 30)
    [[ -z "$max_fan" ]] && return 1

    # Validate all inputs are positive integers
    local var
    for var in "$min_temp" "$max_temp" "$min_fan" "$max_fan"; do
        if ! [[ "$var" =~ ^[0-9]+$ ]]; then
            notify_error "Invalid input: Positive integers only." >&2
            sleep 2
            return 1
        fi
    done

    # Logic validation
    if (( min_temp >= max_temp )); then
        notify_error "Start temp must be lower than end temp." >&2
        sleep 2
        return 1
    fi
    
    if (( min_fan > max_fan )); then
        notify_error "Start fan speed cannot exceed end fan speed." >&2
        sleep 2
        return 1
    fi
    
    # Clamp fan values to valid range
    (( min_fan > 100 )) && min_fan=100
    (( max_fan > 100 )) && max_fan=100

    # Generate 8-point curve using linear interpolation
    raw_points=$(awk -v t1="$min_temp" -v t2="$max_temp" \
                     -v f1="$min_fan"  -v f2="$max_fan" '
    BEGIN {
        for (i = 0; i < 8; i++) {
            r = i / 7.0
            t = t1 + (t2 - t1) * r
            f = f1 + (f2 - f1) * r
            printf "%.0fc:%.0f%%", t, f
            if (i < 7) printf ","
        }
    }')
    
    echo >&2
    gum style --foreground "$C_ORANGE" "Generated curve:" >&2
    gum style --foreground "$C_TEXT" --border rounded --padding "0 1" "$raw_points" >&2
    echo >&2
    
    if gum confirm "Apply this curve?"; then
        printf '%s' "$raw_points"
    else
        return 1
    fi
}

menu_fans() {
    local p_states active ac bat choice curve prof_arg
    
    # Get active profile for context
    p_states=$(get_power_states)
    IFS='|' read -r active ac bat <<< "$p_states"
    
    choice=$(gum choose --cursor="➜ " --header "Fan Controls (Profile: $active)" \
        "Wizard: Create Custom Curve" \
        "Preset: Silent" \
        "Preset: Balanced" \
        "Preset: Turbo" \
        "Reset to BIOS Defaults" \
        "Back")

    case "${choice:-Back}" in
        Back) return ;;
        "Wizard"*) 
            curve=$(run_fan_wizard) || return
            ;;
        "Preset: Silent"*)
            curve="50c:0%,60c:20%,70c:40%,80c:55%,85c:70%,90c:85%,95c:100%,100c:100%"
            ;;
        "Preset: Balanced"*)
            curve="40c:10%,50c:25%,60c:40%,70c:55%,80c:70%,90c:85%,95c:95%,100c:100%"
            ;;
        "Preset: Turbo"*)
            curve="30c:50%,40c:60%,50c:70%,60c:80%,70c:90%,80c:100%,90c:100%,100c:100%"
            ;;
        "Reset"*)
            if gum confirm "Reset fan curves to BIOS defaults?"; then
                prof_arg="${active,,}"
                prof_arg=$(trim "$prof_arg")
                
                notify_info "Resetting fan curves..."
                exec_asus fan-curve -m "$prof_arg" -e false &>/dev/null
                notify_success "Reset complete."
                sleep 1
            fi
            return
            ;;
    esac

    # Apply the curve if set
    if [[ -n "${curve:-}" ]]; then
        prof_arg="${active,,}"
        prof_arg=$(trim "$prof_arg")
        
        notify_info "Applying curve to profile: $active..."
        
        # Apply to both CPU and GPU fans
        exec_asus fan-curve -m "$prof_arg" -f cpu -D "$curve" &>/dev/null
        exec_asus fan-curve -m "$prof_arg" -f gpu -D "$curve" &>/dev/null
        exec_asus fan-curve -m "$prof_arg" -e true &>/dev/null
        
        notify_success "Fan curve applied."
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
        
        action=$(gum choose --cursor="➜ " --header "Main Menu" \
            "Manage Fan Curves" \
            "Power Profiles" \
            "Battery Charge Limit" \
            "Keyboard Control" \
            "Quit")
        
        case "${action:-Quit}" in
            "Manage Fan Curves")      menu_fans ;;
            "Power Profiles")         menu_profiles ;;
            "Battery Charge Limit")   menu_battery_limit ;;
            "Keyboard Control")       menu_keyboard ;;
            "Quit")                   break ;;
        esac
    done
}

main "$@"
