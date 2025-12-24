#!/usr/bin/env bash
# ==============================================================================
# WAYCLICK ELITE - ARCH LINUX / UV OPTIMIZED
# ==============================================================================
# "I fear not the man who has practiced 10,000 kicks once,
#  but I fear the man who has practiced one kick 10,000 times." - Bruce Lee
# ==============================================================================

set -euo pipefail
trap cleanup EXIT INT TERM

# --- CONFIGURATION ---
readonly APP_NAME="wayclick"
readonly BASE_DIR="$HOME/contained_apps/uv/$APP_NAME"
readonly VENV_DIR="$BASE_DIR/.venv"
readonly RUNNER_SCRIPT="$BASE_DIR/runner.py"
readonly CONFIG_DIR="$HOME/.config/wayclick"

# --- ANSI COLORS ---
readonly C_RED=$'\033[1;31m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_CYAN=$'\033[1;36m'
readonly C_YELLOW=$'\033[1;33m'
readonly C_DIM=$'\033[2m'
readonly C_RESET=$'\033[0m'

cleanup() {
    tput cnorm 2>/dev/null || true
}

# --- CHECKS & TOGGLE LOGIC ---

# 0. Root Check (Safety)
if [[ $EUID -eq 0 ]]; then
    printf "%b[CRITICAL]%b Do not run this script as root. Run as normal user.\n" "${C_RED}" "${C_RESET}"
    exit 1
fi

# 1. Toggle Logic (Fixed)
# Check if the runner is active. 
# We use 'if' directly so the script doesn't crash if pgrep finds nothing.
if pgrep -f "$RUNNER_SCRIPT" >/dev/null; then
    printf "%b[TOGGLE]%b Stopping active instance...\n" "${C_YELLOW}" "${C_RESET}"
    
    # Notify user
    command -v notify-send >/dev/null && notify-send --app-name="WayClick" "WayClick Elite" "Disabled"
    
    # Kill the process
    pkill -f "$RUNNER_SCRIPT"
    
    # Wait loop: Ensure process is dead before exiting (Fixes audio device race condition)
    while pgrep -f "$RUNNER_SCRIPT" >/dev/null; do
        sleep 0.1
    done
    
    exit 0
fi

# 2. Interactive Mode Detection
if [[ -t 0 ]]; then
    INTERACTIVE=true
else
    INTERACTIVE=false
fi

notify_user() {
    # Send notification if possible (for keybind feedback)
    if command -v notify-send >/dev/null; then
        notify-send --app-name="WayClick" "WayClick Elite" "$1"
    fi
}

# 3. Dependency Check & Auto-Install
# We need 'uv' for the environment and 'libnotify' for user feedback
NEEDED_DEPS=""
if ! command -v uv &>/dev/null; then NEEDED_DEPS="$NEEDED_DEPS uv"; fi
if ! command -v notify-send &>/dev/null; then NEEDED_DEPS="$NEEDED_DEPS libnotify"; fi

if [[ -n "$NEEDED_DEPS" ]]; then
    if $INTERACTIVE; then
        # BANNER (Only show in terminal)
        clear
        printf "%b
╔══════════════════════════════════════════════════════════════╗
║  %bWAYCLICK ELITE%b                                            ║
║  %bHotplug • User Mode • Native AVX2 • Contained%b             ║
╚══════════════════════════════════════════════════════════════╝
%b" "${C_CYAN}" "${C_GREEN}" "${C_CYAN}" "${C_DIM}" "${C_CYAN}" "${C_RESET}"

        printf "%b[SETUP]%b Missing system dependencies:%b%s%b\n" "${C_YELLOW}" "${C_RESET}" "${C_CYAN}" "$NEEDED_DEPS" "${C_RESET}"
        printf "       Requesting sudo to install via pacman...\n"
        
        # Sudo is only used here for pacman. The rest of the script runs as user.
        if sudo pacman -S --needed $NEEDED_DEPS; then
            printf "%b[SUCCESS]%b Dependencies installed.\n" "${C_GREEN}" "${C_RESET}"
        else
            printf "%b[ERROR]%b Installation failed.\n" "${C_RED}" "${C_RESET}"
            exit 1
        fi
    else
        # If running via keybind and deps are missing, we cannot ask for password.
        notify_user "Missing dependencies ($NEEDED_DEPS). Run in terminal first to install."
        exit 1
    fi
fi

# 4. Group Permission Check (Input)
if ! groups "$USER" | grep -q "\binput\b"; then
    if $INTERACTIVE; then
        printf "%b[PERM]%b User '%s' is not in the 'input' group.\n" "${C_RED}" "${C_RESET}" "$USER"
        read -p "Run 'sudo usermod -aG input $USER'? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo usermod -aG input "$USER"
            printf "%b[INFO]%b Group added. %bLOGOUT REQUIRED%b for changes to apply.\n" "${C_GREEN}" "${C_RESET}" "${C_RED}" "${C_RESET}"
            exit 0
        else
            exit 1
        fi
    else
        notify_user "Permission error: User not in 'input' group. Run in terminal."
        exit 1
    fi
fi

# 5. Sound Files Check
check_sounds() {
    [[ -d "$CONFIG_DIR" ]] || return 1
    for f in enter.wav space.wav key1.wav key3.wav key4.wav; do
        [[ -f "${CONFIG_DIR}/${f}" ]] || return 1
    done
    return 0
}

if ! check_sounds; then
    if $INTERACTIVE; then
        while ! check_sounds; do
            printf "\n%b[ACTION REQUIRED]%b Missing sound files in: %s\n" "${C_YELLOW}" "${C_RESET}" "${CONFIG_DIR}"
            [[ -d "$CONFIG_DIR" ]] || mkdir -p "$CONFIG_DIR"
            printf "       Need: enter.wav, space.wav, key1.wav, key3.wav, key4.wav\n"
            printf "       %bPress Enter to re-scan...%b" "${C_DIM}" "${C_RESET}"
            read -r
        done
        printf "%b[CHECK]%b Sound files verified.\n" "${C_GREEN}" "${C_RESET}"
    else
        notify_user "Missing sound files in ~/.config/wayclick. Run in terminal."
        exit 1
    fi
fi

# --- ENVIRONMENT SETUP (The Elite Part) ---

# Create directory structure
if [[ ! -d "$BASE_DIR" ]]; then
    printf "%b[INIT]%b Creating contained environment: %s\n" "${C_BLUE}" "${C_RESET}" "$BASE_DIR"
    mkdir -p "$BASE_DIR"
fi

# Check if VENV exists
if [[ ! -d "$VENV_DIR" ]]; then
    if ! $INTERACTIVE; then
        notify_user "Environment not built! Run in terminal once to initialize."
        exit 1
    fi
    printf "%b[BUILD]%b Initializing UV environment...\n" "${C_BLUE}" "${C_RESET}"
    uv venv "$VENV_DIR" --python 3.13 --quiet
fi

# Check dependencies. 
MARKER_FILE="$BASE_DIR/.build_marker_v3"

if [[ ! -f "$MARKER_FILE" ]]; then
    if ! $INTERACTIVE; then
        notify_user "First run setup required! Run in terminal to build native extensions."
        exit 1
    fi

    printf "%b[BUILD]%b Compiling dependencies with NATIVE CPU FLAGS (AVX2+)...\n" "${C_YELLOW}" "${C_RESET}"
    printf "       %bThis runs ON THE METAL. No generic binaries allowed.%b\n" "${C_DIM}" "${C_RESET}"
    
    # ---------------------------------------------------------
    # ELITE BUILD FLAGS
    # -march=native: Use all instructions available on THIS CPU
    # -O3: Maximum optimization
    # -fno-plt: Faster dynamic linking calls
    # ---------------------------------------------------------
    export CFLAGS="-march=native -mtune=native -O3 -pipe -fno-plt"
    export CXXFLAGS="-march=native -mtune=native -O3 -pipe -fno-plt"
    
    # Install evdev and pygame-ce from source
    # pygame-ce fixes the 'pkg_resources' warning at the source level.
    uv pip install --python "$VENV_DIR/bin/python" \
        --no-binary :all: \
        --compile-bytecode \
        evdev pygame-ce

    touch "$MARKER_FILE"
    printf "%b[SUCCESS]%b Native build complete.\n" "${C_GREEN}" "${C_RESET}"
fi

# --- PYTHON RUNNER GENERATION ---
# Persistent file for debugging and direct editing.
cat > "$RUNNER_SCRIPT" << 'EOF'
import asyncio
import os
import sys
import signal
import random

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

# === MAPPING ===
# We define the map, but we will convert it to a flat list for O(1) access speed
RAW_KEY_MAP = {
    # Number Row
    1: "key1.wav", 2: "key4.wav", 3: "key3.wav", 4: "key4.wav", 5: "key1.wav", 
    6: "key4.wav", 7: "key3.wav", 8: "key4.wav", 9: "key1.wav", 10: "key4.wav", 
    11: "key3.wav", 12: "key4.wav", 13: "key4.wav", 14: "key1.wav",
    # QWERTY Row
    16: "key4.wav", 17: "key1.wav", 18: "key4.wav", 19: "key3.wav", 20: "key4.wav",
    21: "key1.wav", 22: "key4.wav", 23: "key3.wav", 24: "key4.wav", 25: "key1.wav",
    26: "key4.wav", 27: "key3.wav", 43: "enter.wav",
    # ASDF Row
    30: "key4.wav", 31: "key3.wav", 32: "key4.wav", 33: "key1.wav", 34: "key4.wav",
    35: "key3.wav", 36: "key4.wav", 37: "key1.wav", 38: "key4.wav", 39: "key3.wav",
    40: "enter.wav",
    # ZXCV Row
    44: "key4.wav", 45: "key1.wav", 46: "key4.wav", 47: "key3.wav", 48: "key4.wav",
    49: "key1.wav", 50: "key4.wav",
    # Modifiers
    57: "space.wav", 28: "enter.wav", 29: "key1.wav", 42: "key1.wav", 56: "key1.wav"
}

SOUND_FILES = ["key1.wav", "key3.wav", "key4.wav", "enter.wav", "space.wav"]
DEFAULTS = ["key1.wav", "key3.wav", "key4.wav"]
SOUNDS = {}

print(f"{C_BLUE}[INFO]{C_RESET} Loading assets from {ASSET_DIR}...")

# Load Sounds
for filename in SOUND_FILES:
    path = os.path.join(ASSET_DIR, filename)
    if os.path.exists(path):
        try:
            SOUNDS[filename] = pygame.mixer.Sound(path)
        except pygame.error:
            pass

if not SOUNDS:
    sys.exit("ERROR: No sounds loaded!")

# === OPTIMIZATION: CACHED LIST LOOKUP ===
# Convert Dictionary Map -> Array Index for O(1) access
# Max standard evdev keycode is usually < 256 for standard keyboards, 
# but we allocate enough to be safe.
MAX_KEYCODE = 512 
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

    # Fallback (unmapped keys)
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

# --- EXECUTION ---
printf "%b[RUN]%b Starting engine...\n" "${C_BLUE}" "${C_RESET}"

# Keybind Notification: Enabled
# We only send this if we are NOT in a terminal (keybind mode)
if ! $INTERACTIVE; then
    notify_user "Enabled"
fi

# Execute using the VENV python directly, with -O to remove assertions
"$VENV_DIR/bin/python" -O "$RUNNER_SCRIPT" "$CONFIG_DIR"

printf "\n%b[INFO]%b WayClick stopped.\n" "${C_BLUE}" "${C_RESET}"
