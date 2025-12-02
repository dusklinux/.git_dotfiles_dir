1. Install packages. 
```bash
pacman -S --needed efibootmgr
```

2. Boot kernal parameters. 
```ini

```

4. To automatically updates the bootloader binary in the ESP if the systemd package is updated.
```bash
systemctl enable systemd-boot-update.service
```