#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
# The Rofi command. We enable markup for nicer formatting.
# -markup-rows: Allows us to use <b>bold</b> or <span foreground='color'> tags.
MENU_COMMAND="rofi -dmenu -i -markup-rows -p 'Hyprland Keybinds' -theme-str 'window {width: 70%;}'"

# --- DEPENDENCY CHECK ---
for cmd in hyprctl jq awk xkbcli; do
    if ! command -v "$cmd" &> /dev/null; then
        notify-send "Keybind Error" "Missing dependency: $cmd"
        exit 1
    fi
done

# --- LOGIC ---

# 1. Get the Keymap
# We dump the current keymap and format it as "KEYCODE:SYMBOL" for Awk to read later.
get_keymap() {
    xkbcli compile-keymap | awk '
    BEGIN { in_codes=0; in_syms=0 }
    /xkb_keycodes/ { in_codes=1; in_syms=0; next }
    /xkb_symbols/  { in_codes=0; in_syms=1; next }
    
    # Capture Keycodes: <AD01> = 24;
    in_codes && /<.*>=/ {
        sub(/<|>/, "", $1); # Remove brackets
        gsub(/;/, "", $3);  # Remove semicolon
        code_map[$1] = $3
    }
    
    # Capture Symbols: key <AD01> { [ q, Q ] };
    # We extract the first symbol in the bracket.
    in_syms && /key <.*>/ {
        split($0, parts, "<"); split(parts[2], name_parts, ">"); key_name = name_parts[1];
        
        # Extract content inside [ ... ]
        if (match($0, /\[.*\]/)) {
            content = substr($0, RSTART+1, RLENGTH-2);
            split(content, syms, ",");
            gsub(/ /, "", syms[1]); # Clean whitespace
            
            # Map the code to the symbol
            if (code_map[key_name] != "") {
                print code_map[key_name] "\t" syms[1]
            }
        }
    }'
}

# 2. Get Hyprland Bindings
# We use JQ to do the heavy lifting of Bitwise math for modifiers.
# This ensures perfect accuracy regardless of the integer value.
# Mod Masks: Shift(1), Caps(2), Ctrl(4), Alt(8), Mod2(16), Mod3(32), Super(64), Mod5(128)
get_binds() {
    hyprctl -j binds | jq -r '
    .[] | select(.key != "") |
    
    # Logic to decode modmask integers into string arrays
    (.modmask | tonumber) as $m |
    [
        if ($m % 2 >= 1) then "SHIFT" else empty end,
        if ($m % 8 >= 4) then "CTRL" else empty end,
        if ($m % 16 >= 8) then "ALT" else empty end,
        if ($m % 128 >= 64) then "SUPER" else empty end
    ] as $mods |
    
    # Format: SUBMAP \t MODS \t KEY \t KEYCODE \t DESCRIPTION \t DISPATCHER \t ARG
    [
        (.submap // ""),
        ($mods | join(" ")),
        .key,
        .keycode,
        .description,
        .dispatcher,
        .arg
    ] | join("\t")'
}

# 3. The Pipeline
# We process two input streams in one Awk command:
# Stream 1: The keymap definitions (from get_keymap)
# Stream 2: The active bindings (from get_binds)
get_keymap > /tmp/hypr_keymap_cache
get_binds | awk -F'\t' '
    BEGIN { 
        # Load the keymap cache into an associative array
        while ((getline < "/tmp/hypr_keymap_cache") > 0) {
            key_lookup[$1] = $2
        }
        close("/tmp/hypr_keymap_cache")
    }

    {
        submap = $1
        mods = $2
        key = $3
        keycode = $4
        desc = $5
        dispatcher = $6
        arg = $7

        # If the key is a raw code (mouse or unmapped), look it up or format it
        if (key == "" || key ~ /^mouse:/) {
             # Keep as is (e.g., mouse:272)
        } else if (keycode > 0 && key_lookup[keycode] != "") {
             # Replace with mapped symbol (e.g., "q" instead of code 24)
             key = key_lookup[keycode]
        }

        # Capitalize the key for display
        key = toupper(key)

        # Format the action text
        action = desc
        if (action == "") {
            if (arg != "") {
                action = dispatcher " (" arg ")"
            } else {
                action = dispatcher
            }
        }

        # Submap Label (only show if not default)
        submap_str = ""
        if (submap != "" && submap != "global") {
            submap_str = "[" toupper(submap) "] "
        }

        # Icon logic (Optional: add icons if you want)
        # type = " "

        # Visual Formatting with Pango Markup
        # Columns: <Submap> <Mods + Key>    -->   <Action>
        
        # Clean up double spaces in mods
        gsub(/  +/, " ", mods)
        
        # Prepare Display Strings
        display_key = (mods == "" ? "" : mods " + ") key
        
        # Use printf for alignment. 
        # %-25s means padding to 25 chars.
        # We use <b> tags for the keys to make them pop.
        printf "<b>%-30s</b>   <span foreground=\"#a6adc8\">%s%s</span>\n", display_key, submap_str, action
    }
' | sort -u | eval "$MENU_COMMAND"
