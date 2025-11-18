#!/usr/bin/env bash

# This script defines just a mode for rofi instead of being a self-contained
# executable that launches rofi by itself. This makes it more flexible than
# running rofi inside this script as now the user can call rofi as one pleases.
# For instance:
#
#   rofi -show powermenu -modi powermenu:./rofi-power-menu
#
# See README.md for more information.

set -e
set -u

# All supported choices
all=(shutdown suspend reboot soft_reboot logout lock)

# By default, show all (i.e., just copy the array)
show=("${all[@]}")

declare -A texts
texts[shutdown]="Shutdown"
texts[suspend]="Suspend"
texts[reboot]="Reboot"
texts[soft_reboot]="Soft Reboot"
texts[logout]="Logout"
texts[lock]="Lock"

declare -A icons
icons[shutdown]="\Uf0425"
icons[reboot]="\Uf0709"
icons[suspend]="\Uf04b2"
icons[soft_reboot]="\Uf0709"
icons[logout]="\Uf0343"
icons[lock]="\Uf033e"
icons[cancel]="\Uf0156"

declare -A actions
actions[shutdown]="systemctl poweroff"
actions[suspend]="systemctl suspend"
actions[reboot]="systemctl reboot"
actions[soft_reboot]="systemctl soft-reboot"
actions[logout]="loginctl terminate-session $XDG_SESSION_ID"
actions[lock]="hyprlock -q"

# By default, ask for confirmation for actions that are irreversible
confirmations=(reboot soft_reboot shutdown logout)

# By default, no dry run
dryrun=false
showsymbols=true
showtext=true

function check_valid {
    option="$1"
    shift 1
    for entry in "${@}"
    do
        if [ -z "${actions[$entry]+x}" ]
        then
            echo "Invalid choice in $1: $entry" >&2
            exit 1
        fi
    done
}

# Parse command-line options
parsed=$(getopt --options=h --longoptions=help,dry-run,confirm:,choices:,choose:,symbols,no-symbols,text,no-text,symbols-font: --name "$0" -- "$@")
if [ $? -ne 0 ]; then
    echo 'Terminating...' >&2
    exit 1
fi
eval set -- "$parsed"
unset parsed
while true; do
    case "$1" in
        "-h"|"--help")
            echo "rofi-power-menu - a power menu mode for Rofi"
            echo
            echo "Usage: rofi-power-menu [--choices CHOICES] [--confirm CHOICES]"
            echo "                       [--choose CHOICE] [--dry-run] [--symbols|--no-symbols]"
            echo
            echo "Use with Rofi in script mode. For instance, to ask for shutdown or reboot:"
            echo
            echo "  rofi -show menu -modi \"menu:rofi-power-menu --choices=shutdown/reboot\""
            echo
            echo "Available options:"
            echo "  --dry-run            Don't perform the selected action but print it to stderr."
            echo "  --choices CHOICES    Show only the selected choices in the given order. Use /"
            echo "                       as the separator. Available choices are lock, logout,"
            echo "                       suspend, soft_reboot, reboot and shutdown. By"
            echo "                       default, all available choices are shown."
            echo "  --confirm CHOICES    Require confirmation for the gives choices only. Use / as"
            echo "                       the separator. Available choices are lock, logout,"
            echo "                       suspend, soft_reboot, reboot and shutdown. By default, only"
            echo "                       irreversible actions logout, soft_reboot, reboot and shutdown require"
            echo "                       confirmation."
            echo "  --choose CHOICE      Preselect the given choice and only ask for a"
            echo "                       confirmation (if confirmation is set to be requested). It"
            echo "                       is strongly recommended to combine this option with"
            echo "                       --confirm=CHOICE if the choice wouldn't require"
            echo "                       confirmation by default. Available choices are"
            echo "                       lock, logout, suspend, soft_reboot, reboot and"
            echo "                       shutdown."
            echo "  --[no-]symbols       Show Unicode symbols or not. Requires a font with support"
            echo "                       for the symbols. Use, for instance, fonts from the"
            echo "                       Nerdfonts collection. By default, they are shown"
            echo "  --[no-]text          Show text description or not."
            echo "  --symbols-font FONT  Use the given font for symbols. By default, the symbols"
            echo "                       use the same font as the text. That font is configured"
            echo "                       with rofi."
            echo "  -h,--help            Show this help text."
            exit 0
            ;;
        "--dry-run")
            dryrun=true
            shift 1
            ;;
        "--confirm")
            IFS='/' read -ra confirmations <<< "$2"
            check_valid "$1" "${confirmations[@]}"
            shift 2
            ;;
        "--choices")
            IFS='/' read -ra show <<< "$2"
            check_valid "$1" "${show[@]}"
            shift 2
            ;;
        "--choose")
            # Check that the choice is valid
            check_valid "$1" "$2"
            selectionID="$2"
            shift 2
            ;;
        "--symbols")
            showsymbols=true
            shift 1
            ;;
        "--no-symbols")
            showsymbols=false
            shift 1
            ;;
        "--text")
            showtext=true
            shift 1
            ;;
        "--no-text")
            showtext=false
            shift 1
            ;;
        "--symbols-font")
            symbols_font="$2"
            shift 2
            ;;
        "--")
            shift
            break
            ;;
        *)
            echo "Internal error" >&2
            exit 1
            ;;
    esac
done

if [ "$showsymbols" = "false" -a "$showtext" = "false" ]
then
    echo "Invalid options: cannot have --no-symbols and --no-text enabled at the same time." >&2
    exit 1
fi

# Define the messages after parsing the CLI options so that it is possible to
# configure them in the future.

function write_message {
    if [ -z ${symbols_font+x} ];
    then
        icon="<span font_size=\"medium\">$1</span>"
    else
        icon="<span font=\"${symbols_font}\" font_size=\"medium\">$1</span>"
    fi
    text="<span font_size=\"medium\">$2</span>"
    if [ "$showsymbols" = "true" ]
    then
        if [ "$showtext" = "true" ]
        then
            echo -n "\u200e$icon \u2068$text\u2069"
        else
            echo -n "\u200e$icon"
        fi
    else
        echo -n "$text"
    fi
}

function print_selection {
    echo -e "$1" | $(read -r -d '' entry; echo "echo $entry")
}

declare -A messages
declare -A confirmationMessages
for entry in "${all[@]}"
do
    messages[$entry]=$(write_message "${icons[$entry]}" "${texts[$entry]^}")
done
for entry in "${all[@]}"
do
    # Add zero-width space character (\u200b) to icon to ensure confirmation-
    # and regular messages never collide.
    confirmationMessages[$entry]=$(write_message "${icons[$entry]}\u200b" "Yes, ${texts[$entry]}")
done
confirmationMessages[cancel]=$(write_message "${icons[cancel]}" "No, cancel")

if [ $# -gt 0 ]
then
    # If arguments given, use those as the selection
    selection="${@}"
else
    # Otherwise, use the CLI passed choice if given
    if [ -n "${selectionID+x}" ]
    then
        selection="${messages[$selectionID]}"
    fi
fi

# Don't allow custom entries
echo -e "\0no-custom\x1ftrue"
# Use markup
echo -e "\0markup-rows\x1ftrue"

if [ -z "${selection+x}" ]
then
    echo -e "\0prompt\x1fPower menu"
    for entry in "${show[@]}"
    do
        echo -e "${messages[$entry]}\0icon\x1f${icons[$entry]}"
    done
else
    for entry in "${show[@]}"
    do
        if [ "$selection" = "$(print_selection "${messages[$entry]}")" ]
        then
            # Check if the selected entry is listed in confirmation requirements
            for confirmation in "${confirmations[@]}"
            do
                if [ "$entry" = "$confirmation" ]
                then
                    # Ask for confirmation
                    echo -e "\0prompt\x1fAre you sure"
                    echo -e "${confirmationMessages[$entry]}\0icon\x1f${icons[$entry]}"
                    echo -e "${confirmationMessages[cancel]}\0icon\x1f${icons[cancel]}"
                    exit 0
                fi
            done
            # If not, then no confirmation is required, so mark confirmed
            selection=$(print_selection "${confirmationMessages[$entry]}")
        fi
        if [ "$selection" = "$(print_selection "${confirmationMessages[$entry]}")" ]
        then
            if [ $dryrun = true ]
            then
                # Tell what would have been done
                echo "Selected: $entry" >&2
            else
                # Perform the action
                ${actions[$entry]}
            fi
            exit 0
        fi
        if [ "$selection" = "$(print_selection "${confirmationMessages[cancel]}")" ]
        then
            # Do nothing
            exit 0
        fi
    done
    # The selection didn't match anything, so raise an error
    echo "Invalid selection: $selection" >&2
    exit 1
fi
