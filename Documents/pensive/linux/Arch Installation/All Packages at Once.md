This is not recommended at all, but if you're in a hurry you're can use this. this has everything including the grub packages the only thing it doesn't include are the **NVIDIA drivers** 


```bash
pacman -S --needed intel-media-driver mesa vulkan-intel mesa-utils intel-gpu-tools libva libva-utils vulkan-icd-loader vulkan-tools intel-ucode btrfs-progs zram-generator hyprland xorg-xwayland uwsm qt5-wayland qt6-wayland xdg-desktop-portal-gtk gtk3 gtk4 nwg-look qt5ct qt6ct qt6-svg qt6-multimedia-ffmpeg kvantum hyprpolkitagent xorg-xhost polkit xdg-desktop-portal-hyprland xdg-utils ttf-font-awesome ttf-jetbrains-mono-nerd noto-fonts-emoji waybar libdbusmenu-qt5 socat swww inotify-tools sassc file libdbusmenu-glib fastfetch hyprlock hypridle hyprsunset swappy rofi playerctl brightnessctl vsftpd fwupd featherpad networkmanager iwd nm-connection-editor compsize ncdu kitty pavucontrol unzip swayimg python-pipx arch-wiki-lite arch-wiki-docs pipewire wireplumber pipewire-pulse bluez bluez-utils blueman dosfstools sof-firmware gst-plugin-pipewire git wget curl xdg-user-dirs gvfs firewalld udisks2 udiskie tlp tlp-rdw thermald powertop 7zip usbutils usbmuxd gparted ntfs-3g acpid pacman-contrib nvtop btop inxi less dialog tealdeer iotop iftop ethtool httrack filezilla handbrake cliphist grim slurp wl-clipboard tree fzf thunar swaync compsize clang obsidian gnome-disk-utility logrotate lshw ffmpeg mpv mpv-mpris firefox gnome-keyring libsecret yad yazi zellij zsh zsh-syntax-highlighting starship imagemagick bat krita uv rq jq bc zathura zathura-pdf-mupdf grub efibootmgr grub-btrfs os-prober man-db sysstat qbittorrent openssh libheif zip unrar wev cpio gnome-calculator baobab gnome-clocks hyprpicker guvcview file-roller thunar-archive-plugin
```


> [!note] Only install this if you have an **intel** mobile chip between **5th gen and 11th gen** (hardware encoding/decoding)
>```bash
>pacman intel-media-sdk
> ```