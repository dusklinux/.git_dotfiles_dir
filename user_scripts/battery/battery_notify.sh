#!/usr/bin/env bash
# Self-contained battery notification script for Arch Linux (Hyprland/systemd service)
# - Single-file, no external config or logging
# - Uses upower and notify-send (user said these are installed)
# - All configurable variables are at the top of this file
# - Designed to be run as a long-running systemd service (user already created one)

##########################
# CONFIGURATION (edit these values near the top of the script)
##########################
# If empty, script will auto-detect the first battery device via `upower -e`.
BATTERY_DEVICE=""            # Example: "/org/freedesktop/UPower/devices/battery_BAT0"

# Percentage thresholds (integers 0-100)
BATTERY_FULL_THRESHOLD=74     # Consider battery "Full" at or above this percentage
BATTERY_LOW_THRESHOLD=40      # Notify for low battery when percentage <= this
BATTERY_CRITICAL_THRESHOLD=30 # Critical; immediate notification and optional command
BATTERY_UNPLUG_THRESHOLD=90   # If charger unplugged (state changed to Discharging) and percentage <= this, notify

# Timing / intervals
CHECK_INTERVAL=30             # Seconds between checks (script sleeps this long between loops)
REPEAT_FULL_MIN=1080          # Minutes to wait before repeating a "Full" notification
REPEAT_LOW_MIN=5              # Minutes to wait before repeating a "Low" notification
REPEAT_CRITICAL_MIN=1         # Minutes to wait before repeating a "Critical" notification

# Commands to execute on events (leave empty to disable). They will be executed in background.
EXECUTE_CRITICAL="systemctl suspend"         # Example: "systemctl hibernate"  (will be run once per critical crossing)
EXECUTE_LOW=""                               # Example: "paplay /usr/share/sounds/low.wav"
EXECUTE_UNPLUG=""                            # Example: "notify-send 'Action' 'Charger unplugged'" (usually not needed)
EXECUTE_CHARGING=""                          # Command when starting to charge (optional)

# Notification settings
NOTIFY_TIMEOUT_MS=5000       # notify-send timeout in milliseconds
VERBOSE=false                # set to true to echo debug lines to stdout (useful for testing)

##########################
# End of user-editable config
##########################

# Internal state variables
last_state=""           # previous upower state: Charging / Discharging / Fully-charged / Unknown
last_percentage=999
last_full_notified_at=0   # epoch seconds
last_low_notified_at=0
last_critical_notified_at=0
last_unplug_notified_at=0

# helper: log when VERBOSE
log() { if [ "$VERBOSE" = true ]; then echo "[battery_notify] $*"; fi }

# find battery device via upower
detect_battery() {
  if [ -n "$BATTERY_DEVICE" ]; then
    echo "$BATTERY_DEVICE"
    return 0
  fi
  # prefer a device path that looks like a battery
  local dev
  dev=$(upower -e 2>/dev/null | grep -i battery | head -n1 || true)
  if [ -z "$dev" ]; then
    # fall back to searching for "Battery"
    dev=$(upower -e 2>/dev/null | grep -i "battery" -m1 || true)
  fi
  if [ -z "$dev" ]; then
    return 1
  fi
  echo "$dev"
}

# read state and percentage from upower for a device path
read_battery() {
  local dev="$1"
  # Use upower -i which gives lines like: state: discharging; percentage: 45%
  local info
  info=$(upower -i "$dev" 2>/dev/null)
  if [ -z "$info" ]; then
    return 1
  fi
  local state
  local perc
  state=$(printf "%s" "$info" | awk -F: '/state:/ {gsub(/^[ \t]+|\n/,"",$2); print $2; exit}')
  perc=$(printf "%s" "$info" | awk -F: '/percentage:/ {gsub(/[^0-9]/, "", $2); print $2; exit}')
  # Normalize some states
  case "${state,,}" in
    discharging) state="Discharging" ;;
    charging)    state="Charging" ;;
    fully-charged|fully_charged|fullycharged) state="Full" ;;
    *) state="Unknown" ;;
  esac
  printf "%s;%s" "$state" "$perc"
}

# send a notification using notify-send
fn_notify() {
  local timeout_ms="$1"
  local urgency="$2"
  local title="$3"
  local body="$4"
  # Use notify-send; do not try to create files or logs
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u "$urgency" -t "$timeout_ms" "$title" "$body"
  else
    log "notify-send not found; would send: $title - $body"
  fi
}

# safely run a command in background without creating files
run_bg() {
  local cmd="$1"
  if [ -z "$cmd" ]; then return 0; fi
  # Run in subshell, detach, redirect outputs to /dev/null
  ( setsid bash -lc "$cmd" >/dev/null 2>&1 & )
}

# convert minutes to epoch seconds delta
minutes_to_seconds() { echo $(( $1 * 60 )); }

# main loop
main_loop() {
  local dev
  dev=$(detect_battery) || {
    echo "No battery device found via upower. Exiting." >&2
    exit 2
  }
  log "Using battery device: $dev"

  while true; do
    local read
    read=$(read_battery "$dev") || {
      log "Failed to read battery info; retrying in $CHECK_INTERVAL seconds"
      sleep "$CHECK_INTERVAL"
      continue
    }

    local state=${read%%;*}
    local percentage=${read##*;}
    # ensure percentage numeric
    if ! [[ "$percentage" =~ ^[0-9]+$ ]]; then
      log "Unreadable percentage: '$percentage'"
      sleep "$CHECK_INTERVAL"
      continue
    fi

    log "State=$state Percentage=$percentage PrevState=$last_state PrevPerc=$last_percentage"

    now=$(date +%s)

    # Detect transitions
    if [ "$state" != "$last_state" ]; then
      # Charging started
      if [ "$state" = "Charging" ]; then
        log "Transition: -> Charging"
        fn_notify "$NOTIFY_TIMEOUT_MS" "normal" "Battery: Charging" "Battery is charging — ${percentage}%"
        [ -n "$EXECUTE_CHARGING" ] && run_bg "$EXECUTE_CHARGING"
      fi

      # Became Discharging (unplugged)
      if [ "$state" = "Discharging" ]; then
        log "Transition: -> Discharging"
        # only notify unplug if below threshold
        if [ "$percentage" -le "$BATTERY_UNPLUG_THRESHOLD" ]; then
          # check repeat
          if [ $(( now - last_unplug_notified_at )) -ge $(minutes_to_seconds $REPEAT_LOW_MIN) ]; then
            fn_notify "$NOTIFY_TIMEOUT_MS" "normal" "Battery: Unplugged" "Charger unplugged — battery at ${percentage}%"
            [ -n "$EXECUTE_UNPLUG" ] && run_bg "$EXECUTE_UNPLUG"
            last_unplug_notified_at=$now
          else
            log "Skipping unplug notify due to repeat timer"
          fi
        fi
      fi

      last_state="$state"
    fi

    # Full notification (only when plugged or full state)
    if [ "$percentage" -ge "$BATTERY_FULL_THRESHOLD" ] && [ "$state" != "Discharging" ]; then
      if [ $(( now - last_full_notified_at )) -ge $(minutes_to_seconds $REPEAT_FULL_MIN) ]; then
        fn_notify "$NOTIFY_TIMEOUT_MS" "normal" "Battery: Full" "Battery is ${percentage}% — consider unplugging when convenient."
        last_full_notified_at=$now
      else
        log "Skipping full notify due to repeat timer"
      fi
    fi

    # Low battery notification (on crossing downward or periodic)
    if [ "$percentage" -le "$BATTERY_LOW_THRESHOLD" ] && [ "$state" = "Discharging" ]; then
      # Notify when crossing threshold downward (prev > low) or when repeat interval passed
      if [ "$last_percentage" -gt "$BATTERY_LOW_THRESHOLD" ] || [ $(( now - last_low_notified_at )) -ge $(minutes_to_seconds $REPEAT_LOW_MIN) ]; then
        fn_notify "$NOTIFY_TIMEOUT_MS" "normal" "Battery: Low" "Battery is at ${percentage}%. Please connect the charger."
        [ -n "$EXECUTE_LOW" ] && run_bg "$EXECUTE_LOW"
        last_low_notified_at=$now
      else
        log "Skipping low notify"
      fi
    fi

    # Critical battery (strong action)
    if [ "$percentage" -le "$BATTERY_CRITICAL_THRESHOLD" ]; then
      if [ "$last_percentage" -gt "$BATTERY_CRITICAL_THRESHOLD" ] || [ $(( now - last_critical_notified_at )) -ge $(minutes_to_seconds $REPEAT_CRITICAL_MIN) ]; then
        fn_notify "$NOTIFY_TIMEOUT_MS" "critical" "Battery: CRITICAL" "Battery critically low: ${percentage}%. Immediate action recommended."
        [ -n "$EXECUTE_CRITICAL" ] && run_bg "$EXECUTE_CRITICAL"
        last_critical_notified_at=$now
      else
        log "Skipping critical notify"
      fi
    fi

    last_percentage=$percentage
    sleep "$CHECK_INTERVAL"
  done
}

# If script is executed directly, start loop
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main_loop
fi
