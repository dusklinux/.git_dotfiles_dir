#!/bin/bash

# A comprehensively rewritten, robust, and user-friendly menu-driven script for
# managing NetworkManager connections. This version uses a guaranteed-correct
# method to identify saved networks and provides clear, distinct workflows for
# interacting with visible networks and managing all saved profiles.

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Function to Pause and Wait for User ---
press_enter_to_continue() {
    echo ""
    read -p "Press [Enter] to return..."
}

# --- Reusable Function to Manage a Single Connection Profile ---
# Takes one argument: the connection NAME (e.g., "HomeWiFi" or "Near").
# This function is the single point of truth for all connection actions.
manage_single_connection() {
    local conn_name="$1"
    
    if [ -z "$conn_name" ]; then
        echo -e "${RED}Error: No connection name provided to management function.${NC}" >&2
        sleep 2
        return
    fi
    
    # Escape special characters for safe use in grep
    local safe_conn_name=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<< "$conn_name")

    if nmcli -t -f NAME,DEVICE connection show --active | grep -q "^${safe_conn_name}:"; then
        current_status="${GREEN}[Active]${NC}"
    else
        current_status="${RED}[Inactive]${NC}"
    fi

    clear
    echo -e "${YELLOW}Managing Connection Profile:${NC} ${CYAN}$conn_name${NC}"
    echo -e "Current Status:             $current_status"
    echo "------------------------------------------------"
    echo "  1) Connect (Bring Up)"
    echo "  2) Disconnect (Bring Down)"
    echo "  3) Forget (Permanently Delete this Profile)"
    echo "  q) Go back"
    echo ""
    read -p "What would you like to do? " action_choice

    case "$action_choice" in
        1) sudo nmcli connection up "$conn_name" && echo -e "\n${GREEN}Activation successful.${NC}" || echo -e "\n${RED}Failed to activate.${NC}" ;;
        2) sudo nmcli connection down "$conn_name" && echo -e "\n${GREEN}Deactivation successful.${NC}" || echo -e "\n${RED}Failed to deactivate.${NC}" ;;
        3)
            read -p "Are you sure you want to PERMANENTLY delete '$conn_name'? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                sudo nmcli connection delete "$conn_name" && echo -e "\n${GREEN}Profile deleted.${NC}" || echo -e "\n${RED}Failed to delete profile.${NC}"
            else
                echo "Deletion cancelled."
            fi ;;
        [qQ]) return ;;
        *) echo -e "\n${RED}Invalid action.${NC}" ;;
    esac
    press_enter_to_continue
}

# --- MENU FUNCTION 1: Scan and Interact with VISIBLE Wi-Fi Networks ---
interactive_scan_and_connect() {
    while true; do
        clear
        echo -e "${BLUE}--- Scanning for Visible Wi-Fi Networks ---${NC}"
        echo "Building network list... please wait."
        
        # **THE DEFINITIVE FIX**: Build a reliable map of Saved SSID -> Saved NAME.
        # This is done in two stages to be 100% correct, avoiding previous errors.
        declare -A saved_ssid_map
        # Stage 1: Get the NAMES of all saved Wi-Fi connections.
        mapfile -t saved_conn_names < <(nmcli -t -f NAME,TYPE c s | grep ':802-11-wireless$' | cut -d: -f1)
        
        # Stage 2: For each NAME, get its specific SSID and build the map.
        # This is the correct way, as querying 'ssid' on a general list is invalid.
        for name in "${saved_conn_names[@]}"; do
            # Use 'nmcli -g' (get-value) on a single connection 'id' for reliability.
            ssid=$(nmcli -g 802-11-wireless.ssid c s id "$name")
            if [ -n "$ssid" ]; then
                saved_ssid_map["$ssid"]="$name"
            fi
        done

        mapfile -t visible_networks < <(nmcli -t -f IN-USE,SSID,SECURITY dev wifi list --rescan yes)

        if [ ${#visible_networks[@]} -eq 0 ]; then
            echo -e "${RED}No Wi-Fi networks found.${NC}"; press_enter_to_continue; return;
        fi
        
        echo -e "${YELLOW}Please select a network:${NC}"
        declare -a network_ssids network_names network_statuses

        for i in "${!visible_networks[@]}"; do
            line="${visible_networks[$i]}"
            in_use=$(cut -d: -f1 <<< "$line")
            ssid=$(cut -d: -f2 <<< "$line")
            security=$(cut -d: -f3- <<< "$line")

            network_ssids[$i]=$ssid
            local status_tag display_status
            
            # Now, check the visible SSID against our accurately built map.
            if [[ "$in_use" == "*" ]]; then
                status_tag="active"
                display_status="${GREEN}[Active]${NC}"
                network_names[$i]=${saved_ssid_map["$ssid"]:-$ssid}
            elif [[ -v saved_ssid_map["$ssid"] ]]; then
                status_tag="saved"
                display_status="${CYAN}[Saved]${NC}"
                network_names[$i]=${saved_ssid_map["$ssid"]}
            else
                status_tag="new"
                display_status="${YELLOW}[New]${NC}"
                network_names[$i]=""
            fi
            network_statuses[$i]=$status_tag
            
            printf "  ${BLUE}%2d)${NC} %-25.25s %-18.18s %b\n" "$((i+1))" "$ssid" "$security" "$display_status"
        done
        
        echo "------------------------------------------------------------"
        echo "  r) Rescan for networks"
        echo "  q) Back to main menu"
        echo ""
        read -p "Enter your choice: " choice

        case "$choice" in
            [rR]) continue ;;
            [qQ]) return ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#visible_networks[@]}" ]; then
                    selected_ssid="${network_ssids[$((choice-1))]}"
                    selected_name="${network_names[$((choice-1))]}"
                    selected_status="${network_statuses[$((choice-1))]}"
                    
                    if [[ "$selected_status" == "active" || "$selected_status" == "saved" ]]; then
                        manage_single_connection "$selected_name"
                    else # This is a "new" network
                        read -s -p "Enter password for new network '$selected_ssid': " password; echo ""
                        if sudo nmcli device wifi connect "$selected_ssid" password "$password"; then
                           echo -e "\n${GREEN}Successfully connected to '$selected_ssid' and saved connection!${NC}"
                        else
                           echo -e "\n${RED}Failed to connect. Please check password or network status.${NC}"
                        fi
                        press_enter_to_continue
                    fi
                    return
                else
                    echo -e "\n${RED}Invalid option.${NC}"; sleep 2
                fi ;;
        esac
    done
}

# --- MENU FUNCTION 2: Manage ALL Saved Wi-Fi Networks ---
manage_all_saved_wifi() {
    while true; do
        clear
        echo -e "${BLUE}--- Manage ALL Saved Wi-Fi Networks ---${NC}"
        mapfile -t saved_wifi_names < <(nmcli -t -f NAME,TYPE c s | grep ':802-11-wireless$' | cut -d: -f1)
        
        if [ ${#saved_wifi_names[@]} -eq 0 ]; then
            echo -e "${RED}No saved Wi-Fi connections found.${NC}"; press_enter_to_continue; return;
        fi

        echo -e "${YELLOW}Select a saved profile to manage:${NC}"
        for i in "${!saved_wifi_names[@]}"; do
            printf "  ${BLUE}%2d)${NC} %s\n" "$((i+1))" "${saved_wifi_names[$i]}"
        done
        echo "----------------------------------------"
        echo "  q) Back to main menu"
        echo ""
        read -p "Enter your choice: " choice

        if [[ "$choice" =~ ^[qQ]$ ]]; then
            return
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#saved_wifi_names[@]}" ]; then
            manage_single_connection "${saved_wifi_names[$((choice-1))]}"
            return
        else
            echo -e "\n${RED}Invalid selection.${NC}"; sleep 2
        fi
    done
}

# --- Initial Prerequisite Check ---
if ! systemctl is-active --quiet NetworkManager.service; then
    clear
    echo -e "${YELLOW}WARNING: NetworkManager service is not running.${NC}"
    read -p "Attempt to start it now? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        if sudo systemctl start NetworkManager.service && sudo systemctl enable NetworkManager.service; then
            echo -e "${GREEN}Successfully started and enabled NetworkManager.${NC}"; sleep 2
        else
            echo -e "${RED}ERROR: Failed to start NetworkManager.${NC}"; exit 1
        fi
    else
        echo -e "${RED}Exiting. Script cannot continue without NetworkManager.${NC}"; exit 1
    fi
fi

# --- Main Menu Loop ---
while true; do
    clear
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}    Network Manager Control Script       ${NC}"
    echo -e "${BLUE}=========================================${NC}"
    active_conn=$(nmcli -t -f NAME,DEVICE connection show --active | head -n1 | cut -d: -f1)
    [ -n "$active_conn" ] && status_line="Status: ${GREEN}$active_conn [Active]${NC}" || status_line="Status: ${RED}Not Connected${NC}"
    echo -e "$status_line\n"
    
    echo -e "${YELLOW}What would you like to do?${NC}"
    echo "  1) Scan & Interact with Visible Wi-Fi"
    echo "  2) Manage ALL Saved Wi-Fi Networks"
    echo "  3) Show all network devices (Wi-Fi, Ethernet, etc.)"
    echo ""
    echo "  q) Quit"
    echo ""
    read -p "Enter your choice: " main_choice

    case "$main_choice" in
        1) interactive_scan_and_connect ;;
        2) manage_all_saved_wifi ;;
        3) clear; echo -e "${BLUE}--- Available Network Devices ---${NC}"; nmcli device; press_enter_to_continue ;;
        q|Q) clear; echo "Exiting script. Goodbye!"; exit 0 ;;
        *) echo -e "\n${RED}Invalid option.${NC}"; sleep 2 ;;
    esac
done
