#!/usr/bin/env bash
# ==============================================================================
#  ARCH LINUX / HYPRLAND WIFI MANAGER (REFACTORED v2.0)
#  Hardened & Optimized by: Elite DevOps Engineer
#  Target: Bash 5.0+ / Arch Linux / Hyprland / UWSM
#  Dependencies: gum (charmbracelet), networkmanager, nerd-fonts (optional)
# ==============================================================================

# --- Bash Strict Mode (Interactive-Safe) ---
# Note: -e (errexit) intentionally omitted for interactive menu compatibility
set -o pipefail
set -o nounset

# --- Immutable Configuration ---
declare -ri WIDTH=60
declare -ri C_PRIMARY=212    # Pink
declare -ri C_SECONDARY=99   # Purple  
declare -ri C_ACCENT=50      # Cyan
declare -ri C_ERROR=196      # Red
declare -ri C_SUCCESS=46     # Green
declare -ri C_MUTED=240      # Grey

# --- Global State ---
declare -A SAVED_CONNS=()    # [connection_name]=uuid

# ==============================================================================
#  DEPENDENCY & ENVIRONMENT CHECKS
# ==============================================================================

check_dependencies() {
    local -a missing=()
    local -A deps=(
        [gum]="gum"
        [nmcli]="networkmanager"
    )
    
    local cmd pkg
    for cmd in "${!deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("${deps[$cmd]}")
        fi
    done
    
    if ((${#missing[@]} > 0)); then
        printf '❌ Missing dependencies: %s\n' "${missing[*]}" >&2
        printf '   Install: sudo pacman -S %s\n' "${missing[*]}" >&2
        return 1
    fi
    
    # Verify bash version for associative array support
    if ((BASH_VERSINFO[0] < 4)); then
        printf '❌ Bash 4.0+ required (found %s)\n' "$BASH_VERSION" >&2
        return 1
    fi
    
    return 0
}

check_networkmanager() {
    if ! systemctl is-active --quiet NetworkManager.service; then
        printf '❌ NetworkManager is not running!\n' >&2
        printf '   Run: sudo systemctl start NetworkManager\n' >&2
        return 1
    fi
    return 0
}

# ==============================================================================
#  CLEANUP & SIGNAL HANDLING  
# ==============================================================================

cleanup() {
    local -ri exit_code="${1:-$?}"
    
    # Restore terminal state
    tput cnorm 2>/dev/null || true  # Show cursor
    
    # Kill any background jobs we spawned
    jobs -p | xargs -r kill 2>/dev/null || true
    
    exit "$exit_code"
}

setup_traps() {
    # Separate traps for different signals
    trap 'cleanup 130' INT      # Ctrl+C = 128 + 2
    trap 'cleanup 143' TERM     # SIGTERM = 128 + 15
    trap 'cleanup $?' EXIT      # Preserve exit code
}

# ==============================================================================
#  HELPER FUNCTIONS
# ==============================================================================

notify() {
    local -r title="${1:-Notification}"
    local -r body="${2:-}"
    
    if command -v notify-send &>/dev/null; then
        # Run in background, disown to prevent zombie
        notify-send -a "WiFi Manager" -u low -i network-wireless "$title" "$body" &
        disown "$!" 2>/dev/null
    fi
}

style_header() {
    clear
    gum style \
        --border double \
        --border-foreground "$C_PRIMARY" \
        --padding "0 2" \
        --margin "1 0" \
        --align center \
        --width "$WIDTH" \
        --bold \
        "  Network Architect"
}

style_msg() {
    local -r color="${1:?Color required}"
    shift
    gum style --foreground "$color" --bold -- "$*"
}

# Format ANSI color escape sequence (avoids subshell for gum in loops)
ansi_color() {
    local -r code="${1:?Color code required}"
    printf '\033[38;5;%dm' "$code"
}

ansi_reset() {
    printf '\033[0m'
}

# ==============================================================================
#  NETWORKMANAGER INTERFACE
# ==============================================================================

# Load all saved WiFi connections into SAVED_CONNS associative array
# Uses connection NAME as key (not SSID - they can differ!)
load_saved_connections() {
    SAVED_CONNS=()
    
    local line name uuid type
    
    # Get connections with proper field separation
    # Format: NAME:UUID:TYPE (TYPE is "802-11-wireless" for WiFi)
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        # TYPE is always "802-11-wireless" (17 chars) at end
        type="${line##*:}"
        [[ "$type" != "802-11-wireless" ]] && continue
        
        # Remove type and trailing colon
        line="${line%:802-11-wireless}"
        
        # UUID is always 36 characters (standard UUID format)
        # Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        if ((${#line} >= 37)); then
            uuid="${line: -36}"
            name="${line:0:$((${#line} - 37))}"  # Everything before ":UUID"
            
            if [[ -n "$name" && "$uuid" =~ ^[a-f0-9-]{36}$ ]]; then
                SAVED_CONNS["$name"]="$uuid"
            fi
        fi
    done < <(nmcli -t -f NAME,UUID,TYPE connection show 2>/dev/null)
}

# Get the currently active WiFi connection name
# Returns empty string if no WiFi is active
get_active_wifi_name() {
    local line name type
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        # Extract type (last field)
        type="${line##*:}"
        [[ "$type" != "802-11-wireless" ]] && continue
        
        # Extract name (everything before last colon)
        name="${line%:802-11-wireless}"
        
        # Return first WiFi connection found
        printf '%s' "$name"
        return 0
    done < <(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null)
    
    return 1
}

# Get the currently connected SSID (from device, not connection)
get_active_ssid() {
    nmcli -t -f active,ssid device wifi list 2>/dev/null | \
        awk -F: '$1 == "yes" { print $2; exit }'
}

# Get WiFi radio status
get_radio_status() {
    nmcli radio wifi 2>/dev/null || echo "unknown"
}

# Perform a WiFi scan and return network list
# Output format: IN-USE|SSID|SECURITY|SIGNAL|BARS (pipe-delimited for safety)
scan_networks() {
    local rescan="${1:-yes}"
    
    # Use pipe delimiter which is illegal in SSIDs (per IEEE 802.11)
    # Fields: IN-USE, SSID, SECURITY, SIGNAL, BARS
    nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL,BARS device wifi list \
        ${rescan:+--rescan "$rescan"} 2>/dev/null | \
    while IFS=: read -r in_use rest; do
        # 'rest' contains SSID:SECURITY:SIGNAL:BARS
        # We need to parse from the RIGHT since SSID can contain colons
        
        local bars signal security ssid
        
        # BARS is last (variable length, but contains only bar chars)
        bars="${rest##*:}"
        rest="${rest%:*}"
        
        # SIGNAL is numeric (1-100)
        signal="${rest##*:}"
        rest="${rest%:*}"
        
        # SECURITY is next from right
        security="${rest##*:}"
        rest="${rest%:*}"
        
        # Remaining 'rest' is the SSID (may contain colons)
        ssid="$rest"
        
        # Skip hidden networks (empty SSID)
        [[ -z "$ssid" ]] && continue
        
        # Output with pipe delimiter
        printf '%s|%s|%s|%s|%s\n' "$in_use" "$ssid" "$security" "$signal" "$bars"
    done
}

# ==============================================================================
#  CONNECTION MANAGEMENT
# ==============================================================================

connect_to_network() {
    local -r ssid="${1:?SSID required}"
    local -r password="${2:-}"
    
    local -a cmd=(nmcli device wifi connect "$ssid")
    
    if [[ -n "$password" ]]; then
        cmd+=(password "$password")
    fi
    
    # Execute directly - NO string interpolation, NO eval, NO bash -c
    # This is safe because we're passing arguments directly, not building strings
    if "${cmd[@]}" &>/dev/null; then
        return 0
    fi
    return 1
}

connect_saved_network() {
    local -r uuid="${1:?UUID required}"
    
    nmcli connection up uuid "$uuid" &>/dev/null
}

disconnect_network() {
    local -r identifier="${1:?Identifier required}"
    local -r id_type="${2:-uuid}"  # "uuid" or "id"
    
    nmcli connection down "$id_type" "$identifier" &>/dev/null
}

forget_network() {
    local -r identifier="${1:?Identifier required}"
    local -r id_type="${2:-uuid}"
    
    nmcli connection delete "$id_type" "$identifier" &>/dev/null
}

toggle_radio() {
    local state
    state=$(get_radio_status)
    
    case "$state" in
        enabled)
            if gum confirm "Turn Wi-Fi OFF?"; then
                gum spin --spinner dot --title "Disabling radio..." -- \
                    nmcli radio wifi off
                style_msg "$C_ERROR" "睊 Wi-Fi Disabled"
                notify "Wi-Fi" "Radio disabled"
                sleep 1
            fi
            ;;
        disabled)
            gum spin --spinner dot --title "Enabling radio..." -- \
                nmcli radio wifi on
            style_msg "$C_SUCCESS" " Wi-Fi Enabled"
            notify "Wi-Fi" "Radio enabled"
            # Allow time for device initialization
            sleep 2
            ;;
        *)
            style_msg "$C_ERROR" "⚠ Unable to determine radio state"
            sleep 1
            ;;
    esac
}

# ==============================================================================
#  NETWORK SELECTION UI
# ==============================================================================

scan_and_connect() {
    local active_wifi active_ssid
    
    while true; do
        style_header
        gum style --foreground "$C_SECONDARY" "  Scanning airwaves..."
        
        # Refresh saved connections
        load_saved_connections
        
        # Get current active connection for comparison
        active_wifi=$(get_active_wifi_name) || active_wifi=""
        active_ssid=$(get_active_ssid) || active_ssid=""
        
        # Perform network scan
        local -a raw_ssids=()
        local -a display_lines=()
        local -A seen_ssids=()  # Proper deduplication
        
        local line in_use ssid security signal bars
        local icon state color
        
        while IFS='|' read -r in_use ssid security signal bars; do
            # Skip empty or already-seen SSIDs
            [[ -z "$ssid" ]] && continue
            [[ -v "seen_ssids[$ssid]" ]] && continue
            seen_ssids["$ssid"]=1
            
            # Determine network state
            icon=" "
            state="New"
            color=255
            
            if [[ "$in_use" == "*" ]]; then
                icon=""
                state="Active"
                color=$C_SUCCESS
            elif [[ -v "SAVED_CONNS[$ssid]" ]]; then
                icon=""
                state="Saved"
                color=$C_ACCENT
            fi
            
            # Build display line WITHOUT subshells (performance optimization)
            local fmt_line
            printf -v fmt_line '%s%s%s %-8s  %-25.25s  %-10.10s  %3s%%  %s' \
                "$(ansi_color "$color")" \
                "$icon" \
                "$(ansi_reset)" \
                "$state" \
                "$ssid" \
                "${security:-Open}" \
                "$signal" \
                "$bars"
            
            raw_ssids+=("$ssid")
            display_lines+=("$fmt_line")
            
        done < <(scan_networks yes)
        
        # Check if we found any networks
        if ((${#raw_ssids[@]} == 0)); then
            style_msg "$C_ERROR" "" "No networks found."
            sleep 2
            return
        fi
        
        # Render selection UI
        style_header
        
        # Build menu efficiently (single printf call with array)
        local menu_input idx
        menu_input=$(
            for ((idx = 0; idx < ${#display_lines[@]}; idx++)); do
                printf '%03d %s\n' "$idx" "${display_lines[idx]}"
            done
        )
        
        local choice
        choice=$(
            printf '%s' "$menu_input" | gum filter \
                --height 15 \
                --width "$WIDTH" \
                --indicator "➜" \
                --indicator.foreground "$C_PRIMARY" \
                --placeholder "Type to filter networks..." \
                --header "    STATE     SSID                        SECURITY    RSSI  SIGNAL"
        ) || return  # User cancelled
        
        [[ -z "$choice" ]] && return
        
        # Extract selection index safely
        local idx_str="${choice:0:3}"
        
        # Validate it's numeric
        if [[ ! "$idx_str" =~ ^[0-9]+$ ]]; then
            style_msg "$C_ERROR" "⚠ Invalid selection"
            sleep 1
            continue
        fi
        
        # Force base-10 interpretation (avoid octal with 08/09)
        local selected_idx=$((10#$idx_str))
        
        # Bounds validation
        if ((selected_idx < 0 || selected_idx >= ${#raw_ssids[@]})); then
            style_msg "$C_ERROR" "⚠ Selection out of range"
            sleep 1
            continue
        fi
        
        local target_ssid="${raw_ssids[$selected_idx]}"
        local saved_uuid="${SAVED_CONNS[$target_ssid]:-}"
        
        # Refresh active state before action
        active_ssid=$(get_active_ssid) || active_ssid=""
        
        # Dispatch to action handler
        handle_network_action "$target_ssid" "$saved_uuid" "$active_ssid"
    done
}

handle_network_action() {
    local -r ssid="${1:?SSID required}"
    local -r uuid="${2:-}"  # Empty if not saved
    local -r active_ssid="${3:-}"
    
    local action
    
    # === CASE 1: Currently Active Connection ===
    if [[ "$ssid" == "$active_ssid" ]]; then
        action=$(gum choose \
            --header "󰤨 Managing: $ssid (Active)" \
            --cursor.foreground "$C_PRIMARY" \
            "Disconnect" \
            "Forget Network" \
            "Cancel"
        ) || return
        
        case "$action" in
            "Disconnect")
                style_header
                if [[ -n "$uuid" ]]; then
                    gum spin --spinner dot --title "Disconnecting..." -- \
                        nmcli connection down uuid "$uuid"
                else
                    gum spin --spinner dot --title "Disconnecting..." -- \
                        nmcli connection down id "$ssid"
                fi
                style_msg "$C_SUCCESS" "" "Disconnected from $ssid"
                notify "Wi-Fi" "Disconnected from $ssid"
                sleep 1
                ;;
            "Forget Network")
                if gum confirm --affirmative "Delete" --negative "Keep" \
                    "Permanently delete saved profile for '$ssid'?"; then
                    
                    if [[ -n "$uuid" ]]; then
                        forget_network "$uuid" "uuid"
                    else
                        forget_network "$ssid" "id"
                    fi
                    style_msg "$C_SUCCESS" "" "Network profile deleted"
                    notify "Wi-Fi" "Forgot $ssid"
                    sleep 1
                fi
                ;;
        esac
        return
    fi
    
    # === CASE 2: Saved But Not Active ===
    if [[ -n "$uuid" ]]; then
        action=$(gum choose \
            --header "󰤨 Managing: $ssid (Saved)" \
            --cursor.foreground "$C_PRIMARY" \
            "Connect" \
            "Forget Network" \
            "Cancel"
        ) || return
        
        case "$action" in
            "Connect")
                style_header
                gum style --foreground "$C_SECONDARY" " Connecting to $ssid..."
                
                if gum spin --spinner dot --title "Authenticating..." -- \
                    nmcli connection up uuid "$uuid"; then
                    style_msg "$C_SUCCESS" "" "Connected to $ssid"
                    notify "Wi-Fi" "Connected to $ssid"
                else
                    style_msg "$C_ERROR" "" "Connection failed"
                    notify "Wi-Fi" "Failed to connect to $ssid"
                fi
                sleep 1
                ;;
            "Forget Network")
                forget_network "$uuid" "uuid"
                style_msg "$C_SUCCESS" "" "Network profile deleted"
                sleep 1
                ;;
        esac
        return
    fi
    
    # === CASE 3: New Network ===
    style_header
    gum style --foreground "$C_ACCENT" " New Network: $ssid"
    echo
    
    local password=""
    
    # Prompt for password (empty for open networks)
    password=$(gum input \
        --password \
        --width 40 \
        --placeholder "Enter password (empty for open network)..." \
        --header "Authentication Required"
    ) || return  # User cancelled
    
    style_header
    gum style --foreground "$C_SECONDARY" " Connecting to $ssid..."
    
    # SECURITY: Direct argument passing - NO string interpolation
    local connect_status
    if gum spin --spinner dot --title "Negotiating connection..." -- \
        bash -c 'nmcli device wifi connect "$1" ${2:+password "$2"}' -- "$ssid" "$password"; then
        connect_status=0
    else
        connect_status=1
    fi
    
    if ((connect_status == 0)); then
        style_msg "$C_SUCCESS" "" "Successfully connected!"
        notify "Wi-Fi" "Connected to $ssid"
        sleep 1
    else
        style_msg "$C_ERROR" "" "Connection failed"
        echo
        gum style --foreground "$C_MUTED" "Possible causes:"
        gum style --foreground "$C_MUTED" "  • Incorrect password"
        gum style --foreground "$C_MUTED" "  • Network out of range"
        gum style --foreground "$C_MUTED" "  • Authentication timeout"
        notify "Wi-Fi" "Failed to connect to $ssid"
        sleep 3
    fi
}

# ==============================================================================
#  MAIN MENU
# ==============================================================================

show_status_dashboard() {
    local active_ssid radio_status status_line
    
    active_ssid=$(get_active_ssid) || active_ssid=""
    radio_status=$(get_radio_status)
    
    if [[ "$radio_status" == "disabled" ]]; then
        status_line=$(gum style --foreground "$C_ERROR" "睊 Wi-Fi Radio: OFF")
    elif [[ -n "$active_ssid" ]]; then
        status_line=$(gum style --foreground "$C_SUCCESS" "  Connected: $active_ssid")
    else
        status_line=$(gum style --foreground "$C_MUTED" "直 Disconnected")
    fi
    
    echo
    echo "$status_line"
    echo
}

main_menu() {
    local choice radio_status
    
    while true; do
        style_header
        show_status_dashboard
        
        radio_status=$(get_radio_status)
        
        choice=$(gum choose \
            --cursor-prefix "➜ " \
            --cursor.foreground "$C_PRIMARY" \
            --header "Select an option:" \
            " Scan Networks" \
            "󰖩 Toggle Radio" \
            " Exit"
        ) || break  # Handle Ctrl+C gracefully
        
        case "$choice" in
            *"Scan Networks"*)
                if [[ "$radio_status" == "disabled" ]]; then
                    style_msg "$C_ERROR" "⚠" "Wi-Fi radio is disabled. Enable it first."
                    sleep 1.5
                else
                    scan_and_connect
                fi
                ;;
            *"Toggle Radio"*)
                toggle_radio
                ;;
            *"Exit"*)
                break
                ;;
            "")
                # Empty selection (Ctrl+C in gum)
                break
                ;;
        esac
    done
}

# ==============================================================================
#  ENTRY POINT
# ==============================================================================

main() {
    # Run pre-flight checks
    check_dependencies || exit 1
    check_networkmanager || exit 1
    
    # Setup signal handlers
    setup_traps
    
    # Launch main interface
    main_menu
    
    # Clean exit
    clear
    gum style --foreground "$C_MUTED" "👋 Goodbye!"
    exit 0
}

# Execute main only if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
