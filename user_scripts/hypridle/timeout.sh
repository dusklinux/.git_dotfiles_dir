#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
CONFIG_FILE="$HOME/.config/hypr/hypridle.conf"

# Unique strings to identify which listener block is which
# We look for these specific commands inside the blocks
SIG_DIM="brightnessctl -s set 1"
SIG_LOCK="loginctl lock-session"
SIG_OFF="dispatch dpms off"
SIG_SUSPEND="systemctl suspend"

# Colors for Gum
C_TEXT="212"    # Pink
C_ACCENT="99"   # Purple
C_WARN="208"    # Orange
C_ERR="196"     # Red

# ==============================================================================
# SETUP & CLEANUP
# ==============================================================================

# Ensure temporary files are deleted on exit or interrupt (Cleanliness)
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Check for Gum on Arch
if ! command -v gum &> /dev/null; then
    echo "Error: 'gum' is required."
    read -p "Install it now via pacman? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo pacman -S gum
    else
        exit 1
    fi
fi

# ==============================================================================
# FUNCTIONS
# ==============================================================================

get_timeout() {
    local signature="$1"
    # awk: parses file paragraph-style or line-buffer style to find the timeout associated with the command signature
    awk -v sig="$signature" '
    BEGIN { in_block=0; block="" }
    /listener/ { in_block=1; block="" }
    in_block { block = block $0 "\n" }
    /}/ { 
        in_block=0; 
        if (block ~ sig) {
            match(block, /timeout = [0-9]+/);
            val = substr(block, RSTART, RLENGTH);
            split(val, arr, " ");
            print arr[3];
            exit;
        }
    }
    ' "$CONFIG_FILE"
}

update_file() {
    local signature="$1"
    local new_val="$2"
    
    # awk: Rewrite the file into the temp file
    awk -v sig="$signature" -v nv="$new_val" '
    BEGIN { in_block=0 }
    /listener/ { in_block=1; buffer=$0; next }
    
    in_block {
        buffer = buffer "\n" $0
        if ($0 ~ /}/) {
            in_block=0
            if (buffer ~ sig) {
                sub(/timeout = [0-9]+/, "timeout = " nv, buffer)
            }
            print buffer
            buffer=""
        }
        next
    }
    
    { print }
    ' "$CONFIG_FILE" > "$TEMP_FILE"
    
    # Overwrite original
    cat "$TEMP_FILE" > "$CONFIG_FILE"
}

# ==============================================================================
# MAIN LOGIC
# ==============================================================================

# 1. Check Config Exists
if [ ! -f "$CONFIG_FILE" ]; then
    gum style --foreground "$C_ERR" "Error: $CONFIG_FILE not found."
    exit 1
fi

# 2. Load Current State
gum style --border normal --margin "1" --padding "1 2" --border-foreground "$C_TEXT" \
    "$(gum style --foreground "$C_TEXT" --bold "HYPRIDLE") $(gum style --foreground "$C_ACCENT" "ARCH CONTROLLER")"

# Load values (defaulting to safe nums if parsing fails)
CUR_DIM=$(get_timeout "$SIG_DIM"); CUR_DIM=${CUR_DIM:-150}
CUR_LOCK=$(get_timeout "$SIG_LOCK"); CUR_LOCK=${CUR_LOCK:-300}
CUR_OFF=$(get_timeout "$SIG_OFF"); CUR_OFF=${CUR_OFF:-310}
CUR_SUSPEND=$(get_timeout "$SIG_SUSPEND"); CUR_SUSPEND=${CUR_SUSPEND:-500}

NEW_DIM=$CUR_DIM
NEW_LOCK=$CUR_LOCK
NEW_OFF=$CUR_OFF
NEW_SUSPEND=$CUR_SUSPEND

# 3. Interactive Loop
while true; do
    clear
    gum style --border normal --margin "1" --padding "1 2" --border-foreground "$C_TEXT" \
    "$(gum style --foreground "$C_TEXT" --bold "HYPRIDLE") $(gum style --foreground "$C_ACCENT" "ARCH CONTROLLER")"

    CHOICE=$(gum choose --cursor.foreground="$C_TEXT" --header "Select value to edit (ESC to exit)" \
        "1. Dim Screen     [${NEW_DIM}s]" \
        "2. Lock Session   [${NEW_LOCK}s]" \
        "3. Screen Off     [${NEW_OFF}s]" \
        "4. System Suspend [${NEW_SUSPEND}s]" \
        " " \
        "Apply & Restart" \
        "Exit")

    case "$CHOICE" in
        *"Dim Screen"*)
            NEW_DIM=$(gum input --placeholder "$NEW_DIM" --value "$NEW_DIM" --header "Seconds until screen dims:") ;;
        *"Lock Session"*)
            NEW_LOCK=$(gum input --placeholder "$NEW_LOCK" --value "$NEW_LOCK" --header "Seconds until lock:") ;;
        *"Screen Off"*)
            NEW_OFF=$(gum input --placeholder "$NEW_OFF" --value "$NEW_OFF" --header "Seconds until screen off:") ;;
        *"System Suspend"*)
            NEW_SUSPEND=$(gum input --placeholder "$NEW_SUSPEND" --value "$NEW_SUSPEND" --header "Seconds until suspend:") ;;
        "Apply & Restart")
            break ;;
        "Exit")
            exit 0 ;;
    esac
done

# 4. Logic Validation
# Ensure the timeline makes sense (Dim -> Lock -> Off -> Suspend)
WARNINGS=""
if (( NEW_DIM >= NEW_LOCK )); then WARNINGS+="[!] Dim ($NEW_DIM) >= Lock ($NEW_LOCK)\n"; fi
if (( NEW_LOCK >= NEW_OFF )); then WARNINGS+="[!] Lock ($NEW_LOCK) >= Screen Off ($NEW_OFF)\n"; fi
if (( NEW_OFF >= NEW_SUSPEND )); then WARNINGS+="[!] Screen Off ($NEW_OFF) >= Suspend ($NEW_SUSPEND)\n"; fi

if [ -n "$WARNINGS" ]; then
    gum style --border double --border-foreground "$C_WARN" --padding "1" \
        "$(gum style --foreground "$C_WARN" "LOGIC WARNING")" \
        "Your timeline seems out of order:" \
        "$(echo -e "$WARNINGS")" \
        "Typically: Dim < Lock < Off < Suspend"
    
    if ! gum confirm "Apply anyway?"; then
        exit 0
    fi
fi

# 5. Apply Changes
echo ""
# Only update if changed to be efficient
if [ "$NEW_DIM" != "$CUR_DIM" ]; then
    gum spin --spinner dot --title "Setting Dim to ${NEW_DIM}s..." -- sleep 0.5
    update_file "$SIG_DIM" "$NEW_DIM"
fi
if [ "$NEW_LOCK" != "$CUR_LOCK" ]; then
    gum spin --spinner dot --title "Setting Lock to ${NEW_LOCK}s..." -- sleep 0.5
    update_file "$SIG_LOCK" "$NEW_LOCK"
fi
if [ "$NEW_OFF" != "$CUR_OFF" ]; then
    gum spin --spinner dot --title "Setting Screen Off to ${NEW_OFF}s..." -- sleep 0.5
    update_file "$SIG_OFF" "$NEW_OFF"
fi
if [ "$NEW_SUSPEND" != "$CUR_SUSPEND" ]; then
    gum spin --spinner dot --title "Setting Suspend to ${NEW_SUSPEND}s..." -- sleep 0.5
    update_file "$SIG_SUSPEND" "$NEW_SUSPEND"
fi

# 6. Restart Service
if systemctl --user is-active --quiet hypridle; then
    gum spin --spinner monkey --title "Restarting hypridle..." -- systemctl --user restart hypridle
    gum style --foreground "35" "Done. Hypridle restarted successfully."
else
    gum style --foreground "$C_WARN" "Hypridle was not running."
    if gum confirm "Start hypridle now?"; then
        gum spin --spinner monkey --title "Starting hypridle..." -- systemctl --user start hypridle
        gum style --foreground "35" "Done. Hypridle started."
    fi
fi
