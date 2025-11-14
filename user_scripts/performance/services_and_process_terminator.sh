#!/bin/bash
#
# performance_toggle.sh (v2.8)
#
# A script to temporarily kill processes and stop services to free up resources.
# Uses 'gum' for an interactive TUI.
#
# Author: Your AI Assistant
# Version: 2.8 - Critical fix for terminal auto-closing.
#                The script now concludes by executing an interactive shell
#                to keep the terminal window open when run via a keybinding,
#                ensuring the final report is always visible.
#

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# --- CONFIGURATION ---
# --- Define your items in ONE of the lists below. ---
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# --- Processes ---
# Processes to be STOPPED BY DEFAULT if they are running.
DEFAULT_PROCESSES=(
    "hyprsunset"
    "swww-daemon"
    "inotifywait"
    "wl-paste"
    "wl-copy"
    "hypridle"
    "waybar"
    "wallpaper_updat"
    "swaync"
    "swayosd-server"
)
# Optional processes to show in the checklist (but OFF by default).
OPTIONAL_PROCESSES=(
)


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# --- System Services (requires sudo) ---
# System services to be STOPPED BY DEFAULT if they are running.
DEFAULT_SYSTEM_SERVICES=(
  "udisks2"
  "firewalld"
  "vsftpd"
  "swayosd-libinput-backend"
  "warp-svc"
  "waydroid-container"
  "logrotate.timer"
  "sshd"
)
# Optional system services.
OPTIONAL_SYSTEM_SERVICES=(
  "NetworkManager-dispatcher"
  "NetworkManager"
  "wpa_supplicant"
  "acpid"
  "asusd"
)


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# --- User Services ---
# User services to be STOPPED BY DEFAULT if they are running.
DEFAULT_USER_SERVICES=(
  "hypridle"
  "hyprpolkitagent"
  "gvfs-daemon"
  "gvfs-metadata"
  "firewalld"
  "hyprpolkitagent"
  "swaync"
  "blueman-applet"
  "network_meter"
  "battery_notify"
  "blueman-manager"
  "waybar"
  "gnome-keyring-daemon"
  "hyprpolkitagent"
  "hyprsunset"
)
# Optional user services.
OPTIONAL_USER_SERVICES=(
  "pipewire-pulse.socket"
  "pipewire.socket"
  "pipewire-pulse"
  "pipewire"
  "wireplumber"
)

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# --- SCRIPT LOGIC ---
# --- (No modification needed below this line) ---
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# 1. Dependency Check
if ! command -v gum &> /dev/null; then
    echo "Error: 'gum' is not installed. Please install it to run this script."
    echo "Find instructions at: https://github.com/charmbracelet/gum"
    exit 1
fi

# Function to check if an item is in a list
# Usage: containsElement "item" "${array[@]}"
containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# 2. Status Gathering
get_status() {
    local item_name="$1"
    local item_type="$2" # "process", "system_service", or "user_service"

    case "$item_type" in
        "process") pgrep -x "$item_name" &> /dev/null && echo "active" || echo "inactive" ;;
        "system_service") systemctl is-active --quiet "$item_name" && echo "active" || echo "inactive" ;;
        "user_service") systemctl --user is-active --quiet "$item_name" && echo "active" || echo "inactive" ;;
    esac
}

# 3. Main Interactive Menu
build_and_show_menu() {
    local active_items_to_display=()
    local items_to_preselect=()
    local item_metadata=() # parallel array to store item type and name

    # --- Gather all active items and their types ---
    local all_processes=("${DEFAULT_PROCESSES[@]}" "${OPTIONAL_PROCESSES[@]}")
    local all_system_services=("${DEFAULT_SYSTEM_SERVICES[@]}" "${OPTIONAL_SYSTEM_SERVICES[@]}")
    local all_user_services=("${DEFAULT_USER_SERVICES[@]}" "${OPTIONAL_USER_SERVICES[@]}")

    # Helper function to process each list
    process_list() {
        local -n items=$1   # nameref to the array of items
        local -n defaults=$2 # nameref to the default list
        local type=$3        # string like "process"
        local type_display=$4 # string like "Process"

        for item in "${items[@]}"; do
            if [[ $(get_status "$item" "$type") == "active" ]]; then
                local display_name="$item ($type_display)"
                active_items_to_display+=("$display_name")
                item_metadata+=("$type:$item")
                if containsElement "$item" "${defaults[@]}"; then
                    items_to_preselect+=("$display_name")
                fi
            fi
        done
    }

    process_list all_processes DEFAULT_PROCESSES "process" "Process"
    process_list all_system_services DEFAULT_SYSTEM_SERVICES "system_service" "System Service"
    process_list all_user_services DEFAULT_USER_SERVICES "user_service" "User Service"


    if [ ${#active_items_to_display[@]} -eq 0 ]; then
        gum style --border normal --padding "1 2" --border-foreground 212 "Nothing to do!" "All configured services and processes are already inactive."
        exit 0
    fi

    # Pre-select default items by converting array to comma-separated string
    local selected_string
    local IFS=','
    selected_string="${items_to_preselect[*]}"
    unset IFS

    local selection
    selection=$(gum choose --no-limit --height 15 \
                         --header "Select items to STOP. (SPACE to toggle, ENTER to confirm)" \
                         --cursor-prefix "[ ] " --selected-prefix "[✓] " \
                         --unselected-prefix "[ ] " \
                         --selected="$selected_string" \
                         "${active_items_to_display[@]}")

    # If nothing is selected (user pressed ESC), exit
    if [ -z "$selection" ]; then
        echo "Operation cancelled."
        exit 130 # Use standard exit code for Ctrl+C / ESC
    fi

    # Find the original metadata for the selected display names
    local final_selection_metadata=()
    local selected_array
    mapfile -t selected_array <<< "$selection"

    for sel in "${selected_array[@]}"; do
        for i in "${!active_items_to_display[@]}"; do
            if [[ "${active_items_to_display[$i]}" == "$sel" ]]; then
                final_selection_metadata+=("${item_metadata[$i]}")
                break
            fi
        done
    done
    printf '%s\n' "${final_selection_metadata[@]}"
}


# 4. Action Phase (Now with Verification)
execute_selection() {
    local selected_items_str="$1"
    if [ -z "$selected_items_str" ]; then
        gum style --border normal --padding "1 2" --border-foreground 220 "No items were selected to stop."
        return
    fi

    local system_services_to_stop=()
    local user_services_to_stop=()
    local processes_to_kill=()

    # Read selection into arrays based on metadata
    while IFS= read -r item; do
        local type="${item%%:*}"
        local name="${item#*:}"
        case "$type" in
            "process") processes_to_kill+=("$name") ;;
            "user_service") user_services_to_stop+=("$name") ;;
            "system_service") system_services_to_stop+=("$name") ;;
        esac
    done <<< "$selected_items_str"

    # Check for sudo if needed
    if [ ${#system_services_to_stop[@]} -gt 0 ]; then
        if ! sudo -v &> /dev/null; then
            gum confirm "Sudo privileges are required to stop system services. Authenticate now?" || exit 1
        fi
        # Refresh sudo timestamp before batch operation
        sudo -v
    fi

    local success_report="Successfully stopped:\n"
    local failure_report="Failed to stop (still active):\n"
    local success_count=0
    local failure_count=0

    # Kill Processes
    if [ ${#processes_to_kill[@]} -gt 0 ]; then
        for p in "${processes_to_kill[@]}"; do
            pkill -x "$p"
            sleep 0.1 # Give the process a moment to terminate
            if [[ $(get_status "$p" "process") == "inactive" ]]; then
                success_report+="- Process: $p\n"
                ((success_count++))
            else
                failure_report+="- Process: $p\n"
                ((failure_count++))
            fi
        done
    fi

    # Stop User Services
    if [ ${#user_services_to_stop[@]} -gt 0 ]; then
        for s in "${user_services_to_stop[@]}"; do
            systemctl --user stop "$s" &> /dev/null
            if [[ $(get_status "$s" "user_service") == "inactive" ]]; then
                success_report+="- User Service: $s\n"
                ((success_count++))
            else
                failure_report+="- User Service: $s\n"
                ((failure_count++))
            fi
        done
    fi

    # Stop System Services
    if [ ${#system_services_to_stop[@]} -gt 0 ]; then
        for s in "${system_services_to_stop[@]}"; do
            sudo systemctl stop "$s" &> /dev/null
            if [[ $(get_status "$s" "system_service") == "inactive" ]]; then
                success_report+="- System Service: $s\n"
                ((success_count++))
            else
                failure_report+="- System Service: $s\n"
                ((failure_count++))
            fi
        done
    fi

    local full_report="Execution Report\n\n"

    if [ "$success_count" -gt 0 ]; then
        full_report+="$success_report"
    fi
    if [ "$failure_count" -gt 0 ]; then
        full_report+="\n\n$failure_report"
    fi
    if [ "$success_count" -eq 0 ] && [ "$failure_count" -eq 0 ]; then
        full_report+="No actions were performed or status remains unchanged."
    fi

    printf "%b" "$full_report" | gum style --border normal --padding "1 2" --border-foreground 212
}

# 5. Hold Terminal Open Function
# This function prevents the terminal from auto-closing by starting an interactive shell.
# This is crucial for running the script via keybindings.
hold_terminal_open() {
    echo ""
    echo "-----------------------------------------------------"
    gum style --bold "Script finished. Execution report is above."
    echo "An interactive shell will now start to keep this terminal open."
    echo "Type 'exit' or press Ctrl+D to close this window."
    echo "-----------------------------------------------------"
    # Replace the current script process with the user's default shell to keep the terminal alive.
    exec "${SHELL:-/bin/bash}"
}


# --- --- --- Main Execution Flow --- --- ---

# Non-interactive mode for automation/keybinding
if [[ "$1" == "--auto" ]]; then
    AUTO_SELECTION=""
    # Gather default processes
    for item in "${DEFAULT_PROCESSES[@]}"; do
        [[ $(get_status "$item" "process") == "active" ]] && AUTO_SELECTION+="process:$item\n"
    done
    # Gather default system services
    for item in "${DEFAULT_SYSTEM_SERVICES[@]}"; do
        [[ $(get_status "$item" "system_service") == "active" ]] && AUTO_SELECTION+="system_service:$item\n"
    done
    # Gather default user services
    for item in "${DEFAULT_USER_SERVICES[@]}"; do
        [[ $(get_status "$item" "user_service") == "active" ]] && AUTO_SELECTION+="user_service:$item\n"
    done

    clear
    execute_selection "$AUTO_SELECTION"
    hold_terminal_open
fi

# Interactive Mode
clear
gum style --border double --padding "1 2" --border-foreground 57 "Performance Toggle Script"
SELECTION=$(build_and_show_menu)

# The exit code of 'gum choose' is 0 on selection, but 130 on ESC.
if [ $? -ne 0 ]; then
    clear
    echo "Operation cancelled by user."
    exit 1
fi

clear
execute_selection "$SELECTION"
hold_terminal_open
