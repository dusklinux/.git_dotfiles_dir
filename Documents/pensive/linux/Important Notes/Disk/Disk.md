
# Disk Management and Diagnostics in Arch Linux

This guide serves as a comprehensive reference for managing, diagnosing, and optimizing storage devices in Arch Linux. It covers everything from basic identification and benchmarking to advanced NVMe power management and health monitoring.

---

## 1. Identifying Disks and Controllers

Before you can manage a disk, you must correctly identify it. The following commands are essential for discovering storage devices and their properties.

| Command     | Description                                                                                                                                                 |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lsblk`     | Lists all block devices (disks, partitions) in a tree-like format. This is the primary tool for identifying device names like `/dev/sda` or `/dev/nvme0n1`. |
| `nvme list` | Specifically lists all NVMe SSDs connected to the system, providing a clean overview.                                                                       |
| `lspci`     | Lists all PCI devices. Useful for identifying the disk controller hardware.                                                                                 |
| `mount`     | List all the flags that each block device / disk is mounted with, ie flags for each file system                                                             |
| `sudo fdisk -l`     | shows a lot of info about block devices                                                                                                             |

> [!TIP] Finding Your NVMe Controller
> To find the specific controller for your NVMe drives, you can filter the output of `lspci`.
> ```bash
> lspci | grep -i "Non-Volatile memory controller"
> ```

---

## 2. Performance Benchmarking

Measuring disk performance is crucial for diagnostics and optimization. These tools help you test read/write speeds and monitor I/O activity.

### Read Speed (Non-Destructive)

The `hdparm` utility provides a quick and safe way to benchmark the sequential read speed of a drive.

> [!WARNING] Use `hdparm` with caution. The `-t` flag is safe as it only performs read tests. Other flags can be dangerous and may lead to data loss if used incorrectly.

```bash
# Replace /dev/sdX with your target SATA/IDE drive
sudo hdparm -t /dev/sdX
```

### Read & Write Speed (Destructive Test)

The `dd` command is a powerful tool for low-level data copying, often used for benchmarking.

> [!DANGER] Data Destruction
> The `dd` write test will overwrite data at the specified output file (`of=...`). **Never** point the output to a device (`/dev/sdX`) unless you intend to wipe it completely. Always perform write tests on a file within a mounted filesystem.

**Write Speed Test**
This command writes a 1GB file of zeros to the specified path. The `conv=fdatasync` flag ensures the write operation is flushed to the disk for accurate measurement.

```bash
# This example writes to a ZRAM disk, see [[ZRAM Setup]]
# Replace the path to test a different disk
dd if=/dev/zero of=/mnt/zram1/testfile bs=1M count=1024 conv=fdatasync
```

**Read Speed Test**
This command reads the previously created test file and discards the output, measuring pure read throughput.

```bash
dd if=/mnt/zram1/testfile of=/dev/null bs=1M
```

### Continuous I/O Monitoring

To watch disk activity in real-time, use `iostat`. This is invaluable for diagnosing performance bottlenecks.

```bash
# Monitor I/O on nvme0n1, updating every 1 second
# Install with: sudo pacman -S --needed sysstat
iostat -d 1 /dev/nvme0n1
```

---

## 3. Health and Monitoring (S.M.A.R.T.)

S.M.A.R.T. (Self-Monitoring, Analysis, and Reporting Technology) is a monitoring system included in drives that can help predict failures.

> [!NOTE] Installation
> The `smartctl` tool is part of the `smartmontools` package.
> ```bash
> sudo pacman -S --needed smartmontools
> ```

To get a detailed health report for a drive, use the following command:

```bash
# Get all S.M.A.R.T. attributes for /dev/sda
sudo smartctl -a /dev/sda
```

For NVMe drives, you can check the specific health log:

```bash
# Check the S.M.A.R.T. health log for an NVMe drive
sudo nvme smart-log /dev/nvmeX -H
```

---

## 4. NVMe Drive Management

NVMe drives have a dedicated set of tools for advanced management, primarily through the `nvme-cli` package.

> [!NOTE] Installation
> Ensure you have the `nvme-cli` package installed.
> ```bash
> sudo pacman -S --needed nvme-cli
> ```

### Identifying NVMe Drive Details

To get detailed information about an NVMe controller and its capabilities:

```bash
# Replace /dev/nvmeX with your target drive
sudo nvme id-ctrl /dev/nvmeX
```

### NVMe Power Management

You can inspect and manage your NVMe drive's power states, which is especially useful for laptops.

1.  **Check Current Power State:**
    State `0` is the highest performance state. Higher numbers indicate deeper, more power-efficient sleep states.
    ```bash
    # Get feature 0x02 (Power Management)
    sudo nvme get-feature -f 0x02 -H /dev/nvmeX
    ```

2.  **Check for APSTA Support:**
    Autonomous Power State Transition (APSTA) allows the drive to change power states automatically without driver intervention.
    ```bash
    sudo nvme id-ctrl /dev/nvmeX | grep -i apsta
    ```

3.  **Check for ASPM Support:**
    Active State Power Management (ASPM) is a PCI Express power-saving feature. First, get the PCIe bus ID of your NVMe controller, then check its status.
    ```bash
    # Step 1: Get the bus ID (e.g., 10000:e1:00.0)
    lspci | grep -i "Non-Volatile memory controller"
    
    # Step 2: Check ASPM status using the bus ID
    sudo lspci -vvv -s <bus_id> | grep -iE "ASPM Support:|ASPM Control:|LnkCtl:|LnkSta:"
    ```

4.  **View All Power-Saving Features:**
    The following commands provide a comprehensive overview of the drive's power-saving capabilities.
    ```bash
    # General feature overview
    sudo nvme get-feature -H /dev/nvmeX
    
    # Specifically check Autonomous Power State Transition (APST) config
    sudo nvme get-feature -f 0x0c -H /dev/nvmeX
    ```

---

## 5. Common Disk Operations

### Unlocking Encrypted Drives

To unlock a LUKS-encrypted volume from the command line, use `udisksctl`.

> [!NOTE]
> This command only unlocks the device; it does not mount it. After unlocking, you can mount it manually or it may appear in your file manager (like Thunar) to be mounted with a click.

```bash
# Find your block device with lsblk first
udisksctl unlock --block-device /dev/nvme1n1p1
```

### Mounting Drives

If a drive has a corresponding entry in your `/etc/fstab` file, you can mount it with a simplified command by specifying only the mount point.

```bash
# Example for a partition defined in fstab to be mounted at /mnt/media
sudo mount /mnt/media
```

---

## 6. Advanced Topics & Tools

### HDD Partition Layout for Performance

For traditional spinning hard drives (HDDs), physical data placement matters.
*   **Faster Sectors:** Sectors at the beginning of the drive (outer edge of the platter) are faster.
*   **Reduced Head Movement:** Smaller partitions lead to faster seek times.

> [!TIP] Optimal HDD Layout
> For best performance, create a small partition (e.g., 20-30GB) for your root (`/`) system near the beginning of the drive. Place larger, less frequently accessed data (like `/home`) on a separate partition after it. For more details, see [[Disk Partitioning]].

### Visualizing Disk Usage

To get a graphical, interactive map of what's taking up space on your disk, use `baobab` (Disk Usage Analyzer).

```bash
sudo pacman -S --needed baobab
```

### Software RAID

For massive I/O improvements and data redundancy, consider combining multiple disks into a **Software RAID** array. This is an advanced topic that can significantly boost performance. 

---

## Appendix: File Decompression Utilities

A quick reference for decompressing common archive formats in the terminal.

| Command | File Extension(s) | Description |
|---|---|---|
| `zstd -d` | `.zst` | Decompresses Zstandard files. |
| `gunzip` | `.gz` | Decompresses Gzip files. |
| `bunzip2` | `.bz2` | Decompresses Bzip2 files. |
| `unxz` | `.xz` | Decompresses XZ files. |
| `unzip` | `.zip` | Extracts files from a ZIP archive. |
| `unrar x` | `.rar` | Extracts files from a RAR archive. |
| `7z x` | `.7z` | Extracts files from a 7-Zip archive. |

