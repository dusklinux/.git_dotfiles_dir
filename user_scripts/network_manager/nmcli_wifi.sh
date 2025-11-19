#!/bin/bash

# ==============================================================================
#  ARCH LINUX / HYPRLAND WIFI MANAGER
#  Powered by 'gum' and 'nmcli'
# ==============================================================================

# --- Configuration & Styles ---
WIDTH=65
COLOR_PRIMARY=212    # Pink/Magenta
COLOR_SECONDARY=99   # Purple
COLOR_ACCENT=50      # Cyan
COLOR_ERROR=196      # Red
COLOR_SUCCESS=46     # Green
COLOR_TEXT=255       # White

# Check for gum
if ! command -v gum &> /dev/null; then
    echo "Error: 'gum' is not installed."
    echo "Install it with: sudo pacman -S gum"
    exit 1
fi

# --- Helper Functions ---

# Graceful exit on Ctrl+C
trap "echo; exit" INT

notify() {
    local title="$1"
    local msg="$2"
    if command -v notify-send &> /dev/null; then
        notify-send -a "Wifi Manager" "$title" "$msg"
    fi
}

header() {
    clear
    gum style --border double --border-foreground "$COLOR_PRIMARY" --padding "1 2" --margin "1" \
        --align center --width "$WIDTH" "  Network Manager"
}

show_error() {
    gum style --foreground "$COLOR_ERROR" --bold " $1"
    sleep 2
}

show_success() {
    gum style --foreground "$COLOR_SUCCESS" --bold " $1"
    sleep 1.5
}

get_active_connection() {
    # 2>/dev/null silences the "version mismatch" warnings
    nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep ':802-11-wireless' | cut -d: -f1 | head -n1
}

# --- Core Logic: Scan & Connect ---

scan_and_connect() {
    while true; do
        header
        
        echo -e "$(gum style --foreground "$COLOR_SECONDARY" " Reading saved profiles...")"
        
        # 1. ROBUST DATA MAPPING (FIXED)
        # We cannot fetch SSID in the summary view on all nmcli versions.
        # We must get UUIDs first, then query SSID individually.
        # 2>/dev/null is CRITICAL to hide system warnings.

        declare -A saved_connections
        
        # Get list of saved wifi connection UUIDs
        local saved_uuids
        saved_uuids=$(nmcli -t -f UUID,TYPE connection show 2>/dev/null | grep ':802-11-wireless' | cut -d: -f1)

        # Loop through them to get the real SSID (Safe method)
        for uuid in $saved_uuids; do
            # 'nmcli -g' gets a specific field value cleanly
            local s_ssid
            local s_name
            s_ssid=$(nmcli -g 802-11-wireless.ssid connection show "$uuid" 2>/dev/null)
            s_name=$(nmcli -g connection.id connection show "$uuid" 2>/dev/null)
            
            if [[ -n "$s_ssid" ]]; then
                saved_connections["$s_ssid"]="$s_name"
            fi
        done

        echo -e "$(gum style --foreground "$COLOR_SECONDARY" " Scanning networks...")"

        # 2. Scan Wifi List
        local wifi_list
        wifi_list=$(nmcli -t -f IN-USE,SSID,SECURITY,BARS device wifi list --rescan yes 2>/dev/null)

        # 3. Build the Menu List
        local menu_options=""
        
        while IFS=: read -r in_use ssid security bars; do
            [[ -z "$ssid" ]] && continue

            local display_str=""
            local status_icon=""
            local status_text=""
            
            # Determine Status
            if [[ "$in_use" == "*" ]]; then
                status_icon="" 
                status_text="Active"
            elif [[ -n "${saved_connections["$ssid"]}" ]]; then
                status_icon="" 
                status_text="Saved"
            else
                status_icon=""
                status_text="New"
            fi

            # Visual formatting for Gum
            # We pack the raw data into the string using a delimiter that won't appear in SSIDs usually
            # Using valid Nerd Fonts
            menu_options+="$status_icon $status_text;;$ssid;;$security;;$bars"$'\n'

        done <<< "$wifi_list"

        # 4. Display Menu with Alignment
        header
        
        # Check if we found anything
        if [[ -z "$menu_options" ]]; then
            show_error "No networks found"
            return
        fi

        local selected_line
        # We use awk to create nice columns. 
        # $1=Status $2=SSID $3=Sec $4=Bars
        selected_line=$(echo -e "$menu_options" | \
            awk -F';;' '{printf "%-10s  %-25s  %-10s  %s\n", $1, $2, $3, $4}' | \
            gum filter --placeholder "Select a network..." --height 15 --indicator="➜" --header "STATUS      SSID                       SECURITY    SIGNAL")

        [[ -z "$selected_line" ]] && return

        # 5. Extract SSID cleanly
        # We rely on the robust delimiter ';;' from the raw loop, but we only have the visual line now.
        # We must parse the visual line.
        # Visual: " Active    MyWifi                     WPA2        ▂▄▆_"
        # Fixed width parsing is risky if SSID is long.
        # Better: Search the original menu_options for the line that matches the visual selection partially.
        
        # Actually, let's just use cut based on the spaces we injected in awk.
        # Warning: SSIDs can contain spaces.
        # Strategy: The SSID is the 2nd column in our visual table.
        # The first column is 12 chars wide (Status + Icon).
        # SSID starts at char 13. Length 25.
        local selected_ssid
        selected_ssid=$(echo "$selected_line" | cut -c 13-38 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # 6. Action Logic
        local is_saved="${saved_connections["$selected_ssid"]}"
        local is_active=false
        local active_name
        active_name=$(get_active_connection)

        # Check if strictly active
        if [[ -n "$active_name" && "$active_name" == "$is_saved" ]]; then
            is_active=true
        fi

        handle_connection_action "$selected_ssid" "$is_saved" "$is_active"
    done
}

handle_connection_action() {
    local ssid="$1"
    local conn_name="$2"
    local is_active="$3"

    local action
    
    # Case 1: Network is currently ACTIVE
    if [[ "$is_active" == "true" ]]; then
        action=$(gum choose --header "Managing: $ssid (Active)" "Disconnect" "Forget" "Cancel")
        case "$action" in
            "Disconnect")
                gum spin --spinner dot --title "Disconnecting..." -- sudo nmcli con down "$conn_name" 2>/dev/null
                notify "Wi-Fi" "Disconnected from $ssid"
                ;;
            "Forget")
                if gum confirm "Permanently delete $ssid?"; then
                    sudo nmcli con delete "$conn_name" 2>/dev/null
                    show_success "Forgot network"
                fi
                ;;
        esac

    # Case 2: Network is SAVED but NOT ACTIVE
    elif [[ -n "$conn_name" ]]; then
        action=$(gum choose --header "Managing: $ssid (Saved)" "Connect" "Forget" "Cancel")
        case "$action" in
            "Connect")
                # Use 'con up' for saved networks, NOT 'dev wifi connect'
                if gum spin --spinner dot --title "Connecting to $ssid..." -- sudo nmcli con up "$conn_name" 2>/dev/null; then
                    show_success "Connected"
                    notify "Wi-Fi" "Connected to $ssid"
                else
                    show_error "Connection Failed"
                fi
                ;;
            "Forget")
                if gum confirm "Permanently delete $ssid?"; then
                    sudo nmcli con delete "$conn_name" 2>/dev/null
                    show_success "Forgot network"
                fi
                ;;
        esac

    # Case 3: NEW Network
    else
        # Prompt for password
        local pass
        echo -e "$(gum style --foreground "$COLOR_ACCENT" "Enter Password for: $ssid")"
        pass=$(gum input --password --placeholder "Password (leave empty for Open)...")
        
        # If user hit Esc (exit code != 0), return
        if [ $? -ne 0 ]; then return; fi

        local connect_cmd
        if [[ -z "$pass" ]]; then
            connect_cmd="sudo nmcli device wifi connect \"$ssid\""
        else
            connect_cmd="sudo nmcli device wifi connect \"$ssid\" password \"$pass\""
        fi

        # Run connection
        if gum spin --spinner points --title "Negotiating with $ssid..." -- bash -c "$connect_cmd > /dev/null 2>&1"; then
            show_success "Connected!"
            notify "Wi-Fi" "Successfully connected to $ssid"
        else
            show_error "Failed to connect"
            notify "Wi-Fi" "Connection failed for $ssid"
        fi
    fi
}

# --- Manage Saved Profiles ---

manage_saved() {
    while true; do
        header
        echo -e "$(gum style --foreground "$COLOR_SECONDARY" "Loading profiles...")"

        local profiles
        profiles=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep ':802-11-wireless' | cut -d: -f1 | sort)

        if [[ -z "$profiles" ]]; then
            show_error "No saved profiles found."
            return
        fi

        local selected_profile
        selected_profile=$(echo "$profiles" | gum filter --header "Select Profile to Manage" --placeholder "Search profiles..." --height 10)

        [[ -z "$selected_profile" ]] && return

        local action
        action=$(gum choose --header "Profile: $selected_profile" "Connect" "Edit (nmtui)" "Delete" "Back")

        case "$action" in
            "Connect")
                gum spin --spinner dot --title "Activating..." -- sudo nmcli con up "$selected_profile" 2>/dev/null
                ;;
            "Edit (nmtui)")
                nmtui-edit "$selected_profile"
                ;;
            "Delete")
                if gum confirm "Delete $selected_profile?"; then
                    sudo nmcli con delete "$selected_profile" 2>/dev/null
                    show_success "Deleted"
                fi
                ;;
        esac
    done
}

# --- Main Entry Point ---

# Check if NM is running
if ! systemctl is-active --quiet NetworkManager.service; then
    gum style --foreground "$COLOR_ERROR" --border double --padding "1" "NetworkManager is NOT running."
    if gum confirm "Start NetworkManager now?"; then
        gum spin --title "Starting service..." -- sudo systemctl start NetworkManager.service
    else
        exit 1
    fi
fi

while true; do
    header
    
    active_con=$(get_active_connection)
    if [[ -n "$active_con" ]]; then
        gum style --foreground "$COLOR_SUCCESS" --align center "Connected to: $active_con"
    else
        gum style --foreground "$COLOR_ERROR" --align center "Disconnected"
    fi
    echo ""

    CHOICE=$(gum choose --cursor-prefix "➜ " --selected.foreground "$COLOR_PRIMARY" \
        "1. Scan & Connect" \
        "2. Manage Saved Profiles" \
        "3. Toggle Radio (On/Off)" \
        "Exit")

    case "$CHOICE" in
        "1. Scan & Connect")
            scan_and_connect
            ;;
        "2. Manage Saved Profiles")
            manage_saved
            ;;
        "3. Toggle Radio (On/Off)")
            status=$(nmcli radio wifi)
            if [[ "$status" == "enabled" ]]; then
                gum spin --title "Disabling Wi-Fi..." -- nmcli radio wifi off 2>/dev/null
            else
                gum spin --title "Enabling Wi-Fi..." -- nmcli radio wifi on 2>/dev/null
            fi
            ;;
        "Exit")
            clear
            exit 0
            ;;
    esac
done
