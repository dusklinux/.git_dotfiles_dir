|**Category**|**Package Name**|**Description**|
|---|---|---|
|**Audio (PipeWire)**|`pipewire`|A modern multimedia server that handles audio and video streams. It is the replacement for PulseAudio and JACK, offering low-latency processing and better security.|
|**Audio (PipeWire)**|`wireplumber`|A powerful session and policy manager for PipeWire. It manages audio devices, streams, and permissions, ensuring that audio routing works automatically.|
|**Audio (PipeWire)**|`pipewire-pulse`|A compatibility layer that allows PipeWire to emulate a PulseAudio server. This ensures that applications built for PulseAudio work seamlessly with PipeWire.|
|**Audio (PipeWire)**|`pipewire-alsa`|A compatibility plugin that allows ALSA applications to use PipeWire as their backend. Critical for legacy Linux audio support.|
|**Audio (PipeWire)**|`sof-firmware`|Sound Open Firmware. Provides the necessary binary firmware for modern Intel audio DSPs (often required for audio on newer Intel laptops like your 12th gen).|
|**Audio (PipeWire)**|`gst-plugin-pipewire`|GStreamer plugin for PipeWire. Allows GStreamer-based applications (like many GNOME apps) to record and play audio/video via PipeWire.|
|**Audio (PipeWire)**|`easyeffects`|A highly advanced audio manipulation tool for PipeWire. It includes an equalizer, compressor, reverberation, and other effects for system-wide audio processing.|
|**Audio (PipeWire)**|`qpwgraph`|A graphical user interface for managing PipeWire connections. It visualizes audio/video nodes and allows you to drag-and-drop cables between apps and devices.|
|**Audio (Legacy)**|`pulseaudio`|The traditional sound server system for POSIX OSs. (Note: Only install if _not_ using PipeWire; PipeWire is generally recommended for Hyprland).|
|**Audio (Legacy)**|`pulseaudio-alsa`|ALSA configuration for PulseAudio compatibility.|
|**Audio (Legacy)**|`xfce4-pulseaudio-plugin`|A panel plugin for the Xfce desktop to control PulseAudio volume (useful if using Xfce components, otherwise optional).|
|**Audio & Bluetooth**|`pavucontrol`|PulseAudio Volume Control. Despite the name, it is the standard GTK GUI for controlling audio devices and volume levels on both PulseAudio and PipeWire systems.|
|**Audio & Bluetooth**|`bluez`|The official Linux Bluetooth protocol stack. It provides the core background daemons necessary to use Bluetooth devices.|
|**Audio & Bluetooth**|`bluez-utils`|Contains command-line utilities (like `bluetoothctl`) for interacting with and configuring the BlueZ Bluetooth stack.|
|**Audio & Bluetooth**|`blueman`|A full-featured GTK+ Bluetooth manager. Provides a GUI to pair devices, send files, and manage Bluetooth audio profiles.|
|**Audio & Bluetooth**|`bluetui`|A Terminal User Interface (TUI) for managing Bluetooth. A lightweight alternative to Blueman for pairing and connecting devices from the terminal.|
|**Audio & Bluetooth**|`libcanberra`|A library for playing simple event sounds (like beeps or alerts) in desktop applications.|
|**Audio & Bluetooth**|`cava`|Console Audio Visualizer for ALSA (and PulseAudio/PipeWire). Creates dynamic audio visualizations (bars/waves) in your terminal.|
|**Development**|`git`|The distributed version control system. Essential for managing code, cloning repositories (including AUR packages), and versioning.|
|**Development**|`python-pipx`|A tool to install and run Python applications in isolated environments. Prevents system-wide Python package conflicts (critical on Arch).|
|**Development**|`python-pip`|The standard package installer for Python. (Note: On Arch, use `pipx` or pacman for system tools; use `pip` only inside virtual environments).|
|**Development**|`uv`|An extremely fast Python package installer and resolver, written in Rust. Designed as a drop-in replacement for `pip` and `pip-tools`.|
|**Development**|`meson`|A high-performance build system used by many open-source projects (especially GNOME and Wayland components) to compile software.|
|**Development**|`cmake`|A cross-platform open-source family of tools designed to build, test, and package software. Required for compiling many C/C++ projects.|
|**Development**|`clang`|A compiler front end for the C, C++, and Objective-C languages. Often used as a faster, more modern alternative to GCC.|
|**Development**|`luarocks`|The package manager for Lua modules. Essential for managing dependencies for Neovim plugins if they are written in Lua.|
|**Development**|`docker`|The industry-standard platform for developing, shipping, and running applications in containers.|
|**Development**|`docker-compose`|A tool for defining and running multi-container Docker applications using YAML configuration files.|
|**Development**|`docker-buildx`|A Docker CLI plugin for extended build capabilities with BuildKit, enabling multi-architecture builds and advanced caching.|
|**Development**|`lazygit`|A simple terminal UI for git commands. It visualizes branches, diffs, and commits, making complex git operations easier.|
|**Development**|`jq`|A lightweight and flexible command-line JSON processor. Essential for parsing JSON output in shell scripts.|
|**Development**|`rq`|A tool similar to `jq` but for other formats like TOML, YAML, and XML, or a job queue system (likely Record Query in this context).|
|**File Management**|`thunar`|A modern, lightweight, and fast file manager for the Xfce desktop environment. Works well as a GUI file manager in Hyprland.|
|**File Management**|`thunar-archive-plugin`|A plugin for Thunar that adds context menu options to create and extract archives (zip, tar, etc.) directly within the file manager.|
|**File Management**|`yazi`|A blazing fast terminal file manager written in Rust, based on non-blocking async I/O. It supports image previews and is highly customizable.|
|**File Management**|`ranger`|A text-based file manager with VI key bindings. (Note: `yazi` is the modern successor, but `ranger` is the classic choice).|
|**File Management**|`gnome-disk-utility`|Also known as "Disks". A graphical tool for managing disk drives, partitions, S.M.A.R.T. data, and formatting drives.|
|**File Management**|`gvfs`|GNOME Virtual File System. Allows file managers like Thunar to access trash, mount removable media, and access remote filesystems (SFTP/SMB).|
|**File Management**|`gvfs-mtp`|Adds support to GVFS for the Media Transfer Protocol (MTP), allowing you to access files on Android devices via USB.|
|**File Management**|`gvfs-nfs`|Adds support to GVFS for mounting Network File System (NFS) shares seamlessly in user space.|
|**File Management**|`gvfs-smb`|Adds support to GVFS for SMB/CIFS (Windows file sharing) networking protocols.|
|**File Management**|`ntfs-3g`|A stable, open-source NTFS driver that provides read and write support for Windows-formatted NTFS drives.|
|**File Management**|`dosfstools`|Utilities for creating, checking, and labeling FAT16/FAT32 filesystems (essential for managing the EFI partition).|
|**File Management**|`udisks2`|A daemon that manipulates storage devices. It handles mounting, unmounting, and querying storage devices in user space.|
|**File Management**|`udiskie`|An automounter for removable media (USBs) that sits in the system tray. Requires `udisks2` to function.|
|**File Management**|`xdg-user-dirs`|A tool to manage "well known" user directories like Downloads, Pictures, and Music, creating them and updating configuration files.|
|**File Management**|`file-roller`|An archive manager for the GNOME environment. Provides a GUI for creating and modifying archives.|
|**File Management**|`nautilus`|The default file manager for GNOME (also known as "Files"). A polished, user-friendly alternative to Thunar.|
|**File Management**|`sushi`|A previewer for Nautilus. Allows you to tap the spacebar to peek at files (images, audio, text) without opening them.|
|**File Management**|`nautilus-python`|Python bindings for Nautilus extensions, required for some advanced Nautilus plugins to function.|
|**File Management**|`nautilus-open-any-terminal`|An extension for Nautilus allowing you to open a terminal in the current folder via the context menu (supports Kitty, Alacritty, etc.).|
|**File Management**|`doublecmd-qt5`|Double Commander. A twin-panel file manager inspired by Total Commander. Powerful for heavy file operations.|
|**File Management**|`tumbler`|A D-Bus service for applications to request thumbnails. Essential for file managers like Thunar to show image previews.|
|**File Management**|`zip`|Compression and file packaging utility for .zip files.|
|**File Management**|`unzip`|Utility to unpack .zip archives.|
|**File Management**|`unrar`|Utility to unpack .rar archives.|
|**File Management**|`7zip`|A file archiver with a high compression ratio. Handles .7z files and many others.|
|**File Management**|`cpio`|A utility for creating and extracting archives, often used for initramfs images or RPM packages.|
|**File Management**|`tree`|A recursive directory listing command that produces a depth-indented listing of files (visual tree structure).|
|**Fonts**|`ttf-jetbrains-mono-nerd`|The JetBrains Mono typeface patched with Nerd Fonts glyphs. Excellent for coding and terminal use due to high legibility.|
|**Fonts**|`ttf-font-awesome`|An iconic font and CSS toolkit. Provides scalable vector icons (like social logos, UI elements) used by Waybar and other tools.|
|**Fonts**|`noto-fonts-emoji`|Google's Noto Color Emoji font. Essential for rendering colorful emojis in browsers and terminals.|
|**Fonts**|`ttf-dejavu`|A font family based on Bitstream Vera. Covers a very wide range of Unicode characters; a solid fallback font.|
|**Fonts**|`ttf-firacode-nerd`|Fira Code font patched with Nerd Fonts. Famous for its programming ligatures (combining symbols like `!=` into one).|
|**Fonts**|`noto-fonts`|The standard Google Noto font family (Serif, Sans, Mono) designed to support all languages with a harmonious look.|
|**Fonts**|`ttf-nerd-fonts-symbols`|A package containing _only_ the Nerd Font symbols/glyphs. Useful if you want to use a standard font but still have icons.|
|**Fonts**|`noto-fonts-cjk`|Noto Sans CJK. Provides support for Chinese, Japanese, and Korean characters (critical for Asian language support).|
|**Fonts**|`noto-fonts-extra`|Additional variants of the Noto font family (like Condensed or ExtraLight weights) not included in the base package.|
|**Games**|`chess-tui`|A simple chess game played directly in the terminal.|
|**Games**|`cmatrix`|Displays the scrolling "digital rain" effect from The Matrix in your terminal. Purely aesthetic.|
|**Games**|`rebels-in-the-sky`|A P2P multiplayer terminal game about space pirates playing basketball. Networked without a central server using libp2p.|
|**Games**|`0ad`|A free, open-source real-time strategy (RTS) game of ancient warfare, similar to Age of Empires.|
|**Games**|`openra`|An open-source implementation of the Command & Conquer: Red Alert engine. Allows playing classic RTS games on modern systems.|
|**Games**|`warzone2100`|A 3D post-apocalyptic real-time strategy game. Famous for its unit design system and tech trees.|
|**Games**|`wesnoth`|Battle for Wesnoth. A high-fantasy, turn-based tactical strategy game with a hexagonal grid.|
|**Games**|`freeciv`|A free, open-source turn-based strategy game inspired by the Civilization series.|
|**Games**|`supertuxkart`|A 3D open-source kart racing game featuring Tux the Linux penguin and other mascots.|
|**Games**|`endless-sky`|A 2D space trading and combat game. Explore the galaxy, trade goods, and fight pirates in a sandbox universe.|
|**GNOME Apps**|`snapshot`|The modern GNOME camera application. Simple and easy to use for taking photos and videos.|
|**GNOME Apps**|`loupe`|The modern GNOME image viewer. Written in Rust, it is fast and adapts well to different screen sizes.|
|**GNOME Apps**|`gnome-text-editor`|A simple, core text editor for GNOME. It replaces Gedit in modern GNOME installs with a cleaner UI.|
|**GNOME Apps**|`blanket`|An application that plays ambient sounds (rain, white noise, coffee shop) to help you focus or relax.|
|**GNOME Apps**|`collision`|A utility to check and verify file hashes (MD5, SHA256, etc.) to ensure file integrity.|
|**GNOME Apps**|`errands`|A clean and simple todo/task management application designed for GNOME.|
|**GNOME Apps**|`identity`|An app to compare multiple versions of an image or video side-by-side. Useful for checking quality differences.|
|**GNOME Apps**|`impression`|A utility to create bootable USB drives from disk images (ISO files). A GNOME alternative to Etcher or Rufus.|
|**GNOME Apps**|`gnome-calculator`|The standard calculator application for the GNOME desktop.|
|**GNOME Apps**|`gnome-clocks`|A simple application to manage world clocks, alarms, a stopwatch, and a timer.|
|**GNOME Apps**|`baobab`|Disk Usage Analyzer. A graphical tool that visualizes directory sizes as rings or treemaps to find what's eating space.|
|**Graphics (Intel)**|`intel-media-driver`|The VA-API (Video Acceleration API) implementation for Intel Gen8+ graphics. Provides hardware acceleration for video decoding/encoding.|
|**Graphics (Intel)**|`mesa`|The open-source implementation of OpenGL and Vulkan. It is the core graphics driver stack for Linux gaming and desktop rendering.|
|**Graphics (Intel)**|`vulkan-intel`|The dedicated Intel Vulkan driver (ANV). Required for running Vulkan-based games and applications on Intel GPUs.|
|**Graphics (Intel)**|`mesa-utils`|Contains utility programs like `glxgears` and `glxinfo` to test OpenGL functionality and view driver information.|
|**Graphics (Intel)**|`intel-gpu-tools`|A suite of tools for debugging and monitoring Intel GPUs. Includes `intel_gpu_top` for viewing real-time GPU usage.|
|**Graphics (Intel)**|`libva`|The main library for the Video Acceleration API. Acts as the interface between apps and the hardware driver.|
|**Graphics (Intel)**|`libva-utils`|Utilities for VA-API, including `vainfo` which verifies if hardware video acceleration is correctly enabled.|
|**Graphics (Intel)**|`vulkan-icd-loader`|The Installable Client Driver loader. It finds and loads the correct Vulkan driver for your hardware.|
|**Graphics (Intel)**|`vulkan-tools`|Official tools for Vulkan development and diagnostics, including `vulkaninfo` to check Vulkan support.|
|**Graphics (Intel)**|`intel-ucode`|Microcode updates for Intel CPUs. Loads patches during boot to fix processor bugs and security vulnerabilities (Critical).|
|**Graphics (Intel)**|`intel-media-sdk`|Provides access to hardware-accelerated video processing (QuickSync) for older Intel CPUs (Gen 5-11). (User note: Only install if applicable).|
|**Hyprland & Wayland**|`hyprland`|A dynamic tiling Wayland compositor based on wlroots. Known for its fluid animations, blur effects, and high configurability.|
|**Hyprland & Wayland**|`xorg-xwayland`|An X server running as a Wayland client. Allows you to run legacy X11 applications seamlessly inside Hyprland.|
|**Hyprland & Wayland**|`uwsm`|Universal Wayland Session Manager. Wraps Hyprland in systemd units to manage the session lifecycle, ensuring clean startups and shutdowns.|
|**Hyprland & Wayland**|`xdg-desktop-portal-hyprland`|The interface between Hyprland and sandboxed apps. Enables features like screen sharing and file pickers in Wayland.|
|**Hyprland & Wayland**|`hyprpolkitagent`|A simple Polkit authentication agent written in Qt/QML. It provides the GUI popup when an app asks for `sudo` or system privileges.|
|**Hyprland & Wayland**|`hyprlock`|A screen locking utility specifically built for Hyprland. Highly customizable visual locker.|
|**Hyprland & Wayland**|`hypridle`|An idle management daemon. Detects when you are inactive to turn off screens or trigger `hyprlock`.|
|**Hyprland & Wayland**|`hyprsunset`|A blue-light filter application for Hyprland (similar to f.lux or Redshift) to reduce eye strain at night.|
|**Hyprland & Wayland**|`hyprpicker`|A Wayland color picker. Allows you to click anywhere on your screen to grab the HEX or RGB color code of a pixel.|
|**Hyprland & Wayland**|`waybar`|A highly customizable Wayland bar for Hyprland. Displays workspaces, clock, battery, and custom modules (CSS styled).|
|**Hyprland & Wayland**|`swww`|A Solution for Wayland Wallpaper. An efficient wallpaper daemon that supports animated GIFs and smooth transition effects.|
|**Hyprland & Wayland**|`rofi`|A window switcher, application launcher, and dmenu replacement. (Note: On Wayland, usually `rofi-wayland` is preferred, but `rofi` runs via XWayland).|
|**Hyprland & Wayland**|`swaync`|Sway Notification Center. A notification daemon that provides a control center panel (DND, clear all) for Hyprland/Sway.|
|**Hyprland & Wayland**|`swayosd`|An OSD (On-Screen Display) daemon for brightness, volume, and Caps Lock events. Provides visual feedback when keys are pressed.|
|**Hyprland & Wayland**|`grim`|Grab Images. A command-line screenshot utility for Wayland. It captures the screen output to a file.|
|**Hyprland & Wayland**|`slurp`|Select a region. Works with `grim` to allow you to draw a box on the screen to screenshot a specific area.|
|**Hyprland & Wayland**|`swappy`|A Wayland-native snapshot editing tool. Opens screenshots immediately for annotation (arrows, text, blur) before saving.|
|**Hyprland & Wayland**|`grimblast`|A helper script that combines `grim`, `slurp`, and `wl-clipboard` to make taking screenshots easier (copy to clipboard, save to file, etc.).|
|**Hyprland & Wayland**|`wl-clipboard`|Command-line copy/paste utilities (`wl-copy`, `wl-paste`) for Wayland. Essential for sharing clipboard data between apps.|
|**Hyprland & Wayland**|`cliphist`|A clipboard manager for Wayland. Stores your clipboard history (text and images) so you can search and paste older items.|
|**Hyprland & Wayland**|`wlr-randr`|A command-line utility to manage display outputs (resolution, refresh rate, rotation) on wlroots-based compositors like Hyprland.|
|**Hyprland & Wayland**|`libinput-gestures`|A utility that reads touchpad gestures from libinput and maps them to custom shell commands (useful for workspace switching).|
|**Multimedia**|`mpv`|A free, open-source, and cross-platform media player. Extremely minimalist GUI but powerful command-line options and format support.|
|**Multimedia**|`mpv-mpris`|A plugin for mpv that allows it to be controlled by MPRIS clients (like `playerctl` or media keys on your keyboard).|
|**Multimedia**|`ffmpeg`|A complete, cross-platform solution to record, convert, and stream audio and video. The backbone of many media apps.|
|**Multimedia**|`ffmpegthumbnailer`|A lightweight video thumbnailer that can be used by file managers (like Thunar) to generate previews for video files.|
|**Multimedia**|`imagemagick`|A suite of tools for creating, editing, composing, or converting bitmap images. Powerful for batch processing images in terminal.|
|**Multimedia**|`libheif`|A library for decoding HEIF/HEIC images (the High Efficiency Image Format used by iPhones and modern cameras).|
|**Multimedia**|`obs-studio`|Open Broadcaster Software. The standard for video recording and live streaming.|
|**Multimedia**|`audacity`|A free, open-source, cross-platform audio software. Used for multi-track recording and editing sounds.|
|**Multimedia**|`handbrake`|A tool for converting video from nearly any format to a selection of modern, widely supported codecs.|
|**Multimedia**|`swayimg`|A lightweight image viewer for Wayland. It supports keyboard navigation and fits well into tiling window manager workflows.|
|**Multimedia**|`imv`|Image Viewer. A command-line driven image viewer intended for tiling window managers. (Not explicitly in lists, but often grouped here).|
|**Multimedia**|`yt-dlp`|A feature-rich command-line audio/video downloader. A fork of `youtube-dl` that is actively maintained and faster.|
|**Networking**|`networkmanager`|The standard Linux network configuration daemon. Manages WiFi, Ethernet, VPNs, and mobile broadband connections.|
|**Networking**|`nm-connection-editor`|A GTK GUI for NetworkManager. Allows advanced configuration of network profiles not exposed in simple applets.|
|**Networking**|`iwd`|iNet Wireless Daemon. A modern, lightweight wireless daemon written by Intel. Can be used standalone or as a backend for NetworkManager.|
|**Networking**|`inetutils`|A collection of common network programs (hostname, ping, ifconfig, etc.). Basic networking tools.|
|**Networking**|`openssh`|The premier connectivity tool for remote login with the SSH protocol. Includes `ssh` client and `sshd` server.|
|**Networking**|`wget`|A network utility to retrieve files from the web via HTTP, HTTPS, and FTP.|
|**Networking**|`curl`|A command line tool and library for transferring data with URLs. Supports a massive range of protocols.|
|**Networking**|`rsync`|A fast and versatile file copying tool. Famous for its delta-transfer algorithm, which only sends differences between source and destination.|
|**Networking**|`grsync`|A GTK GUI for `rsync`. Makes it easier to construct rsync commands for backups without memorizing flags.|
|**Networking**|`reflector`|A script that retrieves the latest Arch Linux mirror list, sorts them by speed/location, and updates your `pacman.d/mirrorlist`.|
|**Networking**|`ethtool`|A standard Linux utility for controlling network driver and hardware settings (speed, duplex, wake-on-lan).|
|**Networking**|`arp-scan`|A tool that sends ARP packets to hosts on the local network to discover active devices and their MAC addresses.|
|**Networking**|`wavemon`|An ncurses-based monitoring application for wireless network devices. Shows signal levels, noise, and other wifi parameters.|
|**Networking**|`crda`|Central Regulatory Domain Agent. Helps the kernel enforce radio frequency regulations (channels/power) based on your country.|
|**Networking**|`firewalld`|A firewall management tool that provides a dynamically managed firewall with support for network/firewall zones.|
|**Networking**|`vsftpd`|Very Secure FTP Daemon. A lightweight and secure FTP server for UNIX-like systems.|
|**Networking**|`speedtest-cli`|Command-line interface for testing internet bandwidth using speedtest.net.|
|**OCR**|`tesseract`|An optical character recognition (OCR) engine. It can read text from images.|
|**OCR**|`tesseract-data-eng`|The language data model required by Tesseract to recognize English text.|
|**Office & Text**|`libreoffice-fresh`|The "Fresh" version of the LibreOffice suite. Contains the absolute latest features for documents, spreadsheets, and presentations.|
|**Office & Text**|`obsidian`|A powerful knowledge base that works on top of a local folder of plain text Markdown files.|
|**Office & Text**|`zathura`|A highly customizable, keyboard-driven document viewer (PDF, DjVu, PS). Minimalist and efficient.|
|**Office & Text**|`zathura-pdf-mupdf`|The rendering backend for Zathura based on MuPDF. Provides fast and accurate PDF rendering.|
|**Office & Text**|`kate`|The Advanced Text Editor by KDE. Feature-rich with syntax highlighting, plugins, and a built-in terminal.|
|**System & Hardware**|`btrfs-progs`|Userspace utilities for the Btrfs filesystem. Required to create, check, and modify your Btrfs partitions.|
|**System & Hardware**|`zram-generator`|A systemd unit generator that automatically sets up zram (compressed RAM) devices for swap, improving performance on low-RAM situations (or preventing disk swap).|
|**System & Hardware**|`acpid`|Advanced Configuration and Power Interface Event Daemon. Handles power events like closing the lid or pressing the power button.|
|**System & Hardware**|`polkit`|A toolkit for defining and handling the policy that allows unprivileged processes to speak to privileged processes (e.g., sudo GUI prompts).|
|**System & Hardware**|`tlp`|A feature-rich command-line utility for Linux power management. Optimizes battery life on laptops automatically.|
|**System & Hardware**|`tlp-rdw`|TLP Radio Device Wizard. Handles event-based switching of radios (e.g., disable generic wifi when ethernet is plugged in).|
|**System & Hardware**|`thermald`|A Linux thermal management daemon. Monitors temperatures and prevents overheating by adjusting CPU cooling methods.|
|**System & Hardware**|`powertop`|A diagnostics tool to analyze power consumption and power management issues. Can autotune settings for better battery life.|
|**System & Hardware**|`power-profiles-daemon`|A DBus daemon that allows changing system power profiles (Performance, Balanced, Power Saver) easily. (Alternative to TLP).|
|**System & Hardware**|`lm_sensors`|Provides tools to read temperature, voltage, and fan speed sensors on your motherboard and CPU.|
|**System & Hardware**|`smartmontools`|Tools to control and monitor storage systems using the S.M.A.R.T. system built into most modern hard drives and SSDs.|
|**System & Hardware**|`turbostat`|A tool that reports processor topology, frequency, idle power-state statistics, temperature, and power on Intel processors.|
|**System & Hardware**|`usbutils`|Contains `lsusb` and other utilities for inspecting USB devices connected to the system.|
|**System & Hardware**|`usbmuxd`|A socket daemon to multiplex connections from and to iOS devices. Essential if you connect an iPhone via USB.|
|**System & Hardware**|`pacman-contrib`|Contributed scripts and tools for pacman, including `paccache` for cleaning the package cache.|
|**System & Hardware**|`logrotate`|A system utility that manages the automatic rotation and compression of log files to prevent them from filling the disk.|
|**System & Hardware**|`lshw`|Hardware Lister. A small tool to provide detailed information on the hardware configuration of the machine.|
|**System & Hardware**|`supergfxctl`|A utility specifically for ASUS laptops to manage hybrid graphics switching (MUX switch) and GPU power profiles.|
|**System & Hardware**|`asusctltray`|A system tray application that provides a GUI for controlling `asusctl` and `supergfxctl` features.|
|**System Monitoring**|`btop`|A resource monitor that shows usage and stats for processor, memory, disks, network and processes. Has a beautiful TUI.|
|**System Monitoring**|`nvtop`|Neat Videocard TOP. A task monitor for GPUs (Intel, AMD, NVIDIA). Shows utilization, temperature, and memory usage.|
|**System Monitoring**|`httop`|(Likely `htop` or `btop` typo, assuming `htop`): An interactive process viewer for the terminal.|
|**System Monitoring**|`iotop`|A simple top-like I/O monitor. Shows which processes are reading or writing to the disk in real time.|
|**System Monitoring**|`iftop`|Display bandwidth usage on an interface by host. Shows who you are communicating with and at what speed.|
|**System Monitoring**|`sysstat`|A collection of performance monitoring tools for Linux (includes `iostat`, `mpstat`, `sar`) to track system activity over time.|
|**System Monitoring**|`inxi`|A full-featured CLI system information script. Great for generating hardware reports for support forums.|
|**System Monitoring**|`bmon`|Bandwidth Monitor. A text-based bandwidth monitor and rate estimator for networks.|
|**System Monitoring**|`s-tui`|Stress Terminal UI. Monitors CPU temperature, frequency, power and utilization in a graphical way from the terminal.|
|**System Monitoring**|`stress-ng`|A tool to stress test your system. It can load various physical subsystems of a computer (CPU, cache, drive, etc.).|
|**System Monitoring**|`mission-center`|A modern, GTK4-based system monitor (similar to Windows Task Manager) showing CPU, RAM, and GPU usage graphs.|
|**System Monitoring**|`dysk`|A linux utility to get information on filesystems. It's a more intuitive and colorful alternative to the standard `df` command.|
|**System Monitoring**|`ncdu`|NCurses Disk Usage. A disk usage analyzer with a ncurses interface. Fast way to see what is taking up space in the terminal.|
|**System Monitoring**|`gdu`|Go Disk Usage. A disk usage analyzer written in Go. similar to `ncdu` but generally faster on SSDs.|
|**System Monitoring**|`compsize`|A tool for Btrfs filesystems that takes a file/directory and calculates the disk usage and compression ratio.|
|**Terminal & Shell**|`kitty`|A GPU-accelerated terminal emulator. It supports ligatures, images, and is highly scriptable. The standard for Hyprland.|
|**Terminal & Shell**|`zsh`|The Z shell. An extended Bourne shell with many improvements, including better tab completion and plugin support.|
|**Terminal & Shell**|`zsh-syntax-highlighting`|A plugin for Zsh that provides syntax highlighting for commands as you type them (green for valid, red for invalid).|
|**Terminal & Shell**|`zsh-autosuggestions`|A plugin for Zsh that suggests commands as you type based on history and completions (similar to Fish shell).|
|**Terminal & Shell**|`starship`|A cross-shell prompt. It is extremely fast, customizable, and shows relevant info (git status, package versions) automatically.|
|**Terminal & Shell**|`bat`|A `cat` clone with syntax highlighting and Git integration. Makes reading code in the terminal much easier.|
|**Terminal & Shell**|`eza`|A modern replacement for `ls`. It features colors, icons, and better defaults for listing file information.|
|**Terminal & Shell**|`fd`|A simple, fast and user-friendly alternative to `find`. Ignores hidden files and `.gitignore` patterns by default.|
|**Terminal & Shell**|`ripgrep`|A line-oriented search tool that recursively searches the current directory for a regex pattern. Faster replacement for `grep`.|
|**Terminal & Shell**|`fzf`|A general-purpose command-line fuzzy finder. Can be used to find files, command history, and processes interactively.|
|**Terminal & Shell**|`zoxide`|A smarter `cd` command that learns your habits. Allows you to jump to frequently used directories with just a few keystrokes.|
|**Terminal & Shell**|`tealdeer`|A fast implementation of `tldr` in Rust. Provides simplified, community-driven man pages with practical examples.|
|**Terminal & Shell**|`man-db`|The system that provides the `man` command. Manages and displays the on-line manual documentation pages.|
|**Terminal & Shell**|`man-pages`|The actual content for the Linux man pages (system calls, libraries, etc.).|
|**Terminal & Shell**|`gum`|A tool for glamorous shell scripts. Allows you to create interactive TUI scripts with bubbles, inputs, and filters.|
|**Terminal & Shell**|`bc`|Basic Calculator. An arbitrary precision calculator language. Useful for math operations in the terminal or scripts.|
|**Terminal & Shell**|`less`|A terminal pager program used to view (but not change) the contents of a text file one screen at a time.|
|**Terminal & Shell**|`termusic`|A terminal music player written in Rust. Minimalist UI but capable of playing local files.|
|**Terminal & Shell**|`ttyper`|A terminal-based typing test. Good for practicing touch typing without leaving the command line.|
|**Terminal & Shell**|`arch-wiki-lite`|A light version of the Arch Wiki that can be searched and viewed offline from the terminal.|
|**Terminal & Shell**|`arch-wiki-docs`|The documentation files for the Arch Wiki.|
|**Terminal & Shell**|`wikiman`|An offline search engine for manual pages, Arch Wiki, Gentoo Wiki, and other documentation sources.|
|**Theming (GTK/Qt)**|`qt5-wayland`|Provides the Wayland platform plugin for Qt5 applications. Essential for Qt5 apps to run natively on Hyprland.|
|**Theming (GTK/Qt)**|`qt6-wayland`|Provides the Wayland platform plugin for Qt6 applications. Essential for modern Qt apps.|
|**Theming (GTK/Qt)**|`qt5ct`|Qt5 Configuration Tool. Allows you to configure themes, fonts, and icons for Qt5 applications outside of KDE.|
|**Theming (GTK/Qt)**|`qt6ct`|Qt6 Configuration Tool. The same as `qt5ct` but for Qt6 applications.|
|**Theming (GTK/Qt)**|`qt6-svg`|Provides SVG image format support for Qt6 applications. Necessary for icons in many Qt apps.|
|**Theming (GTK/Qt)**|`qt6-multimedia-ffmpeg`|FFmpeg backend for Qt6 Multimedia. Enables Qt6 apps to play audio and video.|
|**Theming (GTK/Qt)**|`kvantum`|A SVG-based theme engine for Qt. Allows Qt applications to look very distinct and match specific aesthetic themes.|
|**Theming (GTK/Qt)**|`gtk3`|The GTK+ 3 library. Required by a vast number of Linux GUI applications.|
|**Theming (GTK/Qt)**|`gtk4`|The latest GTK 4 library. Used by modern GNOME apps and newer software.|
|**Theming (GTK/Qt)**|`nwg-look`|A GTK3 settings editor for wlroots compositors. The standard tool on Hyprland to change GTK themes, icons, and fonts.|
|**Theming (GTK/Qt)**|`xdg-desktop-portal-gtk`|A backend implementation for xdg-desktop-portal using GTK. Provides native file dialogs for GTK apps running in Wayland.|
|**Theming (GTK/Qt)**|`adw-gtk-theme`|A GTK theme that mimics the "Libadwaita" style of GNOME 40+, making legacy GTK3 apps look modern.|
|**Theming (GTK/Qt)**|`matugen`|A Material You color generation tool. Generates color palettes from your wallpaper for system-wide theming.|
|**Theming (GTK/Qt)**|`sassc`|A C implementation of Sass. Used by many theme generators and tools (like Waybar styles) to compile CSS.|
|**Theming (Style)**|`everforest-gtk-theme-git`|A soft, natural, and comfortable dark GTK theme based on the Everforest color palette.|
|**Theming (Style)**|`gruvbox-dark-gtk`|A retro groove color scheme for GTK. Popular for its reddish-brown, warm dark tones.|
|**Theming (Style)**|`nordic-darker-theme`|A dark GTK theme based on the popular Nord color palette (cool, bluish-grey tones).|
|**Theming (Style)**|`papirus-icon-theme`|A popular, flat, and material-design inspired icon theme. covers a massive amount of applications.|
|**Theming (Style)**|`bibata-cursor-theme`|A modern, material-based cursor theme. Smooth and very readable on high-DPI screens.|
|**Utilities**|`rofi`|(Listed again for completeness as user had it in multiple contexts) A window switcher and launcher.|
|**Utilities**|`playerctl`|A command-line utility to control media players (Spotify, mpv, browsers) using the MPRIS standard.|
|**Utilities**|`brightnessctl`|A lightweight utility to read and control device brightness (screen backlight, keyboard LEDs).|
|**Utilities**|`fwupd`|A daemon to allow session software to update device firmware (BIOS, peripherals) on your local machine.|
|**Utilities**|`libdbusmenu-qt5`|Library for passing menus over DBus (Qt5). Used to show tray menus for some applications.|
|**Utilities**|`libdbusmenu-glib`|Library for passing menus over DBus (GLib). Used to show tray menus for GTK applications.|
|**Utilities**|`socat`|Multipurpose relay (SOcket CAT). Connects two bidirectional byte streams. Used by Hyprland scripts to listen to socket events.|
|**Utilities**|`inotify-tools`|A set of command-line programs to interface with the inotify subsystem. Used to trigger scripts when files change.|
|**Utilities**|`file`|A standard utility to determine the file type of a given file by checking its "magic numbers".|
|**Utilities**|`fastfetch`|A system information tool (like Neofetch) written in C. Highly performant and customizable.|
|**Utilities**|`gnome-keyring`|A daemon that stores passwords and secrets (like WiFi keys) securely.|
|**Utilities**|`libsecret`|A library for storing and retrieving passwords and other secrets. Used by applications to talk to gnome-keyring.|
|**Utilities**|`yad`|Yet Another Dialog. Displays GTK+ dialog boxes from shell scripts. Useful for creating simple GUIs for scripts.|
|**Utilities**|`zellij`|A terminal workspace/multiplexer (like tmux) written in Rust. Features a layout engine and plugins.|
|**Utilities**|`wev`|Wayland Event Viewer. A tool to debug input events. Useful for finding the key codes of keys on your keyboard.|
|**Utilities**|`dunst`|A lightweight and customizable notification daemon. (Alternative to SwayNC, noted in optional packages).|
|**Web**|`firefox`|The Mozilla Firefox web browser. A free and open-source web browser.|
|**Tools (Images)**|`viu`|A terminal image viewer. Allows you to view images directly inside the terminal window.|
|**Tools (Images)**|`chafa`|A terminal graphics/image viewer that works even in terminals without full graphics support (using characters).|
|**Tools (Images)**|`ueberzugpp`|A command line utility to draw images on terminals. A C++ rewrite of the classic ueberzug.|
|**Utilities**|`tldr`|(Listed as alternative) Simplified man pages.|
|**Utilities**|`meld`|A visual diff and merge tool. Helps you compare files, directories, and version controlled projects.|
|**Games**|`endless-sky`|A 2D space trading and combat game.|
|**BitTorrent**|`qbittorrent`|A cross-platform, free and open-source BitTorrent client. Lightweight and feature-rich without ads.|
|**Utilities**|`gparted`|GNOME Partition Editor. A graphical tool for creating, reorganizing, and deleting disk partitions.|
|**Utilities**|`filezilla`|A fast and reliable cross-platform FTP, FTPS and SFTP client with a graphical user interface.|
