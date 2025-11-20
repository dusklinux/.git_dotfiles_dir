#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# CONFIGURATION & ASSETS
# -----------------------------------------------------------------------------
set -u
# We intentionally remove pipefail to allow background disowning without grief
set +o pipefail

# Icons
declare -A icons=( [active]="" [inactive]="" [off]="" [shader]="" )

# Rofi Command
# -mesg: Adds a persistent message
rofi_cmd=(
    rofi -dmenu -i -markup-rows
    -theme-str "window {location: center; anchor: center; fullscreen: false; width: 400px;}"
    -mesg "<span size='x-small' color='#6c7086'>Use <b>Up/Down</b> to preview. <b>Enter</b> to apply. <b>Esc</b> to cancel.</span>"
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
    # A. Build Menu String
    menu_content=""
    for item in "${shaders[@]}"; do
        if [[ "$item" == "$virtual_current" ]]; then
            # Active Item
            if [[ "$item" == "off" ]]; then
                 line="<span weight='bold' color='#f38ba8'>${icons[off]}  Turn Off (Active)</span>"
            else
                 line="<span weight='bold' color='#a6e3a1'>${icons[active]}  ${item} (Active)</span>"
            fi
        else
            # Inactive Item
             if [[ "$item" == "off" ]]; then
                 line="${icons[inactive]}  Turn Off"
            else
                 line="${icons[shader]}  ${item}"
            fi
        fi
        menu_content+="${line}\n"
    done

    # B. Prepare Rofi Flags
    # We define dynamic flags based on whether a search is active.
    # We MUST use -format 's|f' to capture both the selection (s) and the current filter/search (f).
    rofi_flags=(-p "Shader Preview" -format "s|f")

    if [[ -n "$search_query" ]]; then
        # --- SEARCH MODE ---
        # If there is a query, we restore it using -filter.
        # We DO NOT use custom keybindings for Up/Down here. This allows standard Rofi navigation
        # (scrolling the list) without closing Rofi, ensuring the search doesn't reset.
        # Note: Live preview is effectively paused while searching to allow navigation.
        rofi_flags+=(-filter "$search_query")
    else
        # --- PREVIEW MODE ---
        # Standard behavior: Custom keys trigger exit (code 10/11) to reload the wallpaper.
        rofi_flags+=(-selected-row "$current_idx")
        rofi_flags+=(-kb-custom-1 "Down" -kb-custom-2 "Up" -kb-row-down "" -kb-row-up "")
    fi

    # C. Render Rofi
    raw_output=$(echo -e "$menu_content" | "${rofi_cmd[@]}" "${rofi_flags[@]}")
    exit_code=$?

    # D. Parse Output (Split Selection | Filter)
    # Rofi returns "Selection Text|User Query" due to our -format flag.
    if [[ "$raw_output" == *"|"* ]]; then
        selection="${raw_output%|*}"    # Take everything before the last pipe
        returned_query="${raw_output##*|}" # Take everything after the last pipe
    else
        selection="$raw_output"
        returned_query=""
    fi

    # E. Handle Navigation
    if [[ $exit_code -eq 10 ]]; then
        # --- DOWN ARROW (Preview Mode) ---
        # If user typed text and hit Down, we switch to Search Mode instead of previewing.
        if [[ -n "$returned_query" ]]; then
            search_query="$returned_query"
            continue
        fi

        ((current_idx++))
        if [[ $current_idx -gt $max_idx ]]; then current_idx=0; fi
        
        target="${shaders[$current_idx]}"
        virtual_current="$target"
        search_query="" # Ensure search is clear

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
        search_query="" # Ensure search is clear

        if [[ "$target" == "off" ]]; then
            hyprshade off >/dev/null 2>&1 &
        else
            hyprshade on "$target" >/dev/null 2>&1 &
        fi

    elif [[ $exit_code -eq 0 ]]; then
        # --- ENTER (CONFIRM SELECTION) ---
        
        # 1. Strip Pango markup tags
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
        # Revert to original state
        if [[ "$ORIGINAL_SHADER" == "off" ]]; then
            hyprshade off
        else
            hyprshade on "$ORIGINAL_SHADER"
        fi
        exit 0
    fi
done
