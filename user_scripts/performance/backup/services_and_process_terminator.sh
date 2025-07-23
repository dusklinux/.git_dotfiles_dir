#!/bin/bash
#
# performance_toggle.sh (v1.1)
#
# A script to temporarily kill processes and stop services to free up resources.
# Uses 'dialog' for an interactive TUI.
#
# Author: Your AI Assistant (with feedback from user)
# Version: 1.1 - Simplified configuration to avoid duplicate entries.

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# --- CONFIGURATION ---
# --- Define your items in ONE of the lists below. ---
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---



#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# --- Processes ---
# Processes to be STOPPED BY DEFAULT. They will be pre-selected in the menu.
# Run with --auto, these are the processes that will be killed.
DEFAULT_PROCESSES=(
    "swww-daemon"
    "firewalld"
    "waybar"
    "wallpaper_updat"
    "swaync"
)
# Optional processes to show in the checklist (but OFF by default).
OPTIONAL_PROCESSES=(
    "blueman-manager"
    "hyprsunset"
)


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# --- System Services (requires sudo) ---
# System services to be STOPPED BY DEFAULT.
DEFAULT_SYSTEM_SERVICES=(
    "vsftpd"
    "firewalld"
    "systemd-timesyncd"
    "systemd-journald"
    "logrotate.timer"
    "shadow.timer"
    "systemd-tmpfiles-clean.timer"
    "archlinux-keyring-wkd-sync.timer"
    "systemd-coredump.socket"
    "systemd-hostnamed.socket"
    "sshd"
)
# Optional system services.
OPTIONAL_SYSTEM_SERVICES=(
    "waydroid-container"
    "NetworkManager"
    "warp-svc"
    "wpa_supplicant"
    "bluetooth"
    "polkit"
    "upower"
    "udisks2"
    "rtkit-daemon"
    "systemd-udevd"
    "systemd-importd.socket"

)



#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# --- User Services ---
# User services to be STOPPED BY DEFAULT.
DEFAULT_USER_SERVICES=(
    "xdg-user-dirs-update"
    "gnome-keyring-daemon"
    "hyprpolkitagent"
    "app-blueman@autostart"
    "at-spi-dbus-bus"
)
# Optional user services.
OPTIONAL_USER_SERVICES=(
    "pipewire-pulse.socket"
    "pipewire.socket"
    "pipewire-pulse"
    "pipewire"
    "wireplumber"
    "p11-kit-server"
    "gvfs-daemon.service"
    "gnome-keyring-daemon"
    "gnome-keyring-daemon"

)







# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
# --- SCRIPT LOGIC ---
# --- (No modification needed below this line) ---
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# --- Combine lists for internal use ---
PROCESS_LIST=("${DEFAULT_PROCESSES[@]}" "${OPTIONAL_PROCESSES[@]}")
SYSTEM_SERVICE_LIST=("${DEFAULT_SYSTEM_SERVICES[@]}" "${OPTIONAL_SYSTEM_SERVICES[@]}")
USER_SERVICE_LIST=("${DEFAULT_USER_SERVICES[@]}" "${OPTIONAL_USER_SERVICES[@]}")
# --- --- --- --- --- --- --- --- --- --- ---

# 1. Dependency Check
if ! command -v dialog &> /dev/null; then
    echo "Error: 'dialog' is not installed. Please install it to run this script."
    echo "On Arch Linux: sudo pacman -S dialog"
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
        "process")
            pgrep -x "$item_name" &> /dev/null && echo "active" || echo "inactive"
            ;;
        "system_service")
            systemctl is-active --quiet "$item_name" && echo "active" || echo "inactive"
            ;;
        "user_service")
            systemctl --user is-active --quiet "$item_name" && echo "active" || echo "inactive"
            ;;
    esac
}

# 3. Initial Status Report
show_initial_status() {
    local running_items="The following configured items are currently RUNNING:\n\n"
    local found_running=false

    # Check Processes
    for item in "${PROCESS_LIST[@]}"; do
        if [[ $(get_status "$item" "process") == "active" ]]; then
            running_items+="[Process] $item\n"
            found_running=true
        fi
    done

    # Check System Services
    for item in "${SYSTEM_SERVICE_LIST[@]}"; do
        if [[ $(get_status "$item" "system_service") == "active" ]]; then
            running_items+="[System Service] $item\n"
            found_running=true
        fi
    done

    # Check User Services
    for item in "${USER_SERVICE_LIST[@]}"; do
        if [[ $(get_status "$item" "user_service") == "active" ]]; then
            running_items+="[User Service] $item\n"
            found_running=true
        fi
    done
    
    if ! $found_running; then
        running_items="None of the configured processes or services are currently running."
    fi

    dialog --title "Initial Status" --msgbox "$running_items" 15 70
}

# 4. Main Interactive Menu
build_and_show_checklist() {
    local checklist_options=()
    
    # Add Processes to checklist
    for item in "${PROCESS_LIST[@]}"; do
        status_text=$(get_status "$item" "process")
        default_state="off"
        # Check if the item is in the DEFAULT list to set its state
        containsElement "$item" "${DEFAULT_PROCESSES[@]}" && default_state="on"
        checklist_options+=("$item" "Process ($status_text)" "$default_state")
    done

    # Add System Services to checklist
    for item in "${SYSTEM_SERVICE_LIST[@]}"; do
        status_text=$(get_status "$item" "system_service")
        default_state="off"
        containsElement "$item" "${DEFAULT_SYSTEM_SERVICES[@]}" && default_state="on"
        checklist_options+=("$item" "System Service ($status_text)" "$default_state")
    done

    # Add User Services to checklist
    for item in "${USER_SERVICE_LIST[@]}"; do
        status_text=$(get_status "$item" "user_service")
        default_state="off"
        containsElement "$item" "${DEFAULT_USER_SERVICES[@]}" && default_state="on"
        checklist_options+=("$item" "User Service ($status_text)" "$default_state")
    done
    
    local selection
    selection=$(dialog --title "Performance Toggle" \
                     --checklist "Select items to STOP or KILL. \nUse SPACE to toggle, ENTER to confirm." \
                     20 70 15 \
                     "${checklist_options[@]}" \
                     3>&1 1>&2 2>&3 3>&-)
    
    echo "$selection"
}

# 5. Action Phase
execute_selection() {
    local selected_items=("$@")
    local sudo_needed=false
    local system_services_to_stop=()
    
    for item in "${selected_items[@]}"; do
        if containsElement "$item" "${SYSTEM_SERVICE_LIST[@]}"; then
            sudo_needed=true
            system_services_to_stop+=("$item")
        fi
    done

    if $sudo_needed; then
        if ! sudo -v; then
            dialog --title "Sudo Required" --msgbox "Sudo privileges are required to stop system services. Please enter your password." 8 50
            if ! sudo -v; then
                dialog --title "Error" --msgbox "Sudo authentication failed. Cannot stop system services." 8 50
                sudo_needed=false
            fi
        fi
    fi
    
    for item in "${selected_items[@]}"; do
        if containsElement "$item" "${PROCESS_LIST[@]}"; then
            if [[ $(get_status "$item" "process") == "active" ]]; then
                pkill -x "$item"
                echo "Killed process: $item"
            fi
        fi
        
        if containsElement "$item" "${USER_SERVICE_LIST[@]}"; then
            if [[ $(get_status "$item" "user_service") == "active" ]]; then
                systemctl --user stop "$item"
                echo "Stopped user service: $item"
            fi
        fi
    done
    
    if $sudo_needed && [ ${#system_services_to_stop[@]} -gt 0 ]; then
        echo "Stopping system services with sudo: ${system_services_to_stop[*]}"
        sudo systemctl stop "${system_services_to_stop[@]}"
    fi
}

# 6. Final Report
show_final_status() {
    local stopped_items="The following configured items are now INACTIVE:\n(Either stopped by script or were not running)\n\n"
    
    ALL_ITEMS=("${PROCESS_LIST[@]}" "${SYSTEM_SERVICE_LIST[@]}" "${USER_SERVICE_LIST[@]}")
    for item in "${ALL_ITEMS[@]}"; do
        type=""
        containsElement "$item" "${PROCESS_LIST[@]}" && type="process"
        containsElement "$item" "${SYSTEM_SERVICE_LIST[@]}" && type="system_service"
        containsElement "$item" "${USER_SERVICE_LIST[@]}" && type="user_service"
        
        if [[ $(get_status "$item" "$type") == "inactive" ]]; then
            stopped_items+="[${type^}] $item\n"
        fi
    done

    dialog --title "Final Status" --msgbox "$stopped_items" 15 70
}

# --- --- --- Main Execution Flow --- --- ---

# Non-interactive mode for automation/keybinding
if [[ "$1" == "--auto" ]]; then
    AUTO_SELECTION=("${DEFAULT_PROCESSES[@]}" "${DEFAULT_SYSTEM_SERVICES[@]}" "${DEFAULT_USER_SERVICES[@]}")
    execute_selection "${AUTO_SELECTION[@]}"
    exit 0
fi

# Interactive Mode
clear
show_initial_status
SELECTION=$(build_and_show_checklist)

if [ -z "$SELECTION" ]; then
    clear
    echo "Operation cancelled by user."
    exit 1
fi

clear
execute_selection $SELECTION
show_final_status
clear
echo "Performance script finished."
