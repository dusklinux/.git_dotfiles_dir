#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: premiere-prep.sh
# AUTHOR: Elite DevOps Assistant (Refined for Arch/Hyprland Ecosystem)
# PURPOSE: Intelligent Remuxer for Arch -> Premiere Pro (Windows) Workflow.
#          - Auto-detects HEVC and applies 'hvc1' tags.
#          - Scans ALL audio tracks (not just the first) for incompatible codecs.
#          - Preserves ALL audio tracks (Mic, Game, Discord).
#          - Uses modern Bash 5+ arrays, safety features, and regex.
#          - NOW SUPPORTS: Directory paths as arguments (Batch processing folders).
#          - INTERACTIVE: Prompts for directory with TAB completion if none found.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. CONFIGURATION & SAFETY
# ------------------------------------------------------------------------------

# Strict Mode: Unset variables error out, pipe failures propagate.
set -uo pipefail

# ANSI Colors
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' B=$'\e[34m' M=$'\e[35m' C=$'\e[36m' RS=$'\e[0m'

# Track current output for cleanup on interrupt (Ctrl+C)
CURRENT_OUTPUT=""

# ------------------------------------------------------------------------------
# 2. TRAP HANDLER (CLEANUP)
# ------------------------------------------------------------------------------

cleanup() {
    # If we are interrupted while writing a file, delete the corrupt partial file
    if [[ -n "$CURRENT_OUTPUT" && -f "$CURRENT_OUTPUT" ]]; then
        rm -f -- "$CURRENT_OUTPUT"
        printf '\n%s\n' "${R}[!] Interrupted. Cleaned up partial file.${RS}" >&2
    fi
    exit 130
}
trap cleanup INT TERM

# ------------------------------------------------------------------------------
# 3. DEPENDENCY CHECK
# ------------------------------------------------------------------------------

check_dependencies() {
    local missing=()
    command -v ffmpeg  &>/dev/null || missing+=(ffmpeg)
    command -v ffprobe &>/dev/null || missing+=(ffprobe)
    
    if (( ${#missing[@]} )); then
        printf '%s\n' "${R}[!] Error: Missing required tools: ${missing[*]}${RS}" >&2
        printf '%s\n' "    Install with: sudo pacman -S ffmpeg" >&2
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 4. CORE ANALYSIS ENGINE
# ------------------------------------------------------------------------------

analyze_and_process() {
    local input_file="$1"
    
    # Security: Normalize relative paths starting with '-' to prevent flag confusion
    [[ $input_file == -* && $input_file != /* ]] && input_file="./$input_file"
    
    local dir_name base_name output_dir output_file
    dir_name=$(dirname -- "$input_file")
    base_name=$(basename -- "$input_file")
    output_dir="${dir_name}/premiere_ready"
    output_file="${output_dir}/${base_name%.*}.mov"

    # Create directory with error checking
    if ! mkdir -p -- "$output_dir" 2>/dev/null; then
        printf '%s\n' "   ${R}[!] Cannot create output directory: ${output_dir}${RS}" >&2
        return 1
    fi

    printf '\n%s\n' "${M}════════════════════════════════════════════════════════════${RS}"
    printf '%s\n'   "${M} ANALYZING: ${C}${base_name}${RS}"

    # --- PROBE THE FILE ---
    # We redirect stderr to null to keep the UI clean, errors handled by exit code
    local v_codec a_codecs_list
    v_codec=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=codec_name -of csv=p=0 "$input_file" 2>/dev/null) || true
    
    # Get all audio codecs separated by newlines
    a_codecs_list=$(ffprobe -v error -select_streams a \
        -show_entries stream=codec_name -of csv=p=0 "$input_file" 2>/dev/null) || true

    if [[ -z $v_codec ]]; then
        printf '%s\n' "   ${R}[!] No video stream detected. Skipping.${RS}" >&2
        return 1
    fi

    # --- VIDEO STRATEGY ---
    local -a v_args=(-c:v copy)
    local v_msg="Copy Video (Lossless)"

    case "$v_codec" in
        hevc|h265)
            # HEVC requires 'hvc1' tag for Apple/Adobe compatibility
            v_args=(-c:v copy -tag:v hvc1)
            v_msg="Copy HEVC + Fix Tag (hvc1)"
            ;;
        av1)
            printf '%s\n' "   ${Y}[!] Warning: AV1 detected. Ensure Premiere is updated.${RS}"
            ;;
    esac

    # --- AUDIO STRATEGY ---
    # If ANY track is Opus/Vorbis/FLAC, convert ALL to PCM for consistency.
    local -a a_args=(-c:a copy)
    local a_msg="Copy All Audio Tracks"

    if [[ -n $a_codecs_list ]]; then
        # OPTIMIZATION: Use Bash Regex instead of piping to grep
        if [[ "$a_codecs_list" =~ (opus|vorbis|flac) ]]; then
            a_args=(-c:a pcm_s16le)
            a_msg="Convert All Audio to PCM (Fixing Opus/Vorbis/FLAC)"
        fi
    else
        a_msg="No Audio Streams Found"
    fi

    # --- CONTAINER STRATEGY ---
    local -a container_args=(-map 0 -movflags +faststart)

    # --- DISPLAY INFO ---
    # Bash parameter expansion replaces newlines with spaces for clean display
    printf '%s\n' "   ${B}Video:${RS} $v_codec"
    printf '%s\n' "   ${B}Audio:${RS} ${a_codecs_list//$'\n'/ }"
    printf '\n'
    printf '%s\n' "   ${G}Plan:${RS} 1. $v_msg"
    printf '%s\n' "         2. $a_msg"
    printf '%s\n' "         3. Optimize for Premiere (MOV + FastStart)"
    printf '\n'

    local choice
    read -rp "   ${Y}Proceed? [Y/n/transcode] ${RS}" choice

    case "${choice,,}" in
        transcode)
            _execute_transcode "$input_file" "$output_file"
            ;;
        n|no)
            printf '%s\n' "   ${R}Skipped.${RS}"
            ;;
        *)  # Default catch-all (handles Y, yes, or empty Enter)
            _execute_remux "$input_file" "$output_file" v_args a_args container_args
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 5. EXECUTION HANDLERS
# ------------------------------------------------------------------------------

_execute_remux() {
    local input="$1" output="$2"
    local -n _v="$3" _a="$4" _c="$5"

    [[ -f $output ]] && printf '%s\n' "   ${Y}[!] File exists. Overwriting...${RS}"

    printf '%s\n' "   ${B}[*] Processing...${RS}"
    CURRENT_OUTPUT="$output"

    if ffmpeg -hide_banner -y -v error -stats \
        -i "$input" \
        "${_v[@]}" "${_a[@]}" "${_c[@]}" \
        "$output"; then
        CURRENT_OUTPUT=""
        printf '\n%s\n' "   ${G}[✔] Done: ${output}${RS}"
    else
        printf '\n%s\n' "   ${R}[✘] Error during processing.${RS}" >&2
        [[ -f $output ]] && rm -f -- "$output"
        CURRENT_OUTPUT=""
        return 1
    fi
}

_execute_transcode() {
    local input="$1"
    local output="${2%.*}_ProRes.mov"
    
    printf '\n%s\n' "   ${Y}[!] NUCLEAR OPTION: Transcoding to ProRes 422${RS}"
    printf '%s\n'   "       - Fixing VFR (Frame Rate Drift)"
    printf '%s\n'   "       - Converting Audio to PCM"
    printf '%s\n'   "       - Creating Edit-Ready Master (Large File)"

    CURRENT_OUTPUT="$output"

    # CRITICAL FIX: Added -movflags +faststart here too.
    # ProRes files are huge; without faststart, Premiere hangs while indexing them.
    if ffmpeg -hide_banner -y -v error -stats \
        -i "$input" \
        -c:v prores_ks -profile:v 2 \
        -c:a pcm_s16le \
        -r 60 \
        -map 0 \
        -movflags +faststart \
        "$output"; then
        CURRENT_OUTPUT=""
        printf '\n%s\n' "   ${G}[✔] Transcode Complete: ${output}${RS}"
    else
        printf '\n%s\n' "   ${R}[✘] Transcode Failed.${RS}" >&2
        [[ -f $output ]] && rm -f -- "$output"
        CURRENT_OUTPUT=""
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 6. MAIN LOOP
# ------------------------------------------------------------------------------

main() {
    check_dependencies

    local -a files=()
    local arg dir target_dir f
    
    if (( $# )); then
        # Process command-line arguments
        for arg in "$@"; do
            if [[ -d $arg ]]; then
                shopt -s nullglob nocaseglob
                dir="${arg%/}"
                files+=( "$dir"/*.{mkv,mp4,webm,avi,ts} )
                shopt -u nullglob nocaseglob
            elif [[ -f $arg ]]; then
                files+=("$arg")
            else
                printf '%s\n' "${R}[!] Not a file or directory: ${arg}${RS}" >&2
            fi
        done
        
        if (( ! ${#files[@]} )); then
            printf '%s\n' "${R}[!] No video files found in the provided paths.${RS}" >&2
            exit 1
        fi
    else
        # No arguments: scan current directory
        shopt -s nullglob nocaseglob
        files=(*.{mkv,mp4,webm,avi,ts})
        shopt -u nullglob nocaseglob
        
        if (( ! ${#files[@]} )); then
            # Interactive fallback
            printf '\n%s\n' "${Y}[!] No video files found in current directory.${RS}"
            
            while true; do
                printf '\n%s' "${M}Enter path to video directory (TAB completion enabled):${RS} "
                
                # Using 'read -e' enables readline for TAB completion
                read -r -e target_dir
                
                # Manual tilde expansion (bash doesn't always auto-expand in read)
                target_dir="${target_dir/#\~/$HOME}"
                
                [[ -z $target_dir ]] && continue

                if [[ -d $target_dir ]]; then
                    shopt -s nullglob nocaseglob
                    files=( "${target_dir%/}"/*.{mkv,mp4,webm,avi,ts} )
                    shopt -u nullglob nocaseglob
                    
                    if (( ${#files[@]} )); then
                        printf '%s\n' "${G}[✔] Found ${#files[@]} videos in: ${target_dir}${RS}"
                        break
                    fi
                    printf '%s\n' "${R}[!] No video files found in that directory.${RS}" >&2
                else
                    printf '%s\n' "${R}[!] Directory not found. Try again.${RS}" >&2
                fi
            done
        fi
    fi

    # Process all collected files
    for f in "${files[@]}"; do
        if [[ -f $f ]]; then
            analyze_and_process "$f"
        else
            printf '%s\n' "${R}[!] File not found: ${f}${RS}" >&2
        fi
    done
}

main "$@"
