#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Rofi command as a proper array (handles spaces/quotes correctly)
declare -a MENU_COMMAND=(
    rofi -dmenu -i
    -p 'Hyprland Keybinds'
    -theme-str 'window {width: 70%;}'
)

# ASCII Unit Separator - safe delimiter that won't appear in normal text
readonly DELIM=$'\x1f'

# ==============================================================================
# DEPENDENCY CHECK
# ==============================================================================

declare -a missing_deps=()
for cmd in hyprctl jq gawk xkbcli sed rofi; do
    command -v "$cmd" >/dev/null 2>&1 || missing_deps+=("$cmd")
done

if (( ${#missing_deps[@]} > 0 )); then
    err_msg="Missing dependencies: ${missing_deps[*]}"
    # Try notify-send, fall back to stderr
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical "Keybind Script Error" "$err_msg"
    fi
    printf 'Error: %s\n' "$err_msg" >&2
    exit 1
fi

# ==============================================================================
# SETUP & CLEANUP
# ==============================================================================

KEYMAP_CACHE=$(mktemp) || { printf 'Failed to create temp file\n' >&2; exit 1; }
trap 'rm -f -- "$KEYMAP_CACHE"' EXIT INT TERM HUP

# ==============================================================================
# FUNCTIONS
# ==============================================================================

get_keymap() {
    # Extract keycode -> symbol mappings from the active XKB keymap
    # Output format: KEYCODE<TAB>SYMBOL
    xkbcli compile-keymap 2>/dev/null | awk '
    BEGIN {
        in_codes = 0
        in_syms  = 0
    }

    /xkb_keycodes[[:space:]]+"/ { in_codes = 1; in_syms = 0; next }
    /xkb_symbols[[:space:]]+"/  { in_codes = 0; in_syms = 1; next }
    /^[[:space:]]*};/           { in_codes = 0; in_syms = 0; next }

    # Parse: <KEYNAME> = KEYCODE ;
    in_codes && /<[A-Z0-9]+>[[:space:]]*=[[:space:]]*[0-9]+/ {
        line = $0
        gsub(/[<>;]/, "", line)
        n = split(line, parts, /[[:space:]]*=[[:space:]]*/)
        if (n >= 2) {
            key_name = parts[1]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", key_name)
            key_code = parts[2]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", key_code)
            if (key_name != "" && key_code ~ /^[0-9]+$/) {
                code_map[key_name] = key_code
            }
        }
    }

    # Parse: key <KEYNAME> { [ symbol, symbol, ... ] };
    in_syms && /key[[:space:]]+<[A-Z0-9]+>/ {
        if (match($0, /<[A-Z0-9]+>/)) {
            key_name = substr($0, RSTART + 1, RLENGTH - 2)
        } else {
            next
        }

        if (match($0, /\[[^\]]+\]/)) {
            content = substr($0, RSTART + 1, RLENGTH - 2)
            # Get first symbol (unshifted)
            split(content, syms, /[[:space:]]*,[[:space:]]*/)
            sym = syms[1]
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", sym)

            if ((key_name in code_map) && sym != "") {
                print code_map[key_name] "\t" sym
            }
        }
    }
    '
}

get_binds() {
    # Fetch keybindings from Hyprland and format as delimited fields
    local delim="$1"

    hyprctl -j binds 2>/dev/null | jq -r --arg d "$delim" '
        .[]
        | select(.key != null and .key != "")
        | ((.modmask // 0) | tonumber) as $m
        | [
            (if ($m % 2)   >= 1  then "SHIFT" else empty end),
            (if ($m % 8)   >= 4  then "CTRL"  else empty end),
            (if ($m % 16)  >= 8  then "ALT"   else empty end),
            (if ($m % 128) >= 64 then "SUPER" else empty end)
          ] as $mods
        | [
            (.submap      // ""),
            ($mods | join(" ")),
            .key,
            ((.keycode    // 0) | tostring),
            (.description // ""),
            (.dispatcher  // ""),
            (.arg         // "")
          ]
        | join($d)
    '
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

# 1. Build keycode-to-symbol lookup cache
get_keymap > "$KEYMAP_CACHE"

# 2. Fetch and format keybindings
DATA=$(get_binds "$DELIM" | awk -F"$DELIM" -v delim="$DELIM" -v cache="$KEYMAP_CACHE" '
BEGIN {
    # Load keymap cache into associative array
    while ((getline line < cache) > 0) {
        n = split(line, parts, "\t")
        if (n >= 2 && parts[1] != "") {
            key_lookup[parts[1]] = parts[2]
        }
    }
    close(cache)
}

{
    submap     = $1
    mods       = $2
    key        = $3
    keycode    = int($4)   # Force numeric comparison
    desc       = $5
    dispatcher = $6
    arg        = $7

    # Skip entries without a dispatcher
    if (dispatcher == "") next

    # Resolve keycode to symbol (unless it is a mouse binding)
    if (key !~ /^mouse:/ && keycode > 0 && (keycode in key_lookup)) {
        key = key_lookup[keycode]
    }
    key = toupper(key)

    # Build human-readable action string
    if (desc != "") {
        action = desc
    } else if (arg != "") {
        action = dispatcher " (" arg ")"
    } else {
        action = dispatcher
    }

    # Submap indicator prefix
    submap_prefix = ""
    if (submap != "" && submap != "global") {
        submap_prefix = "[" toupper(submap) "] "
    }

    # Normalize whitespace in modifiers
    gsub(/[[:space:]]+/, " ", mods)
    sub(/^[[:space:]]+/, "", mods)
    sub(/[[:space:]]+$/, "", mods)

    # Assemble display key
    display_key = (mods != "") ? (mods " + " key) : key

    # Output format: DISPLAY_COLUMN | DELIM | DISPATCHER | DELIM | ARG
    printf "%-45s %s%s%s%s%s%s\n", display_key, submap_prefix, action, delim, dispatcher, delim, arg
}
' | sort -t"$DELIM" -k1,1 -u)

# Exit gracefully if no bindings were found
if [[ -z "${DATA:-}" ]]; then
    exit 0
fi

# 3. Present the menu (display only the human-readable portion)
# Rofi returns the 0-based index with -format i
SELECTED_INDEX=$(
    awk -F"$DELIM" '{print $1}' <<< "$DATA" \
    | "${MENU_COMMAND[@]}" -format i
) || exit 0   # User cancelled or rofi error

# Validate we received a numeric index
if [[ ! "$SELECTED_INDEX" =~ ^[0-9]+$ ]]; then
    exit 0
fi

# 4. Retrieve the full selected line (convert 0-based index to 1-based line number)
LINE_NUM=$((SELECTED_INDEX + 1))
SELECTED_LINE=$(sed -n "${LINE_NUM}p" <<< "$DATA")

if [[ -z "${SELECTED_LINE:-}" ]]; then
    exit 1
fi

# 5. Parse dispatcher and argument from the hidden portion
IFS="$DELIM" read -r _display DISPATCHER ARG <<< "$SELECTED_LINE"

if [[ -z "${DISPATCHER:-}" ]]; then
    printf 'Error: No dispatcher found in selection\n' >&2
    exit 1
fi

# 6. Execute the keybinding via hyprctl
if [[ -n "${ARG:-}" ]]; then
    exec hyprctl dispatch "$DISPATCHER" "$ARG"
else
    exec hyprctl dispatch "$DISPATCHER"
fi
