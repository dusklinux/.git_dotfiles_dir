>[!tip] **SSH vs. Manual Typing**
> Only use the "Recommended" one-liners if you are **copy-pasting** via SSH. 
>
> If you are typing by hand, use the manual method instead. The automated commands are too complex and prone to typos when typed manually.
### **Optional** : Verify the boot mode

```bash
cat /sys/firmware/efi/fw_platform_size
```

> [!NOTE]- What the Output Means.
> - If the command returns `64`, the system is booted in UEFI mode and has a 64-bit x64 UEFI.
> - If the command returns `32`, the system is booted in UEFI mode and has a 32-bit IA32 UEFI. While this is supported, it will limit the boot loader choice to those that support mixed mode booting.
> - If it returns `No such file or directory`, the system may be booted in BIOS or CSM mode

### 1. *WiFi Connection*
```bash
iwctl
```

```bash
device list
```

- *Replace wlan0 with your device name from above eg: wlan1* or what ever your deivce is called

```bash
station wlan0 scan
```

```bash
station wlan0 get-networks
```

```bash
station wlan0 connect "Near"
```

```bash
exit
```

```bash
ping -c 2 x.com
```

- [ ] Status

---

### 2. *SSH*

```bash
passwd
```

```bash
ip a
```

*client side (to connect to target machine)*

```bash
ssh root@192.168.xx
```

*only if you want to reset the key (troubleshooting)*

```bash
ssh-keygen -R 192.168.xx
```

- [ ] Status

---

### 3. *Setting a bigger Font*

```bash
setfont latarcyrheb-sun32
```

- [ ] Status

---

### 4. *Optional* : *Limiting Battery Charge to 60%* (check if you have BAT1 or somehting else first, or it wont work)

```bash
echo 60 | sudo tee /sys/class/power_supply/BAT1/charge_control_end_threshold
```

- [ ] Status

---

### 5. *Pacman Update and Packages Corruption Detection*

```bash
pacman-key --init
```

```bash
pacman-key --populate archlinux
```

```bash
pacman -Sy archlinux-keyring
```

```bash
pacman -Syy
```

give arch iso more space for the update

```bash
mount -o remount,size=4G /run/archiso/cowspace
```

After entering this next command, type "y" for all prompts. 
```bash
pacman -Scc
```

- [ ] Status

---

### 6. *System Timezone*

```bash
timedatectl set-timezone Asia/Kolkata
```

```bash
timedatectl set-ntp true
```

- [ ] Status

---

### 7. *Partitioning Target Drive*

*Identifying the Target Drive*

```bash
lsblk
```

*Partitioning Target Drive*

```bash
cfdisk /dev/sdX
```

- [ ] Status

---

### 8. *Formatting Root and ESP/Boot partitions*

*Identifying Target Drive's Partitions*

```bash
lsblk /dev/sdX
```

*Formatting BOOT/ESP Partition*

```bash
mkfs.fat -F 32 -n "EFI" /dev/esp_partition
```

*Formatting ROOT Partition*

```bash
mkfs.btrfs -f -L "ROOT" /dev/root_partition
```

- [ ] Status

---

### 9. *Mounting Root Partition*

```bash
mount /dev/root_partition /mnt
```

- [ ] Status

---

### 10. **ROOT Partition** *Sub-Volume Creation*

```bash
btrfs subvolume create /mnt/{@,@home}
```

```bash
ls /mnt
```

*Un-Mounting Root Partition and it's newly created Sub-volumes*

```bash
umount -R /mnt
```

- [ ] Status

---

### 11. *Mounting Root Partition's*  **ROOT Sub-Volume** 

```bash
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@ /dev/root_partition /mnt
```

- [ ] Status

---

### 12. *Creating Directories to mount Home Sub-Vol & Boot/ESP Partition*

```bash
mkdir /mnt/{home,boot}
```

```bash
ls /mnt
```

- [ ] Status

---

### 13. Again mounting the *Root Partition* but this time it's **HOME Sub-Volume** 

```bash
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@home /dev/root_partition /mnt/home
```

- [ ] Status

---

### 14. *Mounting the BOOT/ESP Partition*

```bash
mount /dev/esp_partition /mnt/boot
```

- [ ] Status

---

### 15. *Syncing Mirrors for faster Download Speeds*

```bash
reflector --protocol https --country India --latest 6 --sort rate --save /etc/pacman.d/mirrorlist
```

### Critical to resync the packages after new mirrors
```bash
pacman -Syy
```

These are old Indian mirrors, Only paste this into the file if the above command *failed*.

```bash
vim /etc/pacman.d/mirrorlist
```

[[Indian Pacman Mirrors]]

- [ ] Status

---

### 16. *Installing Linux*

>[!Note]- Microcode: `intel-ucode` or `amd-ucode`, Pick for your CPU: AMD/Intel
>Neglecting this can lead to stability issues or unpatched processor vulnerabilities. The microcode is loaded early in the boot process to patch the CPU's internal instruction set behavior.

> [!tip]- Install linux-firmware specific to your hardware instead of the monolith. 
> The biggest culprit for the "useless" packages (like `linux-firmware-radeon`, `linux-firmware-nvidia`, `linux-firmware-mediatek`) is the generic/monolith linux-firmware. Arch Linux recently split the massive `linux-firmware` package into smaller chunks.
> - **The Catch:** When you install the generic package named `linux-firmware`, it **depends on** all those smaller chunks by default to ensure the system creates a bootable image for _any_ hardware.
> - **The Fix:** Since you are on an Intel-Nvidia only laptop, you can explicitly replace `linux-firmware` with just `linux-firmware-intel` and `intel-firmware-nvidia`

```bash
pacstrap -K /mnt base base-devel linux linux-headers linux-firmware intel-ucode neovim dosfstools btrfs-progs
```

- [ ] Status

---

### 17. *Fstab File Generation*

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

```bash
cat /mnt/etc/fstab
```

- [ ] Status

---

### 18. *Chrooting*

```bash
arch-chroot /mnt
```

- [ ] Status

---

### 19. *Setting System Time*

```bash
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
```

```bash
hwclock --systohc
```

- [ ] Status

---

### 20. *Setting System Language*
**removes the hash before the mentioned line** (recommanded)
```bash
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
```
**OR** do it manually
```bash
nvim /etc/locale.gen
```

> [!note] **Un-Comment This **
> en_US.UTF-8 UTF-8

- [ ] Status

---

### 21. *Part of Setting System Language*

```bash
locale-gen
```

```bash
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

- [ ] Status

---

### 22. *Setting Hostname* **(replace placeholder text with your desired hostname)**

```bash
echo "your-hostname" > /etc/hostname
```

- [ ] Status

---

### 23. *Setting Root Password*

```bash
passwd
```

- [ ] Status

---

### 24. *Creating User Account* **(replace with your username)**

```bash
useradd -m -G wheel,input,audio,video,storage,optical,network,lp,power,games,rfkill your_username
```

*Setting User Password* **(replace with your username)**

```bash
passwd your_username
```

- [ ] Status

---

### 25. *Allowing Wheel Group to have root rights.* 

**Create a drop in file** (recommanded)
```bash
echo '%wheel ALL=(ALL:ALL) ALL' | EDITOR='tee' visudo -f /etc/sudoers.d/10_wheel
```

**OR** do it manually, and edit the main file instead
```bash
EDITOR=nvim visudo
```

> [!note] **Un-Comment This **
>%wheel ALL=(ALL:ALL) ALL

- [ ] Status

---

### 26. *Configuring Initiramfs config*
insert the required text into the file (recommanded)
```bash
sed -i -e 's/^MODULES=.*/MODULES=(btrfs)/' -e 's|^BINARIES=.*|BINARIES=(/usr/bin/btrfs)|' -e 's/^HOOKS=.*/HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)/' /etc/mkinitcpio.conf
```
**OR** do it manually. 
```bash
nvim /etc/mkinitcpio.conf
```

> [!note] Fill the empty brackets with 
> MODULES=(btrfs)
> BINARIES=(/usr/bin/btrfs)
> HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)


- [ ] Status

---

### 27. *Installing Apps* **[[Package Installation]]**

- [ ] Status

---

### 28. *Generating Initramfs*

```bash
mkinitcpio -P
```

- [ ] Status

---

### 29. Boot Loader

**Recommended for uefi (faster boot times)**
[[Boot Loader systemd boot]]

**or** 

**Recommanded for Legacy Bios (slower boot times by 2-3 seconds) **
[[Boot Loader Grub]]

- [ ] Status

---

### 30. *Zram as Block device and Swap device (ZSTD compression)*

do it all with once command (recommanded)

```bash
mkdir -p /mnt/zram1 && printf "[zram0]\nzram-size = ram - 2000\ncompression-algorithm = zstd\n\n[zram1]\nzram-size = ram - 2000\nfs-type = ext2\nmount-point = /mnt/zram1\ncompression-algorithm = zstd\noptions = rw,nosuid,nodev,discard,X-mount.mode=1777\n" > /etc/systemd/zram-generator.conf
```

**OR** do it manually. 
```bash
mkdir /mnt/zram1
```

```bash
sudo nvim /etc/systemd/zram-generator.conf
```

```ini
[zram0]
zram-size = ram - 2000
compression-algorithm = zstd

[zram1]
zram-size = ram - 2000
fs-type = ext2
mount-point = /mnt/zram1
compression-algorithm = zstd
options = rw,nosuid,nodev,discard,X-mount.mode=1777
```

- [ ] Status

---

### 31. *System Services*

```bash
systemctl enable NetworkManager.service tlp.service udisks2.service thermald.service bluetooth.service firewalld.service fstrim.timer systemd-timesyncd.service acpid.service vsftpd.service reflector.timer swayosd-libinput-backend systemd-resolved.service
```

*Tlp-rdw services*

```bash
sudo systemctl mask systemd-rfkill.service && sudo systemctl mask systemd-rfkill.socket
```

- [ ] Status

---

### 32. *Concluding*

```bash
exit
```

```bash
umount -R /mnt
```

```bash
poweroff
```

- [ ] Status

---