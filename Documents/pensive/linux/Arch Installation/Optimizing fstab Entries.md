
After generating the `/etc/fstab` file, this crucial step involves verifying its entries and adding specific mount options to optimize filesystem performance, especially for Btrfs on an SSD. A correctly configured `fstab` is essential for the system to boot properly.

> [!WARNING] Critical System File
> Incorrectly editing `/etc/fstab` can prevent your system from booting. Double-check all changes before saving the file.

#### 1. Open the `fstab` File

First, open the file in a text editor.

```sh
nvim /etc/fstab
```

#### 2. Verify and Modify Mount Options

Your goal is to inspect the lines for your Btrfs partitions (typically root `/` and home `/home`) and verify their mount options.

1.  **Verify UUIDs**: Confirm that `genfstab` correctly assigned the `UUID`s for your root (`/`) and EFI System Partition (`/boot`).
2.  **Optimize Btrfs Options**: Modify the options string for each Btrfs subvolume to enhance performance and enable compression.

> [!NOTE] Apply to All Btrfs Subvolumes (SSD)
> If you created separate subvolumes for root (`@`) and home (`@home`), you must apply these changes to the mount options for **both** entries in your `fstab` file.

The key changes are:
*   **Add** performance-enhancing options.
*   **Remove** `discard=async` to use periodic TRIM instead of continuous TRIM.

The table below explains the recommended options.

| Option | Description | Action |
| :--- | :--- | :--- |
| `noatime` | Disables writing file access times to disk with every read, reducing I/O. | **Add/Ensure Present** |
| `compress=zstd` | Enables transparent, real-time compression with the efficient Zstandard algorithm. | **Add/Ensure Present** |
| `ssd` | Enables SSD-specific optimizations within the Btrfs driver. | **Add/Ensure Present** |
| `space_cache=v2` | Uses the more robust and modern V2 space cache for | **Add/Ensure Present** |

