#!/usr/bin/env bash
# Hyprland Waybar Visibility Manager Script
# Version 3.1.0 (Further Optimized)
#
# This script manages Waybar visibility in Hyprland based on Hyprland events:
# 1. Special Workspace: Waybar is hidden if on a specific "special" workspace.
# 2. Regular Workspaces: Waybar visibility is based on the active window's fullscreen state.
# This version builds on 3.0.0 (Lean Edition) with further optimizations:
# - Replaced grep/xargs/basename with shell builtins or more efficient patterns.
# - Reduced hyprctl/jq calls by combining queries and improving logic flow.
# - Optimized event handling loop with case statements and direct string parsing.

# Exit on error, treat unset variables as error, propagate pipeline errors
set -euo pipefail

# --- Configuration ---
WAYBAR_BIN_NAME="waybar" # Used for pgrep/pkill and to find the binary path
SPECIAL_WORKSPACE_NAME="special:magic"
# --- End Configuration ---

# --- Script Globals ---
WAYBAR_BIN_PATH="" # Full path to waybar binary
_IS_CURRENTLY_ON_SPECIAL="false" # Tracks if Hyprland is on the special workspace
HYPRLAND_SOCKET2=""
# --- End Script Globals ---

# --- Helper Functions ---
find_waybar_binary() {
  if ! WAYBAR_BIN_PATH=$(command -v "$WAYBAR_BIN_NAME"); then
    # No logging in lean version
    exit 1
  fi
}

check_dependencies() {
  local missing_deps=0
  # Removed grep, xargs, basename from this direct check as they are avoided or handled differently
  for cmd in hyprctl jq socat awk; do 
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps=1
    fi
  done
  if [ "$missing_deps" -eq 1 ]; then
    exit 1
  fi
}

is_waybar_running() {
  pgrep -x "$WAYBAR_BIN_NAME" >/dev/null
}

start_waybar() {
  if [[ "$_IS_CURRENTLY_ON_SPECIAL" == "true" ]]; then
    return
  fi
  if ! is_waybar_running; then
    # WAYBAR_BIN_PATH is the full path, good for launching
    nohup "$WAYBAR_BIN_PATH" >/dev/null 2>&1 &
  fi
}

kill_waybar() {
  if is_waybar_running; then
    pkill -x "$WAYBAR_BIN_NAME" || true # Suppress error if not found
  fi
}

find_hyprland_socket() {
  local sig hyprctl_output hyprctl_status=0
  hyprctl_output=$(hyprctl instances -j 2>/dev/null) || hyprctl_status=$?
  if [[ $hyprctl_status -ne 0 || -z "$hyprctl_output" ]]; then
    return 1
  fi
  
  # Use process substitution with read for efficiency and to avoid subshell for sig
  read -r sig < <(jq -r '.[0].instance // ""' <<< "$hyprctl_output")
  if [[ -z "$sig" ]]; then
    return 1
  fi

  HYPRLAND_SOCKET2="$XDG_RUNTIME_DIR/hypr/$sig/.socket2.sock"
  if [[ ! -S "$HYPRLAND_SOCKET2" ]]; then
    return 1
  fi
  return 0
}

# Renamed and refactored from check_fullscreen_and_manage_waybar_on_regular_ws
update_waybar_visibility_based_on_hyprland_state() {
    local hypr_output hypr_status=0
    local active_win_ws_name is_fullscreen
    local current_ws_name # Used in fallback

    # Try to get active window info first, as it contains workspace name and fullscreen state
    hypr_output=$(hyprctl -j activewindow 2>/dev/null) || hypr_status=$?

    if [[ $hypr_status -ne 0 ]]; then
        # Failed to get active window. This could mean no active window, or other hyprctl error.
        # Fallback to checking activeworkspace.
        local active_ws_info_output active_ws_info_status=0
        active_ws_info_output=$(hyprctl -j activeworkspace 2>/dev/null) || active_ws_info_status=$?

        if [[ $active_ws_info_status -ne 0 || -z "$active_ws_info_output" ]]; then
            # Both hyprctl calls failed or gave empty output.
            # Failsafe: assume not special, start Waybar.
            _IS_CURRENTLY_ON_SPECIAL="false"
            start_waybar
            return
        fi
        
        # Read workspace name from activeworkspace output
        # jq -r output is usually clean, but read -r will trim any leading/trailing whitespace
        read -r current_ws_name < <(jq -r '.name // ""' <<< "$active_ws_info_output")

        if [[ -n "$current_ws_name" && "$current_ws_name" == "$SPECIAL_WORKSPACE_NAME" ]]; then
            _IS_CURRENTLY_ON_SPECIAL="true"
            kill_waybar
        else
            # Not on special, but no active window (or error getting it specifically)
            _IS_CURRENTLY_ON_SPECIAL="false"
            start_waybar
        fi
        return
    fi

    # Successfully got activewindow info. Parse it.
    local values jq_status=0
    # mapfile reads lines from jq output into an array. jq outputs two lines: workspace name, fullscreen state.
    mapfile -t values < <(jq -r '(.workspace.name // ""), (.fullscreen // "0")' <<< "$hypr_output") || jq_status=$?

    if [[ $jq_status -ne 0 || ${#values[@]} -lt 2 ]]; then
        # jq failed or didn't produce expected output (e.g. not enough lines for 'values').
        # This could happen if hypr_output was "null" (string) or malformed.
        # Failsafe: assume regular workspace, not fullscreen.
        _IS_CURRENTLY_ON_SPECIAL="false"
        start_waybar
        return
    fi

    # mapfile doesn't trim values robustly itself, 'read -r' does.
    read -r active_win_ws_name <<< "${values[0]}"
    read -r is_fullscreen <<< "${values[1]}"


    if [[ -n "$active_win_ws_name" && "$active_win_ws_name" == "$SPECIAL_WORKSPACE_NAME" ]]; then
        _IS_CURRENTLY_ON_SPECIAL="true"
        kill_waybar
        return
    fi

    # If we reach here, we are on a regular workspace
    _IS_CURRENTLY_ON_SPECIAL="false"

    if [[ "$is_fullscreen" == "1" || "$is_fullscreen" == "2" ]]; then # fullscreen values 1 (real) or 2 (fake/maximized)
        kill_waybar
    else
        start_waybar
    fi
}
# --- End Helper Functions ---

# --- Main Logic ---
main() {
  find_waybar_binary
  check_dependencies

  if ! find_hyprland_socket; then
    exit 1
  fi

  # Set initial Waybar state based on current Hyprland state
  update_waybar_visibility_based_on_hyprland_state

  # Listen for Hyprland events
  # awk is used for line buffering to ensure timely event processing by the while loop.
  socat -u "UNIX-CONNECT:$HYPRLAND_SOCKET2" - | awk '{print; fflush()}' | \
  while IFS= read -r event_line; do
      # Efficiently extract event type (part before ">>")
      local event_type="${event_line%%>>*}"
      # And payload (part after ">>")
      local event_payload="${event_line#*>>}"

      case "$event_type" in
          "activespecial")
              # Payload is "NAME,MONITOR" or ",MONITOR" (if no special active)
              local active_special_name="${event_payload%%,*}" # Get part before first comma

              if [[ "$active_special_name" == "$SPECIAL_WORKSPACE_NAME" ]]; then
                  # Our target special workspace became active
                  if [[ "$_IS_CURRENTLY_ON_SPECIAL" == "false" ]]; then # Only act if state changed
                      _IS_CURRENTLY_ON_SPECIAL="true"
                      kill_waybar
                  fi
              elif [[ "$_IS_CURRENTLY_ON_SPECIAL" == "true" ]]; then
                  # We *were* on our special workspace, but an 'activespecial' event occurred
                  # that isn't for our target special workspace (name is empty or different).
                  # This implies we have left *our* special workspace.
                  # update_waybar_visibility_based_on_hyprland_state will set _IS_CURRENTLY_ON_SPECIAL correctly
                  # and manage Waybar (e.g., start it if now on a regular non-fullscreen WS).
                  update_waybar_visibility_based_on_hyprland_state
              fi
              ;;
          "workspace")
              # Active workspace changed. This always requires a full re-evaluation.
              # update_waybar_visibility_based_on_hyprland_state handles setting
              # _IS_CURRENTLY_ON_SPECIAL and managing Waybar.
              update_waybar_visibility_based_on_hyprland_state
              ;;
          "fullscreen" | "activewindow")
              # For fullscreen/activewindow events, only re-evaluate if we believe we are
              # currently on a non-special workspace. If on special, Waybar is already hidden,
              # and these events don't change that aspect of its visibility.
              if [[ "$_IS_CURRENTLY_ON_SPECIAL" == "false" ]]; then
                  update_waybar_visibility_based_on_hyprland_state
              fi
              ;;
      esac
  done
}

# Original lock file name from the user's script
LOCK_FILE_DIR="/tmp/waybar_visibility_manager.lock"

_main_with_trap() {
    # Ensure lock directory is removed on exit, interrupt, termination, or hangup
    trap 'if [ -d "$LOCK_FILE_DIR" ]; then rmdir "$LOCK_FILE_DIR" 2>/dev/null; fi; exit 0' EXIT INT TERM HUP

    # Attempt to create lock directory; mkdir is atomic
    if mkdir "$LOCK_FILE_DIR" 2>/dev/null; then
      main
    else
      # Script is already running or lock file is stale. Exit silently as per "lean edition" goal.
      exit 1
    fi
}

_main_with_trap
