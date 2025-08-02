
# Performance Tuning in Arch Linux

This guide provides a methodical approach to diagnosing and improving the performance of an Arch Linux system. It covers boot time analysis, CPU stress testing, power management, and application-level diagnostics, serving as both a step-by-step manual and a quick reference for system administrators.

---

## 1. Boot Time Analysis with `systemd-analyze`

The first step in performance tuning is often to analyze and reduce boot time. `systemd-analyze` is the primary tool for this, providing detailed insights into the startup process.

| Command | Description |
|---|---|
| `systemd-analyze` | Displays the total time spent in the kernel and userspace during boot. This is your high-level starting point. |
| `systemd-analyze blame` | Lists all running units, sorted by the time they took to initialize. Ideal for quickly identifying the slowest services. |
| `systemd-analyze critical-chain` | Shows a tree of units on the critical path, highlighting the chain of dependencies that most impacted boot time. |
| `systemd-analyze critical-chain <unit>` | Drills down into the critical chain for a specific unit (e.g., `network-online.target`). |

> [!TIP] Visualizing Boot Performance
> For a detailed, interactive visualization of the entire boot process, you can generate an SVG graph.
> ```bash
> systemd-analyze plot > boot_analysis.svg
> ```
> Open the `boot_analysis.svg` file in any modern web browser to explore the boot sequence timeline.

---

## 2. Managing System Services

After identifying slow or unnecessary services with `systemd-analyze`, you can manage them to improve boot time and reduce background resource usage.

#### List Enabled Services
Use these commands to see which services are set to start automatically.

*   **System-wide services:**
    ```bash
    systemctl list-unit-files --state=enabled
    ```
*   **User-specific services:**
    ```bash
    systemctl --user list-unit-files --state=enabled
    ```

#### Disable Unnecessary Services
Once you identify a service you don't need, you can disable it.

```bash
sudo systemctl disable NetworkManager-wait-online.service
```

> [!WARNING] Be Cautious When Disabling Services
> Disabling a critical system service can lead to instability or prevent your system from booting. Research any unfamiliar service before disabling it.

---

## 3. CPU Performance & Stress Testing

These tools help you benchmark your CPU's throughput, identify thermal throttling, and test system stability under load.

### General CPU Stress Testing with `stress-ng`

`stress-ng` is a powerful utility for stress-testing system components. It reports performance in real-time using "bogo ops/s" (bogus operations per second), a fluctuating metric that provides an excellent relative measure of computational throughput.

*   **Benchmark all CPU cores:**
    The `--cpu 0` flag targets all available CPU cores, and `--metrics-brief` provides a clean, summary output.
    ```bash
    stress-ng --cpu 0 --metrics-brief
    ```

### Visualizing CPU Utilization with `s-tui`

For a simple, terminal-based user interface (TUI) to monitor CPU frequency, utilization, and temperature in real-time, `s-tui` is an excellent choice.

*   **Launch the monitor:**
    ```bash
    s-tui
    ```

### Single-Core Benchmarking with `taskset`

To measure the performance of a *specific* CPU core, you can use `taskset` to pin the `stress-ng` process to it.

*   **Syntax:** `taskset -c <CPU_CORE_NUMBER> <COMMAND>`
*   **Example:** To benchmark only CPU core #4 (cores are numbered from 0):
    ```bash
    taskset -c 4 stress-ng --cpu 1 --metrics-brief
    ```

> [!CAUTION] Critical `stress-ng` Flag for Single-Core Tests
> When pinning `stress-ng` to a single core with `taskset`, you **must** use `--cpu 1`. This tells `stress-ng` to use only one worker thread.
>
> Using `--cpu 0` (all cores) would create multiple worker threads that compete for time on the single pinned core, producing meaningless benchmark results.

---

## 4. Power Consumption Monitoring

Understanding power draw is crucial for thermal management and performance tuning, especially on laptops. `turbostat` provides detailed CPU power metrics.

> [!NOTE] Installation
> `turbostat` is part of the `linux-tools` package. You may need to install it first:
> ```bash
> sudo pacman -S --needed linux-tools
> ```

*   **Monitor CPU Package Power:**
    This command shows the real-time power consumption in Watts for the entire CPU package (`PkgWatt`), refreshing every second (`-i 1`).
    ```bash
    sudo turbostat -i 1 --show PkgWatt
    ```

---

## 5. Process Resource Management

### Limiting CPU Usage with `limitcpu`

`limitcpu` allows you to restrict the CPU usage of a specific process by its Process ID (PID).

> [!NOTE] Installation from AUR
> `limitcpu` is available in the Arch User Repository (AUR). You can install it using an AUR helper like `yay` or `paru`.
> ```bash
> yay -S limitcpu
> ```

*   **Usage:** The `-l` flag sets the percentage limit. This value is scaled by the number of CPU cores (e.g., on an 8-core system, the range is 0-800).
*   **Example:** Limit the process with PID `5081` to 50% of one CPU core's capacity.
    ```bash
    limitcpu -l 50 -p 5081
    ```

---

## 6. Application-Level Diagnostics with `strace`

When a specific application is slow or misbehaving, `strace` can help diagnose the issue by logging every system call the program makes. This is invaluable for debugging file access issues, permission errors, or performance bottlenecks within an application.

*   **Trace a running application:**
    This command attaches to a running process by its PID (`-p`), follows any child processes it creates (`-f`), and writes the log to a file (`-o`).
    ```bash
    sudo strace -o trace.log -f -p <PID>
    ```
*   **Trace an application from launch:**
    This runs a new command and logs all its system calls to `trace.out`.
    ```bash
    strace -o trace.out <your_application_command>
    ```
    *Example:* `strace -o trace.out myapp` runs `myapp` and logs calls like `open("file.txt", O_RDONLY) = 3`.

---

## 7. Further Reading & Related Topics

Optimizing system performance is a broad topic. The following notes provide essential, related information:

*   **[[Install Kernel and Base Packages]]:** Consider installing an alternative kernel like `linux-zen` for enhanced desktop responsiveness.
*   **[[Disk Swap]]:** A foundational guide to understanding and managing disk-based swap.
*   **[[Tuning Swap Performance (Advanced)]]:** Learn to fine-tune kernel swappiness and set swap priorities, which directly impacts how your system performs under memory pressure.

