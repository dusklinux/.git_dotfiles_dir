#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# CONFIGURATION & ASSETS
# -----------------------------------------------------------------------------
set -u
set +o pipefail

# Icons
declare -A icons=( [active]="" [inactive]="" [off]="" [shader]="" )

# Rofi Command
# -mesg: Removed hardcoded color. It will now use your config's text-color.
# -theme-str: Kept width override (400px) for menu shape, but removed other constraints.
rofi_cmd=(
    rofi -dmenu -i -markup-rows
    -theme-str "window {width: 400px;}"
    -mesg "<span size='x-small'>Use <b>Up/Down</b> to preview. <b>Enter</b> to apply. <b>Esc</b> to cancel.</span>"
)

# -----------------------------------------------------------------------------
# INITIALIZATION
# -----------------------------------------------------------------------------

# 1. Capture Original State (for Cancellation)
raw_orig=$(hyprshade current)
ORIGINAL_SHADER="${raw_orig#"${raw_orig%%[![:space:]]*}"}"
ORIGINAL_SHADER="${ORIGINAL_SHADER%"${ORIGINAL_SHADER##*[![:space:]]}"}"
[[ -z "$ORIGINAL_SHADER" ]] && ORIGINAL_SHADER="off"

# 2. Load Shaders into Memory
mapfile -t raw_list < <(hyprshade ls)
declare -a shaders
shaders+=("off") 

for raw in "${raw_list[@]}"; do
    clean="${raw#"${raw%%[![:space:]]*}"}"
    clean="${clean%"${clean##*[![:space:]]}"}"
    [[ -n "$clean" ]] && shaders+=("$clean")
done

# 3. Find Start Index
current_idx=0
for i in "${!shaders[@]}"; do
    if [[ "${shaders[$i]}" == "$ORIGINAL_SHADER" ]]; then
        current_idx=$i
        break
    fi
done

# 4. Pre-calculate list size
max_idx=$((${#shaders[@]} - 1))

# 5. Track "Virtual" Current State
virtual_current="$ORIGINAL_SHADER"
search_query=""

# -----------------------------------------------------------------------------
# THE LOOP
# -----------------------------------------------------------------------------

while true; do
    # A. Build Menu String & Calculate Active Row
    menu_content=""
    active_row_index="" 
    counter=0

    for item in "${shaders[@]}"; do
        # Determine if this is the active item
        if [[ "$item" == "$virtual_current" ]]; then
            active_row_index="$counter"
            # Bold text, but NO hardcoded colors (Rofi handles color via -a flag)
            style_start="<b>"
            style_end=" (Active)</b>"
            current_icon="${icons[active]}"
        else
            style_start=""
            style_end=""
            current_icon="${icons[shader]}"
        fi

        # Handle "off" specific labelling
        if [[ "$item" == "off" ]]; then
            display_name="Turn Off"
            if [[ "$item" != "$virtual_current" ]]; then 
                current_icon="${icons[inactive]}"
            else 
                current_icon="${icons[off]}"
            fi
        else
            display_name="$item"
        fi

        line="${style_start}${current_icon}  ${display_name}${style_end}"
        menu_content+="${line}\n"
        
        ((counter++))
    done

    # B. Prepare Rofi Flags
    # -a "$active_row_index" tells Rofi to style this row using 'element normal.active' from config.rasi
    rofi_flags=(-p "Shader Preview" -format "s|f" -a "$active_row_index")

    if [[ -n "$search_query" ]]; then
        # --- SEARCH MODE ---
        rofi_flags+=(-filter "$search_query")
    else
        # --- PREVIEW MODE ---
        rofi_flags+=(-selected-row "$current_idx")
        rofi_flags+=(-kb-custom-1 "Down" -kb-custom-2 "Up" -kb-row-down "" -kb-row-up "")
    fi

    # C. Render Rofi
    raw_output=$(echo -e "$menu_content" | "${rofi_cmd[@]}" "${rofi_flags[@]}")
    exit_code=$?

    # D. Parse Output (Split Selection | Filter)
    if [[ "$raw_output" == *"|"* ]]; then
        selection="${raw_output%|*}"
        returned_query="${raw_output##*|}"
    else
        selection="$raw_output"
        returned_query=""
    fi

    # E. Handle Navigation
    if [[ $exit_code -eq 10 ]]; then
        # --- DOWN ARROW (Preview Mode) ---
        if [[ -n "$returned_query" ]]; then
            search_query="$returned_query"
            continue
        fi

        ((current_idx++))
        if [[ $current_idx -gt $max_idx ]]; then current_idx=0; fi
        
        target="${shaders[$current_idx]}"
        virtual_current="$target"
        search_query=""

        if [[ "$target" == "off" ]]; then
            hyprshade off >/dev/null 2>&1 &
        else
            hyprshade on "$target" >/dev/null 2>&1 &
        fi

    elif [[ $exit_code -eq 11 ]]; then
        # --- UP ARROW (Preview Mode) ---
        if [[ -n "$returned_query" ]]; then
            search_query="$returned_query"
            continue
        fi

        ((current_idx--))
        if [[ $current_idx -lt 0 ]]; then current_idx=$max_idx; fi
        
        target="${shaders[$current_idx]}"
        virtual_current="$target"
        search_query=""

        if [[ "$target" == "off" ]]; then
            hyprshade off >/dev/null 2>&1 &
        else
            hyprshade on "$target" >/dev/null 2>&1 &
        fi

    elif [[ $exit_code -eq 0 ]]; then
        # --- ENTER (CONFIRM SELECTION) ---
        
        # 1. Strip Pango markup tags (removes <b> etc)
        clean_selection=$(echo "$selection" | sed 's/<[^>]*>//g')

        # 2. Extract the shader name
        target_name=$(echo "$clean_selection" | awk -F"  " '{print $2}' | sed 's/ (Active)//')

        # 3. Handle the special "Turn Off" label
        if [[ "$target_name" == "Turn Off" ]]; then
            target="off"
        else
            target="$target_name"
        fi

        # 4. Validate target
        if [[ -z "$target" ]]; then
            exit 1
        fi

        if [[ "$target" == "off" ]]; then
            hyprshade off
        else
            hyprshade on "$target"
        fi
        
        notify-send "Hyprshade" "Applied: $target" -i video-display
        exit 0

    else
        # --- ESC (CANCEL) ---
        if [[ "$ORIGINAL_SHADER" == "off" ]]; then
            hyprshade off
        else
            hyprshade on "$ORIGINAL_SHADER"
        fi
        exit 0
    fi
done
