#!/usr/bin/env bash
# =============================================================================
# Script: imgsort
# Description: Unified image sorting utility - by brightness or file size
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

readonly VERSION="2.0.4"
readonly SCRIPT_NAME="${0##*/}"
readonly BYTES_MB=1048576
readonly IMAGE_EXTENSIONS=("jpg" "jpeg" "png" "gif" "webp" "avif" "jxl" "bmp" "tiff" "heif" "heic")

# Colors
if [[ -z "${NO_COLOR:-}" && -t 1 ]]; then
    readonly C_RED=$'\e[0;31m' C_GREEN=$'\e[0;32m' C_YELLOW=$'\e[0;33m'
    readonly C_BLUE=$'\e[0;34m' C_MAGENTA=$'\e[0;35m' C_CYAN=$'\e[0;36m'
    readonly C_BOLD=$'\e[1m' C_DIM=$'\e[2m' C_RESET=$'\e[0m'
else
    readonly C_RED='' C_GREEN='' C_YELLOW='' C_BLUE=''
    readonly C_MAGENTA='' C_CYAN='' C_BOLD='' C_DIM='' C_RESET=''
fi

# MODIFIED: Switched to standard ASCII to fix rendering issues on some terminals
readonly BOX_H="-" BOX_TL="+" BOX_TR="+" BOX_BL="+" BOX_BR="+" BOX_V="|"

# Runtime state
declare MODE="" TARGET_DIR="." THRESHOLD="0.5" SORT_ORDER="ascending"
declare DRY_RUN=false USE_PARALLEL="auto" INTERACTIVE=false
declare -i PROCESSED=0 FAILED=0
declare tmp_list=""

# =============================================================================
# LOGGING (always to stderr for safety)
# =============================================================================
log_info()    { printf '%s[INFO]%s %s\n' "$C_BLUE" "$C_RESET" "$1" >&2; }
log_success() { printf '%s[OK]%s %s\n' "$C_GREEN" "$C_RESET" "$1" >&2; }
log_warn()    { printf '%s[WARN]%s %s\n' "$C_YELLOW" "$C_RESET" "$1" >&2; }
log_error()   { printf '%s[ERROR]%s %s\n' "$C_RED" "$C_RESET" "$1" >&2; }

die() { log_error "$1"; exit "${2:-1}"; }

cleanup() {
    local exit_code=$?
    printf '\e[?25h' 2>/dev/null || true
    # Fix: Cleanup temp file if it exists
    [[ -n "${tmp_list:-}" && -f "$tmp_list" ]] && rm -f "$tmp_list"
    # Kill any background xargs jobs if interrupted
    jobs -p | xargs -r kill 2>/dev/null || true
    exit $exit_code
}
trap cleanup EXIT INT TERM

# =============================================================================
# UI HELPERS - All output to stderr, only results to stdout
# =============================================================================
print_header() {
    local term_width
    term_width=$(tput cols 2>/dev/null) || term_width=60
    
    # Ensure minimum width to prevent math errors
    (( term_width < 40 )) && term_width=40

    # Calculate precise padding to avoid wrapping
    # Content: "|  IMAGE SORTER  vX.X.X" (Left side) + "|" (Right side)
    # Length: 1 + 2 + 12 + 2 + 1 + len(VER) = 18 + len(VER)
    # Right border uses 1 char. Total non-padded = 19 + len(VER)
    local content_len=$(( 18 + ${#VERSION} ))
    local pad_len=$(( term_width - content_len - 1 ))
    
    printf '\n' >&2
    printf '%s%s%s\n' "$C_CYAN" "${BOX_TL}$(printf '%*s' $((term_width - 2)) '' | tr ' ' "$BOX_H")${BOX_TR}" "$C_RESET" >&2
    
    # Header Line
    printf '%s%s  %sIMAGE SORTER%s  %sv%s%s%*s%s%s\n' \
        "$C_CYAN" "$BOX_V" \
        "$C_BOLD" "$C_RESET" "$C_DIM" "$VERSION" "$C_RESET" \
        "$pad_len" "" \
        "$C_CYAN" "$BOX_V$C_RESET" >&2
        
    printf '%s%s%s\n\n' "$C_CYAN" "${BOX_BL}$(printf '%*s' $((term_width - 2)) '' | tr ' ' "$BOX_H")${BOX_BR}" "$C_RESET" >&2
}

print_section() {
    printf '\n%s%s=== %s ===%s\n\n' "$C_BOLD" "$C_BLUE" "$1" "$C_RESET" >&2
}

# Returns 0-based index via stdout, all prompts to stderr
show_menu() {
    local title="$1"
    shift
    local -a options=("$@")
    local -i count=${#options[@]}
    
    printf '%s%s%s\n\n' "$C_BOLD" "$title" "$C_RESET" >&2
    
    local -i i
    for i in "${!options[@]}"; do
        printf '  %s[%d]%s  %s\n' "$C_CYAN" $((i + 1)) "$C_RESET" "${options[$i]}" >&2
    done
    printf '  %s[q]%s  Quit\n\n' "$C_DIM" "$C_RESET" >&2
    
    while true; do
        printf '%sEnter choice%s [%s1%s]: ' "$C_BOLD" "$C_RESET" "$C_GREEN" "$C_RESET" >&2
        local choice
        read -r choice
        choice="${choice:-1}"
        
        if [[ "${choice,,}" == "q" ]]; then
            printf '\n%sGoodbye!%s\n\n' "$C_DIM" "$C_RESET" >&2
            exit 0
        fi
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= count )); then
            printf '%d' "$((choice - 1))"  # Only this goes to stdout
            return 0
        fi
        
        printf '%sInvalid choice. Enter 1-%d or q.%s\n' "$C_RED" "$count" "$C_RESET" >&2
    done
}

# Accepts: 1, 2, or direct path input
select_directory() {
    local current_dir
    current_dir="$(pwd)"
    
    printf '%s%s%s\n\n' "$C_BOLD" "Select target directory" "$C_RESET" >&2
    printf '  %s[1]%s  Current directory %s(%s)%s\n' "$C_CYAN" "$C_RESET" "$C_DIM" "$current_dir" "$C_RESET" >&2
    printf '  %s[2]%s  Enter custom path\n' "$C_CYAN" "$C_RESET" >&2
    printf '  %s---  Or type a path directly%s\n\n' "$C_DIM" "$C_RESET" >&2
    
    printf '%sChoice/path%s [%s1%s]: ' "$C_BOLD" "$C_RESET" "$C_GREEN" "$C_RESET" >&2
    local input
    read -r input
    input="${input:-1}"
    
    local dir_path=""
    
    # Detect if input looks like a path
    if [[ "$input" == "1" ]]; then
        dir_path="$current_dir"
    elif [[ "$input" == "2" ]]; then
        printf '\n%sEnter path%s: ' "$C_BOLD" "$C_RESET" >&2
        read -r dir_path
        dir_path="${dir_path:-.}"
    else
        # Treat as direct path input
        dir_path="$input"
    fi
    
    # Expand ~
    dir_path="${dir_path/#\~/$HOME}"
    
    # Validate
    if [[ ! -d "$dir_path" ]]; then
        printf '%sDirectory not found: %s%s\n' "$C_RED" "$dir_path" "$C_RESET" >&2
        printf 'Create it? [y/N]: ' >&2
        local response
        read -r response
        if [[ "${response,,}" == "y" ]]; then
            mkdir -p "$dir_path" || die "Failed to create directory"
            log_success "Created: $dir_path"
        else
            die "Directory does not exist"
        fi
    fi
    
    # Only output the resolved path to stdout
    cd "$dir_path" && pwd
}

select_threshold() {
    cat >&2 << 'EOF'

  DARK <---------------------------------> LIGHT
       0.0   0.2   0.4   0.5   0.6   0.8   1.0

  Lower = more images marked "light"
  Higher = more images marked "dark"

EOF
    printf '  %s[1]%s  0.4  %s(Dark-mode friendly)%s\n' "$C_CYAN" "$C_RESET" "$C_DIM" "$C_RESET" >&2
    printf '  %s[2]%s  0.5  %s(Balanced)%s\n' "$C_CYAN" "$C_RESET" "$C_DIM" "$C_RESET" >&2
    printf '  %s[3]%s  0.6  %s(Light-mode friendly)%s\n' "$C_CYAN" "$C_RESET" "$C_DIM" "$C_RESET" >&2
    printf '  %s[4]%s  Custom\n\n' "$C_CYAN" "$C_RESET" >&2
    
    printf '%sChoice%s [%s2%s]: ' "$C_BOLD" "$C_RESET" "$C_GREEN" "$C_RESET" >&2
    local choice
    read -r choice
    choice="${choice:-2}"
    
    case "$choice" in
        1) printf '0.4' ;;
        2) printf '0.5' ;;
        3) printf '0.6' ;;
        4)
            while true; do
                printf '%sEnter value (0.0-1.0)%s: ' "$C_BOLD" "$C_RESET" >&2
                local val
                read -r val
                if [[ "$val" =~ ^0*\.[0-9]+$|^[01](\.0*)?$ ]]; then
                    printf '%s' "$val"
                    break
                fi
                printf '%sInvalid. Enter 0.0 to 1.0%s\n' "$C_RED" "$C_RESET" >&2
            done
            ;;
        *) printf '0.5' ;;
    esac
}

select_sort_order() {
    printf '\n%sSort order:%s\n\n' "$C_BOLD" "$C_RESET" >&2
    printf '  %s[1]%s  Smallest -> Largest  %s(0001 = smallest)%s\n' "$C_CYAN" "$C_RESET" "$C_DIM" "$C_RESET" >&2
    printf '  %s[2]%s  Largest -> Smallest  %s(0001 = largest)%s\n\n' "$C_CYAN" "$C_RESET" "$C_DIM" "$C_RESET" >&2
    
    printf '%sChoice%s [%s1%s]: ' "$C_BOLD" "$C_RESET" "$C_GREEN" "$C_RESET" >&2
    local choice
    read -r choice
    
    case "${choice:-1}" in
        2) printf 'descending' ;;
        *) printf 'ascending' ;;
    esac
}

confirm() {
    local message="$1" default="${2:-y}"
    local hint="Y/n"
    [[ "${default,,}" != "y" ]] && hint="y/N"
    
    printf '%s%s%s [%s]: ' "$C_BOLD" "$message" "$C_RESET" "$hint" >&2
    local response
    read -r response
    response="${response:-$default}"
    [[ "${response,,}" == "y" || "${response,,}" == "yes" ]]
}

# =============================================================================
# FILE DISCOVERY
# =============================================================================
build_find_args() {
    local first=true
    for ext in "${IMAGE_EXTENSIONS[@]}"; do
        $first || printf -- '-o '
        printf -- '-iname *.%s ' "$ext"
        first=false
    done
}

count_images() {
    local dir="$1"
    local count=0
    for ext in "${IMAGE_EXTENSIONS[@]}"; do
        count=$((count + $(find "$dir" -maxdepth 1 -type f -iname "*.$ext" 2>/dev/null | wc -l)))
    done
    printf '%d' "$count"
}

get_image_files() {
    local dir="$1"
    for ext in "${IMAGE_EXTENSIONS[@]}"; do
        find "$dir" -maxdepth 1 -type f -iname "*.$ext" 2>/dev/null
    done | sort
}

# =============================================================================
# SUMMARY
# =============================================================================
show_summary() {
    print_section "Summary"
    
    printf '  %sMode:%s          ' "$C_DIM" "$C_RESET" >&2
    case "$MODE" in
        brightness)
            printf '%sBrightness Sort%s -> dark/ & light/\n' "$C_BOLD" "$C_RESET" >&2
            printf '  %sThreshold:%s     %s\n' "$C_DIM" "$C_RESET" "$THRESHOLD" >&2
            ;;
        size)
            printf '%sSize Rename%s -> sequential numbering\n' "$C_BOLD" "$C_RESET" >&2
            printf '  %sOrder:%s         %s\n' "$C_DIM" "$C_RESET" "$SORT_ORDER" >&2
            ;;
    esac
    
    printf '  %sDirectory:%s     %s\n' "$C_DIM" "$C_RESET" "$TARGET_DIR" >&2
    printf '  %sDry-run:%s       %s\n' "$C_DIM" "$C_RESET" \
        "$([[ "$DRY_RUN" == true ]] && echo "Yes (preview)" || echo "No")" >&2
    
    local file_count
    file_count=$(count_images "$TARGET_DIR")
    printf '  %sImages:%s        %s%d%s found\n' "$C_DIM" "$C_RESET" "$C_BOLD" "$file_count" "$C_RESET" >&2
    
    if [[ $file_count -eq 0 ]]; then
        printf '\n%s! No image files found!%s\n\n' "$C_YELLOW" "$C_RESET" >&2
        return 1
    fi
    
    printf '\n' >&2
    confirm "Proceed?" "y"
}

# =============================================================================
# INTERACTIVE MODE
# =============================================================================
run_interactive() {
    clear 2>/dev/null || true
    print_header
    
    # Step 1: Mode
    print_section "Step 1: Choose Operation"
    local selection
    selection=$(show_menu "What would you like to do?" \
        "Sort by Brightness  ->  dark/ and light/ folders" \
        "Sort by Size        ->  Rename as 0001, 0002, ...")
    
    case "$selection" in
        0) MODE="brightness" ;;
        1) MODE="size" ;;
    esac
    
    printf '\n  %sOK%s %s\n' "$C_GREEN" "$C_RESET" \
        "$([[ "$MODE" == "brightness" ]] && echo "Brightness sorting" || echo "Size-based renaming")" >&2
    
    # Step 2: Directory
    print_section "Step 2: Choose Directory"
    TARGET_DIR=$(select_directory)
    printf '\n  %sOK%s %s\n' "$C_GREEN" "$C_RESET" "$TARGET_DIR" >&2
    
    # Step 3: Options
    print_section "Step 3: Configure"
    
    case "$MODE" in
        brightness)
            THRESHOLD=$(select_threshold)
            printf '\n  %sOK%s Threshold: %s\n' "$C_GREEN" "$C_RESET" "$THRESHOLD" >&2
            ;;
        size)
            SORT_ORDER=$(select_sort_order)
            printf '\n  %sOK%s Order: %s\n' "$C_GREEN" "$C_RESET" "$SORT_ORDER" >&2
            ;;
    esac
    
    # Dry run?
    printf '\n' >&2
    if confirm "Preview first (dry-run)?" "n"; then
        DRY_RUN=true
    fi
    
    # Confirm
    show_summary || exit 0
    printf '\n' >&2
}

# =============================================================================
# BRIGHTNESS SORTING
# =============================================================================
# Worker function for parallel execution (injected from v4 engine)
sort_brightness_worker() {
    local file="$1"
    local threshold="$2"
    local dry_run="$3"
    local dark_dir="$4"
    local light_dir="$5"

    # 1. Calculate Brightness (No -ping, force pixel read, use quiet)
    local brightness
    if ! brightness=$(magick identify -quiet -format "%[fx:mean]\n" "$file" 2>/dev/null | head -n1); then
        printf "ERR|%s\n" "$file"
        return
    fi

    # 2. Sanity check: Ensure valid float
    if [[ -z "$brightness" ]] || ! [[ "$brightness" =~ ^[0-9.]+$ ]]; then
        printf "ERR|%s\n" "$file"
        return
    fi

    # 3. Compare using bc (Robust float math)
    local is_light
    is_light=$(echo "$brightness > $threshold" | bc -l)

    local dest_dir category
    if (( is_light )); then
        dest_dir="$light_dir"
        category="LIGHT"
    else
        dest_dir="$dark_dir"
        category="DARK"
    fi

    # 4. Action (Fix: Collision Check & mv -n)
    if [[ "$dry_run" == "false" ]]; then
        # Atomic move attempt
        mv -n -- "$file" "$dest_dir/" 2>/dev/null
        
        # If source file still exists, it failed (Collision or Error)
        if [[ -e "$file" ]]; then
             # Check destination to distinguish collision from other errors
             if [[ -e "$dest_dir/${file##*/}" ]]; then
                 printf "COLLISION|%s|%s|%s\n" "$category" "$brightness" "$file"
             else
                 printf "ERR|%s\n" "$file"
             fi
             return
        fi
    fi
    
    # Output: OK|CATEGORY|VALUE|FILE
    printf "OK|%s|%s|%s\n" "$category" "$brightness" "$file"
}
export -f sort_brightness_worker

sort_by_brightness() {
    local dir="$1"
    local dark_dir="${dir}/dark" light_dir="${dir}/light"
    local -i count_dark=0 count_light=0
    
    print_section "Processing"
    log_info "Sorting by brightness (threshold: $THRESHOLD) [Multi-Core Parallel]"
    [[ "$DRY_RUN" == true ]] && log_warn "DRY RUN - no files will be moved"
    printf '\n' >&2
    
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$dark_dir" "$light_dir"
    fi
    
    # Discovery: Single-pass find for efficiency (Optimization A)
    tmp_list=$(mktemp)
    
    local -a find_args=()
    for ext in "${IMAGE_EXTENSIONS[@]}"; do
        [[ ${#find_args[@]} -gt 0 ]] && find_args+=("-o")
        find_args+=("-iname" "*.$ext")
    done
    find "$dir" -maxdepth 1 -type f \( "${find_args[@]}" \) -print0 > "$tmp_list"
    
    local total_files
    total_files=$(tr -cd '\0' < "$tmp_list" | wc -c)

    if [[ "$total_files" -eq 0 ]]; then
        log_warn "No images found"
        rm "$tmp_list"
        return 0
    fi
    
    # Fix: LC_NUMERIC allows float math without breaking UTF-8 filenames
    export LC_NUMERIC=C

    # Producer-Consumer Loop
    while IFS='|' read -r status category val file; do
        if [[ "$status" == "ERR" ]]; then
            # In ERR case, category is actually the filename (2nd arg)
            local filename="${category##*/}"
            printf '  %s!%s %s (failed to analyze or move)\n' "$C_YELLOW" "$C_RESET" "$filename" >&2
            (( ++FAILED ))
            continue
        fi
        
        # Fix: Handle collision status
        if [[ "$status" == "COLLISION" ]]; then
            local filename="${file##*/}"
            printf '  %s!%s %s (collision - skipped)\n' "$C_YELLOW" "$C_RESET" "$filename" >&2
            (( ++FAILED ))
            continue
        fi

        # Format output to match original UI style
        local filename="${file##*/}"
        local color="$C_BLUE"
        [[ "$category" == "LIGHT" ]] && color="$C_YELLOW"
        
        if [[ "$category" == "LIGHT" ]]; then
             (( ++count_light ))
        else
             (( ++count_dark ))
        fi
        
        if [[ "$DRY_RUN" == true ]]; then
            printf '  %s[DRY]%s %s%-5s%s %s %s(%.3f)%s\n' \
                "$C_MAGENTA" "$C_RESET" "$color" "$category" "$C_RESET" \
                "$filename" "$C_DIM" "$val" "$C_RESET" >&2
        else
            printf '  %s%-5s%s %s %s[%.3f]%s\n' \
                "$color" "$category" "$C_RESET" \
                "$filename" "$C_DIM" "$val" "$C_RESET" >&2
        fi
        (( ++PROCESSED ))
        
    done < <(xargs -0 -a "$tmp_list" -P "$(nproc)" -I {} bash -c \
        'sort_brightness_worker "$@"' _ "{}" "$THRESHOLD" "$DRY_RUN" "$dark_dir" "$light_dir")

    rm "$tmp_list"
    
    print_section "Results"
    printf '  + Dark:  %d images' "$count_dark" >&2
    [[ "$DRY_RUN" == false ]] && printf ' -> %s' "$dark_dir" >&2
    printf '\n' >&2
    printf '  + Light: %d images' "$count_light" >&2
    [[ "$DRY_RUN" == false ]] && printf ' -> %s' "$light_dir" >&2
    printf '\n\n' >&2
    
    log_success "Processed $PROCESSED images ($FAILED failed)"
    [[ "$DRY_RUN" == true ]] && printf '\n%sRun without dry-run to apply.%s\n' "$C_YELLOW" "$C_RESET" >&2
}

# =============================================================================
# SIZE SORTING
# =============================================================================
sort_by_size() {
    local dir="$1"
    local output_dir="${dir}/renamed_sorted"
    local sort_flag="-n"
    [[ "$SORT_ORDER" == "descending" ]] && sort_flag="-rn"
    
    print_section "Processing"
    log_info "Renaming by size ($SORT_ORDER)"
    [[ "$DRY_RUN" == true ]] && log_warn "DRY RUN - no files will be created"
    printf '\n' >&2
    
    local -a sorted_files
    mapfile -t sorted_files < <(
        get_image_files "$dir" | while read -r f; do
            [[ -f "$f" ]] && printf '%s\t%s\n' "$(stat -c%s "$f")" "$f"
        done | sort $sort_flag -t$'\t' -k1,1 | cut -f2
    )
    
    local total=${#sorted_files[@]}
    if [[ $total -eq 0 ]]; then
        log_warn "No images found"
        return 0
    fi
    
    local -i digits=${#total}
    (( digits < 4 )) && digits=4
    
    [[ "$DRY_RUN" == false ]] && mkdir -p "$output_dir"
    
    local -i count=1
    for file_path in "${sorted_files[@]}"; do
        [[ -f "$file_path" ]] || continue
        
        local filename="${file_path##*/}"
        local ext="${filename##*.}"
        [[ "$filename" == "$ext" ]] && continue
        
        local new_name size_bytes size_h
        printf -v new_name '%0*d.%s' "$digits" "$count" "${ext,,}"
        size_bytes=$(stat -c%s "$file_path")
        
        if (( size_bytes >= BYTES_MB )); then
            printf -v size_h '%.1fM' "$(bc -l <<< "$size_bytes/$BYTES_MB")"
        elif (( size_bytes >= 1024 )); then
            printf -v size_h '%.0fK' "$(bc -l <<< "$size_bytes/1024")"
        else
            size_h="${size_bytes}B"
        fi
        
        if [[ "$DRY_RUN" == true ]]; then
            printf '  %s[DRY]%s %s -> %s %s(%s)%s\n' \
                "$C_MAGENTA" "$C_RESET" "$filename" "$new_name" "$C_DIM" "$size_h" "$C_RESET" >&2
        else
            cp -- "$file_path" "${output_dir}/${new_name}"
            printf '  %s%s%s -> %s %s(%s)%s\n' \
                "$C_GREEN" "$filename" "$C_RESET" "$new_name" "$C_DIM" "$size_h" "$C_RESET" >&2
        fi
        
        (( ++count, ++PROCESSED ))
    done
    
    print_section "Results"
    printf '  + Output: %s\n' "$output_dir" >&2
    printf '  + Renamed: %d images\n\n' "$PROCESSED" >&2
    
    log_success "Complete!"
    [[ "$DRY_RUN" == false ]] && log_warn "Originals preserved - verify before deleting"
    [[ "$DRY_RUN" == true ]] && printf '\n%sRun without dry-run to apply.%s\n' "$C_YELLOW" "$C_RESET" >&2
}

# =============================================================================
# CLI PARSING & MAIN
# =============================================================================
show_help() {
    cat << EOF
${C_BOLD}$SCRIPT_NAME${C_RESET} v$VERSION - Image Sorting Utility

${C_BOLD}USAGE${C_RESET}
    $SCRIPT_NAME                    # Interactive mode
    $SCRIPT_NAME -b [OPTIONS] DIR   # Brightness sort
    $SCRIPT_NAME -s [OPTIONS] DIR   # Size rename

${C_BOLD}MODES${C_RESET}
    -b, --brightness    Sort into dark/light folders
    -s, --size          Rename by file size (0001, 0002...)
    -i, --interactive   Force interactive mode

${C_BOLD}OPTIONS${C_RESET}
    -d, --directory DIR   Target directory
    -t, --threshold N     Brightness 0.0-1.0 (default: 0.5)
    --ascending           Size: smallest first (default)
    --descending          Size: largest first
    -n, --dry-run         Preview only
    -h, --help            Show help
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) show_help; exit 0 ;;
            -V|--version) echo "$VERSION"; exit 0 ;;
            -i|--interactive) INTERACTIVE=true; shift ;;
            -b|--brightness) MODE="brightness"; shift ;;
            -s|--size) MODE="size"; shift ;;
            -t|--threshold)
                # Fix: Smart validation for threshold
                if [[ ! "$2" =~ ^(0?\.[0-9]+|[01](\.0*)?)$ ]]; then
                    die "Invalid threshold: $2. Must be 0.0-1.0"
                fi
                THRESHOLD="$2"; shift 2 ;;
            -d|--directory) TARGET_DIR="$2"; shift 2 ;;
            -n|--dry-run) DRY_RUN=true; shift ;;
            --ascending) SORT_ORDER="ascending"; shift ;;
            --descending) SORT_ORDER="descending"; shift ;;
            -*) die "Unknown option: $1" ;;
            *) TARGET_DIR="$1"; shift ;;
        esac
    done
}

main() {
    [[ $# -eq 0 ]] && INTERACTIVE=true
    parse_args "$@"
    
    if [[ "$INTERACTIVE" == true ]]; then
        run_interactive
    else
        [[ -z "$MODE" ]] && die "Specify mode: -b (brightness) or -s (size)"
        [[ ! -d "$TARGET_DIR" ]] && die "Directory not found: $TARGET_DIR"
        TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
        print_header
    fi
    
    # Check dependencies
    if ! command -v bc &>/dev/null; then
        die "bc required. Install: sudo pacman -S --needed bc"
    fi

    if [[ "$MODE" == "brightness" ]]; then 
        if ! command -v magick &>/dev/null; then
            die "ImageMagick required. Install: sudo pacman -S --needed imagemagick"
        fi
        
        # Check for libheif (Arch specific as user requested pacman checks)
        # Using pacman -Q because command -v cannot check for libraries/delegates easily
        if command -v pacman &>/dev/null && ! pacman -Q libheif &>/dev/null; then
            die "libheif required for HEIF/HEIC. Install: sudo pacman -S --needed libheif"
        fi
    fi
    
    case "$MODE" in
        brightness) sort_by_brightness "$TARGET_DIR" ;;
        size) sort_by_size "$TARGET_DIR" ;;
    esac
    
    printf '\n' >&2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
