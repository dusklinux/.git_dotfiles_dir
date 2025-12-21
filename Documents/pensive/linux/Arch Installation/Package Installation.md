
>[!tip] Recommended to enable simultaneous downloads by un-commentating and setting `ParallelDownloads = 5`, especially useful if your downloads are slow for some reason in-spite of a fast connection.
>```bash
>nvim /etc/pacman.conf
>```



## Not Recommanded to install all at once but here it is anyway. 
[[All Packages at Once]]

# Phased Package Installation

This list organizes your system packages into logical groups for a cleaner installation process. All duplicates have been removed, and related tools (like Btrfs utilities or Nvim dependencies) are grouped together.

> [!TIP]
> 
> Install these groups one by one. If a group fails, it is easier to troubleshoot than a single massive command.

## 1. Graphics, Drivers & Firmware (Intel 12th Gen)

_Core GPU drivers, hardware acceleration, microcode, and firmware._


> [!note] Only install this if you have an **intel** mobile chip between **5th gen and 11th gen** (hardware encoding/decoding)
>```bash
>pacman -S --needed intel-media-sdk
> ```


```
pacman -S --needed intel-media-driver mesa vulkan-intel mesa-utils intel-gpu-tools libva libva-utils vulkan-icd-loader vulkan-tools sof-firmware linux-firmware acpi_call
```

- [ ] Status

## 2. Hyprland Core & Wayland Base

_The compositor, session management, portals, and security authentication._

```
pacman -S --needed hyprland uwsm xorg-xwayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xorg-xhost polkit hyprpolkitagent xdg-utils socat inotify-tools file
```

- [ ] Status

## 3. GUI Appearance, Toolkits & Fonts

_Qt/GTK themes, libraries required for apps to look native, and fonts._

```
pacman -S --needed qt5-wayland qt6-wayland gtk3 gtk4 nwg-look qt5ct qt6ct qt6-svg qt6-multimedia-ffmpeg kvantum adw-gtk-theme matugen ttf-font-awesome ttf-jetbrains-mono-nerd noto-fonts-emoji sassc
```

- [ ] Status

## 4. Hyprland Desktop Experience

_Status bar, wallpaper, lock screen, notifications, launcher, and OSD._

```
pacman -S --needed waybar swww hyprlock hypridle hyprsunset hyprpicker swaync swayosd rofi libdbusmenu-qt5 libdbusmenu-glib brightnessctl
```

- [ ] Status

## 5. Audio & Bluetooth (Pipewire Stack)

_Audio server, bluetooth management, and volume controls._

```
pacman -S --needed pipewire wireplumber pipewire-pulse playerctl bluez bluez-utils blueman bluetui pavucontrol gst-plugin-pipewire libcanberra
```

- [ ] Status

## 6. File System, Disks & Archiving

_Btrfs tools, mounting utilities, and archive managers._

```
pacman -S --needed btrfs-progs compsize zram-generator udisks2 udiskie dosfstools ntfs-3g gvfs gvfs-mtp gvfs-nfs gvfs-smb xdg-user-dirs usbutils usbmuxd gparted gnome-disk-utility baobab unzip zip unrar 7zip cpio file-roller rsync grsync thunar thunar-archive-plugin
```

- [ ] Status

## 7. Networking & Internet

_Network managers, browsers, download tools, and SSH._

```
pacman -S --needed networkmanager iwd network-manager-applet nm-connection-editor inetutils wget curl openssh firewalld vsftpd reflector bmon ethtool httrack filezilla qbittorrent wavemon firefox arch-wiki-lite arch-wiki-docs aria2 uget
```

- [ ] Status

## 8. Terminal, Shell & CLI Tools

_Zsh, terminal emulator, and modern Rust-based CLI replacements._

```
pacman -S --needed kitty zsh zsh-syntax-highlighting starship fastfetch bat eza fd tealdeer yazi zellij gum man-db ttyper tree fzf less ripgrep expac zsh-autosuggestions calcurse iperf3 pkgstats libqalculate
```

- [ ] Status

## 9. Development & Neovim Dependencies

_Build tools, languages, and image previewers for Neovim/Yazi._

```
pacman -S --needed neovim git git-delta meson cmake clang uv rq jq bc viu chafa ueberzugpp ccache mold shellcheck fd ripgrep fzf shfmt stylua prettier tree-sitter-cli
```


Installing using npm
```bash
sudo npm install -g neovim
```

- [ ] Status

## 10. Multimedia & Content Creation

_Video players, recording (OBS), image editing, and screenshot tools._


> [!TIP] Installing Tesseract Language Data
> After the command above completes, `pacman` will prompt you to select optional packages for language data. For English support, find `tesseract-data-eng` in the list, type its corresponding number, and press Enter to install it. (USUALLY 30TH)


```
pacman -S --needed ffmpeg mpv mpv-mpris swappy swayimg resvg imagemagick libheif obs-studio audacity handbrake guvcview ffmpegthumbnailer krita grim slurp wl-clipboard cliphist tesseract-data-eng
```

- [ ] Status

## 11. System Management & Monitoring

_Power management, system stats, logs, and security keyrings._

```
pacman -S --needed btop htop nvtop inxi sysstat sysbench logrotate acpid tlp tlp-rdw thermald powertop gdu iotop iftop lshw wev pacman-contrib gnome-keyring libsecret seahorse yad dysk fwupd caligula
```

- [ ] Status

## 12. Gnome Utilities Suite

_Specific Gnome apps for productivity and utilities._

```
pacman -S --needed snapshot cameractrls loupe gnome-text-editor blanket collision errands identity impression gnome-calculator gnome-clocks showmethekey
```

- [ ] Status

## 13. Productivity & Leisure

_PDF readers, note-taking, and miscellaneous TUI apps._

```
pacman -S --needed obsidian zathura zathura-pdf-mupdf termusic cava
```

- [ ] Status

## 14. Games

_Strategy and terminal-based games._

```
pacman -S --needed chess-tui cmatrix rebels-in-the-sky 0ad openra warzone2100 wesnoth freeciv supertuxkart endless-sky
```

- [ ] Status



### See Also
For alternative hardware or additional software, refer to these notes:
- [ ] only for pc's with nvidia gpu [[Nvidia Packages]] 
- [ ] extra stuff [[Optional packages]]
- [ ] Packages's discriptions. [[Package Discription]]

- (if you have an nvidia gpu and you don't install this while also restoring backup, you'll get an error logging in, make sure to uncomment this line in .config/uwsm/env-hyprland `export AQ_DRM_DEVICES=/dev/dri/card1`and if it still doesn't login, try commenting out the display thing `monitor=eDP-1,1920x1080@60,0x0,1.6` in the hyprland config )