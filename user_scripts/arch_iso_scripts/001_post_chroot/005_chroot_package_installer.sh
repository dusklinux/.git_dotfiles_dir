#!/usr/bin/env bash
# --------------------------------------------------------------------------
# Arch Linux / Hyprland / UWSM - Elite System Installer (v3.2 - ISO/Chroot Edition)
# --------------------------------------------------------------------------

# --- 0. SAFETY & ENVIRONMENT ---
set -euo pipefail

# ANSI Colors (Safer than tput inside chroot where TERM might be unset)
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
RESET=$'\033[0m'

# Cleanup Trap
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        printf "\n${RED}[!] Script interrupted or failed with code %d${RESET}\n" "$exit_code"
    fi
}
trap cleanup EXIT INT TERM

# --- 1. CONFIGURATION (UNCHANGED) ---

# Group 1: Graphics & Drivers (Intel 12th Gen)
pkgs_graphics=(
  "intel-media-driver" "mesa" "vulkan-intel" "mesa-utils" "intel-gpu-tools" "libva" "libva-utils" "vulkan-icd-loader" "vulkan-tools" "sof-firmware" "linux-firmware" "acpi_call"
)

# Group 2: Hyprland Core
pkgs_hyprland=(
"hyprland" "uwsm" "xorg-xwayland" "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk" "xorg-xhost" "polkit" "hyprpolkitagent" "xdg-utils" "socat" "inotify-tools" "file"
)

# Group 3: GUI, Toolkits & Fonts
pkgs_appearance=(
"qt5-wayland" "qt6-wayland" "gtk3" "gtk4" "nwg-look" "qt5ct" "qt6ct" "qt6-svg" "qt6-multimedia-ffmpeg" "kvantum" "adw-gtk-theme" "matugen" "ttf-font-awesome" "ttf-jetbrains-mono-nerd" "noto-fonts-emoji" "sassc"
)

# Group 4: Desktop Experience
pkgs_desktop=(
"waybar" "swww" "hyprlock" "hypridle" "hyprsunset" "hyprpicker" "swaync" "swayosd" "rofi" "libdbusmenu-qt5" "libdbusmenu-glib" "brightnessctl"
)

# Group 5: Audio & Bluetooth
pkgs_audio=(
"pipewire" "wireplumber" "pipewire-pulse" "playerctl" "bluez" "bluez-utils" "blueman" "bluetui" "pavucontrol" "gst-plugin-pipewire" "libcanberra"
)

# Group 6: Filesystem & Archives
pkgs_filesystem=(
"btrfs-progs" "compsize" "zram-generator" "udisks2" "udiskie" "dosfstools" "ntfs-3g" "gvfs" "gvfs-mtp" "gvfs-nfs" "gvfs-smb" "xdg-user-dirs" "usbutils" "usbmuxd" "gparted" "gnome-disk-utility" "baobab" "unzip" "zip" "unrar" "7zip" "cpio" "file-roller" "rsync" "grsync" "thunar" "thunar-archive-plugin"
)

# Group 7: Network & Internet
pkgs_network=(
"networkmanager" "iwd" "nm-connection-editor" "inetutils" "wget" "curl" "openssh" "firewalld" "vsftpd" "reflector" "bmon" "ethtool" "httrack" "filezilla" "qbittorrent" "wavemon" "firefox" "arch-wiki-lite" "arch-wiki-docs" "network-manager-applet" "aria2" "uget"
)

# Group 8: Terminal & Shell
pkgs_terminal=(
"kitty" "zsh" "zsh-syntax-highlighting" "starship" "fastfetch" "bat" "eza" "fd" "tealdeer" "yazi" "zellij" "gum" "man-db" "ttyper" "tree" "fzf" "less" "ripgrep" "expac" "zsh-autosuggestions" "calcurse" "iperf3" "pkgstats" "libqalculate"
)

# Group 9: Development
pkgs_dev=(
"neovim" "git" "git-delta" "meson" "cmake" "clang" "uv" "rq" "jq" "bc" "viu" "chafa" "ueberzugpp" "ccache" "mold" "shellcheck" "fd" "ripgrep" "fzf" "shfmt" "stylua" "prettier" "tree-sitter-cli" "nano"
)

# Group 10: Multimedia
pkgs_multimedia=(
"ffmpeg" "mpv" "mpv-mpris" "swappy" "swayimg" "resvg" "imagemagick" "libheif" "obs-studio" "audacity" "handbrake" "guvcview" "ffmpegthumbnailer" "krita" "grim" "slurp" "wl-clipboard" "cliphist" "tesseract-data-eng"
)

# Group 11: Sys Admin
pkgs_sysadmin=(
"btop" "htop" "nvtop" "inxi" "sysstat" "sysbench" "logrotate" "acpid" "tlp" "tlp-rdw" "thermald" "powertop" "gdu" "iotop" "iftop" "lshw" "wev" "pacman-contrib" "gnome-keyring" "libsecret" "seahorse" "yad" "dysk" "fwupd" "caligula"
)

# Group 12: Gnome Utilities
pkgs_gnome=(
"snapshot" "cameractrls" "loupe" "gnome-text-editor" "blanket" "collision" "errands" "identity" "impression" "gnome-calculator" "gnome-clocks" "showmethekey"
)

# Group 13: Productivity
pkgs_productivity=(
"obsidian" "zathura" "zathura-pdf-mupdf" "termusic" "cava"
)

# --------------------------------------------------------------------------
# --- 2. ENGINE (Optimized for Chroot) ---
# --------------------------------------------------------------------------

# Helper: Enable Parallel Downloads if not active
optimize_pacman() {
    local conf="/etc/pacman.conf"
    if grep -q "^#ParallelDownloads" "$conf"; then
        printf "${CYAN}:: Enabling Parallel Downloads in pacman.conf...${RESET}\n"
        sed -i 's/^#ParallelDownloads/ParallelDownloads/' "$conf"
    fi
}

# Helper: Clear Lock
clear_lock() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        printf "${YELLOW}[!] Removing stale pacman lock file...${RESET}\n"
        rm -f /var/lib/pacman/db.lck
    fi
}

install_group() {
    local group_name="$1"
    shift
    local pkgs=("$@")

    [[ ${#pkgs[@]} -eq 0 ]] && return

    printf "\n${BOLD}${CYAN}:: Processing Group: %s${RESET}\n" "$group_name"

    # STRATEGY A: Batch Install
    # Using --needed to skip re-installs, --noconfirm for automation
    if pacman -S --needed --noconfirm "${pkgs[@]}"; then
        printf "${GREEN} [OK] Batch installation successful.${RESET}\n"
        return 0
    fi

    # STRATEGY B: Fallback Individual Install (Smart)
    printf "\n${YELLOW} [!] Batch transaction failed. Retrying individually...${RESET}\n"
    
    # Clear lock just in case the batch fail left it
    clear_lock

    local fail_count=0

    for pkg in "${pkgs[@]}"; do
        # Try 1: Auto-install (Silent)
        if pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1; then
            printf "  ${GREEN}[+] Installed:${RESET} %s\n" "$pkg"
        
        # Try 2: Manual Attempt (Verbose)
        else
            printf "  ${YELLOW}[?] Failed Auto. Retrying verbose:${RESET} %s\n" "$pkg"
            if pacman -S --needed --noconfirm "$pkg"; then
                 printf "  ${GREEN}[+] Installed (Retry):${RESET} %s\n" "$pkg"
            else
                 printf "  ${RED}[X] Not Found / Failed:${RESET} %s\n" "$pkg"
                 ((fail_count++))
            fi
        fi
    done

    if [[ $fail_count -gt 0 ]]; then
        printf "${YELLOW} [!] Group completed with %d failures.${RESET}\n" "$fail_count"
    else
        printf "${GREEN} [OK] Recovery successful. All packages installed.${RESET}\n"
    fi
}

# --- 3. EXECUTION ---

main() {
    printf "${BOLD}:: Starting Post-Bootstrap Package Installation...${RESET}\n"

    # 1. Pre-flight checks
    clear_lock
    optimize_pacman
    
    # 2. Sync DB
    printf "\n${BOLD}:: Syncing Repositories...${RESET}\n"
    pacman -Syy --noconfirm || printf "${YELLOW}[!] Sync skipped or failed (Network issue?)${RESET}\n"

    # 3. Execute Groups
    install_group "Graphics & Drivers" "${pkgs_graphics[@]}"
    install_group "Hyprland Core" "${pkgs_hyprland[@]}"
    install_group "GUI Appearance" "${pkgs_appearance[@]}"
    install_group "Desktop Experience" "${pkgs_desktop[@]}"
    install_group "Audio & Bluetooth" "${pkgs_audio[@]}"
    install_group "Filesystem Tools" "${pkgs_filesystem[@]}"
    install_group "Networking" "${pkgs_network[@]}"
    install_group "Terminal & CLI" "${pkgs_terminal[@]}"
    install_group "Development" "${pkgs_dev[@]}"
    install_group "Multimedia" "${pkgs_multimedia[@]}"
    install_group "System Admin" "${pkgs_sysadmin[@]}"
    install_group "Gnome Utilities" "${pkgs_gnome[@]}"
    install_group "Productivity" "${pkgs_productivity[@]}"

    printf "\n${BOLD}${GREEN}:: PACKAGE INSTALLATION COMPLETE ::${RESET}\n"
}

main "$@"
