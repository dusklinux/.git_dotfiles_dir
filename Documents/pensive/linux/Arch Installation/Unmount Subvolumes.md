
After creating the `@` and `@home` subvolumes, you must unmount the top-level Btrfs volume from `/mnt`. This is a critical step that prepares the system for the next phase: mounting the subvolumes themselves to their proper mount points.

### 1. Unmount the Volume

Use the `umount` command with the `-R` (recursive) flag. This ensures that the `/mnt` directory and any filesystems mounted underneath it are unmounted cleanly.

```bash
umount -R /mnt
```

> [!TIP]
> The `-R` or `--recursive` option is highly recommended. It prevents potential "target is busy" errors by unmounting a directory and all nested mount points in a single, reliable operation.

### 2. Verify (Optional)

You can verify that nothing is mounted at `/mnt` by running the `findmnt` command.

```bash
findmnt
```

If the unmount was successful, this command should produce no output.

---

**Next Step:** The next logical step is to remount the `@` and `@home` subvolumes with the correct mount options to `/mnt` and `/mnt/home`, respectively home will require a directory to be created and so will the boot partitition before you can mount them at those paths.
