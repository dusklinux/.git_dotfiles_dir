
# Managing and Monitoring RAM on Arch Linux

This guide provides essential commands for monitoring memory (RAM) and disk usage on an Arch Linux system. Understanding how to use these tools is a fundamental skill for system administration and troubleshooting performance issues.

---

## Checking Memory Usage with `free`

The `free` command provides a quick overview of the total, used, and free physical and swap memory.

To see a summary of your system's memory usage in a human-readable format (e.g., MB, GB), use the `-h` flag.

```bash
free -h
```

> [!TIP] Understanding the Output
> The output of `free -h` will look something like this:
> ```
>                total        used        free      shared  buff/cache   available
> Mem:            31Gi       4.5Gi        19Gi       512Mi       7.5Gi        26Gi
> Swap:           32Gi       0.0Ki        32Gi
> ```
> - **total**: Total installed memory.
> - **used**: Memory currently in use by applications.
> - **free**: Unused memory.
> - **buff/cache**: Memory used by the kernel for buffers and cache. This memory can be freed up for applications if needed.
> - **available**: An estimate of how much memory is available for starting new applications, without swapping. This is often a more useful metric than `free`.

---

## Checking Disk Space with `df`

While not directly related to RAM, monitoring disk space is equally crucial for system health. The `df` (disk free) command reports file system disk space usage.

To view disk space in a human-readable format, use the `-h` flag.

```bash
df -h
```

> [!NOTE] RAM vs. Disk Space
> It's important to distinguish between RAM (`free`) and disk storage (`df`).
> - **RAM** is volatile, high-speed memory used by active processes. Data is lost on reboot.
> - **Disk Space** is non-volatile, slower storage for your operating system, applications, and files. Data persists after a reboot.

---

## Detailed Process Information with `inxi`

`inxi` is a powerful command-line tool that provides comprehensive system hardware information. It can be used to identify which processes are consuming the most memory.

> [!ATTENTION] Installation Required
> `inxi` is not installed by default on Arch Linux. You must install it first using `pacman`:
> ```bash
> sudo pacman -S --needed inxi
> ```

To list the top processes sorted by memory usage, use the following command. You can change `10` to any number to see more or fewer processes.

```bash
sudo inxi -t m10
```

**Command Breakdown:**
- `sudo`: Runs the command with administrative privileges to ensure it can access all process information.
- `-t`: Specifies the "top" processes output.
- `m`: Instructs `inxi` to sort the processes by **m**emory usage.
- `10`: Limits the output to the top 10 processes.

---

## Advanced RAM Configuration

For more advanced memory management techniques, you can configure a portion of your RAM to act as storage.

- **Ramdisk (`tmpfs`)**: A volatile, high-speed storage volume in RAM, ideal for temporary files like browser caches. See [[OPTIONAL Configuring Ramdisk]] for setup instructions.
- **ZRAM**: Creates a compressed block device in RAM, which can be used for swap space or as a general-purpose storage device. It offers better memory efficiency than a standard ramdisk due to compression. For setup and monitoring, refer to:
    - [[ZRAM Setup]]
    - [[zramctl]]

