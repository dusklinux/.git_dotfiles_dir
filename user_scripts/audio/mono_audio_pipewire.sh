#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Elite Mono Toggle for Arch/Hyprland (PipeWire)
# Architecture: Null Sink (1ch Mix) -> Loopback (2ch Duplicate) -> Hardware
# Features: Atomic cleanup, Polling wait-states, Robust stream migration
# -----------------------------------------------------------------------------

set -euo pipefail

# Configuration
readonly MONO_SINK_NAME="mono_global_downmix"
# Include UID in state file to prevent multi-user collisions in /tmp
readonly STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/mono_audio_state_${UID}"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

# Get sink ID from sink name
get_sink_id_by_name() {
    pactl list sinks short 2>/dev/null | awk -v name="$1" '$2 == name {print $1; exit}'
}

# Get sink name from sink ID
get_sink_name_by_id() {
    pactl list sinks short 2>/dev/null | awk -v id="$1" '$1 == id {print $2; exit}'
}

# Wait for a sink to appear in PipeWire (Polling)
# Prevents race conditions where we try to use the sink before it's registered
wait_for_sink() {
    local sink_name="$1"
    local attempts=0
    local max_attempts=20 # 1 second total

    while (( attempts++ < max_attempts )); do
        if pactl list sinks short 2>/dev/null | grep -q "$sink_name"; then
            return 0
        fi
        sleep 0.05
    done
    return 1
}

# Move all running audio streams to a specified target sink
move_streams() {
    local target_name="$1"
    local target_id
    
    # Resolve name to ID for accurate comparison
    target_id=$(get_sink_id_by_name "$target_name")
    
    if [[ -z "$target_id" ]]; then
        return 0
    fi

    # Iterate active streams
    # Columns: ID, Sink_ID, Client/Proto...
    while read -r stream_id current_sink_id _rest; do
        if [[ -n "$stream_id" ]]; then
            # Optimization: Skip if already on the target
            if [[ "$current_sink_id" == "$target_id" ]]; then
                continue
            fi
            
            # Attempt move, ignore errors (stream might die during operation)
            pactl move-sink-input "$stream_id" "$target_id" 2>/dev/null || true
        fi
    done < <(pactl list sink-inputs short 2>/dev/null)
}

# Find the hardware sink with the most active streams
get_busiest_sink_id() {
    pactl list sink-inputs short 2>/dev/null | awk '
        { count[$2]++ }
        END {
            max = 0
            best = ""
            for (id in count) {
                if (count[id] > max) {
                    max = count[id]
                    best = id
                }
            }
            print best
        }
    '
}

# Clean up ANY modules related to this script
# We filter by the specific names we assigned to the modules
cleanup_mono_modules() {
    # 1. Unload Loopbacks targeting our setup
    pactl list modules short 2>/dev/null | grep "module-loopback" | while read -r mod_id _rest; do
        # Inspect full module arguments to see if it belongs to us
        if pactl list modules | grep -A 20 "Module #$mod_id" | grep -q "source=${MONO_SINK_NAME}.monitor"; then
            pactl unload-module "$mod_id" 2>/dev/null || true
        fi
    done

    # 2. Unload the Null Sink
    pactl list modules short 2>/dev/null | grep "module-null-sink" | while read -r mod_id _rest; do
        if pactl list modules | grep -A 20 "Module #$mod_id" | grep -q "sink_name=${MONO_SINK_NAME}"; then
            pactl unload-module "$mod_id" 2>/dev/null || true
        fi
    done
}

# -----------------------------------------------------------------------------
# Main Logic
# -----------------------------------------------------------------------------

# Check if our Mono setup is currently active
CURRENT_NULL_ID=$(pactl list modules short 2>/dev/null | awk -v name="sink_name=$MONO_SINK_NAME" '$0 ~ name {print $1; exit}')

if [[ -n "$CURRENT_NULL_ID" ]]; then
    # =========================================================================
    # TOGGLE OFF: Restore Stereo
    # =========================================================================

    # 1. Retrieve the hardware sink we were using before
    RESTORE_SINK=""
    if [[ -s "$STATE_FILE" ]]; then
        RESTORE_SINK=$(<"$STATE_FILE")
    fi

    # Fallback: Find a hardware sink that isn't our mono sink
    if [[ -z "$RESTORE_SINK" ]]; then
        RESTORE_SINK=$(pactl list sinks short 2>/dev/null | awk -v mono="$MONO_SINK_NAME" '$2 != mono {print $2; exit}')
    fi

    if [[ -z "${RESTORE_SINK:-}" ]]; then
        notify-send -u critical "Audio Error" "Could not find hardware sink to restore!" || true
        exit 1
    fi

    # 2. Restore Default
    pactl set-default-sink "$RESTORE_SINK" || true

    # 3. Move audio back to hardware
    move_streams "$RESTORE_SINK"

    # 4. Cleanup Modules (Robust method)
    cleanup_mono_modules
    
    # 5. Cleanup State
    rm -f "$STATE_FILE"
    notify-send -u low -t 2000 "Audio" "Switched to Stereo 🎧" || true

else
    # =========================================================================
    # TOGGLE ON: Enable True Mono
    # =========================================================================

    # 1. INTELLIGENT SINK DETECTION
    BUSIEST_SINK_ID=$(get_busiest_sink_id)
    
    TARGET_HARDWARE_SINK=""
    if [[ -n "$BUSIEST_SINK_ID" ]]; then
        TARGET_HARDWARE_SINK=$(get_sink_name_by_id "$BUSIEST_SINK_ID")
    fi

    if [[ -z "$TARGET_HARDWARE_SINK" ]]; then
        TARGET_HARDWARE_SINK=$(pactl get-default-sink)
    fi

    if [[ -z "$TARGET_HARDWARE_SINK" ]]; then
        notify-send -u critical "Audio Error" "No audio device found!" || true
        exit 1
    fi

    # 2. Save state
    printf "%s" "$TARGET_HARDWARE_SINK" > "$STATE_FILE"

    # 3. Create the 1-Channel Null Sink (Forces Downmix L+R -> Mono)
    if ! pactl load-module module-null-sink \
        sink_name="$MONO_SINK_NAME" \
        sink_properties='device.description="Mono_Downmix"' \
        channels=1 \
        channel_map=mono > /dev/null; then
        notify-send -u critical "Audio Error" "Failed to create null sink." || true
        exit 1
    fi

    # 4. Wait for Sink to be ready (Polling)
    if ! wait_for_sink "$MONO_SINK_NAME"; then
        notify-send -u critical "Audio Error" "Mono sink failed to register." || true
        cleanup_mono_modules
        exit 1
    fi

    # 5. Set Default Sink -> Mono
    pactl set-default-sink "$MONO_SINK_NAME" || true

    # 6. Move streams -> Mono
    # We do this BEFORE creating the loopback to ensure the loopback doesn't get moved
    move_streams "$MONO_SINK_NAME"

    # 7. Create Loopback (Mono Source -> Stereo Hardware)
    # We force 2 channels output to ensure it plays on both speakers
    if ! pactl load-module module-loopback \
        source="${MONO_SINK_NAME}.monitor" \
        sink="$TARGET_HARDWARE_SINK" \
        channels=2 \
        channel_map=front-left,front-right > /dev/null; then
        
        notify-send -u critical "Audio Error" "Failed to create loopback." || true
        cleanup_mono_modules
        exit 1
    fi

    notify-send -u low -t 2000 "Audio" "Switched to Mono 🔊" || true
fi
