#!/usr/bin/env bash
#
# kokoro-stream-player.sh
#
# A sophisticated automation script to capture clipboard text, generate speech using
# the 'kokoros' TTS engine, and immediately play the resulting audio with MPV.
# Designed for seamless integration with desktop environments like Hyprland via
# keyboard shortcuts.
#
# Author: Gemini
# Date: 2025-06-29
# Version: 2.1

# --- ENVIRONMENT SETUP FOR NOTIFICATIONS ---
# Ensure that libnotify (notify-send) can connect over D-Bus in a Hyprland/Sway session.
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
if [ -z "${DBUS_SESSION_BUS_ADDRESS-}" ]; then
  # Start a private D-Bus session if one isn’t already available
  eval "$(dbus-launch --sh-syntax --exit-with-session)"
fi

# --- USER CONFIGURATION ---
# Adjust the variables in this section to match your system and preferences.

# 1. Voice Model Selection
#    Choose your preferred voice model from the available options.
#"af_alloy", "af_aoede", "af_bella", "af_heart", "af_jessica", "af_kore", "af_nicole", "af_nova", "af_river", "af_sarah", "af_sky", "am_adam", "am_echo", "am_eric", "am_fenrir", "am_liam", "am_michael", "am_onyx", "am_puck", "am_santa", "bf_alice", "bf_emma", "bf_isabella", "bf_lily", "bm_daniel", "bm_fable", "bm_george", "bm_lewis", "ef_dora", "em_alex", "em_santa", "ff_siwis", "hf_alpha", "hf_beta", "hm_omega", "hm_psi", "if_sara", "im_nicola", "jf_alpha", "jf_gongitsune", "jf_nezumi", "jf_tebukuro", "jm_kumo", "pf_dora", "pm_alex", "pm_santa", "zf_xiaobei", "zf_xiaoni", "zf_xiaoxiao", "zf_xiaoyi", "zm_yunjian", "zm_yunxi", "zm_yunxia", "zm_yunyang", "af_sarah.4+af_nicole.6"
VOICE_MODEL="af_sarah.4+af_nicole.6"

# 2. Output Directory
#    The path where the generated .wav files will be stored.
#    IMPORTANT: This script will create the directory if it doesn’t exist.
#    Using a zram1 is recommended for performance and automatic cleanup on reboot.
OUTPUT_DIR="/mnt/zram1/kokoros"

# 3. MPV Playback Speed
#    Set the audio playback speed for MPV. 1.0 is normal speed.
PLAYBACK_SPEED="2.2"

# 4. Kokoros Model and Data Paths
#    Ensure these paths point to your kokoros model and data files.
#    The script will expand the tilde (~) to your home directory.
KOKOROS_MODEL_PATH="~/contained_apps/uv/kokoros_rust_onnx/Kokoros/checkpoints/kokoro-v1.0.onnx"
KOKOROS_DATA_PATH="~/contained_apps/uv/kokoros_rust_onnx/Kokoros/data/voices-v1.0.bin"

# --- END OF CONFIGURATION ---


# --- SCRIPT LOGIC ---
# Do not edit below this line unless you know what you are doing.

# Function for sending desktop notifications (requires `notify-send`)
function notify() {
    command -v notify-send &>/dev/null && notify-send -a "Kokoros TTS" "$1" "$2"
}

# Step 1: Pre-flight checks for required dependencies
# The script will exit if any of these are not found in your PATH.
# Given you are on Hyprland/Sway, we use `wl-paste` for clipboard access.
for cmd in kokoros mpv wl-paste tee; do
    if ! command -v "$cmd" &> /dev/null; then
        notify "Error: Dependency Missing" \
               "The required command '$cmd' could not be found. Please install it and ensure it's in your PATH."
        exit 1
    fi
done

# Step 2: Expand tilde-prefixed paths to absolute paths
# This ensures that paths like ~/path/to/file are correctly interpreted.
KOKOROS_MODEL_PATH_EXPANDED="${KOKOROS_MODEL_PATH/#\~/$HOME}"
KOKOROS_DATA_PATH_EXPANDED="${KOKOROS_DATA_PATH/#\~/$HOME}"

if [[ ! -f "$KOKOROS_MODEL_PATH_EXPANDED" || ! -f "$KOKOROS_DATA_PATH_EXPANDED" ]]; then
    notify "Error: Kokoros Files Not Found" \
           "The model or data file was not found. Please check the KOKOROS_MODEL_PATH and KOKOROS_DATA_PATH variables."
    exit 1
fi

# Step 3: Get text from the Wayland clipboard
# We use `wl-paste` and remove any trailing newline for cleaner processing.
CLIPBOARD_TEXT=$(wl-paste --no-newline)
if [[ -z "$CLIPBOARD_TEXT" ]]; then
    notify "Clipboard is Empty" "There is no text on the clipboard to process."
    exit 0  # Exit gracefully, not as an error.
fi

# Step 4: Ensure the output directory exists
# The `-p` flag creates parent directories as needed and doesn't error if it already exists.
mkdir -p "$OUTPUT_DIR"

# Step 5: Determine the next file index
# This mechanism scans for files named like '[number]_*.wav', finds the highest
# number, and increments it to prevent overwriting files.
LATEST_INDEX=0
shopt -s nullglob  # Prevent errors if no files match the glob
for f in "$OUTPUT_DIR"/*_*.wav; do
    BASENAME=$(basename "$f")
    CURRENT_INDEX=${BASENAME%%_*}
    if [[ "$CURRENT_INDEX" =~ ^[0-9]+$ ]] && (( CURRENT_INDEX > LATEST_INDEX )); then
        LATEST_INDEX=$CURRENT_INDEX
    fi
done
NEXT_INDEX=$((LATEST_INDEX + 1))

# Step 6: Sanitize the first five words of the clipboard text for the filename
FIRST_FIVE_WORDS=$(echo "$CLIPBOARD_TEXT" \
    | head -n 1 \
    | cut -d' ' -f1-5 \
    | tr '[:upper:]' '[:lower:]' \
    | tr -s ' ' '_' \
    | sed 's/[^a-z0-9_]//g')
FILENAME="${NEXT_INDEX}_${FIRST_FIVE_WORDS}.wav"
FULL_OUTPUT_PATH="${OUTPUT_DIR}/${FILENAME}"

# Step 7: Execute TTS → Save → Play → Notify
# We pipe the kokoros output to both a file and mpv, background mpv so we can fire the notification.
echo "$CLIPBOARD_TEXT" | kokoros \
    -s "$VOICE_MODEL" \
    -m "$KOKOROS_MODEL_PATH_EXPANDED" \
    -d "$KOKOROS_DATA_PATH_EXPANDED" \
    stream \
  | tee "$FULL_OUTPUT_PATH" \
  | mpv --no-terminal --force-window --speed="$PLAYBACK_SPEED" --title="Kokoros TTS" - &

MPV_PID=$!

# Send desktop notification now that playback has started
notify "🔊 $(basename "$FULL_OUTPUT_PATH")"

# Optional: wait for playback to finish before exiting the script
wait $MPV_PID

exit 0
