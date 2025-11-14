 Part 2: GRUB Configuration (`/etc/default/grub`)

Before installing the bootloader to the disk, you must configure its default behavior by editing the `/etc/default/grub` file. This file controls kernel parameters, appearance, and other boot-time options.

### 1. Open the Configuration File

Use a text editor like `nvim` to open the GRUB default configuration file.

```bash
nvim /etc/default/grub
```

### 2. Configure Kernel Parameters

Locate the `GRUB_CMDLINE_LINUX_DEFAULT` line. This line sets the kernel parameters that are applied during a normal boot. The default is often `"loglevel=3 quiet"`. It's recommended to change this for better boot-time visibility and to add other system-specific tweaks.

A well-configured line might look like this:

```ini
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=7 zswap.enabled=0"
```

Here is a breakdown of common and useful parameters:

| Parameter                | Description                                                                                                                                                                                  |
| :----------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `loglevel=7`             | Increases the verbosity of kernel messages during boot. This is extremely helpful for troubleshooting, as it replaces the default `quiet` parameter which hides these messages.              |
| `zswap.enabled=0`        | Explicitly disables `zswap`. This is critical if you plan to use `zram` for swap, as having both enabled can lead to conflicts and performance issues.                                       |
| `usbcore.autosuspend=-1` | Disables autosuspend for all USB devices. This can resolve boot-time hangs or errors related to peripherals like Bluetooth or NVIDIA GPUs, where aggressive power-saving can cause problems. |
| `pcie_aspm=force`        | Forcibly enables Active State Power Management for PCIe devices to save power.                                                                                                               |
| `mitigations=off`        | Disables CPU mitigation for Spectre/Meltdown vulnerabilities. This can significantly boost performance on older CPUs but comes with security risks.                                          |
| `mem=8G`                 | Limits the total RAM visible to the system, if you have 16G of ram, this will only use 8G of it.                                                                                             |
| `rootfstype=btrfs`       | ensures the kernel loads the correct filesystem driver early, improving boot reliability and speed on Btrfs systems.                                                                         |
> [!WARNING] Use `pcie_aspm=force` with Caution
> Forcibly enabling ASPM on hardware that does not properly support it can cause system instability or hangs. Before using this parameter, verify that your hardware is compatible.

> [!WARNING] Security vs. Performance
> The `mitigations=off` parameter should only be used if you understand the security implications and are prioritizing raw performance on a trusted machine. For most users, it is safer to leave the default mitigations enabled.

### 3. Enable OS Prober (for Dual-Booting)

If you installed `os-prober` in the previous section, you must enable it in the GRUB configuration. Find the line `#GRUB_DISABLE_OS_PROBER=false` and uncomment it by removing the `#`.

If the line does not exist or is set to `true`, add or change it to:

```ini
GRUB_DISABLE_OS_PROBER=false
```


### 4. (This is auto enabled by default usually) Enable preloading modules. 

# What those modules do

- **`part_gpt`** — support for **GPT** partition tables.
    
- **`part_msdos`** — support for legacy **MBR (msdos)** partition tables.
    

Loading either module enables GRUB to parse that partition table type so it can locate and read the `/boot` (or EFI) partition and the GRUB configuration and kernel files.

# Why people include both

- **Portability:** a single GRUB install that works whether the disk has GPT or MBR (handy for live images, installers, multi-disk machines).
    
- **Resilience:** if GRUB’s auto-probing fails, explicitly preloading avoids surprises where GRUB can’t find the kernel because it couldn’t read the partition table.
  
### info
- uefi is usally laptops after 2012 and their fore GPT
- legacy bios are MBR/msdos
- some laptops are mixed. 


for GPT
```ini
GRUB_PRELOAD_MODULES="part_gpt"
```

for MBR
```ini
GRUB_PRELOAD_MODULES="part_msdos"
```

or both  for compatibility across different types
```ini
GRUB_PRELOAD_MODULES="part_gpt part_msdos"
```

***