#!/usr/bin/env bash
#
# Hyprshade Selector - Interactive shader picker with live preview
#

# -----------------------------------------------------------------------------
# STRICT MODE & SAFETY
# -----------------------------------------------------------------------------
set -o errexit      # Exit on error
set -o nounset      # Error on unset variables
set -o pipefail     # Pipeline fails on first error

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
declare -rA ICONS=(
    [active]=""
    [inactive]=""
    [off]=""
    [shader]=""
)

declare -ra ROFI_CMD=(
    rofi
    -dmenu
    -i
    -markup-rows
    -theme-str 'window {width: 400px;}'
    -mesg "<span size='x-small'>Use <b>Up/Down</b> to preview. <b>Enter</b> to apply. <b>Esc</b> to cancel.</span>"
)

# -----------------------------------------------------------------------------
# GLOBAL STATE
# -----------------------------------------------------------------------------
declare -a SHADERS=()
declare ORIGINAL_SHADER=""
declare -i CURRENT_IDX=0
declare -i MAX_IDX=0
declare VIRTUAL_CURRENT=""
declare SEARCH_QUERY=""
declare CLEANUP_NEEDED="true"

# -----------------------------------------------------------------------------
# UTILITY FUNCTIONS
# -----------------------------------------------------------------------------

# Trim leading and trailing whitespace
trim() {
    local str="${1:-}"
    str="${str#"${str%%[![:space:]]*}"}"
    str="${str%"${str##*[![:space:]]}"}"
    printf '%s' "$str"
}

# Log error message to stderr
err() {
    printf 'Error: %s\n' "$*" >&2
}

# Check for required commands
check_dependencies() {
    local -a missing=()
    local cmd
    for cmd in rofi hyprshade awk sed; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if ((${#missing[@]} > 0)); then
        err "Missing required commands: ${missing[*]}"
        exit 1
    fi
}

# Apply shader (foreground or background)
apply_shader() {
    local shader="${1:-off}"
    local background="${2:-false}"
    
    local redirect=""
    [[ "$background" == "true" ]] && redirect="&"
    
    if [[ "$shader" == "off" ]]; then
        if [[ "$background" == "true" ]]; then
            hyprshade off &>/dev/null &
        else
            hyprshade off
        fi
    else
        if [[ "$background" == "true" ]]; then
            hyprshade on "$shader" &>/dev/null &
        else
            hyprshade on "$shader"
        fi
    fi
}

# Cleanup handler - restore original state on unexpected exit
cleanup() {
    if [[ "$CLEANUP_NEEDED" == "true" && -n "$ORIGINAL_SHADER" ]]; then
        apply_shader "$ORIGINAL_SHADER" 2>/dev/null || true
    fi
}

# -----------------------------------------------------------------------------
# INITIALIZATION
# -----------------------------------------------------------------------------

init() {
    check_dependencies
    
    # Set up cleanup trap
    trap cleanup EXIT INT TERM HUP
    
    # Capture original shader state
    ORIGINAL_SHADER=$(trim "$(hyprshade current 2>/dev/null || echo '')")
    [[ -z "$ORIGINAL_SHADER" ]] && ORIGINAL_SHADER="off"
    
    # Load available shaders
    SHADERS=("off")
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        local clean
        clean=$(trim "$line")
        [[ -n "$clean" ]] && SHADERS+=("$clean")
    done < <(hyprshade ls 2>/dev/null || true)
    
    # Validate shaders array
    if ((${#SHADERS[@]} == 0)); then
        err "No shaders available"
        exit 1
    fi
    
    # Find current shader index
    CURRENT_IDX=0
    local i
    for i in "${!SHADERS[@]}"; do
        if [[ "${SHADERS[i]}" == "$ORIGINAL_SHADER" ]]; then
            CURRENT_IDX=$i
            break
        fi
    done
    
    MAX_IDX=$((${#SHADERS[@]} - 1))
    VIRTUAL_CURRENT="$ORIGINAL_SHADER"
    SEARCH_QUERY=""
}

# -----------------------------------------------------------------------------
# MENU BUILDING
# -----------------------------------------------------------------------------

build_menu() {
    local -n menu_ref=$1
    local -n active_ref=$2
    
    menu_ref=()
    active_ref=0
    
    local i item icon style_start style_end display_name
    
    for i in "${!SHADERS[@]}"; do
        item="${SHADERS[i]}"
        
        # Determine styling
        if [[ "$item" == "$VIRTUAL_CURRENT" ]]; then
            active_ref=$i
            style_start="<b>"
            style_end=" (Active)</b>"
            
            if [[ "$item" == "off" ]]; then
                icon="${ICONS[off]}"
            else
                icon="${ICONS[active]}"
            fi
        else
            style_start=""
            style_end=""
            
            if [[ "$item" == "off" ]]; then
                icon="${ICONS[inactive]}"
            else
                icon="${ICONS[shader]}"
            fi
        fi
        
        # Display name
        if [[ "$item" == "off" ]]; then
            display_name="Turn Off"
        else
            display_name="$item"
        fi
        
        menu_ref+=("${style_start}${icon}  ${display_name}${style_end}")
    done
}

# -----------------------------------------------------------------------------
# MAIN LOOP
# -----------------------------------------------------------------------------

main_loop() {
    local -a menu_lines
    local -i active_row_index
    local -a rofi_flags
    local raw_output selection returned_query
    local -i exit_code
    local target
    
    while true; do
        # Build menu
        build_menu menu_lines active_row_index
        
        # Prepare rofi flags
        # Using index format for reliable parsing
        rofi_flags=(
            -p "Shader Preview"
            -format "i|f"
            -a "$active_row_index"
        )
        
        if [[ -n "$SEARCH_QUERY" ]]; then
            rofi_flags+=(-filter "$SEARCH_QUERY")
        else
            rofi_flags+=(
                -selected-row "$CURRENT_IDX"
                -kb-custom-1 "Down"
                -kb-custom-2 "Up"
                -kb-row-down ""
                -kb-row-up ""
            )
        fi
        
        # Execute rofi - use printf for safe output (no backslash interpretation)
        # Temporarily disable errexit for rofi call
        set +o errexit
        raw_output=$(printf '%s\n' "${menu_lines[@]}" | "${ROFI_CMD[@]}" "${rofi_flags[@]}" 2>/dev/null)
        exit_code=$?
        set -o errexit
        
        # Parse output (index|filter format)
        if [[ "$raw_output" == *"|"* ]]; then
            selection="${raw_output%%|*}"
            returned_query="${raw_output#*|}"
        else
            selection="$raw_output"
            returned_query=""
        fi
        
        # Handle based on exit code
        case $exit_code in
            0)
                # ENTER - Confirm selection
                if [[ -n "$selection" ]] && [[ "$selection" =~ ^[0-9]+$ ]]; then
                    if ((selection >= 0 && selection <= MAX_IDX)); then
                        target="${SHADERS[selection]}"
                    else
                        target="$VIRTUAL_CURRENT"
                    fi
                else
                    target="$VIRTUAL_CURRENT"
                fi
                
                apply_shader "$target"
                
                # Send notification if available
                if command -v notify-send &>/dev/null; then
                    local display_target
                    [[ "$target" == "off" ]] && display_target="Off" || display_target="$target"
                    notify-send -i video-display "Hyprshade" "Applied: $display_target"
                fi
                
                CLEANUP_NEEDED="false"
                exit 0
                ;;
                
            10)
                # DOWN - Preview next
                if [[ -n "$returned_query" ]]; then
                    SEARCH_QUERY="$returned_query"
                    continue
                fi
                
                ((++CURRENT_IDX > MAX_IDX)) && CURRENT_IDX=0
                
                target="${SHADERS[CURRENT_IDX]}"
                VIRTUAL_CURRENT="$target"
                SEARCH_QUERY=""
                
                apply_shader "$target" true
                ;;
                
            11)
                # UP - Preview previous
                if [[ -n "$returned_query" ]]; then
                    SEARCH_QUERY="$returned_query"
                    continue
                fi
                
                ((--CURRENT_IDX < 0)) && CURRENT_IDX=$MAX_IDX
                
                target="${SHADERS[CURRENT_IDX]}"
                VIRTUAL_CURRENT="$target"
                SEARCH_QUERY=""
                
                apply_shader "$target" true
                ;;
                
            1)
                # ESC / Cancel
                apply_shader "$ORIGINAL_SHADER"
                CLEANUP_NEEDED="false"
                exit 0
                ;;
                
            *)
                # Unknown exit code - treat as error
                err "Rofi exited with unexpected code: $exit_code"
                apply_shader "$ORIGINAL_SHADER"
                CLEANUP_NEEDED="false"
                exit 1
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# ENTRY POINT
# -----------------------------------------------------------------------------

main() {
    init
    main_loop
}

main "$@"
