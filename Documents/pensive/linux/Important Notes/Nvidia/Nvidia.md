# The Ultimate Arch Linux NVIDIA Guide: From Installation to Advanced Power Management

Welcome to your comprehensive manual for installing, configuring, and mastering the NVIDIA ecosystem on Arch Linux. This document is designed for system administrators and power users who require a deep, foundational understanding of every component, from the initial driver installation to the nuances of power management and Wayland integration. Every step is explained in detail to build robust knowledge and serve as a reliable reference for managing large-scale deployments.

---

## Part 1: The Foundation - Core Driver Installation

This section covers the essential, non-negotiable steps for installing the proprietary NVIDIA driver on a fresh Arch Linux system. Getting this foundation right prevents a cascade of issues later on.

> [!WARNING] **Clean Slate Required**
> Before you begin, it is imperative to ensure that any previous or conflicting graphics drivers (including prior versions of the NVIDIA proprietary driver or open-source drivers like `xf86-video-nouveau`) are completely uninstalled from the system. Conflicts during this initial phase are the most common source of problems.

### Step 1.1: Installing Kernel Headers

**Purpose:** The NVIDIA driver is a kernel module, meaning it's a piece of code that loads directly into the Linux kernel to communicate with the hardware. **DKMS (Dynamic Kernel Module Support)** is a system that automatically recompiles kernel modules when the kernel itself is updated. To do this, DKMS needs the source code "blueprints" for your specific kernel version, which are provided by the kernel headers packages.

**Action:** Install the headers for every kernel you have installed and intend to use.

```bash
# Install headers for the standard 'linux' and 'linux-lts' kernels
sudo pacman -S --needed linux-headers linux-lts-headers
```

> [!TIP] **Kernel Specificity**
> If you only use the standard `linux` kernel, you only need `linux-headers`. If you use a custom kernel (e.g., `linux-zen`), you must install its corresponding headers (`linux-zen-headers`). Failure to match headers to the kernel will cause the DKMS build to fail, and the NVIDIA driver will not load.

### Step 1.2: Installing the NVIDIA Driver Packages via DKMS

**Purpose:** While you can install a pre-compiled driver package (`nvidia`), the `nvidia-dkms` package is the professional standard for Arch Linux. It ensures that your graphics driver remains compatible with your kernel across updates, saving you from a black screen after a system upgrade.

**Action:** Install the core NVIDIA packages.

```bash
# Install the DKMS driver, essential utilities, and the graphical settings panel
sudo pacman -S --needed nvidia-dkms nvidia-utils nvidia-settings
```

**Package Breakdown:**

Your original note correctly identified the key packages and their dependencies. Let's break them down in detail:

*   **`nvidia-dkms`**: This is the heart of the installation. It contains the source code for the NVIDIA kernel module. When you install or update your kernel, the DKMS service automatically triggers a build process, compiling a new module that perfectly matches the new kernel.
*   **`nvidia-utils`**: This package is indispensable. It provides the essential userspace libraries and command-line tools required for the driver to function. The most famous of these is **`nvidia-smi`** (NVIDIA System Management Interface), your primary tool for monitoring and managing the GPU. It also contains libraries needed for CUDA and other NVIDIA technologies.
*   **`nvidia-settings`**: This is a graphical utility that allows you to configure display settings, anti-aliasing, power profiles (MPO), and more. While some of its functionality can be limited under Wayland compositors, it remains a valuable tool for diagnostics and configuration.
*   **Dependencies (e.g., `libxnvctrl`, `egl-gbm`, `egl-x11`)**: These are pulled in automatically. They provide critical interfaces for display management (`libxnvctrl`), EGL (a Khronos API that provides a platform-agnostic interface between rendering APIs like OpenGL ES and the native platform windowing system), and GBM (Generic Buffer Management), which is crucial for modern graphics stacks, especially in Wayland.

### Step 1.3: Blacklisting the `nouveau` Driver

**Purpose:** `nouveau` is the open-source, reverse-engineered driver for NVIDIA graphics cards. It is part of the Linux kernel. The proprietary `nvidia` driver and the `nouveau` driver cannot coexist; they will conflict over control of the hardware. You must explicitly prevent the `nouveau` module from loading at boot.

**Action:** The `nvidia-dkms` package is designed to handle this for you by installing a file in `/usr/lib/modprobe.d/`. You must verify this and, if necessary, create a manual override.

1.  **Verify Automatic Blacklisting:**
    ```bash
    grep nouveau /usr/lib/modprobe.d/nvidia*.conf
    ```
    **Expected Output:** A line containing `blacklist nouveau`. If you see this, the process was successful.

2.  **Manual Blacklisting (The Failsafe):**
    If the verification command returns no output, or if you want to be absolutely certain, create your own blacklist file. Files in `/etc/modprobe.d/` take precedence over those in `/usr/lib/modprobe.d/`.
    ```bash
    sudo nano /etc/modprobe.d/blacklist-nouveau.conf
    ```
    Add the following single line to this new file:
    ```conf
    blacklist nouveau
    ```

### Step 1.4: Enabling NVIDIA Kernel Mode Setting (KMS)

**Purpose:** **KMS (Kernel Mode Setting)** is a fundamental technology in the modern Linux graphics stack. It moves the responsibility for setting the display resolution, refresh rate, and memory from userspace drivers into the kernel itself.
*   **For you, this means:** A flicker-free boot experience, the ability to see high-resolution text in virtual consoles (TTYs), and—most importantly—it is an **absolute requirement for Wayland compositors** like Hyprland and GNOME to function correctly with the NVIDIA driver.

**Action:** Add the `nvidia_drm.modeset=1` parameter to your bootloader's kernel command line.

*   **For GRUB Bootloader:**
    1.  Edit the GRUB default configuration file:
        ```bash
        sudo nano /etc/default/grub
        ```
    2.  Locate the `GRUB_CMDLINE_LINUX_DEFAULT` line and add the parameter inside the quotes.
        ```diff
        - GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
        + GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nvidia_drm.modeset=1"
        ```
    3.  After saving the file, you must regenerate the main GRUB configuration file for the changes to be applied.
        ```bash
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        ```

*   **For systemd-boot Bootloader:**
    1.  Edit the relevant entry file in `/boot/loader/entries/`. The file is often named after your Arch installation (e.g., `arch.conf`).
    2.  Append the parameter to the end of the `options` line.
        ```diff
        - options root=PARTUUID=... rw
        + options root=PARTUUID=... rw nvidia_drm.modeset=1
        ```
    The change is applied automatically on the next boot; no regeneration command is needed for `systemd-boot`.

### Step 1.5: Rebuilding the Initial Ramdisk (Initramfs)

**Purpose:** The initramfs is a temporary, miniature root filesystem that is loaded into memory during the boot process. Its job is to mount the real root filesystem and initialize necessary hardware. When you install a new kernel module (like `nvidia`) or change module loading rules (like blacklisting `nouveau`), you must update the initramfs so it knows about these changes at the earliest stage of booting.

**Action:** Regenerate the initramfs for all installed kernels.

```bash
# The -P preset flag automatically rebuilds the initramfs for all kernel presets found
sudo mkinitcpio -P
```

### Step 1.6: The Final Reboot

**Purpose:** All the changes you have made—installing the new driver, blacklisting the old one, setting kernel parameters, and rebuilding the initramfs—only take effect after a full system reboot.

**Action:** Reboot your system.

```bash
sudo reboot
```

> [!SUCCESS] **Verification After Reboot**
> After rebooting, you can run `lsmod | grep -i nvidia`. If you see a list of `nvidia` modules (`nvidia_drm`, `nvidia_modeset`, `nvidia`), your installation was successful. If you see `nouveau`, the blacklisting failed. If you see neither, the driver failed to load.

---

## Part 2: Managing Hybrid Graphics (NVIDIA Optimus)

Most modern laptops feature NVIDIA Optimus technology, a hybrid graphics system with a power-saving integrated GPU (iGPU, usually Intel or AMD) and a powerful dedicated NVIDIA GPU (dGPU). This section details the tools to manage which GPU is active.

### 2.1: `envycontrol` - The Recommended Tool

**Purpose:** `envycontrol` is a modern, straightforward command-line utility for switching between graphics modes on Optimus laptops.

**Action:** Install from the Arch User Repository (AUR) and use its simple commands.

1.  **Installation (using an AUR helper like `yay`):**
    ```bash
    yay -S envycontrol
    ```

2.  **Command Reference:**
    | Command | Description | When to Use |
    | :--- | :--- | :--- |
    | `sudo envycontrol -q` | **Query:** Checks the currently active graphics mode. | Your first step for diagnostics. |
    | `sudo envycontrol -s integrated` | **Integrated Mode:** Powers off the NVIDIA dGPU completely. | For maximum battery life, travel, light tasks. |
    | `sudo envycontrol -s hybrid` | **Hybrid Mode:** The iGPU renders the desktop, but the dGPU can be used on-demand for specific applications (PRIME Render Offload). | The best of both worlds. Good battery life with performance available. **This is the standard mode for most users.** |
    | `sudo envycontrol -s nvidia` | **NVIDIA Mode:** The dGPU handles all rendering. | For maximum performance when plugged in, or if external monitors are connected directly to the NVIDIA GPU. Drains battery quickly. |

> [!NOTE]
> A full reboot is required for any changes made with `envycontrol` to take effect.

### 2.2: `acpi_call` - The Advanced Fallback

**Purpose:** `acpi_call` is a low-level kernel module that allows you to make direct ACPI calls to system hardware. It can be used to manually script the power-down of the dGPU.

> [!DANGER] **Use as a Last Resort**
> This method is highly complex, varies significantly between laptop models, and can cause system instability if the wrong call is used. It is a fallback for older or unsupported hardware where tools like `envycontrol` fail. It requires the `acpi_call-dkms` package and extensive research on your specific laptop model.

---

## Part 3: Mastering Power Management for Laptops

This is arguably the most critical section for laptop users. Proper configuration here means the difference between 1 hour and 8+ hours of battery life. The goal is to achieve **RTD3 (Runtime D3 Power Management)**, where the NVIDIA GPU is completely powered off when idle.

### 3.1: System-Wide Power Features (`nvidia-powerd`)

**Purpose:** The `nvidia-powerd` service enables **Dynamic Boost**, a feature on modern laptops that intelligently shifts the power budget between the CPU and GPU based on workload. If a game is GPU-bound, more power is allocated to the GPU; if a compilation task is CPU-bound, the CPU gets the extra power.

**Action:** Enable and start the service.

```bash
sudo systemctl enable --now nvidia-powerd.service
```

### 3.2: Deep Kernel Control (`modprobe.d`)

**Purpose:** This is where you set the fundamental, persistent behavior of the driver at the kernel level. These options are read when the `nvidia` module is loaded at boot.

**Action:** Create a configuration file to enable the most aggressive power-saving mode.

1.  **Create the configuration file:** The name is arbitrary, but it must end in `.conf`.
    ```bash
    sudo nvim /etc/modprobe.d/nvidia-power.conf
    ```

2.  **Add the recommended content:**
    ```conf
    # This enables Fine-Grained Runtime D3 Power Management, the key to RTD3 suspend.
    options nvidia "NVreg_DynamicPowerManagement=0x02"
    ```

3.  **Rebuild the initramfs and reboot** for the changes to be applied at the kernel level.
    ```bash
    sudo mkinitcpio -P
    sudo reboot
    ```

**`NVreg_DynamicPowerManagement` Explained:**

| Value | Name | In-Depth Explanation |
| :--- | :--- | :--- |
| `0x00` | Disabled | The GPU will never enter a low-power state. It remains fully powered even at idle. Avoid this setting on a laptop. |
| `0x01` | Coarse-Grained | The GPU will only power down if there are absolutely zero applications using it (no active clients). This is often too strict, as even a desktop compositor can count as a client. |
| `0x02` | **Fine-Grained** | **(The Optimal Setting)** The GPU can power down even if applications have an active context, as long as the GPU hardware itself has been idle for a short period. This is the setting that enables true RTD3 suspend and massive battery savings. |
| `0x03` | Default | On modern Ampere-generation GPUs and newer, this defaults to `0x02`. However, explicitly setting it to `0x02` is a best practice to ensure consistent behavior across driver updates. |

### 3.3: Automating Power State with `udev`

**Purpose:** Your note correctly identified this as a missing piece. `udev` is the Linux subsystem that manages device events. You can create a rule that tells the kernel it has permission to automatically manage the power state of the NVIDIA GPU as soon as it's detected during boot.

**Action:** Create a `udev` rule to set the GPU's power control to `auto`.

1.  **Create the udev rule file:**
    ```bash
    sudo nano /etc/udev/rules.d/80-nvidia-pm.rules
    ```

2.  **Add the following content:**
    ```
    # Allow the kernel to automatically manage the power state of the NVIDIA GPU.
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", ATTR{power/control}="auto"
    
    # Keep the NVIDIA audio device powered on to prevent audio glitches.
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="on"
    ```
    *   **Explanation:** This rule triggers when a PCI device (`SUBSYSTEM=="pci"`) is added. If the vendor is NVIDIA (`0x10de`) and it's a VGA controller (`class=="0x030000"`) or 3D controller (`class=="0x030200"`), it sets its `power/control` file to `auto`. This is the final piece of the puzzle for enabling RTD3.

3.  **Reload the rules and reboot:**
    ```bash
    sudo udevadm control --reload-rules
    sudo reboot
    ```

---

## Part 4: Wayland & Hyprland Multi-GPU Configuration

This section details how to configure a Wayland compositor like Hyprland in a multi-GPU environment, ensuring it uses the correct GPU for rendering.

### 4.1: Identifying Your GPUs Persistently

**Purpose:** You must tell Hyprland which GPU to use. Device names like `/dev/dri/card0` are **not stable** and can swap on reboot. You must use the persistent, path-based names.

**The Two-Step Identification Process:**

1.  **Find PCI Addresses:** Use `lspci` to list your display controllers and their unique addresses.
    ```bash
    lspci -d ::03xx
    ```
    **Example Output:**
    ```
    0000:00:02.0 VGA compatible controller: Intel Corporation TigerLake-H GT1 [UHD Graphics] (rev 01)
    0000:01:00.0 VGA compatible controller: NVIDIA Corporation GA107M [GeForce RTX 3050 Ti Mobile] (rev a1)
    ```

2.  **Map Addresses to Persistent Device Paths:** Use `ls` to see how these PCI addresses link to device files.
    ```bash
    ls -l /dev/dri/by-path/
    ```
    **Example Output:**
    ```
    lrwxrwxrwx 1 root root 8 Jul 8 12:00 pci-0000:00:02.0-card -> ../card0
    lrwxrwxrwx 1 root root 9 Jul 8 12:00 pci-0000:00:02.0-render -> ../renderD128
    lrwxrwxrwx 1 root root 8 Jul 8 12:00 pci-0000:01:00.0-card -> ../card1
    lrwxrwxrwx 1 root root 9 Jul 8 12:00 pci-0000:01:00.0-render -> ../renderD129
    ```
    **Conclusion:** In this example, the Intel iGPU is `pci-0000:00:02.0-card` and the NVIDIA dGPU is `pci-0000:01:00.0-card`. These are the paths you must use.

### 4.2: Configuring Hyprland with `AQ_DRM_DEVICES`

**Purpose:** The `AQ_DRM_DEVICES` environment variable tells Hyprland (and other `wlroots`-based compositors) which GPU(s) to use, in order of priority.

**Action:** Set this variable in your configuration.

*   **For `hyprland.conf`:**
    This is the most direct method. Add the `env` line to your `hyprland.conf`. The first device in the list is the primary renderer.
    ```conf
    # Example: Use the Intel iGPU as primary, with NVIDIA as a secondary for render offload or external monitors.
    # Replace the paths with the ones you identified in the previous step.
    env = AQ_DRM_DEVICES,/dev/dri/by-path/pci-0000:00:02.0-card:/dev/dri/by-path/pci-0000:01:00.0-card
    ```

*   **For `uwsm` / Shell Profile Users:**
    As your note mentions, for some setups (like using `uwsm`), it's better to export this variable system-wide or in a shell profile.
    1.  Edit the appropriate file (`~/.config/uwsm/env-hyprland`, `~/.bash_profile`, `~/.zshenv`, etc.):
        ```bash
        nvim ~/.bash_profile
        ```
    2.  Add the export line.
        ```bash
        # Use the persistent path for the desired primary GPU
        export AQ_DRM_DEVICES="/dev/dri/by-path/pci-0000:00:02.0-card"
        ```

> [!IMPORTANT] **External Monitors**
> If you have an external monitor that is physically wired to a specific GPU (often the NVIDIA dGPU on laptops), that GPU's device path **must** be included in the `AQ_DRM_DEVICES` list for the monitor to be detected and used.

---

## Part 5: The System Administrator's Command Reference

This is your comprehensive, categorized library of commands for diagnostics, troubleshooting, and verification.

### Category 1: Hardware & Driver Identification

| Command | Purpose & Interpretation |
| :--- | :--- |
| `lspci \| grep -E 'VGA\|3D'` | **Purpose:** Quickly list all graphics controllers on the PCI bus. This is your first step to see what hardware the system detects. |
| `ls -l /dev/dri/by-path/` | **Purpose:** **The most reliable way to identify GPUs.** It links stable PCI addresses to the dynamic `/dev/dri/cardX` device files. **Always use this to avoid errors from device name changes.** |
| `lspci -k \| grep -EA3 'VGA\|3D'` | **Purpose:** Shows which kernel driver is currently bound to and controlling each graphics card. Look for `Kernel driver in use: nvidia` or `Kernel driver in use: i915`. If it says `nouveau`, your blacklisting failed. |
| `lspci -nnk \| grep -EA3 '\[03(00\|01\|02|80)\]'` | **Purpose:** A more robust version of the above command. It uses PCI class codes instead of keywords, making it less likely to miss a device. |
| `vulkaninfo --summary` | **Purpose:** Shows all GPUs that are properly exposed to the Vulkan API. This is an excellent high-level check to see if both your iGPU and dGPU are ready for applications. |

### Category 2: Kernel Module & Log Inspection

| Command | Purpose & Interpretation |
| :--- | :--- |
| `lsmod \| grep -i nvidia` | **Purpose:** Confirms that the `nvidia` kernel modules are currently loaded into memory. If this is empty after a reboot, the driver failed to load. |
| `lsmod \| grep -E "bbswitch\|nouveau\|nvidia"` | **Purpose:** A broader check to see if `nvidia` is loaded and, crucially, if `nouveau` or the legacy `bbswitch` module are also loaded, which would indicate a conflict. |
| `sudo dmesg \| grep -i nvidia` | **Purpose:** Dumps the kernel ring buffer and filters for messages from the `nvidia` driver. This is the primary place to look for error messages during the module loading process at boot. |
| `journalctl -k \| grep -E -i "nvidia\|nouveau"` | **Purpose:** A more modern and powerful way to view kernel logs. It's searchable and persistent across reboots. Use this to find errors related to either driver. |
| `journalctl \| grep -E -i "nvidia\|nouveau"` | **Purpose:** Searches the *entire systemd journal* (not just kernel logs) for messages. This can reveal issues from userspace services or Xorg/Wayland. |

### Category 3: Configuration & Power State Verification

| Command | Purpose & Interpretation |
| :--- | :--- |
| `sudo cat /sys/module/nvidia_drm/parameters/modeset` | **Purpose:** Directly checks if KMS was enabled. **Expected Output:** `Y`. If it's `N`, your kernel parameter was not applied correctly. |
| `sudo cat /sys/bus/pci/devices/0000\:01\:00.0/power/control` | **Purpose:** Verifies your `udev` rule worked. **Expected Output:** `auto`. (Remember to replace the PCI address with your NVIDIA GPU's address, escaping the colons for the shell). |
| `sudo cat /sys/bus/pci/devices/0000\:01\:00.0/power/runtime_status` | **Purpose:** **The ultimate RTD3 check.** Shows the real-time power status. **Expected Output (when idle):** `suspended`. If it says `active`, the GPU is not powering down. |
| `ls -l /usr/lib/systemd/system/nvidia-*.service` | **Purpose:** Lists all systemd services installed by the NVIDIA packages, such as `nvidia-suspend.service`, `nvidia-resume.service`, and `nvidia-powerd.service`. |

---

## Part 6: Real-Time Monitoring & Management Tools

### 6.1: `nvidia-smi` - The Core Management Tool

**Purpose:** The NVIDIA System Management Interface is your command-line dashboard and control panel for the GPU. It is built on top of the NVIDIA Management Library (NVML).

**Key Commands:**

| Command | Description |
| :--- | :--- |
| `nvidia-smi` | The main command. Gives a detailed snapshot of GPU utilization, VRAM usage, temperature, power draw, and a list of processes using the GPU. |
| `watch -n 1 nvidia-smi` | Runs `nvidia-smi` every second, giving you a live view of GPU activity. |
| `nvidia-smi -q -d POWER` | Queries and displays detailed information about the GPU's power state, including current draw and power limits. |
| `sudo nvidia-smi -pl 90` | **Temporarily** sets the maximum power limit to 90 watts. This is useful for managing thermals but **resets on reboot**. |
| `sudo nvidia-smi -pm 1` | **Enables Persistence Mode.** Forces the NVIDIA driver to stay loaded in the kernel at all times. **This is bad for laptop battery life** as it prevents RTD3 suspend. Its main use is for CUDA developers who need to minimize driver load latency. |
| `sudo nvidia-smi -pm 0` | **Disables Persistence Mode.** This is the **default and recommended setting for laptops**, as it allows the driver to be unloaded, which is a prerequisite for the GPU to enter its deep sleep state. |

### 6.2: Other Essential Monitoring Utilities

| Tool | Command | Description & Underlying Technology |
| :--- | :--- | :--- |
| **NVTOP** | `nvtop` | A user-friendly, `htop`-like interface for real-time GPU monitoring. It leverages NVML to display utilization, VRAM, power, and processes in a clean, terminal-based UI. **If it shows "No GPU to monitor," your RTD3 power saving is working!** |
| **Intel GPU Top** | `sudo intel_gpu_top` | The equivalent of `nvtop` for Intel iGPUs. It queries the `i915` kernel module directly for detailed performance counters and engine utilization. Essential for debugging hybrid graphics issues. |
| **Btop++** | `btop` | A full-system resource monitor. It gathers data from `/proc` and `/sys` to show CPU, memory, disk, network, and process information in a beautiful and intuitive interface. |
| **VA-API Info** | `vainfo` | Displays information about your system's Video Acceleration API (VA-API) capabilities. It tells you which video codecs (H.264, HEVC, AV1) your GPUs can accelerate for hardware decoding and encoding. |

---

## Part 7: Deep Dive - Understanding Low-Level System Interfaces

This section demystifies the underlying system components you are interacting with, transforming commands from magic incantations into understood tools.

### 7.1: The `/proc` Filesystem - A Direct Window to the Kernel

Your note contained an excellent explanation of this, which I have preserved and expanded upon here.

The `/proc` directory is not a real directory on your storage device. It is a **virtual filesystem** (`procfs`) created in memory by the Linux kernel at boot time. It serves as a live dashboard and control panel for the kernel and its modules.

When you interact with a file like `/proc/driver/nvidia/gpus/0000:01:00.0/power`, you are not reading a text file from disk. Your action (`cat` or `nvim`) is intercepted by the kernel, which forwards the request to the `nvidia` driver. The driver then queries the GPU's hardware/firmware for its real-time power status and formats that information as text for you to see.

> [!DANGER] **The Mechanic's Wrench vs. The Car's Computer**
> Modifying files in `/proc` is a powerful but risky operation. It is like a mechanic directly turning a screw on the engine. It's useful for low-level debugging but lacks the safety checks of high-level tools.
>
> | Interface | Use Case | Safety | Persistence | Analogy |
> | :--- | :--- | :--- | :--- | :--- |
> | **`nvidia-smi`** | General monitoring, setting power limits, clocks. | **Recommended & Safe.** Has built-in error checking. | Yes, can be configured for persistence. | The car's official diagnostic and tuning computer. |
> | **`/proc/.../power`** | Low-level debugging and deep system inspection. | **Use with caution.** Mistakes can cause instability. | **No, changes are lost on reboot.** | A mechanic directly adjusting a single screw on the engine. |
>
> **Conclusion:** Use `/proc` to observe and learn. Use `nvidia-smi` to act.

### 7.2: Kernel Module Management with `modprobe`

`modprobe` is the master utility for managing kernel modules.

| Command | Description |
| :--- | :--- |
| `depmod` | Scans all module directories and creates a list of dependencies (`modules.dep`). This ensures that when you load a module, `modprobe` knows all the other modules it depends on. |
| `sudo modprobe <module_name>` | Loads a module and all of its dependencies into the kernel. Use the `-v` (verbose) flag to see what it's doing. |
| `sudo modprobe -r <module_name>` | Unloads (removes) a module from the kernel. This will fail if the module is currently in use (e.g., you cannot unload `nvidia` while a graphical session is running). |
| `modinfo <module_name>` | Displays detailed information about a module, including its author, description, license, dependencies, and available parameters. |

---

## Part 8: Glossary of Core Concepts

*   **DKMS (Dynamic Kernel Module Support):** A framework that automatically recompiles kernel modules when the kernel is updated, ensuring drivers continue to work across upgrades.
*   **DRM (Direct Rendering Manager):** The Linux kernel subsystem that interfaces with GPUs. It's responsible for managing memory, setting display modes (via KMS), and coordinating access to the hardware.
*   **KMS (Kernel Mode Setting):** A feature of DRM that allows the kernel to control display settings. It enables a high-resolution, flicker-free boot and is a prerequisite for Wayland.
*   **P-States (Performance Levels):** The active power states of the GPU, ranging from P0 (maximum performance) to P8/P12 (idle). The driver switches between these automatically based on workload.
*   **RTD3 (Runtime D3 Power Management):** The "off" state for a PCI device. On Optimus laptops, this is the deep sleep state where the NVIDIA GPU is completely powered down to save battery. Achieving this is the primary goal of laptop power management.
*   **DPMS (Display Power Management Signaling):** A standard for managing the power state of monitors, allowing them to enter standby, suspend, or off modes to save power. This is related to, but distinct from, GPU power management.

