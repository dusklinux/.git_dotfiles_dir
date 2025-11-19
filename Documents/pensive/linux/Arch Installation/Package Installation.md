
## Not Recommanded to install all at once but here it is anyway. 
[[All Packages at Once]]
# (Hyprland & Essentials)

This is a critical step where you install the core software for your system, including the graphical environment, drivers, and essential applications. The packages are installed in thematic groups across multiple commands to ensure a stable process and simplify troubleshooting.

> [!NOTE] Phased Installation Strategy
> Running these `pacman` commands separately is intentional. It allows `pacman` to resolve dependencies and download packages in manageable chunks. If one command fails, it's easier to identify the problematic package without halting the entire installation process.

### 1. Graphics Drivers & Core System Utilities 
This command installs essential drivers for Intel GPUs, Mesa for 3D graphics, Vulkan support, and key system tools for Btrfs and ZRAM.
- [ ] Status
```bash
pacman -S --needed intel-media-driver mesa vulkan-intel mesa-utils intel-gpu-tools libva libva-utils vulkan-icd-loader vulkan-tools intel-ucode btrfs-progs zram-generator inetutils
```

> [!note] Only install this if you have an **intel** mobile chip between **5th gen and 11th gen** (hardware encoding/decoding)
>```bash
>pacman -S --needed intel-media-sdk
> ```

### 2. Hyprland Window Manager & Wayland Components
Install the Hyprland compositor, Wayland compatibility layers, and the necessary GTK/Qt frameworks for application rendering.
- [ ] Status
```bash
pacman -S --needed hyprland xorg-xwayland uwsm qt5-wayland qt6-wayland xdg-desktop-portal-gtk gtk3 gtk4 nwg-look qt5ct qt6ct qt6-svg qt6-multimedia-ffmpeg kvantum hyprpolkitagent
```

### 3. System Integration & Fonts
Install Polkit for permissions, XDG portals for Hyprland integration, and essential Nerd Fonts for icons and terminal aesthetics.
- [ ] Status
```bash
pacman -S --needed xorg-xhost polkit xdg-desktop-portal-hyprland xdg-utils ttf-font-awesome ttf-jetbrains-mono-nerd noto-fonts-emoji adw-gtk-theme matugen
```

### 4. Hyprland Ecosystem & Desktop Utilities
Install core components for the Hyprland desktop experience, including the status bar, wallpaper manager, lock screen, and idle daemon.
- [ ] Status
```bash
pacman -S --needed waybar libdbusmenu-qt5 socat swww inotify-tools sassc file libdbusmenu-glib fastfetch hyprlock hypridle hyprsunset hyprpicker swappy
```

### 5. Essential Applications & Network Tools
Install a base set of applications: a launcher, terminal, text editor, network management tools, and system monitors.
- [ ] Status
```bash
pacman -S --needed rofi playerctl brightnessctl vsftpd fwupd networkmanager iwd nm-connection-editor compsize ncdu gdu kitty pavucontrol unzip swayimg python-pipx arch-wiki-lite arch-wiki-docs reflector bmon rsync grsync
```

### 6. Audio (PipeWire) & Bluetooth Support
Set up the modern PipeWire audio server and install utilities for managing Bluetooth devices.
- [ ] Status
```bash
pacman -S --needed pipewire wireplumber pipewire-pulse bluez bluez-utils blueman dosfstools sof-firmware gst-plugin-pipewire guvcview bluetui libcanberra
```

### 7. System Management & Power Saving
Install tools for version control, file transfers, firewall, power management, and system monitoring.
- [ ] Status
```bash
pacman -S --needed git wget curl xdg-user-dirs gvfs gvfs-mtp gvfs-nfs gvfs-smb firewalld udisks2 udiskie tlp tlp-rdw thermald powertop 7zip usbutils usbmuxd gparted ntfs-3g acpid pacman-contrib nvtop btop inxi less gum man-db sysstat openssh libheif zip unrar wev cpio file-roller
```

### 8. File Management & Productivity Tools
Install a file manager, clipboard manager, screenshot tools, and other productivity utilities.
- [ ] Status
```bash
pacman -S --needed tealdeer iotop iftop ethtool httrack filezilla handbrake cliphist grim slurp wl-clipboard tree fzf swaync swayosd compsize clang obsidian qbittorrent thunar thunar-archive-plugin obs-studio audacity cava ttyper termusic eza fd ffmpegthumbnailer dysk
```

### 9. Optical Character Recognition (OCR)
Install the Tesseract OCR engine.
- [ ] Status
```bash
pacman -S --needed tesseract
```

> [!TIP] Installing Tesseract Language Data
> After the command above completes, `pacman` will prompt you to select optional packages for language data. For English support, find `tesseract-data-eng` in the list, type its corresponding number, and press Enter to install it. (USUALLY 30TH)

### 10. Core Applications & Shell Enhancements
Install final applications like a web browser and media player, along with powerful shell tools like Zsh, Starship, and Bat.
- [ ] Status
```bash
pacman -S --needed logrotate lshw ffmpeg mpv mpv-mpris firefox gnome-keyring libsecret yad yazi zellij zsh zsh-syntax-highlighting starship imagemagick bat krita uv rq jq bc zathura zathura-pdf-mupdf meson cmake wavemon
```

---

### 11. Nvim stuff. 
- [ ] Status
```bash
pacman -S --needed luarocks ripgrep fzf viu chafa ueberzugpp
```

---

### 12. Gnome Apps

```bash
pacman -S --needed snapshot loupe gnome-text-editor blanket collision errands identity impression gnome-disk-utility gnome-calculator gnome-clocks baobab
```

---

### 13. Games 
```bash
pacman -S --needed chess-tui cmatrix rebels-in-the-sky 0ad openra warzone2100 wesnoth freeciv supertuxkart endless-sky wesnoth
```
### See Also
For alternative hardware or additional software, refer to these notes:
- [ ] only for pc's with nvidia gpu [[Nvidia Packages]] 
- [ ] extra stuff [[Optional packages]]


- (if you have an nvidia gpu and you don't install this while also restoring backup, you'll get an error logging in, make sure to uncomment this line in .config/uwsm/env-hyprland `export AQ_DRM_DEVICES=/dev/dri/card1`and if it still doesn't login, try commenting out the display thing `monitor=eDP-1,1920x1080@60,0x0,1.6` in the hyprland config )