#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# CONFIGURATION & ASSETS
# -----------------------------------------------------------------------------
set -u
# We intentionally remove pipefail to allow background disowning without grief
set +o pipefail

# Icons
declare -A icons=( [active]="" [inactive]="" [off]="" [shader]="" )

# Rofi Command (Using Array for Safety)
# -mesg: Adds a persistent message so the window size doesn't jump around
rofi_cmd=(
    rofi -dmenu -i -markup-rows
    -theme-str "window {location: center; anchor: center; fullscreen: false; width: 400px;}"
    -mesg "<span size='x-small' color='#6c7086'>Use <b>Up/Down</b> to preview. <b>Enter</b> to apply. <b>Esc</b> to cancel.</span>"
)

# -----------------------------------------------------------------------------
# INITIALIZATION (Done ONCE to save time)
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

# 5. Track "Virtual" Current State (Memory Cache)
# We use this variable instead of querying 'hyprshade current' repeatedly
virtual_current="$ORIGINAL_SHADER"

# -----------------------------------------------------------------------------
# THE HIGH-SPEED LOOP
# -----------------------------------------------------------------------------

while true; do
    # A. Build Menu String (In-Memory)
    # This is the only heavy lifting inside the loop
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

    # B. Render Rofi
    # We capture the exit code immediately
    selection=$(echo -e "$menu_content" | "${rofi_cmd[@]}" \
        -p "Shader Preview" \
        -selected-row "$current_idx" \
        -kb-custom-1 "Down" \
        -kb-custom-2 "Up" \
        -kb-row-down "" \
        -kb-row-up "")
    
    exit_code=$?

    # C. Handle Navigation (The Critical Path)
    if [[ $exit_code -eq 10 ]]; then
        # --- DOWN ARROW ---
        ((current_idx++))
        if [[ $current_idx -gt $max_idx ]]; then current_idx=0; fi
        
        target="${shaders[$current_idx]}"
        virtual_current="$target"

        # ASYNC APPLY: We run hyprshade in background (&) so Rofi can reopen INSTANTLY.
        # We silence output to prevent buffer lag.
        if [[ "$target" == "off" ]]; then
            hyprshade off >/dev/null 2>&1 &
        else
            hyprshade on "$target" >/dev/null 2>&1 &
        fi

    elif [[ $exit_code -eq 11 ]]; then
        # --- UP ARROW ---
        ((current_idx--))
        if [[ $current_idx -lt 0 ]]; then current_idx=$max_idx; fi
        
        target="${shaders[$current_idx]}"
        virtual_current="$target"

        # ASYNC APPLY
        if [[ "$target" == "off" ]]; then
            hyprshade off >/dev/null 2>&1 &
        else
            hyprshade on "$target" >/dev/null 2>&1 &
        fi

    elif [[ $exit_code -eq 0 ]]; then
        # --- ENTER (CONFIRM) ---
        # Just ensure the final state is enforced synchronously
        target="${shaders[$current_idx]}"
        if [[ "$target" == "off" ]]; then
            hyprshade off
        else
            hyprshade on "$target"
        fi
        notify-send "Hyprshade" "Applied: $target" -i video-display
        exit 0

    else
        # --- ESC (CANCEL) ---
        # Revert to original
        if [[ "$ORIGINAL_SHADER" == "off" ]]; then
            hyprshade off
        else
            hyprshade on "$ORIGINAL_SHADER"
        fi
        exit 0
    fi
done
