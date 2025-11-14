
# Mastering USB Power Management in Arch Linux

USB autosuspend is a critical kernel feature for power saving, particularly on laptops. It automatically places idle USB devices into a low-power state. While highly effective for extending battery life, it can sometimes cause issues with peripherals like mice or keyboards that may lag upon waking.

This guide provides a comprehensive walkthrough for diagnosing, troubleshooting, and persistently configuring USB power states on your Arch Linux systems.

> [!TIP] Relation to Overall Power Management
> USB power settings are one component of a larger strategy. For a complete overview, refer to the main [[Power Management]] guide, which covers tools like TLP and Powertop that can manage these settings globally.

---

## 1. Diagnosing the Current USB Power State

Before making any changes, you must first inspect the current configuration of your USB devices. The following commands query the kernel's `sysfs` filesystem to reveal the live power management status.

### 1.1. Check Autosuspend Status (`power/control`)

This command iterates through all USB devices and checks whether the kernel is permitted to manage their power state.

*   `auto`: Autosuspend is **enabled**. The kernel can suspend the device when idle.
*   `on`: Autosuspend is **disabled**. The device is always kept fully powered.

```bash
#!/bin/bash
# Script to check the power/control state for all USB devices.

for devpath in /sys/bus/usb/devices/*-* ; do
    if [ -f "$devpath/power/control" ]; then
        device_name=$(lsusb -s $(basename $devpath) | cut -d ' ' -f 7-)
        printf "Device: %s\n" "$device_name"
        printf "  Path: %s\n" "$devpath/power/control"
        printf "  State: %s\n\n" "$(cat "$devpath/power/control")"
    fi
done
```

### 1.2. Check Autosuspend Delay (`autosuspend_delay_ms`)

If a device's `power/control` is set to `auto`, this value determines how long (in milliseconds) the device must be idle before the kernel suspends it. The default is typically `2000` (2 seconds).

```bash
#!/bin/bash
# Script to check the autosuspend delay for all applicable USB devices.

for devpath in /sys/bus/usb/devices/*-* ; do
    if [ -f "$devpath/power/autosuspend_delay_ms" ]; then
        device_name=$(lsusb -s $(basename $devpath) | cut -d ' ' -f 7-)
        printf "Device: %s\n" "$device_name"
        printf "  Path: %s\n" "$devpath/power/autosuspend_delay_ms"
        printf "  Delay: %s\n\n" "$(cat "$devpath/power/autosuspend_delay_ms")"
    fi
done
```

---

## 2. Manual Configuration (Temporary)

You can manually change these settings for testing purposes. This is useful for quickly diagnosing if autosuspend is the cause of a problem with a specific device.

> [!WARNING] Temporary Changes
> Any changes made directly to `sysfs` files are temporary and will be **reset upon reboot**. For a permanent solution, see the `udev` rules section below.

**Step 1: Identify the Device Path**
Run the diagnostic script from section 1.1 to find the path for your target device (e.g., `/sys/bus/usb/devices/1-4`).

**Step 2: Change the Power State**
Use the following command, replacing the path with your device's path.

*   **To disable autosuspend (force the device on):**
    ```bash
    echo 'on' | sudo tee /sys/bus/usb/devices/1-4/power/control
    ```
*   **To enable autosuspend:**
    ```bash
    echo 'auto' | sudo tee /sys/bus/usb/devices/1-4/power/control
    ```

---

## 3. Persistent Configuration with `udev` Rules

The correct, professional method for managing device-specific power settings is to use `udev` rules. This ensures your configuration is automatically applied every time the device is connected or the system boots. This is the ideal solution for permanently disabling autosuspend for a problematic mouse, keyboard, or other peripheral.

### Step-by-Step Guide to Creating a `udev` Rule

**1. Find the Device's Vendor and Product ID**

Use the `lsusb` command to list all connected USB devices. Find your target device and note its `ID`. The format is `vendorID:productID`.

```bash
lsusb
```
*Example Output:*
```
Bus 001 Device 004: ID 046d:c52b Logitech, Inc. Unifying Receiver
```
In this example, the `idVendor` is `046d` and the `idProduct` is `c52b`.

**2. Create a New `udev` Rule File**

Rule files are stored in `/etc/udev/rules.d/`. The name should start with a number (to control ordering) and end in `.rules`.

```bash
sudo nvim /etc/udev/rules.d/50-usb-power-settings.rules
```

**3. Write the Rule**

Add a line to the file using the IDs you found. The following rule disables autosuspend for the Logitech Unifying Receiver from the example.

```udev
# Disable autosuspend for the Logitech Unifying Receiver to prevent mouse lag
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c52b", TEST=="power/control", ATTR{power/control}="on"
```

**Rule Breakdown:**

| Component | Purpose |
|---|---|
| `ACTION=="add"` | Triggers the rule when the device is connected. |
| `SUBSYSTEM=="usb"` | Specifies that this rule only applies to USB devices. |
| `ATTR{idVendor}=="046d"` | Matches the device's Vendor ID. |
| `ATTR{idProduct}=="c52b"` | Matches the device's Product ID. |
| `TEST=="power/control"` | Checks if the `power/control` file exists, preventing errors. |
| `ATTR{power/control}="on"` | The action: writes `on` to the `power/control` file. |

**4. Reload `udev` Rules**

Apply the new rule without needing to reboot.

```bash
sudo udevadm control --reload-rules
```

Your device's power settings will now be applied automatically and persistently across reboots. You can create multiple lines in this file for different devices.

