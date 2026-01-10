# ARCH Clean Install + Hyprland

A complete step-by-step guide for installing **Arch Linux** from scratch and setting up **Hyprland** 

NOTE BACKUP YOUR DATA BEFORE THIS AS WE ARE GOING TO WIPE YOUR DRIVE

---

## Prerequisites

- Arch Linux ISO  
- Bootable USB drive  
- Internet connection  
- Basic Linux command-line knowledge  

---

## Booting the Arch ISO

Once the flashing process is complete, restart your PC or laptop and enter the boot menu (ESC, F8, F9, F10, F12).  
Select the Arch Linux USB drive to boot into the live environment.

---

## Network Setup (Wi-Fi)

If your computer has built-in Wi-Fi support, you can connect using the iwctl tool.

Start the iwd shell:
iwctl

List available network interfaces:
device list

If wlan0 is powered off, enable it:
device wlan0 set-property Powered on

Scan and list available Wi-Fi networks:
station wlan0 scan  
station wlan0 get-networks

Connect to your Wi-Fi network:
station wlan0 connect WIFI_NAME

Enter your Wi-Fi password. If no message appears, wait 2–5 seconds.

Exit iwctl:
exit

Verify internet connection:
ping -c 3 google.com

If you receive replies, the internet connection is working.

---

## Disk Partitioning

Update package databases:
pacman -Sy

List connected drives:
lsblk

Identify your target disk (example: /dev/nvme0n1).

CAUTION: All data on the selected drive will be permanently erased.

Start partitioning:
gdisk /dev/nvme0n1

Verify partitions:
lsblk

---

## Base System Installation

Launch the installer:
archinstall

If archinstall is missing:
pacman -Sy archinstall

Navigation:
- Arrow keys to move  
- Enter to select  
- Space to toggle options  

---

## MOST IMPORTANT STEP — Disk Configuration

Inside archinstall:

Disk Configuration  
- Partitioning  
- Use best-effort default partition layout  
- Select target disk (e.g. /dev/nvme0n1)  
- Filesystem: btrfs  
- Confirm wipe: Yes  
- Enable compression  

Return to the main menu.

---

## Installer Configuration Summary

Enable swap  
Bootloader: GRUB  
Hostname: arch  

Authentication  
- Set root password  
- Create a new user  
- Add user to sudo  
- Confirm and exit  

Profile  
- Desktop  
- Hyprland  

Graphics Drivers  
- Select according to your hardware  

Additional Options  
- Greeter: SDDM  
- Audio: PipeWire  
- Bluetooth: Enable  
- Network: Copy from ISO  
- Optional packages: firefox  
- Timezone: use / to search  

Start installation and wait for completion.

---

## System Configuration

Configure timezone, locale, hostname, and essential services.

---

## Bootloader Setup

Configure GRUB or systemd-boot for EFI systems.

---

## User Setup

Set user permissions, sudo access, and shell preferences.

---

## Graphics Drivers

Install and verify Intel, AMD, or NVIDIA drivers.

---

And then install and let the magic happen 

After that reboot 
Remove Pendrive 
and done you are ready

For dusklinux installation
press super+q
Open firefox then go to the  repo and then follow the steps there In the method one
