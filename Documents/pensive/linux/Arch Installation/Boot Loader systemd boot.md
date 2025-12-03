first check if you're running uefi and not bios (if this command lists a bunch of files, it means you've got a uefi based system if not, it's bios)
```bash
ls /sys/firmware/efi/efivars
```

### 1. Install packages. 
```bash
pacman -S --needed efibootmgr
```

### 2. Boot loader config.  (replace $ESP with /boot)
**`$ESP/loader/loader.conf`**: The global bootloader settings (Timeouts, default entry).

```bash
sudo nvim /boot/loader/loader.conf
```

```ini
default  arch.conf
timeout  1
console-mode max
editor   no
```
> [!tip]- what is console-mode max? 
> **`console-mode max`**: _Highly recommended for Hyprland users._ This forces the bootloader to use the maximum available resolution supported by UEFI, preventing resolution switching glitches when the kernel (and subsequently Hyprland) takes over.

### 3. **`$ESP/loader/entries/*.conf`**: The specific kernel entries (Where your parameters go).


first find your root partiton's partuuid with # Replace nvme1np5 with your root partition (e.g., sda4 or whatever it is)  You need the `PARTUUID` of your **root** partition (not the EFI partition). Run this to get it:
```bash
 sudo blkid -s PARTUUID -o value /dev/nvme1n1p5
```

```bash
sudo nvim /boot/loader/entries/arch.conf
```

```ini
title   Arch Linux
linux   /vmlinuz-linux
# Remember microcode! GRUB usually auto-detects this. In sd-boot, you must be explicit.
# Use /amd-ucode.img if you are on AMD.
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=YOUR-ROOT-PARTUUID-HERE rw loglevel=3 zswap.enabled=0 rootfstype=btrfs pcie_aspm=force fsck.mode=skip
```

### 4. To automatically updates the bootloader binary in the ESP if the systemd package is updated.
```bash
systemctl enable systemd-boot-update.service
```


```bash
bootctl install
```