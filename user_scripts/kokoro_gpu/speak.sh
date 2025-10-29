#!/bin/bash

# A robust script to capture clipboard text, synthesize it to speech,
# play it back in real-time, and save it to a file.
#
# v3: Simplifies speed control by removing the redundant Kokoro speed
#     variable. Synthesis speed is now managed in the Python script,
#     while this script controls MPV playback speed.
#
# Dependencies: wl-paste, mpv, uv, notify-send

# --- User Configuration ---
# The directory where your Kokoro models are located.
KOKORO_APP_DIR="$HOME/contained_apps/uv/kokoro_gpu"

# The full, unambiguous path to the Python script to execute.
PYTHON_SCRIPT_PATH="$HOME/user_scripts/kokoro_gpu/speak.py"

# Default path for saving the generated audio files.
SAVE_DIR="/mnt/zram1/kokoro_gpu"

# --- MPV Playback Speed Control ---
# Controls the playback speed in MPV.
# For kokoro's native playback speed, change it in the python script.
MPV_PLAYBACK_SPEED="2.2"


# --- Pre-flight Checks ---
# Ensure the script is not run as root.
if [[ "$EUID" -eq 0 ]];
then
  notify-send "Kokoro TTS Error" "This script should not be run as root." -u critical
  exit 1
fi

# Ensure necessary commands are available.
for cmd in wl-paste mpv uv notify-send;
do
  if ! command -v "$cmd" &> /dev/null; then
    notify-send "Kokoro TTS Error" "Dependency missing: '$cmd' is not installed." -u critical
    exit 1
  fi
done

# Ensure the Kokoro app directory and Python script exist.
if [[ ! -d "$KOKORO_APP_DIR" ]] || [[ ! -f "$PYTHON_SCRIPT_PATH" ]];
then
  notify-send "Kokoro TTS Error" "Kokoro directory ('$KOKORO_APP_DIR') or Python script ('$PYTHON_SCRIPT_PATH') not found." -u critical
  exit 1
fi

# --- Main Logic ---
# Create the save directory if it doesn't exist.
mkdir -p "$SAVE_DIR"
if [[ ! -d "$SAVE_DIR" ]]; then
    notify-send "Kokoro TTS Error" "Failed to create save directory at '$SAVE_DIR'." -u critical
    exit 1
fi

# Get text from the Wayland clipboard.
CLIPBOARD_TEXT=$(wl-paste --no-newline)

# Exit gracefully if clipboard is empty.
if [[ -z "$CLIPBOARD_TEXT" ]];
then
  notify-send "Kokoro TTS" "Clipboard is empty." -u low
  exit 0
fi

# --- Robust Filename Generation ---
# 1. Sanitize the entire clipboard text:
#    - Replace any whitespace character (space, tab, newline) with a single underscore.
#    - Remove any character that is not alphanumeric or an underscore.
#    - Convert to lowercase.
# 2. Extract the first 5 "words" (now underscore-separated tokens).
# 3. Truncate the result to 100 characters as a final safeguard against "File name too long".
FILENAME_WORDS=$(echo "$CLIPBOARD_TEXT" | tr -s '[:space:]' '_' | tr -cd '[:alnum:]_' | tr '[:upper:]' '[:lower:]' | cut -d'_' -f1-5 | cut -c1-100)

# Find the next available chronological index.
# This is a robust way to handle file numbering, even if files are deleted.
LAST_INDEX=$(find "$SAVE_DIR" -type f -name "*.wav" -print0 | xargs -0 -n 1 basename | cut -d'_' -f1 | grep '^[0-9]\+$' | sort -rn | head -n 1)
NEXT_INDEX=$((LAST_INDEX + 1))

# Construct the final filename.
FINAL_FILENAME="${NEXT_INDEX}_${FILENAME_WORDS}.wav"
FULL_PATH="$SAVE_DIR/$FINAL_FILENAME"

# --- Execution ---
# Notify the user that the process has started, using the sanitized words for a clean notification.
notify-send "Kokoro TTS" "Synthesizing: '${FILENAME_WORDS//_/ }...'" -u low

# The core pipeline, now run in a backgrounded subshell.
# This ensures the main script exits immediately, which is ideal for keybindings.
(
  cd "$KOKORO_APP_DIR" && \
  echo "$CLIPBOARD_TEXT" | uv run python "$PYTHON_SCRIPT_PATH" | \
  tee "$FULL_PATH" | \
  mpv --speed="$MPV_PLAYBACK_SPEED" --no-terminal --force-window --title="Kokoro TTS" - > /dev/null 2>&1
) &

# The script will now exit immediately, leaving the pipeline running in the background.
exit 0
