
### GRUB Installation Overview

This process installs and configures the GRUB bootloader, which is responsible for loading Arch Linux when you start your computer.
> [!attention] ALL FOUR STEPS SHOULD BE FOLLOWED FOR A SUCESSFUL GRUB INSTALLATION. 

1.  **[[Installing Grub Packages]]**
    This initial step uses the `pacman` package manager to install the essential software: `grub` (the bootloader), `efibootmgr` (to manage UEFI boot entries), and optionally `os-prober` if you need to dual-boot with another operating system like Windows.

2.  **[[Grub file Configuration]]**
    This step involves editing the `/etc/default/grub` file to customize the bootloader's behavior. Here, you can define kernel parameters to manage power-saving features, adjust system logging levels, and enable `os-prober` to detect other installed operating systems.

3.  **[[Installing Grub to EFI partition]]**
    In this step, you run the `grub-install` command. This copies the necessary GRUB files to your EFI System Partition (ESP) and creates a boot entry in your computer's firmware, making the system officially bootable.

4.  **[[Generating the Final Grub File]]**
    The final step is to run `grub-mkconfig`. This command reads your settings from `/etc/default/grub`, detects your Linux kernel, finds other operating systems, and generates the main `grub.cfg` file that GRUB uses at startup to display the boot menu.

