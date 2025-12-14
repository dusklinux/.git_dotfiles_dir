#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Rofi Command
# -theme-str 'window {width: 70%;}' forces the window to be wider
declare -a MENU_COMMAND=(
    rofi -dmenu -i
    -markup-rows
    -p 'Keybinds'
    -theme-str 'window {width: 70%;}'
    -theme-str 'listview {fixed-height: true;}'
)

# ASCII Unit Separator (Hidden delimiter)
readonly DELIM=$'\x1f'

# ==============================================================================
# DEPENDENCIES
# ==============================================================================

declare -a missing_deps=()
for cmd in hyprctl jq gawk xkbcli sed rofi; do
    command -v "$cmd" >/dev/null 2>&1 || missing_deps+=("$cmd")
done

if (( ${#missing_deps[@]} > 0 )); then
    notify-send -u critical "Keybind Error" "Missing: ${missing_deps[*]}" 2>/dev/null || \
    printf 'Error: Missing dependencies: %s\n' "${missing_deps[*]}" >&2
    exit 1
fi

# ==============================================================================
# LOGIC
# ==============================================================================

KEYMAP_CACHE=$(mktemp) || exit 1
trap 'rm -f -- "$KEYMAP_CACHE"' EXIT INT TERM HUP

get_keymap() {
    xkbcli compile-keymap 2>/dev/null | awk '
    BEGIN { in_codes=0; in_syms=0 }
    /xkb_keycodes/ { in_codes=1; in_syms=0; next }
    /xkb_symbols/  { in_codes=0; in_syms=1; next }
    /^};/          { in_codes=0; in_syms=0; next }
    in_codes && /<[A-Z0-9]+>[[:space:]]*=[[:space:]]*[0-9]+/ {
        gsub(/[<>;]/,"",$0); split($0,p,/[[:space:]]*=[[:space:]]*/)
        if(p[2]~/^[0-9]+$/) c[p[1]]=p[2]
    }
    in_syms && /key[[:space:]]+<[A-Z0-9]+>/ {
        if(match($0,/<[A-Z0-9]+>/)) k=substr($0,RSTART+1,RLENGTH-2)
        if(match($0,/\[[^\]]+\]/)) {
            split(substr($0,RSTART+1,RLENGTH-2),s,",")
            gsub(/^[[:space:]]+|[[:space:]]+$/,"",s[1])
            if((k in c) && s[1]!="") print c[k]"\t"s[1]
        }
    }'
}

get_binds() {
    hyprctl -j binds 2>/dev/null | jq -r --arg d "$1" '
        .[] | select(.key != null and .key != "") |
        ((.modmask//0)|tonumber) as $m |
        [
            (if ($m%2)>=1 then "SHIFT" else empty end),
            (if ($m%8)>=4 then "CTRL" else empty end),
            (if ($m%16)>=8 then "ALT" else empty end),
            (if ($m%128)>=64 then "SUPER" else empty end)
        ] as $mods |
        [ (.submap//""), ($mods|join(" ")), .key, ((.keycode//0)|tostring),
          (.description//""), (.dispatcher//""), (.arg//"") ] | join($d)
    '
}

# 1. Build Cache
get_keymap > "$KEYMAP_CACHE"

# 2. Process Data
DATA=$(get_binds "$DELIM" | awk -F"$DELIM" -v delim="$DELIM" -v cache="$KEYMAP_CACHE" '
BEGIN {
    while((getline < cache) > 0) { split($0,p,"\t"); if(p[1]!="") map[p[1]]=p[2] }
    close(cache)
}
function esc(s) { gsub(/&/,"&amp;",s); gsub(/</,"&lt;",s); gsub(/>/,"&gt;",s); return s }

{
    submap=$1; mods=$2; key=$3; code=int($4); desc=$5; disp=$6; arg=$7
    if(disp == "") next

    # Resolve Key Symbol
    if(key !~ /^mouse:/ && code > 0 && (code in map)) key=map[code]
    key = toupper(key)

    # Clean Mods
    gsub(/[[:space:]]+/, " ", mods); sub(/^[[:space:]]+/, "", mods); sub(/[[:space:]]+$/, "", mods)

    # --- Icons ---
    icon=" "
    if(disp ~ /exec/)        icon=" "
    else if(disp ~ /kill/)   icon=" "
    else if(disp ~ /resize/) icon="󰩨 "
    else if(disp ~ /move/)   icon="󰆾 "
    else if(disp ~ /float/)  icon=" "
    else if(disp ~ /full/)   icon=" "
    else if(disp ~ /work/)   icon=" "
    else if(disp ~ /pass/)   icon=" " 

    # --- Formatting ---
    
    # ADJUSTED: Reduced Mod width to 7 (was 10) and Key width to 10 (was 12).
    # This brings ALT and the Key closer, and pulls the description in.
    if (mods != "") {
        display_key = sprintf("<span alpha=\"65%%\">%-7s</span> <span weight=\"bold\">%-10s</span>", mods, key)
    } else {
        display_key = sprintf("<span alpha=\"65%%\">%-7s</span> <span weight=\"bold\">%-10s</span>", "", key)
    }

    # 2. Action: Escape HTML chars
    if (desc != "") action = esc(desc)
    else if (arg != "") action = sprintf("%s <span alpha=\"50%%\" style=\"italic\">(%s)</span>", esc(disp), esc(arg))
    else action = esc(disp)

    # 3. Submap Prefix
    if (submap != "" && submap != "global") {
        action = sprintf("<span weight=\"bold\" foreground=\"#f38ba8\">[%s]</span> %s", toupper(submap), action)
    }

    # Output
    printf "%s  %s  %s%s%s%s%s\n", icon, display_key, action, delim, disp, delim, arg
}
' | sort -t"$DELIM" -k1,1 -u)

[[ -z "${DATA:-}" ]] && exit 0

# 3. Show Menu
SELECTED_INDEX=$(awk -F"$DELIM" '{print $1}' <<< "$DATA" | "${MENU_COMMAND[@]}" -format i)

if [[ "$SELECTED_INDEX" =~ ^[0-9]+$ ]]; then
    LINE_NUM=$((SELECTED_INDEX + 1))
    SELECTED_LINE=$(sed -n "${LINE_NUM}p" <<< "$DATA")
    IFS="$DELIM" read -r _ disp arg <<< "$SELECTED_LINE"
    
    # Execute
    if [[ -n "$arg" ]]; then
        exec hyprctl dispatch "$disp" "$arg"
    else
        exec hyprctl dispatch "$disp"
    fi
fi
