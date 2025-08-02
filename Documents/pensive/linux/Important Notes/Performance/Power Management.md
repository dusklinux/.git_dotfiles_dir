
# Power Management in Arch Linux: A Comprehensive Guide

Effective power management is critical for extending battery life on laptops and reducing energy costs and thermal output in large-scale deployments. This guide provides a structured, comprehensive approach to setting up, diagnosing, and understanding the full spectrum of power-saving features in Arch Linux, designed to serve as both a step-by-step manual and a quick-reference document for system administrators.

---

## 1. Core Power Management Tools: Setup & Usage

For most systems, a combination of `TLP` for automated background management and `powertop` for real-time diagnostics is the ideal setup.

### 1.1. TLP: Automated Power Management

TLP (Linux Advanced Power Management) is a feature-rich utility that applies a comprehensive set of power-saving tweaks automatically. It is the recommended "set-and-forget" solution for most use cases.

**Step 1: Installation**
Install TLP and `tlp-rdw`, which is essential for managing power on radio devices like Wi-Fi and Bluetooth.

```bash
sudo pacman -S --needed tlp tlp-rdw
```

**Step 2: Enable and Start the Service**
Enable the TLP service to ensure it starts automatically on every boot, then start it immediately.

```bash
sudo systemctl enable tlp.service
sudo systemctl start tlp.service
```

**Step 3: Verify Status**
Check that the service is active and running without errors.

```bash
sudo systemctl status tlp.service
```

### 1.2. Powertop: Diagnostics and Fine-Tuning

`powertop` is an Intel-developed tool for diagnosing power consumption issues. It helps identify which processes and devices are consuming the most power and which power-saving features are not enabled.

> [!WARNING] Potential Conflicts
> TLP and `powertop --auto-tune` can conflict, as both attempt to manage the same kernel settings. It is best practice to use **TLP for automated management** and **`powertop` only for monitoring and diagnostics**. Avoid using `powertop`'s auto-tune feature if TLP is active.

**Step 1: Installation**

```bash
sudo pacman -S --needed powertop
```

**Step 2: Interactive Diagnostics**
Run `powertop` with root privileges to access its full feature set. Use the `Tab` and arrow keys to navigate.

```bash
sudo powertop
```
*   **Overview:** Shows which processes and devices are drawing the most power and causing CPU wakeups.
*   **Tunables Tab:** This is the most critical section for diagnostics. Devices marked as **"Bad"** are not using their power-saving features. You can press `Enter` on a tunable to toggle its state to **"Good"**.

**Step 3: Automated Tuning (Use with Extreme Caution)**
The `--auto-tune` flag sets all tunables to their optimal "Good" state.

```bash
sudo powertop --auto-tune
```

> [!DANGER] Temporary and Potentially Unstable
> Changes made by `powertop` (both interactively and via `--auto-tune`) are **temporary** and will be lost on reboot. While you can create a systemd service to apply them at boot, this is **not recommended** if you are using TLP, as TLP already manages these settings more intelligently and safely. Using this can sometimes cause instability with certain hardware (e.g., USB devices disappearing).

---

## 2. The System Administrator's Command Reference

This is your comprehensive library of commands for deep inspection and verification of power management subsystems.

### 2.1. General Hardware and Power State Inspection

| Command | Purpose & Interpretation |
|---|---|
| `lspci` | The fundamental tool for listing all PCI devices. Use `lspci -h` to see its many useful flags. |
| `sudo lspci -vvv \| grep ASPM` | Lists all PCI devices and their **ASPM (Active State Power Management)** capabilities and current status. This is the most comprehensive view. |
| `sudo lspci -vvv \| grep 'ASPM .*abled'` | A filtered view that quickly shows only the devices for which ASPM is currently **enabled** or **disabled**. |
| `cat /sys/module/pcie_aspm/parameters/policy` | Checks the kernel's global ASPM policy. The currently active policy is enclosed in `[]` brackets (e.g., `[default] powersave powersupersave`). |
| `cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor` | Displays the current CPU frequency scaling governor for each core (e.g., `powersave`, `performance`). |
| `cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_available_governors` | Lists all available governors your CPU supports, showing what policies you can set. |
| `cat /sys/bus/pci/devices/*/power/control` | Checks the **Runtime Power Management** status for all PCI devices. `auto` means enabled; `on` means the device is forced on (power saving disabled). |

### 2.2. Script: Check Runtime PM Status for All PCI Devices

This script provides a clean, human-readable list of all PCI devices and their current runtime power management status (`active` or `suspended`).

```bash
#!/bin/bash
# Iterates through all PCI devices and reports their runtime power status.

for device_path in /sys/bus/pci/devices/*; do
    device_id=$(basename "$device_path")
    
    # Get the human-readable device name from lspci
    device_name=$(lspci -s "$device_id" | awk -F': ' '{print $2}')
    
    if [ -f "$device_path/power/runtime_status" ]; then
        status=$(cat "$device_path/power/runtime_status")
        echo "Device $device_id ($device_name): $status"
    else
        echo "Device $device_id ($device_name): runtime_status not available or not applicable."
    fi
done
```

---

## 3. Glossary of Power Management Terminology

Understanding these core concepts is essential for effective troubleshooting.

### 3.1. Core Technologies & Standards

**ASPM (Active State Power Management)**
Imagine your computer is a busy office building. The departments (CPU, GPU, Wi-Fi) communicate through super-fast hallways called PCI Express (PCIe) lanes. Normally, these hallways are always "on," consuming power. ASPM is a smart energy-saving feature that allows these hallways and the connected devices to enter a low-power "sleep" state when no data is being sent.
*   **L0s (L0 Substate):** A very light "napping" state. Devices can wake up almost instantly. Think of someone briefly closing their eyes at their desk.
*   **L1 (L1 Substate):** A deeper "sleep" state that saves more power but has a longer wake-up time. Think of someone taking a short power nap in a break room.

**ACPI (Advanced Configuration and Power Interface)**
ACPI is the fundamental industry standard defining how the operating system (OS) interacts with and controls the hardware's power states. It shifts control from the legacy BIOS to the OS, allowing for more intelligent, dynamic power management.
*   **OS-Directed Power Management (OSPM):** Allows the OS to decide when to put components to sleep, wake them up, and adjust CPU speeds.
*   **Device States (D-States):**
    *   **D0 (Fully On):** The device is fully operational.
    *   **D1/D2 (Intermediate):** Device-specific low-power states with faster wake-up times than D3.
    *   **D3 (Off):** The device is mostly powered off. It is subdivided into `D3hot` (auxiliary power present, allowing remote wake-up) and `D3cold` (no power, device completely off).

**APM (Advanced Power Management)**
APM is the older, less sophisticated predecessor to ACPI. It was a BIOS-controlled standard from the mid-1990s. The OS could only make requests to the BIOS, which retained ultimate control. It provided basic functions like spinning down hard drives.
> [!NOTE] Key takeaway: APM was largely superseded by ACPI. You will not typically see APM in use on any contemporary hardware.

**Linux Kernel's Runtime Power Management (Runtime PM)**
The Linux kernel has a dedicated "efficiency manager" (the Runtime PM framework). This manager constantly watches individual devices. If a device has been idle for a while, the manager tells it to take a nap (enter a low-power state). When the device is needed again, the manager quickly wakes it up. This happens seamlessly in the background without the entire system having to sleep.

### 3.2. CPU-Specific Power States

**C-States (CPU Sleep States)**
These states save power when the CPU is idle. The deeper the C-state, the more power is saved, but the longer it takes for the CPU to become fully responsive again.
*   **C0:** "Awake" state – the CPU is actively working.
*   **C1 (Halt):** A very light nap. The CPU stops its main clock but can wake up almost instantly.
*   **C2 (Stop-Clock):** A slightly deeper nap where more parts of the CPU are powered down.
*   **C3 (Deep Sleep):** Deeper still. Caches might be flushed, and more power is cut.
*   **C4, C5, C6, etc.:** Progressively deeper sleep states, saving more power but incurring longer wake-up latencies.

**P-States (CPU Performance States)**
If C-states are about napping, P-states are about how fast the CPU works when it *is* awake. They control the CPU's "speed dial" (frequency) and "power dial" (voltage).
*   **P0:** Maximum performance, highest frequency, highest voltage.
*   **P1, P2, ... Pn:** Progressively lower performance states with reduced frequency and voltage, saving significant power during less intensive tasks.

**DVFS (Dynamic Voltage and Frequency Scaling)**
This is the underlying technology that makes P-states possible. It's the physical mechanism that allows the CPU to change its speed (frequency) and voltage on the fly to match the current workload.

### 3.3. Other Related Concepts

**DPM (Dynamic Power Management)**
This is a broad, general term for the overall strategy of dynamically adjusting power usage based on workload. P-states, C-states, ASPM, and Runtime PM all fall under the umbrella of DPM. It's about making power decisions "on-the-fly."

**SMM (System Management Mode)**
Think of SMM as a hidden, ultra-privileged "secret service" for your computer's firmware (BIOS/UEFI). It runs at a higher privilege level than the OS kernel. Historically used for power management, it now primarily handles low-level functions like thermal management, fan control, and system diagnostics. Modern systems prefer to let the OS handle power management via ACPI to avoid SMM-induced latency.

**PMIC (Power Management Integrated Circuit)**
This is a literal hardware component—a specialized chip on the motherboard that acts as the "power distribution board." It handles voltage regulation, power sequencing (turning components on/off in the correct order), battery charging, and overall power supply control.

**TPM (Trusted Platform Module)**
A hardware chip for security, not directly related to power consumption. It acts as a secure vault for cryptographic keys and platform integrity measurements (e.g., for secure boot). It's about trust and security, not energy saving.

---

### 4. Component-Specific Power Management

For detailed guides on managing power for specific hardware, refer to these specialized notes:

*   **GPU Power:** For NVIDIA GPUs, managing power states (like RTD3) is crucial for battery life. See [[Nvidia]] for details on `nvidia-smi` and driver configuration.
*   **Storage Power:** Modern NVMe SSDs have advanced power-saving features. See [[Disk]] for how to inspect and manage NVMe power states, APST, and ASPM.

