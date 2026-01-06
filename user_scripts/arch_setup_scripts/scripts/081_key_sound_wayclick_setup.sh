#!/usr/bin/env bash
# ==============================================================================
# WAYCLICK ELITE - SETUP ONLY (ORCHESTRA MODULE)
# ==============================================================================
#  INSTRUCTIONS:
#  Add this to your Orchestra INSTALL_SEQUENCE as a User command:
#  "U | 081_wayclick_setup.sh"
# ==============================================================================

set -euo pipefail

# --- CONFIGURATION (MATCHING ORIGINAL) ---
readonly APP_NAME="wayclick"
readonly BASE_DIR="$HOME/contained_apps/uv/$APP_NAME"
readonly VENV_DIR="$BASE_DIR/.venv"
readonly RUNNER_SCRIPT="$BASE_DIR/runner.py"
readonly CONFIG_DIR="$HOME/.config/wayclick"

# --- LOGGING HELPER ---
# Matches the style of your personal orchestra for consistency in logs
log() {
    echo " -> [WAYCLICK SETUP] $1"
}

# 1. Dependency Check & Auto-Install
# We rely on the Orchestra's sudo keep-alive for permissions.
NEEDED_DEPS=""
if ! command -v uv &>/dev/null; then NEEDED_DEPS="$NEEDED_DEPS uv"; fi
if ! command -v notify-send &>/dev/null; then NEEDED_DEPS="$NEEDED_DEPS libnotify"; fi

# [FIX] Critical headers for compiling pygame-ce from source
# Since we use --no-binary :all:, we MUST have these system libraries present.
for pkg in sdl2_image sdl2_mixer sdl2_ttf; do
    if ! pacman -Qi "$pkg" &>/dev/null; then
        NEEDED_DEPS="$NEEDED_DEPS $pkg"
    fi
done

if [[ -n "$NEEDED_DEPS" ]]; then
    log "Installing missing dependencies: $NEEDED_DEPS"
    sudo pacman -S --needed --noconfirm $NEEDED_DEPS
else
    log "System dependencies (uv, libnotify, sdl2_*) are present."
fi

# 2. Group Permission Check (Input)
# Critical for reading evdev events without root
if ! groups "$USER" | grep -q "\binput\b"; then
    log "User '$USER' is not in 'input' group. Adding now..."
    sudo usermod -aG input "$USER"
    log "WARNING: You must REBOOT or LOGOUT for group changes to take effect."
else
    log "User is already in 'input' group."
fi

# 3. Directory Structure
if [[ ! -d "$BASE_DIR" ]]; then
    log "Creating base directory: $BASE_DIR"
    mkdir -p "$BASE_DIR"
fi

if [[ ! -d "$CONFIG_DIR" ]]; then
    log "Creating config directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
fi

# 4. Environment Setup (UV)
MARKER_FILE="$BASE_DIR/.build_marker_v3"

if [[ ! -f "$MARKER_FILE" ]]; then
    log "Initializing UV environment..."

    # Create VENV if it doesn't exist
    if [[ ! -d "$VENV_DIR" ]]; then
        uv venv "$VENV_DIR" --python 3.13 --quiet
    fi

    log "Compiling dependencies with NATIVE CPU FLAGS (AVX2+)..."
    
    # ---------------------------------------------------------
    # ELITE BUILD FLAGS (Preserved from original script)
    # ---------------------------------------------------------
    export CFLAGS="-march=native -mtune=native -O3 -pipe -fno-plt"
    export CXXFLAGS="-march=native -mtune=native -O3 -pipe -fno-plt"
    
    # Install evdev and pygame-ce from source
    uv pip install --python "$VENV_DIR/bin/python" \
        --no-binary :all: \
        --compile-bytecode \
        evdev pygame-ce

    touch "$MARKER_FILE"
    log "Native build complete."
else
    log "Environment already built (Marker found). Skipping build."
fi

# 5. Generate Runner Script
# We overwrite this every time to ensure the latest logic is present.
log "Generating runner.py..."

cat > "$RUNNER_SCRIPT" << 'EOF'
import asyncio
import os
import sys
import signal
import random
import json

# === PERFORMANCE FLAGS ===
# Clean startup
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = '1'
# Low latency audio drivers
os.environ['SDL_AUDIODRIVER'] = 'pulseaudio' 
os.environ['SDL_BUFFER_CHUNK_SIZE'] = '256' 

import pygame
import evdev
from evdev import ecodes

# ANSI Colors for Python
C_GREEN = "\033[1;32m"
C_YELLOW = "\033[1;33m"
C_BLUE = "\033[1;34m"
C_RED = "\033[1;31m"
C_RESET = "\033[0m"

ASSET_DIR = sys.argv[1]

# === AUDIO INIT ===
# 44100Hz, 16-bit, 2 channels, 256 sample buffer
try:
    pygame.mixer.pre_init(frequency=44100, size=-16, channels=2, buffer=256)
    pygame.mixer.init()
    pygame.mixer.set_num_channels(32)
except pygame.error as e:
    print(f"\033[1;31m[AUDIO ERROR]\033[0m {e}")
    sys.exit(1)

# === CONFIG LOADING ===
CONFIG_FILE = os.path.join(ASSET_DIR, "config.json")
print(f"{C_BLUE}[INFO]{C_RESET} Loading assets from {ASSET_DIR}...")

try:
    with open(CONFIG_FILE, 'r') as f:
        config_data = json.load(f)
        
        # JSON keys are strings, but evdev expects integers.
        # We assume the config file uses string representation of integers (e.g. "1": "file.wav")
        RAW_KEY_MAP = {int(k): v for k, v in config_data.get("mappings", {}).items()}
        DEFAULTS = config_data.get("defaults", [])
        
except Exception as e:
    print(f"{C_RED}[CONFIG ERROR]{C_RESET} Failed to load {CONFIG_FILE}: {e}")
    sys.exit(1)

# Dynamically determine which files to load based on the config
# This allows the user to add new wav files to config.json without editing script
SOUND_FILES = list(set(list(RAW_KEY_MAP.values()) + DEFAULTS))
SOUNDS = {}

# Load Sounds
for filename in SOUND_FILES:
    path = os.path.join(ASSET_DIR, filename)
    if os.path.exists(path):
        try:
            SOUNDS[filename] = pygame.mixer.Sound(path)
        except pygame.error:
            # File exists but is corrupt or invalid
            print(f"{C_YELLOW}[WARN]{C_RESET} Failed to load wav: {filename}")
    else:
        # Warn about missing files (non-blocking)
        print(f"{C_YELLOW}[WARN]{C_RESET} File not found: {filename}")

if not SOUNDS:
    sys.exit("ERROR: No sounds loaded! Check your config.json and .wav files.")

# === OPTIMIZATION: CACHED LIST LOOKUP ===
# Convert Dictionary Map -> Array Index for O(1) access
# Standard evdev keycodes are usually small, but user configs may use higher scan codes.
# We allocate 64k to cover virtually all possibilities (consumes ~0.5MB RAM).
MAX_KEYCODE = 65536
SOUND_CACHE = [None] * MAX_KEYCODE
DEFAULT_SOUND_OBJS = [SOUNDS[f] for f in DEFAULTS if f in SOUNDS]

# Pre-fill the cache
for code, filename in RAW_KEY_MAP.items():
    if code < MAX_KEYCODE and filename in SOUNDS:
        SOUND_CACHE[code] = SOUNDS[filename]

# Pre-bind random choice to avoid module lookup in hot path
_random_choice = random.choice

def play_sound(code):
    # Ultra-fast path
    if code < MAX_KEYCODE:
        sound = SOUND_CACHE[code]
        if sound:
            sound.play()
            return

    # Fallback (unmapped keys or missing sound files)
    if DEFAULT_SOUND_OBJS:
        _random_choice(DEFAULT_SOUND_OBJS).play()

async def read_device(path, stop_event):
    """Async reader for a specific input device."""
    dev = None
    try:
        dev = evdev.InputDevice(path)
        print(f"{C_GREEN}[+] Connected:{C_RESET} {dev.name}")
        
        async for event in dev.async_read_loop():
            if stop_event.is_set():
                break
            # EV_KEY (1) and Value 1 (Key Down)
            if event.type == 1 and event.value == 1:
                play_sound(event.code)
                
    except (OSError, IOError):
        print(f"{C_YELLOW}[-] Disconnected:{C_RESET} {path}")
    except asyncio.CancelledError:
        pass
    finally:
        if dev:
            dev.close()

async def main():
    print(f"{C_BLUE}[CORE]{C_RESET} Engine started. Monitoring devices...")
    
    stop = asyncio.Event()
    loop = asyncio.get_running_loop()
    
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, stop.set)
    
    monitored_tasks = {} # path -> task

    while not stop.is_set():
        # 1. Device Discovery
        try:
            # We explicitly check for EV_KEY capabilities to filter out non-keyboards
            all_paths = evdev.list_devices()
            
            for path in all_paths:
                if path in monitored_tasks:
                    continue
                
                try:
                    dev = evdev.InputDevice(path)
                    caps = dev.capabilities()
                    # Check for EV_KEY (1)
                    if 1 in caps:
                        task = asyncio.create_task(read_device(path, stop))
                        monitored_tasks[path] = task
                    dev.close()
                except (OSError, IOError):
                    continue

        except Exception as e:
            print(f"Discovery Loop Error: {e}")

        # 2. Cleanup Dead Tasks
        dead_paths = [p for p, t in monitored_tasks.items() if t.done()]
        for p in dead_paths:
            del monitored_tasks[p]

        # 3. Hotplug Polling Rate
        try:
            await asyncio.wait_for(stop.wait(), timeout=3.0)
        except asyncio.TimeoutError:
            continue
    
    # Graceful Shutdown
    print("\nStopping...")
    for t in monitored_tasks.values():
        t.cancel()
    if monitored_tasks:
        await asyncio.gather(*monitored_tasks.values(), return_exceptions=True)
    pygame.mixer.quit()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
EOF

log "Setup complete. Wayclick environment is ready."
