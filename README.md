# Updated demo Video coming soon.

> If you're here just for wallpapers, You can get them from my 'images' repo.

```bash
https://github.com/dusklinux/images
```

# 🎻 Dusky: The Ultimate Arch Hyprland Experience

> This repository is the result of 8 months of tinkering, breaking, fixing, and polishing. It is a labor of love designed to feel as easy to install as a "standard" distribution, but with the raw power and minimalism of Arch Linux.
> 
> Since I build and maintain this alone, **please consider starring ⭐ this repo** as a token of support.

## 🚀 Overview

**Great News!** The installation process is 99% automated.

While these dotfiles are extremely powerful, you don't need to be a wizard to install them. You only need to run a few commands to clone the repo and trigger the "Orchestra" scripts.

### ✨ Key Features

**Performance & System**

- **Ultra Lightweight:** ~900MB RAM usage and ~5GB disk usage (fully configured).
    
- **ZSTD & ZRAM:** Compression enabled by default to save storage and triple your effective RAM (great for low-spec machines).
    
- **Native Optimization:** AUR helpers configured to build with CPU-native flags (up to 20% performance boost).
    
- **Space Efficient:** Vertical Waybar saves vertical screen real estate.
    
- **UWSM Environment:** Optimized specifically for Hyprland.
    

**Graphics & Gaming**

- **Fluid Animations:** Tuned physics and momentum for a "liquid" feel, I've spent days fine tuning this.
    
- **GPU Passthrough Guide:** Zero latency (native performance) for dual-GPU setups using Looking Glass.
    
- **Instant Shaders:** Switch visual shaders instantly via Rofi.
    
- **Android Support:** Automated Waydroid installer script.
    

**Usability & Theming**

- **Universal Theming:** `Matugen` powers a unified Light/Dark mode across the system.
    
- **Dual Workflow:** Designed for both GUI-centric (mouse) and Terminal-centric (keyboard) users.
    
- **Rofi System Menu:** A resource-efficient one-stop-shop for settings.
    
- **Accessibility:** Text-to-Speech (TTS) and Speech-to-Text (STT) capabilities (hardware dependent).
    
- **Keybind Cheatsheet:** Press `CTRL` + `SHIFT` + `SPACE` anytime to see your controls.
    

## ⚠️ Prerequisites & Hardware

### Filesystem

This setup is strictly optimized for **BTRFS**.

- **Why?** ZSTD compression, Copy-on-Write (CoW) to prevent data corruption, and instant Snapshots.
    

### Hardware Config (Intel/Nvidia/AMD)

These scripts default to **Intel (CPU) +  Intel Integrated GPU + Nvidia (GPU)**

> [!Note]
>
> AMD Users: You must configure the uwsm env files to set your gpu environment variables.
>
> 1. Open the files at ~/.config/uwsm/env and ~/.config/uwsm/env-hyprland
>
> 2. Replace Intel/Nvidia-specific variables with amd with their AMD equivalents.
>
>4. I will automate this in the future, i don't currently have an amd system at hand to test it on.



### Dual Booting

- Compatible with Windows or other Linux distros.
    
- **Bootloader:** Defaults to `systemd-boot` for UEFI (boots up to 5s faster). Defaults to `GRUB` for BIOS.



# Installation 💿
## 📦 Method 1: Existing Arch Install (Recommended)

**Best for:** Users who already have Arch + Hyprland installed via `archinstall` or manual installation.

### Step 1: Clone Dotfiles (Bare Repo Method)

We use a bare git repository method to drop files exactly where they belong in your home directory.

```
git clone --bare --depth 1 https://github.com/dusklinux/dusky.git $HOME/dusky
```

```bash
git --git-dir=$HOME/dusky/ --work-tree=$HOME checkout -f
```

### Step 2: Run the Orchestra

Run the master script to install dependencies, themes, and services.

```bash
~/user_scripts/arch_setup_scripts/ORCHESTRA.sh
```

## 🎻 The Orchestra Script

The `ORCHESTRA.sh` is a "conductor" that manages ~70 subscripts.

- **Smart:** It detects installed packages and skips them.

- **Safe:** You can re-run it as many times as you like without breaking things.

- **Time:** Expect 30–60 minutes. We use `paru` to install AUR packages, and compiling from source takes time. Grab a coffee! ☕


## ⌨️ Usage & Keybinds

The steepest learning curve will be the keybinds. I have designed them to be intuitive, but feel free to change them in the config.

> 💡 Pro Tip:
>
> Press CTRL + SHIFT + SPACE to open the Keybinds Cheatsheet. You can click commands in this menu to run them directly!

## Method 2: The "Clean Slate" (only recommended if you have Intel or (Intel + Nvidia) hardware.

Best for: New installs, Dual Booting, ensuring zero bloat.

Requirement: Official Arch Linux ISO.

This method handles everything from disk partitioning with guided user intervention to automated installing of packages and everything else.

### Step 1: Connect to Internet

Boot the Arch ISO. USB tethering usually works out of the box. For WiFi, follow these steps:

<details>

<summary>Click to view WiFi Connection Commands</summary>

1. Run the interactive tool:
    
    ```
    iwctl
    ```
    
2. List your devices (note your device name, e.g., `wlan0`):
    
    ```
    device list
    ```
    
3. Scan for networks:
    
    ```
    station wlan0 scan
    ```
    
4. List available networks:
    
    ```
    station wlan0 get-networks
    ```
    
5. Connect:
    
    ```
    station wlan0 connect "YOUR_SSID"
    ```
    
6. Exit the tool:
    
    ```
    exit
    ```
    

</details>

### Step 2: Download the Script

Run the following commands to initialize keys, install git, and clone the installer:

```bash
pacman-key --init
pacman -Sy git
```

##### Clone the repo (type carefully or it asks a password if you enter the wrong repo)
```bash
git clone --depth 1 https://github.com/dusklinux/dusky.git
```

##### Copy the pre-chroot scripts to the current directory
```bash
cp dusky/user_scripts/arch_iso_scripts/000_pre_chroot/* .
```

### Step 3: Run the ISO Orchestra

This script automates the pre-chroot setup (disk partitioning)
```bash
./001_ISO_ORCHESTRA.sh
```

### Step 4: Run the Chroot Orchestra

Once the previous script finishes, enter your new system and run the final stage:
```bash
arch-chroot /mnt
```

```bash
./001_CHROOT_ORCHESTRA.sh
```

### Step 5: Post-Reboot Setup

1. Reboot your computer.
    
2. Login with your username and password.
    
3. Open the terminal (Default: `Super` + `Q`).
    
4. Run the final deployment scripts:
    

```
# Connect to wifi if needed
./wifi_connect.sh
```

```
# Deploy config files
./deploy_dotfiles.sh
```

> Note:
> 
> This will immediately list a few errors at the top, but dont worry, that's expected behaviour, the errors will later go away on there own after matugen generates colors and cycles through a wallpaper. 

the main setup script.
```bash
~/user_scripts/arch_setup_scripts/ORCHESTRA.sh
```

## 🔧 Troubleshooting

If a script fails (which can happen on a rolling release distro):

1. **Don't Panic.** The scripts are modular. The rest of the system usually installs fine.
    
2. **Check the Output.** Identify which subscript failed (located in `$HOME/user_scripts/setup_scripts/scripts/`).
    
3. **Run Manually.** You can try running that specific subscript individually.
    
4. **AI Help.** Copy the script content and the error message into ChatGPT/Gemini. It can usually pinpoint the exact issue (missing dependency, changed package name, etc.).
    


<div align="center">

Enjoy the experience!

If you run into issues, check the detailed Obsidian notes included in the repo (~2MB).

</div>
