
This step creates the file system table (`fstab`), which instructs the operating system on how to mount your partitions automatically at boot time.

### Generate fstab

Use the `genfstab` script to scan your currently mounted partitions and generate the configuration. We use the `-U` flag to identify partitions by their UUIDs, which is more reliable than device names (e.g., `/dev/nvme0n1p1`) that can sometimes change.

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

> [!TIP] What does this command do?
> - **`genfstab -U`**: Generates `fstab` entries using **U**UIDs for disk identification.
> - **`/mnt`**: Scans the directory where your new system's partitions are mounted.
> - **`>> /mnt/etc/fstab`**: Appends the generated output to the `fstab` file inside your new system.

### Verify the Generated File

It is **highly recommended** to check the generated `fstab` file for any errors before proceeding. An incorrect `fstab` can prevent your system from booting correctly.

You can display the contents of the new file with this command:

```bash
cat /mnt/etc/fstab
```

> [!NOTE] What to Check
> - Ensure all your partitions (root, boot, home, etc.) are listed.
> - Check that the mount points and filesystem types are correct.
> - You can compare the output with the example in [[fstab reference]].
>
> A more thorough verification will be performed in a later step, [[Optimizing fstab Entries]], after we `chroot` into the new environment.

