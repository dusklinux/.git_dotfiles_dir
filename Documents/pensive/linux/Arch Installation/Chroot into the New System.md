
With the base packages installed, it's time to switch from the live installation environment into your new system on the hard drive. The `chroot` (change root) command makes this possible, allowing you to work directly from within the new system to configure it before the first boot.

#### 1. Enter the Chroot Environment

Use the `arch-chroot` script, which handles the `chroot` process and also mounts necessary API filesystems like `/proc`, `/sys`, and `/dev`.

```bash
arch-chroot /mnt
```

> [!NOTE] You're In!
> Once the command completes, your shell prompt will change. You are now operating directly inside your newly installed Arch Linux system. Any command you run from this point forward will configure the system on your disk, not the live USB environment.

