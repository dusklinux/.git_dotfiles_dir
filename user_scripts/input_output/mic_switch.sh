#!/bin/bash
# -----------------------------------------------------------------------------
# OPTIMIZED MICROPHONE INPUT SWITCHER FOR HYPRLAND
# Dependencies: hyprland, pulseaudio-utils (pactl), jq, swayosd-client
# -----------------------------------------------------------------------------
set -uo pipefail

# Dependency check
for cmd in pactl jq hyprctl swayosd-client; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required command '$cmd' not found." >&2
        exit 1
    fi
done

# 1. Get the currently focused monitor for OSD notification
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name // empty')
focused_monitor="${focused_monitor:-}"

# 2. Get the current default source (microphone)
current_source=$(pactl get-default-source 2>/dev/null || echo "")

# 3. THE LOGIC CORE
#    Key difference: Filter out monitor sources (.monitor_of != null)
source_data=$(pactl -f json list sources 2>/dev/null | jq -r --arg current "$current_source" '
  # Filter: Exclude monitor sources AND apply availability check
  [ .[]
    | select(.monitor_of == null)
    | select((.ports | length == 0) or ([.ports[]? | .availability != "not available"] | any))
  ]
  | sort_by(.name) as $sources
  | ($sources | length) as $len

  # Safety: Exit early if no sources available
  | if $len == 0 then ""
    else
      (($sources | map(.name) | index($current)) // -1) as $idx
      | (if $idx < 0 then 0 else ($idx + 1) % $len end) as $next_idx
      | $sources[$next_idx]
      | [
          .name,
          ((.description // .properties."device.description" // .properties."node.description" // .properties."device.product.name" // .name) | gsub("[\\t\\n\\r]"; " ")),
          ((.volume | to_entries[0].value.value_percent // "0%") | sub("%$"; "")),
          (if .mute then "true" else "false" end)
        ]
      | @tsv
    end
')

# 4. Parse the output safely
IFS=$'\t' read -r next_name next_desc next_vol next_mute <<< "$source_data"

# 5. Error handling: No sources found
if [[ -z "${next_name:-}" ]]; then
    swayosd-client ${focused_monitor:+--monitor "$focused_monitor"} \
        --custom-message "No Input Devices Available" \
        --custom-icon "microphone-sensitivity-muted-symbolic"
    exit 1
fi

# 6. Ensure volume is numeric
if ! [[ "${next_vol:-}" =~ ^[0-9]+$ ]]; then
    next_vol=0
fi

# 7. Switch the default source
if ! pactl set-default-source "$next_name" 2>/dev/null; then
    swayosd-client ${focused_monitor:+--monitor "$focused_monitor"} \
        --custom-message "Failed to switch input" \
        --custom-icon "dialog-error-symbolic"
    exit 1
fi

# 8. Move all currently recording applications to the new source
while IFS=$'\t' read -r output_id _; do
    [[ -n "$output_id" ]] && pactl move-source-output "$output_id" "$next_name" 2>/dev/null || true
done < <(pactl list short source-outputs 2>/dev/null)

# 9. Determine icon based on volume and mute status
if [[ "${next_mute:-}" == "true" ]] || (( next_vol == 0 )); then
    icon="microphone-sensitivity-muted-symbolic"
elif (( next_vol <= 33 )); then
    icon="microphone-sensitivity-low-symbolic"
elif (( next_vol <= 66 )); then
    icon="microphone-sensitivity-medium-symbolic"
else
    icon="microphone-sensitivity-high-symbolic"
fi

# 10. Display the OSD notification
swayosd-client \
    ${focused_monitor:+--monitor "$focused_monitor"} \
    --custom-message "${next_desc:-Unknown Device}" \
    --custom-icon "$icon"

exit 0
