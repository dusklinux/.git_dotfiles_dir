#!/bin/bash

# -----------------------------------------------------------------------------
# OPTIMIZED MICROPHONE SWITCHER FOR HYPRLAND
# Dependencies: hyprland, pulseaudio-utils (pactl), jq, swayosd-git
# -----------------------------------------------------------------------------

# 1. Get the currently focused monitor for the OSD notification
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')

# 2. Get the current default source (mic)
current_source=$(pactl get-default-source)

# 3. THE LOGIC CORE
#    Differences from the Audio script:
#    a. We list 'sources' instead of 'sinks'.
#    b. CRITICAL: We filter out sources where 'monitor_of' is not null. 
#       This prevents switching to "Monitor of HDMI" or "Monitor of Headphones".
read -r next_name next_desc next_vol next_mute <<< "$(pactl -f json list sources | jq -r --arg current "$current_source" '
  [ .[] 
    | select(.monitor_of == null) 
    | select((.ports | length == 0) or ([.ports[]? | .availability != "not available"] | any)) 
  ] 
  | sort_by(.name) as $sources
  | ($sources | map(.name) | index($current)) as $idx
  | if $idx == null then 0 else ($idx + 1) % ($sources | length) end as $next_idx
  | $sources[$next_idx] 
  | [
      .name,
      (.description // .properties."device.description" // .properties."node.description" // .properties."device.product.name" // .name),
      (.volume | to_entries[0].value.value_percent | sub("%";"")),
      (.mute)
    ] 
  | @tsv
')"

# 4. Error Handling: If no microphones found
if [ -z "$next_name" ]; then
    swayosd-client --monitor "$focused_monitor" --custom-message "No Input Devices"
    exit 1
fi

# 5. Switch the default source
pactl set-default-source "$next_name"

# 6. CRITICAL: Move currently recording applications (Discord, OBS, Zoom, etc.)
#    This ensures your voice chat switches immediately.
pactl list short source-outputs | cut -f1 | while read -r output_id; do
    pactl move-source-output "$output_id" "$next_name"
done

# 7. Determine Icon based on volume and mute status
#    We use 'microphone-sensitivity' icons which are standard in most icon themes.
if [ "$next_mute" = "true" ] || [ "$next_vol" -eq 0 ]; then
    icon="microphone-sensitivity-muted-symbolic"
elif [ "$next_vol" -le 33 ]; then
    icon="microphone-sensitivity-low-symbolic"
elif [ "$next_vol" -le 66 ]; then
    icon="microphone-sensitivity-medium-symbolic"
else
    icon="microphone-sensitivity-high-symbolic"
fi

# 8. Display the OSD Notification
swayosd-client \
    --monitor "$focused_monitor" \
    --custom-message "$next_desc" \
    --custom-icon "$icon"
