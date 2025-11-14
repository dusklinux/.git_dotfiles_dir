
This master note outlines the complete, step-by-step process for a manual Arch Linux installation. The guide is divided into three main phases: pre-installation setup, core system installation, and post-installation configuration.

---

## Phase 1: Pre-Installation Setup

These optional steps are performed within the live installation environment to improve usability and prepare the system before beginning the core installation.

> [!NOTE] Optional Preparatory Steps
> - - [ ] [[Increase Console Font Size]]: Improve readability on high-resolution displays.
> - - [ ] [[Set Keyboard Layout]]: Configure the correct keyboard map for your language.
> - - [ ] [[Verify Boot Mode]]: Ensure the system has booted in UEFI mode.
> - - [ ] [[SSH]]: Set up remote access for a more comfortable installation experience.
> - - [ ] [[Limiting Battery Charge]]: (ASUS Laptops) Temporarily limit the charge threshold to preserve battery health.
> - - [ ] [[Initialize Pacman Keyring]]: Set up package manager keys to verify official packages.

---

## Phase 2: Core Installation

Follow these steps sequentially to partition the disk, install the base system, and configure it.

### A. Environment and Networking
1. - [ ] [[Create a Bootable USB Drive]]
2. - [ ] [[Disable secureboot]] 
3. - [ ] [[IWD]]
4. - [ ] [[Synchronize the System Clock]]

### B. Disk Preparation
5. - [ ] [[Disk Partitioning]]
6. - [ ] [[Formatting Partitions]]
7. - [ ] [[Btrfs Subvolume Creation]]
    - [[Unmount Subvolumes]]
8. - [ ] [[Mounting Partitions]]

### C. Base System Installation
9. - [ ] [[Synchronize Pacman Mirrors]]
10. - [ ] [[Install Kernel and Base Packages]]
11. - [ ] [[Generate the fstab File]]
12. - [ ] [[Chroot into the New System]]

### D. System Configuration (Inside Chroot)
13. - [ ] *Optional* [[Optimizing fstab Entries]]
14. - [ ] [[Setting Time Zone]]
15. - [ ] [[Configure System Locale]]
16. - [ ] [[Setting Hostname]]
    - - [ ] *Optional:* [[Configure the Hosts File]]
17. - [ ] [[Setting Root Password]]
18. - [ ] [[User Account Creation]]
    - - [ ] *Optional:* [[User Group Assignments]]
19. - [ ] [[Configuring Sudo Privileges]]
20. - [ ] *Optional* [[Reflector Setup (mirror)]]
21. - [ ] [[Package Installation]]
22. - [ ] [[Configuring the Initial RAM File System]]
23. - [ ] [[Generating the Initramfs]]
24. - [ ] [[GRUB]]
25. - [ ] [[ZRAM Setup]]
26. - [ ] *Optional* [[Disk Swap]]
27. - [ ] [[Enabling System Services]]

### E. Finalization
28. - [ ] *Optional* [[Optional steps arch install]]
29. - [ ] [[Exiting and Unmounting]]

---

## Phase 3: Post-Installation

Once you have rebooted into your new Arch Linux system, perform these final steps to install an AUR helper and additional software.

1. [[Installing an AUR Helper]]
2. [[AUR Packages]]
    - [[AUR Package services]]

---

## Reference Material
- [[Key Configuration Files in Arch Linux]]
