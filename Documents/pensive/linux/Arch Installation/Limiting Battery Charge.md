---
subject: battery limiter temperary
context:
  - setup
  - arch install
type: guide
status: complete
---

To prolong your laptop's battery lifespan, especially when it's frequently plugged in, you can limit its maximum charge level. This guide shows how to set a temporary charge threshold.

> [!NOTE] Temporary Change
> The setting applied in this guide is temporary and will be reset upon reboot. For a permanent solution, a `systemd` service is required.

### 1. Identify Your Battery

First, you need to find the name of your battery device, which is typically `BAT0` or `BAT1`.

Run the following command to list your power supply devices:

```bash
ls /sys/class/power_supply/
```

Identify the entry corresponding to your main battery from the output.

### 2. Set the Charge Threshold

Once you have the battery name, use the following command to set the maximum charge percentage. This example limits the charge to `60%` for a battery named `BAT1`.

```bash
echo 60 | sudo tee /sys/class/power_supply/BAT1/charge_control_end_threshold
```

> [!TIP] Customization
> - Replace `60` with your desired percentage (e.g., `80`).
> - Replace `BAT1` with the correct battery name you found in the previous step.

Your laptop will now stop charging once it reaches the specified threshold.
