
With the Btrfs partition formatted, the next step is to create subvolumes. This is a key advantage of Btrfs, as it allows you to logically separate parts of your filesystem (like `/` and `/home`) for easier management, snapshotting, and rollbacks.

### 1. Mount the Top-Level Btrfs Volume

First, mount the entire Btrfs partition to `/mnt`. This gives you access to the top level of the volume, where you will create the subvolumes.

> [!WARNING]
> Be sure to replace `/dev/xyz` with the correct device name for your root partition (e.g., `/dev/nvme0n1p2` or `/dev/sda3`).

```bash
mount /dev/xyz /mnt
```

### 2. Create Root and Home Subvolumes

Now, create the subvolumes for your root (`/`) and home (`/home`) directories. The `@` and `@home` naming convention is a widely adopted standard that simplifies snapshot and system recovery configurations.

-   `@` will serve as the root of your Arch Linux installation.
-   `@home` will contain all user home directories.

```bash
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
```

### 3. Verify Creation

To ensure the subvolumes were created correctly, list the contents of `/mnt`.

```bash
ls /mnt
```

The output should confirm the presence of the new subvolume directories:

```
@  @home
```

> [!NOTE]
> At this point, you have created the subvolumes within the top-level Btrfs volume. The next step is to unmount this volume so you can remount the subvolumes to their proper mount points.




