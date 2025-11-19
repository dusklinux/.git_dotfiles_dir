#!/usr/bin/env bash
# Final Battery Notification Script
# Features: Configurable Interval, Safety Locks, Icons, Sounds, Self-Healing

##########################
# CONFIGURATION
##########################
# If empty, script auto-detects.
BATTERY_DEVICE=""

# Check Interval (Seconds)
# How often to poll the battery status.
CHECK_INTERVAL=30

# Thresholds
BATTERY_FULL_THRESHOLD=75
BATTERY_LOW_THRESHOLD=50
BATTERY_CRITICAL_THRESHOLD=30  # Critical warning
BATTERY_UNPLUG_THRESHOLD=100   # Set to 100 to ALWAYS notify when unplugged

# Timers (Minutes)
REPEAT_FULL_MIN=999
REPEAT_LOW_MIN=3
REPEAT_CRITICAL_MIN=1

# Commands & Sounds
CMD_CRITICAL="systemctl suspend"
SOUND_LOW="/usr/share/sounds/freedesktop/stereo/complete.oga"
SOUND_CRITICAL="/usr/share/sounds/freedesktop/stereo/suspend-error.oga"

##########################
# INTERNAL HELPERS
##########################

log() { echo "[battery_notify] $*"; }

get_icon() {
  local perc=$1
  local state=$2
  if [[ "$state" == "Charging" ]]; then
    echo "battery-level-${perc}-charging-symbolic"
  else
    # Round to nearest 10
    local rounded=$(( (perc + 5) / 10 * 10 ))
    [ "$rounded" -gt 100 ] && rounded=100
    echo "battery-level-${rounded}-symbolic"
  fi
}

fn_notify() {
  local urgency="$1"
  local title="$2"
  local body="$3"
  local icon="$4"
  local sound="$5"

  # 1. Ensure DBus environment exists
  if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
  fi

  # 2. Send Notification
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u "$urgency" -t 5000 -a "Battery Monitor" -i "$icon" "$title" "$body"
  else
    log "notify-send not found: $title"
  fi

  # 3. Play Sound
  if [ -n "$sound" ] && [ -f "$sound" ] && command -v paplay >/dev/null 2>&1; then
    (paplay "$sound" >/dev/null 2>&1 &)
  fi
}

detect_battery() {
  if [ -n "$BATTERY_DEVICE" ]; then echo "$BATTERY_DEVICE"; return 0; fi
  local dev=$(upower -e 2>/dev/null | grep -i 'BAT' | head -n1)
  if [ -z "$dev" ]; then dev=$(upower -e 2>/dev/null | grep -i 'battery' | head -n1); fi
  echo "$dev"
}

read_battery() {
  local dev="$1"
  local info=$(upower -i "$dev" 2>/dev/null)
  if [ -z "$info" ]; then return 1; fi
  
  local state=$(printf "%s" "$info" | awk -F: '/state:/ {gsub(/^[ \t]+|\n/,"",$2); print $2; exit}')
  local perc=$(printf "%s" "$info" | awk -F: '/percentage:/ {gsub(/[^0-9]/, "", $2); print $2; exit}')
  
  case "${state,,}" in
    discharging) state="Discharging" ;;
    charging)    state="Charging" ;;
    fully-charged|fully_charged) state="Full" ;;
    *) state="Unknown" ;;
  esac
  printf "%s;%s" "$state" "$perc"
}

##########################
# MAIN LOOP
##########################
main_loop() {
  local last_state=""
  local last_percentage=999
  local last_full_notified_at=0
  local last_low_notified_at=0
  local last_critical_notified_at=0
  local suspended_once=false

  local dev
  dev=$(detect_battery) || { log "No battery found."; exit 1; }
  log "Monitoring device: $dev"

  while true; do
    local reading
    reading=$(read_battery "$dev")
    
    # Self-healing retry using configured interval
    if [ -z "$reading" ]; then
       log "Reading failed. Retrying detection in ${CHECK_INTERVAL}s..."
       dev=$(detect_battery)
       sleep "$CHECK_INTERVAL"
       continue
    fi

    local state=${reading%%;*}
    local percentage=${reading##*;}
    local now=$(date +%s)

    # Reset Suspend Lock if charging
    if [ "$state" == "Charging" ] || [ "$state" == "Full" ]; then
        suspended_once=false
    fi

    # --- 1. State Transition ---
    if [ "$state" != "$last_state" ]; then
      log "State change: $last_state -> $state ($percentage%)"
      
      if [ "$state" == "Charging" ]; then
         fn_notify "normal" "Charging" "Battery is charging ($percentage%)" "$(get_icon $percentage $state)" ""
      
      elif [ "$state" == "Discharging" ]; then
         if [ "$percentage" -le "$BATTERY_UNPLUG_THRESHOLD" ]; then
            fn_notify "normal" "Unplugged" "System is running on battery ($percentage%)" "$(get_icon $percentage $state)" ""
         fi
      fi
      last_state="$state"
    fi

    # --- 2. Full Notification ---
    if [ "$state" == "Full" ] || ([ "$state" == "Charging" ] && [ "$percentage" -ge "$BATTERY_FULL_THRESHOLD" ]); then
       if [ $((now - last_full_notified_at)) -ge $((REPEAT_FULL_MIN * 60)) ]; then
          fn_notify "normal" "Battery Full" "Level: $percentage%" "battery-full-charged-symbolic" ""
          last_full_notified_at=$now
       fi
    fi

    # --- 3. Low Notification ---
    if [ "$state" == "Discharging" ] && [ "$percentage" -le "$BATTERY_LOW_THRESHOLD" ]; then
       if [ "$last_percentage" -gt "$BATTERY_LOW_THRESHOLD" ] || [ $((now - last_low_notified_at)) -ge $((REPEAT_LOW_MIN * 60)) ]; then
          fn_notify "normal" "Battery Low" "$percentage% remaining" "$(get_icon $percentage $state)" "$SOUND_LOW"
          last_low_notified_at=$now
       fi
    fi

    # --- 4. Critical Notification & Action ---
    if [ "$percentage" -le "$BATTERY_CRITICAL_THRESHOLD" ] && [ "$state" == "Discharging" ]; then
       if [ "$last_percentage" -gt "$BATTERY_CRITICAL_THRESHOLD" ] || [ $((now - last_critical_notified_at)) -ge $((REPEAT_CRITICAL_MIN * 60)) ]; then
          
          fn_notify "critical" "BATTERY CRITICAL" "$percentage% remaining. Suspending..." "battery-level-0-symbolic" "$SOUND_CRITICAL"
          last_critical_notified_at=$now
          
          if [ -n "$CMD_CRITICAL" ]; then
             if [ "$suspended_once" = false ]; then
                log "Executing critical command..."
                sleep 2 
                ($CMD_CRITICAL) &
                suspended_once=true
             fi
          fi
       fi
    fi

    last_percentage=$percentage
    sleep "$CHECK_INTERVAL"
  done
}

main_loop
