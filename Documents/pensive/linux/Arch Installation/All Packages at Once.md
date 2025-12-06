This is not recommended at all, but if you're in a hurry you're can use this. this has everything including the grub packages the only thing it doesn't include are the **NVIDIA drivers** 


```bash
pacman -S --needed intel-media-driver mesa vulkan-intel mesa-utils intel-gpu-tools libva libva-utils vulkan-icd-loader vulkan-tools sof-firmware linux-firmware hyprland uwsm xorg-xwayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xorg-xhost polkit hyprpolkitagent xdg-utils socat inotify-tools file qt5-wayland qt6-wayland gtk3 gtk4 nwg-look qt5ct qt6ct qt6-svg qt6-multimedia-ffmpeg kvantum adw-gtk-theme matugen ttf-font-awesome ttf-jetbrains-mono-nerd noto-fonts-emoji sassc waybar swww hyprlock hypridle hyprsunset hyprpicker swaync swayosd rofi libdbusmenu-qt5 libdbusmenu-glib brightnessctl pipewire wireplumber pipewire-pulse playerctl bluez bluez-utils blueman bluetui pavucontrol gst-plugin-pipewire libcanberra btrfs-progs compsize zram-generator udisks2 udiskie dosfstools ntfs-3g gvfs gvfs-mtp gvfs-nfs gvfs-smb xdg-user-dirs usbutils usbmuxd gparted gnome-disk-utility baobab unzip zip unrar 7zip cpio file-roller rsync grsync thunar thunar-archive-plugin networkmanager iwd nm-connection-editor inetutils wget curl openssh firewalld vsftpd reflector bmon ethtool httrack filezilla qbittorrent wavemon firefox arch-wiki-lite arch-wiki-docs kitty zsh zsh-syntax-highlighting starship expac zsh-autosuggestions fastfetch bat eza fd tealdeer yazi zellij gum man-db ttyper tree fzf less ripgrep git meson cmake clang python-pipx uv rq jq bc luarocks viu chafa ueberzugpp ffmpeg mpv mpv-mpris swappy swayimg imagemagick libheif obs-studio audacity handbrake guvcview ffmpegthumbnailer krita grim slurp wl-clipboard cliphist tesseract btop htop nvtop inxi sysstat sysbench logrotate acpid tlp tlp-rdw thermald powertop ncdu gdu iotop iftop lshw wev pacman-contrib gnome-keyring libsecret yad dysk fwupd snapshot loupe gnome-text-editor blanket collision errands identity impression gnome-calculator gnome-clocks obsidian zathura zathura-pdf-mupdf termusic cava chess-tui cmatrix cache seahorse lua-language-server shellcheck caligula
```

#### games
```bash
pacman -S --needed rebels-in-the-sky openra warzone2100 wesnoth freeciv supertuxkart endless-sky 0ad
```

> [!note] Only install this if you have an **intel** mobile chip between **5th gen and 11th gen** (hardware encoding/decoding)
>```bash
>pacman intel-media-sdk
> ```