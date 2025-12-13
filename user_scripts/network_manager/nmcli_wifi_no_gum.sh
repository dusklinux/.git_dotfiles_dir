#!/usr/bin/env bash
# ==============================================================================
#  ARCH LINUX / HYPRLAND WIFI MANAGER (NO-GUM VERSION)
#  Refactored by: Elite DevOps Engineer
#  Target: Bash 5.0+ / Arch Linux / Hyprland / UWSM
#  Dependencies: networkmanager, coreutils, sed, awk
# ==============================================================================

# --- Bash Strict Mode ---
set -o pipefail
set -o nounset
# set -e is omitted for interactive menu handling

# --- Configuration & Colors ---
declare -r C_RESET=$'\033[0m'
declare -r C_BOLD=$'\033[1m'
declare -r C_PINK=$'\033[38;5;212m'
declare -r C_PURPLE=$'\033[38;5;99m'
declare -r C_CYAN=$'\033[38;5;50m'
declare -r C_RED=$'\033[38;5;196m'
declare -r C_GREEN=$'\033[38;5;46m'
declare -r C_GREY=$'\033[38;5;240m'

# --- Global State ---
declare -A SAVED_CONNS=()

# ==============================================================================
#  DEPENDENCY & ENVIRONMENT CHECKS
# ==============================================================================

check_dependencies() {
    # Removed 'gum' from check
    if ! command -v nmcli &>/dev/null; then
        printf "${C_RED}❌ Missing dependency: networkmanager (nmcli)${C_RESET}\n" >&2
        return 1
    fi
    
    if ((BASH_VERSINFO[0] < 5)); then
        printf "${C_RED}❌ Bash 5.0+ required (found %s)${C_RESET}\n" "$BASH_VERSION" >&2
        return 1
    fi
    return 0
}

check_networkmanager() {
    if ! systemctl is-active --quiet NetworkManager.service; then
        printf "${C_RED}❌ NetworkManager is not running!${C_RESET}\n" >&2
        printf "   Run: sudo systemctl start NetworkManager\n" >&2
        return 1
    fi
    return 0
}

# ==============================================================================
#  CLEANUP & SIGNAL HANDLING  
# ==============================================================================

cleanup() {
    local -ri exit_code="${1:-$?}"
    # Ensure cursor is visible (in case read -s was interrupted)
    printf '\033[?25h' 
    exit "$exit_code"
}

setup_traps() {
    trap 'cleanup 130' INT
    trap 'cleanup 143' TERM
    trap 'cleanup $?' EXIT
}

# ==============================================================================
#  HELPER FUNCTIONS (UI REPLACEMENTS)
# ==============================================================================

notify() {
    local -r title="${1:-Notification}"
    local -r body="${2:-}"
    
    if command -v notify-send &>/dev/null; then
        notify-send -a "WiFi Manager" -u low -i network-wireless "$title" "$body" &
        disown "$!" 2>/dev/null
    fi
}

print_header() {
    clear
    printf "${C_PINK}${C_BOLD}"
    printf "==========================================================\n"
    printf "                  NETWORK ARCHITECT                       \n"
    printf "==========================================================\n"
    printf "${C_RESET}\n"
}

print_status() {
    local -r color="$1"
    local -r msg="$2"
    printf "${color}%s${C_RESET}\n" "$msg"
}

# Native spinner replacement
run_with_feedback() {
    local -r msg="$1"
    shift
    local -r cmd=("$@")

    printf "${C_PURPLE}➜ %s...${C_RESET} " "$msg"
    
    # Run command and capture output/status
    if "${cmd[@]}" &>/dev/null; then
        printf "${C_GREEN}[OK]${C_RESET}\n"
        return 0
    else
        printf "${C_RED}[FAILED]${C_RESET}\n"
        return 1
    fi
}

# ==============================================================================
#  NETWORKMANAGER LOGIC (IDENTICAL TO ORIGINAL)
# ==============================================================================

load_saved_connections() {
    SAVED_CONNS=()
    local line name uuid type
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        type="${line##*:}"
        [[ "$type" != "802-11-wireless" ]] && continue
        line="${line%:802-11-wireless}"
        
        if ((${#line} >= 37)); then
            uuid="${line: -36}"
            name="${line:0:$((${#line} - 37))}"
            if [[ -n "$name" && "$uuid" =~ ^[a-f0-9-]{36}$ ]]; then
                SAVED_CONNS["$name"]="$uuid"
            fi
        fi
    done < <(nmcli -t -f NAME,UUID,TYPE connection show 2>/dev/null)
}

get_active_wifi_name() {
    local line name type
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        type="${line##*:}"
        [[ "$type" != "802-11-wireless" ]] && continue
        name="${line%:802-11-wireless}"
        printf '%s' "$name"
        return 0
    done < <(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null)
    return 1
}

get_active_ssid() {
    nmcli -t -f active,ssid device wifi list 2>/dev/null | \
        awk -F: '$1 == "yes" { print $2; exit }'
}

get_radio_status() {
    nmcli radio wifi 2>/dev/null || echo "unknown"
}

scan_networks() {
    local rescan="${1:-yes}"
    nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL,BARS device wifi list \
        ${rescan:+--rescan "$rescan"} 2>/dev/null | \
    while IFS=: read -r in_use rest; do
        local bars signal security ssid
        bars="${rest##*:}"
        rest="${rest%:*}"
        signal="${rest##*:}"
        rest="${rest%:*}"
        security="${rest##*:}"
        rest="${rest%:*}"
        ssid="$rest"
        [[ -z "$ssid" ]] && continue
        printf '%s|%s|%s|%s|%s\n' "$in_use" "$ssid" "$security" "$signal" "$bars"
    done
}

forget_network() {
    local -r identifier="${1:?Identifier required}"
    local -r id_type="${2:-uuid}"
    nmcli connection delete "$id_type" "$identifier" &>/dev/null
}

toggle_radio() {
    local state
    state=$(get_radio_status)
    
    echo
    case "$state" in
        enabled)
            read -p "Turn Wi-Fi OFF? [y/N] " -n 1 -r REPLY
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if run_with_feedback "Disabling radio" nmcli radio wifi off; then
                    print_status "$C_RED" "睊 Wi-Fi Disabled"
                    notify "Wi-Fi" "Radio disabled"
                fi
                sleep 1
            fi
            ;;
        disabled)
            if run_with_feedback "Enabling radio" nmcli radio wifi on; then
                print_status "$C_GREEN" " Wi-Fi Enabled"
                notify "Wi-Fi" "Radio enabled"
                sleep 2
            fi
            ;;
        *)
            print_status "$C_RED" "⚠ Unable to determine radio state"
            sleep 1
            ;;
    esac
}

# ==============================================================================
#  INTERACTIVE UI LOGIC
# ==============================================================================

scan_and_connect() {
    local active_wifi active_ssid
    
    while true; do
        print_header
        printf "${C_PURPLE}  Scanning airwaves...${C_RESET}\n"
        
        load_saved_connections
        active_wifi=$(get_active_wifi_name) || active_wifi=""
        active_ssid=$(get_active_ssid) || active_ssid=""
        
        local -a raw_ssids=()
        local -a display_lines=()
        local -A seen_ssids=()
        
        local line in_use ssid security signal bars
        local icon state color
        
        while IFS='|' read -r in_use ssid security signal bars; do
            [[ -z "$ssid" ]] && continue
            [[ -v "seen_ssids[$ssid]" ]] && continue
            seen_ssids["$ssid"]=1
            
            icon=" "
            state="New"
            color="$C_RESET"
            
            if [[ "$in_use" == "*" ]]; then
                icon="*"
                state="Active"
                color="$C_GREEN"
            elif [[ -v "SAVED_CONNS[$ssid]" ]]; then
                icon="S"
                state="Saved"
                color="$C_CYAN"
            fi
            
            # Format strictly for alignment
            local fmt_line
            printf -v fmt_line '%s%s %-1s %-6s %-20.20s %-8.8s %3s%% %s%s' \
                "$color" "$icon" "" "$state" "$ssid" "${security:-Open}" "$signal" "$bars" "$C_RESET"
            
            raw_ssids+=("$ssid")
            display_lines+=("$fmt_line")
            
        done < <(scan_networks yes)
        
        if ((${#raw_ssids[@]} == 0)); then
            print_status "$C_RED" "No networks found."
            sleep 2
            return
        fi
        
        print_header
        printf "    %-3s %-6s %-20s %-8s %-4s %s\n" "ID" "STATE" "SSID" "SEC" "SIG" "BARS"
        printf "    ----------------------------------------------------------\n"
        
        local idx
        for ((idx = 0; idx < ${#display_lines[@]}; idx++)); do
            printf "   [%02d] %s\n" "$idx" "${display_lines[idx]}"
        done
        echo
        
        local selection
        read -p "Select network ID (or enter to cancel): " -r selection
        
        [[ -z "$selection" ]] && return
        
        if [[ ! "$selection" =~ ^[0-9]+$ ]] || ((selection < 0 || selection >= ${#raw_ssids[@]})); then
            print_status "$C_RED" "⚠ Invalid selection"
            sleep 1
            continue
        fi
        
        # Base-10 conversion handled by bash arithmetic context
        local target_ssid="${raw_ssids[$selection]}"
        local saved_uuid="${SAVED_CONNS[$target_ssid]:-}"
        
        active_ssid=$(get_active_ssid) || active_ssid=""
        handle_network_action "$target_ssid" "$saved_uuid" "$active_ssid"
    done
}

handle_network_action() {
    local -r ssid="${1:?SSID required}"
    local -r uuid="${2:-}"
    local -r active_ssid="${3:-}"
    
    echo
    print_status "$C_PINK" "Managing: $ssid"
    echo
    
    # === CASE 1: Active Connection ===
    if [[ "$ssid" == "$active_ssid" ]]; then
        echo "1) Disconnect"
        echo "2) Forget Network"
        echo "3) Cancel"
        read -p "Choose option: " -n 1 -r opt
        echo
        
        case "$opt" in
            1)
                if [[ -n "$uuid" ]]; then
                    run_with_feedback "Disconnecting" nmcli connection down uuid "$uuid"
                else
                    run_with_feedback "Disconnecting" nmcli connection down id "$ssid"
                fi
                notify "Wi-Fi" "Disconnected from $ssid"
                sleep 1
                ;;
            2)
                read -p "Permanently delete profile? [y/N] " -n 1 -r confirm
                echo
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    if [[ -n "$uuid" ]]; then
                        forget_network "$uuid" "uuid"
                    else
                        forget_network "$ssid" "id"
                    fi
                    print_status "$C_GREEN" "Network profile deleted"
                    notify "Wi-Fi" "Forgot $ssid"
                    sleep 1
                fi
                ;;
        esac
        return
    fi
    
    # === CASE 2: Saved Connection ===
    if [[ -n "$uuid" ]]; then
        echo "1) Connect"
        echo "2) Forget Network"
        echo "3) Cancel"
        read -p "Choose option: " -n 1 -r opt
        echo 
        
        case "$opt" in
            1)
                if run_with_feedback "Connecting" nmcli connection up uuid "$uuid"; then
                    print_status "$C_GREEN" "Connected to $ssid"
                    notify "Wi-Fi" "Connected to $ssid"
                else
                    print_status "$C_RED" "Connection failed"
                    notify "Wi-Fi" "Failed to connect to $ssid"
                fi
                sleep 1
                ;;
            2)
                forget_network "$uuid" "uuid"
                print_status "$C_GREEN" "Network profile deleted"
                sleep 1
                ;;
        esac
        return
    fi
    
    # === CASE 3: New Network ===
    print_status "$C_CYAN" "New Connection Setup"
    local password=""
    
    printf "Enter Password (leave empty for open network): "
    # REMOVED -s flag so password text is visible
    read -r password
    echo
    
    printf "${C_PURPLE}➜ Connecting to %s...${C_RESET}\n" "$ssid"
    
    # Safe execution without eval
    local connect_status
    if bash -c 'nmcli device wifi connect "$1" ${2:+password "$2"}' -- "$ssid" "$password" &>/dev/null; then
        connect_status=0
    else
        connect_status=1
    fi
    
    if ((connect_status == 0)); then
        print_status "$C_GREEN" "Successfully connected!"
        notify "Wi-Fi" "Connected to $ssid"
        sleep 1
    else
        print_status "$C_RED" "Connection failed"
        printf "${C_GREY}Possible causes: Bad password, out of range, or timeout.${C_RESET}\n"
        notify "Wi-Fi" "Failed to connect to $ssid"
        sleep 3
    fi
}

show_status_dashboard() {
    local active_ssid radio_status
    active_ssid=$(get_active_ssid) || active_ssid=""
    radio_status=$(get_radio_status)
    
    echo
    if [[ "$radio_status" == "disabled" ]]; then
        printf "   ${C_RED}睊 Wi-Fi Radio: OFF${C_RESET}\n"
    elif [[ -n "$active_ssid" ]]; then
        printf "   ${C_GREEN}Connected: %s${C_RESET}\n" "$active_ssid"
    else
        printf "   ${C_GREY}直 Disconnected${C_RESET}\n"
    fi
    echo
}

main_menu() {
    local choice radio_status
    
    while true; do
        print_header
        show_status_dashboard
        
        radio_status=$(get_radio_status)
        
        echo "1) Scan Networks"
        echo "2) Toggle Radio"
        echo "3) Exit"
        echo
        read -p "Select option: " -n 1 -r choice
        echo
        
        case "$choice" in
            1)
                if [[ "$radio_status" == "disabled" ]]; then
                    print_status "$C_RED" "⚠ Wi-Fi radio is disabled. Enable it first."
                    sleep 1.5
                else
                    scan_and_connect
                fi
                ;;
            2)
                toggle_radio
                ;;
            3|q|Q)
                break
                ;;
            *)
                ;;
        esac
    done
}

# ==============================================================================
#  ENTRY POINT
# ==============================================================================

main() {
    check_dependencies || exit 1
    check_networkmanager || exit 1
    setup_traps
    
    main_menu
    
    clear
    printf "${C_GREY}👋 Goodbye!${C_RESET}\n"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
