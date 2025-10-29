
# Diagnostics on Arch Linux

This guide covers essential command-line tools for diagnosing performance and hardware health on an Arch Linux system. Each tool is explained with its purpose, usage, and how to interpret its output, providing a solid foundation for system administration and troubleshooting.

---

## Command Execution Timing: `time`

The `time` command is a shell builtin that measures the resources consumed by another command. It is invaluable for identifying performance bottlenecks by breaking down the execution time into three key components.

### Usage

To use it, simply prefix any command you want to measure with `time`.

```bash
time <your_command>
```
**Example:**
```bash
time ls -R /
```

### Interpreting the Output

The output of `time` provides a detailed breakdown of where the command spent its time.

> [!TIP] How to Read `time` Output
> *   **`real`**: This is the total wall-clock time from the moment you hit Enter until the command finishes. It includes time spent waiting for I/O (like disk or network) and time the CPU was busy with other processes.
> *   **`user`**: This is the amount of CPU time spent executing the command's own code in "user mode." A high `user` time indicates the program is CPU-intensive and performing a lot of calculations.
> *   **`sys`**: This is the amount of CPU time spent inside the kernel on behalf of your command. A high `sys` time means the program is making frequent system calls (e.g., reading/writing files, network operations).

**Key Insights:**
*   If `real` is much larger than `user` + `sys`, your command spent most of its time waiting, not working. This points to I/O bottlenecks.
*   If `user` is high, the program itself is computationally heavy. See [[Performance Tuning]] for optimization strategies.
*   If `sys` is high, the program is heavily interacting with the operating system's kernel.

---

## Hardware Health Monitoring: `sensors`

The `sensors` command reads data from hardware monitoring chips on your motherboard and [[CPU]]. It provides real-time values for temperatures, voltages, and fan speeds, which is critical for preventing overheating and diagnosing hardware issues.

### Installation

The `sensors` command is part of the `lm_sensors` package. If it's not already installed, you can add it with:

```bash
sudo pacman -S --needed lm_sensors
```

### First-Time Setup

Before you can use `sensors`, you must run a detection script to identify the specific sensor chips in your system.

> [!WARNING] One-Time Configuration
> This command probes your hardware to find modules to load. You only need to run this **once** per system. Accept the default answers (by pressing Enter) if you are unsure.
> ```bash
> sudo sensors-detect
> ```

After the script finishes, you may need to reboot or run `sudo systemctl restart systemd-modules-load.service` for the new kernel modules to be loaded.

### Usage

Once configured, using `sensors` is straightforward.

**1. Get a Snapshot Reading**
Run the command by itself to get the current sensor values.

```bash
sensors
```

**2. Continuous Monitoring**
To monitor values in real-time, use the `watch` command. It will re-run `sensors` every two seconds (by default) and update the display.

> [!NOTE]
> The `watch` command is part of the `procps-ng` package, which is included in the base Arch Linux installation.

```bash
# Refresh sensor data every 2 seconds
watch sensors

# Refresh every 1 second
watch -n 1 sensors
```
This is extremely useful for observing how temperatures change under load. You can run a tool like `stress-ng` (see [[Performance Tuning]]) in another terminal to see the immediate impact.

