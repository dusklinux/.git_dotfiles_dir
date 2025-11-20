#!/bin/bash

# -----------------------------------------------------------------------------
# OPTIMIZED AUDIO SWITCHER FOR HYPRLAND
# Dependencies: hyprland, pulseaudio-utils (pactl), jq, swayosd-git
# -----------------------------------------------------------------------------

# 1. Get the currently focused monitor for the OSD notification
#    We capture this early to ensure the OSD appears on the screen you are looking at.
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')

# 2. Get the current default sink name to calculate the rotation
current_sink=$(pactl get-default-sink)

# 3. THE LOGIC CORE
#    We use one single jq command to:
#    a. List sinks and filter out unavailable ones (e.g. unplugged HDMI).
#    b. Find the index of the current sink.
#    c. Calculate the next sink in the cycle.
#    d. formatting the output data (Name, Description, Volume, Mute Status).
#    We use @tsv (Tab Separated Values) to safely pass data back to Bash.

read -r next_name next_desc next_vol next_mute <<< "$(pactl -f json list sinks | jq -r --arg current "$current_sink" '
  # Filter sinks: Keep only those with no ports OR where availability is not "not available"
  [ .[] | select((.ports | length == 0) or ([.ports[]? | .availability != "not available"] | any)) ] 
  | sort_by(.name) as $sinks
  | ($sinks | map(.name) | index($current)) as $idx
  | if $idx == null then 0 else ($idx + 1) % ($sinks | length) end as $next_idx
  | $sinks[$next_idx] 
  | [
      .name,
      # Intelligent Description Lookup: Try specific properties before falling back to generic name
      (.description // .properties."device.description" // .properties."node.description" // .properties."device.product.name" // .name),
      (.volume | to_entries[0].value.value_percent | sub("%";"")),
      (.mute)
    ] 
  | @tsv
')"

# 4. Error Handling: If no sinks found or jq failed
if [ -z "$next_name" ]; then
    swayosd-client --monitor "$focused_monitor" --custom-message "No Output Devices"
    exit 1
fi

# 5. Switch the default sink
pactl set-default-sink "$next_name"

# 6. CRITICAL: Move currently playing audio streams to the new sink
#    This ensures music/video moves immediately without needing a restart.
pactl list short sink-inputs | cut -f1 | while read -r input_id; do
    pactl move-sink-input "$input_id" "$next_name"
done

# 7. Determine Icon based on volume and mute status
if [ "$next_mute" = "true" ] || [ "$next_vol" -eq 0 ]; then
    icon="sink-volume-muted-symbolic"
elif [ "$next_vol" -le 33 ]; then
    icon="sink-volume-low-symbolic"
elif [ "$next_vol" -le 66 ]; then
    icon="sink-volume-medium-symbolic"
else
    icon="sink-volume-high-symbolic"
fi

# 8. Display the OSD Notification
#    Using --custom-icon allows us to use the standard icon set calculated above.
swayosd-client \
    --monitor "$focused_monitor" \
    --custom-message "$next_desc" \
    --custom-icon "$icon"
