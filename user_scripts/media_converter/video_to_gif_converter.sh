#!/usr/bin/env bash
#
# hypergif - Arch Linux High-Fidelity Video to GIF Converter
# Optimized for Hyprland/UWSM environments.
#
# Features:
# - Motion Interpolation (30fps -> 60fps) using 'minterpolate' (MCI)
# - Lanczos Upscaling (force 1080p minimum) with Mod-2 safety
# - High-Quality Palette Generation (Global Palette)
# - URL Support (via yt-dlp with explicit container forcing)
# - Automatic Dependency Management (pacman)


# - Web Mode (--low_quality) for smaller, sharable files


# --- 1. Safety & Environment ---
set -euo pipefail

# Direct ANSI codes (no subshells for performance)
readonly C_RESET=$'\033[0m'
readonly C_BOLD=$'\033[1m'
readonly C_BLUE=$'\033[1;34m'
readonly C_GREEN=$'\033[1;32m'
readonly C_YELLOW=$'\033[1;33m'
readonly C_RED=$'\033[1;31m'
readonly C_CYAN=$'\033[1;36m'

# Configuration Defaults
OPT_LOW_QUALITY=0

# Temp directory setup
readonly TMP_DIR="$(mktemp -d -t hypergif.XXXXXX)"
readonly PALETTE="${TMP_DIR}/palette.png"
readonly DL_VIDEO="${TMP_DIR}/video.mp4"

# Cleanup trap (Robust: handles missing dirs and exit codes)
cleanup() {
    rm -rf -- "$TMP_DIR" 2>/dev/null || :
    printf '\033[?25h' >&2  # Restore cursor
}
trap cleanup EXIT

# --- 2. Logging Functions ---
# All logs go to stderr to prevent pollution of stdout capture
log_info()    { printf '%s[INFO]%s %s\n' "$C_BLUE" "$C_RESET" "$*" >&2; }
log_success() { printf '%s[OK]%s   %s\n' "$C_GREEN" "$C_RESET" "$*" >&2; }
log_warn()    { printf '%s[WARN]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
log_err()     { printf '%s[ERR]%s  %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# --- 3. Dependency Check ---
ensure_deps() {
    # Map: [command]="arch_package"
    declare -A deps=(
        [ffmpeg]=ffmpeg
        [bc]=bc
        [yt-dlp]=yt-dlp
        [notify-send]=libnotify
    )

    local missing_pkgs=()
    local cmd

    for cmd in "${!deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_pkgs+=("${deps[$cmd]}")
        fi
    done

    if (( ${#missing_pkgs[@]} )); then
        # Deduplicate and sort
        readarray -t missing_pkgs < <(printf '%s\n' "${missing_pkgs[@]}" | sort -u)

        log_warn "Missing dependencies: ${missing_pkgs[*]}. Installing via pacman..."
        if ! sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}"; then
            log_err "Failed to install dependencies."
        fi
        log_success "Dependencies installed."
    fi
}

# --- 4. Input Handling ---
get_input() {
    local input="${1:-}"

    # Interactive prompt if no argument
    if [[ -z "$input" ]]; then
        printf '%s[?]%s Enter path to video or URL: ' "$C_CYAN" "$C_RESET" >&2
        # -e enables readline (tab completion), -r prevents backslash escaping
        read -e -r input
    fi

    # Trim leading/trailing whitespace
    input="${input#"${input%%[![:space:]]*}"}"
    input="${input%"${input##*[![:space:]]}"}"

    [[ -z "$input" ]] && log_err "No input provided."

    # Handle URL vs file
    if [[ "$input" =~ ^https?:// ]]; then
        log_info "Detected URL. Downloading with yt-dlp..."
        # Remux to mp4 to ensure consistent container
        if yt-dlp -f 'bv*+ba/b' --remux-video mp4 -o "$DL_VIDEO" "$input" --quiet --no-warnings; then
            printf '%s\n' "$DL_VIDEO"
        else
            log_err "Failed to download video."
        fi
    elif [[ -f "$input" ]]; then
        printf '%s\n' "$input"
    else
        log_err "File not found: $input"
    fi
}

# --- 5. Analysis & Conversion ---
process_video() {
    local input_file="$1"
    local output_file="${input_file%.*}.gif"

    # Use timestamped name for downloaded files to avoid overwrites
    [[ "$input_file" == "$DL_VIDEO" ]] && output_file="./$(date +%s)_output.gif"

    log_info "Analyzing source..."

    local src_width src_height src_fps_raw src_fps

    # Probe video metadata (suppress errors, validate later)
    # 2>/dev/null suppresses ffprobe banner/errors, || : ensures no crash on fail
    src_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$input_file" 2>/dev/null) || :
    src_height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$input_file" 2>/dev/null) || :
    src_fps_raw=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$input_file" 2>/dev/null) || :

    # Validate dimensions
    if [[ -z "${src_width:-}" || -z "${src_height:-}" ]]; then
        log_err "Failed to detect video dimensions. Is this a valid video file?"
    fi

    # Parse FPS (handles "30000/1001" fractions and plain numbers)
    # BASH_REMATCH is used to safely extract numerator/denominator
    if [[ "$src_fps_raw" =~ ^([0-9]+)/([0-9]+)$ && "${BASH_REMATCH[2]}" -ne 0 ]]; then
        src_fps=$(bc -l <<< "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}")
    elif [[ "$src_fps_raw" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        src_fps="$src_fps_raw"
    else
        log_warn "Could not determine FPS. Defaulting to 30."
        src_fps=30
    fi

    # Round FPS to integer (LOCALE SAFE)
    # LC_NUMERIC=C prevents crashes if user locale expects commas (e.g., 29,97)
    local fps_int
    fps_int=$(LC_NUMERIC=C printf '%.0f' "$src_fps")

    log_info "Source: ${src_width}x${src_height} @ ${fps_int}fps"

    # --- Build Filter Chains ---
    local filters_base="" filters_interp=""

    if (( OPT_LOW_QUALITY )); then
        # --- LOW QUALITY / WEB MODE ---
        log_info "Mode: Low Quality (Web Optimized)"
        
        # Logic: Use native resolution.
        # No downscaling filters applied.
        log_info "Keeping native resolution."
        
        # Logic: No interpolation. Use native FPS.
        log_info "Skipping motion interpolation for size/speed."
        
    else
        # --- HYPER FIDELITY MODE ---
        log_info "Mode: Hyper-Fidelity (The 'Lamborghini' GIF)"

        # Upscale if below 1080p (-2 ensures even width for codec compatibility)
        if (( src_height < 1080 )); then
            log_warn "Low resolution detected. Upscaling to 1080p (Lanczos)."
            filters_base="scale=-2:1080:flags=lanczos,"
        fi

        # Interpolate if below 50fps
        if (( fps_int < 50 )); then
            log_warn "Low FPS (${fps_int}) detected. Interpolating to 60fps (MCI)."
            log_warn "Note: minterpolate is single-threaded and CPU intensive."
            filters_interp="minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1,"
        else
            log_info "FPS is sufficient (${fps_int}). Keeping native."
        fi
    fi

    # Palette chain: base filters + palettegen (skip interpolation for speed)
    local chain_palette="${filters_base}palettegen=stats_mode=full"

    # Render chain: base + interp (fallback to null filter if empty)
    local chain_render="${filters_base}${filters_interp}"
    chain_render="${chain_render%,}"          # Strip trailing comma
    : "${chain_render:=null}"                 # Default to passthrough if empty

    # --- Pass 1: Generate Palette ---
    log_info "Generating palette (Pass 1/2)..."
    [[ -z "$filters_interp" ]] && log_info "Optimized: Skipping interpolation for palette generation."

    # Added -update 1 to silence image2 muxer warning about single frames
    ffmpeg -hide_banner -loglevel warning -stats \
        -i "$input_file" \
        -vf "$chain_palette" \
        -update 1 \
        -y "$PALETTE"

    # --- Pass 2: Render GIF ---
    log_info "Rendering GIF (Pass 2/2)..."

    # Use native filtergraph syntax to combine chains
    ffmpeg -hide_banner -loglevel warning -stats \
        -i "$input_file" -i "$PALETTE" \
        -lavfi "${chain_render}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
        -y "$output_file"

    printf '\n' >&2
    log_success "Conversion complete!"
    log_info "Saved to: ${C_BOLD}${output_file}${C_RESET}"

    # Desktop notification (if available)
    command -v notify-send &>/dev/null && \
        notify-send "HyperGIF" "Conversion Complete: $output_file" -i video-x-generic
}

# --- 6. Main ---
main() {
    printf '%sHyperGIF%s :: Arch Video Converter\n' "$C_BOLD" "$C_RESET" >&2

    ensure_deps

    local input_arg=""
    
    # Argument Parser
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --low_quality|--low-quality|--web|-w)
                OPT_LOW_QUALITY=1
                shift
                ;;
            -*)
                log_err "Unknown option: $1"
                ;;
            *)
                if [[ -n "$input_arg" ]]; then
                    log_err "Multiple input files specified."
                fi
                input_arg="$1"
                shift
                ;;
        esac
    done

    local file_path
    file_path=$(get_input "$input_arg")

    process_video "$file_path"
}

main "$@"
