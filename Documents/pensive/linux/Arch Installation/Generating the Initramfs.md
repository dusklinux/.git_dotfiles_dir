
After configuring the `mkinitcpio.conf` file in the previous step ([[Configuring the Initial RAM File System]]), the next crucial step is to generate the initial RAM disk (initramfs). This is a compressed environment that the kernel loads into memory during boot, containing the necessary modules (like `btrfs`) to mount your root filesystem.

You can generate the initramfs using one of two methods.

### Method 1: Generate for All Kernels (Recommended)

This command automatically detects all installed kernel presets (e.g., `linux`, `linux-lts`) and generates an initramfs for each one. This is the safest and most efficient approach.

> [!TIP] Recommended Approach
> Using the `-P` (uppercase) flag ensures that all kernels on your system have an up-to-date initramfs. This prevents boot issues, especially after a kernel update.

```bash
mkinitcpio -P
```

### Method 2: Generate for Specific Kernels

If you need to generate the initramfs for a single, specific kernel (e.g., for troubleshooting), you can use the `-p` (lowercase) flag followed by the kernel's preset name.

> [!NOTE] Understanding the Flags
> - `-P`: Uses **all** presets found in `/etc/mkinitcpio.d/`.
> - `-p`: Uses a **single, specified** preset.

For the standard `linux` kernel:
```bash
mkinitcpio -p linux
```

For the `linux-lts` kernel:
```bash
mkinitcpio -p linux-lts
```

