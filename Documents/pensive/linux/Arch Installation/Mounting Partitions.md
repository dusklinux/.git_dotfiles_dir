With the Btrfs subvolumes created and the top-level volume unmounted, the next step is to mount the subvolumes and the EFI System Partition (ESP) to their correct locations. This prepares the directory structure for the Arch Linux installation.

### 1. Mount the Root Subvolume (`@`)

First, mount the `@` subvolume to `/mnt`. This directory will become the root (`/`) of your new system. We use specific mount options optimized for performance and data integrity on an SSD with Btrfs.

> [!WARNING]
> Replace `/dev/root_partition` with your actual Btrfs partition (e.g., `/dev/nvme0n1p2` or `/dev/sda2`).

```bash
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@ /dev/root_partition /mnt
```

> [!TIP]
> **Mount Options Explained:**
> - `rw`: Mount the filesystem as read-write.
> - `noatime`: Disables writing file access times to reduce disk I/O.
> - `compress=zstd:3`: Enables transparent compression with the zstd algorithm (level 3) to save space.
> - `ssd`: Enables SSD-specific optimizations.
> - `discard=async`: Enables asynchronous TRIM operations for better SSD performance and longevity.
> - `space_cache=v2`: Uses the improved free space cache, which is the robust default on modern kernels.
> - `subvol=@`: Specifies the exact subvolume to mount.

### 2. Create Mount Points for Home and Boot

Before mounting the remaining partitions, you must create the directories within `/mnt` that will serve as their mount points.

```bash
mkdir /mnt/home
mkdir /mnt/boot
```

You can verify their creation by listing the contents of `/mnt`:

```bash
ls /mnt
```

### 3. Mount the Home Subvolume (`@home`)

Next, mount the `@home` subvolume to the `/mnt/home` directory you just created. This uses the same performance-oriented mount options as the root subvolume.

> [!NOTE]
> Use the same Btrfs partition device as you did for the root subvolume.

```bash
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@home /dev/root_partition /mnt/home
```

### 4. Mount the EFI System Partition (ESP)

Finally, mount your boot partition (ESP) to `/mnt/boot`.

> [!IMPORTANT]
> This step must be done **after** mounting the root filesystem to `/mnt`. The bootloader paritition requires the boot directory to be created inside the mounted root partition .
>
> Be sure to replace `/dev/esp_partition` with your actual EFI partition (e.g., `/dev/nvme0n1p1` or `/dev/sda1`).

```bash
mount /dev/esp_partition /mnt/boot
```

