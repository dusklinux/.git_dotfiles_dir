#!/bin/bash
#
# A script to display your live Hyprland keybindings in an interactive menu.
# It dynamically queries Hyprland for all active keymaps, including defaults.

# --- CONFIGURATION ---
# Set the command for your preferred interactive menu.
# - You can replace 'rofi' with another menu like 'wofi' or 'fuzzel'.
# - Add or remove flags to customize the appearance and behavior.
# Examples:
# MENU_COMMAND="rofi -dmenu -i -p 'Keybindings:' -theme-str 'window {width: 60%;}'"
# MENU_COMMAND="wofi --dmenu --prompt 'Keybindings:'"
# MENU_COMMAND="fuzzel --dmenu --prompt 'Keybindings:'"

MENU_COMMAND="rofi -dmenu -i -p 'Hyprland Keybindings' -theme-str 'window {width: 60%; height: 70%;}'"


# --- SCRIPT LOGIC ---

# This script uses an in-memory map to cache keycode-to-symbol translations.
declare -A KEYCODE_SYM_MAP

# build_keymap_cache: Compiles your keyboard layout to find which keycode (e.g., 24)
# maps to which symbol (e.g., q). This makes the script more accurate than just
# reading text from a config file.
build_keymap_cache() {
  local keymap
  keymap="$(xkbcli compile-keymap)" || {
    echo "Failed to compile keymap. Is 'xkbcli' installed?" >&2
    exit 1
  }

  while IFS=, read -r code sym; do
    [[ -z "$code" || -z "$sym" ]] && continue
    KEYCODE_SYM_MAP["$code"]="$sym"
  done < <(
    awk '
      BEGIN { sec = "" }
      /xkb_keycodes/ { sec = "codes"; next }
      /xkb_symbols/  { sec = "syms";  next }
      sec == "codes" {
        if (match($0, /<([A-Z0-9_]+)>\s*=\s*([0-9]+)\s*;/, m)) code_by_name[m[1]] = m[2]
      }
      sec == "syms" {
        if (match($0, /key\s*<([A-Z0-9_]+)>\s*\{\s*\[\s*([^, \]]+)/, m)) sym_by_name[m[1]] = m[2]
      }
      END {
        for (k in code_by_name) {
          c = code_by_name[k]
          s = sym_by_name[k]
          if (c != "" && s != "" && s != "NoSymbol") print c "," s
        }
      }
    ' <<<"$keymap"
  )
}

# parse_keycodes: Replaces raw keycodes in the output from Hyprland
# with the human-readable symbols we found using the cache.
parse_keycodes() {
  while IFS= read -r line; do
    if [[ "$line" =~ code:([0-9]+) ]]; then
      local code="${BASH_REMATCH[1]}"
      local symbol="${KEYCODE_SYM_MAP[$code]}"
      echo "${line/code:${code}/$symbol}"
    else
      echo "$line"
    fi
  done
}

# dynamic_bindings: Asks the running Hyprland process for its current bindings
# using `hyprctl`. It then does some initial cleanup to make the output
# easier to parse later.
dynamic_bindings() {
  hyprctl -j binds |
    jq -r '.[] | {modmask, key, keycode, description, dispatcher, arg} | "\(.modmask),\(.key)@\(.keycode),\(.description),\(.dispatcher),\(.arg)"' |
    sed -r \
      -e 's/null//' \
      -e 's/@0//' \
      -e 's/,@/,code:/' \
      -e 's/^0,/,/' \
      -e 's/^1,/SHIFT,/' \
      -e 's/^4,/CTRL,/' \
      -e 's/^5,/SHIFT CTRL,/' \
      -e 's/^8,/ALT,/' \
      -e 's/^9,/SHIFT ALT,/' \
      -e 's/^12,/CTRL ALT,/' \
      -e 's/^13,/SHIFT CTRL ALT,/' \
      -e 's/^64,/SUPER,/' \
      -e 's/^65,/SUPER SHIFT,/' \
      -e 's/^68,/SUPER CTRL,/' \
      -e 's/^69,/SUPER SHIFT CTRL,/' \
      -e 's/^72,/SUPER ALT,/' \
      -e 's/^73,/SUPER SHIFT ALT,/' \
      -e 's/^76,/SUPER CTRL ALT,/' \
      -e 's/^77,/SUPER SHIFT CTRL ALT,/'
}

# parse_bindings: Takes the cleaned-up data and formats it into a
# "Key Combo → Action" format for the menu. It prioritizes the simple
# 'description' field if it exists, otherwise it shows the command.
parse_bindings() {
  awk -F, '
{
    # Combine the modifier and key
    key_combo = $1 " + " $2;
    gsub(/^[ \t]*\+?[ \t]*/, "", key_combo);
    gsub(/[ \t]+$/, "", key_combo);
    gsub(/[ \t]+/, " ", key_combo);

    # Use the friendly description field if available
    action = $3;

    # Otherwise, reconstruct the command from the dispatcher and arg fields
    if (action == "") {
        action = $4
        for (i = 5; i <= NF; i++) {
            action = action " " $i
        }
    }

    # Print the final formatted line if an action exists
    if (action != "") {
        printf "%-35s → %s\n", key_combo, action;
    }
}'
}

# --- EXECUTION ---
# The main pipeline of the script.
# 1. Build the keycode-to-symbol map.
# 2. Get the raw bindings from Hyprland.
# 3. Sort them to remove any duplicates.
# 4. Translate raw keycodes to proper symbols.
# 5. Format the bindings into clean, readable lines.
# 6. Pipe the final list into the menu command you defined above.
build_keymap_cache

dynamic_bindings |
  sort -u |
  parse_keycodes |
  parse_bindings |
  eval "$MENU_COMMAND"
