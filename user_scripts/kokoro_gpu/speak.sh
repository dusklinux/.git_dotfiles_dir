#!/bin/bash

# --- Configuration ---
KOKORO_APP_DIR="$HOME/contained_apps/uv/kokoro_gpu"
PYTHON_SCRIPT_PATH="$HOME/user_scripts/kokoro_gpu/speak.py"
SAVE_DIR="/mnt/zram1/kokoro_gpu"
MPV_PLAYBACK_SPEED="2.2"
AUDIO_RATE=24000
AUDIO_CHANNELS=1
AUDIO_FORMAT="f32le"
BUFFER_SIZE="512M"

# --- Checks ---
if [[ "$EUID" -eq 0 ]]; then
    notify-send "Kokoro Error" "Don't run as root." -u critical
    exit 1
fi
if ! command -v mbuffer &> /dev/null; then
    notify-send "Kokoro Error" "Please install 'mbuffer'" -u critical
    exit 1
fi

# --- Setup ---
mkdir -p "$SAVE_DIR"
CLIPBOARD_TEXT=$(wl-paste --no-newline)

if [[ -z "$CLIPBOARD_TEXT" ]]; then
    notify-send "Kokoro TTS" "Clipboard empty." -u low
    exit 0
fi

# --- FILE NAMING & INDEXING ---
# Logic: Split to newlines, remove punctuation, lowercase, take top 5 lines, join with underscores.
FILENAME_WORDS=$(echo "$CLIPBOARD_TEXT" | tr -s '[:space:]' '\n' | tr -cd '[:alnum:]\n' | tr '[:upper:]' '[:lower:]' | grep . | head -n 5 | paste -sd _)

# Safety: If clipboard contained only symbols (resulting in empty string), use generic name.
[[ -z "$FILENAME_WORDS" ]] && FILENAME_WORDS="audio"

LAST_INDEX=$(find "$SAVE_DIR" -type f -name "*.wav" -print0 | xargs -0 -n 1 basename | cut -d'_' -f1 | grep '^[0-9]\+$' | sort -rn | head -n 1)

# CRITICAL FIX: If directory is empty, LAST_INDEX is null, causing the math below to crash.
[[ -z "$LAST_INDEX" ]] && LAST_INDEX=0

NEXT_INDEX=$((LAST_INDEX + 1))
FINAL_FILENAME="${NEXT_INDEX}_${FILENAME_WORDS}.wav"
FULL_PATH="$SAVE_DIR/$FINAL_FILENAME"

notify-send "Kokoro TTS" "Streaming: '${FILENAME_WORDS//_/ }...'" -u low

# --- AUTO-KILL LOGIC (FIXED) ---
# Only run cleanup on interrupt (Ctrl+C) or Termination. 
# Do NOT run on EXIT, because that kills mpv while it's closing, crashing Hyprland.
cleanup() {
    kill 0 2>/dev/null
}
trap cleanup INT TERM

# --- EXECUTION ---
cd "$KOKORO_APP_DIR" && \
echo "$CLIPBOARD_TEXT" | \
uv run python "$PYTHON_SCRIPT_PATH" | \
mbuffer -q -m "$BUFFER_SIZE" | \
tee --output-error=exit >(ffmpeg -f "$AUDIO_FORMAT" -ar "$AUDIO_RATE" -ac "$AUDIO_CHANNELS" -i pipe:0 -y "$FULL_PATH" -loglevel quiet) | \
mpv \
  --no-terminal \
  --force-window \
  --title="Kokoro TTS" \
  --geometry=400x100 \
  --keep-open=yes \
  --speed="$MPV_PLAYBACK_SPEED" \
  --demuxer=rawaudio \
  --demuxer-rawaudio-rate="$AUDIO_RATE" \
  --demuxer-rawaudio-channels="$AUDIO_CHANNELS" \
  --demuxer-rawaudio-format=float \
  --cache=yes \
  --cache-secs=30 \
  - 

# When mpv closes naturally, the pipe breaks. 
# Python and mbuffer will receive SIGPIPE and terminate on their own.
exit 0
