#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# ROFI POWER MENU (Fixed Delimiters)
# -----------------------------------------------------------------------------

set -e
set -u

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------

# Visual Configuration
showsymbols=true
declare -A icons
icons[shutdown]=""
icons[reboot]=""
icons[suspend]=""
icons[soft_reboot]=""
icons[logout]=""
icons[lock]=""
icons[cancel]=""

# Text Configuration
declare -A texts
texts[shutdown]="Shutdown"
texts[reboot]="Reboot"
texts[suspend]="Suspend"
texts[soft_reboot]="Soft Reboot"
texts[logout]="Logout"
texts[lock]="Lock"

# Action Configuration
declare -A actions
actions[shutdown]="systemctl poweroff"
actions[reboot]="systemctl reboot"
actions[suspend]="systemctl suspend"
actions[soft_reboot]="systemctl soft-reboot"
actions[logout]="loginctl terminate-session ${XDG_SESSION_ID-}"
actions[lock]="pidof hyprlock >/dev/null || hyprlock -q"

# Options
all_options=(lock logout suspend reboot shutdown)
confirmations=(reboot shutdown logout soft_reboot)
dryrun=false

# -----------------------------------------------------------------------------
# ARGUMENT PARSING
# -----------------------------------------------------------------------------

check_valid() {
    local option="$1"
    shift 1
    for entry in "$@"; do
        if [[ -z "${actions[$entry]+x}" ]]; then
            echo "Invalid choice: $entry" >&2
            exit 1
        fi
    done
}

parsed=$(getopt --options=h --longoptions=help,dry-run,confirm:,choices:,choose:,symbols,no-symbols --name "$0" -- "$@")
if [ $? -ne 0 ]; then echo 'Terminating...' >&2; exit 1; fi
eval set -- "$parsed"
unset parsed

while true; do
    case "$1" in
        -h|--help) exit 0 ;;
        --dry-run) dryrun=true; shift 1 ;;
        --confirm)
            IFS='/' read -ra confirmations <<< "$2"
            check_valid "confirm" "${confirmations[@]}"
            shift 2
            ;;
        --choices)
            IFS='/' read -ra all_options <<< "$2"
            check_valid "choices" "${all_options[@]}"
            shift 2
            ;;
        --symbols) showsymbols=true; shift 1 ;;
        --no-symbols) showsymbols=false; shift 1 ;;
        --) shift; break ;;
        *) echo "Internal error" >&2; exit 1 ;;
    esac
done

# -----------------------------------------------------------------------------
# LOGIC
# -----------------------------------------------------------------------------

# Rofi passes the selected entry as $1
selection="${1:-}"

# 1. INITIAL RUN: Show Main Menu
if [[ -z "$selection" ]]; then
    echo -e "\0prompt\x1fSystem"
    echo -e "\0markup-rows\x1ftrue"

    for entry in "${all_options[@]}"; do
        if [[ "$showsymbols" == "true" ]]; then
             # We use printf to safely generate the null delimiter (\0) and unit separator (\x1f)
             # Format: Text \0 icon \x1f ICON_VAL \x1f info \x1f INFO_VAL
             label="<span font_size='medium'>${icons[$entry]}  ${texts[$entry]}</span>"
             printf "%s\0icon\x1f%s\x1finfo\x1f%s\n" "$label" "${icons[$entry]}" "$entry"
        else
             label="<span font_size='medium'>${texts[$entry]}</span>"
             printf "%s\0info\x1f%s\n" "$label" "$entry"
        fi
    done
    exit 0
fi

# 2. HANDLE SELECTIONS
# If Rofi fails to pass 'info', we strip pango markup as a fallback to prevent crashes
# This removes <tags> and extracts the raw ID if needed, but the printf fix above should prevent this.
clean_selection=$(echo "$selection" | sed 's/<[^>]*>//g')

# Split selection by ':' to handle confirmed states
IFS=':' read -r key state <<< "$selection:"

# If the fix worked, $key is "shutdown". If not, it might be the text. 
# We can try to map it if it looks like an error.
if [[ -z "${actions[$key]+x}" ]]; then
    # Fallback: try to find key by matching text (in case info passing fails completely)
    found=false
    for k in "${!texts[@]}"; do
        if [[ "$clean_selection" == *"${texts[$k]}"* ]]; then
            key="$k"
            found=true
            break
        fi
    done
    
    if [[ "$found" == "false" && "$key" != "cancel" ]]; then
        echo "Error: Unknown action '$key'" >&2
        exit 1
    fi
fi

if [[ "$key" == "cancel" ]]; then
    exit 0
fi

# 3. CHECK CONFIRMATION
need_confirm=false
for item in "${confirmations[@]}"; do
    if [[ "$item" == "$key" ]]; then
        need_confirm=true
        break
    fi
done

# 4. SHOW CONFIRMATION MENU
if [[ "$need_confirm" == "true" && "$state" != "confirmed" ]]; then
    echo -e "\0prompt\x1fAre you sure?"
    echo -e "\0markup-rows\x1ftrue"
    
    # YES Option
    label_yes="<span font_size='medium' color='red'>Yes, ${texts[$key]}</span>"
    printf "%s  %s\0icon\x1f%s\x1finfo\x1f%s:confirmed\n" "${icons[$key]}" "$label_yes" "${icons[$key]}" "$key"
    
    # NO Option
    label_no="<span font_size='medium'>No, cancel</span>"
    printf "%s  %s\0icon\x1f%s\x1finfo\x1fcancel\n" "${icons[cancel]}" "$label_no" "${icons[cancel]}"
    
    exit 0
fi

# 5. EXECUTE
cmd="${actions[$key]}"

if [[ "$dryrun" == "true" ]]; then
    echo "Selected action: $key" >&2
    echo "Command: $cmd" >&2
else
    eval "$cmd"
fi

exit 0
