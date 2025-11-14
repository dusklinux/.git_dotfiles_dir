# Hardware & Resource Diagnostics on Arch Linux

This guide provides a foundational set of command-line tools for inspecting hardware and diagnosing resource usage on Arch Linux. A clear understanding of these utilities is essential for troubleshooting, system inventory, and day-to-day administration.

---

## 1. Hardware Enumeration

These commands allow you to identify and list the physical components installed in your system. They are often the first step in diagnosing hardware-related issues, such as a device not being recognized.

### `lspci` - List PCI Devices

The `lspci` command is a fundamental utility for listing all Peripheral Component Interconnect (PCI) buses and the devices connected to them. This is your primary tool for quickly checking if hardware like GPUs, network adapters, sound cards, and storage controllers are detected by the kernel.

> [!TIP] Your First Stop for Hardware Checks
> If you've just installed a new graphics card or Wi-Fi adapter and it's not working, `lspci` is the first command to run to see if the system even sees the hardware.

**Usage:**
```bash
lspci
```
This command is also referenced in [[Power Management]] for checking device power states.

### `lshw` - List Hardware (Comprehensive)

The `lshw` (list hardware) utility provides a deeply detailed report on the system's hardware configuration. It extracts information from various sources in `/proc` to give you a complete picture of your machine's internals, including the [[CPU]], memory, motherboard, firmware version, and bus speeds.

> [!NOTE]
> Running `lshw` requires root privileges (`sudo`) to access the most detailed information. Without `sudo`, the output may be incomplete.

**Usage:**
*   **Full Detailed Report:**
    ```bash
    sudo lshw
    ```
*   **Concise Summary:** For a more digestible, high-level overview, the `-short` flag is invaluable. It presents the hardware in a clean, hierarchical list.
    ```bash
    sudo lshw -short
    ```

---

## 2. Resource Usage: `lsof` (List Open Files)

In Linux, nearly everything is treated as a file: regular files, directories, network sockets, pipes, and hardware devices. The `lsof` command is an incredibly powerful diagnostic tool that shows which processes have which files open.

### Core Concept: "Everything is a file"

Understanding `lsof` means understanding its scope. It can tell you:
*   Which application is preventing a USB drive from unmounting.
*   What process is listening on a specific network port.
*   Which files a misbehaving application is currently accessing.

**General Usage:**
Running `lsof` without arguments will list every open file by every process, which can be an overwhelming amount of data. It is almost always used with filters.

```bash
lsof
```

### Common `lsof` Use Cases

Here are practical, targeted examples for system administration.

#### Find Which Process is Using a Specific File or Directory

This is essential for troubleshooting "Resource busy" errors, especially when trying to unmount a filesystem.

> [!WARNING] Unmount Example
> If you run `umount /mnt/data` and get `target is busy`, this command will show you exactly which process is holding a file open inside `/mnt/data`.

```bash
# Replace with the actual path to your file or mount point
sudo lsof /path/to/your/file_or_directory
```

#### See What Process is Using a Network Port

This is critical for network troubleshooting and security audits. It helps you identify which service is bound to a specific port.

```bash
# Example: Find what is using the standard web server port (80)
sudo lsof -i :80

# General syntax
sudo lsof -i :<port_number>
```

#### List Files Opened by a Specific Process

If you know the Process ID (PID) of an application, you can see all the files it currently has open. This is useful for debugging a specific program's behavior.

```bash
# Replace <PID> with the actual Process ID
sudo lsof -p <PID>
```

#### Find Deleted Files Still Held Open

Sometimes, a process will keep a file open even after it has been deleted from the filesystem. The file won't appear in directory listings, but it will continue to occupy disk space until the process holding it is closed. This command is crucial for finding and reclaiming this "invisible" used space.

```bash
sudo lsof | grep '(deleted)'
```

