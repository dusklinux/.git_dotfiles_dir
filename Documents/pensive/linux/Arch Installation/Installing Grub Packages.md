 Part 1: GRUB Package Installation

This is the first step, where you install the necessary software packages for the GRUB bootloader using `pacman`.

### 1. Install Core and Optional Packages

Install the essential packages for a UEFI system. The command below includes `grub` itself, `efibootmgr` to interact with the UEFI firmware, and `grub-btrfs` which is highly recommended if you are using a Btrfs filesystem.

```bash
pacman -S --needed grub efibootmgr grub-btrfs
```

> [!TIP] Why `grub-btrfs`?
> If your root filesystem is Btrfs, the `grub-btrfs` package automatically creates GRUB menu entries for your Btrfs snapshots. This allows you to easily boot into a previous snapshot directly from the boot menu, which is invaluable for system recovery.

### 2. Install OS Prober (for Dual-Booting)

If you are setting up a dual-boot system (e.g., with Windows), you must also install `os-prober`. This package allows GRUB to detect other operating systems on your machine.

```bash
pacman -S --needed os-prober
```

> [!NOTE]
> If you are only installing Arch Linux, you can skip this step.

***