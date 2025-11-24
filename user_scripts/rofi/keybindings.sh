#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
# The Rofi command.
# Removed '-markup-rows' so rofi uses its own theme for text colors.
MENU_COMMAND="rofi -dmenu -i -p 'Hyprland Keybinds' -theme-str 'window {width: 70%;}'"

# --- DEPENDENCY CHECK ---
for cmd in hyprctl jq awk xkbcli sed; do
    if ! command -v "$cmd" &> /dev/null; then
        notify-send "Keybind Error" "Missing dependency: $cmd"
        exit 1
    fi
done

# --- SETUP & CLEANUP ---
# Use mktemp for security and collision avoidance.
# The 'trap' command ensures this file is deleted when the script exits or crashes.
KEYMAP_CACHE=$(mktemp)
trap 'rm -f "$KEYMAP_CACHE"' EXIT

# --- LOGIC ---

get_keymap() {
    # Extract keycodes and symbols from the active XKB keymap
    xkbcli compile-keymap | awk '
    BEGIN { in_codes=0; in_syms=0 }
    /xkb_keycodes/ { in_codes=1; in_syms=0; next }
    /xkb_symbols/  { in_codes=0; in_syms=1; next }
    
    in_codes && /<.*>=/ {
        sub(/<|>/, "", $1); gsub(/;/, "", $3);
        code_map[$1] = $3
    }
    
    in_syms && /key <.*>/ {
        split($0, parts, "<"); split(parts[2], name_parts, ">"); key_name = name_parts[1];
        if (match($0, /\[.*\]/)) {
            content = substr($0, RSTART+1, RLENGTH-2);
            split(content, syms, ",");
            gsub(/ /, "", syms[1]);
            if (code_map[key_name] != "") {
                print code_map[key_name] "\t" syms[1]
            }
        }
    }'
}

get_binds() {
    hyprctl -j binds | jq -r '
    .[] | select(.key != "") |
    (.modmask | tonumber) as $m |
    [
        if ($m % 2 >= 1) then "SHIFT" else empty end,
        if ($m % 8 >= 4) then "CTRL" else empty end,
        if ($m % 16 >= 8) then "ALT" else empty end,
        if ($m % 128 >= 64) then "SUPER" else empty end
    ] as $mods |
    [
        (.submap // ""), ($mods | join(" ")), .key, .keycode, .description, .dispatcher, .arg
    ] | join("\t")'
}

# --- EXECUTION ---

# 1. Prepare the Data
get_keymap > "$KEYMAP_CACHE"

DATA=$(get_binds | awk -F'\t' -v cache="$KEYMAP_CACHE" '
    BEGIN { 
        while ((getline < cache) > 0) {
            key_lookup[$1] = $2
        }
        close(cache)
    }

    {
        submap = $1; mods = $2; key = $3; keycode = $4; desc = $5; dispatcher = $6; arg = $7

        # Resolve Keycodes to Symbols if possible
        if (key == "" || key ~ /^mouse:/) {
        } else if (keycode > 0 && key_lookup[keycode] != "") {
             key = key_lookup[keycode]
        }
        key = toupper(key)

        # Format Description/Action
        action = desc
        if (action == "") {
            if (arg != "") { action = dispatcher " (" arg ")" } 
            else { action = dispatcher }
        }

        # Submap Indicator (Plain text)
        submap_str = ""
        if (submap != "" && submap != "global") {
            submap_str = "[" toupper(submap) "] "
        }

        # Formatting
        gsub(/  +/, " ", mods)
        display_key = (mods == "" ? "" : mods " + ") key
        
        # Format: DISPLAY_STRING #### DISPATCHER #### ARG
        # Removed <b>, <span>, and foreground colors.
        printf "%-35s   %s%s####%s####%s\n", display_key, submap_str, action, dispatcher, arg
    }
' | sort -u)

if [[ -z "$DATA" ]]; then
    exit 0
fi

# 2. Select with Rofi
# We use -format i to get the index (0-based)
SELECTED_INDEX=$(echo "$DATA" | awk -F '####' '{print $1}' | eval "$MENU_COMMAND -format i" || true)

if [[ -z "$SELECTED_INDEX" ]]; then
    exit 0
fi

# 3. Retrieve and Execute
# Convert 0-based index to 1-based line number
LINE_NUM=$((SELECTED_INDEX + 1))
SELECTED_LINE=$(echo "$DATA" | sed -n "${LINE_NUM}p")

# Parse hidden data
TEMP="${SELECTED_LINE#*####}"
DISPATCHER="${TEMP%%####*}"
ARG="${TEMP#*####}"

# Dispatch
if [[ -n "$ARG" ]]; then
    hyprctl dispatch "$DISPATCHER" "$ARG"
else
    hyprctl dispatch "$DISPATCHER"
fi
