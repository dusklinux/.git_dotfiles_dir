# Mastering CPU Management on Arch Linux

This guide provides a comprehensive set of commands and procedures for installing, monitoring, and analyzing CPU performance on Arch Linux. It is structured to serve as both a step-by-step manual for setup and a quick reference for experienced users.

> [!NOTE] Foundational Knowledge
> A solid understanding of your CPU's behavior is critical for system administration. This note covers hardware-specific tools, general performance analysis, and deep-dive diagnostics. For related topics, see [[Power Management]] and [[CPU Vulnerabilities]].

---

## 1. Intel-Specific Tools & Configuration

For systems with Intel CPUs, installing specific tools for GPU monitoring and hardware-accelerated media decoding is essential for optimal performance and efficiency.

### Installation

First, install the necessary packages using `pacman`.

*   **GPU Monitoring & Media Drivers:** These packages provide tools to monitor the integrated GPU and enable hardware acceleration for video encoding/decoding, which offloads work from the CPU, improving performance and reducing power consumption.

```bash
sudo pacman -S --needed intel-gpu-tools libva-utils libva-intel-driver intel-media-driver
```

| Package | Purpose |
| :--- | :--- |
| `intel-gpu-tools` | A collection of tools for debugging the Intel graphics driver stack. |
| `libva-utils` | Provides the `vainfo` utility to verify VA-API support. |
| `libva-intel-driver` | The legacy VA-API driver for Intel hardware (Broadwell and older). |
| `intel-media-driver` | The modern VA-API driver for Intel hardware (Broadwell and newer). |

### Usage & Verification

After installation, you can use these utilities to verify and monitor your hardware.

*   **Check Hardware Codecs:** Use `vainfo` to list all supported hardware-accelerated encoders and decoders. This confirms that your drivers are correctly installed and recognized.
    ```bash
    vainfo
    ```

*   **Monitor CPU States:** `turbostat` provides detailed information on CPU topology, frequency, idle states (C-states), and temperature. It is excellent for checking if Turbo Boost is functioning correctly.
    ```bash
    sudo turbostat
    ```

---

## 2. General CPU Information

These tools are universal and provide essential information about the CPU architecture on any Arch Linux system.

### `lscpu`

The `lscpu` command provides a quick and comprehensive summary of the CPU architecture. It gathers information from `sysfs` and `/proc/cpuinfo`.

> [!TIP] Your Go-To for Quick CPU Specs
> `lscpu` is the fastest way to check core count, threads, architecture (e.g., x86_64), cache sizes, and NUMA node information without needing special permissions.

```bash
lscpu
```

---

## 3. Advanced Performance Analysis with `perf`

`perf` is a powerful and versatile performance analysis tool built into the Linux kernel. It allows you to diagnose complex performance issues at a very low level.

> [!NOTE] How `perf` Works
> Think of your CPU as having built-in, highly precise sensors called **Performance Monitoring Units (PMUs)**. `perf` is the interface to read these sensors. It can either take frequent snapshots (sampling) of what your system is doing or count specific hardware events (like cache misses or branch mispredictions). This provides unparalleled insight into how a program interacts with the hardware.

### `perf list`

Before you start, see what events `perf` can track on your system.

*   **List Available Events:** This command shows all hardware and software events you can monitor.
    ```bash
    perf list
    ```

### `perf stat`

Use `perf stat` to get a high-level statistical overview of a command's performance. It's perfect for a quick analysis of why a specific command might be slow.

*   **Get Performance Statistics for a Command:**
    ```bash
    perf stat <your_command>
    ```
    For example, to analyze `ls -R /`:
    ```bash
    perf stat ls -R /
    ```

### `perf top`

`perf top` provides a real-time, function-level view of CPU usage, similar to the standard `top` command but far more granular. It shows which functions are currently the "hottest" (consuming the most CPU cycles).

*   **System-Wide Real-Time Monitoring:**
    ```bash
    sudo perf top
    ```

*   **Monitor a Specific Process:**
    ```bash
    sudo perf top -p <PID>
    ```

*   **Filter Display:**
    *   Hide kernel symbols to focus on user-space applications:
        ```bash
        sudo perf top -K
        ```
    *   Hide user-space symbols to focus on kernel activity:
        ```bash
        sudo perf top -U
        ```

### `perf record` & `perf report`

For deep-dive analysis, `perf` uses a two-step process: record performance data, then analyze it with an interactive report.

*   **Step 1: Record Performance Data:** The `-g` flag captures call-graph information, which is crucial for understanding the context of function calls.
    ```bash
    perf record -g <your_command>
    ```
    This creates a `perf.data` file in your current directory.

*   **Step 2: Analyze the Data:** Run `perf report` to open an interactive viewer for the `perf.data` file. You can navigate the call stacks to pinpoint the exact sources of performance bottlenecks.
    ```bash
    perf report
    ```

### `perf trace`

Similar to `strace`, `perf trace` uses the `perf` infrastructure to trace system calls, providing a more efficient and powerful alternative.

> [!WARNING] Requires Root Privileges
> Tracing system calls for arbitrary processes requires elevated permissions. Always use `sudo`.

*   **Trace System Calls for a Specific Process:**
    ```bash
    sudo perf trace -p <PID>
    ```
