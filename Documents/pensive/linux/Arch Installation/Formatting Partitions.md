
With the disk partitioned, the next step is to create filesystems on the newly created partitions. This process formats each partition to store data correctly.

> [!WARNING] Data Destruction
> The following commands are destructive and will permanently erase all data on the specified partitions. Double-check your partition device names (e.g., `/dev/sda1`, `/dev/nvme0n1p2`) before proceeding. The examples use placeholders like `/dev/esp_partition` and `/dev/root_partition`.

---

### 1. EFI System Partition (ESP)

The EFI System Partition (ESP) is used by the UEFI firmware to boot the operating system. It must be formatted with the **FAT32** filesystem.

Execute the following command, replacing `/dev/esp_partition` with your actual ESP device name (e.g., `/dev/sda1`):

```sh
mkfs.fat -F32 /dev/esp_partition
```

| Flag | Description |
| :--- | :--- |
| `-F32` | Specifies the FAT32 filesystem type. |

---

### 2. Root Partition

The root partition will hold the core operating system files. We will format this with the **Btrfs** filesystem.

Execute the following command, replacing `/dev/root_partition` with your actual root partition device name (e.g., `/dev/sda2`):

```sh
mkfs.btrfs -f /dev/root_partition
```

> [!NOTE] The `-f` (Force) Flag
> The `-f` flag forces the creation of a new Btrfs filesystem, even if one already exists on the partition. It's good practice to include this to ensure a clean format, especially when re-using a drive.

With the filesystems created, the next step is [[Btrfs Subvolume Creation]].
