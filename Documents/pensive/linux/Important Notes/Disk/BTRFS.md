# BTRFS Filesystem Management

This guide covers essential management tasks for a BTRFS filesystem, focusing on performance tuning by disabling Copy-on-Write (CoW) for specific use cases and providing detailed `fstab` configuration examples.

---

## Disabling Copy-on-Write (CoW)

BTRFS uses Copy-on-Write by default, which is excellent for data integrity and snapshots. However, for certain workloads like virtual machine disk images or database files, CoW can introduce performance overhead. Disabling it can significantly improve performance for these specific applications.

You can disable CoW on a per-directory basis by setting the `+C` attribute.

> [!WARNING] Important Considerations
> *   **New Files Only**: Setting the `+C` attribute on a directory only affects **newly created files**. Existing files within the directory will retain their original CoW status.
> *   **Feature Loss**: Disabling CoW (`No_COW`) on files also disables other BTRFS features for those specific files, such as data checksumming, compression, and the ability to include them in snapshots.

### How to Disable CoW

To disable CoW for all new files in a directory, use the `chattr` command.

**Syntax:**
```bash
sudo chattr +C /path/to/your/directory
```

**Example: Optimizing a Directory for Virtual Machines**

Let's say you store your VM disk images in `/mnt/browser/vms`. Disabling CoW for this directory is highly recommended to improve I/O performance.

1.  **Create the directory if it doesn't exist:**
    ```bash
    sudo mkdir -p /mnt/browser/vms
    ```

2.  **Apply the `No_COW` attribute:**
    ```bash
    sudo chattr +C /mnt/browser/vms
    ```

From this point forward, any new file created or copied into `/mnt/browser/vms` will be created with CoW disabled, benefiting from improved performance.

---

## `fstab` Configuration Examples

The `/etc/fstab` file is critical for defining how disk partitions and storage devices are mounted at boot time. Below are optimized examples for both BTRFS and NTFS drives.

### BTRFS Drive Configuration

This example demonstrates mounting a BTRFS drive with options optimized for an SSD, including disabling CoW at the filesystem level.

> [!CAUTION] Disabling CoW Mount-Wide
> The `nodatacow` option disables Copy-on-Write for the **entire filesystem**. This also disables compression (`compress=...` will have no effect). Use this only if you are certain you want to prioritize performance over data integrity features for the whole volume. For most users, the `chattr +C` method above is the preferred approach.

**`/etc/fstab` Entry:**
```fstab
# The unlocked Browser BTRFS drive
UUID=67a3dcc0-6186-4000-a96a-47f29ab0293e  /mnt/browser  btrfs  rw,noatime,ssd,discard=async,space_cache=v2,nofail,nodatacow,x-systemd.automount,comment=x-gvfs-show  0 0
```

**Mount Options Explained:**

| Option | Description |
| :--- | :--- |
| `rw` | Mounts the filesystem in read-write mode. |
| `noatime` | Disables updating file access times, reducing disk writes and improving performance. |
| `ssd` | Enables SSD-specific optimizations within the BTRFS driver. |
| `discard=async` | Enables asynchronous TRIM operations, which helps maintain SSD performance over time without blocking I/O. |
| `space_cache=v2` | Uses the more robust and performant V2 space cache for tracking free space. |
| `nofail` | Prevents the system from halting the boot process if the drive is not present. |
| `nodatacow` | Disables Copy-on-Write for all new data on the filesystem. **This also disables compression.** |
| `x-systemd.automount` | Instructs systemd to automount the drive on first access. |
| `comment=x-gvfs-show` | A hint for desktop environments (like GNOME) to display this mount in the file manager. |

### NTFS Drive Configuration

This example shows how to mount an NTFS drive for a standard user, ensuring correct permissions and automounting behavior.

**`/etc/fstab` Entry:**
```fstab
# The unlocked media NTFS drive
UUID=9C38076638073F30  /mnt/media  ntfs  uid=1000,gid=1000,umask=0022,noatime,nofail,x-systemd.automount,comment=x-gvfs-show 0 0
```

**Mount Options Explained:**

| Option | Description |
| :--- | :--- |
| `uid=1000` | Sets the user ID of the owner for all files on the filesystem. `1000` is typically the first standard user. |
| `gid=1000` | Sets the group ID of the owner for all files. `1000` is the corresponding group for the user. |
| `umask=0022` | Sets the file permissions. `0022` gives the owner read/write/execute permissions, while group and others get read/execute. |
| `noatime` | Disables updating file access times to reduce I/O. |
| `nofail` | Prevents boot failure if the drive is not connected. |
| `x-systemd.automount` | Tells systemd to mount the drive when it's first accessed. |
| `comment=x-gvfs-show` | Makes the drive visible in the file manager's sidebar. |

