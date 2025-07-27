
This step configures the `mkinitcpio.conf` file, which is used to generate the initial RAM disk (initramfs). The initramfs is a small, temporary root filesystem that loads essential drivers into memory, enabling the kernel to access the main root filesystem, especially when using features like Btrfs or disk encryption.

### 1. Edit the Configuration File

Open the `mkinitcpio` configuration file in a text editor:

```bash
nvim /etc/mkinitcpio.conf
```

### 2. Modify Configuration Arrays

You will need to add specific values to the `MODULES`, `BINARIES`, and `HOOKS` arrays within the file.

#### MODULES

Add `btrfs` to the `MODULES` array. This ensures the Btrfs kernel module is included in the initramfs, which is essential for booting from a Btrfs filesystem.

```
MODULES=(btrfs)
```

#### BINARIES

Add the path to the Btrfs user-space utility to the `BINARIES` array. This allows the initramfs environment to execute Btrfs commands if necessary during early boot.

```
BINARIES=(/usr/bin/btrfs)
```

#### HOOKS

The `HOOKS` array defines the sequence of actions taken during the boot process. If you are using a LUKS-encrypted root partition, you must add the `encrypt` hook.

> [!WARNING] Hook Order is Critical
> The order of hooks is sequential and extremely important. The `encrypt` hook **must** be placed before the `filesystems` hook. This ensures the system unlocks the encrypted volume *before* it attempts to mount the filesystem on it.

A standard `HOOKS` line for a system with an encrypted Btrfs root partition is shown below:

```
HOOKS=(base udev autodetect microcode modconf keyboard keymap consolefont block encrypt filesystems fsck)
```

> [!TIP]
> After saving your changes to `/etc/mkinitcpio.conf`, the next step is to [[Generating the Initramfs|generate the initramfs image]].


## Reference file
[[Initramfs file Reference]]