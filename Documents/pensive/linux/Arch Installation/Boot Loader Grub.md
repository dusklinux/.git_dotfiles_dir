### 1. *Grub Packages*

```bash
pacman -S --needed grub efibootmgr grub-btrfs os-prober
```

- [ ] Status

---

### 2. *Configuring Grub Config*

>[!danger] Caution! **remove** 'pcie_aspm=force' if your laptop crashes or has issues with power saving. 

make the changes with just this one command (recommanded)
```bash
sed -i -e 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 zswap.enabled=0 rootfstype=btrfs pcie_aspm=force fsck.mode=skip"/' -e 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
```

**OR** do it manually

```bash
nvim /etc/default/grub
```

```bash
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 zswap.enabled=0 rootfstype=btrfs pcie_aspm=force fsck.mode=skip"
```

> [!note] **Un-comment this **
> GRUB_DISABLE_OS_PROBER=false

- [ ] Status

---

### 3. *Installing Grub to the BOOT/ESP Partition. *

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
```

- [ ] Status

---

### 4. *Generating Grub File for Boot*

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

- [ ] Status
