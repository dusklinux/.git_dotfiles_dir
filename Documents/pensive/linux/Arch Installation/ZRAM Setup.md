
ZRAM significantly improves system responsiveness by creating a compressed swap space directly in your RAM. This is considerably faster than using a traditional swap file or partition on a disk, making it an excellent optimization, especially for systems with ample RAM.

This note provides a high-level overview of the setup process. For detailed instructions, refer to the linked notes for each step.

> [!IMPORTANT]
> ### Prerequisites
> Before you begin, ensure the following prerequisites are met:
> 1. The `zswap` kernel feature is enabled by default in Arch Linux and conflicts with ZRAM. Before setting up ZRAM, ensure `zswap` is disabled in your GRUB configuration by adding `zswap.enabled=0` to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`.
> See step [[Grub file Configuration]] for details.
> ---
> 2.  **Create Mount Point**: If you intend to use a ZRAM device for temporary file storage (as shown in the `zram1` example), create the mount directory beforehand:
>     ```bash
>     mkdir /mnt/zram1
>     ```

---

## Installation and Configuration Workflow

Follow these steps chronologically to correctly configure, optimize, and verify your ZRAM setup.

### 1. Configure the ZRAM Generator

The first step is to create a configuration file at `/etc/systemd/zram-generator.conf`. This file instructs the `zram-generator` service on how to create and manage your ZRAM devices at boot time. Here, you will define crucial parameters like device size, compression algorithm, and mount points.

*   **For detailed instructions, see:** [[zram-generator config]]

### 2. Optimize Kernel Parameters

To ensure the system leverages the fast ZRAM swap effectively, you must tune several kernel virtual memory (VM) parameters. These adjustments encourage the kernel to swap idle application data to ZRAM more aggressively, which enhances performance, particularly under memory pressure.

*   **For detailed instructions, see:** [[Optimizing Kernel Parameters for ZRAM]]

### 3. Verify the Setup (Post-Boot)

After configuring ZRAM and booting into your system, the final step is to verify that it is active and performing as expected. The `zramctl` command-line utility provides a real-time overview of all active ZRAM devices, showing their size, current usage, and compression efficiency.

*   **For verification commands and output examples, see:** [[zramctl]]

> [!NOTE] Related but not recommanded [[OPTIONAL Configuring Ramdisk]]