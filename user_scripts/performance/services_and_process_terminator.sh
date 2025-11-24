#!/bin/bash
#
# performance_toggle.sh (v3.1)
#
# A robust utility to terminate processes and stop services to free up system resources.
# Optimized for Arch Linux / Hyprland workflows.
#
# v3.1 FIX: Removed 'gum spin' wrapper which caused scope issues with bash functions.
#
# Dependencies: gum, sudo, systemd, procps-ng
#

# --- SAFETY TRAP ---
trap 'echo -e "\n\033[1;31mScript encountered an error.\033[0m"; read -rp "Press Enter to exit..."' ERR

# --- CONFIGURATION ---

# 1. Processes (Raw Binaries)
DEFAULT_PROCESSES=(
    "hyprsunset"
    "swww-daemon"
    "waybar"
)
OPTIONAL_PROCESSES=(
    "inotifywait"
    "wl-paste"
    "wl-copy"
    "firefox"
    "discord"
)

# 2. System Services (Root)
DEFAULT_SYSTEM_SERVICES=(
    "firewalld"
    "vsftpd"
    "waydroid-container"
    "logrotate.timer"
    "sshd"
)
OPTIONAL_SYSTEM_SERVICES=(
    "udisks2"
    "swayosd-libinput-backend"
    "warp-svc"
    "NetworkManager"
)

# 3. User Services (Systemd --user)
DEFAULT_USER_SERVICES=(
    "battery_notify"
    "blueman-applet"
    "blueman-manager"
    "hypridle"
    "hyprpolkitagent"
    "swaync"
    "gvfs-daemon"
    "gvfs-metadata"
    "network_meter"
    "waybar"
)
OPTIONAL_USER_SERVICES=(
    "gnome-keyring-daemon"
    "swayosd-server"
    "pipewire-pulse.socket"
    "pipewire.socket"
    "pipewire"
    "wireplumber"
)

# --- LOGIC IMPLEMENTATION ---

if ! command -v gum &> /dev/null; then
    echo "Error: 'gum' is not installed."
    exit 1
fi

contains_element() {
    local match="$1"; shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}

is_active() {
    local name="$1"
    local type="$2"
    case "$type" in
        "proc") pgrep -x "$name" &> /dev/null ;;
        "sys")  systemctl is-active --quiet "$name" ;;
        "user") systemctl --user is-active --quiet "$name" ;;
    esac
}

gather_candidates() {
    local -n list_proc_def=DEFAULT_PROCESSES
    local -n list_proc_opt=OPTIONAL_PROCESSES
    local -n list_sys_def=DEFAULT_SYSTEM_SERVICES
    local -n list_sys_opt=OPTIONAL_SYSTEM_SERVICES
    local -n list_usr_def=DEFAULT_USER_SERVICES
    local -n list_usr_opt=OPTIONAL_USER_SERVICES

    for p in "${list_proc_def[@]}" "${list_proc_opt[@]}"; do
        is_active "$p" "proc" && echo "proc:$p|$p (Process)"
    done
    for s in "${list_sys_def[@]}" "${list_sys_opt[@]}"; do
        is_active "$s" "sys" && echo "sys:$s|$s (System Svc)"
    done
    for u in "${list_usr_def[@]}" "${list_usr_opt[@]}"; do
        is_active "$u" "user" && echo "user:$u|$u (User Svc)"
    done
}

is_default_item() {
    local name="$1"
    local type="$2"
    case "$type" in
        "proc") contains_element "$name" "${DEFAULT_PROCESSES[@]}" ;;
        "sys")  contains_element "$name" "${DEFAULT_SYSTEM_SERVICES[@]}" ;;
        "user") contains_element "$name" "${DEFAULT_USER_SERVICES[@]}" ;;
    esac
}

perform_stop() {
    local type="$1"
    local name="$2"

    case "$type" in
        "proc")
            pkill -x "$name"
            # Wait loop: Check every 0.1s for up to 2 seconds
            for _ in {1..20}; do
                if ! is_active "$name" "proc"; then return 0; fi
                sleep 0.1
            done
            return 1
            ;;
        "sys")
            sudo systemctl stop "$name"
            ! is_active "$name" "sys"
            ;;
        "user")
            systemctl --user stop "$name"
            ! is_active "$name" "user"
            ;;
    esac
}

# --- EXECUTION PHASES ---

mapfile -t CANDIDATES < <(gather_candidates)

if [ ${#CANDIDATES[@]} -eq 0 ]; then
    gum style --border normal --padding "1 2" --border-foreground 212 "System Clean" "All monitored services/processes are already inactive."
    echo ""
    exec "${SHELL:-/bin/bash}"
fi

SELECTED_ITEMS=()

if [[ "$1" == "--auto" ]]; then
    for line in "${CANDIDATES[@]}"; do
        data="${line%%|*}"
        type="${data%%:*}"
        name="${data#*:}"
        if is_default_item "$name" "$type"; then
            SELECTED_ITEMS+=("$line")
        fi
    done
else
    OPTIONS_DISPLAY=()
    PRE_SELECTED_DISPLAY=()
    declare -A DATA_MAP

    for line in "${CANDIDATES[@]}"; do
        data="${line%%|*}"
        display="${line#*|}"
        type="${data%%:*}"
        name="${data#*:}"

        OPTIONS_DISPLAY+=("$display")
        DATA_MAP["$display"]="$data"

        if is_default_item "$name" "$type"; then
            PRE_SELECTED_DISPLAY+=("$display")
        fi
    done

    PRE_SELECTED_STR=$(IFS=, ; echo "${PRE_SELECTED_DISPLAY[*]}")

    gum style --border double --padding "1 2" --border-foreground 57 "Performance Terminator"

    SELECTION_RESULT=$(gum choose --no-limit --height 15 \
        --header "Select resources to FREE. (SPACE: toggle, ENTER: confirm)" \
        --selected="$PRE_SELECTED_STR" \
        "${OPTIONS_DISPLAY[@]}")

    if [ -z "$SELECTION_RESULT" ]; then
        echo "Cancelled."
        exit 0
    fi

    while IFS= read -r line; do
        [[ -n "$line" ]] && SELECTED_ITEMS+=("${DATA_MAP[$line]}")
    done <<< "$SELECTION_RESULT"
fi

if [ ${#SELECTED_ITEMS[@]} -eq 0 ]; then
    echo "No items selected."
    exec "${SHELL:-/bin/bash}"
fi

# Sudo Check
NEEDS_SUDO=false
for item in "${SELECTED_ITEMS[@]}"; do
    [[ "$item" == sys:* ]] && NEEDS_SUDO=true && break
done

if $NEEDS_SUDO; then
    if ! sudo -v; then
        gum style --foreground 196 "Authentication failed. Aborting."
        exit 1
    fi
fi

SUCCESS_LIST=()
FAIL_LIST=()

echo ""
gum style --bold "Stopping selected resources..."

# --- MAIN LOOP (Corrected) ---
for item in "${SELECTED_ITEMS[@]}"; do
    type="${item%%:*}"
    name="${item#*:}"
    
    # Print status (simulated spinner text since we can't use gum spin comfortably here)
    echo -n " • Stopping $name..."

    # Execute logic DIRECTLY in shell context
    if perform_stop "$type" "$name"; then
        echo -e "\r \033[0;32m✔\033[0m Stopped $name    "
        SUCCESS_LIST+=("$type: $name")
    else
        echo -e "\r \033[0;31m✘\033[0m Failed $name     "
        FAIL_LIST+=("$type: $name")
    fi
done

# --- REPORTING ---
REPORT=""

if [ ${#SUCCESS_LIST[@]} -gt 0 ]; then
    REPORT+="$(gum style --foreground 82 "✔ Successfully Stopped:")\n"
    for s in "${SUCCESS_LIST[@]}"; do REPORT+="  $s\n"; done
    REPORT+="\n"
fi

if [ ${#FAIL_LIST[@]} -gt 0 ]; then
    REPORT+="$(gum style --foreground 196 "✘ Failed to Stop (Still Active):")\n"
    for f in "${FAIL_LIST[@]}"; do REPORT+="  $f\n"; done
    REPORT+="\n"
fi

clear
gum style --border double --padding "1 2" --border-foreground 57 "Execution Complete"
echo -e "$REPORT"

trap - ERR
echo "-----------------------------------------------------"
echo "Session Active. Type 'exit' to close."
exec "${SHELL:-/bin/bash}"
