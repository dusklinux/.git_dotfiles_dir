#!/usr/bin/env bash
# ==============================================================================
# WAYCLICK V27 - UNIVERSAL MECHANICAL KEYBOARD SOUND ENGINE
# ==============================================================================
# AUTHOR: Elite Systems Architect  
# TARGET: Arch Linux / Hyprland (Wayland) / UWSM
#
# CHANGELOG V27:
#   - Smart sound detection in ~/.config/wayclick/
#   - MechVibes download support with instructions
#   - ZIP file extraction support
#   - Interactive menu system for sound source selection
#   - Maintains user config as source of truth
#   - Syncs to system directory for service access
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- CONFIGURATION ---
readonly APP_NAME="wayclick"
readonly APP_VERSION="27.0"
readonly INSTALL_DIR="/usr/local/bin"
readonly SYSTEM_ASSET_DIR="/usr/local/share/${APP_NAME}"
readonly SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"

# MechVibes recommended sound pack
readonly MECHVIBES_RECOMMENDED_URL="https://mechvibes.com/sound-packs/custom-sound-pack-1203000000083/"
readonly MECHVIBES_PACK_NAME="Apex Pro TKL v2 (Akira)"

# --- COLORS (readonly) ---
readonly RED=$'\033[1;31m'
readonly GREEN=$'\033[1;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[1;34m'
readonly MAGENTA=$'\033[1;35m'
readonly CYAN=$'\033[1;36m'
readonly WHITE=$'\033[1;37m'
readonly DIM=$'\033[2m'
readonly NC=$'\033[0m'

# --- LOGGING FUNCTIONS ---
log()     { printf '%b[SETUP]%b %s\n' "${BLUE}" "${NC}" "$*"; }
success() { printf '%b[  ✓  ]%b %s\n' "${GREEN}" "${NC}" "$*"; }
warn()    { printf '%b[WARN]%b %s\n' "${YELLOW}" "${NC}" "$*" >&2; }
error()   { printf '%b[ERROR]%b %s\n' "${RED}" "${NC}" "$*" >&2; exit 1; }
debug()   { [[ "${DEBUG:-0}" == "1" ]] && printf '%b[DEBUG]%b %s\n' "${MAGENTA}" "${NC}" "$*" >&2 || true; }
info()    { printf '%b[INFO]%b %s\n' "${CYAN}" "${NC}" "$*"; }

# --- CLEANUP TRAP ---
declare -a CLEANUP_ACTIONS=()
TEMP_DIR=""

cleanup() {
    local exit_code=$?
    set +e
    
    # Clean up temp directory if exists
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    
    if [[ $exit_code -ne 0 ]]; then
        warn "Installation failed! Rolling back changes..."
        for action in "${CLEANUP_ACTIONS[@]:-}"; do
            debug "Cleanup: $action"
            eval "$action" 2>/dev/null || true
        done
    fi
    
    exit $exit_code
}
trap cleanup EXIT

register_cleanup() {
    CLEANUP_ACTIONS+=("$1")
}

# --- HELPER FUNCTIONS ---
command_exists() {
    command -v "$1" &>/dev/null
}

count_files() {
    local pattern="$1"
    local -a files
    shopt -s nullglob
    files=($pattern)
    shopt -u nullglob
    echo "${#files[@]}"
}

list_files() {
    local pattern="$1"
    local -a files
    shopt -s nullglob
    files=($pattern)
    shopt -u nullglob
    printf '%s\n' "${files[@]}"
}

copy_wav_files() {
    local src_dir="$1"
    local dest_dir="$2"
    local -a files
    
    shopt -s nullglob
    files=("${src_dir}"/*.wav)
    shopt -u nullglob
    
    if [[ ${#files[@]} -eq 0 ]]; then
        return 1
    fi
    
    cp -- "${files[@]}" "$dest_dir/"
    echo "${#files[@]}"
}

run_as_user() {
    local user="$1"
    local uid="$2"
    shift 2
    
    sudo -u "$user" \
        XDG_RUNTIME_DIR="/run/user/$uid" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
        "$@"
}

print_separator() {
    echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
}

print_header() {
    local title="$1"
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}║${NC} %-62s ${CYAN}║${NC}\n" "$title"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ==============================================================================
# 1. PRE-FLIGHT CHECKS
# ==============================================================================
print_header "🎹 WAYCLICK v${APP_VERSION} INSTALLER"

# Bash version check
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    error "Bash 4.0+ required. Current: ${BASH_VERSION}"
fi

# Root check - prompt for sudo if not root
if [[ "${EUID}" -ne 0 ]]; then
    warn "This script requires root privileges."
    log "Requesting sudo access..."
    exec sudo "$0" "$@"
fi

# Detect the real user
REAL_USER="${SUDO_USER:-}"
REAL_UID="${SUDO_UID:-}"

if [[ -z "$REAL_USER" || -z "$REAL_UID" ]]; then
    error "Could not detect real user. Run via 'sudo', not from root shell."
fi

if ! id "$REAL_USER" &>/dev/null; then
    error "User '$REAL_USER' does not exist."
fi

if ! [[ "$REAL_UID" =~ ^[0-9]+$ ]]; then
    error "Invalid UID: $REAL_UID"
fi

REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
    error "Could not determine home directory for $REAL_USER"
fi

# User config directory (source of truth for sounds)
USER_CONFIG_DIR="${REAL_HOME}/.config/${APP_NAME}"

log "Installing for user: ${CYAN}$REAL_USER${NC} (UID: $REAL_UID)"
log "Home directory: $REAL_HOME"
log "User config: $USER_CONFIG_DIR"

# Check required system tools
for cmd in python3 systemctl; do
    if ! command_exists "$cmd"; then
        error "Required command '$cmd' not found."
    fi
done

# Detect audio server
AUDIO_SERVER="unknown"
if run_as_user "$REAL_USER" "$REAL_UID" systemctl --user is-active pipewire-pulse.service &>/dev/null; then
    AUDIO_SERVER="pipewire"
    log "Detected audio server: ${GREEN}PipeWire${NC}"
elif run_as_user "$REAL_USER" "$REAL_UID" systemctl --user is-active pulseaudio.service &>/dev/null; then
    AUDIO_SERVER="pulseaudio"
    log "Detected audio server: ${GREEN}PulseAudio${NC}"
else
    warn "Could not detect running audio server. Will attempt generic configuration."
fi

# ==============================================================================
# 2. CLEANUP OLD INSTALLATIONS
# ==============================================================================
log "Cleaning up previous installations..."

if systemctl is-active "${APP_NAME}.service" &>/dev/null; then
    systemctl stop "${APP_NAME}.service" || warn "Failed to stop service"
fi

if systemctl is-enabled "${APP_NAME}.service" &>/dev/null; then
    systemctl disable "${APP_NAME}.service" || warn "Failed to disable service"
fi

# Clean up old user-level services
for old_service in wayvibes wayclick; do
    if run_as_user "$REAL_USER" "$REAL_UID" systemctl --user is-active "${old_service}.service" &>/dev/null; then
        run_as_user "$REAL_USER" "$REAL_UID" systemctl --user stop "${old_service}.service" || true
    fi
    if run_as_user "$REAL_USER" "$REAL_UID" systemctl --user is-enabled "${old_service}.service" &>/dev/null; then
        run_as_user "$REAL_USER" "$REAL_UID" systemctl --user disable "${old_service}.service" || true
    fi
done

# Kill running instances
if pgrep -x "$APP_NAME" &>/dev/null; then
    pkill -x "$APP_NAME" || warn "Could not kill existing $APP_NAME processes"
    sleep 1
fi

# Create directories
mkdir -p "$USER_CONFIG_DIR"
chown "$REAL_USER:$REAL_USER" "$USER_CONFIG_DIR"
chmod 755 "$USER_CONFIG_DIR"

mkdir -p "$SYSTEM_ASSET_DIR"
register_cleanup "rm -rf '$SYSTEM_ASSET_DIR'"

success "Cleanup complete"

# ==============================================================================
# 3. DEPENDENCY RESOLUTION
# ==============================================================================
log "Checking system dependencies..."

install_pkg() {
    local pkg="$1"
    local is_aur="${2:-false}"
    
    if pacman -Qi "$pkg" &>/dev/null; then
        debug "Package '$pkg' already installed"
        return 0
    fi
    
    warn "Package '$pkg' not found. Installing..."
    
    if [[ "$is_aur" == "true" ]]; then
        local aur_helper=""
        
        for helper in paru yay pikaur; do
            if run_as_user "$REAL_USER" "$REAL_UID" command -v "$helper" &>/dev/null; then
                aur_helper="$helper"
                break
            fi
        done
        
        if [[ -n "$aur_helper" ]]; then
            log "Using $aur_helper to install $pkg..."
            run_as_user "$REAL_USER" "$REAL_UID" "$aur_helper" -S --needed --noconfirm "$pkg" \
                || error "Failed to install $pkg via $aur_helper"
        else
            error "AUR package '$pkg' required but no AUR helper found. Install paru or yay first."
        fi
    else
        pacman -S --needed --noconfirm "$pkg" \
            || error "Failed to install $pkg"
    fi
    
    success "Installed $pkg"
}

install_pkg "python" false
install_pkg "python-evdev" false
install_pkg "libpulse" false
install_pkg "unzip" false        # For extracting sound packs

if ! command_exists paplay; then
    error "paplay not found after installing libpulse. Check your installation."
fi

success "All dependencies satisfied"

# ==============================================================================
# 4. SOUNDPACK ACQUISITION (SMART DETECTION)
# ==============================================================================
print_header "🔊 SOUND CONFIGURATION"

# --- Helper Functions for Sound Management ---

show_existing_sounds() {
    local dir="$1"
    local -a files
    
    shopt -s nullglob
    files=("${dir}"/*.wav)
    shopt -u nullglob
    
    echo -e "${DIM}Found files:${NC}"
    for f in "${files[@]}"; do
        local basename=$(basename "$f")
        local size=$(stat -c%s "$f" 2>/dev/null || echo "?")
        printf "  ${GREEN}✓${NC} %-20s ${DIM}(%s bytes)${NC}\n" "$basename" "$size"
    done
}

extract_soundpack_zip() {
    local zip_file="$1"
    local dest_dir="$2"
    
    # Create temp directory for extraction
    TEMP_DIR=$(mktemp -d -t wayclick-extract-XXXXXX)
    
    log "Extracting: $(basename "$zip_file")"
    
    if command_exists unzip; then
        unzip -q "$zip_file" -d "$TEMP_DIR" || error "Failed to extract ZIP file"
    elif command_exists bsdtar; then
        bsdtar -xf "$zip_file" -C "$TEMP_DIR" || error "Failed to extract ZIP file"
    else
        error "No extraction utility found. Install unzip: sudo pacman -S unzip"
    fi
    
    # Find directory containing WAV files (might be nested)
    local wav_source=""
    local wav_count=0
    
    # First check the temp dir itself
    local count=$(count_files "${TEMP_DIR}/*.wav")
    if [[ $count -gt 0 ]]; then
        wav_source="$TEMP_DIR"
        wav_count=$count
    else
        # Search subdirectories
        while IFS= read -r -d '' subdir; do
            count=$(count_files "${subdir}/*.wav")
            if [[ $count -gt 0 ]]; then
                wav_source="$subdir"
                wav_count=$count
                break
            fi
        done < <(find "$TEMP_DIR" -mindepth 1 -maxdepth 3 -type d -print0 2>/dev/null)
    fi
    
    # Check for OGG files if no WAV files found
    if [[ $wav_count -eq 0 ]]; then
        local ogg_count=$(find "$TEMP_DIR" -type f \( -name "*.ogg" -o -name "*.OGG" \) 2>/dev/null | wc -l)
        if [[ $ogg_count -gt 0 ]]; then
            rm -rf "$TEMP_DIR"
            TEMP_DIR=""
            warn "This sound pack contains OGG files ($ogg_count found), not WAV files."
            warn "WayClick only supports WAV format (.wav files)."
            warn "Please download a sound pack that contains WAV files instead."
            return 1
        fi
        
        rm -rf "$TEMP_DIR"
        TEMP_DIR=""
        error "No WAV files found in the ZIP archive"
    fi
    
    log "Found $wav_count WAV files in: $(basename "$wav_source")"
    
    # Copy WAV files to destination
    copy_wav_files "$wav_source" "$dest_dir"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    TEMP_DIR=""
    
    success "Extracted $wav_count sound files"
    return 0
}

import_from_path() {
    local src_path="$1"
    local dest_dir="$2"
    
    # Expand tilde
    src_path="${src_path/#\~/$REAL_HOME}"
    
    # Remove trailing slash
    src_path="${src_path%/}"
    
    if [[ ! -e "$src_path" ]]; then
        warn "Path does not exist: $src_path"
        return 1
    fi
    
    if [[ -f "$src_path" ]]; then
        # It's a file - check if it's a ZIP
        if [[ "$src_path" == *.zip || "$src_path" == *.ZIP ]]; then
            extract_soundpack_zip "$src_path" "$dest_dir"
            return $?
        else
            warn "File is not a ZIP archive: $src_path"
            return 1
        fi
    elif [[ -d "$src_path" ]]; then
        # It's a directory - look for WAV files
        local count=$(count_files "${src_path}/*.wav")
        
        if [[ $count -eq 0 ]]; then
            # Check one level deeper (for extracted zips like apex-pro-tkl-v2_Akira/)
            local -a subdirs
            shopt -s nullglob
            subdirs=("${src_path}"/*/)
            shopt -u nullglob
            
            for subdir in "${subdirs[@]}"; do
                count=$(count_files "${subdir}*.wav")
                if [[ $count -gt 0 ]]; then
                    src_path="${subdir%/}"
                    break
                fi
            done
        fi
        
        count=$(count_files "${src_path}/*.wav")
        if [[ $count -eq 0 ]]; then
            # Check for OGG files
            local ogg_count=$(find "$src_path" -maxdepth 2 -type f \( -name "*.ogg" -o -name "*.OGG" \) 2>/dev/null | wc -l)
            if [[ $ogg_count -gt 0 ]]; then
                warn "This folder contains OGG files ($ogg_count found), not WAV files."
                warn "WayClick only supports WAV format (.wav files)."
                warn "Please use a sound pack that contains WAV files instead."
                return 1
            fi
            
            warn "No WAV files found in directory: $src_path"
            return 1
        fi
        
        log "Found $count WAV files in: $src_path"
        copy_wav_files "$src_path" "$dest_dir"
        success "Imported $count sound files"
        return 0
    fi
    
    warn "Invalid path type: $src_path"
    return 1
}

show_mechvibes_instructions() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${WHITE}📥 MECHVIBES SOUND PACK DOWNLOAD${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  MechVibes offers high-quality mechanical keyboard sound packs."
    echo -e "  You need to download manually from their website."
    echo ""
    echo -e "  ${WHITE}Recommended Pack:${NC} ${YELLOW}${MECHVIBES_PACK_NAME}${NC}"
    echo ""
    echo -e "  ${WHITE}URL:${NC}"
    echo -e "  ${CYAN}${MECHVIBES_RECOMMENDED_URL}${NC}"
    echo ""
    print_separator
    echo ""
    echo -e "  ${WHITE}Instructions:${NC}"
    echo -e "  ${DIM}1.${NC} Open the URL above in your web browser"
    echo -e "  ${DIM}2.${NC} Click the ${GREEN}Download${NC} button on the page"
    echo -e "  ${DIM}3.${NC} Save the ZIP file (e.g., to ~/Downloads)"
    echo -e "  ${DIM}4.${NC} Enter the path to the ZIP file below"
    echo ""
    echo -e "  ${RED}⚠ Important:${NC} Sound packs must contain ${WHITE}.wav${NC} files."
    echo -e "    ${DIM}OGG files (.ogg) are NOT supported.${NC}"
    echo ""
    echo -e "  ${DIM}Tip: You can also browse other packs at:${NC}"
    echo -e "  ${DIM}https://mechvibes.com/sound-packs/${NC}"
    echo ""
    print_separator
    echo ""
}

generate_synthetic_sounds() {
    local dest_dir="$1"
    
    log "Generating high-quality synthetic mechanical keyboard sounds..."
    
    export ASSET_DIR="$dest_dir"
    
    python3 << 'PYTHON_SYNTH'
import wave
import struct
import math
import random
import os
import sys

ASSET_DIR = os.environ.get('ASSET_DIR', '/usr/local/share/wayclick')

def generate_thock(filename, freq_base=180, duration_ms=75, body_mix=0.75, variation=0):
    """Generate a realistic mechanical key thock sound."""
    sample_rate = 44100
    num_samples = int(sample_rate * (duration_ms / 1000.0))
    
    filepath = os.path.join(ASSET_DIR, filename)
    
    # Add slight random variation
    freq_base += variation * random.randint(-15, 15)
    
    with wave.open(filepath, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        
        data = bytearray()
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            
            # Exponentially decaying frequency for "thock" character
            freq = freq_base * math.exp(-t * 25.0)
            
            # Main body (sine wave)
            body = math.sin(2.0 * math.pi * freq * t)
            
            # Add harmonics for richness
            harmonic1 = 0.3 * math.sin(4.0 * math.pi * freq * t)
            harmonic2 = 0.15 * math.sin(6.0 * math.pi * freq * t)
            
            # Filtered noise for texture
            noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 40.0)
            
            # Attack/decay envelope
            if i < 80:
                env = (i / 80.0) ** 0.5
            else:
                env = math.exp(-(i - 80) / 600.0)
            
            # Mix components
            sample = (body_mix * (body + harmonic1 + harmonic2) + (1 - body_mix) * noise) * env
            
            # Soft clipping for warmth
            sample = math.tanh(sample * 1.2)
            
            # Convert to 16-bit signed integer
            val = int(sample * 26000)
            val = max(-32768, min(32767, val))
            data.extend(struct.pack('<h', val))
        
        w.writeframes(bytes(data))
    
    return filepath

print("  Generating key sounds...", flush=True)

# Generic key sounds with variations
for i in range(1, 8):
    generate_thock(f"key{i}.wav", freq_base=180, duration_ms=70, body_mix=0.75, variation=1)
    print(f"    ✓ key{i}.wav", flush=True)

# Enter: deeper, longer thock
generate_thock("enter.wav", freq_base=140, duration_ms=100, body_mix=0.85)
print("    ✓ enter.wav", flush=True)

# Space: mid-range, slightly longer
generate_thock("space.wav", freq_base=160, duration_ms=90, body_mix=0.80)
print("    ✓ space.wav", flush=True)

# Backspace: slightly higher pitch, snappier
generate_thock("backspace.wav", freq_base=200, duration_ms=65, body_mix=0.70)
print("    ✓ backspace.wav", flush=True)

print(f"\n  Generated sounds in {ASSET_DIR}", flush=True)
PYTHON_SYNTH

    local count=$(count_files "${dest_dir}/*.wav")
    if [[ $count -gt 0 ]]; then
        success "Generated $count synthetic sound files"
        return 0
    else
        error "Failed to generate synthetic sounds"
    fi
}

sync_sounds_to_system() {
    local source_dir="$1"
    local count=$(count_files "${source_dir}/*.wav")
    
    if [[ $count -eq 0 ]]; then
        error "No sound files to sync from: $source_dir"
    fi
    
    # Clear system directory
    rm -f "${SYSTEM_ASSET_DIR}"/*.wav 2>/dev/null || true
    
    # Copy files
    copy_wav_files "$source_dir" "$SYSTEM_ASSET_DIR"
    
    # Set permissions
    chmod 644 "${SYSTEM_ASSET_DIR}"/*.wav
    chown root:root "${SYSTEM_ASSET_DIR}"/*.wav
    
    success "Synced $count sounds to system directory"
}

# --- Main Sound Selection Logic ---

SOUND_SOURCE=""
EXISTING_COUNT=$(count_files "${USER_CONFIG_DIR}/*.wav")

if [[ $EXISTING_COUNT -gt 0 ]]; then
    # Found existing sounds in user config
    echo -e "${GREEN}Found $EXISTING_COUNT existing sound files in:${NC}"
    echo -e "${CYAN}~/.config/${APP_NAME}/${NC}"
    echo ""
    show_existing_sounds "$USER_CONFIG_DIR"
    echo ""
    print_separator
    echo ""
    echo -e "${WHITE}What would you like to do?${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} Use existing sounds ${DIM}(recommended)${NC}"
    echo -e "  ${YELLOW}[2]${NC} Download new sounds from MechVibes"
    echo -e "  ${BLUE}[3]${NC} Import from custom path ${DIM}(folder or ZIP file)${NC}"
    echo -e "  ${MAGENTA}[4]${NC} Generate synthetic sounds"
    echo ""
    
    while true; do
        read -rp "Enter choice [1-4]: " choice
        case "$choice" in
            1)
                SOUND_SOURCE="existing"
                log "Using existing sounds from ~/.config/${APP_NAME}/"
                break
                ;;
            2)
                SOUND_SOURCE="mechvibes"
                break
                ;;
            3)
                SOUND_SOURCE="custom"
                break
                ;;
            4)
                SOUND_SOURCE="synthetic"
                break
                ;;
            *)
                warn "Invalid choice. Please enter 1, 2, 3, or 4."
                ;;
        esac
    done
else
    # No existing sounds
    echo -e "${YELLOW}No sound files found in ~/.config/${APP_NAME}/${NC}"
    echo ""
    print_separator
    echo ""
    echo -e "${WHITE}Choose your sound source:${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} Download from MechVibes ${DIM}(recommended - high quality)${NC}"
    echo -e "  ${BLUE}[2]${NC} Import from custom path ${DIM}(folder or ZIP file)${NC}"
    echo -e "  ${MAGENTA}[3]${NC} Generate synthetic sounds ${DIM}(instant, no download)${NC}"
    echo ""
    
    while true; do
        read -rp "Enter choice [1-3]: " choice
        case "$choice" in
            1)
                SOUND_SOURCE="mechvibes"
                break
                ;;
            2)
                SOUND_SOURCE="custom"
                break
                ;;
            3)
                SOUND_SOURCE="synthetic"
                break
                ;;
            *)
                warn "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
fi

# --- Execute Sound Source Selection ---

case "$SOUND_SOURCE" in
    existing)
        # Already have sounds, nothing to do
        success "Using existing sounds"
        ;;
        
    mechvibes)
        # Clear existing user config sounds
        rm -f "${USER_CONFIG_DIR}"/*.wav 2>/dev/null || true
        
        show_mechvibes_instructions
        
        while true; do
            read -rp "Path to downloaded ZIP or folder (or 'q' to quit): " user_path
            
            if [[ "$user_path" == "q" || "$user_path" == "Q" ]]; then
                echo ""
                warn "Download cancelled. Falling back to synthetic sounds..."
                generate_synthetic_sounds "$USER_CONFIG_DIR"
                chown -R "$REAL_USER:$REAL_USER" "$USER_CONFIG_DIR"
                break
            fi
            
            if import_from_path "$user_path" "$USER_CONFIG_DIR"; then
                chown -R "$REAL_USER:$REAL_USER" "$USER_CONFIG_DIR"
                break
            else
                echo ""
                warn "Failed to import from that path. Please try again."
                echo ""
            fi
        done
        ;;
        
    custom)
        # Clear existing user config sounds
        rm -f "${USER_CONFIG_DIR}"/*.wav 2>/dev/null || true
        
        echo ""
        echo -e "${WHITE}Enter the path to your sounds:${NC}"
        echo -e "${DIM}  - Can be a folder containing .wav files${NC}"
        echo -e "${DIM}  - Can be a .zip file (will be extracted)${NC}"
        echo -e "${DIM}  - Use ~ for home directory${NC}"
        echo ""
        echo -e "  ${RED}⚠ Important:${NC} Sound files must be ${WHITE}.wav${NC} format."
        echo -e "    ${DIM}OGG files (.ogg) are NOT supported.${NC}"
        echo ""
        
        while true; do
            read -rp "Path: " user_path
            
            if [[ -z "$user_path" ]]; then
                warn "No path entered. Falling back to synthetic sounds..."
                generate_synthetic_sounds "$USER_CONFIG_DIR"
                chown -R "$REAL_USER:$REAL_USER" "$USER_CONFIG_DIR"
                break
            fi
            
            if import_from_path "$user_path" "$USER_CONFIG_DIR"; then
                chown -R "$REAL_USER:$REAL_USER" "$USER_CONFIG_DIR"
                break
            else
                echo ""
                warn "Failed to import from that path. Please try again."
                echo ""
            fi
        done
        ;;
        
    synthetic)
        # Clear existing user config sounds
        rm -f "${USER_CONFIG_DIR}"/*.wav 2>/dev/null || true
        
        generate_synthetic_sounds "$USER_CONFIG_DIR"
        chown -R "$REAL_USER:$REAL_USER" "$USER_CONFIG_DIR"
        ;;
esac

# --- Sync to System Directory ---
echo ""
log "Syncing sounds to system directory..."
sync_sounds_to_system "$USER_CONFIG_DIR"

# Show final sound inventory
echo ""
log "Sound files installed:"
show_existing_sounds "$SYSTEM_ASSET_DIR"

# ==============================================================================
# 5. INSTALL PYTHON ENGINE
# ==============================================================================
print_header "🔧 INSTALLING ENGINE"

cat > "${INSTALL_DIR}/${APP_NAME}" << 'PYTHON_ENGINE'
#!/usr/bin/env python3
"""
WayClick - Mechanical Keyboard Sound Engine
Listens for keyboard events and plays corresponding sounds.
"""

import asyncio
import glob
import os
import random
import subprocess
import sys
import signal
import time
from pathlib import Path
from typing import Optional, List, Dict, Set
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor

try:
    import evdev
    from evdev import ecodes
except ImportError:
    print("Error: python-evdev not installed. Run: sudo pacman -S python-evdev")
    sys.exit(1)

# ==============================================================================
# CONFIGURATION - Injected during installation
# ==============================================================================
TARGET_USER = "@@TARGET_USER@@"
TARGET_UID = "@@TARGET_UID@@"
ASSET_DIR = "@@ASSET_DIR@@"

# Runtime configuration
MAX_CONCURRENT_SOUNDS = 8
SOUND_COOLDOWN_MS = 15
DEVICE_RESCAN_INTERVAL = 5.0

# ==============================================================================
# AUDIO BACKEND
# ==============================================================================
@dataclass
class AudioConfig:
    """Audio server configuration."""
    pulse_socket: str
    runtime_dir: str
    
    @classmethod
    def detect(cls) -> 'AudioConfig':
        runtime_dir = f"/run/user/{TARGET_UID}"
        pipewire_socket = f"{runtime_dir}/pulse/native"
        return cls(pulse_socket=pipewire_socket, runtime_dir=runtime_dir)


class SoundPlayer:
    """Non-blocking sound player with rate limiting."""
    
    def __init__(self, audio_config: AudioConfig):
        self.config = audio_config
        self.executor = ThreadPoolExecutor(max_workers=MAX_CONCURRENT_SOUNDS)
        self.active_sounds: Set[asyncio.Future] = set()
        self.last_play_time = 0.0
        self._shutdown = False
    
    def play(self, sound_file: str) -> None:
        if self._shutdown or not sound_file or not os.path.exists(sound_file):
            return
        
        current_time = time.monotonic() * 1000
        if current_time - self.last_play_time < SOUND_COOLDOWN_MS:
            return
        self.last_play_time = current_time
        
        self._cleanup_finished()
        if len(self.active_sounds) >= MAX_CONCURRENT_SOUNDS:
            return
        
        future = self.executor.submit(self._play_sync, sound_file)
        self.active_sounds.add(future)
    
    def _play_sync(self, sound_file: str) -> None:
        try:
            cmd = [
                "runuser", "-u", TARGET_USER, "--",
                "paplay",
                f"--server={self.config.pulse_socket}",
                "--latency-msec=10",
                sound_file
            ]
            
            env = os.environ.copy()
            env["XDG_RUNTIME_DIR"] = self.config.runtime_dir
            
            subprocess.run(
                cmd, env=env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=2.0
            )
        except Exception:
            pass
    
    def _cleanup_finished(self) -> None:
        self.active_sounds = {f for f in self.active_sounds if not f.done()}
    
    def shutdown(self) -> None:
        self._shutdown = True
        self.executor.shutdown(wait=False, cancel_futures=True)


# ==============================================================================
# SOUND MAPPING
# ==============================================================================
class SoundMapper:
    """Maps key codes to sound files."""
    
    def __init__(self, asset_dir: str):
        self.asset_dir = Path(asset_dir)
        self.sounds: Dict[str, List[str]] = {}
        self._load_sounds()
    
    def _load_sounds(self) -> None:
        generic = sorted(glob.glob(str(self.asset_dir / "key*.wav")))
        
        if not generic:
            generic = sorted(glob.glob(str(self.asset_dir / "*.wav")))
        
        self.sounds["GENERIC"] = generic
        
        for key in ["enter", "space", "backspace"]:
            specific = self.asset_dir / f"{key}.wav"
            if specific.exists():
                self.sounds[key.upper()] = [str(specific)]
            elif generic:
                self.sounds[key.upper()] = [generic[0]]
            else:
                self.sounds[key.upper()] = []
    
    def get_sound(self, key_name: str) -> Optional[str]:
        sounds = self.sounds.get(key_name, self.sounds.get("GENERIC", []))
        if not sounds:
            return None
        return random.choice(sounds)


# ==============================================================================
# KEYBOARD HANDLER
# ==============================================================================
class KeyboardHandler:
    """Handles events from a single keyboard device."""
    
    SPECIAL_KEYS = {
        ecodes.KEY_ENTER: "ENTER",
        ecodes.KEY_KPENTER: "ENTER",
        ecodes.KEY_SPACE: "SPACE",
        ecodes.KEY_BACKSPACE: "BACKSPACE",
    }
    
    def __init__(self, device: evdev.InputDevice, sound_mapper: SoundMapper, player: SoundPlayer):
        self.device = device
        self.mapper = sound_mapper
        self.player = player
        self._active = True
    
    async def run(self) -> None:
        try:
            async for event in self.device.async_read_loop():
                if not self._active:
                    break
                    
                if event.type == ecodes.EV_KEY and event.value == 1:
                    self._handle_keypress(event.code)
                    
        except (OSError, IOError) as e:
            print(f"Device disconnected: {self.device.name}")
        finally:
            try:
                self.device.close()
            except Exception:
                pass
    
    def _handle_keypress(self, code: int) -> None:
        key_type = self.SPECIAL_KEYS.get(code, "GENERIC")
        sound = self.mapper.get_sound(key_type)
        if sound:
            self.player.play(sound)
    
    def stop(self) -> None:
        self._active = False


# ==============================================================================
# DEVICE MANAGER
# ==============================================================================
class DeviceManager:
    """Manages keyboard device discovery and hot-plug."""
    
    def __init__(self, sound_mapper: SoundMapper, player: SoundPlayer):
        self.mapper = sound_mapper
        self.player = player
        self.handlers: Dict[str, KeyboardHandler] = {}
        self._shutdown = asyncio.Event()
    
    def _is_keyboard(self, device: evdev.InputDevice) -> bool:
        try:
            caps = device.capabilities()
            if ecodes.EV_KEY not in caps:
                return False
            
            keys = caps[ecodes.EV_KEY]
            keyboard_keys = [ecodes.KEY_A, ecodes.KEY_Z, ecodes.KEY_ENTER, ecodes.KEY_SPACE]
            return any(k in keys for k in keyboard_keys)
        except Exception:
            return False
    
    def _discover_keyboards(self) -> List[evdev.InputDevice]:
        keyboards = []
        try:
            for path in evdev.list_devices():
                try:
                    device = evdev.InputDevice(path)
                    if self._is_keyboard(device):
                        keyboards.append(device)
                except (PermissionError, OSError):
                    continue
        except Exception as e:
            print(f"Device discovery error: {e}")
        return keyboards
    
    async def run(self) -> None:
        print("─" * 50)
        print("WayClick Engine Started")
        print(f"Target User: {TARGET_USER} (UID: {TARGET_UID})")
        print(f"Asset Directory: {ASSET_DIR}")
        print(f"Generic Sounds: {len(self.mapper.sounds.get('GENERIC', []))}")
        print("─" * 50)
        
        while not self._shutdown.is_set():
            keyboards = self._discover_keyboards()
            
            for device in keyboards:
                if device.path not in self.handlers:
                    print(f"Attached: {device.name}")
                    handler = KeyboardHandler(device, self.mapper, self.player)
                    self.handlers[device.path] = handler
                    asyncio.create_task(handler.run())
            
            active_paths = {d.path for d in keyboards}
            for path in list(self.handlers.keys()):
                if path not in active_paths:
                    print(f"Detached: {path}")
                    del self.handlers[path]
            
            if not self.handlers:
                print("Warning: No keyboards detected")
            
            try:
                await asyncio.wait_for(
                    self._shutdown.wait(),
                    timeout=DEVICE_RESCAN_INTERVAL
                )
            except asyncio.TimeoutError:
                pass
    
    def shutdown(self) -> None:
        self._shutdown.set()
        for handler in self.handlers.values():
            handler.stop()


# ==============================================================================
# MAIN
# ==============================================================================
def main() -> int:
    if os.geteuid() != 0:
        print("Error: Must run as root for input device access")
        return 1
    
    audio_config = AudioConfig.detect()
    if not os.path.exists(audio_config.runtime_dir):
        print(f"Error: User runtime directory not found: {audio_config.runtime_dir}")
        print(f"Is user {TARGET_USER} logged in?")
        return 1
    
    sound_mapper = SoundMapper(ASSET_DIR)
    if not sound_mapper.sounds.get("GENERIC"):
        print(f"Error: No sound files found in {ASSET_DIR}")
        return 1
    
    player = SoundPlayer(audio_config)
    manager = DeviceManager(sound_mapper, player)
    
    def signal_handler(sig, frame):
        print("\nShutting down...")
        manager.shutdown()
        player.shutdown()
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        asyncio.run(manager.run())
    except KeyboardInterrupt:
        pass
    finally:
        player.shutdown()
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
PYTHON_ENGINE

# Replace placeholders
sed -i "s|@@TARGET_USER@@|${REAL_USER}|g" "${INSTALL_DIR}/${APP_NAME}"
sed -i "s|@@TARGET_UID@@|${REAL_UID}|g" "${INSTALL_DIR}/${APP_NAME}"
sed -i "s|@@ASSET_DIR@@|${SYSTEM_ASSET_DIR}|g" "${INSTALL_DIR}/${APP_NAME}"

chmod 755 "${INSTALL_DIR}/${APP_NAME}"
chown root:root "${INSTALL_DIR}/${APP_NAME}"

success "Installed engine to ${INSTALL_DIR}/${APP_NAME}"

# ==============================================================================
# 6. CONTROL UTILITY
# ==============================================================================
log "Installing control utility..."

cat > "${INSTALL_DIR}/${APP_NAME}-ctl" << 'CONTROL_SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

readonly APP_NAME="wayclick"
readonly SERVICE="${APP_NAME}.service"
readonly USER_CONFIG_DIR="${HOME}/.config/${APP_NAME}"
readonly SYSTEM_ASSET_DIR="/usr/local/share/${APP_NAME}"

RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[1;36m'
NC=$'\033[0m'

usage() {
    cat << EOF
${CYAN}WayClick Control Utility${NC}

Usage: $(basename "$0") <command>

${CYAN}Service Commands:${NC}
    start       Start the WayClick service
    stop        Stop the WayClick service  
    restart     Restart the WayClick service
    status      Show service status
    logs        Show recent logs (use -f to follow)
    enable      Enable auto-start on boot
    disable     Disable auto-start on boot

${CYAN}Sound Commands:${NC}
    sounds      List installed sounds
    reload      Reload sounds from ~/.config/wayclick/
    test        Run a 5-second sound test

${CYAN}Info:${NC}
    User sounds: ~/.config/${APP_NAME}/
    System sounds: ${SYSTEM_ASSET_DIR}/
EOF
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "${RED}This command requires root.${NC} Use: sudo $(basename "$0") $1"
        exit 1
    fi
}

case "${1:-help}" in
    start)
        require_root start
        systemctl start "$SERVICE"
        echo "${GREEN}✓${NC} WayClick started"
        ;;
    stop)
        require_root stop
        systemctl stop "$SERVICE"
        echo "${GREEN}✓${NC} WayClick stopped"
        ;;
    restart)
        require_root restart
        systemctl restart "$SERVICE"
        echo "${GREEN}✓${NC} WayClick restarted"
        ;;
    status)
        systemctl status "$SERVICE" --no-pager || true
        ;;
    logs)
        if [[ "${2:-}" == "-f" ]]; then
            journalctl -u "$SERVICE" -f
        else
            journalctl -u "$SERVICE" -n 50 --no-pager
        fi
        ;;
    enable)
        require_root enable
        systemctl enable "$SERVICE"
        echo "${GREEN}✓${NC} WayClick enabled for auto-start"
        ;;
    disable)
        require_root disable
        systemctl disable "$SERVICE"
        echo "${GREEN}✓${NC} WayClick disabled"
        ;;
    sounds)
        echo "${CYAN}User sounds (~/.config/${APP_NAME}/):${NC}"
        ls -la "$USER_CONFIG_DIR"/*.wav 2>/dev/null || echo "  (none)"
        echo ""
        echo "${CYAN}System sounds (${SYSTEM_ASSET_DIR}/):${NC}"
        ls -la "$SYSTEM_ASSET_DIR"/*.wav 2>/dev/null || echo "  (none)"
        ;;
    reload)
        require_root reload
        if [[ ! -d "$USER_CONFIG_DIR" ]]; then
            echo "${RED}Error:${NC} User config directory not found: $USER_CONFIG_DIR"
            exit 1
        fi
        count=$(ls -1 "$USER_CONFIG_DIR"/*.wav 2>/dev/null | wc -l)
        if [[ $count -eq 0 ]]; then
            echo "${RED}Error:${NC} No WAV files in $USER_CONFIG_DIR"
            exit 1
        fi
        rm -f "${SYSTEM_ASSET_DIR}"/*.wav
        cp "$USER_CONFIG_DIR"/*.wav "$SYSTEM_ASSET_DIR/"
        chmod 644 "${SYSTEM_ASSET_DIR}"/*.wav
        systemctl restart "$SERVICE"
        echo "${GREEN}✓${NC} Reloaded $count sounds and restarted service"
        ;;
    test)
        require_root test
        echo "Running 5-second test (type to hear sounds)..."
        timeout --signal=SIGINT 5s /usr/local/bin/wayclick || true
        echo "${GREEN}✓${NC} Test complete"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "${RED}Unknown command:${NC} $1"
        echo ""
        usage
        exit 1
        ;;
esac
CONTROL_SCRIPT

chmod 755 "${INSTALL_DIR}/${APP_NAME}-ctl"
success "Installed ${APP_NAME}-ctl utility"

# ==============================================================================
# 7. TEST RUN
# ==============================================================================
echo ""
print_header "🎹 TEST DRIVE (5 seconds)"
echo -e "  ${WHITE}Type on your keyboard to verify sounds are working${NC}"
echo ""
print_separator

if timeout --signal=SIGINT 5s "${INSTALL_DIR}/${APP_NAME}" 2>&1; then
    echo ""
    success "Test completed successfully!"
else
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        echo ""
        success "Test completed"
    else
        warn "Test exited with code $exit_code"
    fi
fi

echo ""

# ==============================================================================
# 8. SYSTEMD SERVICE (OPTIONAL)
# ==============================================================================
print_header "⚙️  SERVICE INSTALLATION"

echo -e "${WHITE}Would you like to install WayClick as a system service?${NC}"
echo ""
echo -e "  ${GREEN}[Y]${NC} Yes - Auto-start on boot ${DIM}(recommended)${NC}"
echo -e "  ${YELLOW}[n]${NC} No  - Run manually when needed"
echo ""

# Clear any pending stdin from the test run
read -t 0.1 -n 10000 discard 2>/dev/null || true

# Read from /dev/tty explicitly to avoid stdin issues after timeout
read -rp "Install service? [Y/n]: " install_service </dev/tty

if [[ "${install_service,,}" == "n" || "${install_service,,}" == "no" ]]; then
    echo ""
    info "Service installation skipped."
    echo ""
    print_separator
    echo ""
    echo -e "${CYAN}To run WayClick for this session only:${NC}"
    echo ""
    echo -e "  ${WHITE}Foreground (see output, Ctrl+C to stop):${NC}"
    echo -e "    ${YELLOW}sudo ${INSTALL_DIR}/${APP_NAME}${NC}"
    echo ""
    echo -e "  ${WHITE}Background (runs silently):${NC}"
    echo -e "    ${YELLOW}sudo ${INSTALL_DIR}/${APP_NAME} &${NC}"
    echo ""
    echo -e "  ${WHITE}Background with disown (persists after terminal close):${NC}"
    echo -e "    ${YELLOW}sudo ${INSTALL_DIR}/${APP_NAME} &${NC}"
    echo -e "    ${YELLOW}disown${NC}"
    echo ""
    echo -e "  ${WHITE}To stop a background instance:${NC}"
    echo -e "    ${YELLOW}sudo pkill -x ${APP_NAME}${NC}"
    echo ""
    print_separator
else
    log "Installing systemd service..."
    
    cat > "${SERVICE_FILE}" << EOF
[Unit]
Description=WayClick Mechanical Keyboard Sound Engine
Documentation=https://github.com/wayclick
After=multi-user.target
After=user@${REAL_UID}.service
Wants=user@${REAL_UID}.service

[Service]
Type=simple
ExecStart=${INSTALL_DIR}/${APP_NAME}
ExecReload=/bin/kill -HUP \$MAINPID

Restart=on-failure
RestartSec=3
StartLimitBurst=5
StartLimitIntervalSec=30

Environment=XDG_RUNTIME_DIR=/run/user/${REAL_UID}
Environment=PULSE_SERVER=unix:/run/user/${REAL_UID}/pulse/native

ProtectSystem=strict
ProtectHome=read-only
PrivateTmp=true
NoNewPrivileges=false
ReadWritePaths=${SYSTEM_ASSET_DIR}

StandardOutput=journal
StandardError=journal
SyslogIdentifier=${APP_NAME}

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "${APP_NAME}.service"
    systemctl start "${APP_NAME}.service"

    sleep 1

    if systemctl is-active "${APP_NAME}.service" &>/dev/null; then
        success "Service is running!"
    else
        warn "Service may not have started correctly"
        systemctl status "${APP_NAME}.service" --no-pager || true
    fi
fi

# ==============================================================================
# 9. FINAL SUMMARY
# ==============================================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║     🎉 WAYCLICK V${APP_VERSION} INSTALLATION COMPLETE!             ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Quick Commands:${NC}"
echo -e "  ${YELLOW}${APP_NAME}-ctl status${NC}       - Check if running (no sudo needed)"
echo -e "  ${YELLOW}${APP_NAME}-ctl sounds${NC}       - List installed sounds"
echo -e "  ${YELLOW}sudo ${APP_NAME}-ctl restart${NC}  - Restart after changes"
echo -e "  ${YELLOW}sudo ${APP_NAME}-ctl reload${NC}   - Reload sounds from ~/.config"
echo ""
echo -e "${CYAN}Sound Locations:${NC}"
echo -e "  ${WHITE}Your sounds:${NC}    ~/.config/${APP_NAME}/"
echo -e "  ${WHITE}System copy:${NC}    ${SYSTEM_ASSET_DIR}/"
echo ""
echo -e "${CYAN}To add new sounds:${NC}"
echo -e "  1. Place .wav files in ${YELLOW}~/.config/${APP_NAME}/${NC}"
echo -e "     ${DIM}(Only .wav format is supported, NOT .ogg)${NC}"
echo -e "  2. Run ${YELLOW}sudo ${APP_NAME}-ctl reload${NC}"
echo ""
echo -e "${CYAN}Logs:${NC} journalctl -u ${APP_NAME} -f"
echo ""
echo -e "${CYAN}Uninstall:${NC}"
echo -e "  sudo systemctl disable --now ${APP_NAME}"
echo -e "  sudo rm -f ${INSTALL_DIR}/${APP_NAME} ${INSTALL_DIR}/${APP_NAME}-ctl"
echo -e "  sudo rm -rf ${SYSTEM_ASSET_DIR}"
echo -e "  sudo rm -f ${SERVICE_FILE}"
echo ""

# Clear cleanup actions since we succeeded
CLEANUP_ACTIONS=()

exit 0
